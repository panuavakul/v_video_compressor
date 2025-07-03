package com.v_chat_sdk.v_video_compressor

import android.content.ContentResolver
import android.content.Context
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.provider.MediaStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.ensureActive

/**
 * Utility class for loading video files from device storage
 */
class VVideoMediaLoader(private val context: Context) {
    private val contentResolver: ContentResolver = context.contentResolver
    
    /**
     * Loads all videos from device storage with memory-efficient approach
     */
    suspend fun loadAllVideos(): List<VVideoInfo> = withContext(Dispatchers.IO) {
        val videoList = mutableListOf<VVideoInfo>()
        val projection = arrayOf(
            MediaStore.Video.Media._ID,
            MediaStore.Video.Media.DISPLAY_NAME,
            MediaStore.Video.Media.SIZE,
            MediaStore.Video.Media.DURATION,
            MediaStore.Video.Media.WIDTH,
            MediaStore.Video.Media.HEIGHT,
            MediaStore.Video.Media.DATE_ADDED,
            MediaStore.Video.Media.DATA // File path
        )
        
        val sortOrder = "${MediaStore.Video.Media.DATE_ADDED} DESC"
        
        try {
            contentResolver.query(
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                projection,
                null,
                null,
                sortOrder
            )?.use { cursor ->
                val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Video.Media._ID)
                val nameColumn = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DISPLAY_NAME)
                val sizeColumn = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.SIZE)
                val durationColumn = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DURATION)
                val widthColumn = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.WIDTH)
                val heightColumn = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.HEIGHT)
                val dateColumn = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DATE_ADDED)
                val dataColumn = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DATA)
                
                while (cursor.moveToNext()) {
                    // Check if coroutine is still active
                    ensureActive()
                    
                    try {
                        val id = cursor.getLong(idColumn)
                        val name = cursor.getString(nameColumn) ?: "Unknown"
                        val size = cursor.getLong(sizeColumn)
                        val duration = cursor.getLong(durationColumn)
                        var width = cursor.getInt(widthColumn)
                        var height = cursor.getInt(heightColumn)
                        val dateAdded = cursor.getLong(dateColumn)
                        val dataPath = cursor.getString(dataColumn)
                        
                        // Use the file path if available, otherwise construct URI
                        val videoPath = dataPath ?: run {
                            val contentUri = Uri.withAppendedPath(
                                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                                id.toString()
                            )
                            contentUri.toString()
                        }
                        
                        // If width/height are 0, try to get them from MediaMetadataRetriever
                        if (width == 0 || height == 0) {
                            var retriever: MediaMetadataRetriever? = null
                            try {
                                retriever = MediaMetadataRetriever()
                                if (dataPath != null) {
                                    retriever.setDataSource(dataPath)
                                } else {
                                    val contentUri = Uri.withAppendedPath(
                                        MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                                        id.toString()
                                    )
                                    retriever.setDataSource(context, contentUri)
                                }
                                width = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull() ?: width
                                height = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull() ?: height
                            } catch (e: Exception) {
                                // Keep the original values if retrieval fails
                            } finally {
                                retriever?.release()
                            }
                        }
                        
                        videoList.add(
                            VVideoInfo(
                                path = videoPath,
                                name = name,
                                fileSizeBytes = size,
                                durationMillis = duration,
                                width = width,
                                height = height
                            )
                        )
                        
                        // Periodically request garbage collection for large lists
                        if (videoList.size % 50 == 0) {
                            System.gc()
                        }
                    } catch (e: OutOfMemoryError) {
                        // Stop loading more videos if we're running out of memory
                        e.printStackTrace()
                        break
                    } catch (e: Exception) {
                        // Skip problematic video entries
                        e.printStackTrace()
                    }
                }
            }
        } catch (e: OutOfMemoryError) {
            e.printStackTrace()
            // Return what we've loaded so far
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        videoList
    }
    
    /**
     * Gets video duration from file path with proper resource management
     */
    suspend fun getVideoDuration(videoPath: String): Long = withContext(Dispatchers.IO) {
        var retriever: MediaMetadataRetriever? = null
        try {
            retriever = MediaMetadataRetriever()
            retriever.setDataSource(videoPath)
            val duration = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
            duration?.toLongOrNull() ?: 0L
        } catch (e: OutOfMemoryError) {
            0L
        } catch (e: Exception) {
            0L
        } finally {
            retriever?.release()
        }
    }
    
    /**
     * Gets video thumbnail path (this is a simplified implementation)
     */
    suspend fun getVideoThumbnailPath(videoPath: String): String? = withContext(Dispatchers.IO) {
        try {
            // For now, return null as thumbnail generation is complex
            // In a real implementation, you might want to generate thumbnails
            null
        } catch (e: Exception) {
            null
        }
    }
} 