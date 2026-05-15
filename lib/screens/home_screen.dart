import 'package:flutter/material.dart';
import '../services/voice_service.dart';
import '../services/command_service.dart';
import '../services/radio_service.dart';
import '../services/theme_service.dart';
import 'commands_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoiceService voiceService;
  final CommandService commandService;
  final RadioService radioService;
  final ThemeService themeService;

  const HomeScreen({
    super.key,
    required this.voiceService,
    required this.commandService,
    required this.radioService,
    required this.themeService,
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
    widget.radioService.addListener(_onRadioChanged);
    _init();
  }

  void _onRadioChanged() {
    setState(() {});
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
    widget.radioService.removeListener(_onRadioChanged);
    widget.voiceService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = widget.radioService.isPlaying;
    final stationName = widget.radioService.currentStationName;
    final track = widget.radioService.currentTrack;

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
                builder: (_) => SettingsScreen(
                      themeService: widget.themeService,
                    ),
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onLongPressStart: _initialized && !_isListening
            ? (_) => _startListening()
            : null,
        behavior: HitTestBehavior.translucent,
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
                        color:
                            (_isListening ? Colors.red : Colors.deepPurple)
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
      bottomSheet: isPlaying
          ? Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.radio, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          stationName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (track.isNotEmpty)
                          Text(
                            track,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
