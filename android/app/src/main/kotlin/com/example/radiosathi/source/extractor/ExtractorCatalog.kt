package com.example.radiosathi.source.extractor

import com.example.radiosathi.source.http.OkHttpDownloader
import okhttp3.OkHttpClient
import org.schabi.newpipe.extractor.NewPipe
import org.schabi.newpipe.extractor.ServiceList
import org.schabi.newpipe.extractor.stream.StreamInfo

class ExtractorCatalog(
    private val downloader: OkHttpDownloader = OkHttpDownloader(),
) {
    private val service = ServiceList.YouTube
    private val client = OkHttpClient.Builder()
        .followRedirects(true)
        .followSslRedirects(true)
        .build()

    init {
        NewPipe.init(downloader)
    }

    fun stream(videoUrl: String): Map<String, Any?>? {
        if (!videoUrl.startsWith("http")) return null

        val targetUrl = if (videoUrl.contains("/@")) {
            resolveHandleLive(videoUrl) ?: return null
        } else videoUrl

        return tryExtract(targetUrl)
    }

    private fun resolveHandleLive(url: String): String? {
        return try {
            val request = okhttp3.Request.Builder()
                .url(url)
                .header("User-Agent", "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36")
                .build()
            val html = client.newCall(request).execute().use { resp ->
                if (!resp.isSuccessful) return@use null
                resp.body?.string() ?: return@use null
            } ?: return null

            val liveIdRegex = Regex("\"liveStreamabilityRenderer\":\\{\"videoId\":\"([a-zA-Z0-9_-]{11})\"")
            val match = liveIdRegex.find(html)
            val videoId = match?.groupValues?.getOrNull(1) ?: return null
            "https://www.youtube.com/watch?v=$videoId"
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
        val streams = info.audioStreams.filter { it.isUrl }
        if (streams.isNotEmpty()) {
            val best = streams.maxByOrNull { maxOf(it.bitrate, it.averageBitrate) }
            if (best != null) return best.url
        }
        val hls = info.hlsUrl
        if (hls != null && hls.isNotEmpty()) return hls
        return null
    }
}
