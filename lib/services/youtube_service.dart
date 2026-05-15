import 'package:flutter/services.dart';
import 'log_service.dart';

class YoutubeService {
  static const _channel = MethodChannel('radiosathi/source');
  final LogService logService;

  YoutubeService({required this.logService});

  Future<Map<String, String>?> resolveLiveStream(String handle) async {
    final clean = handle.startsWith('@') ? handle : '@$handle';
    final url = 'https://www.youtube.com/$clean/live';
    final start = DateTime.now();
    logService.i('╔══════════════════════════════════════════');
    logService.i('║ YT: resolve start  handle=$clean');
    logService.i('║ YT: url=$url');

    var diag = <String, String>{};
    try {
      final raw = await _channel
          .invokeMapMethod<String, dynamic>('stream', {'url': url});

      final elapsed = DateTime.now().difference(start).inMilliseconds;
      logService.i('║ YT: native returned in ${elapsed}ms');

      if (raw == null) {
        logService.e('║ YT: native returned NULL');
        logService.i('╚══════════════════════════════════════════');
        return null;
      }

      diag = raw.map((k, v) => MapEntry(k, v.toString()));

      final error = raw['error'] as String?;
      if (error != null) {
        logService.e('║ YT: NATIVE ERROR: $error');
        _logNativeDiag(raw);
        logService.e('╚══════════════════════════════════════════');
        return null;
      }

      final streamUrl = (raw['streamUrl'] as String?) ?? '';
      final title = (raw['title'] as String?) ?? '';
      final uploader = (raw['uploader'] as String?) ?? '';

      logService.i('║ YT: title="$title"  uploader="$uploader"');
      logService.i('║ YT: streamUrl=${streamUrl.length > 100 ? '${streamUrl.substring(0, 100)}...' : streamUrl}');
      logService.i('║ YT: streamUrl_len=${streamUrl.length} streamUrl_type=${streamUrl.startsWith('http') ? 'http' : 'UNEXPECTED'}');

      _logNativeDiag(raw);

      if (streamUrl.isEmpty) {
        logService.e('║ YT: streamUrl is EMPTY');
        logService.e('╚══════════════════════════════════════════');
        return null;
      }

      logService.i('╚══════════════════════════════════════════');
      return {
        'title': title,
        'uploader': uploader,
        'streamUrl': streamUrl,
      };
    } on PlatformException catch (e) {
      logService.e('║ YT: PlatformException');
      logService.e('║ YT:   code=${e.code}');
      logService.e('║ YT:   message=${e.message}');
      logService.e('║ YT:   details=${e.details}');
      if (diag.isNotEmpty) _logNativeDiag(diag);
      logService.e('╚══════════════════════════════════════════');
      return null;
    } catch (e) {
      logService.e('║ YT: UNEXPECTED DART ERROR: $e');
      if (diag.isNotEmpty) _logNativeDiag(diag);
      logService.e('╚══════════════════════════════════════════');
      return null;
    }
  }

  void _logNativeDiag(Map raw) {
    for (final key in ['diag_htmlSize', 'diag_httpCode', 'diag_videoId', 'diag_streamCount', 'diag_bitrates', 'diag_selectedType', 'diag_exception', 'diag_step']) {
      final val = raw[key] as String?;
      if (val != null && val.isNotEmpty) {
        logService.i('║ YT: $key=$val');
      }
    }
  }
}
