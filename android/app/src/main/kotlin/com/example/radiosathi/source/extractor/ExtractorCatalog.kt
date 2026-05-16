package com.example.radiosathi.source.extractor

import com.example.radiosathi.source.http.OkHttpDownloader
import okhttp3.OkHttpClient
import org.schabi.newpipe.extractor.NewPipe
import org.schabi.newpipe.extractor.ServiceList
import org.schabi.newpipe.extractor.stream.StreamInfo
import java.io.StringWriter
import java.io.PrintWriter

class ExtractorCatalog(
    private val downloader: OkHttpDownloader = OkHttpDownloader(),
) {
    private val tag = "YT"
    private val service = ServiceList.YouTube
    private val client = OkHttpClient.Builder()
        .followRedirects(true)
        .followSslRedirects(true)
        .build()

    init {
        NewPipe.init(downloader)
    }

    fun stream(videoUrl: String): Map<String, Any?> {
        val diag = mutableMapOf<String, Any?>()
        diag["diag_step"] = "0:start"

        if (!videoUrl.startsWith("http")) {
            diag["diag_step"] = "0:bad_url"
            android.util.Log.e(tag, "URL must start with http: $videoUrl")
            return mapOf<String, Any?>("error" to "URL must start with http") + diag
        }

        return if (videoUrl.contains("/@")) {
            resolveAndExtract(videoUrl, diag)
        } else {
            extractStream(videoUrl, diag)
        }
    }

    private fun resolveAndExtract(handleUrl: String, diag: MutableMap<String, Any?>): Map<String, Any?> {
        val resolved = resolveHandleLive(handleUrl, diag)
        if (resolved == null) {
            android.util.Log.e(tag, "resolveHandleLive returned null")
            return mapOf<String, Any?>("error" to "Could not find live stream on this channel") + diag
        }
        android.util.Log.i(tag, "resolveHandleLive success -> $resolved")
        return extractStream(resolved, diag)
    }

    private fun resolveHandleLive(url: String, diag: MutableMap<String, Any?>): String? {
        diag["diag_step"] = "1:fetch_html"
        return try {
            android.util.Log.i(tag, "=== STEP 1: FETCH HTML ===")
            android.util.Log.i(tag, "URL: $url")
            val request = okhttp3.Request.Builder()
                .url(url)
                .header("User-Agent", "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36")
                .header("Accept-Language", "en-US,en;q=0.9")
                .build()

            val (httpCode, html) = client.newCall(request).execute().use { resp ->
                val code = resp.code
                android.util.Log.i(tag, "HTTP response: code=$code")
                if (!resp.isSuccessful) {
                    android.util.Log.e(tag, "HTTP $code for $url")
                    diag["diag_httpCode"] = code.toString()
                    diag["diag_step"] = "1:http_${code}"
                    return@use null
                }
                val body = resp.body?.string()
                if (body == null) {
                    android.util.Log.e(tag, "Response body was null")
                    diag["diag_httpCode"] = "$code"
                    diag["diag_step"] = "1:null_body"
                    return@use null
                }
                diag["diag_httpCode"] = "$code"
                Pair(code, body)
            } ?: return null

            diag["diag_htmlSize"] = html.length.toString()
            android.util.Log.i(tag, "HTML size: ${html.length} bytes")
            android.util.Log.i(tag, "HTML starts with: ${html.take(200)}")
            android.util.Log.i(tag, "HTML ends with: ${html.takeLast(200)}")

            diag["diag_step"] = "2:regex"
            android.util.Log.i(tag, "=== STEP 2: REGEX MATCH ===")
            val liveIdRegex = Regex("\"liveStreamabilityRenderer\":\\{\"videoId\":\"([a-zA-Z0-9_-]{11})\"")
            val match = liveIdRegex.find(html)
            if (match != null) {
                val videoId = match.groupValues[1]
                android.util.Log.i(tag, "REGEX MATCH FOUND: videoId=$videoId")
                android.util.Log.i(tag, "Full match: ${match.value}")
                diag["diag_videoId"] = videoId
                diag["diag_step"] = "3:extract_stream"
                "https://www.youtube.com/watch?v=$videoId"
            } else {
                android.util.Log.e(tag, "NO REGEX MATCH for liveStreamabilityRenderer")
                val hasAnyStreamability = html.contains("streamabilityRenderer")
                android.util.Log.e(tag, "Contains 'streamabilityRenderer' anywhere? $hasAnyStreamability")
                val hasIsLive = html.contains("isLive")
                android.util.Log.e(tag, "Contains 'isLive'? $hasIsLive")
                val liveIdx = html.indexOf("liveStreamability")
                if (liveIdx != -1) {
                    android.util.Log.e(tag, "Found 'liveStreamability' at index $liveIdx, context: ${html.substring(maxOf(0, liveIdx - 50), minOf(html.length, liveIdx + 100))}")
                }
                diag["diag_step"] = "2:no_match"
                diag["diag_videoId"] = "NOT_FOUND"
                diag["diag_htmlHasStreamability"] = hasAnyStreamability.toString()
                diag["diag_htmlHasIsLive"] = hasIsLive.toString()
                null
            }
        } catch (e: Exception) {
            val sw = StringWriter()
            e.printStackTrace(PrintWriter(sw))
            android.util.Log.e(tag, "EXCEPTION in resolveHandleLive: ${e.message}")
            android.util.Log.e(tag, "STACKTRACE: ${sw.toString()}")
            diag["diag_step"] = "1:exception"
            diag["diag_exception"] = "${e::class.simpleName}: ${e.message}"
            null
        }
    }

    private fun extractStream(url: String, diag: MutableMap<String, Any?>): Map<String, Any?> {
        diag["diag_step"] = "3:extract"
        android.util.Log.i(tag, "=== STEP 3: NEWPIPE EXTRACT ===")
        android.util.Log.i(tag, "Video URL: $url")
        return try {
            android.util.Log.i(tag, "Calling StreamInfo.getInfo()...")
            val info = StreamInfo.getInfo(service, url)
            android.util.Log.i(tag, "StreamInfo.getInfo() succeeded")
            android.util.Log.i(tag, "  name=${info.name}")
            android.util.Log.i(tag, "  uploader=${info.uploaderName}")
            android.util.Log.i(tag, "  duration=${info.duration}")
            android.util.Log.i(tag, "  audioStreamCount=${info.audioStreams.size}")
            android.util.Log.i(tag, "  hlsUrl=${info.hlsUrl}")
            android.util.Log.i(tag, "  streamType=${info.streamType}")

            diag["diag_step"] = "4:pick_audio"
            android.util.Log.i(tag, "=== STEP 4: PICK AUDIO ===")
            val streamUrl = pickAudioUrl(info, diag)

            if (streamUrl == null) {
                android.util.Log.e(tag, "No playable audio URL found")
                return mapOf<String, Any?>(
                    "error" to "No playable audio URL found",
                    "title" to (info.name ?: ""),
                    "uploader" to (info.uploaderName ?: ""),
                ) + diag
            }

            android.util.Log.i(tag, "=== SUCCESS ===")
            android.util.Log.i(tag, "Final streamUrl: ${streamUrl.take(100)}...")
            mapOf<String, Any?>(
                "title" to info.name,
                "uploader" to (info.uploaderName ?: ""),
                "streamUrl" to streamUrl,
            ) + diag
        } catch (e: Exception) {
            val sw = StringWriter()
            e.printStackTrace(PrintWriter(sw))
            android.util.Log.e(tag, "EXCEPTION in extractStream: ${e.message}")
            android.util.Log.e(tag, "STACKTRACE: ${sw.toString()}")
            diag["diag_step"] = "3:exception"
            diag["diag_exception"] = "${e::class.simpleName}: ${e.message}"
            mapOf<String, Any?>("error" to "Extraction failed: ${e.message}") + diag
        }
    }

    // NewPipe approach for live streams:
    //   Priority 1: HLS manifest (info.hlsUrl) — YouTube DASH manifests
    //     need a custom manifest parser (YoutubeDashLiveManifestParser) to
    //     fix availabilityStartTime, which ExoPlayer can't do without.
    //   Priority 2: DASH manifest (info.dashMpdUrl) — if HLS not available
    //   Priority 3: individual audio streams — last resort, YouTube CDN
    //     requires Origin/Referer/POST headers individual URLs won't get.
    private fun pickAudioUrl(info: StreamInfo, diag: MutableMap<String, Any?>): String? {
        val hls = info.hlsUrl
        if (hls != null && hls.isNotEmpty()) {
            android.util.Log.i(tag, "HLS manifest: ${hls.take(80)}...")
            diag["diag_selectedType"] = "hls"
            diag["diag_step"] = "4:hls"
            return hls
        }

        val dash = info.dashMpdUrl
        if (dash != null && dash.isNotEmpty()) {
            android.util.Log.i(tag, "DASH manifest (HLS unavailable): ${dash.take(80)}...")
            diag["diag_selectedType"] = "dash"
            diag["diag_step"] = "4:dash"
            return dash
        }

        android.util.Log.w(tag, "No manifest URL — falling back to individual audio streams")
        val streams = info.audioStreams.filter { it.isUrl }
        android.util.Log.i(tag, "Individual audio streams: ${streams.size} / ${info.audioStreams.size}")
        if (streams.isNotEmpty()) {
            val bitrates = streams.map { maxOf(it.bitrate, it.averageBitrate) }
            val urls = streams.map { it.url?.take(80).orEmpty() }
            val deliveries = streams.map { it.deliveryMethod }
            for (i in streams.indices) {
                android.util.Log.i(tag, "  [$i] bitrate=${bitrates[i]} delivery=${deliveries[i]} url=${urls[i]}...")
            }
            diag["diag_streamCount"] = streams.size.toString()
            diag["diag_bitrates"] = bitrates.joinToString(",")

            val best = streams.maxByOrNull { maxOf(it.bitrate, it.averageBitrate) }
            if (best != null) {
                android.util.Log.i(tag, "FALLBACK selected stream: bitrate=${maxOf(best.bitrate, best.averageBitrate)}")
                diag["diag_selectedType"] = "audio_fallback"
                diag["diag_step"] = "4:audio_fallback"
                return best.url
            }
        }

        android.util.Log.e(tag, "NO AUDIO SOURCE: dash=$dash hls=$hls streams=${info.audioStreams.size}")
        diag["diag_step"] = "4:no_audio"
        return null
    }
}
