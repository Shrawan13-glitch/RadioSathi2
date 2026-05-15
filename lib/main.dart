import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'services/command_service.dart';
import 'services/radio_service.dart';
import 'services/voice_service.dart';
import 'services/theme_service.dart';
import 'services/youtube_service.dart';
import 'services/log_service.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final themeService = ThemeService();
  final commandService = CommandService();
  final radioService = RadioService();
  final logService = LogService();
  late final youtubeService = YoutubeService(logService: logService);

  late final voiceService = VoiceService(
    speech: stt.SpeechToText(),
    tts: FlutterTts(),
    commandService: commandService,
    radioService: radioService,
    youtubeService: youtubeService,
    logService: logService,
  );

  @override
  void initState() {
    super.initState();
    radioService.attachLog(logService);
    themeService.addListener(() => setState(() {}));
    themeService.load();
  }

  @override
  void dispose() {
    themeService.removeListener(() => setState(() {}));
    radioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radio Sathi',
      themeMode: themeService.mode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(
        voiceService: voiceService,
        commandService: commandService,
        radioService: radioService,
        themeService: themeService,
        logService: logService,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
