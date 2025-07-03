# Memory Optimization Guide for V Video Compressor

## Overview

This guide addresses the OutOfMemoryError issues that can occur during video compression in production environments. We've implemented several memory optimizations to prevent these errors, but it's important to understand how to use the plugin efficiently.

## The OutOfMemoryError Issue

The reported error occurred at:

```
java.lang.OutOfMemoryError at File.length()
in VVideoCompressionEngine.startProgressTracking (line 353)
```

This was caused by:

1. Frequent file I/O operations (checking file size every 100ms)
2. Lack of memory pressure handling
3. Resource leaks from MediaMetadataRetriever
4. Accumulation of coroutine objects

## Implemented Solutions

### 1. Memory Management

- **Pre-compression Memory Check**: The plugin now checks available memory before starting compression
- **Minimum Memory Threshold**: Requires at least 100MB free memory
- **Storage Check**: Ensures sufficient storage space (video size + 200MB buffer)

### 2. Reduced File I/O Operations

- **File Size Caching**: Caches file size for 500ms to reduce system calls
- **Batch Updates**: Progress updates are batched to reduce main thread pressure

### 3. Resource Management

- **Proper Resource Cleanup**: All MediaMetadataRetriever instances are properly released
- **Garbage Collection**: Strategic GC calls during low memory conditions
- **Coroutine Lifecycle**: Proper cancellation and cleanup of coroutines

### 4. Error Handling

- **Graceful Degradation**: Plugin continues working in low memory conditions
- **Clear Error Messages**: Specific error messages for memory issues

## Best Practices for Production

### 1. Video Quality Selection

```dart
// For low-memory devices, use lower quality settings
final quality = await getDeviceMemory() < 2048
    ? VideoQuality.low
    : VideoQuality.medium;
```

### 2. Batch Processing

```dart
// Process videos in smaller batches to avoid memory pressure
const batchSize = 3;
for (var i = 0; i < videos.length; i += batchSize) {
  final batch = videos.skip(i).take(batchSize).toList();
  await compressVideoBatch(batch);

  // Allow memory to be freed between batches
  await Future.delayed(Duration(seconds: 1));
}
```

### 3. Memory Monitoring

```dart
// Monitor device memory before compression
Future<bool> hasEnoughMemory() async {
  // Platform-specific memory check implementation
  final availableMemory = await getAvailableMemory();
  return availableMemory > 100 * 1024 * 1024; // 100MB
}

// Use before compression
if (!await hasEnoughMemory()) {
  showLowMemoryWarning();
  return;
}
```

### 4. Error Recovery

```dart
try {
  final result = await VVideoCompressor.compressVideo(
    videoPath: path,
    quality: VideoQuality.medium,
  );
} catch (e) {
  if (e.toString().contains('OUT_OF_MEMORY')) {
    // Try again with lower quality
    final result = await VVideoCompressor.compressVideo(
      videoPath: path,
      quality: VideoQuality.ultraLow,
    );
  }
}
```

### 5. Progressive Quality Reduction

```dart
Future<CompressionResult?> compressWithFallback(String videoPath) async {
  final qualities = [
    VideoQuality.high,
    VideoQuality.medium,
    VideoQuality.low,
    VideoQuality.veryLow,
    VideoQuality.ultraLow,
  ];

  for (final quality in qualities) {
    try {
      return await VVideoCompressor.compressVideo(
        videoPath: videoPath,
        quality: quality,
      );
    } catch (e) {
      if (e.toString().contains('OUT_OF_MEMORY')) {
        print('Memory error with $quality, trying lower quality...');
        continue;
      }
      rethrow;
    }
  }

  return null; // All qualities failed
}
```

### 6. Clean Up Resources

```dart
// Always clean up after compression sessions
await VVideoCompressor.cleanup(
  deleteThumbnails: true,
  clearCache: true,
);
```

## Advanced Configuration for Low Memory

### 1. Aggressive Compression

```dart
final result = await VVideoCompressor.compressVideo(
  videoPath: videoPath,
  quality: VideoQuality.low,
  advanced: VVideoAdvancedConfig(
    aggressiveCompression: true,
    variableBitrate: true,
    reducedFrameRate: 24.0, // Reduce from 30fps
  ),
);
```

### 2. Custom Resolution

```dart
// Reduce resolution for memory-constrained devices
final result = await VVideoCompressor.compressVideo(
  videoPath: videoPath,
  quality: VideoQuality.medium,
  advanced: VVideoAdvancedConfig(
    customWidth: 640,
    customHeight: 480,
  ),
);
```

### 3. Remove Audio

```dart
// Save memory by removing audio track
final result = await VVideoCompressor.compressVideo(
  videoPath: videoPath,
  quality: VideoQuality.medium,
  advanced: VVideoAdvancedConfig(
    removeAudio: true,
  ),
);
```

## Monitoring and Analytics

### Track Memory Errors

```dart
void trackCompressionError(dynamic error) {
  if (error.toString().contains('OUT_OF_MEMORY')) {
    // Send to analytics
    analytics.logEvent('video_compression_oom', {
      'device_memory': getDeviceMemory(),
      'available_memory': getAvailableMemory(),
      'video_size': getVideoSize(),
    });
  }
}
```

### Memory Usage Metrics

```dart
// Log memory usage before and after compression
final memoryBefore = await getAvailableMemory();
final result = await compressVideo(path);
final memoryAfter = await getAvailableMemory();

analytics.logEvent('compression_memory_usage', {
  'memory_used_mb': (memoryBefore - memoryAfter) / 1024 / 1024,
  'compression_ratio': result.compressionRatio,
});
```

## Platform-Specific Considerations

### Android

- Devices with < 2GB RAM are at higher risk
- Use `android:largeHeap="true"` in AndroidManifest.xml for video-heavy apps
- Consider using `android:hardwareAccelerated="true"`

### iOS

- Generally better memory management than Android
- Still implement checks for older devices (iPhone 6/7)
- Use lower quality settings for devices with < 2GB RAM

## Testing for Memory Issues

### 1. Test on Low-End Devices

- Test on devices with 1-2GB RAM
- Use Android emulators with limited memory
- Test with large video files (>500MB)

### 2. Stress Testing

```dart
// Test multiple compressions in sequence
Future<void> stressTest() async {
  final videos = getLargeVideoFiles(); // Get 10+ large videos

  for (final video in videos) {
    try {
      await compressVideo(video);
      print('Compressed: $video');
    } catch (e) {
      print('Failed at video ${videos.indexOf(video)}: $e');
      break;
    }
  }
}
```

### 3. Memory Profiling

- Use Android Studio Memory Profiler
- Monitor heap usage during compression
- Look for memory leaks in repeated compressions

## Conclusion

By following these guidelines and using the improved memory management features, you can significantly reduce the likelihood of OutOfMemoryError in production. Always test on low-end devices and implement progressive fallback strategies for the best user experience.
