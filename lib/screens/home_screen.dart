import 'package:flutter/material.dart';
import '../services/voice_service.dart';
import '../services/command_service.dart';
import '../services/radio_service.dart';
import '../services/theme_service.dart';
import '../services/log_service.dart';
import '../services/playlist_service.dart';
import 'commands_screen.dart';
import 'settings_screen.dart';
import 'playlist_list_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoiceService voiceService;
  final CommandService commandService;
  final RadioService radioService;
  final ThemeService themeService;
  final LogService logService;
  final PlaylistService playlistService;

  const HomeScreen({
    super.key,
    required this.voiceService,
    required this.commandService,
    required this.radioService,
    required this.themeService,
    required this.logService,
    required this.playlistService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _lastText = '';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    widget.radioService.addListener(_onRadioChanged);
    widget.voiceService.addListener(_onVoiceChanged);
    _init();
  }

  void _onRadioChanged() {
    setState(() {});
  }

  void _onVoiceChanged() {
    setState(() {});
  }

  Future<void> _init() async {
    await widget.commandService.load();
    await widget.playlistService.load();
    await widget.voiceService.init();
    setState(() => _initialized = true);
  }

  void _startListening() {
    if (!_initialized) return;
    widget.voiceService.startListening(
      onPartialResult: (text) {
        setState(() => _lastText = text);
      },
    );
  }

  @override
  void dispose() {
    widget.radioService.removeListener(_onRadioChanged);
    widget.voiceService.removeListener(_onVoiceChanged);
    widget.voiceService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = widget.radioService.isPlaying;
    final stationName = widget.radioService.currentStationName;
    final track = widget.radioService.currentTrack;

    return Scaffold(
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
                  playlistService: widget.playlistService,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.queue_music),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlaylistListScreen(
                  playlistService: widget.playlistService,
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
                      logService: widget.logService,
                    ),
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onLongPressStart: _initialized && !widget.voiceService.isListening
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
                onTap: widget.voiceService.isListening
                    ? () => widget.voiceService.stopListening()
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: widget.voiceService.isListening ? 100 : 72,
                  height: widget.voiceService.isListening ? 100 : 72,
                  decoration: BoxDecoration(
                    color: widget.voiceService.isListening ? Colors.red : Colors.deepPurple,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (widget.voiceService.isListening ? Colors.red : Colors.deepPurple)
                                .withValues(alpha: 0.3),
                        blurRadius: widget.voiceService.isListening ? 24 : 12,
                        spreadRadius: widget.voiceService.isListening ? 8 : 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.voiceService.isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: widget.voiceService.isListening ? 48 : 36,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.voiceService.isListening
                    ? 'Tap the mic to stop'
                    : !_initialized
                        ? 'Initializing...'
                        : 'Hold anywhere to speak',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),
              if (widget.voiceService.isListening)
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
      bottomSheet: isPlaying && !widget.voiceService.isListening
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
