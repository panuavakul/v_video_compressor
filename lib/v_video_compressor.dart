/// V Video Compressor - A focused Flutter plugin for efficient video compression
///
/// This plugin provides:
/// - High-quality video compression with multiple quality levels
/// - Real-time progress tracking with smooth updates
/// - Advanced customization options for professional use
/// - Thumbnail generation from video files
/// - Batch compression capabilities
/// - Comprehensive error handling and configurable logging
///
/// Version: 1.0.0
/// Author: V Chat SDK Team
/// License: MIT
library;

import 'src/v_video_logger.dart';
import 'v_video_compressor_platform_interface.dart';

// Export all public APIs
export 'src/v_video_logger.dart' show VVideoLogConfig, VVideoLogLevel;
export 'src/v_video_models.dart';

/// Compression quality levels
enum VVideoCompressQuality {
  high('HIGH', '1080p HD', 'High quality with better file size'),
  medium('MEDIUM', '720p', 'Balanced quality and compression'),
  low('LOW', '480p', 'Good compression for sharing'),
  veryLow('VERY_LOW', '360p', 'High compression, smaller files'),
  ultraLow('ULTRA_LOW', '240p', 'Maximum compression, smallest files');

  const VVideoCompressQuality(this.value, this.displayName, this.description);

  final String value;
  final String displayName;
  final String description;
}

/// Video codec types
enum VVideoCodec {
  h264('H264', 'H.264/AVC', 'Standard codec, widely compatible'),
  h265('H265', 'H.265/HEVC', 'Better compression, newer devices');

  const VVideoCodec(this.value, this.displayName, this.description);

  final String value;
  final String displayName;
  final String description;
}

/// Audio codec types
enum VAudioCodec {
  aac('AAC', 'AAC', 'Standard audio codec'),
  mp3('MP3', 'MP3', 'Universal compatibility');

  const VAudioCodec(this.value, this.displayName, this.description);

  final String value;
  final String displayName;
  final String description;
}

/// Encoding speed vs quality tradeoff
enum VEncodingSpeed {
  ultrafast('ULTRAFAST', 'Ultra Fast', 'Fastest encoding, larger file'),
  superfast('SUPERFAST', 'Super Fast', 'Very fast encoding'),
  veryfast('VERYFAST', 'Very Fast', 'Fast encoding, good for real-time'),
  faster('FASTER', 'Faster', 'Faster than default'),
  fast('FAST', 'Fast', 'Fast encoding'),
  medium('MEDIUM', 'Medium', 'Balanced speed and quality'),
  slow('SLOW', 'Slow', 'Better quality, slower'),
  slower('SLOWER', 'Slower', 'High quality, slow'),
  veryslow('VERYSLOW', 'Very Slow', 'Best quality, very slow');

  const VEncodingSpeed(this.value, this.displayName, this.description);

  final String value;
  final String displayName;
  final String description;
}

/// Advanced video compression configuration
class VVideoAdvancedConfig {
  /// Custom video bitrate in bits per second (overrides quality preset)
  final int? videoBitrate;

  /// Custom audio bitrate in bits per second
  final int? audioBitrate;

  /// Custom resolution width (must be used with height)
  final int? customWidth;

  /// Custom resolution height (must be used with width)
  final int? customHeight;

  /// Target frame rate (FPS)
  final double? frameRate;

  /// Video codec selection
  final VVideoCodec? videoCodec;

  /// Audio codec selection
  final VAudioCodec? audioCodec;

  /// Encoding speed vs quality tradeoff
  final VEncodingSpeed? encodingSpeed;

  /// Constant Rate Factor (0-51, lower = better quality)
  final int? crf;

  /// Enable two-pass encoding for better quality
  final bool? twoPassEncoding;

  /// Enable hardware acceleration
  final bool? hardwareAcceleration;

  /// Trim video - start time in milliseconds
  final int? trimStartMs;

  /// Trim video - end time in milliseconds
  final int? trimEndMs;

  /// Rotate video (degrees: 0, 90, 180, 270)
  final int? rotation;

  /// Audio sample rate in Hz
  final int? audioSampleRate;

  /// Audio channels (1 = mono, 2 = stereo)
  final int? audioChannels;

  /// Remove audio track completely
  final bool? removeAudio;

  /// Video brightness adjustment (-1.0 to 1.0)
  final double? brightness;

  /// Video contrast adjustment (-1.0 to 1.0)
  final double? contrast;

  /// Video saturation adjustment (-1.0 to 1.0)
  final double? saturation;

  /// Enable variable bitrate for better compression efficiency
  final bool? variableBitrate;

  /// Keyframe interval in seconds (larger = better compression)
  final int? keyframeInterval;

  /// Number of B-frames for better encoding efficiency (0-16)
  final int? bFrames;

  /// Automatically reduce frame rate for smaller files
  final double? reducedFrameRate;

  /// Enable all aggressive compression settings
  final bool? aggressiveCompression;

  /// Apply noise reduction preprocessing
  final bool? noiseReduction;

  /// Convert audio to mono for smaller file size
  final bool? monoAudio;

  const VVideoAdvancedConfig({
    this.videoBitrate,
    this.audioBitrate,
    this.customWidth,
    this.customHeight,
    this.frameRate,
    this.videoCodec,
    this.audioCodec,
    this.encodingSpeed,
    this.crf,
    this.twoPassEncoding,
    this.hardwareAcceleration,
    this.trimStartMs,
    this.trimEndMs,
    this.rotation,
    this.audioSampleRate,
    this.audioChannels,
    this.removeAudio,
    this.brightness,
    this.contrast,
    this.saturation,
    this.variableBitrate,
    this.keyframeInterval,
    this.bFrames,
    this.reducedFrameRate,
    this.aggressiveCompression,
    this.noiseReduction,
    this.monoAudio,
  });

