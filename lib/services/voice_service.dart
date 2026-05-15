import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/command.dart';
import 'command_service.dart';
import 'radio_service.dart';

class VoiceService {
  final stt.SpeechToText speech;
  final FlutterTts tts;
  final CommandService commandService;
  final RadioService radioService;
  bool _isListening = false;
  bool _initialized = false;

  VoiceService({
    required this.speech,
    required this.tts,
    required this.commandService,
    required this.radioService,
  });

  bool get isListening => _isListening;
  bool get initialized => _initialized;

  Future<void> init() async {
    await tts.setSharedInstance(true);
    await tts.setLanguage('en-US');
    await tts.setPitch(1.0);
    await tts.setSpeechRate(0.5);

    _initialized = await speech.initialize();
  }

  void startListening({
    required void Function(String text) onPartialResult,
    void Function()? onDone,
  }) {
    if (!_initialized) return;
    _isListening = true;
    speech.listen(
      onResult: (result) {
        final text = result.recognizedWords;
        onPartialResult(text);
        if (result.finalResult) {
          _handleCommand(text);
          onDone?.call();
        }
      },
      pauseFor: const Duration(seconds: 2),
    );
  }

  void stopListening() {
    _isListening = false;
    speech.stop();
  }

  Future<void> say(String text) async {
    await tts.speak(text);
  }

  void _handleCommand(String text) {
    _isListening = false;
    final lower = text.toLowerCase().trim();

    if (lower.contains('stop') && radioService.isPlaying) {
      radioService.stop();
      say('Stopped');
      return;
    }
    if (lower.contains('volume up') && radioService.isPlaying) {
      final v = (radioService.volume + 0.1).clamp(0.0, 1.0);
      radioService.setVolume(v);
      say('Volume ${(v * 100).round()} percent');
      return;
    }
    if (lower.contains('volume down') && radioService.isPlaying) {
      final v = (radioService.volume - 0.1).clamp(0.0, 1.0);
      radioService.setVolume(v);
      say('Volume ${(v * 100).round()} percent');
      return;
    }

    final cmd = commandService.findMatch(text);
    if (cmd != null) {
      _executeCommand(cmd);
    } else {
      say('No command found for: $text');
    }
  }

  void _executeCommand(Command cmd) {
    switch (cmd.actionType) {
      case ActionType.radio:
        final url = cmd.actionParams['streamUrl'] as String?;
        if (url != null && url.isNotEmpty) {
          final name = cmd.actionParams['stationName'] as String? ?? '';
          radioService.play(url, stationName: name);
          say('Playing $name');
        } else {
          say('No stream URL configured');
        }
    }
  }
}
