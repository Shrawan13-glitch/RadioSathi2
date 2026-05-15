package com.example.radiosathi.source.extractor

import com.example.radiosathi.source.http.OkHttpDownloader
import org.schabi.newpipe.extractor.NewPipe
import org.schabi.newpipe.extractor.ServiceList
import org.schabi.newpipe.extractor.stream.DeliveryMethod
import org.schabi.newpipe.extractor.stream.StreamInfo

class ExtractorCatalog(
    private val downloader: OkHttpDownloader = OkHttpDownloader(),
) {
    private val service = ServiceList.YouTube

    init {
        NewPipe.init(downloader)
    }

    fun stream(videoUrl: String): Map<String, Any?>? {
        if (!videoUrl.startsWith("http")) return null

        val info = StreamInfo.getInfo(service, videoUrl)
        val direct = info.audioStreams
            .filter { it.isUrl && it.deliveryMethod != DeliveryMethod.HLS }
        val streamUrl = if (direct.isNotEmpty()) {
            direct.maxByOrNull { maxOf(it.bitrate, it.averageBitrate) }?.url
        } else {
            info.hlsUrl
        } ?: return null

        return mapOf(
            "title" to info.name,
            "uploader" to (info.uploaderName ?: ""),
            "streamUrl" to streamUrl,
        )
    }
}
