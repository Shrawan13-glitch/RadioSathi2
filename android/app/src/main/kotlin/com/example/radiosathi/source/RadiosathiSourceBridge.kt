package com.example.radiosathi.source

import com.example.radiosathi.source.extractor.ExtractorCatalog
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class RadiosathiSourceBridge(
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "radiosathi/source")
    private val executor = Executors.newSingleThreadExecutor()
    private val extractor = ExtractorCatalog()

    fun register() {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        executor.execute {
            try {
                when (call.method) {
                    "stream" -> {
                        val url = call.argument<String>("url").orEmpty()
                        val stream = extractor.stream(url)
                        if (stream == null) {
                            result.error("not_found", "Stream not found for $url", null)
                        } else {
                            result.success(stream)
                        }
                    }
                    else -> result.notImplemented()
                }
            } catch (error: Throwable) {
                result.error("source_error", error.message, null)
            }
        }
    }
}
