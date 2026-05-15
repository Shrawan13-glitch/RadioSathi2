import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

class RadioService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  String _currentStationName = '';
  String _currentTrack = '';

  bool get isPlaying => _isPlaying;
  String get currentStationName => _currentStationName;
  String get currentTrack => _currentTrack;

  RadioService() {
    _player.icyMetadataStream.listen((icy) {
      if (icy?.info?.title != null) {
        _currentTrack = icy!.info!.title!;
        notifyListeners();
      }
    });
  }

  Future<List<Map<String, dynamic>>> searchStations(String query) async {
    final url = Uri.parse(
        'https://de1.api.radio-browser.info/json/stations/search?name=$query&limit=30&hidebroken=true');
    final res = await http.get(url);
    if (res.statusCode != 200) return [];
    final list = jsonDecode(res.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> play(String url, {String stationName = ''}) async {
    _currentStationName = stationName;
    _currentTrack = '';
    await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
    await _player.play();
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  double get volume => _player.volume;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
