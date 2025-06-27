import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'v_video_compressor_platform_interface.dart';
import 'v_video_compressor.dart';

/// Internal logging utility for method channel operations
class _MethodChannelLogger {
  static const String _tag = 'VVideoCompressor.MethodChannel';

  static void info(String message, [Object? error]) {
    developer.log(message, name: _tag, level: 800, error: error);
  }

  static void warning(String message, [Object? error]) {
    developer.log(message, name: _tag, level: 900, error: error);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(message,
        name: _tag, level: 1000, error: error, stackTrace: stackTrace);
  }

  static void methodCall(String methodName, Map<String, dynamic>? params) {
    final paramsStr =
        params?.entries.map((e) => '${e.key}: ${e.value}').join(', ') ??
            'no params';
    info('Native call: $methodName($paramsStr)');
  }

  static void methodResult(String methodName, dynamic result,
      [Duration? duration]) {
    final durationStr =
        duration != null ? ' (${duration.inMilliseconds}ms)' : '';
    info(
        'Native result: $methodName completed$durationStr - ${result != null ? 'SUCCESS' : 'NULL'}');
  }

  static void methodError(String methodName, Object error,
      [Duration? duration]) {
    final durationStr =
        duration != null ? ' (${duration.inMilliseconds}ms)' : '';
    _MethodChannelLogger.error(
        'Native error: $methodName failed$durationStr', error);
  }
}

