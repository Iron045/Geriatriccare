package com.example.geriatriccare

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.geriatriccare/notification_sound"
    private val preferencesName = "geriatric_notification_sound"
    private val selectedUriKey = "selected_uri"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSelectedSoundUri" -> result.success(
                        getSharedPreferences(preferencesName, MODE_PRIVATE)
                            .getString(selectedUriKey, null)
                    )
                    "saveAndSelectSound" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val title = call.argument<String>("title") ?: "Loi nhac uong thuoc"
                        if (bytes == null || bytes.isEmpty()) {
                            result.error("EMPTY_AUDIO", "Bản ghi âm đang trống.", null)
                        } else {
                            try {
                                val uri = saveNotificationSound(bytes, title)
                                getSharedPreferences(preferencesName, MODE_PRIVATE)
                                    .edit()
                                    .putString(selectedUriKey, uri)
                                    .apply()
                                result.success(uri)
                            } catch (error: Exception) {
                                result.error("SAVE_SOUND_FAILED", error.message, null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun saveNotificationSound(bytes: ByteArray, title: String): String {
        check(Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            "Thiết bị cần Android 10 trở lên để dùng bản ghi làm âm báo."
        }
        val safeTitle = title
            .replace(Regex("[^a-zA-Z0-9_-]"), "_")
            .take(40)
            .ifBlank { "medication_reminder" }
        val values = ContentValues().apply {
            put(MediaStore.Audio.Media.DISPLAY_NAME, "${safeTitle}_${System.currentTimeMillis()}.wav")
            put(MediaStore.Audio.Media.MIME_TYPE, "audio/wav")
            put(
                MediaStore.Audio.Media.RELATIVE_PATH,
                "${Environment.DIRECTORY_NOTIFICATIONS}/GeriatricCare"
            )
            put(MediaStore.Audio.Media.IS_NOTIFICATION, 1)
            put(MediaStore.Audio.Media.IS_PENDING, 1)
        }
        val collection = MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val uri = contentResolver.insert(collection, values)
            ?: error("Không thể tạo tệp âm báo trên thiết bị.")
        try {
            contentResolver.openOutputStream(uri, "w")?.use { it.write(bytes) }
                ?: error("Không thể ghi dữ liệu âm thanh.")
            contentResolver.update(
                uri,
                ContentValues().apply { put(MediaStore.Audio.Media.IS_PENDING, 0) },
                null,
                null
            )
            return uri.toString()
        } catch (error: Exception) {
            contentResolver.delete(uri, null, null)
            throw error
        }
    }
}
