# V Video Compressor

[![pub package](https://img.shields.io/pub/v/v_video_compressor.svg)](https://pub.dev/packages/v_video_compressor)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-blue.svg)](https://flutter.dev)

A professional Flutter plugin for **high-quality video compression** with real-time progress tracking, advanced customization, and comprehensive debugging capabilities.

## ✨ **Key Features**

- ⛔ **NO ffmpeg** this package use native api for compress android **media3** for android and **AVFoundation** for ios
- 🎬 **Professional Video Compression** - Multiple quality levels with advanced customization
- 📊 **Real-Time Progress Tracking** - Smooth progress updates with hybrid estimation algorithm
- 🔧 **Advanced Configuration** - 20+ compression parameters for professional control
- 🖼️ **Thumbnail Generation** - Extract high-quality thumbnails at any timestamp
- 📱 **Cross-Platform** - Full Android & iOS support with native performance
- 🚀 **Batch Processing** - Compress multiple videos with overall progress
- 📝 **Small apk size** - very high speed video compress native side kotlin and swift
- ⛔ **Cancellation Support** - Cancel operations anytime with automatic cleanup
- 📝 **Comprehensive Logging** - Production-ready error tracking and debugging
- 🧪 **Thoroughly Tested** - 95%+ test coverage with mock implementations

## 🎯 **Philosophy**

This plugin **focuses exclusively on video compression** - it does what it does best. For video selection, use established plugins like [`image_picker`](https://pub.dev/packages/image_picker) or [`file_picker`](https://pub.dev/packages/file_picker).

## 📱 **Platform Support**

| Platform    | Support             | Minimum Version        | Notes                           |
| ----------- | ------------------- | ---------------------- | ------------------------------- |
| **Android** | ✅ **Full Support** | API 21+ (Android 5.0+) | Hardware acceleration available |
| **iOS**     | ✅ **Full Support** | iOS 13.0+              | Hardware acceleration available |

### **iOS Version Compatibility**

| iOS Version   | Support Level     | Features                                     |
| ------------- | ----------------- | -------------------------------------------- |
| **iOS 16.0+** | ✅ **Optimal**    | All features, latest APIs                    |
| **iOS 15.0+** | ✅ **Full**       | All features supported                       |
| **iOS 14.0+** | ✅ **Full**       | All features supported                       |
| **iOS 13.0+** | ✅ **Full**       | All features supported                       |
| **iOS 12.0+** | ✅ **Full**       | All features supported                       |
| **iOS 11.0+** | ✅ **Compatible** | Core features, limited hardware acceleration |

**Note**: iOS Simulator has limited hardware acceleration. Test on physical devices for optimal performance.

## 🚀 **Quick Start**

### 1. Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  v_video_compressor: ^1.0.0
  image_picker: ^1.0.7 # For video selection
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
import 'package:image_picker/image_picker.dart';

class VideoCompressionScreen extends StatefulWidget {
  @override
  _VideoCompressionScreenState createState() => _VideoCompressionScreenState();
}

class _VideoCompressionScreenState extends State<VideoCompressionScreen> {
  final VVideoCompressor _compressor = VVideoCompressor();
  final ImagePicker _picker = ImagePicker();

  double _progress = 0.0;
  bool _isCompressing = false;

  Future<void> _compressVideo() async {
    // 1. Pick video using image_picker
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;

    setState(() {
      _isCompressing = true;
      _progress = 0.0;
    });

    try {
      // 2. Compress with progress tracking
      final result = await _compressor.compressVideo(
        video.path,
        VVideoCompressionConfig.medium(),
        onProgress: (progress) {
          setState(() => _progress = progress);
        },
      );

      if (result != null) {
        print('✅ Compression completed!');
        print('Original: ${result.originalSizeFormatted}');
        print('Compressed: ${result.compressedSizeFormatted}');
        print('Space saved: ${result.spaceSavedFormatted}');
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
      appBar: AppBar(title: Text('Video Compressor')),
      body: Center(
        child: _isCompressing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(value: _progress),
                  SizedBox(height: 16),
                  Text('${(_progress * 100).toInt()}%'),
                ],
              )
            : ElevatedButton(
                onPressed: _compressVideo,
                child: Text('Pick & Compress Video'),
              ),
      ),
    );
  }
}
```

## 🎯 **Quality Levels**

Choose the right quality for your use case:

| Quality                          | Resolution | Bitrate Range | File Size  | Use Case                      |
| -------------------------------- | ---------- | ------------- | ---------- | ----------------------------- |
| `VVideoCompressQuality.high`     | 1080p HD   | 8-12 Mbps     | Larger     | Professional, archival        |
| `VVideoCompressQuality.medium`   | 720p       | 4-6 Mbps      | Balanced   | General purpose, social media |
| `VVideoCompressQuality.low`      | 480p       | 1-3 Mbps      | Smaller    | Quick sharing, messaging      |
| `VVideoCompressQuality.veryLow`  | 360p       | 0.5-1.5 Mbps  | Very small | Bandwidth limited             |
| `VVideoCompressQuality.ultraLow` | 240p       | 0.2-0.8 Mbps  | Minimal    | Maximum compression           |

## 🔧 **Advanced Configuration**

### Custom Compression Settings

```dart
final advancedConfig = VVideoAdvancedConfig(
  // Resolution & Quality
  customWidth: 1280,
  customHeight: 720,
  videoBitrate: 4000000,        // 4 Mbps
  frameRate: 30.0,              // 30 FPS

  // Codec & Encoding
  videoCodec: VVideoCodec.h265, // Better compression
  audioCodec: VAudioCodec.aac,
  encodingSpeed: VEncodingSpeed.slow, // Better quality
  crf: 23,                      // Quality factor (lower = better)
  twoPassEncoding: true,        // Best quality
  hardwareAcceleration: true,   // Use GPU

  // Audio Settings
  audioBitrate: 128000,         // 128 kbps
  audioSampleRate: 44100,       // 44.1 kHz
  audioChannels: 2,             // Stereo

  // Effects & Editing
  brightness: 0.1,              // Slight brightness boost
  contrast: 0.05,               // Slight contrast increase
  trimStartMs: 2000,            // Skip first 2 seconds
  trimEndMs: 60000,             // End at 1 minute
  rotation: 90,                 // Rotate 90 degrees
);

final result = await compressor.compressVideo(
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
  targetBitrate: 500000,  // 500 kbps
  keepAudio: false,       // Remove audio
);

// Social media optimized
final socialMedia = VVideoAdvancedConfig.socialMediaOptimized();

// Mobile optimized
final mobile = VVideoAdvancedConfig.mobileOptimized();
```

## 🖼️ **Thumbnail Generation**

### Single Thumbnail

```dart
final thumbnail = await compressor.getVideoThumbnail(
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
}
```

### Multiple Thumbnails

```dart
final thumbnails = await compressor.getVideoThumbnails(
  videoPath,
  [
    VVideoThumbnailConfig(timeMs: 1000, maxWidth: 150),   // 1s
    VVideoThumbnailConfig(timeMs: 5000, maxWidth: 150),   // 5s
    VVideoThumbnailConfig(timeMs: 10000, maxWidth: 150),  // 10s
  ],
);

print('Generated ${thumbnails.length} thumbnails');
```

## 📊 **Batch Processing**

Compress multiple videos with overall progress tracking:

```dart
final results = await compressor.compressVideos(
  [videoPath1, videoPath2, videoPath3],
  VVideoCompressionConfig.medium(),
  onProgress: (progress, currentIndex, total) {
    print('Overall: ${(progress * 100).toInt()}% (${currentIndex + 1}/$total)');
  },
);

print('Successfully compressed ${results.length} videos');
```

## 🔍 **Compression Estimation**

Get size estimates before compression:

```dart
final estimate = await compressor.getCompressionEstimate(
  videoPath,
  VVideoCompressQuality.medium,
  advanced: advancedConfig,
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
await compressor.cancelCompression();

// Check if compression is running
final isActive = await compressor.isCompressing();

// Handle cancellation in UI
if (isActive) {
  await compressor.cancelCompression();
  // Files are automatically cleaned up
}
```

## 🧹 **Resource Management**

### Complete Cleanup

```dart
// Clean everything when app closes
@override
void dispose() {
  compressor.cleanup();
  super.dispose();
}
```

### Selective Cleanup

```dart
// Safe cleanup - keep compressed videos
await compressor.cleanupFiles(
  deleteThumbnails: true,
  deleteCompressedVideos: false,  // Keep compressed videos
  clearCache: true,
);

// Full cleanup - ⚠️ removes all compressed videos
await compressor.cleanupFiles(
  deleteThumbnails: true,
  deleteCompressedVideos: true,   // ⚠️ This deletes your videos!
  clearCache: true,
);
```

## 📝 **Comprehensive API Reference**

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
  final result = await compressor.compressVideo(videoPath, config);
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
- **Hardware Acceleration**: Available on most devices
- **Permissions**: Automatically handled for Android 13+
- **Background**: Full background compression support

### iOS

- **Minimum Version**: iOS 11.0
- **Hardware Acceleration**: Available on iOS 11+
- **Simulator**: Limited acceleration (test on devices)
- **Background**: May be limited by iOS background execution policies

## 🔧 **Troubleshooting**

### Common Issues

**1. Compression fails silently**

- Check file permissions and paths
- Verify video file is not corrupted
- Check device storage space

**2. Progress not updating**

- Ensure you're calling `setState()` in progress callback
- Check if compression is actually running

**3. iOS simulator issues**

- Hardware acceleration unavailable in simulator
- Test on physical iOS devices for accurate results

**4. Large file handling**

- Very large files (>4GB) may require more memory
- Consider breaking into smaller segments

### Debug Logging

The plugin provides comprehensive logging. To view logs:

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
- **[Advanced Guide](example/ADVANCED_COMPRESSION_GUIDE.md)** - Professional compression techniques
- **[iOS Integration](example/IOS_ADVANCED_FEATURES_GUIDE.md)** - iOS-specific features and tips
- **[Testing Guide](example/TESTING_GUIDE.md)** - Testing your compression workflow

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
