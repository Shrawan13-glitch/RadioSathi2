import 'package:flutter/services.dart';

class SoundService {
  static const _channel = MethodChannel('radiosathi/sound');

  Future<void> playStart() async {
    try {
      await _channel.invokeMethod('play');
    } catch (_) {}
  }

  Future<void> playStop() async {
    try {
      await _channel.invokeMethod('play');
    } catch (_) {}
  }
}
