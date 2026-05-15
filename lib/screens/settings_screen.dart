import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeService themeService;

  const SettingsScreen({super.key, required this.themeService});

  @override
  Widget build(BuildContext context) {
    final mode = themeService.mode;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language'),
              subtitle: const Text('English (US)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.volume_up),
              title: const Text('TTS Speed'),
              subtitle: const Text('Normal'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(
                mode == ThemeMode.dark
                    ? Icons.dark_mode
                    : mode == ThemeMode.light
                        ? Icons.light_mode
                        : Icons.brightness_auto,
              ),
              title: const Text('Theme'),
              trailing: DropdownButton<ThemeMode>(
                value: mode,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                      value: ThemeMode.light, child: Text('Light')),
                  DropdownMenuItem(
                      value: ThemeMode.dark, child: Text('Dark')),
                  DropdownMenuItem(
                      value: ThemeMode.system, child: Text('System')),
                ],
                onChanged: (v) {
                  if (v != null) themeService.setMode(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
