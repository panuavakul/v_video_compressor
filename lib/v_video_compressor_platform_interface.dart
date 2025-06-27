import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'v_video_compressor_method_channel.dart';
import 'v_video_compressor.dart';

abstract class VVideoCompressorPlatform extends PlatformInterface {
  /// Constructs a VVideoCompressorPlatform.
  VVideoCompressorPlatform() : super(token: _token);

  static final Object _token = Object();

  static VVideoCompressorPlatform _instance = MethodChannelVVideoCompressor();

  /// The default instance of [VVideoCompressorPlatform] to use.
  ///
  /// Defaults to [MethodChannelVVideoCompressor].
  static VVideoCompressorPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [VVideoCompressorPlatform] when
  /// they register themselves.
  static set instance(VVideoCompressorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<VVideoInfo?> getVideoInfo(String videoPath) {
    throw UnimplementedError('getVideoInfo() has not been implemented.');
  }

  Future<VVideoCompressionEstimate?> getCompressionEstimate(
    String videoPath,
    VVideoCompressQuality quality, {
    VVideoAdvancedConfig? advanced,
  }) {
    throw UnimplementedError(
      'getCompressionEstimate() has not been implemented.',
    );
  }

  Future<VVideoCompressionResult?> compressVideo(
    String videoPath,
    VVideoCompressionConfig config, {
    void Function(double progress)? onProgress,
  }) {
    throw UnimplementedError('compressVideo() has not been implemented.');
  }

  Future<List<VVideoCompressionResult>> compressVideos(
    List<String> videoPaths,
    VVideoCompressionConfig config, {
    void Function(double progress, int currentIndex, int total)? onProgress,
  }) {
    throw UnimplementedError('compressVideos() has not been implemented.');
  }

  Future<void> cancelCompression() {
    throw UnimplementedError('cancelCompression() has not been implemented.');
  }

  Future<bool> isCompressing() {
    throw UnimplementedError('isCompressing() has not been implemented.');
  }

  Future<VVideoThumbnailResult?> getVideoThumbnail(
    String videoPath,
    VVideoThumbnailConfig config,
  ) {
    throw UnimplementedError('getVideoThumbnail() has not been implemented.');
  }

  Future<List<VVideoThumbnailResult>> getVideoThumbnails(
    String videoPath,
    List<VVideoThumbnailConfig> configs,
  ) {
    throw UnimplementedError('getVideoThumbnails() has not been implemented.');
  }

  Future<void> cleanup() {
    throw UnimplementedError('cleanup() has not been implemented.');
  }

  Future<void> cleanupFiles({
    bool deleteThumbnails = true,
    bool deleteCompressedVideos = false,
    bool clearCache = true,
  }) {
    throw UnimplementedError('cleanupFiles() has not been implemented.');
  }
}
