package com.example.radiosathi

import android.media.MediaActionSound
import com.example.radiosathi.source.RadiosathiSourceBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val soundChannel = "radiosathi/sound"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        RadiosathiSourceBridge(flutterEngine.dartExecutor.binaryMessenger).register()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, soundChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "play" -> {
                        MediaActionSound().play(MediaActionSound.SHUTTER_CLICK)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
