package com.example.radiosathi.source.extractor

import com.example.radiosathi.source.http.OkHttpDownloader
import okhttp3.OkHttpClient
import org.schabi.newpipe.extractor.NewPipe
import org.schabi.newpipe.extractor.ServiceList
import org.schabi.newpipe.extractor.stream.DeliveryMethod
import org.schabi.newpipe.extractor.stream.StreamInfo

class ExtractorCatalog(
    private val downloader: OkHttpDownloader = OkHttpDownloader(),
) {
    private val service = ServiceList.YouTube
    private val redirectClient = OkHttpClient.Builder()
        .followRedirects(true)
        .followSslRedirects(true)
        .build()

    init {
        NewPipe.init(downloader)
    }

    fun stream(videoUrl: String): Map<String, Any?>? {
        if (!videoUrl.startsWith("http")) return null

        val resolved = resolveRedirects(videoUrl)
        return tryExtract(resolved ?: videoUrl)
    }

    private fun resolveRedirects(url: String): String? {
        return try {
            val request = okhttp3.Request.Builder()
                .url(url).method("HEAD", null).build()
            redirectClient.newCall(request).execute().use { resp ->
                val finalUrl = resp.request.url.toString()
                if (finalUrl != url) finalUrl else null
            }
        } catch (_: Exception) { null }
    }

    private fun tryExtract(url: String): Map<String, Any?>? {
        return try {
            val info = StreamInfo.getInfo(service, url)
            val streamUrl = pickAudioUrl(info) ?: return null
            mapOf(
                "title" to info.name,
                "uploader" to (info.uploaderName ?: ""),
                "streamUrl" to streamUrl,
            )
        } catch (_: Exception) { null }
    }

    private fun pickAudioUrl(info: StreamInfo): String? {
        val direct = info.audioStreams
            .filter { it.isUrl && it.deliveryMethod != DeliveryMethod.HLS }
        return if (direct.isNotEmpty()) {
            direct.maxByOrNull { maxOf(it.bitrate, it.averageBitrate) }?.url
        } else info.hlsUrl
    }
}
