package com.example.radiosathi.source.http

import okhttp3.Headers
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.RequestBody.Companion.toRequestBody
import org.schabi.newpipe.extractor.downloader.Downloader
import org.schabi.newpipe.extractor.downloader.Request
import org.schabi.newpipe.extractor.downloader.Response

class OkHttpDownloader : Downloader() {
    private val client = OkHttpClient.Builder().followRedirects(true).build()

    override fun execute(request: Request): Response {
        val headersBuilder = Headers.Builder()
        request.headers().forEach { (name, values) ->
            values.forEach { value -> headersBuilder.add(name, value) }
        }

        val contentType = request.headers()["Content-Type"]?.firstOrNull()
            ?: "application/octet-stream"
        val body = request.dataToSend()
            ?.takeIf { it.isNotEmpty() }
            ?.toRequestBody(contentType.toMediaType())

        val okHttpRequest = okhttp3.Request.Builder()
            .url(request.url())
            .headers(headersBuilder.build())
            .method(request.httpMethod(), if (request.httpMethod() == "POST") body else null)
            .build()

        client.newCall(okHttpRequest).execute().use { response ->
            return Response(
                response.code,
                response.message,
                response.headers.toMultimap(),
                response.body?.string().orEmpty(),
                response.request.url.toString(),
            )
        }
    }
}
