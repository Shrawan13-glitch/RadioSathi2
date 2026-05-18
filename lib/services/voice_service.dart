import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/command.dart';
import 'command_service.dart';
import 'radio_service.dart';
import 'youtube_service.dart';
import 'log_service.dart';
import 'sound_service.dart';
import 'playlist_service.dart';

class VoiceService extends ChangeNotifier {
  final stt.SpeechToText speech;
  final FlutterTts tts;
  final CommandService commandService;
  final RadioService radioService;
  final YoutubeService youtubeService;
  final LogService logService;
  final SoundService soundService;
  final PlaylistService playlistService;
  bool _isListening = false;
  bool _initialized = false;

  VoiceService({
    required this.speech,
    required this.tts,
    required this.commandService,
    required this.radioService,
    required this.youtubeService,
    required this.logService,
    required this.soundService,
    required this.playlistService,
  });

  bool get isListening => _isListening;
  bool get initialized => _initialized;

  Future<void> init() async {
    logService.i('VoiceService: initializing STT and TTS');
    await tts.setSharedInstance(true);
    await tts.setLanguage('en-US');
    await tts.setPitch(1.0);
    await tts.setSpeechRate(0.5);

    _initialized = await speech.initialize(
      onStatus: (status) {
        logService.i('VoiceService: status=$status');
      },
    );
    logService.i('VoiceService: STT initialized=$_initialized');
  }

  Future<void> startListening({
    required void Function(String text) onPartialResult,
  }) async {
    if (!_initialized) return;
    logService.i('VoiceService: started listening');
    _isListening = true;
    notifyListeners();
    await soundService.playStart();

    try {
      await speech.listen(
        onResult: (result) {
          final text = result.recognizedWords;
          onPartialResult(text);
          if (result.finalResult) {
            logService.i('VoiceService: final result="$text"');
            _handleCommand(text);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 2),
      ).timeout(const Duration(seconds: 35));
    } on TimeoutException {
      logService.w('VoiceService: speech.listen() timed out');
      unawaited(speech.stop());
    } catch (e) {
      logService.e('VoiceService: listen error: $e');
    }

    if (_isListening) {
      logService.i('VoiceService: listening ended');
      _isListening = false;
      notifyListeners();
      soundService.playStop();
    }
  }

  void stopListening() {
    if (!_isListening) return;
    logService.i('VoiceService: stopped listening');
    _isListening = false;
    notifyListeners();
    speech.stop();
    soundService.playStop();
  }

  Future<void> say(String text) async {
    logService.i('TTS: "$text"');
    await tts.speak(text);
  }

  void _handleCommand(String text) {
    final lower = text.toLowerCase().trim();

    if (lower.contains('stop') && radioService.isPlaying) {
      logService.i('CMD: stop');
      radioService.stop();
      unawaited(say('Stopped'));
      return;
    }
    if (lower.contains('volume up') && radioService.isPlaying) {
      logService.i('CMD: volume up');
      final v = (radioService.volume + 0.1).clamp(0.0, 1.0);
      radioService.setVolume(v);
      unawaited(say('Volume ${(v * 100).round()} percent'));
      return;
    }
    if (lower.contains('volume down') && radioService.isPlaying) {
      logService.i('CMD: volume down');
      final v = (radioService.volume - 0.1).clamp(0.0, 1.0);
      radioService.setVolume(v);
      unawaited(say('Volume ${(v * 100).round()} percent'));
      return;
    }

    final cmd = commandService.findMatch(text);
    if (cmd != null) {
      logService.i(
          'CMD: matched "${cmd.triggerPhrase}" → ${cmd.actionType.name}');
      unawaited(_executeCommand(cmd));
    } else {
      logService.w('CMD: no match for "$text"');
      unawaited(say('No command found for: $text'));
    }
  }

  Future<void> _executeCommand(Command cmd) async {
    switch (cmd.actionType) {
      case ActionType.radio:
        final url = cmd.actionParams['streamUrl'] as String?;
        if (url != null && url.isNotEmpty) {
          final name = cmd.actionParams['stationName'] as String? ?? '';
          logService.i('RADIO: playing "$name" url=$url');
          await say('Playing $name');
          await radioService.play(url, stationName: name);
          logService.i('RADIO: play() returned for "$name"');
        } else {
          logService.w('RADIO: no stream URL configured');
          await say('No stream URL configured');
        }
      case ActionType.ytHandleLive:
        await _resolveYtLive(cmd);
      case ActionType.playVideoFromLink:
        await _playVideoFromLink(cmd);
      case ActionType.playPlaylist:
        await _playPlaylistById(cmd);
    }
  }

  Future<void> _playVideoFromLink(Command cmd) async {
    final link = cmd.actionParams['link'] as String?;
    if (link == null || link.isEmpty) {
      logService.w('VIDEO_LINK: no link configured');
      await say('No video link configured');
      return;
    }
    logService.i('VIDEO_LINK: playing link=$link');
    await say('Playing video');
    await radioService.play(link, stationName: 'Video Link');
    logService.i('VIDEO_LINK: play() returned');
  }

  Future<void> _resolveYtLive(Command cmd) async {
    final handle = cmd.actionParams['handle'] as String?;
    if (handle == null || handle.isEmpty) {
      logService.e('YT_LIVE: no handle configured');
      await say('No YouTube handle configured');
      return;
    }

    logService.i('YT_LIVE: resolving handle=$handle');
    await say('Looking up $handle');
    final result = await youtubeService.resolveLiveStream(handle);

    if (result == null) {
      logService.e('YT_LIVE: resolveLiveStream returned null');
      await say('Could not find live stream');
      return;
    }

    final streamUrl = result['streamUrl'] ?? '';
    if (streamUrl.isEmpty) {
      logService.e('YT_LIVE: streamUrl is empty');
      await say('Could not find live stream');
      return;
    }

    final name = result['title'] ?? handle;
    logService.i('YT_LIVE: playing "$name" url=${streamUrl.length > 80 ? '${streamUrl.substring(0, 80)}...' : streamUrl}');

    await say('Playing $name');
    await radioService.play(streamUrl, stationName: name);
    logService.i('YT_LIVE: play() returned for "$name"');
  }

  Future<void> _playPlaylistById(Command cmd) async {
    final playlistId = cmd.actionParams['playlistId'] as String?;
    if (playlistId == null || playlistId.isEmpty) {
      logService.w('PLAYLIST_CMD: no playlist ID configured');
      await say('No playlist configured');
      return;
    }

    await playlistService.load();
    final playlist = playlistService.playlists.firstWhere(
      (p) => p.id == playlistId,
      orElse: () => throw Exception('Playlist not found'),
    );
    if (playlist.items.isEmpty) {
      await say('${playlist.name} playlist is empty');
      return;
    }

    logService.i('PLAYLIST_CMD: playing "${playlist.name}"');
    await say('Playing playlist ${playlist.name}');
    await playlistService.playPlaylist(playlist);
    logService.i('PLAYLIST_CMD: playPlaylist returned');
  }
}