  /// Validates the advanced configuration
  bool isValid() {
    // Both width and height must be specified together
    if ((customWidth != null) != (customHeight != null)) {
      return false;
    }

    // Resolution must be positive and even numbers
    if (customWidth != null && customHeight != null) {
      if (customWidth! <= 0 ||
          customHeight! <= 0 ||
          customWidth! % 2 != 0 ||
          customHeight! % 2 != 0) {
        return false;
      }
    }

    // Frame rate must be positive
    if (frameRate != null && frameRate! <= 0) {
      return false;
    }

    // CRF must be in valid range
    if (crf != null && (crf! < 0 || crf! > 51)) {
      return false;
    }

    // Rotation must be valid degrees
    if (rotation != null && ![0, 90, 180, 270].contains(rotation!)) {
      return false;
    }

    // Trim times must be logical
    if (trimStartMs != null &&
        trimEndMs != null &&
        trimStartMs! >= trimEndMs!) {
      return false;
    }

    // Audio settings validation
    if (audioSampleRate != null && audioSampleRate! <= 0) {
      return false;
    }

    if (audioChannels != null && (audioChannels! < 1 || audioChannels! > 8)) {
      return false;
    }

    // Color adjustments must be in range
    if (brightness != null && (brightness! < -1.0 || brightness! > 1.0)) {
      return false;
    }

    if (contrast != null && (contrast! < -1.0 || contrast! > 1.0)) {
      return false;
    }

    if (saturation != null && (saturation! < -1.0 || saturation! > 1.0)) {
      return false;
    }

    // NEW: Validate new compression options
    if (keyframeInterval != null &&
        (keyframeInterval! < 1 || keyframeInterval! > 30)) {
      return false;
    }

    if (bFrames != null && (bFrames! < 0 || bFrames! > 16)) {
      return false;
    }

    if (reducedFrameRate != null &&
        (reducedFrameRate! <= 0 || reducedFrameRate! > 120)) {
      return false;
    }

    return true;
  }

  Map<String, dynamic> toMap() {
    return {
      'videoBitrate': videoBitrate,
      'audioBitrate': audioBitrate,
      'customWidth': customWidth,
      'customHeight': customHeight,
      'frameRate': frameRate,
      'videoCodec': videoCodec?.value,
      'audioCodec': audioCodec?.value,
      'encodingSpeed': encodingSpeed?.value,
      'crf': crf,
      'twoPassEncoding': twoPassEncoding,
      'hardwareAcceleration': hardwareAcceleration,
      'trimStartMs': trimStartMs,
      'trimEndMs': trimEndMs,
      'rotation': rotation,
      'audioSampleRate': audioSampleRate,
      'audioChannels': audioChannels,
      'removeAudio': removeAudio,
      'brightness': brightness,
      'contrast': contrast,
      'saturation': saturation,
      'variableBitrate': variableBitrate,
      'keyframeInterval': keyframeInterval,
      'bFrames': bFrames,
      'reducedFrameRate': reducedFrameRate,
      'aggressiveCompression': aggressiveCompression,
      'noiseReduction': noiseReduction,
      'monoAudio': monoAudio,
    };
  }

  /// Creates a maximum compression configuration for smallest file sizes
  factory VVideoAdvancedConfig.maximumCompression({
    int? targetBitrate,
    bool keepAudio = false,
  }) {
    return VVideoAdvancedConfig(
      videoCodec: VVideoCodec.h265, // H.265 for 30-50% better compression
      videoBitrate: targetBitrate ?? 300000, // Very low bitrate (300 kbps)
      audioBitrate: keepAudio ? 64000 : null, // Low audio bitrate or remove
      removeAudio: !keepAudio, // Remove audio if not needed
      crf: 28, // Lower quality for smaller size
      twoPassEncoding: true, // Better compression efficiency
      hardwareAcceleration: true, // Faster encoding
      variableBitrate: true, // Better compression
      keyframeInterval: 10, // Larger GOP for better compression
      bFrames: 3, // Enable B-frames
      reducedFrameRate: 24.0, // Reduce to 24 FPS
      aggressiveCompression: true, // Enable all aggressive settings
      noiseReduction: true, // Remove noise for better compression
      monoAudio: !keepAudio ? null : true, // Mono audio if keeping audio
      audioSampleRate: keepAudio ? 22050 : null, // Lower sample rate
      audioChannels: keepAudio ? 1 : null, // Mono audio
    );
  }

  /// Creates a social media optimized compression configuration
  factory VVideoAdvancedConfig.socialMediaOptimized() {
    return VVideoAdvancedConfig(
      videoCodec: VVideoCodec.h265, // H.265 for better compression
      videoBitrate: 800000, // 800 kbps for social media
      audioBitrate: 96000, // 96 kbps audio
      crf: 25, // Good quality/size balance
      variableBitrate: true, // Better compression
      keyframeInterval: 5, // Good for streaming
      bFrames: 2, // Moderate B-frames
      reducedFrameRate: 30.0, // 30 FPS for social media
      aggressiveCompression: true, // Enable aggressive settings
      audioSampleRate: 44100, // Standard sample rate
      audioChannels: 2, // Stereo audio
    );
  }

