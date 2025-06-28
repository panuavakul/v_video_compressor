# iOS Compression Engine - Quick Fix Implementation

## 🔧 Immediate Improvements for iOS

### 1. **Add Custom Bitrate Support Using AVAssetReaderOutput**

Since iOS export presets are limited, implement a custom compression approach:

```swift
private func createVideoOutputSettings(
    for quality: VVideoCompressQuality,
    advanced: VVideoAdvancedConfig?
) -> [String: Any] {
    var settings: [String: Any] = [:]

    // Set codec
    let codec = advanced?.videoCodec == .h265 ? AVVideoCodecType.hevc : AVVideoCodecType.h264
    settings[AVVideoCodecKey] = codec

    // Set bitrate
    let bitrate = advanced?.videoBitrate ?? getDefaultBitrate(for: quality)
    settings[AVVideoAverageBitRateKey] = bitrate

    // Set dimensions
    if let width = advanced?.customWidth, let height = advanced?.customHeight {
        settings[AVVideoWidthKey] = width
        settings[AVVideoHeightKey] = height
    }

    // Compression properties
    settings[AVVideoCompressionPropertiesKey] = [
        AVVideoAverageBitRateKey: bitrate,
        AVVideoExpectedSourceFrameRateKey: advanced?.frameRate ?? 30,
        AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
    ]

    return settings
}

private func getDefaultBitrate(for quality: VVideoCompressQuality) -> Int {
    switch quality {
    case .high: return 3500000      // 3.5 Mbps
    case .medium: return 1800000    // 1.8 Mbps
    case .low: return 900000        // 900 kbps
    case .veryLow: return 500000    // 500 kbps
    case .ultraLow: return 350000   // 350 kbps
    }
}
```

### 2. **Implement Custom Compression with AVAssetWriter**

Replace the export session approach for more control:

```swift
func compressVideoWithWriter(
    _ videoInfo: VVideoInfo,
    config: VVideoCompressionConfig,
    callback: CompressionCallback
) {
    guard let inputURL = createURL(from: videoInfo.path) else {
        callback.onError("Invalid video path")
        return
    }

    let asset = AVAsset(url: inputURL)
    let outputURL = createOutputFile(config.outputPath, videoInfo: videoInfo, quality: config.quality)

    // Remove existing file
    try? FileManager.default.removeItem(at: outputURL)

    guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
        callback.onError("Failed to create writer")
        return
    }

    // Video settings
    let videoSettings = createVideoOutputSettings(for: config.quality, advanced: config.advanced)
    let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
    writerInput.expectsMediaDataInRealTime = false

    // Add video input
    if writer.canAdd(writerInput) {
        writer.add(writerInput)
    }

    // Audio settings (if not removing audio)
    var audioInput: AVAssetWriterInput?
    if config.advanced?.removeAudio != true {
        let audioSettings = createAudioOutputSettings(config: config)
        audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        if let audio = audioInput, writer.canAdd(audio) {
            writer.add(audio)
        }
    }

    // Start compression
    writer.startWriting()
    writer.startSession(atSourceTime: .zero)

    // Process video and audio tracks
    processVideoTrack(asset: asset, writer: writer, input: writerInput) { videoSuccess in
        if let audioInput = audioInput {
            self.processAudioTrack(asset: asset, writer: writer, input: audioInput) { audioSuccess in
                self.finishWriting(writer: writer, outputURL: outputURL, callback: callback)
            }
        } else {
            self.finishWriting(writer: writer, outputURL: outputURL, callback: callback)
        }
    }
}
```

### 3. **Add Frame Rate Control**

Implement frame dropping for lower frame rates:

```swift
private func processVideoWithFrameRateReduction(
    reader: AVAssetReader,
    writer: AVAssetWriter,
    targetFrameRate: Float
) {
    let sourceFrameRate: Float = 30.0 // Get from video track
    let frameDropRatio = targetFrameRate / sourceFrameRate
    var frameCount = 0

    while reader.status == .reading {
        if let sampleBuffer = readerOutput.copyNextSampleBuffer() {
            // Drop frames based on ratio
            if Float(frameCount) * frameDropRatio >= Float(Int(Float(frameCount) * frameDropRatio)) {
                // Keep this frame
                if writerInput.isReadyForMoreMediaData {
                    writerInput.append(sampleBuffer)
                }
            }
            frameCount += 1
        }
    }
}
```

