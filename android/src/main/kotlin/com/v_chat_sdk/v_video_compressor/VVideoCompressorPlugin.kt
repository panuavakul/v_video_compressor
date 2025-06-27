package com.v_chat_sdk.v_video_compressor

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

/** VVideoCompressorPlugin */
class VVideoCompressorPlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    
    /// The MethodChannel that will handle communication between Flutter and native Android
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context
    
    // Core components
    private lateinit var compressionEngine: VVideoCompressionEngine
    
    // Coroutine scope for background operations
    private val pluginScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    
    // Event sink for progress updates
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        
        // Initialize core components
        compressionEngine = VVideoCompressionEngine(context)
        
        // Set up method channel
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "v_video_compressor")
        methodChannel.setMethodCallHandler(this)
        
        // Set up event channel for progress updates
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "v_video_compressor/progress")
        eventChannel.setStreamHandler(this)
    }
    
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            
            "getVideoInfo" -> {
                handleGetVideoInfo(call, result)
            }
            
            "getCompressionEstimate" -> {
                handleGetCompressionEstimate(call, result)
            }
            
            "compressVideo" -> {
                handleCompressVideo(call, result)
            }
            
            "compressVideos" -> {
                handleCompressVideos(call, result)
            }
            
            "cancelCompression" -> {
                handleCancelCompression(result)
            }
            
            "isCompressing" -> {
                result.success(compressionEngine.isCompressing())
            }
            
            "getVideoThumbnail" -> {
                handleGetVideoThumbnail(call, result)
            }
            
            "getVideoThumbnails" -> {
                handleGetVideoThumbnails(call, result)
            }
            
            "cleanup" -> {
                handleCleanup(result)
            }
            
            "cleanupFiles" -> {
                handleCleanupFiles(call, result)
            }
            
            else -> {
                result.notImplemented()
            }
        }
    }
    
    private fun handleGetVideoInfo(call: MethodCall, result: Result) {
        val videoPath = call.argument<String>("videoPath")
        if (videoPath == null) {
            result.error("INVALID_ARGUMENT", "Video path is required", null)
            return
        }
        
        pluginScope.launch {
            try {
                val videoInfo = withContext(Dispatchers.IO) {
                    compressionEngine.getVideoInfo(videoPath)
                }
                
                if (videoInfo != null) {
                    result.success(videoInfo.toMap())
                } else {
                    result.success(null)
                }
            } catch (e: Exception) {
                result.error("ERROR", "Failed to get video info: ${e.message}", null)
            }
        }
    }
    
    private fun handleGetCompressionEstimate(call: MethodCall, result: Result) {
        val videoPath = call.argument<String>("videoPath")
        val qualityStr = call.argument<String>("quality")
        val advancedMap = call.argument<Map<String, Any?>>("advanced")
        
        if (videoPath == null || qualityStr == null) {
            result.error("INVALID_ARGUMENT", "Video path and quality are required", null)
            return
        }
        
        pluginScope.launch {
            try {
                val videoInfo = withContext(Dispatchers.IO) {
                    compressionEngine.getVideoInfo(videoPath)
                }
                
                if (videoInfo == null) {
                    result.error("ERROR", "Could not get video info", null)
                    return@launch
                }
                
                val quality = VVideoCompressQuality.fromString(qualityStr)
                val advanced = VVideoAdvancedConfig.fromMap(advancedMap)
                val estimate = compressionEngine.estimateCompressionSize(videoInfo, quality, advanced)
                
                result.success(estimate.toMap())
            } catch (e: Exception) {
                result.error("ERROR", "Failed to get compression estimate: ${e.message}", null)
            }
        }
    }
    
    private fun handleCompressVideo(call: MethodCall, result: Result) {
        val videoPath = call.argument<String>("videoPath")
        val configMap = call.argument<Map<String, Any?>>("config")
        
        if (videoPath == null || configMap == null) {
            result.error("INVALID_ARGUMENT", "Video path and config are required", null)
            return
        }
        
        pluginScope.launch {
            try {
                val videoInfo = withContext(Dispatchers.IO) {
                    compressionEngine.getVideoInfo(videoPath)
                }
                
                if (videoInfo == null) {
                    result.error("ERROR", "Could not get video info", null)
                    return@launch
                }
                
                val config = VVideoCompressionConfig.fromMap(configMap)
                
                compressionEngine.compressVideo(
                    videoInfo = videoInfo,
                    config = config,
                    callback = object : VVideoCompressionEngine.CompressionCallback {
                        override fun onProgress(progress: Float) {
                            // Send progress update through event channel
                            mainHandler.post {
                                eventSink?.success(mapOf("progress" to progress))
                            }
                        }
                        
                        override fun onComplete(compressionResult: VVideoCompressionResult) {
                            result.success(compressionResult.toMap())
                        }
                        
                        override fun onError(error: String) {
                            result.error("COMPRESSION_ERROR", error, null)
                        }
                    }
                )
            } catch (e: Exception) {
                result.error("ERROR", "Failed to start compression: ${e.message}", null)
            }
        }
    }
    
    private fun handleCompressVideos(call: MethodCall, result: Result) {
        val videoPaths = call.argument<List<String>>("videoPaths")
        val configMap = call.argument<Map<String, Any?>>("config")
        
        if (videoPaths == null || configMap == null) {
            result.error("INVALID_ARGUMENT", "Video paths and config are required", null)
            return
        }
        
        pluginScope.launch {
            try {
                val config = VVideoCompressionConfig.fromMap(configMap)
                val results = mutableListOf<VVideoCompressionResult>()
                val totalVideos = videoPaths.size
                
                for (i in videoPaths.indices) {
                    val videoPath = videoPaths[i]
                    
                    val videoInfo = withContext(Dispatchers.IO) {
                        compressionEngine.getVideoInfo(videoPath)
                    }
                    
                    if (videoInfo == null) {
                        // Skip invalid videos but continue with others
                        continue
                    }
                    
                    // Use a suspending approach for sequential compression
                    var compressionCompleted = false
                    var compressionResult: VVideoCompressionResult? = null
                    var compressionError: String? = null
                    
                    compressionEngine.compressVideo(
                        videoInfo = videoInfo,
                        config = config,
                        callback = object : VVideoCompressionEngine.CompressionCallback {
                            override fun onProgress(progress: Float) {
                                // Calculate overall progress
                                val overallProgress = (i + progress) / totalVideos
                                
                                // Send batch progress update through event channel
                                mainHandler.post {
                                    eventSink?.success(mapOf(
                                        "progress" to overallProgress,
                                        "currentIndex" to i,
                                        "total" to totalVideos
                                    ))
                                }
                            }
                            
                            override fun onComplete(result: VVideoCompressionResult) {
                                compressionResult = result
                                compressionCompleted = true
                            }
                            
                            override fun onError(error: String) {
                                compressionError = error
                                compressionCompleted = true
                            }
                        }
                    )
                    
                    // Wait for compression to complete
                    while (!compressionCompleted) {
                        kotlinx.coroutines.delay(100)
                    }
                    
                    if (compressionError != null) {
                        result.error("COMPRESSION_ERROR", "Failed to compress ${videoInfo.name}: $compressionError", null)
                        return@launch
                    }
                    
                    compressionResult?.let { results.add(it) }
                }
                
                result.success(results.map { it.toMap() })
            } catch (e: Exception) {
                result.error("ERROR", "Failed to compress videos: ${e.message}", null)
            }
        }
    }
    
    private fun handleCancelCompression(result: Result) {
        try {
            compressionEngine.cancelCompression()
            result.success(null)
        } catch (e: Exception) {
            result.error("ERROR", "Failed to cancel compression: ${e.message}", null)
        }
    }
    
    private fun handleGetVideoThumbnail(call: MethodCall, result: Result) {
        val videoPath = call.argument<String>("videoPath")
        val configMap = call.argument<Map<String, Any?>>("config")
        
        if (videoPath == null || configMap == null) {
            result.error("INVALID_ARGUMENT", "Video path and config are required", null)
            return
        }
        
        pluginScope.launch {
            try {
                val videoInfo = withContext(Dispatchers.IO) {
                    compressionEngine.getVideoInfo(videoPath)
                }
                
                if (videoInfo == null) {
                    result.error("ERROR", "Could not get video info", null)
                    return@launch
                }
                
                val config = VVideoThumbnailConfig.fromMap(configMap)
                val thumbnail = compressionEngine.getVideoThumbnail(videoInfo, config)
                
                if (thumbnail != null) {
                    result.success(thumbnail.toMap())
                } else {
                    result.success(null)
                }
            } catch (e: Exception) {
                result.error("ERROR", "Failed to get video thumbnail: ${e.message}", null)
            }
        }
    }
    
    private fun handleGetVideoThumbnails(call: MethodCall, result: Result) {
        val videoPath = call.argument<String>("videoPath")
        val configMaps = call.argument<List<Map<String, Any?>>>("configs")
        
        if (videoPath == null || configMaps == null) {
            result.error("INVALID_ARGUMENT", "Video path and configs are required", null)
            return
        }
        
        pluginScope.launch {
            try {
                val videoInfo = withContext(Dispatchers.IO) {
                    compressionEngine.getVideoInfo(videoPath)
                }
                
                if (videoInfo == null) {
                    result.error("ERROR", "Could not get video info", null)
                    return@launch
                }
                
                val thumbnails = mutableListOf<Map<String, Any>>()
                
                for (configMap in configMaps) {
                    val config = VVideoThumbnailConfig.fromMap(configMap)
                    val thumbnail = compressionEngine.getVideoThumbnail(videoInfo, config)
                    
                    if (thumbnail != null) {
                        thumbnails.add(thumbnail.toMap())
                    }
                }
                
                result.success(thumbnails)
            } catch (e: Exception) {
                result.error("ERROR", "Failed to get video thumbnails: ${e.message}", null)
            }
        }
    }
    
    private fun handleCleanup(result: Result) {
        pluginScope.launch {
            try {
                // Cancel any ongoing compression
                compressionEngine.cancelCompression()
                
                // Clean up all temporary files and cache
                val cleanupResult = compressionEngine.cleanup()
                
                result.success(cleanupResult)
            } catch (e: Exception) {
                result.error("CLEANUP_ERROR", "Failed to cleanup: ${e.message}", null)
            }
        }
    }
    
    private fun handleCleanupFiles(call: MethodCall, result: Result) {
        val deleteThumbnails = call.argument<Boolean>("deleteThumbnails") ?: true
        val deleteCompressedVideos = call.argument<Boolean>("deleteCompressedVideos") ?: false
        val clearCache = call.argument<Boolean>("clearCache") ?: true
        
        pluginScope.launch {
            try {
                val cleanupResult = compressionEngine.cleanupFiles(
                    deleteThumbnails = deleteThumbnails,
                    deleteCompressedVideos = deleteCompressedVideos,
                    clearCache = clearCache
                )
                
                result.success(cleanupResult)
            } catch (e: Exception) {
                result.error("CLEANUP_ERROR", "Failed to cleanup files: ${e.message}", null)
            }
        }
    }
    
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        
        // Cancel any ongoing compression
        compressionEngine.cancelCompression()
    }
    
    // EventChannel.StreamHandler implementation
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }
    
    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}
