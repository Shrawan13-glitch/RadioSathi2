import 'package:flutter/material.dart';
import '../services/voice_service.dart';
import '../services/command_service.dart';
import '../services/radio_service.dart';
import 'commands_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoiceService voiceService;
  final CommandService commandService;
  final RadioService radioService;

  const HomeScreen({
    super.key,
    required this.voiceService,
    required this.commandService,
    required this.radioService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _lastText = '';
  bool _isListening = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await widget.commandService.load();
    await widget.voiceService.init();
    setState(() => _initialized = true);
  }

  void _startListening() {
    if (!_initialized) return;
    setState(() => _isListening = true);
    widget.voiceService.startListening(
      onPartialResult: (text) {
        setState(() => _lastText = text);
      },
      onDone: () {
        setState(() => _isListening = false);
      },
    );
  }

  @override
  void dispose() {
    widget.voiceService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Radio Sathi'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CommandsScreen(
                  commandService: widget.commandService,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onLongPressStart: _initialized && !_isListening
            ? (_) => _startListening()
            : null,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_lastText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _lastText,
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
                        widget.voiceService.stopListening();
                        setState(() => _isListening = false);
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
                    : !_initialized
                        ? 'Initializing...'
                        : 'Hold anywhere to speak',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),
              if (_lastText.isNotEmpty && _isListening)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Listening...',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red.shade400,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
