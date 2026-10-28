package com.example.mafia

import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var finishSound: Ringtone? = null
    private var feedbackChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        feedbackChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "mafia/timer_feedback"
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method != "playFinishSound") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    finishSound?.stop()
                    val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                    val sound = RingtoneManager.getRingtone(this, uri)
                    if (sound == null) {
                        result.error("sound_unavailable", "System notification sound is unavailable", null)
                        return@setMethodCallHandler
                    }
                    sound.audioAttributes = AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        sound.isLooping = false
                    }
                    finishSound = sound
                    sound.play()
                    result.success(null)
                } catch (error: RuntimeException) {
                    result.error("sound_failed", error.message, null)
                }
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        feedbackChannel?.setMethodCallHandler(null)
        feedbackChannel = null
        finishSound?.stop()
        finishSound = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
