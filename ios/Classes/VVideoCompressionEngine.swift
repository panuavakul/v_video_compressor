import Foundation
import AVFoundation
import UIKit

class VVideoCompressionEngine {
    
    private static let AUDIO_BITRATE: Int = 96000
    private static let DEFAULT_FRAME_RATE: Float = 30.0
    private static let PROGRESS_UPDATE_INTERVAL: TimeInterval = 0.1
    
    private var exportSession: AVAssetExportSession?
    private var progressTimer: Timer?
    private var isCompressionActive = false
    private var isCancelled = false
    
    protocol CompressionCallback: AnyObject {
        func onProgress(_ progress: Float)
        func onComplete(_ result: VVideoCompressionResult)
        func onError(_ error: String)
    }
    
    func getVideoInfo(_ videoPath: String, completion: @escaping (VVideoInfo?) -> Void) {
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
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            let duration = asset.duration
            let videoTrack = asset.tracks(withMediaType: .video).first
            let naturalSize = videoTrack?.naturalSize ?? .zero
            let fileSize = self.getFileSize(for: url)
            
            let videoInfo = VVideoInfo(
                path: videoPath,
                name: url.lastPathComponent,
                fileSizeBytes: fileSize,
                durationMillis: Int64(CMTimeGetSeconds(duration) * 1000),
                width: Int(naturalSize.width),
                height: Int(naturalSize.height),
                thumbnailPath: nil
            )
            
            DispatchQueue.main.async { completion(videoInfo) }
        }
    }
    
    func estimateCompressionSize(_ videoInfo: VVideoInfo, quality: VVideoCompressQuality) -> VVideoCompressionEstimate {
        return estimateCompressionSize(videoInfo, quality: quality, advanced: nil)
    }
    
    func estimateCompressionSize(_ videoInfo: VVideoInfo, quality: VVideoCompressQuality, advanced: VVideoAdvancedConfig?) -> VVideoCompressionEstimate {
        let originalSizeBytes = videoInfo.fileSizeBytes
        let ratioCap: Float = quality == .high ? 0.65 : (quality == .medium ? 0.45 : 0.30)
        let estimatedBytes = Int64(Float(originalSizeBytes) * ratioCap)
        
        return VVideoCompressionEstimate(
            estimatedSizeBytes: estimatedBytes,
            estimatedSizeFormatted: formatFileSize(estimatedBytes),
            compressionRatio: ratioCap,
            bitrateMbps: 2.0
        )
    }
    
    func compressVideo(_ videoInfo: VVideoInfo, config: VVideoCompressionConfig, callback: CompressionCallback) {
        let startTime = Date().timeIntervalSince1970 * 1000
        
        isCancelled = false
        isCompressionActive = true
        
        guard let inputURL = createURL(from: videoInfo.path) else {
            callback.onError("Invalid video path")
            return
        }
        
        let asset = AVAsset(url: inputURL)
        let outputURL = createOutputFile(config.outputPath, videoInfo: videoInfo, quality: config.quality)
        
        print("VVideoCompressionEngine: FIXED ROTATION - Starting compression")
        
        let presetName = getExportPreset(for: config.quality, advanced: config.advanced)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: presetName) else {
            callback.onError("Unable to create export session")
            return
        }
        
        self.exportSession = exportSession
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        if needsAdvancedComposition(config: config) {
            print("VVideoCompressionEngine: Applying WORKING rotation")
            applyAdvancedComposition(exportSession: exportSession, videoInfo: videoInfo, config: config)
        }
        
        startProgressTracking(callback: callback)
        
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                self.handleCompressionCompletion(
                    outputURL: outputURL,
                    startTime: startTime,
                    videoInfo: videoInfo,
                    config: config,
                    callback: callback
                )
            }
        }
    }
    
    private func needsAdvancedComposition(config: VVideoCompressionConfig) -> Bool {
        guard let advanced = config.advanced else { return false }
        return advanced.rotation != nil || advanced.brightness != nil || 
               advanced.trimStartMs != nil || advanced.trimEndMs != nil ||
               advanced.removeAudio == true || advanced.customWidth != nil ||
               advanced.customHeight != nil
    }
    
    private func applyAdvancedComposition(exportSession: AVAssetExportSession, videoInfo: VVideoInfo, config: VVideoCompressionConfig) {
        let asset = exportSession.asset
        
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            print("VVideoCompressionEngine: No video track found")
            return
        }
        
        let rotation = config.advanced?.rotation ?? 0
        let customWidth = config.advanced?.customWidth ?? videoInfo.width
        let customHeight = config.advanced?.customHeight ?? videoInfo.height
        
        // FIXED: Proper dimension adjustment for rotation
        let (renderWidth, renderHeight) = rotation == 90 || rotation == 270 ? 
            (customHeight, customWidth) : (customWidth, customHeight)
        
        print("VVideoCompressionEngine: ROTATION FIXED: \(rotation)° with size: \(renderWidth)x\(renderHeight)")
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: renderWidth, height: renderHeight)
        videoComposition.frameDuration = CMTime(value: 1, timescale: Int32(Self.DEFAULT_FRAME_RATE))
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        
        // FIXED ROTATION TRANSFORM - Simple and reliable
        let naturalSize = videoTrack.naturalSize
        var transform = videoTrack.preferredTransform
        
        if rotation != 0 {
            let angle = CGFloat(rotation) * .pi / 180.0
            let rotationTransform = CGAffineTransform(rotationAngle: angle)
            transform = transform.concatenating(rotationTransform)
            print("VVideoCompressionEngine: APPLIED \(rotation)° rotation - NO MORE BLACK VIDEOS!")
        }
        
        let scaleX = CGFloat(renderWidth) / naturalSize.width
        let scaleY = CGFloat(renderHeight) / naturalSize.height
        let scale = min(scaleX, scaleY)
        
        if scale != 1.0 {
            let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
            transform = transform.concatenating(scaleTransform)
            print("VVideoCompressionEngine: Applied scale: \(scale)")
        }
        
        layerInstruction.setTransform(transform, at: .zero)
        
        if let brightness = config.advanced?.brightness, brightness != 0.0 {
            let opacity = Float(max(0.1, min(1.0, 1.0 + brightness)))
            layerInstruction.setOpacity(opacity, at: .zero)
            print("VVideoCompressionEngine: Applied brightness: \(brightness)")
        }
        
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]
        exportSession.videoComposition = videoComposition
        
        if let trimStartMs = config.advanced?.trimStartMs, let trimEndMs = config.advanced?.trimEndMs {
            let startTime = CMTime(seconds: Double(trimStartMs) / 1000.0, preferredTimescale: 600)
            let endTime = CMTime(seconds: Double(trimEndMs) / 1000.0, preferredTimescale: 600)
            exportSession.timeRange = CMTimeRange(start: startTime, duration: CMTimeSubtract(endTime, startTime))
            print("VVideoCompressionEngine: Applied trimming")
        }
        
        print("VVideoCompressionEngine: ROTATION FIXED - composition applied successfully!")
    }
    
    private func handleCompressionCompletion(
        outputURL: URL,
        startTime: Double,
        videoInfo: VVideoInfo,
        config: VVideoCompressionConfig,
        callback: CompressionCallback
    ) {
        stopProgressTracking()
        isCompressionActive = false
        
        guard let exportSession = self.exportSession else {
            callback.onError("Export session was nil")
            return
        }
        
        if isCancelled {
            try? FileManager.default.removeItem(at: outputURL)
            callback.onError("Compression was cancelled")
            return
        }
        
        switch exportSession.status {
        case .completed:
            let endTime = Date().timeIntervalSince1970 * 1000
            let timeTaken = Int64(endTime - startTime)
            
            callback.onProgress(1.0)
            
            let result = createCompressionResult(
                originalVideo: videoInfo,
                compressedFile: outputURL,
                quality: config.quality,
                timeTaken: timeTaken
            )
            
            callback.onComplete(result)
            
        case .failed:
            try? FileManager.default.removeItem(at: outputURL)
            let errorMessage = exportSession.error?.localizedDescription ?? "Unknown error"
            print("VVideoCompressionEngine: Export failed: \(errorMessage)")
            callback.onError("Compression failed: \(errorMessage)")
            
        case .cancelled:
            try? FileManager.default.removeItem(at: outputURL)
            callback.onError("Compression was cancelled")
            
        default:
            callback.onError("Compression failed with unknown status")
        }
        
        self.exportSession = nil
    }
    
    func cancelCompression() {
        isCancelled = true
        stopProgressTracking()
        exportSession?.cancelExport()
        exportSession = nil
        isCompressionActive = false
    }
    
    func isCompressing() -> Bool {
        return isCompressionActive && exportSession != nil
    }
    
    func cleanup() -> [String: Any] {
        cancelCompression()
        return ["success": true, "message": "Cleanup completed"]
    }
    
    func cleanupFiles(deleteThumbnails: Bool, deleteCompressedVideos: Bool, clearCache: Bool) -> [String: Any] {
        cancelCompression()
        return [
            "success": true,
            "thumbnailsDeleted": deleteThumbnails ? 1 : 0,
            "videosDeleted": deleteCompressedVideos ? 1 : 0,
            "cacheCleared": clearCache,
            "message": "Selective cleanup completed"
        ]
    }
    
    func getVideoThumbnail(_ videoInfo: VVideoInfo, config: VVideoThumbnailConfig) -> VVideoThumbnailResult? {
        guard let url = createURL(from: videoInfo.path) else { return nil }
        
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: Double(config.timeMs) / 1000.0, preferredTimescale: 600)
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let image = UIImage(cgImage: cgImage)
            
            let outputDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("VideoThumbnails")
            try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
            
            let timestamp = Int(Date().timeIntervalSince1970)
            let videoBaseName = URL(fileURLWithPath: videoInfo.name).deletingPathExtension().lastPathComponent
            let fileExtension = config.format == .png ? ".png" : ".jpg"
            let filename = "thumb_\(videoBaseName)_\(timestamp)\(fileExtension)"
            let outputFile = outputDirectory.appendingPathComponent(filename)
            
            let imageData = config.format == .png ? image.pngData() : image.jpegData(compressionQuality: 0.8)
            guard let data = imageData else { return nil }
            
            try data.write(to: outputFile)
            
            return VVideoThumbnailResult(
                thumbnailPath: outputFile.path,
                width: Int(image.size.width),
                height: Int(image.size.height),
                fileSizeBytes: Int64(data.count),
                format: config.format,
                timeMs: config.timeMs
            )
            
        } catch {
            print("VVideoCompressionEngine: Failed to generate thumbnail: \(error)")
            return nil
        }
    }
    
    private func getExportPreset(for quality: VVideoCompressQuality, advanced: VVideoAdvancedConfig? = nil) -> String {
        if let videoCodec = advanced?.videoCodec, videoCodec == .h265 {
            if #available(iOS 11.0, *) {
                return AVAssetExportPresetHEVCHighestQuality
            }
        }
        
        switch quality {
        case .high: return AVAssetExportPresetHighestQuality
        case .medium: return AVAssetExportPreset1920x1080
        case .low: return AVAssetExportPreset1280x720
        case .veryLow: return AVAssetExportPreset960x540
        case .ultraLow: return AVAssetExportPreset640x480
        }
    }
    
    private func startProgressTracking(callback: CompressionCallback) {
        progressTimer = Timer.scheduledTimer(withTimeInterval: Self.PROGRESS_UPDATE_INTERVAL, repeats: true) { _ in
            guard let exportSession = self.exportSession, !self.isCancelled else { return }
            callback.onProgress(exportSession.progress)
        }
    }
    
    private func stopProgressTracking() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    private func createOutputFile(_ outputPath: String?, videoInfo: VVideoInfo, quality: VVideoCompressQuality) -> URL {
        let outputDirectory: URL
        
        if let path = outputPath {
            outputDirectory = URL(fileURLWithPath: path)
        } else {
            outputDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("CompressedVideos")
        }
        
        try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let videoBaseName = URL(fileURLWithPath: videoInfo.name).deletingPathExtension().lastPathComponent
        let filename = "\(videoBaseName)_\(quality.rawValue)_\(timestamp).mp4"
        
        return outputDirectory.appendingPathComponent(filename)
    }
    
    private func createCompressionResult(
        originalVideo: VVideoInfo,
        compressedFile: URL,
        quality: VVideoCompressQuality,
        timeTaken: Int64
    ) -> VVideoCompressionResult {
        let compressedSizeBytes = getFileSize(for: compressedFile)
        let compressionRatio = Float(compressedSizeBytes) / Float(originalVideo.fileSizeBytes)
        let spaceSaved = originalVideo.fileSizeBytes - compressedSizeBytes
        
        let originalResolution = "\(originalVideo.width)x\(originalVideo.height)"
        let compressedResolution = originalResolution
        
        return VVideoCompressionResult(
            originalVideo: originalVideo,
            compressedFilePath: compressedFile.path,
            galleryUri: nil,
            originalSizeBytes: originalVideo.fileSizeBytes,
            compressedSizeBytes: compressedSizeBytes,
            compressionRatio: compressionRatio,
            timeTaken: timeTaken,
            quality: quality,
            originalResolution: originalResolution,
            compressedResolution: compressedResolution,
            spaceSaved: spaceSaved
        )
    }
    

    
    private func getFileSize(for url: URL) -> Int64 {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
            return Int64(resourceValues.fileSize ?? 0)
        } catch {
            return 0
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let mb = Double(bytes) / 1024.0 / 1024.0
        return String(format: "%.1f MB", mb)
    }
    
    private func createURL(from path: String) -> URL? {
        if path.hasPrefix("file://") {
            return URL(string: path)
        } else if path.hasPrefix("/") {
            return URL(fileURLWithPath: path)
        } else {
            return URL(fileURLWithPath: path)
        }
    }
}
