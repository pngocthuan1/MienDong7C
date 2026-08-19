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
            } else if (call.method == "openFileWithExternalApp") {
                val filePath = call.argument<String>("filePath")
                if (filePath != null) {
                    openFileWithExternalApp(filePath, result)
                } else {
                    result.error("INVALID_PATH", "FilePath is null", null)
                }
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

    private fun openFileWithExternalApp(filePath: String, result: MethodChannel.Result) {
        try {
            val file = File(filePath)
            if (!file.exists()) {
                result.error("NOT_FOUND", "File not found on device", null)
                return
            }
            val uri: Uri = androidx.core.content.FileProvider.getUriForFile(
                this,
                "$packageName.fileprovider",
                file
            )
            val extension = file.extension.lowercase()
            val mimeType = when (extension) {
                "pdf" -> "application/pdf"
                "docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
                "doc" -> "application/msword"
                "xlsx" -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                "xls" -> "application/vnd.ms-excel"
                "pptx" -> "application/vnd.openxmlformats-officedocument.presentationml.presentation"
                "ppt" -> "application/vnd.ms-powerpoint"
                "txt", "csv", "log" -> "text/plain"
                "zip" -> "application/zip"
                "rar" -> "application/x-rar-compressed"
                "jpg", "jpeg", "png", "webp" -> "image/*"
                "mp4", "mkv", "avi" -> "video/*"
                "mp3", "wav", "m4a" -> "audio/*"
                else -> "*/*"
            }

            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mimeType)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(Intent.createChooser(intent, "Mở tệp bằng ứng dụng:"))
            result.success(true)
        } catch (e: Exception) {
            result.error("CANNOT_OPEN", e.localizedMessage, null)
        }
    }
}
