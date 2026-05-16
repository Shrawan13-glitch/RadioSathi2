import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/command.dart';
import 'command_service.dart';
import 'radio_service.dart';
import 'youtube_service.dart';
import 'log_service.dart';

class VoiceService {
  final stt.SpeechToText speech;
  final FlutterTts tts;
  final CommandService commandService;
  final RadioService radioService;
  final YoutubeService youtubeService;
  final LogService logService;
  bool _isListening = false;
  bool _initialized = false;

  VoiceService({
    required this.speech,
    required this.tts,
    required this.commandService,
    required this.radioService,
    required this.youtubeService,
    required this.logService,
  });

  bool get isListening => _isListening;
  bool get initialized => _initialized;

  Future<void> init() async {
    logService.i('VoiceService: initializing STT and TTS');
    await tts.setSharedInstance(true);
    await tts.setLanguage('en-US');
    await tts.setPitch(1.0);
    await tts.setSpeechRate(0.5);

    _initialized = await speech.initialize();
    logService.i('VoiceService: STT initialized=$_initialized');
  }

  void startListening({
    required void Function(String text) onPartialResult,
    void Function()? onDone,
  }) {
    if (!_initialized) return;
    logService.i('VoiceService: started listening');
    _isListening = true;
    speech.listen(
      onResult: (result) {
        final text = result.recognizedWords;
        onPartialResult(text);
        if (result.finalResult) {
          logService.i('VoiceService: final result="$text"');
          _handleCommand(text);
          onDone?.call();
        }
      },
      pauseFor: const Duration(seconds: 2),
    );
  }

  void stopListening() {
    logService.i('VoiceService: stopped listening');
    _isListening = false;
    speech.stop();
  }

  Future<void> say(String text) async {
    logService.i('TTS: "$text"');
    await tts.speak(text);
  }

  void _handleCommand(String text) {
    _isListening = false;
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
          if (!radioService.isPlaying) {
            logService.e('RADIO: play() completed but isPlaying=false');
          }
        } else {
          logService.w('RADIO: no stream URL configured');
          await say('No stream URL configured');
        }
      case ActionType.ytHandleLive:
        await _resolveYtLive(cmd);
    }
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
    if (!radioService.isPlaying) {
      logService.e('YT_LIVE: play() completed but isPlaying=false');
    }
  }
}
