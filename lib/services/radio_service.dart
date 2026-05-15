import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

class RadioService {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  Future<List<Map<String, dynamic>>> searchStations(String query) async {
    final url = Uri.parse(
        'https://de1.api.radio-browser.info/json/stations/search?name=$query&limit=30&hidebroken=true');
    final res = await http.get(url);
    if (res.statusCode != 200) return [];
    final list = jsonDecode(res.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> play(String url) async {
    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
      await _player.play();
      _isPlaying = true;
    } catch (_) {}
  }

  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  double get volume => _player.volume;

  void dispose() {
    _player.dispose();
  }
}
