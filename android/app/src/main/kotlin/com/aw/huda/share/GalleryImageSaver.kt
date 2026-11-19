package com.aw.huda.share

import android.Manifest
import android.app.Activity
import android.content.ContentValues
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

/**
 * The "Save image" action of the share sheets (`ShareImageSaver` in Dart):
 * `saveImage` with `{bytes: PNG, name: file name without extension}` puts the
 * image in `Pictures/Huda` and returns `true`.
 *
 * Android 10+ inserts into MediaStore, which needs no permission. Android 7-9
 * writes the file itself, so it asks for WRITE_EXTERNAL_STORAGE first
 * (declared with maxSdkVersion 28); a refusal is a `PERMISSION_DENIED` error.
 */
class GalleryImageSaver(private val activity: Activity) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "com.aw.huda/gallery"
        const val PERMISSION_REQUEST_CODE = 0x6A11
        private const val ALBUM = "Huda"
    }

    private var pending: Pending? = null

    private class Pending(val bytes: ByteArray, val name: String, val result: MethodChannel.Result)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "saveImage") {
            result.notImplemented()
            return
        }
        val bytes = call.argument<ByteArray>("bytes")
        val name = call.argument<String>("name")?.let(::sanitize)
        if (bytes == null || bytes.isEmpty() || name.isNullOrEmpty()) {
            result.error("INVALID_ARGUMENTS", "saveImage needs bytes and a name.", null)
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
            activity.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            // One request at a time: a second tap while the dialog is up fails.
            if (pending != null) {
                result.error("BUSY", "A save is already waiting for permission.", null)
                return
            }
            pending = Pending(bytes, name, result)
            activity.requestPermissions(
                arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                PERMISSION_REQUEST_CODE,
            )
            return
        }
        save(bytes, name, result)
    }

    /** Forwarded from `MainActivity.onRequestPermissionsResult`. */
    fun onPermissionResult(requestCode: Int, grantResults: IntArray): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) return false
        val request = pending ?: return true
        pending = null
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            save(request.bytes, request.name, request.result)
        } else {
            request.result.error("PERMISSION_DENIED", "Storage permission was refused.", null)
        }
        return true
    }

    private fun save(bytes: ByteArray, name: String, result: MethodChannel.Result) {
        val context = activity.applicationContext
        CoroutineScope(Dispatchers.IO).launch {
            val error = runCatching {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    saveToMediaStore(bytes, name)
                } else {
                    saveToFile(bytes, name, context)
                }
            }.exceptionOrNull()
            withContext(Dispatchers.Main) {
                if (error == null) {
                    result.success(true)
                } else {
                    android.util.Log.e("GalleryImageSaver", "save failed", error)
                    result.error("SAVE_FAILED", error.message, null)
                }
            }
        }
    }

    private fun saveToMediaStore(bytes: ByteArray, name: String) {
        val resolver = activity.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, "$name.png")
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            put(MediaStore.Images.Media.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/$ALBUM")
            put(MediaStore.Images.Media.IS_PENDING, 1)
        }
        val collection = MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val uri = resolver.insert(collection, values)
            ?: throw IllegalStateException("MediaStore refused the image.")
        try {
            resolver.openOutputStream(uri)?.use { it.write(bytes) }
                ?: throw IllegalStateException("Could not open the image for writing.")
            values.clear()
            values.put(MediaStore.Images.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            throw e
        }
    }

    @Suppress("DEPRECATION")
    private fun saveToFile(bytes: ByteArray, name: String, context: android.content.Context) {
        val directory = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES),
            ALBUM,
        )
        if (!directory.isDirectory && !directory.mkdirs()) {
            throw IllegalStateException("Could not create ${directory.path}.")
        }
        val file = uniqueFile(directory, name)
        file.writeBytes(bytes)
        MediaScannerConnection.scanFile(context, arrayOf(file.path), arrayOf("image/png"), null)
    }

    /** `name.png`, else `name (2).png` and so on, like the system does. */
    private fun uniqueFile(directory: File, name: String): File {
        var file = File(directory, "$name.png")
        var index = 2
        while (file.exists()) {
            file = File(directory, "$name ($index).png")
            index++
        }
        return file
    }

    private fun sanitize(name: String): String =
        name.replace(Regex("[\\\\/:*?\"<>|\\u0000-\\u001F]"), "_").trim().take(120)
}
