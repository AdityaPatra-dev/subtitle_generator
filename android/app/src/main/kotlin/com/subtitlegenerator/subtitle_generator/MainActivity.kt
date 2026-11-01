package com.subtitlegenerator.subtitle_generator

import android.content.pm.PackageManager
import android.os.Build
import android.provider.MediaStore
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.subtitlegenerator.subtitle_generator/media_resolver"
    private val TAG = "MediaResolver"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestMediaPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        val granted = checkSelfPermission(android.Manifest.permission.READ_MEDIA_VIDEO) == PackageManager.PERMISSION_GRANTED
                        if (!granted) {
                            requestPermissions(arrayOf(android.Manifest.permission.READ_MEDIA_VIDEO), 101)
                        }
                        result.success(granted)
                    } else {
                        val granted = checkSelfPermission(android.Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
                        if (!granted) {
                            requestPermissions(arrayOf(android.Manifest.permission.READ_EXTERNAL_STORAGE), 101)
                        }
                        result.success(granted)
                    }
                }
                "getDisplayNameForMedia" -> {
                    val mediaId = call.argument<String>("mediaId")
                    val rawSize = call.argument<Number>("fileSizeBytes")
                    val fileSizeBytes = rawSize?.toLong()

                    Log.d(TAG, "Resolving video name for mediaId=$mediaId, size=$fileSizeBytes")

                    var resolvedName: String? = null

                    // 1. Try querying MediaStore by _ID
                    if (!mediaId.isNullOrEmpty()) {
                        try {
                            val uri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                            val projection = arrayOf(
                                MediaStore.Video.Media._ID,
                                MediaStore.Video.Media.DISPLAY_NAME,
                                MediaStore.Video.Media.TITLE
                            )
                            val selection = "${MediaStore.Video.Media._ID} = ?"
                            val selectionArgs = arrayOf(mediaId)

                            val cursor = contentResolver.query(uri, projection, selection, selectionArgs, null)
                            cursor?.use {
                                if (it.moveToFirst()) {
                                    val nameIdx = it.getColumnIndex(MediaStore.Video.Media.DISPLAY_NAME)
                                    val titleIdx = it.getColumnIndex(MediaStore.Video.Media.TITLE)
                                    resolvedName = if (nameIdx != -1) it.getString(nameIdx) else null
                                    if (resolvedName.isNullOrEmpty() && titleIdx != -1) {
                                        resolvedName = it.getString(titleIdx)
                                    }
                                    Log.d(TAG, "Found in MediaStore by ID: $resolvedName")
                                }
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Error querying by ID: ${e.message}")
                        }
                    }

                    // 2. If not resolved, try querying MediaStore by exact file size
                    if (resolvedName.isNullOrEmpty() && fileSizeBytes != null && fileSizeBytes > 0) {
                        try {
                            val uri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                            val projection = arrayOf(
                                MediaStore.Video.Media.DISPLAY_NAME,
                                MediaStore.Video.Media.TITLE
                            )
                            val selection = "${MediaStore.Video.Media.SIZE} = ?"
                            val selectionArgs = arrayOf(fileSizeBytes.toString())

                            val cursor = contentResolver.query(uri, projection, selection, selectionArgs, null)
                            cursor?.use {
                                if (it.moveToFirst()) {
                                    val nameIdx = it.getColumnIndex(MediaStore.Video.Media.DISPLAY_NAME)
                                    val titleIdx = it.getColumnIndex(MediaStore.Video.Media.TITLE)
                                    resolvedName = if (nameIdx != -1) it.getString(nameIdx) else null
                                    if (resolvedName.isNullOrEmpty() && titleIdx != -1) {
                                        resolvedName = it.getString(titleIdx)
                                    }
                                    Log.d(TAG, "Found in MediaStore by size: $resolvedName")
                                }
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Error querying by size: ${e.message}")
                        }
                    }

                    Log.d(TAG, "Final resolved video name: $resolvedName")
                    result.success(resolvedName)
                }
                else -> result.notImplemented()
            }
        }
    }
}
