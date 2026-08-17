package com.hospisoft.benhvien7c

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.MediaStore
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.hospisoft.benhvien7c/gallery_picker"
    private val REQUEST_CODE_GALLERY = 8991
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openNativeGalleryApp") {
                val mediaType = call.argument<String>("mediaType") ?: "all"
                if (pendingResult != null) {
                    result.error("BUSY", "Gallery picker already open", null)
                    return@setMethodCallHandler
                }
                pendingResult = result
                launchNativeGalleryApp(mediaType)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun launchNativeGalleryApp(mediaType: String) {
        val intent = Intent(Intent.ACTION_PICK)
        when (mediaType) {
            "image" -> {
                intent.setDataAndType(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, "image/*")
                intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            }
            "video" -> {
                intent.setDataAndType(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, "video/*")
                intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, false)
            }
            else -> { // "all"
                intent.type = "*/*"
                intent.putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("image/*", "video/*"))
                intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            }
        }

        try {
            startActivityForResult(intent, REQUEST_CODE_GALLERY)
        } catch (e: Exception) {
            val fallbackIntent = Intent(Intent.ACTION_GET_CONTENT).apply {
                type = "*/*"
                putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("image/*", "video/*"))
                putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            }
            try {
                startActivityForResult(fallbackIntent, REQUEST_CODE_GALLERY)
            } catch (ex: Exception) {
                pendingResult?.error("CANNOT_OPEN", ex.localizedMessage, null)
                pendingResult = null
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_GALLERY) {
            val result = pendingResult ?: return
            pendingResult = null

            if (resultCode != Activity.RESULT_OK || data == null) {
                result.success(emptyList<Map<String, Any>>())
                return
            }

            val fileList = mutableListOf<Map<String, Any>>()
            val clipData = data.clipData

            if (clipData != null) {
                for (i in 0 until clipData.itemCount) {
                    val uri = clipData.getItemAt(i).uri
                    val fileInfo = processUriToFile(uri)
                    if (fileInfo != null) {
                        fileList.add(fileInfo)
                    }
                }
            } else if (data.data != null) {
                val uri = data.data!!
                val fileInfo = processUriToFile(uri)
                if (fileInfo != null) {
                    fileList.add(fileInfo)
                }
            }

            result.success(fileList)
        }
    }

    private fun processUriToFile(uri: Uri): Map<String, Any>? {
        return try {
            var fileName = "media_${System.currentTimeMillis()}"
            contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (nameIndex != -1 && cursor.moveToFirst()) {
                    fileName = cursor.getString(nameIndex)
                }
            }

            val cacheFile = File(cacheDir, "gallery_$fileName")
            contentResolver.openInputStream(uri)?.use { inputStream ->
                FileOutputStream(cacheFile).use { outputStream ->
                    inputStream.copyTo(outputStream)
                }
            }

            mapOf(
                "fileName" to fileName,
                "filePath" to cacheFile.absolutePath,
                "sizeBytes" to cacheFile.length()
            )
        } catch (e: Exception) {
            null
        }
    }
}
