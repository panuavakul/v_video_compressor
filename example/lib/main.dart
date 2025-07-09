import 'package:flutter/material.dart';
import 'package:v_video_compressor/v_video_compressor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gal/gal.dart';
import 'dart:io';
import 'advanced_compression_page.dart';

void main() {
  runApp(const VideoCompressorApp());
}

class VideoCompressorApp extends StatelessWidget {
  const VideoCompressorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Video Compressor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const VideoCompressorPage(),
    );
  }
}

class VideoCompressorPage extends StatefulWidget {
  const VideoCompressorPage({super.key});

  @override
  State<VideoCompressorPage> createState() => _VideoCompressorPageState();
}

class _VideoCompressorPageState extends State<VideoCompressorPage> {
  final VVideoCompressor _compressor = VVideoCompressor();

  // Video state
  String? _videoPath;
  VVideoInfo? _videoInfo;

  // Thumbnail state
  VVideoThumbnailResult? _thumbnailResult;
  bool _isGeneratingThumbnail = false;

  // Compression state
  bool _isCompressing = false;
  double _compressionProgress = 0.0;
  VVideoCompressionResult? _result;

  // Gallery saving state
  bool _isSavingToGallery = false;
  bool _savedToGallery = false;

  // Error handling
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Compressor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildVideoSelector(),
            if (_videoInfo != null) ...[
              const SizedBox(height: 20),
              _buildVideoInfo(),
            ],
            if (_videoPath != null && !_isCompressing) ...[
              const SizedBox(height: 20),
              _buildCompressionControls(),
            ],
            if (_isCompressing) ...[
              const SizedBox(height: 20),
              _buildCompressionProgress(),
            ],
            if (_result != null) ...[
              const SizedBox(height: 20),
              _buildCompressionResult(),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              _buildErrorMessage(),
            ],
            ElevatedButton(
              onPressed: _isCompressing ? null : _pickVideo,
              child: Text('Pick Video'),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showOrientationFixDemo,
              icon: Icon(Icons.screen_rotation),
              label: Text('Orientation Fix Demo'),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.video_library, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Select Video to Compress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickVideo,
              icon: const Icon(Icons.file_upload),
              label: Text(_videoPath == null ? 'Choose Video' : 'Change Video'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            if (_videoPath != null) ...[
              const SizedBox(height: 12),
              Text(
                'Selected: ${_getFileName(_videoPath!)}',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVideoInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Video Information & Thumbnail',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail Section
                Expanded(flex: 1, child: _buildThumbnailSection()),
                const SizedBox(width: 20),
                // Video Info Section
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Duration', _videoInfo!.durationFormatted),
                      _buildInfoRow(
                        'Resolution',
                        '${_videoInfo!.width} × ${_videoInfo!.height}',
                      ),
                      _buildInfoRow('File Size', _videoInfo!.fileSizeFormatted),
                      _buildInfoRow(
                        'Format',
                        _videoInfo!.name.split('.').last.toUpperCase(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailSection() {
    return Column(
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _isGeneratingThumbnail
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Generating thumbnail...'),
                      ],
                    ),
                  )
                : _thumbnailResult != null &&
                      File(_thumbnailResult!.thumbnailPath).existsSync()
                ? Image.file(
                    File(_thumbnailResult!.thumbnailPath),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'No thumbnail',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        if (_thumbnailResult != null) ...[
          const SizedBox(height: 8),
          Text(
            '${_thumbnailResult!.width} × ${_thumbnailResult!.height}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          Text(
            _thumbnailResult!.fileSizeFormatted,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCompressionControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Compression Quality',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildQualityButton(
              'High Quality (1080p)',
              'Best quality, larger file size',
              VVideoCompressQuality.high,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildQualityButton(
              'Medium Quality (720p)',
              'Good balance of quality and size',
              VVideoCompressQuality.medium,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildQualityButton(
              'Low Quality (480p)',
              'Smaller file size, lower quality',
              VVideoCompressQuality.low,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildQualityButton(
              'Very Low Quality (360p)',
              'Smallest file size, lowest quality',
              VVideoCompressQuality.veryLow,
              Colors.red,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            _buildAdvancedSettingsButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityButton(
    String title,
    String description,
    VVideoCompressQuality quality,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _compressVideo(quality),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      description,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedSettingsButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: InkWell(
        onTap: _openAdvancedSettings,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Advanced Custom Settings',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Full control over all compression parameters',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Custom bitrates, codecs, and resolution\n'
                      '• Advanced video/audio settings\n'
                      '• Trim, rotate, and color adjustments\n'
                      '• Presets for maximum compression',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompressionProgress() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Compressing Video...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _compressionProgress),
            const SizedBox(height: 8),
            Text(
              '${(_compressionProgress * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cancelCompression,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompressionResult() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.check_circle, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Compression Complete!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildResultRow('Original Size', _result!.originalSizeFormatted),
            _buildResultRow(
              'Compressed Size',
              _result!.compressedSizeFormatted,
            ),
            _buildResultRow('Space Saved', _result!.spaceSavedFormatted),
            _buildResultRow(
              'Compression Ratio',
              '${_result!.compressionRatio.toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSavingToGallery ? null : _saveToGallery,
                    icon: _isSavingToGallery
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(_savedToGallery ? Icons.check : Icons.save),
                    label: Text(
                      _isSavingToGallery
                          ? 'Saving...'
                          : _savedToGallery
                          ? 'Saved to Gallery'
                          : 'Save to Gallery',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _savedToGallery ? Colors.green : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Compress Another'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() => _errorMessage = null),
              child: const Text('Dismiss'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickVideo() async {
    try {
      setState(() => _errorMessage = null);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final videoPath = result.files.single.path!;
        setState(() {
          _videoPath = videoPath;
          _videoInfo = null;
          _thumbnailResult = null;
          _isGeneratingThumbnail = false;
          _result = null;
        });

        await _loadVideoInfo(videoPath);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error selecting video: $e');
    }
  }

  Future<void> _loadVideoInfo(String videoPath) async {
    try {
      final videoInfo = await _compressor.getVideoInfo(videoPath);
      setState(() => _videoInfo = videoInfo);

      // Generate thumbnail automatically after video info is loaded
      await _generateThumbnail(videoPath);
    } catch (e) {
      setState(() => _errorMessage = 'Error loading video info: $e');
    }
  }

  Future<void> _generateThumbnail(String videoPath) async {
    setState(() {
      _isGeneratingThumbnail = true;
      _thumbnailResult = null;
    });

    try {
      final config = const VVideoThumbnailConfig.defaults(
        timeMs: 1000, // Extract thumbnail at 2 seconds
        maxWidth: 300,
        maxHeight: 300,
        format: VThumbnailFormat.jpeg,
        quality: 85,
      );

      final thumbnail = await _compressor.getVideoThumbnail(videoPath, config);

      setState(() {
        _thumbnailResult = thumbnail;
        _isGeneratingThumbnail = false;
      });
    } catch (e) {
      setState(() {
        _isGeneratingThumbnail = false;
        _errorMessage = 'Error generating thumbnail: $e';
      });
    }
  }

  Future<void> _compressVideo(VVideoCompressQuality quality) async {
    if (_videoPath == null) return;

    setState(() {
      _isCompressing = true;
      _compressionProgress = 0.0;
      _result = null;
      _errorMessage = null;
    });

    try {
      final config = VVideoCompressionConfig(
        quality: quality,
        advanced: VVideoAdvancedConfig(
          autoCorrectOrientation: true,
          videoBitrate: 1500000,
          audioBitrate: 128000,
        ),
      );

      final result = await _compressor.compressVideo(
        _videoPath!,
        config,
        onProgress: (progress) {
          setState(() => _compressionProgress = progress);
        },
      );

      setState(() {
        _isCompressing = false;
        _result = result;
      });

      if (result != null) {
        debugPrint('✅ Vertical video compressed successfully!');
        debugPrint('Original: ${result.originalResolution}');
        debugPrint('Compressed: ${result.compressedResolution}');
        debugPrint(
          'Orientation preserved: ${result.originalResolution.contains('x')}',
        );
      }
    } catch (e) {
      setState(() {
        _isCompressing = false;
        _errorMessage = 'Compression failed: $e';
      });
    }
  }

  Future<void> _compressVideoWithConfig(VVideoCompressionConfig config) async {
    if (_videoPath == null) return;

    setState(() {
      _isCompressing = true;
      _compressionProgress = 0.0;
      _result = null;
      _errorMessage = null;
    });

    try {
      final result = await _compressor.compressVideo(
        _videoPath!,
        config,
        onProgress: (progress) {
          setState(() => _compressionProgress = progress);
        },
      );

      setState(() {
        _isCompressing = false;
        _result = result;
      });
    } catch (e) {
      setState(() {
        _isCompressing = false;
        _errorMessage = 'Compression failed: $e';
      });
    }
  }

  void _openAdvancedSettings() {
    if (_videoPath == null || _videoInfo == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdvancedCompressionPage(
          videoPath: _videoPath!,
          videoInfo: _videoInfo!,
          onCompress: _compressVideoWithConfig,
        ),
      ),
    );
  }

  Future<void> _cancelCompression() async {
    try {
      await _compressor.cancelCompression();
      setState(() => _isCompressing = false);
    } catch (e) {
      setState(() => _errorMessage = 'Error canceling compression: $e');
    }
  }

  void _reset() {
    setState(() {
      _videoPath = null;
      _videoInfo = null;
      _thumbnailResult = null;
      _isGeneratingThumbnail = false;
      _result = null;
      _errorMessage = null;
      _isCompressing = false;
      _compressionProgress = 0.0;
      _isSavingToGallery = false;
      _savedToGallery = false;
    });
  }

  Future<void> _saveToGallery() async {
    if (_result == null) return;

    setState(() {
      _isSavingToGallery = true;
      _errorMessage = null;
    });

    try {
      await Gal.putVideo(_result!.compressedFilePath);

      setState(() {
        _isSavingToGallery = false;
        _savedToGallery = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Video saved to gallery successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSavingToGallery = false;
        _errorMessage = 'Error saving to gallery: $e';
      });
    }
  }

  String _getFileName(String path) {
    return path.split('/').last;
  }

  void _showOrientationFixDemo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🎥 Orientation Fix Demo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📱 The new autoCorrectOrientation feature ensures:'),
            SizedBox(height: 8),
            Text('• Vertical videos stay vertical after compression'),
            Text('• Portrait videos maintain their 9:16 aspect ratio'),
            Text('• No more horizontal display of vertical content'),
            Text('• Automatic detection of original video orientation'),
            SizedBox(height: 12),
            Text('💡 Usage:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'VVideoAdvancedConfig(\n'
                '  autoCorrectOrientation: true,\n'
                '  // other settings...\n'
                ')',
                style: TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it!'),
          ),
        ],
      ),
    );
  }
}
