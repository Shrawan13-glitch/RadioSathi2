import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'services/command_service.dart';
import 'services/radio_service.dart';
import 'services/voice_service.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final commandService = CommandService();
    final radioService = RadioService();
    final voiceService = VoiceService(
      speech: stt.SpeechToText(),
      tts: FlutterTts(),
      commandService: commandService,
      radioService: radioService,
    );

    return MaterialApp(
      title: 'Radio Sathi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomeScreen(
        voiceService: voiceService,
        commandService: commandService,
        radioService: radioService,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