  /// Creates a mobile optimized compression configuration
  factory VVideoAdvancedConfig.mobileOptimized() {
    return VVideoAdvancedConfig(
      videoCodec: VVideoCodec.h264, // H.264 for compatibility
      videoBitrate: 1500000, // 1.5 Mbps for mobile
      audioBitrate: 128000, // 128 kbps audio
      crf: 23, // Good quality
      hardwareAcceleration: true, // Mobile GPU acceleration
      variableBitrate: true, // Better compression
      keyframeInterval: 3, // Good for mobile playback
      bFrames: 1, // Light B-frames for mobile
      reducedFrameRate: 30.0, // 30 FPS
      audioSampleRate: 44100, // Standard sample rate
      audioChannels: 2, // Stereo audio
    );
  }
}

/// Video information model
class VVideoInfo {
  final String path;
  final String name;
  final int fileSizeBytes;
  final int durationMillis;
  final int width;
  final int height;
  final String? thumbnailPath;

  const VVideoInfo({
    required this.path,
    required this.name,
    required this.fileSizeBytes,
    required this.durationMillis,
    required this.width,
    required this.height,
    this.thumbnailPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'name': name,
      'fileSizeBytes': fileSizeBytes,
      'durationMillis': durationMillis,
      'width': width,
      'height': height,
      'thumbnailPath': thumbnailPath,
    };
  }

  factory VVideoInfo.fromMap(Map<String, dynamic> map) {
    return VVideoInfo(
      path: map['path'] ?? '',
      name: map['name'] ?? '',
      fileSizeBytes: map['fileSizeBytes']?.toInt() ?? 0,
      durationMillis: map['durationMillis']?.toInt() ?? 0,
      width: map['width']?.toInt() ?? 0,
      height: map['height']?.toInt() ?? 0,
      thumbnailPath: map['thumbnailPath'],
    );
  }

  double get fileSizeMB => fileSizeBytes / (1024.0 * 1024.0);

  String get durationFormatted {
    final totalSeconds = durationMillis ~/ 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String get fileSizeFormatted {
    const kb = 1024.0;
    const mb = kb * 1024;
    const gb = mb * 1024;

    if (fileSizeBytes >= gb) {
      return '${(fileSizeBytes / gb).toStringAsFixed(1)} GB';
    } else if (fileSizeBytes >= mb) {
      return '${(fileSizeBytes / mb).toStringAsFixed(1)} MB';
    } else if (fileSizeBytes >= kb) {
      return '${(fileSizeBytes / kb).toStringAsFixed(1)} KB';
    } else {
      return '$fileSizeBytes B';
    }
  }
}

/// Configuration for video compression operations
class VVideoCompressionConfig {
  /// Quality level for the compressed video
  final VVideoCompressQuality quality;

  /// Custom output path for the compressed video (optional)
  final String? outputPath;

  /// Whether to delete the original video file after compression
  final bool deleteOriginal;

  /// Advanced compression settings (optional)
  final VVideoAdvancedConfig? advanced;

  const VVideoCompressionConfig({
    required this.quality,
    this.outputPath,
    this.deleteOriginal = false,
    this.advanced,
  });

  const VVideoCompressionConfig.high({
    this.outputPath,
    this.deleteOriginal = false,
    this.advanced,
  }) : quality = VVideoCompressQuality.high;

  const VVideoCompressionConfig.medium({
    this.outputPath,
    this.deleteOriginal = false,
    this.advanced,
  }) : quality = VVideoCompressQuality.medium;

  const VVideoCompressionConfig.low({
    this.outputPath,
    this.deleteOriginal = false,
    this.advanced,
  }) : quality = VVideoCompressQuality.low;

  /// Validates the configuration
  bool isValid() {
    if (advanced != null && !advanced!.isValid()) {
      return false;
    }
    return true;
  }

  Map<String, dynamic> toMap() {
    return {
      'quality': quality.value,
      'outputPath': outputPath,
      'deleteOriginal': deleteOriginal,
      'advanced': advanced?.toMap(),
    };
  }
}

/// Compression estimation result
class VVideoCompressionEstimate {
  final int estimatedSizeBytes;
  final String estimatedSizeFormatted;
  final double compressionRatio;
  final double bitrateMbps;

  const VVideoCompressionEstimate({
    required this.estimatedSizeBytes,
    required this.estimatedSizeFormatted,
    required this.compressionRatio,
    required this.bitrateMbps,
  });

  factory VVideoCompressionEstimate.fromMap(Map<String, dynamic> map) {
    return VVideoCompressionEstimate(
      estimatedSizeBytes: map['estimatedSizeBytes']?.toInt() ?? 0,
      estimatedSizeFormatted: map['estimatedSizeFormatted'] ?? '',
      compressionRatio: map['compressionRatio']?.toDouble() ?? 0.0,
      bitrateMbps: map['bitrateMbps']?.toDouble() ?? 0.0,
    );
  }
}

/// Compression result
class VVideoCompressionResult {
  final VVideoInfo originalVideo;
  final String compressedFilePath;
  final String? galleryUri;
  final int originalSizeBytes;
  final int compressedSizeBytes;
  final double compressionRatio;
  final int timeTaken;
  final VVideoCompressQuality quality;
  final String originalResolution;
  final String compressedResolution;
  final int spaceSaved;