### 4. **Improve Progress Tracking**

Add more accurate progress tracking:

```swift
private func startProgressTracking(
    reader: AVAssetReader,
    asset: AVAsset,
    callback: CompressionCallback
) {
    let duration = CMTimeGetSeconds(asset.duration)

    progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
        guard reader.status == .reading else { return }

        if let output = reader.outputs.first as? AVAssetReaderTrackOutput,
           let lastSampleBuffer = output.copyNextSampleBuffer() {
            let currentTime = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(lastSampleBuffer))
            let progress = Float(currentTime / duration)
            callback.onProgress(min(progress, 0.98)) // Never report 100% until complete
        }
    }
}
```

### 5. **Add Audio Configuration**

Create custom audio settings:

```swift
private func createAudioOutputSettings(config: VVideoCompressionConfig) -> [String: Any] {
    var settings: [String: Any] = [
        AVFormatIDKey: kAudioFormatMPEG4AAC
    ]

    // Bitrate
    let audioBitrate = config.advanced?.audioBitrate ?? 128000
    settings[AVEncoderBitRateKey] = audioBitrate

    // Sample rate
    let sampleRate = config.advanced?.audioSampleRate ?? 44100
    settings[AVSampleRateKey] = sampleRate

    // Channels
    let channels = config.advanced?.monoAudio == true ? 1 :
                   (config.advanced?.audioChannels ?? 2)
    settings[AVNumberOfChannelsKey] = channels

    // Quality
    settings[AVEncoderAudioQualityKey] = AVAudioQuality.high.rawValue

    return settings
}
```

### 6. **Better Estimation**

Improve size estimation accuracy:

```swift
func estimateCompressionSize(
    _ videoInfo: VVideoInfo,
    quality: VVideoCompressQuality,
    advanced: VVideoAdvancedConfig?
) -> VVideoCompressionEstimate {
    let durationSeconds = Double(videoInfo.durationMillis) / 1000.0

    // Get video bitrate
    var videoBitrate = advanced?.videoBitrate ?? getDefaultBitrate(for: quality)

    // Adjust for resolution change
    if let customWidth = advanced?.customWidth,
       let customHeight = advanced?.customHeight {
        let originalPixels = videoInfo.width * videoInfo.height
        let targetPixels = customWidth * customHeight
        let pixelRatio = Float(targetPixels) / Float(originalPixels)
        videoBitrate = Int(Float(videoBitrate) * pixelRatio * 1.1)
    }

    // Adjust for frame rate
    if let frameRate = advanced?.reducedFrameRate {
        let frameRateRatio = frameRate / 30.0
        videoBitrate = Int(Float(videoBitrate) * frameRateRatio)
    }

    // Audio bitrate
    let audioBitrate = advanced?.removeAudio == true ? 0 :
                      (advanced?.audioBitrate ?? 128000)

    // Calculate size
    let totalBitrate = videoBitrate + audioBitrate
    let estimatedBytes = Int64((Double(totalBitrate) * durationSeconds) / 8.0)

    // Add 5% overhead
    let finalEstimate = Int64(Double(estimatedBytes) * 1.05)

    return VVideoCompressionEstimate(
        estimatedSizeBytes: finalEstimate,
        estimatedSizeFormatted: formatFileSize(finalEstimate),
        compressionRatio: Float(finalEstimate) / Float(videoInfo.fileSizeBytes),
        bitrateMbps: Float(videoBitrate) / 1000000.0
    )
}
```

## 🚀 Quick Implementation Steps

### Step 1: Add H.265 Support Check

