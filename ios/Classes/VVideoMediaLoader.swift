import Foundation
import AVFoundation

/// Utility class for loading video files from device storage
class VVideoMediaLoader {
    
    /// Loads video info from local file path
    func loadVideoInfo(path: String) -> VVideoInfo? {
        guard let url = createURL(from: path) else { return nil }
        return getVideoInfoFromFile(url: url)
    }
    
    /// Gets video info from file URL
    private func getVideoInfoFromFile(url: URL) -> VVideoInfo? {
        let asset = AVAsset(url: url)
        
        // Get video duration
        let duration = Int64(asset.duration.seconds * 1000) // Convert to milliseconds
        
        // Get file size
        let fileSize = getFileSize(for: url)
        
        // Get video dimensions
        guard let track = asset.tracks(withMediaType: .video).first else { return nil }
        let size = track.naturalSize.applying(track.preferredTransform)
        let width = Int(abs(size.width))
        let height = Int(abs(size.height))
        
        // Get filename
        let filename = url.lastPathComponent
        
        return VVideoInfo(
            path: url.path,
            name: filename,
            fileSizeBytes: fileSize,
            durationMillis: duration,
            width: width,
            height: height,
            thumbnailPath: nil
        )
    }
    

    
    /// Gets video duration from file path
    func getVideoDuration(_ videoPath: String, completion: @escaping (Int64) -> Void) {
        guard let url = createURL(from: videoPath) else {
            completion(0)
            return
        }
        
        let asset = AVAsset(url: url)
        asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            var error: NSError?
            let status = asset.statusOfValue(forKey: "duration", error: &error)
            
            guard status == .loaded else {
                DispatchQueue.main.async {
                    completion(0)
                }
                return
            }
            
            let duration = asset.duration
            let durationInMilliseconds = Int64(CMTimeGetSeconds(duration) * 1000)
            
            DispatchQueue.main.async {
                completion(durationInMilliseconds)
            }
        }
    }
    
    /// Gets video information from file path
    func getVideoInfo(from videoPath: String, completion: @escaping (VVideoInfo?) -> Void) {
        guard let url = createURL(from: videoPath) else {
            completion(nil)
            return
        }
        
        let asset = AVAsset(url: url)
        asset.loadValuesAsynchronously(forKeys: ["duration", "tracks"]) {
            var error: NSError?
            let durationStatus = asset.statusOfValue(forKey: "duration", error: &error)
            let tracksStatus = asset.statusOfValue(forKey: "tracks", error: &error)
            
            guard durationStatus == .loaded && tracksStatus == .loaded else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let duration = asset.duration
            let tracks = asset.tracks
            
            // Get video track for dimensions
            let videoTrack = tracks.first { $0.mediaType == .video }
            let naturalSize = videoTrack?.naturalSize ?? .zero
            
            // Get file size
            let fileSize = self.getFileSize(for: url)
            
            // Get filename
            let filename = url.lastPathComponent
            
            let videoInfo = VVideoInfo(
                path: videoPath,
                name: filename,
                fileSizeBytes: fileSize,
                durationMillis: Int64(CMTimeGetSeconds(duration) * 1000),
                width: Int(naturalSize.width),
                height: Int(naturalSize.height),
                thumbnailPath: nil
            )
            
            DispatchQueue.main.async {
                completion(videoInfo)
            }
        }
    }
    
    /// Gets thumbnail path for a video (placeholder implementation)
    func getVideoThumbnailPath(_ videoPath: String, completion: @escaping (String?) -> Void) {
        // For now, return nil as thumbnail generation is handled separately
        // In a real implementation, you might want to generate and cache thumbnails
        completion(nil)
    }
    
    /// Gets file size for a given URL
    private func getFileSize(for url: URL) -> Int64 {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
            return Int64(resourceValues.fileSize ?? 0)
        } catch {
            return 0
        }
    }
    
    /// Creates a URL from various path formats (file paths, URLs, etc.)
    private func createURL(from path: String) -> URL? {
        print("VVideoMediaLoader: Creating URL from path: \(path)")
        
        // First, try to create URL from string (for proper URLs)
        if let url = URL(string: path), url.scheme != nil {
            print("VVideoMediaLoader: Successfully created URL with scheme: \(url.scheme ?? "none")")
            return url
        }
        
        // If that fails, treat it as a file path
        if path.hasPrefix("/") {
            // Absolute file path
            let url = URL(fileURLWithPath: path)
            print("VVideoMediaLoader: Created file URL: \(url)")
            return url
        }
        
        // Try to handle file:// URLs that might be passed as strings
        if path.hasPrefix("file://") {
            let url = URL(string: path)
            print("VVideoMediaLoader: Created file:// URL: \(String(describing: url))")
            return url
        }
        
        // Last resort: try as relative path from documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documentsPath.appendingPathComponent(path)
        print("VVideoMediaLoader: Created relative URL: \(url)")
        return url
    }
} 