import 'package:flutter_test/flutter_test.dart';
import 'package:v_video_compressor/v_video_compressor.dart';
import 'package:v_video_compressor/v_video_compressor_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Mock platform implementation for testing
class MockVVideoCompressorPlatform
    with MockPlatformInterfaceMixin
    implements VVideoCompressorPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<VVideoInfo?> getVideoInfo(String videoPath) async {
    if (videoPath.isEmpty || videoPath == 'invalid_path') {
      return null;
    }

    return VVideoInfo(
      path: videoPath,
      name: 'test_video.mp4',
      fileSizeBytes: 10485760, // 10 MB
      durationMillis: 30000, // 30 seconds
      width: 1920,
      height: 1080,
    );
  }

  @override
  Future<VVideoCompressionEstimate?> getCompressionEstimate(
    String videoPath,
    VVideoCompressQuality quality, {
    VVideoAdvancedConfig? advanced,
  }) async {
    if (videoPath.isEmpty) return null;

    final originalSize = 10485760; // 10 MB
    final compressionRatio = switch (quality) {
      VVideoCompressQuality.high => 0.7,
      VVideoCompressQuality.medium => 0.5,
      VVideoCompressQuality.low => 0.3,
      VVideoCompressQuality.veryLow => 0.2,
      VVideoCompressQuality.ultraLow => 0.15,
    };

    final estimatedSize = (originalSize * compressionRatio).round();

    return VVideoCompressionEstimate(
      estimatedSizeBytes: estimatedSize,
      estimatedSizeFormatted:
          '${(estimatedSize / 1024 / 1024).toStringAsFixed(1)} MB',
      compressionRatio: compressionRatio,
      bitrateMbps: 2.0,
    );
  }

  @override
  Future<VVideoCompressionResult?> compressVideo(
    String videoPath,
    VVideoCompressionConfig config, {
    void Function(double progress)? onProgress,
  }) async {
    if (videoPath.isEmpty) return null;

    // Simulate progress updates
    if (onProgress != null) {
      for (double progress = 0.0; progress <= 1.0; progress += 0.1) {
        onProgress(progress);
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    final originalVideo = VVideoInfo(
      path: videoPath,
      name: 'test_video.mp4',
      fileSizeBytes: 10485760,
      durationMillis: 30000,
      width: 1920,
      height: 1080,
    );

    return VVideoCompressionResult(
      originalVideo: originalVideo,
      compressedFilePath: '/path/to/compressed_video.mp4',
      originalSizeBytes: 10485760,
      compressedSizeBytes: 5242880, // 5 MB
      compressionRatio: 0.5,
      timeTaken: 5000, // 5 seconds
      quality: config.quality,
      originalResolution: '1920x1080',
      compressedResolution: '1280x720',
      spaceSaved: 5242880,
    );
  }

  @override
  Future<List<VVideoCompressionResult>> compressVideos(
    List<String> videoPaths,
    VVideoCompressionConfig config, {
    void Function(double progress, int currentIndex, int total)? onProgress,
  }) async {
    final results = <VVideoCompressionResult>[];

    for (int i = 0; i < videoPaths.length; i++) {
      if (onProgress != null) {
        onProgress(i / videoPaths.length, i, videoPaths.length);
      }

      final result = await compressVideo(videoPaths[i], config);
      if (result != null) {
        results.add(result);
      }
    }

    if (onProgress != null) {
      onProgress(1.0, videoPaths.length, videoPaths.length);
    }

    return results;
  }

  @override
  Future<void> cancelCompression() async {
    // Mock implementation
  }

  @override
  Future<bool> isCompressing() async => false;

  @override
  Future<VVideoThumbnailResult?> getVideoThumbnail(
    String videoPath,
    VVideoThumbnailConfig config,
  ) async {
    if (videoPath.isEmpty) return null;

    return VVideoThumbnailResult(
      thumbnailPath: '/path/to/thumbnail.jpg',
      width: config.maxWidth ?? 200,
      height: config.maxHeight ?? 200,
      fileSizeBytes: 51200, // 50 KB
      format: config.format,
      timeMs: config.timeMs,
    );
  }

  @override
  Future<List<VVideoThumbnailResult>> getVideoThumbnails(
    String videoPath,
    List<VVideoThumbnailConfig> configs,
  ) async {
    final results = <VVideoThumbnailResult>[];

    for (final config in configs) {
      final result = await getVideoThumbnail(videoPath, config);
      if (result != null) {
        results.add(result);
      }
    }

    return results;
  }

  @override
  Future<void> cleanup() async {
    // Mock implementation
  }

  @override
  Future<void> cleanupFiles({
    bool deleteThumbnails = true,
    bool deleteCompressedVideos = false,
    bool clearCache = true,
  }) async {
    // Mock implementation
  }
}

void main() {
  final VVideoCompressorPlatform initialPlatform =
      VVideoCompressorPlatform.instance;

  group('V Video Compressor Tests', () {
    late VVideoCompressor compressor;
    late MockVVideoCompressorPlatform fakePlatform;

    setUpAll(() {
      fakePlatform = MockVVideoCompressorPlatform();
      VVideoCompressorPlatform.instance = fakePlatform;
      compressor = VVideoCompressor();
    });

    tearDownAll(() {
      VVideoCompressorPlatform.instance = initialPlatform;
    });

    group('Logging Configuration', () {
      test('should configure logging correctly', () {
        // Test different logging configurations
        VVideoCompressor.configureLogging(VVideoLogConfig.production());
        expect(VVideoCompressor.loggingConfig.level, VVideoLogLevel.error);
        expect(VVideoCompressor.loggingConfig.enabled, true);

        VVideoCompressor.configureLogging(VVideoLogConfig.development());
        expect(VVideoCompressor.loggingConfig.level, VVideoLogLevel.verbose);
        expect(VVideoCompressor.loggingConfig.showProgress, true);

        VVideoCompressor.configureLogging(VVideoLogConfig.disabled());
        expect(VVideoCompressor.loggingConfig.enabled, false);

        // Custom configuration
        const customConfig = VVideoLogConfig(
          enabled: true,
          level: VVideoLogLevel.info,
          showProgress: true,
          showParameters: true,
        );
        VVideoCompressor.configureLogging(customConfig);
        expect(VVideoCompressor.loggingConfig.level, VVideoLogLevel.info);
        expect(VVideoCompressor.loggingConfig.showProgress, true);
        expect(VVideoCompressor.loggingConfig.showParameters, true);
      });

      test('should have correct log level hierarchy', () {
        expect(VVideoLogLevel.none.level, 0);
        expect(VVideoLogLevel.error.level, 1);
        expect(VVideoLogLevel.warning.level, 2);
        expect(VVideoLogLevel.info.level, 3);
        expect(VVideoLogLevel.debug.level, 4);
        expect(VVideoLogLevel.verbose.level, 5);
      });
    });

    group('Platform Version', () {
      test('should return platform version', () async {
        final version = await compressor.getPlatformVersion();
        expect(version, '42');
      });
    });

    group('Video Information', () {
      test('should get video info for valid path', () async {
        const videoPath = '/path/to/video.mp4';
        final info = await compressor.getVideoInfo(videoPath);

        expect(info, isNotNull);
        expect(info!.path, videoPath);
        expect(info.name, 'test_video.mp4');
        expect(info.fileSizeBytes, 10485760);
        expect(info.durationMillis, 30000);
        expect(info.width, 1920);
        expect(info.height, 1080);
      });

      test('should return null for empty path', () async {
        final info = await compressor.getVideoInfo('');
        expect(info, isNull);
      });

      test('should return null for invalid path', () async {
        final info = await compressor.getVideoInfo('invalid_path');
        expect(info, isNull);
      });

      test('should format duration correctly', () async {
        final info = await compressor.getVideoInfo('/path/to/video.mp4');
        expect(info!.durationFormatted, '00:30');
      });

      test('should format file size correctly', () async {
        final info = await compressor.getVideoInfo('/path/to/video.mp4');
        expect(info!.fileSizeFormatted, '10.0 MB');
      });
    });

    group('Compression Estimation', () {
      test('should estimate compression for different qualities', () async {
        const videoPath = '/path/to/video.mp4';

        final highEstimate = await compressor.getCompressionEstimate(
          videoPath,
          VVideoCompressQuality.high,
        );
        final mediumEstimate = await compressor.getCompressionEstimate(
          videoPath,
          VVideoCompressQuality.medium,
        );
        final lowEstimate = await compressor.getCompressionEstimate(
          videoPath,
          VVideoCompressQuality.low,
        );

        expect(highEstimate, isNotNull);
        expect(mediumEstimate, isNotNull);
        expect(lowEstimate, isNotNull);

        // High quality should result in larger file than medium
        expect(
            highEstimate!.estimatedSizeBytes >
                mediumEstimate!.estimatedSizeBytes,
            true);
        // Medium quality should result in larger file than low
        expect(
            mediumEstimate.estimatedSizeBytes > lowEstimate!.estimatedSizeBytes,
            true);
      });

      test('should return null for empty path', () async {
        final estimate = await compressor.getCompressionEstimate(
          '',
          VVideoCompressQuality.medium,
        );
        expect(estimate, isNull);
      });
    });

    group('Video Compression', () {
      test('should compress video successfully', () async {
        const videoPath = '/path/to/video.mp4';
        const config = VVideoCompressionConfig.medium();

        double? lastProgress;
        final result = await compressor.compressVideo(
          videoPath,
          config,
          onProgress: (progress) {
            lastProgress = progress;
          },
        );

        expect(result, isNotNull);
        expect(result!.originalSizeBytes, 10485760);
        expect(result.compressedSizeBytes, 5242880);
        expect(result.compressionRatio, 0.5);
        expect(result.quality, VVideoCompressQuality.medium);
        expect(lastProgress, closeTo(1.0, 0.01));
      });

      test('should return null for empty path', () async {
        const config = VVideoCompressionConfig.medium();
        final result = await compressor.compressVideo('', config);
        expect(result, isNull);
      });

      test('should validate compression config', () {
        const validConfig = VVideoCompressionConfig.medium();
        expect(validConfig.isValid(), true);

        const invalidConfig = VVideoCompressionConfig.medium(
          advanced: VVideoAdvancedConfig(
            customWidth: 100, // Only width without height
          ),
        );
        expect(invalidConfig.isValid(), false);
      });
    });

    group('Batch Compression', () {
      test('should compress multiple videos', () async {
        final videoPaths = [
          '/path/to/video1.mp4',
          '/path/to/video2.mp4',
          '/path/to/video3.mp4',
        ];
        const config = VVideoCompressionConfig.medium();

        int progressCallCount = 0;
        final results = await compressor.compressVideos(
          videoPaths,
          config,
          onProgress: (progress, current, total) {
            progressCallCount++;
            expect(current, lessThanOrEqualTo(total));
            expect(total, videoPaths.length);
          },
        );

        expect(results, hasLength(videoPaths.length));
        expect(progressCallCount, greaterThan(0));
      });

      test('should return empty list for empty paths', () async {
        const config = VVideoCompressionConfig.medium();
        final results = await compressor.compressVideos([], config);
        expect(results, isEmpty);
      });
    });

    group('Advanced Configuration', () {
      test('should validate advanced config correctly', () {
        // Valid configuration
        const validConfig = VVideoAdvancedConfig(
          customWidth: 1280,
          customHeight: 720,
          frameRate: 30.0,
          crf: 23,
          rotation: 90,
        );
        expect(validConfig.isValid(), true);

        // Invalid: odd dimensions
        const invalidDimensions = VVideoAdvancedConfig(
          customWidth: 1281, // Odd number
          customHeight: 720,
        );
        expect(invalidDimensions.isValid(), false);

        // Invalid: only width specified
        const invalidSingleDimension = VVideoAdvancedConfig(
          customWidth: 1280,
          // Missing height
        );
        expect(invalidSingleDimension.isValid(), false);

        // Invalid: negative frame rate
        const invalidFrameRate = VVideoAdvancedConfig(
          frameRate: -1.0,
        );
        expect(invalidFrameRate.isValid(), false);

        // Invalid: CRF out of range
        const invalidCrf = VVideoAdvancedConfig(
          crf: 60, // Max is 51
        );
        expect(invalidCrf.isValid(), false);

        // Invalid: invalid rotation
        const invalidRotation = VVideoAdvancedConfig(
          rotation: 45, // Must be 0, 90, 180, or 270
        );
        expect(invalidRotation.isValid(), false);
      });

      test('should create preset configurations correctly', () {
        final maxCompression = VVideoAdvancedConfig.maximumCompression();
        expect(maxCompression.videoCodec, VVideoCodec.h265);
        expect(maxCompression.aggressiveCompression, true);
        expect(maxCompression.removeAudio, true);

        final socialMedia = VVideoAdvancedConfig.socialMediaOptimized();
        expect(socialMedia.videoCodec, VVideoCodec.h265);
        expect(socialMedia.videoBitrate, 800000);
        expect(socialMedia.reducedFrameRate, 30.0);

        final mobile = VVideoAdvancedConfig.mobileOptimized();
        expect(mobile.videoCodec, VVideoCodec.h264);
        expect(mobile.hardwareAcceleration, true);
      });
    });

    group('Thumbnail Generation', () {
      test('should generate single thumbnail', () async {
        const videoPath = '/path/to/video.mp4';
        const config = VVideoThumbnailConfig(
          timeMs: 5000,
          maxWidth: 300,
          maxHeight: 200,
          format: VThumbnailFormat.jpeg,
          quality: 85,
        );

        final result = await compressor.getVideoThumbnail(videoPath, config);

        expect(result, isNotNull);
        expect(result!.thumbnailPath, '/path/to/thumbnail.jpg');
        expect(result.width, 300);
        expect(result.height, 200);
        expect(result.format, VThumbnailFormat.jpeg);
        expect(result.timeMs, 5000);
      });

      test('should generate multiple thumbnails', () async {
        const videoPath = '/path/to/video.mp4';
        final configs = [
          const VVideoThumbnailConfig(timeMs: 1000, maxWidth: 150),
          const VVideoThumbnailConfig(timeMs: 5000, maxWidth: 150),
          const VVideoThumbnailConfig(timeMs: 10000, maxWidth: 150),
        ];

        final results = await compressor.getVideoThumbnails(videoPath, configs);

        expect(results, hasLength(configs.length));
        expect(results[0].timeMs, 1000);
        expect(results[1].timeMs, 5000);
        expect(results[2].timeMs, 10000);
      });

      test('should validate thumbnail config', () {
        const validConfig = VVideoThumbnailConfig(
          timeMs: 5000,
          maxWidth: 300,
          maxHeight: 200,
          quality: 85,
        );
        expect(validConfig.isValid(), true);

        const invalidTime = VVideoThumbnailConfig(
          timeMs: -1000, // Negative time
        );
        expect(invalidTime.isValid(), false);

        const invalidQuality = VVideoThumbnailConfig(
          quality: 150, // Max is 100
        );
        expect(invalidQuality.isValid(), false);
      });
    });

    group('Compression State Management', () {
      test('should check compression status', () async {
        final isCompressing = await compressor.isCompressing();
        expect(isCompressing, false);
      });

      test('should cancel compression', () async {
        // Should not throw
        await compressor.cancelCompression();
      });
    });

    group('Cleanup Operations', () {
      test('should perform complete cleanup', () async {
        // Should not throw
        await compressor.cleanup();
      });

      test('should perform selective cleanup', () async {
        // Should not throw
        await compressor.cleanupFiles(
          deleteThumbnails: true,
          deleteCompressedVideos: false,
          clearCache: true,
        );
      });
    });

    group('Model Validation', () {
      test('should validate VVideoInfo creation', () {
        const info = VVideoInfo(
          path: '/test/path.mp4',
          name: 'test.mp4',
          fileSizeBytes: 1048576,
          durationMillis: 30000,
          width: 1920,
          height: 1080,
        );

        expect(info.path, '/test/path.mp4');
        expect(info.fileSizeMB, closeTo(1.0, 0.1));
        expect(info.durationFormatted, '00:30');
        expect(info.fileSizeFormatted, '1.0 MB');
      });

      test('should validate compression result calculations', () {
        const originalVideo = VVideoInfo(
          path: '/test/path.mp4',
          name: 'test.mp4',
          fileSizeBytes: 10485760,
          durationMillis: 30000,
          width: 1920,
          height: 1080,
        );

        const result = VVideoCompressionResult(
          originalVideo: originalVideo,
          compressedFilePath: '/compressed/path.mp4',
          originalSizeBytes: 10485760,
          compressedSizeBytes: 5242880,
          compressionRatio: 0.5,
          timeTaken: 5000,
          quality: VVideoCompressQuality.medium,
          originalResolution: '1920x1080',
          compressedResolution: '1280x720',
          spaceSaved: 5242880,
        );

        expect(result.compressionPercentage, 50);
        expect(result.originalSizeFormatted, '10.0 MB');
        expect(result.compressedSizeFormatted, '5.0 MB');
        expect(result.spaceSavedFormatted, '5.0 MB');
        expect(result.timeTakenFormatted, '5s');
      });
    });

    group('Error Handling', () {
      test('should handle invalid video paths gracefully', () async {
        final info = await compressor.getVideoInfo('');
        expect(info, isNull);

        final estimate = await compressor.getCompressionEstimate(
          '',
          VVideoCompressQuality.medium,
        );
        expect(estimate, isNull);

        final result = await compressor.compressVideo(
          '',
          const VVideoCompressionConfig.medium(),
        );
        expect(result, isNull);
      });

      test('should handle invalid configurations gracefully', () async {
        const invalidConfig = VVideoCompressionConfig.medium(
          advanced: VVideoAdvancedConfig(
            customWidth: 100, // Missing height
          ),
        );

        final result = await compressor.compressVideo(
          '/valid/path.mp4',
          invalidConfig,
        );
        expect(result, isNull);
      });
    });
  });
}
