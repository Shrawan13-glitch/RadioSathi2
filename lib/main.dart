import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radio Sathi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _isInitialized = false;
  String _lastWords = '';
  final List<String> _utterances = [];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _init();
  }

  Future<void> _init() async {
    await _flutterTts.setSharedInstance(true);
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);

    bool available = await _speech.initialize(
      onStatus: (status) => print('onStatus: $status'),
      onError: (error) => print('onError: $error'),
    );
    if (available) {
      setState(() => _isInitialized = true);
    }
  }

  void _startListening() async {
    if (!_isInitialized) return;
    _lastWords = '';
    setState(() => _isListening = true);
    _speech.listen(
      onResult: (result) {
        _lastWords = result.recognizedWords;
        if (result.finalResult) {
          _onSpeechFinalized();
        }
      },
      pauseFor: const Duration(seconds: 2),
    );
  }

  void _onSpeechFinalized() {
    setState(() {
      _isListening = false;
      if (_lastWords.isNotEmpty) {
        _utterances.insert(0, _lastWords);
      }
    });
    if (_lastWords.isNotEmpty) {
      _flutterTts.speak('You said: $_lastWords');
    } else {
      _flutterTts.speak('No speech detected');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onLongPressStart: _isInitialized && !_isListening
            ? (_) => _startListening()
            : null,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_utterances.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _utterances.first,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 60),
              GestureDetector(
                onTap: _isListening
                    ? () {
                        _speech.stop();
                        _onSpeechFinalized();
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: _isListening ? 100 : 72,
                  height: _isListening ? 100 : 72,
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.red : Colors.deepPurple,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening ? Colors.red : Colors.deepPurple)
                            .withValues(alpha: 0.3),
                        blurRadius: _isListening ? 24 : 12,
                        spreadRadius: _isListening ? 8 : 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: _isListening ? 48 : 36,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isListening
                    ? 'Tap the mic to stop'
                    : _utterances.isEmpty
                        ? 'Hold anywhere to speak'
                        : 'Hold again to speak',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
