# V Video Compressor

[![pub package](https://img.shields.io/pub/v/v_video_compressor.svg)](https://pub.dev/packages/v_video_compressor)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-blue.svg)](https://flutter.dev)

A **professional Flutter plugin** for high-quality video compression with real-time progress tracking, thumbnail generation, and comprehensive configuration options.

## ✨ **Key Features**

- 🎬 **Professional Video Compression** - 5 quality levels with native platform APIs (Media3 for Android, AVFoundation for iOS)
- 📊 **Real-Time Progress Tracking** - Smooth progress updates with hybrid estimation algorithm
- 🔧 **Advanced Configuration** - 20+ compression parameters for professional control
- 🖼️ **Thumbnail Generation** - Extract high-quality thumbnails at any timestamp
- 📱 **Cross-Platform** - Full Android & iOS support with hardware acceleration
- 🚀 **Batch Processing** - Compress multiple videos with overall progress tracking
- ⛔ **Cancellation Support** - Cancel operations anytime with automatic cleanup
- 📝 **Comprehensive Logging** - Production-ready error tracking and debugging
- 🧪 **Thoroughly Tested** - 95%+ test coverage with complete mock implementations
- ⚡ **No ffmpeg** - Uses native APIs for optimal performance and smaller app size

## 🎯 **Philosophy**

This plugin **focuses exclusively on video compression and thumbnail generation**. For video selection, use established plugins like [`image_picker`](https://pub.dev/packages/image_picker) or [`file_picker`](https://pub.dev/packages/file_picker).

## 📱 **Platform Support**

| Platform    | Support             | Minimum Version        | Notes                           |
| ----------- | ------------------- | ---------------------- | ------------------------------- |
| **Android** | ✅ **Full Support** | API 21+ (Android 5.0+) | Hardware acceleration available |
| **iOS**     | ✅ **Full Support** | iOS 11.0+              | Hardware acceleration available |

## 🚀 **Quick Start**

### 1. Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  v_video_compressor: ^1.0.3
  file_picker: ^8.0.0 # For video selection
  # OR
  image_picker: ^1.0.7 # Alternative for video selection
```

### 2. Platform Setup

#### Android Setup

Add permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="28" />
```

#### iOS Setup

Add permissions to `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to photo library to compress videos</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app needs access to save compressed videos to photo library</string>
```

### 3. Basic Usage

```dart
import 'package:v_video_compressor/v_video_compressor.dart';
import 'package:file_picker/file_picker.dart';

class VideoCompressionExample extends StatefulWidget {
  @override
  _VideoCompressionExampleState createState() => _VideoCompressionExampleState();
}

class _VideoCompressionExampleState extends State<VideoCompressionExample> {
  final VVideoCompressor _compressor = VVideoCompressor();

  double _progress = 0.0;
  bool _isCompressing = false;

  Future<void> _compressVideo() async {
    // 1. Pick video using file_picker
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result == null || result.files.single.path == null) return;

    final videoPath = result.files.single.path!;

    setState(() {
      _isCompressing = true;
      _progress = 0.0;
    });

    try {
      // 2. Compress with progress tracking
      final compressionResult = await _compressor.compressVideo(
        videoPath,
        const VVideoCompressionConfig.medium(),
        onProgress: (progress) {
          setState(() => _progress = progress);
        },
      );

      if (compressionResult != null) {
        print('✅ Compression completed!');
        print('Original: ${compressionResult.originalSizeFormatted}');
        print('Compressed: ${compressionResult.compressedSizeFormatted}');
        print('Space saved: ${compressionResult.spaceSavedFormatted}');
        print('Output path: ${compressionResult.outputPath}');
      }
    } catch (e) {
      print('❌ Compression failed: $e');
    } finally {
      setState(() => _isCompressing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Compressor')),
      body: Center(
        child: _isCompressing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(value: _progress),
                  const SizedBox(height: 16),
                  Text('${(_progress * 100).toInt()}%'),
                ],
              )
            : ElevatedButton(
                onPressed: _compressVideo,
                child: const Text('Pick & Compress Video'),
              ),
      ),
    );
  }
}
```

## 🎯 **Quality Levels**

Choose the right quality for your use case:

| Quality                          | Resolution | Typical Bitrate | File Size  | Use Case                      |
| -------------------------------- | ---------- | --------------- | ---------- | ----------------------------- |
| `VVideoCompressQuality.high`     | 1080p HD   | 3.5 Mbps        | Larger     | Professional, archival        |
| `VVideoCompressQuality.medium`   | 720p       | 1.8 Mbps        | Balanced   | General purpose, social media |
| `VVideoCompressQuality.low`      | 480p       | 900 kbps        | Smaller    | Quick sharing, messaging      |
| `VVideoCompressQuality.veryLow`  | 360p       | 500 kbps        | Very small | Bandwidth limited             |
| `VVideoCompressQuality.ultraLow` | 240p       | 350 kbps        | Minimal    | Maximum compression           |

## 🔧 **Advanced Configuration**

### Custom Compression Settings

```dart
final advancedConfig = VVideoAdvancedConfig(
  // Resolution & Quality
  customWidth: 1280,
  customHeight: 720,
  videoBitrate: 2000000,        // 2 Mbps
  frameRate: 30.0,              // 30 FPS

  // Codec & Encoding
  videoCodec: VVideoCodec.h265, // Better compression
  audioCodec: VAudioCodec.aac,
  encodingSpeed: VEncodingSpeed.medium,
  crf: 25,                      // Quality factor (lower = better)
  twoPassEncoding: true,        // Better quality
  hardwareAcceleration: true,   // Use GPU

  // Audio Settings
  audioBitrate: 128000,         // 128 kbps
  audioSampleRate: 44100,       // 44.1 kHz
  audioChannels: 2,             // Stereo

  // Video Effects
  brightness: 0.1,              // Slight brightness boost
  contrast: 0.05,               // Slight contrast increase
  saturation: 0.1,              // Slight saturation increase

  // Editing
  trimStartMs: 2000,            // Skip first 2 seconds
  trimEndMs: 60000,             // End at 1 minute
  rotation: 90,                 // Rotate 90 degrees
);

final result = await _compressor.compressVideo(
  videoPath,
  VVideoCompressionConfig(
    quality: VVideoCompressQuality.medium,
    advanced: advancedConfig,
  ),
);
```

### Preset Configurations

```dart
// Maximum compression for smallest files
final maxCompression = VVideoAdvancedConfig.maximumCompression(
  targetBitrate: 300000,  // 300 kbps
  keepAudio: false,       // Remove audio
);

// Social media optimized
final socialMedia = VVideoAdvancedConfig.socialMediaOptimized();

// Mobile optimized
final mobile = VVideoAdvancedConfig.mobileOptimized();

final result = await _compressor.compressVideo(
  videoPath,
  VVideoCompressionConfig(
    quality: VVideoCompressQuality.medium,
    advanced: maxCompression, // Use preset
  ),
);
```

### Advanced Configuration Options

The `VVideoAdvancedConfig` class provides fine-grained control over the compression process:

#### 🔄 **NEW: Automatic Orientation Correction**

```dart
// Fix for vertical videos appearing horizontal after compression
VVideoAdvancedConfig(
  autoCorrectOrientation: true,  // Preserves original video orientation
  videoBitrate: 1500000,
  audioBitrate: 128000,
)
```

**Key Features:**

- ✅ **Automatic Detection**: Detects original video orientation metadata
- ✅ **Vertical Video Fix**: Prevents vertical videos from appearing horizontal
- ✅ **Cross-Platform**: Works on both Android and iOS
- ✅ **No Quality Loss**: Maintains video quality while preserving orientation

#### Other Advanced Options

```dart
VVideoAdvancedConfig(
  videoBitrate: 1500000,        // Custom video bitrate
  audioBitrate: 128000,         // Custom audio bitrate
  customWidth: 1280,            // Custom width (use with height)
  customHeight: 720,            // Custom height (use with width)
  rotation: 90,                 // Manual rotation (0, 90, 180, 270)
  frameRate: 30.0,              // Target frame rate
  removeAudio: false,           // Remove audio track
  brightness: 0.1,              // Brightness adjustment (-1.0 to 1.0)
  contrast: 0.1,                // Contrast adjustment (-1.0 to 1.0)
  autoCorrectOrientation: true, // NEW: Auto-correct orientation
  // ... other options
)
```

## 🖼️ **Thumbnail Generation**

### Single Thumbnail

```dart
final thumbnail = await _compressor.getVideoThumbnail(
  videoPath,
  VVideoThumbnailConfig(
    timeMs: 5000,                    // 5 seconds into video
    maxWidth: 300,
    maxHeight: 200,
    format: VThumbnailFormat.jpeg,
    quality: 85,                     // JPEG quality (0-100)
  ),
);

if (thumbnail != null) {
  print('Thumbnail: ${thumbnail.thumbnailPath}');
  print('Size: ${thumbnail.width}x${thumbnail.height}');
  print('File size: ${thumbnail.fileSizeFormatted}');
}
```

### Multiple Thumbnails

```dart
final thumbnails = await _compressor.getVideoThumbnails(
  videoPath,
  [
    VVideoThumbnailConfig(timeMs: 1000, maxWidth: 150),   // 1s
    VVideoThumbnailConfig(timeMs: 5000, maxWidth: 150),   // 5s
    VVideoThumbnailConfig(timeMs: 10000, maxWidth: 150),  // 10s
  ],
);

print('Generated ${thumbnails.length} thumbnails');
for (final thumbnail in thumbnails) {
  print('${thumbnail.timeMs}ms: ${thumbnail.thumbnailPath}');
}
```

## 📊 **Batch Processing**

Compress multiple videos with overall progress tracking:

```dart
final results = await _compressor.compressVideos(
  [videoPath1, videoPath2, videoPath3],
  const VVideoCompressionConfig.medium(),
  onProgress: (progress, currentIndex, total) {
    print('Overall: ${(progress * 100).toInt()}% (${currentIndex + 1}/$total)');
  },
);

print('Successfully compressed ${results.length} videos');
for (final result in results) {
  print('${result.originalPath} → ${result.outputPath}');
  print('Space saved: ${result.spaceSavedFormatted}');
}
```

## 🔍 **Video Information & Compression Estimation**

### Get Video Information

```dart
final videoInfo = await _compressor.getVideoInfo(videoPath);
if (videoInfo != null) {
  print('Duration: ${videoInfo.durationFormatted}');
  print('Resolution: ${videoInfo.width}x${videoInfo.height}');
  print('File size: ${videoInfo.fileSizeFormatted}');
}
```

### Estimate Compression Size

```dart
final estimate = await _compressor.getCompressionEstimate(
  videoPath,
  VVideoCompressQuality.medium,
  advanced: advancedConfig, // Optional
);

if (estimate != null) {
  print('Estimated size: ${estimate.estimatedSizeFormatted}');
  print('Compression ratio: ${(estimate.compressionRatio * 100).toInt()}%');
  print('Expected bitrate: ${estimate.bitrateMbps.toStringAsFixed(1)} Mbps');
}
```

## ⛔ **Cancellation Support**

Cancel operations anytime:

```dart
// Cancel ongoing compression
await _compressor.cancelCompression();

// Check if compression is running
final isActive = await _compressor.isCompressing();

// Handle cancellation in UI
if (isActive) {
  await _compressor.cancelCompression();
  // Files are automatically cleaned up
}
```

## 🧹 **Resource Management**

### Complete Cleanup

```dart
// Clean everything when app closes
@override
void dispose() {
  _compressor.cleanup();
  super.dispose();
}
```

### Selective Cleanup

```dart
// Safe cleanup - keep compressed videos
await _compressor.cleanupFiles(
  deleteThumbnails: true,
  deleteCompressedVideos: false,  // Keep compressed videos
  clearCache: true,
);

// Full cleanup - ⚠️ removes all compressed videos
await _compressor.cleanupFiles(
  deleteThumbnails: true,
  deleteCompressedVideos: true,   // ⚠️ This deletes your videos!
  clearCache: true,
);
```

## 📝 **Complete API Reference**

### Core Methods

```dart
// Video information
Future<VVideoInfo?> getVideoInfo(String videoPath);

// Compression estimation
Future<VVideoCompressionEstimate?> getCompressionEstimate(
  String videoPath,
  VVideoCompressQuality quality,
  {VVideoAdvancedConfig? advanced}
);

// Single video compression
Future<VVideoCompressionResult?> compressVideo(
  String videoPath,
  VVideoCompressionConfig config,
  {Function(double progress)? onProgress}
);

// Batch compression
Future<List<VVideoCompressionResult>> compressVideos(
  List<String> videoPaths,
  VVideoCompressionConfig config,
  {Function(double progress, int currentIndex, int total)? onProgress}
);

// Control operations
Future<void> cancelCompression();
Future<bool> isCompressing();
```

### Thumbnail Methods

```dart
// Single thumbnail
Future<VVideoThumbnailResult?> getVideoThumbnail(
  String videoPath,
  VVideoThumbnailConfig config
);

// Multiple thumbnails
Future<List<VVideoThumbnailResult>> getVideoThumbnails(
  String videoPath,
  List<VVideoThumbnailConfig> configs
);
```

### Cleanup Methods

```dart
// Complete cleanup
Future<void> cleanup();

// Selective cleanup
Future<void> cleanupFiles({
  bool deleteThumbnails = true,
  bool deleteCompressedVideos = false,
  bool clearCache = true,
});
```

## 🚫 **Error Handling**

The plugin provides comprehensive error handling and logging:

```dart
try {
  final result = await _compressor.compressVideo(videoPath, config);
  if (result == null) {
    print('Compression failed - check logs for details');
  }
} catch (e, stackTrace) {
  print('Error: $e');
  print('Stack trace: $stackTrace');

  // The plugin automatically logs detailed error information
  // Check your development console for full context
}
```

## 📱 **Platform-Specific Notes**

### Android

- **Minimum API**: Android 5.0 (API 21)
- **Hardware Acceleration**: Available on most devices with Media3
- **Permissions**: Automatically handled for Android 13+
- **Background**: Full background compression support

### iOS

- **Minimum Version**: iOS 11.0
- **Hardware Acceleration**: Available with AVFoundation
- **Simulator**: Limited acceleration (test on devices for best results)
- **Background**: May be limited by iOS background execution policies

## 🔧 **Troubleshooting**

### Common Issues

**1. Compression fails silently**

- Check file permissions and paths
- Verify video file is not corrupted
- Check device storage space

**2. Progress not updating**

- Ensure you're calling `setState()` in progress callback
- Check if compression is actually running with `isCompressing()`

**3. iOS simulator issues**

- Hardware acceleration unavailable in simulator
- Test on physical iOS devices for accurate results

**4. Large file handling**

- Very large files (>4GB) may require more memory
- Consider using lower quality settings for large files

### Debug Logging

The plugin provides comprehensive logging:

```dart
// Logs are automatically output to console with tag 'VVideoCompressor'
// Filter logs by tag to see only plugin-related messages
```

## 🎨 **Example Projects**

Check the [example directory](example/) for complete sample applications:

- **Basic compression** with progress tracking
- **Advanced configuration** examples
- **Thumbnail generation** demos
- **Batch processing** implementation
- **UI integration** patterns

## 📚 **Additional Resources**

- **[API Documentation](https://pub.dev/documentation/v_video_compressor)** - Complete API reference
- **[Memory Optimization Guide](MEMORY_OPTIMIZATION_GUIDE.md)** - Critical for production apps
- **[Advanced Features Guide](ADVANCED_FEATURES_SUPPORT.md)** - Detailed feature matrix
- **[Android Quick Fix Guide](ANDROID_QUICK_FIX.md)** - Android-specific issues
- **[iOS Quick Fix Guide](IOS_QUICK_FIX.md)** - iOS-specific issues

## ⚠️ **Important Notes**

### Memory Management

Video compression is memory-intensive. For production apps, please read our [Memory Optimization Guide](MEMORY_OPTIMIZATION_GUIDE.md) to avoid OutOfMemoryError issues. Key recommendations:

- Always check available memory before compression
- Use lower quality settings for devices with < 2GB RAM
- Implement progressive quality fallback
- Process videos in batches for bulk operations

## 🤝 **Contributing**

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

```bash
git clone https://github.com/your-repo/v_video_compressor.git
cd v_video_compressor
flutter pub get
cd example && flutter pub get
```

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔮 **Roadmap**

- **1.1.0**: Enhanced progress algorithms and additional presets
- **1.2.0**: Video filtering and advanced effects
- **1.3.0**: Cloud storage integration helpers
- **2.0.0**: Performance improvements with breaking changes

## 📞 **Support**

- **Issues**: [GitHub Issues](https://github.com/your-repo/v_video_compressor/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-repo/v_video_compressor/discussions)
- **Documentation**: [pub.dev](https://pub.dev/packages/v_video_compressor)

---

**Made with ❤️ for the Flutter community**