```swift
private func isHEVCSupported() -> Bool {
    if #available(iOS 11.0, *) {
        return AVAssetExportSession.allExportPresets().contains(AVAssetExportPresetHEVCHighestQuality)
    }
    return false
}

// In getExportPreset:
if let videoCodec = advanced?.videoCodec, videoCodec == .h265 {
    if isHEVCSupported() {
        switch quality {
        case .high: return AVAssetExportPresetHEVCHighestQuality
        case .medium, .low: return AVAssetExportPresetHEVC1920x1080
        case .veryLow, .ultraLow: return AVAssetExportPresetHEVC1920x1080
        }
    }
}
```

### Step 2: Add Simple Color Adjustment

```swift
// In applyAdvancedComposition, improve color adjustments:
if let brightness = config.advanced?.brightness,
   let contrast = config.advanced?.contrast,
   let saturation = config.advanced?.saturation {

    // Create filter
    let filter = CIFilter(name: "CIColorControls")!
    filter.setValue(brightness, forKey: kCIInputBrightnessKey)
    filter.setValue(1.0 + contrast, forKey: kCIInputContrastKey)
    filter.setValue(1.0 + saturation, forKey: kCIInputSaturationKey)

    // Apply to composition
    videoComposition.colorFilter = filter
}
```

### Step 3: Optimize Export Settings

```swift
// Add these optimizations to export session:
exportSession.shouldOptimizeForNetworkUse = true
exportSession.canPerformMultiplePassesOverSourceMediaData = true

// For metadata
var metadata = [AVMetadataItem]()
let item = AVMutableMetadataItem()
item.key = AVMetadataKey.commonKeyTitle as NSString
item.keySpace = .common
item.value = "Compressed with V Video Compressor" as NSString
metadata.append(item)
exportSession.metadata = metadata
```

### Step 4: Better Error Handling

```swift
private func getDetailedError(from error: Error?) -> String {
    guard let error = error as NSError? else {
        return "Unknown error occurred"
    }

    switch error.code {
    case AVError.Code.fileAlreadyExists.rawValue:
        return "Output file already exists"
    case AVError.Code.diskFull.rawValue:
        return "Not enough storage space"
    case AVError.Code.sessionNotRunning.rawValue:
        return "Compression session failed to start"
    case AVError.Code.deviceNotConnected.rawValue:
        return "Required device not available"
    case AVError.Code.noDataCaptured.rawValue:
        return "No video data found"
    case AVError.Code.fileFormatNotRecognized.rawValue:
        return "Video format not supported"
    case AVError.Code.contentIsProtected.rawValue:
        return "Video is DRM protected"
    default:
        return error.localizedDescription
    }
}
```

## ⚡ Performance Optimizations

### 1. **Reduce Memory Usage**

```swift
// Use autorelease pool for processing
autoreleasepool {
    // Process video frames
}

// Release resources immediately
asset.cancelLoading()
```

### 2. **Background Processing**

```swift
// Move heavy processing to background queue
DispatchQueue.global(qos: .userInitiated).async {
    // Compression work
    DispatchQueue.main.async {
        // UI updates
    }
}
```

### 3. **Optimize Asset Loading**

```swift
// Load only necessary tracks
let options = [AVURLAssetPreferPreciseDurationAndTimingKey: false]
let asset = AVURLAsset(url: url, options: options)

// Preload specific keys
asset.loadValuesAsynchronously(forKeys: ["tracks", "duration"]) {
    // Process when ready
}
```

## 📋 Testing Priorities

1. ✅ Test AVAssetWriter implementation vs Export Session
2. ✅ Verify H.265 support across iOS versions
3. ✅ Test custom bitrate effectiveness
4. ✅ Verify audio configuration works correctly
5. ✅ Check memory usage with large files
6. ✅ Test progress accuracy
7. ✅ Verify color adjustments

## 🎯 Expected Improvements

- **File Size**: 20-40% smaller with custom bitrates
- **Quality**: Better control over output quality
- **Speed**: Similar or slightly faster processing
- **Features**: Full audio control, better progress tracking
- **Compatibility**: Works on iOS 13+

These quick fixes will significantly improve iOS compression while maintaining stability and compatibility.
