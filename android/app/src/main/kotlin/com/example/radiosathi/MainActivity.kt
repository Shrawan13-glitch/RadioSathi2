package com.example.radiosathi

import com.example.radiosathi.source.RadiosathiSourceBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        RadiosathiSourceBridge(flutterEngine.dartExecutor.binaryMessenger).register()
    }
}