/// An implementation of [VVideoCompressorPlatform] that uses method channels.
class MethodChannelVVideoCompressor extends VVideoCompressorPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('v_video_compressor');

  /// The event channel for progress updates
  final eventChannel = const EventChannel('v_video_compressor/progress');

  @override
  Future<String?> getPlatformVersion() async {
    final stopwatch = Stopwatch()..start();
    try {
      _MethodChannelLogger.methodCall('getPlatformVersion', null);

      final version = await methodChannel.invokeMethod<String>(
        'getPlatformVersion',
      );

      stopwatch.stop();
      _MethodChannelLogger.methodResult(
          'getPlatformVersion', version, stopwatch.elapsed);

      return version;
    } catch (error, stackTrace) {
      stopwatch.stop();
      _MethodChannelLogger.methodError(
          'getPlatformVersion', error, stopwatch.elapsed);
      _MethodChannelLogger.error(
          'Failed to get platform version', error, stackTrace);
      return null;
    }
  }

  /// Helper method to convert Map\<Object?, Object?\> to Map\<String, dynamic\>
  /// Recursively handles nested maps and lists
  Map<String, dynamic> _convertToStringMap(Map<Object?, Object?> map) {
    final result = <String, dynamic>{};
    map.forEach((key, value) {
      final stringKey = key.toString();
      if (value is Map<Object?, Object?>) {
        result[stringKey] = _convertToStringMap(value);
      } else if (value is List) {
        result[stringKey] = value.map((item) {
          if (item is Map<Object?, Object?>) {
            return _convertToStringMap(item);
          }
          return item;
        }).toList();
      } else {
        result[stringKey] = value;
      }
    });
    return result;
  }

  @override
  Future<VVideoInfo?> getVideoInfo(String videoPath) async {
    final stopwatch = Stopwatch()..start();
    try {
      _MethodChannelLogger.methodCall('getVideoInfo', {'videoPath': videoPath});

      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'getVideoInfo',
        {'videoPath': videoPath},
      );

      stopwatch.stop();

      if (result != null) {
        final videoInfo = VVideoInfo.fromMap(_convertToStringMap(result));
        _MethodChannelLogger.methodResult(
            'getVideoInfo', videoInfo, stopwatch.elapsed);
        _MethodChannelLogger.info(
            'Video info retrieved: ${videoInfo.name} (${videoInfo.fileSizeFormatted}, ${videoInfo.durationFormatted})');
        return videoInfo;
      } else {
        _MethodChannelLogger.methodResult(
            'getVideoInfo', null, stopwatch.elapsed);
        _MethodChannelLogger.warning(
            'No video info returned for path: $videoPath');
        return null;
      }
    } catch (error, stackTrace) {
      stopwatch.stop();
      _MethodChannelLogger.methodError(
          'getVideoInfo', error, stopwatch.elapsed);
      _MethodChannelLogger.error(
          'Error getting video info for path: $videoPath', error, stackTrace);
      return null;
    }
  }

  @override
  Future<VVideoCompressionEstimate?> getCompressionEstimate(
    String videoPath,
    VVideoCompressQuality quality, {
    VVideoAdvancedConfig? advanced,
  }) async {
    try {
      final params = <String, dynamic>{
        'videoPath': videoPath,
        'quality': quality.value,
      };

      // Add advanced configuration if provided
      if (advanced != null) {
        params['advanced'] = advanced.toMap();
      }

      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'getCompressionEstimate',
        params,
      );

      if (result != null) {
        return VVideoCompressionEstimate.fromMap(_convertToStringMap(result));
      }
      return null;
    } catch (e) {
      debugPrint('Error getting compression estimate: $e');
      return null;
    }
  }

  @override
  Future<VVideoCompressionResult?> compressVideo(
    String videoPath,
    VVideoCompressionConfig config, {
    void Function(double progress)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    StreamSubscription<dynamic>? progressSubscription;

    try {
      _MethodChannelLogger.methodCall('compressVideo', {
        'videoPath': videoPath,
        'quality': config.quality.value,
        'hasAdvanced': config.advanced != null,
        'hasProgressCallback': onProgress != null,
      });

      // Validate configuration before proceeding
      if (!config.isValid()) {
        throw ArgumentError('Invalid compression configuration');
      }

      // Set up progress listener if callback provided
      if (onProgress != null) {
        _MethodChannelLogger.info(
            'Setting up progress listener for compression');
        progressSubscription = eventChannel.receiveBroadcastStream().listen((
          event,
        ) {
          if (event is Map && event.containsKey('progress')) {
            final progress = (event['progress'] as num).toDouble();
            _MethodChannelLogger.info(
                'Compression progress: ${(progress * 100).toStringAsFixed(1)}%');
            onProgress(progress);
          }
        }, onError: (error) {
          _MethodChannelLogger.error('Progress subscription error', error);
        });
      }

      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'compressVideo',
        {'videoPath': videoPath, 'config': config.toMap()},
      );

      // Cancel progress subscription
      await progressSubscription?.cancel();
      stopwatch.stop();

      if (result != null) {
        final compressionResult =
            VVideoCompressionResult.fromMap(_convertToStringMap(result));
        _MethodChannelLogger.methodResult(
            'compressVideo', compressionResult, stopwatch.elapsed);
        _MethodChannelLogger.info(
            'Compression completed: ${compressionResult.originalSizeFormatted} → ${compressionResult.compressedSizeFormatted} (${compressionResult.compressionPercentage}% reduction)');
        return compressionResult;
      } else {
        _MethodChannelLogger.methodResult(
            'compressVideo', null, stopwatch.elapsed);
        _MethodChannelLogger.warning('No compression result returned');
        return null;
      }
    } catch (error, stackTrace) {
      await progressSubscription?.cancel();
      stopwatch.stop();
      _MethodChannelLogger.methodError(
          'compressVideo', error, stopwatch.elapsed);
      _MethodChannelLogger.error(
          'Video compression failed for: $videoPath', error, stackTrace);
      return null;
    }
  }

  @override
  Future<List<VVideoCompressionResult>> compressVideos(
    List<String> videoPaths,
    VVideoCompressionConfig config, {
    void Function(double progress, int currentIndex, int total)? onProgress,
  }) async {
    try {
      // Validate configuration before proceeding
      if (!config.isValid()) {
        throw ArgumentError('Invalid compression configuration');
      }

      // Set up progress listener if callback provided
      StreamSubscription<dynamic>? progressSubscription;
      if (onProgress != null) {
        progressSubscription = eventChannel.receiveBroadcastStream().listen((
          event,
        ) {
          if (event is Map &&
              event.containsKey('progress') &&
              event.containsKey('currentIndex') &&
              event.containsKey('total')) {
            final progress = (event['progress'] as num).toDouble();
            final currentIndex = event['currentIndex'] as int;
            final total = event['total'] as int;
            onProgress(progress, currentIndex, total);
          }
        });
      }

      final result = await methodChannel.invokeMethod<List<Object?>>(
        'compressVideos',
        {'videoPaths': videoPaths, 'config': config.toMap()},
      );

      // Cancel progress subscription
      await progressSubscription?.cancel();

      if (result != null) {
        return result
            .cast<Map<Object?, Object?>>()
            .map(
              (map) =>
                  VVideoCompressionResult.fromMap(_convertToStringMap(map)),
            )
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error compressing videos: $e');
      return [];
    }
  }

  @override
  Future<void> cancelCompression() async {
    try {
      await methodChannel.invokeMethod('cancelCompression');
    } catch (e) {
      debugPrint('Error canceling compression: $e');
    }
  }

  @override
  Future<bool> isCompressing() async {
    try {
      final result = await methodChannel.invokeMethod<bool>('isCompressing');
      return result ?? false;
    } catch (e) {
      debugPrint('Error checking compression status: $e');
      return false;
    }
  }

  @override
  Future<VVideoThumbnailResult?> getVideoThumbnail(
    String videoPath,
    VVideoThumbnailConfig config,
  ) async {
    try {
      // Validate configuration before proceeding
      if (!config.isValid()) {
        throw ArgumentError('Invalid thumbnail configuration');
      }

      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'getVideoThumbnail',
        {'videoPath': videoPath, 'config': config.toMap()},
      );

      if (result != null) {
        return VVideoThumbnailResult.fromMap(_convertToStringMap(result));
      }
      return null;
    } catch (e) {
      debugPrint('Error generating video thumbnail: $e');
      return null;
    }
  }

  @override
  Future<List<VVideoThumbnailResult>> getVideoThumbnails(
    String videoPath,
    List<VVideoThumbnailConfig> configs,
  ) async {
    try {
      // Validate all configurations before proceeding
      for (final config in configs) {
        if (!config.isValid()) {
          throw ArgumentError('Invalid thumbnail configuration');
        }
      }

      final result = await methodChannel
          .invokeMethod<List<Object?>>('getVideoThumbnails', {
        'videoPath': videoPath,
        'configs': configs.map((config) => config.toMap()).toList(),
      });

      if (result != null) {
        return result
            .cast<Map<Object?, Object?>>()
            .map(
              (map) => VVideoThumbnailResult.fromMap(_convertToStringMap(map)),
            )
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error generating video thumbnails: $e');
      return [];
    }
  }

  @override
  Future<void> cleanup() async {
    try {
      await methodChannel.invokeMethod('cleanup');
    } catch (e) {
      debugPrint('Error during cleanup: $e');
    }
  }

  @override
  Future<void> cleanupFiles({
    bool deleteThumbnails = true,
    bool deleteCompressedVideos = false,
    bool clearCache = true,
  }) async {
    try {
      await methodChannel.invokeMethod('cleanupFiles', {
        'deleteThumbnails': deleteThumbnails,
        'deleteCompressedVideos': deleteCompressedVideos,
        'clearCache': clearCache,
      });
    } catch (e) {
      debugPrint('Error during cleanup files: $e');
    }
  }
}