  const VVideoCompressionResult({
    required this.originalVideo,
    required this.compressedFilePath,
    this.galleryUri,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
    required this.compressionRatio,
    required this.timeTaken,
    required this.quality,
    required this.originalResolution,
    required this.compressedResolution,
    required this.spaceSaved,
  });

  factory VVideoCompressionResult.fromMap(Map<String, dynamic> map) {
    return VVideoCompressionResult(
      originalVideo: VVideoInfo.fromMap(map['originalVideo']),
      compressedFilePath: map['compressedFilePath'] ?? '',
      galleryUri: map['galleryUri'],
      originalSizeBytes: map['originalSizeBytes']?.toInt() ?? 0,
      compressedSizeBytes: map['compressedSizeBytes']?.toInt() ?? 0,
      compressionRatio: map['compressionRatio']?.toDouble() ?? 0.0,
      timeTaken: map['timeTaken']?.toInt() ?? 0,
      quality: VVideoCompressQuality.values.firstWhere(
        (q) => q.value == map['quality'],
        orElse: () => VVideoCompressQuality.medium,
      ),
      originalResolution: map['originalResolution'] ?? '',
      compressedResolution: map['compressedResolution'] ?? '',
      spaceSaved: map['spaceSaved']?.toInt() ?? 0,
    );
  }

  String get spaceSavedFormatted => _formatFileSize(spaceSaved);
  int get compressionPercentage => ((1 - compressionRatio) * 100).round();
  String get originalSizeFormatted => _formatFileSize(originalSizeBytes);
  String get compressedSizeFormatted => _formatFileSize(compressedSizeBytes);
  String get timeTakenFormatted => _formatTime(timeTaken);

  String _formatFileSize(int bytes) {
    const kb = 1024.0;
    const mb = kb * 1024;
    const gb = mb * 1024;

    if (bytes >= gb) {
      return '${(bytes / gb).toStringAsFixed(1)} GB';
    } else if (bytes >= mb) {
      return '${(bytes / mb).toStringAsFixed(1)} MB';
    } else if (bytes >= kb) {
      return '${(bytes / kb).toStringAsFixed(1)} KB';
    } else {
      return '$bytes B';
    }
  }

