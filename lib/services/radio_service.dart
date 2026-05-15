import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'log_service.dart';

class RadioService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  String _currentStationName = '';
  String _currentTrack = '';
  LogService? _log;
  bool _wasEverReady = false;

  bool get isPlaying => _isPlaying;
  String get currentStationName => _currentStationName;
  String get currentTrack => _currentTrack;

  void attachLog(LogService log) => _log = log;

  RadioService() {
    _player.icyMetadataStream.listen((icy) {
      if (icy?.info?.title != null) {
        _currentTrack = icy!.info!.title!;
        notifyListeners();
      }
    });

    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      final ps = state.processingState;

      if (ps == ProcessingState.ready) _wasEverReady = true;

      if (ps == ProcessingState.idle && _wasEverReady) {
        _log?.e('AUDIO: player went idle unexpectedly after being ready');
        _isPlaying = false;
      }

      if (ps == ProcessingState.loading) {
        _log?.i('AUDIO: loading...');
      }

      notifyListeners();
    });
  }

  Future<List<Map<String, dynamic>>> searchStations(String query) async {
    final url = Uri.parse(
        'https://de1.api.radio-browser.info/json/stations/search?name=$query&limit=30&hidebroken=true');
    _log?.i('RADIO: searching stations query="$query" url=$url');
    final res = await http.get(url);
    if (res.statusCode != 200) {
      _log?.e('RADIO: search returned HTTP ${res.statusCode}');
      return [];
    }
    _log?.i('RADIO: search returned ${res.body.length} bytes');
    final list = jsonDecode(res.body) as List;
    _log?.i('RADIO: found ${list.length} stations');
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> play(String url, {String stationName = ''}) async {
    _currentStationName = stationName;
    _currentTrack = '';
    _wasEverReady = false;
    _log?.i('PLAY: url=$url station="$stationName"');
    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
      _log?.i('PLAY: AudioSource set, calling play()');
      await _player.play();
      _log?.i('PLAY: play() returned, isPlaying=${_player.playing} processingState=${_player.processingState}');
      if (_player.processingState != ProcessingState.ready && _player.processingState != ProcessingState.buffering) {
        _log?.e('PLAY: play() succeeded but state=${_player.processingState} not ready');
      }
      _isPlaying = true;
      notifyListeners();
    } on PlayerException catch (e) {
      _log?.e('PLAY: PlayerException code=${e.code} message=${e.message}');
      _isPlaying = false;
      rethrow;
    } on Exception catch (e) {
      _log?.e('PLAY: exception: $e');
      _isPlaying = false;
      rethrow;
    }
  }

  Future<void> stop() async {
    _log?.i('RADIO: stop() called');
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
