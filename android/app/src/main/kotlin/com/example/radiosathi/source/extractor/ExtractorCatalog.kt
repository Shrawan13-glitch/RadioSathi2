package com.example.radiosathi.source.extractor

import com.example.radiosathi.source.http.OkHttpDownloader
import okhttp3.OkHttpClient
import org.schabi.newpipe.extractor.NewPipe
import org.schabi.newpipe.extractor.ServiceList
import org.schabi.newpipe.extractor.search.SearchInfo
import org.schabi.newpipe.extractor.stream.DeliveryMethod
import org.schabi.newpipe.extractor.stream.StreamInfo
import org.schabi.newpipe.extractor.stream.StreamInfoItem

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
        tryExtract(resolved ?: videoUrl)?.let { return it }

        val handle = extractHandle(videoUrl)
        if (handle != null) {
            searchLiveStream("@$handle")?.let { return it }
        }

        return null
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
            mapOf("title" to info.name, "uploader" to (info.uploaderName ?: ""), "streamUrl" to streamUrl)
        } catch (_: Exception) { null }
    }

    private fun searchLiveStream(query: String): Map<String, Any?>? {
        return try {
            val handler = service.searchQHFactory.fromQuery(query)
            val search = SearchInfo.getInfo(service, handler)
            val liveItem = search.relatedItems
                .filterIsInstance<StreamInfoItem>()
                .firstOrNull { it.duration <= 0 }
                ?: return null

            val info = StreamInfo.getInfo(service, liveItem.url)
            val streamUrl = pickAudioUrl(info) ?: return null
            mapOf("title" to info.name, "uploader" to (info.uploaderName ?: ""), "streamUrl" to streamUrl)
        } catch (_: Exception) { null }
    }

    private fun pickAudioUrl(info: StreamInfo): String? {
        val direct = info.audioStreams
            .filter { it.isUrl && it.deliveryMethod != DeliveryMethod.HLS }
        return if (direct.isNotEmpty()) {
            direct.maxByOrNull { maxOf(it.bitrate, it.averageBitrate) }?.url
        } else info.hlsUrl
    }

    private fun extractHandle(url: String): String? {
        val match = Regex("youtube\\.com/@([^/]+)").find(url)
        return match?.groupValues?.getOrNull(1)
    }
}
