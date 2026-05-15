import 'package:flutter/services.dart';

class YoutubeService {
  static const _channel = MethodChannel('radiosathi/source');

  Future<Map<String, String>?> resolveLiveStream(String handle) async {
    final clean = handle.startsWith('@') ? handle : '@$handle';
    final url = 'https://www.youtube.com/$clean/live';

    try {
      final result = await _channel
          .invokeMapMethod<String, dynamic>('stream', {'url': url});
      if (result == null) return null;

      return {
        'title': (result['title'] as String?) ?? '',
        'uploader': (result['uploader'] as String?) ?? '',
        'streamUrl': (result['streamUrl'] as String?) ?? '',
      };
    } on PlatformException {
      return null;
    }
  }
}