  String _formatTime(int milliseconds) {
    final totalSeconds = milliseconds ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

/// Video thumbnail configuration
class VVideoThumbnailConfig {
  /// The timestamp in milliseconds to extract the thumbnail from
  final int timeMs;

  /// The maximum width of the thumbnail (maintains aspect ratio)
  final int? maxWidth;

  /// The maximum height of the thumbnail (maintains aspect ratio)
  final int? maxHeight;

  /// The output format for the thumbnail
  final VThumbnailFormat format;

  /// The quality of the thumbnail (0-100, only applies to JPEG)
  final int quality;

  /// The output path for the thumbnail (if null, generates in temp directory)
  final String? outputPath;

  const VVideoThumbnailConfig({
    this.timeMs = 0,
    this.maxWidth,
    this.maxHeight,
    this.format = VThumbnailFormat.jpeg,
    this.quality = 80,
    this.outputPath,
  });

  /// Creates a default configuration for generating thumbnails
  const VVideoThumbnailConfig.defaults({
    this.timeMs = 0,
    this.maxWidth = 200,
    this.maxHeight = 200,
    this.format = VThumbnailFormat.jpeg,
    this.quality = 80,
    this.outputPath,
  });

  /// Validates the thumbnail configuration
  bool isValid() {
    if (timeMs < 0) return false;
    if (maxWidth != null && maxWidth! <= 0) return false;
    if (maxHeight != null && maxHeight! <= 0) return false;
    if (quality < 0 || quality > 100) return false;
    return true;
  }

  Map<String, dynamic> toMap() {
    return {
      'timeMs': timeMs,
      'maxWidth': maxWidth,
      'maxHeight': maxHeight,
      'format': format.value,
      'quality': quality,
      'outputPath': outputPath,
    };
  }
}

/// Thumbnail output format
enum VThumbnailFormat {
  jpeg('JPEG', 'image/jpeg', '.jpg'),
  png('PNG', 'image/png', '.png');

  const VThumbnailFormat(this.value, this.mimeType, this.extension);

  final String value;
  final String mimeType;
  final String extension;
}

/// Video thumbnail result
class VVideoThumbnailResult {
  /// The path to the generated thumbnail file
  final String thumbnailPath;

  /// The width of the generated thumbnail
  final int width;

  /// The height of the generated thumbnail
  final int height;

  /// The file size of the thumbnail in bytes
  final int fileSizeBytes;

  /// The format of the generated thumbnail
  final VThumbnailFormat format;

  /// The timestamp in milliseconds where the thumbnail was extracted from
  final int timeMs;

  const VVideoThumbnailResult({
    required this.thumbnailPath,
    required this.width,
    required this.height,
    required this.fileSizeBytes,
    required this.format,
    required this.timeMs,
  });

  factory VVideoThumbnailResult.fromMap(Map<String, dynamic> map) {
    return VVideoThumbnailResult(
      thumbnailPath: map['thumbnailPath'] ?? '',
      width: map['width']?.toInt() ?? 0,
      height: map['height']?.toInt() ?? 0,
      fileSizeBytes: map['fileSizeBytes']?.toInt() ?? 0,
      format: VThumbnailFormat.values.firstWhere(
        (f) => f.value == map['format'],
        orElse: () => VThumbnailFormat.jpeg,
      ),
      timeMs: map['timeMs']?.toInt() ?? 0,
    );
  }

  String get fileSizeFormatted {
    const kb = 1024.0;
    const mb = kb * 1024;

    if (fileSizeBytes >= mb) {
      return '${(fileSizeBytes / mb).toStringAsFixed(1)} MB';
    } else if (fileSizeBytes >= kb) {
      return '${(fileSizeBytes / kb).toStringAsFixed(1)} KB';
    } else {
      return '$fileSizeBytes B';
    }
  }
}

/// Main plugin class for video compression
///
/// This plugin focuses exclusively on video compression functionality.
/// Use Flutter's image_picker or file_picker plugins for video selection.
///
/// Features:
/// - High-quality video compression with real-time progress
/// - Multiple quality presets and advanced customization
/// - Thumbnail generation at specific timestamps
/// - Batch compression with progress tracking
/// - Comprehensive error handling and configurable logging
/// - Automatic cleanup and resource management
class VVideoCompressor {
  /// Configure logging for the V Video Compressor
  ///
  /// This method allows you to configure how the plugin logs information:
  /// - Enable/disable logging entirely
  /// - Set log levels (none, error, warning, info, debug, verbose)
  /// - Control what types of logs are shown
  /// - Use console output or structured logging
  ///
  /// Example configurations:
  /// ```dart
  /// // Production: minimal logging
  /// VVideoCompressor.configureLogging(VVideoLogConfig.production());
  ///
  /// // Development: verbose logging
  /// VVideoCompressor.configureLogging(VVideoLogConfig.development());
  ///
  /// // Custom configuration
  /// VVideoCompressor.configureLogging(VVideoLogConfig(
  ///   enabled: true,
  ///   level: VVideoLogLevel.info,
  ///   showProgress: true,
  ///   showParameters: true,
  /// ));
  ///
  /// // Disable all logging
  /// VVideoCompressor.configureLogging(VVideoLogConfig.disabled());
  /// ```
  static void configureLogging(VVideoLogConfig config) {
    VVideoLogger.configure(config);
    VVideoLogger.info('Logging configured with level: ${config.level.name}');
  }

  /// Get current logging configuration
  static VVideoLogConfig get loggingConfig => VVideoLogger.config;

  /// Get platform version (for testing and debugging)
  ///
  /// Returns the platform version string or null if unavailable.
  /// This method is primarily used for testing and debugging purposes.
  Future<String?> getPlatformVersion() async {
    try {
      VVideoLogger.methodCall('getPlatformVersion', null);
      final version =
          await VVideoCompressorPlatform.instance.getPlatformVersion();
      VVideoLogger.success(
          'getPlatformVersion', {'version': version ?? 'unknown'});
      return version;
    } catch (error, stackTrace) {
      VVideoLogger.error('Failed to get platform version', error, stackTrace);
      return null;
    }
  }

  /// Get comprehensive video information from file path
  ///
  /// Returns detailed video metadata including:
  /// - File size, duration, and resolution
  /// - Video name and file path
  /// - Formatted duration and file size strings
  ///
  /// Returns null if the video file is invalid or inaccessible.
  ///
  /// Example:
  /// ```dart
  /// final info = await compressor.getVideoInfo('/path/to/video.mp4');
  /// if (info != null) {
  ///   print('Duration: ${info.durationFormatted}');
  ///   print('Size: ${info.fileSizeFormatted}');
  ///   print('Resolution: ${info.width}x${info.height}');
  /// }
  /// ```
  Future<VVideoInfo?> getVideoInfo(String videoPath) async {
    try {
      VVideoLogger.methodCall('getVideoInfo', {'videoPath': videoPath});

      if (videoPath.isEmpty) {
        VVideoLogger.warning('Empty video path provided to getVideoInfo');
        return null;
      }

      final info =
          await VVideoCompressorPlatform.instance.getVideoInfo(videoPath);

      if (info != null) {
        VVideoLogger.success('getVideoInfo', {
          'name': info.name,
          'duration': info.durationFormatted,
          'size': info.fileSizeFormatted,
          'resolution': '${info.width}x${info.height}',
        });
      } else {
        VVideoLogger.warning(
            'Failed to get video info - file may be invalid or inaccessible');
      }

      return info;
    } catch (error, stackTrace) {
      VVideoLogger.error(
          'Failed to get video info for path: $videoPath', error, stackTrace);
      return null;
    }
  }

  /// Estimate compression size and ratio before actual compression
  ///
  /// This method provides accurate estimates for:
  /// - Final compressed file size
  /// - Compression ratio percentage
  /// - Expected bitrate after compression
  ///
  /// Useful for UI feedback and storage planning.
  ///
  /// Example:
  /// ```dart
  /// final estimate = await compressor.getCompressionEstimate(
  ///   videoPath,
  ///   VVideoCompressQuality.medium,
  ///   advanced: advancedConfig,
  /// );
  ///
  /// if (estimate != null) {
  ///   print('Estimated size: ${estimate.estimatedSizeFormatted}');
  ///   print('Compression ratio: ${estimate.compressionRatio}');
  /// }
  /// ```
  Future<VVideoCompressionEstimate?> getCompressionEstimate(
    String videoPath,
    VVideoCompressQuality quality, {
    VVideoAdvancedConfig? advanced,
  }) async {
    try {
      VVideoLogger.methodCall('getCompressionEstimate', {
        'videoPath': videoPath,
        'quality': quality.value,
        'hasAdvanced': advanced != null,
      });

      if (videoPath.isEmpty) {
        VVideoLogger.warning(
            'Empty video path provided to getCompressionEstimate');
        return null;
      }

      final estimate =
          await VVideoCompressorPlatform.instance.getCompressionEstimate(
        videoPath,
        quality,
        advanced: advanced,
      );

      if (estimate != null) {
        VVideoLogger.success('getCompressionEstimate', {
          'estimatedSize': estimate.estimatedSizeFormatted,
          'compressionRatio':
              '${(estimate.compressionRatio * 100).toStringAsFixed(1)}%',
          'bitrate': '${estimate.bitrateMbps.toStringAsFixed(2)} Mbps',
        });
      } else {
        VVideoLogger.warning(
            'Failed to get compression estimate - video may be invalid');
      }

      return estimate;
    } catch (error, stackTrace) {
      VVideoLogger.error('Failed to get compression estimate for: $videoPath',
          error, stackTrace);
      return null;
    }
  }

  /// Compress a single video with real-time progress tracking
  ///
  /// This is the core compression method that provides:
  /// - High-quality video compression with configurable quality levels
  /// - Real-time progress updates via callback
  /// - Advanced compression options support
  /// - Automatic error handling and recovery
  /// - Comprehensive logging for debugging
  ///
  /// The [onProgress] callback receives values from 0.0 to 1.0 representing
  /// compression progress percentage.
  ///
  /// Example:
  /// ```dart
  /// final result = await compressor.compressVideo(
  ///   videoPath,
  ///   VVideoCompressionConfig.medium(),
  ///   onProgress: (progress) {
  ///     print('Progress: ${(progress * 100).toInt()}%');
  ///   },
  /// );
  ///
  /// if (result != null) {
  ///   print('Compressed from ${result.originalSizeFormatted} to ${result.compressedSizeFormatted}');
  ///   print('Space saved: ${result.spaceSavedFormatted}');
  /// }
  /// ```
  Future<VVideoCompressionResult?> compressVideo(
    String videoPath,
    VVideoCompressionConfig config, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      VVideoLogger.methodCall('compressVideo', {
        'videoPath': videoPath,
        'quality': config.quality.value,
        'hasAdvanced': config.advanced != null,
        'deleteOriginal': config.deleteOriginal,
      });

      if (videoPath.isEmpty) {
        VVideoLogger.error('Empty video path provided to compressVideo');
        return null;
      }

      if (!config.isValid()) {
        VVideoLogger.error('Invalid compression configuration provided');
        return null;
      }

      VVideoLogger.info('Starting video compression...');
      final startTime = DateTime.now();

      final result = await VVideoCompressorPlatform.instance.compressVideo(
        videoPath,
        config,
        onProgress: onProgress != null
            ? (progress) {
                VVideoLogger.progress('Compression', progress);
                onProgress(progress);
              }
            : null,
      );

      if (result != null) {
        final endTime = DateTime.now();
        final totalTime = endTime.difference(startTime);

        VVideoLogger.success('compressVideo', {
          'originalSize': result.originalSizeFormatted,
          'compressedSize': result.compressedSizeFormatted,
          'spaceSaved': result.spaceSavedFormatted,
          'compressionRatio': '${result.compressionPercentage}%',
          'timeTaken': result.timeTakenFormatted,
          'totalTime': '${totalTime.inSeconds}s',
        });
      } else {
        VVideoLogger.error('Compression failed - no result returned');
      }

      return result;
    } catch (error, stackTrace) {
      VVideoLogger.error(
          'Video compression failed for: $videoPath', error, stackTrace);
      return null;
    }
  }

  /// Compress multiple videos sequentially with batch progress tracking
  ///
  /// This method processes multiple videos one by one, providing:
  /// - Sequential compression to avoid resource conflicts
  /// - Overall batch progress tracking
  /// - Individual video progress updates
  /// - Comprehensive error handling per video
  /// - Automatic cleanup on cancellation
  ///
  /// The [onProgress] callback provides:
  /// - [progress]: Overall batch progress (0.0 to 1.0)
  /// - [currentIndex]: Index of currently processing video
  /// - [total]: Total number of videos to process
  ///
  /// Example:
  /// ```dart
  /// final results = await compressor.compressVideos(
  ///   [path1, path2, path3],
  ///   VVideoCompressionConfig.medium(),
  ///   onProgress: (progress, current, total) {
  ///     print('Batch: ${(progress * 100).toInt()}% ($current/$total)');
  ///   },
  /// );
  ///
  /// print('Successfully compressed ${results.length} videos');
  /// ```
  Future<List<VVideoCompressionResult>> compressVideos(
    List<String> videoPaths,
    VVideoCompressionConfig config, {
    void Function(double progress, int currentIndex, int total)? onProgress,
  }) async {
    try {
      VVideoLogger.methodCall('compressVideos', {
        'videoCount': videoPaths.length,
        'quality': config.quality.value,
        'hasAdvanced': config.advanced != null,
      });

      if (videoPaths.isEmpty) {
        VVideoLogger.warning(
            'Empty video paths list provided to compressVideos');
        return [];
      }

      if (!config.isValid()) {
        VVideoLogger.error(
            'Invalid compression configuration provided for batch compression');
        return [];
      }

      VVideoLogger.info(
          'Starting batch compression of ${videoPaths.length} videos...');
      final startTime = DateTime.now();

      final results = await VVideoCompressorPlatform.instance.compressVideos(
        videoPaths,
        config,
        onProgress: onProgress != null
            ? (progress, currentIndex, total) {
                VVideoLogger.progress('Batch compression', progress,
                    'Video ${currentIndex + 1}/$total');
                onProgress(progress, currentIndex, total);
              }
            : null,
      );

      final endTime = DateTime.now();
      final totalTime = endTime.difference(startTime);

      VVideoLogger.success('compressVideos', {
        'totalVideos': videoPaths.length,
        'successfulCompressions': results.length,
        'totalTime': '${totalTime.inSeconds}s',
        'averageTimePerVideo':
            '${(totalTime.inSeconds / videoPaths.length).toStringAsFixed(1)}s',
      });

      return results;
    } catch (error, stackTrace) {
      VVideoLogger.error('Batch compression failed', error, stackTrace);
      return [];
    }
  }

  /// Cancel any ongoing compression operations
  ///
  /// This method immediately stops all compression activities and:
  /// - Cancels current compression operation
  /// - Cleans up temporary files
  /// - Releases system resources
  /// - Resets compression state
  ///
  /// Safe to call even when no compression is running.
  ///
  /// Example:
  /// ```dart
  /// // Cancel compression (e.g., user tapped cancel button)
  /// await compressor.cancelCompression();
  /// ```
  Future<void> cancelCompression() async {
    try {
      VVideoLogger.methodCall('cancelCompression', null);

      await VVideoCompressorPlatform.instance.cancelCompression();

      VVideoLogger.success('cancelCompression');
    } catch (error, stackTrace) {
      VVideoLogger.error('Failed to cancel compression', error, stackTrace);
    }
  }

  /// Check if any compression operation is currently running
  ///
  /// Returns true if compression is active, false otherwise.
  /// Useful for UI state management and preventing multiple simultaneous compressions.
  ///
  /// Example:
  /// ```dart
  /// if (await compressor.isCompressing()) {
  ///   print('Compression is already running');
  /// } else {
  ///   // Start new compression
  /// }
  /// ```
  Future<bool> isCompressing() async {
    try {
      VVideoLogger.methodCall('isCompressing', null);

      final isActive = await VVideoCompressorPlatform.instance.isCompressing();

      VVideoLogger.info('Compression status: ${isActive ? 'active' : 'idle'}');

      return isActive;
    } catch (error, stackTrace) {
      VVideoLogger.error(
          'Failed to check compression status', error, stackTrace);
      return false;
    }
  }

  /// Generate a single thumbnail from a video file at a specific timestamp
  ///
  /// This method extracts a high-quality thumbnail image from the video at
  /// the specified timestamp with customizable dimensions and format.
  ///
  /// Features:
  /// - Extract thumbnail at any timestamp (in milliseconds)
  /// - Customizable output dimensions with aspect ratio preservation
  /// - JPEG and PNG format support with quality control
  /// - Automatic file naming and path management
  ///
  /// Example:
  /// ```dart
  /// final thumbnail = await compressor.getVideoThumbnail(
  ///   videoPath,
  ///   VVideoThumbnailConfig(
  ///     timeMs: 5000,        // 5 seconds into the video
  ///     maxWidth: 300,       // Maximum width
  ///     maxHeight: 200,      // Maximum height
  ///     format: VThumbnailFormat.jpeg,
  ///     quality: 85,         // JPEG quality (0-100)
  ///   ),
  /// );
  ///
  /// if (thumbnail != null) {
  ///   print('Thumbnail saved to: ${thumbnail.thumbnailPath}');
  ///   print('Size: ${thumbnail.width}x${thumbnail.height}');
  /// }
  /// ```
  Future<VVideoThumbnailResult?> getVideoThumbnail(
    String videoPath,
    VVideoThumbnailConfig config,
  ) async {
    try {
      VVideoLogger.methodCall('getVideoThumbnail', {
        'videoPath': videoPath,
        'timeMs': config.timeMs,
        'maxWidth': config.maxWidth,
        'maxHeight': config.maxHeight,
        'format': config.format.value,
        'quality': config.quality,
      });

      if (videoPath.isEmpty) {
        VVideoLogger.error('Empty video path provided to getVideoThumbnail');
        return null;
      }

      if (!config.isValid()) {
        VVideoLogger.error('Invalid thumbnail configuration provided');
        return null;
      }

      final result = await VVideoCompressorPlatform.instance.getVideoThumbnail(
        videoPath,
        config,
      );

      if (result != null) {
        VVideoLogger.success('getVideoThumbnail', {
          'thumbnailPath': result.thumbnailPath,
          'dimensions': '${result.width}x${result.height}',
          'fileSize': result.fileSizeFormatted,
          'format': result.format.value,
          'timeMs': result.timeMs,
        });
      } else {
        VVideoLogger.error(
            'Failed to generate thumbnail - video may be invalid or timestamp out of range');
      }

      return result;
    } catch (error, stackTrace) {
      VVideoLogger.error(
          'Thumbnail generation failed for: $videoPath', error, stackTrace);
      return null;
    }
  }

  /// Generate multiple thumbnails from a video file at different timestamps
  ///
  /// This method efficiently generates multiple thumbnails from a single video
  /// file with different configurations, useful for creating video previews,
  /// timelines, or galleries.
  ///
  /// Features:
  /// - Batch thumbnail generation for efficiency
  /// - Individual configuration per thumbnail
  /// - Different timestamps, sizes, and formats supported
  /// - Optimized processing to minimize video file access
  ///
  /// Example:
  /// ```dart
  /// final thumbnails = await compressor.getVideoThumbnails(
  ///   videoPath,
  ///   [
  ///     VVideoThumbnailConfig(timeMs: 1000, maxWidth: 150),  // 1s
  ///     VVideoThumbnailConfig(timeMs: 5000, maxWidth: 150),  // 5s
  ///     VVideoThumbnailConfig(timeMs: 10000, maxWidth: 150), // 10s
  ///   ],
  /// );
  ///
  /// print('Generated ${thumbnails.length} thumbnails');
  /// ```
  Future<List<VVideoThumbnailResult>> getVideoThumbnails(
    String videoPath,
    List<VVideoThumbnailConfig> configs,
  ) async {
    try {
      VVideoLogger.methodCall('getVideoThumbnails', {
        'videoPath': videoPath,
        'configCount': configs.length,
        'timestamps': configs.map((c) => c.timeMs).toList(),
      });

      if (videoPath.isEmpty) {
        VVideoLogger.error('Empty video path provided to getVideoThumbnails');
        return [];
      }

      if (configs.isEmpty) {
        VVideoLogger.warning(
            'Empty configs list provided to getVideoThumbnails');
        return [];
      }

      // Validate all configurations
      for (int i = 0; i < configs.length; i++) {
        if (!configs[i].isValid()) {
          VVideoLogger.error('Invalid thumbnail configuration at index $i');
          return [];
        }
      }

      final results =
          await VVideoCompressorPlatform.instance.getVideoThumbnails(
        videoPath,
        configs,
      );

      VVideoLogger.success('getVideoThumbnails', {
        'requestedCount': configs.length,
        'generatedCount': results.length,
        'totalFileSize':
            results.fold<int>(0, (sum, t) => sum + t.fileSizeBytes),
      });

      return results;
    } catch (error, stackTrace) {
      VVideoLogger.error('Batch thumbnail generation failed for: $videoPath',
          error, stackTrace);
      return [];
    }
  }

  /// Perform complete cleanup of all plugin resources and temporary files
  ///
  /// This method provides comprehensive cleanup including:
  /// - Cancelling any ongoing compression operations
  /// - Deleting all temporary thumbnail files
  /// - Clearing compression cache and intermediate files
  /// - Freeing system memory and resources
  /// - Resetting plugin state to initial conditions
  ///
  /// Call this method when:
  /// - App is being closed or paused
  /// - Switching between different video projects
  /// - Need to free up storage space
  /// - Experiencing memory issues
  ///
  /// Example:
  /// ```dart
  /// // Clean up when app is disposed
  /// @override
  /// void dispose() {
  ///   compressor.cleanup();
  ///   super.dispose();
  /// }
  /// ```
  Future<void> cleanup() async {
    try {
      VVideoLogger.methodCall('cleanup', null);
      VVideoLogger.info('Starting comprehensive cleanup...');

      await VVideoCompressorPlatform.instance.cleanup();

      VVideoLogger.success(
          'cleanup', {'operation': 'Complete cleanup finished'});
    } catch (error, stackTrace) {
      VVideoLogger.error('Cleanup failed', error, stackTrace);
    }
  }

  /// Perform selective cleanup of specific file types and resources
  ///
  /// This method provides granular control over what gets cleaned up:
  ///
  /// - [deleteThumbnails]: Remove all generated thumbnail image files
  /// - [deleteCompressedVideos]: Remove compressed video files (**use with caution**)
  /// - [clearCache]: Clear temporary cache files and free memory
  ///
  /// **Warning**: Setting [deleteCompressedVideos] to true will permanently
  /// delete all videos created by this plugin. Only use this if you're sure
  /// the compressed videos are no longer needed.
  ///
  /// Example:
  /// ```dart
  /// // Safe cleanup - only remove thumbnails and cache
  /// await compressor.cleanupFiles(
  ///   deleteThumbnails: true,
  ///   deleteCompressedVideos: false,  // Keep compressed videos
  ///   clearCache: true,
  /// );
  ///
  /// // Full cleanup - removes everything (dangerous!)
  /// await compressor.cleanupFiles(
  ///   deleteThumbnails: true,
  ///   deleteCompressedVideos: true,   // This will delete your compressed videos!
  ///   clearCache: true,
  /// );
  /// ```
  Future<void> cleanupFiles({
    bool deleteThumbnails = true,
    bool deleteCompressedVideos = false,
    bool clearCache = true,
  }) async {
    try {
      VVideoLogger.methodCall('cleanupFiles', {
        'deleteThumbnails': deleteThumbnails,
        'deleteCompressedVideos': deleteCompressedVideos,
        'clearCache': clearCache,
      });

      if (deleteCompressedVideos) {
        VVideoLogger.warning(
            '⚠️ Selective cleanup includes deleting compressed videos - this action is irreversible');
      }

      VVideoLogger.info('Starting selective cleanup...');

      await VVideoCompressorPlatform.instance.cleanupFiles(
        deleteThumbnails: deleteThumbnails,
        deleteCompressedVideos: deleteCompressedVideos,
        clearCache: clearCache,
      );

      final cleanupTypes = <String>[];
      if (deleteThumbnails) cleanupTypes.add('thumbnails');
      if (deleteCompressedVideos) cleanupTypes.add('compressed videos');
      if (clearCache) cleanupTypes.add('cache');

      VVideoLogger.success('cleanupFiles', {
        'cleanedTypes': cleanupTypes.join(', '),
        'deletedCompressedVideos': deleteCompressedVideos,
      });
    } catch (error, stackTrace) {
      VVideoLogger.error('Selective cleanup failed', error, stackTrace);
    }
  }
}
