import 'dart:async';
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

  bool get isPlaying => _isPlaying;
  String get currentStationName => _currentStationName;
  String get currentTrack => _currentTrack;
  double get volume => _player.volume;

  void attachLog(LogService log) => _log = log;

  RadioService() {
    _player.icyMetadataStream.listen((icy) {
      if (icy?.info?.title != null) {
        _currentTrack = icy!.info!.title!;
        notifyListeners();
      }
    });

    _player.playerStateStream.listen((state) {
      final ps = state.processingState;
      if (ps == ProcessingState.ready) {
        _log?.i('AUDIO: ready');
      } else if (ps == ProcessingState.buffering) {
        _log?.i('AUDIO: buffering...');
      } else if (ps == ProcessingState.loading) {
        _log?.i('AUDIO: loading...');
      } else if (ps == ProcessingState.idle) {
        _log?.i('AUDIO: idle');
      }
      if (_isPlaying != state.playing) {
        _isPlaying = state.playing;
        notifyListeners();
      }
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
    _log?.i('PLAY: url=$url station="$stationName"');

    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
      await _player.play().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          _log?.e('PLAY: play() TIMED OUT after 15s');
          _player.stop();
        },
      );
      _log?.i('PLAY: play() returned, isPlaying=${_player.playing}');
      _isPlaying = _player.playing;
      notifyListeners();
    } on PlayerException catch (e) {
      _log?.e('PLAY: PlayerException code=${e.code} message=${e.message}');
      _isPlaying = false;
      notifyListeners();
    } on TimeoutException {
      _log?.e('PLAY: TimeoutException — playback never started');
      _isPlaying = false;
      notifyListeners();
    } on Exception catch (e) {
      _log?.e('PLAY: exception: $e');
      _isPlaying = false;
      notifyListeners();
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

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
