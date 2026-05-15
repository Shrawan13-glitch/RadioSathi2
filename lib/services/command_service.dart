import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/command.dart';

class CommandService {
  static const _key = 'commands';
  List<Command> _commands = [];
  bool _loaded = false;

  List<Command> get commands => List.unmodifiable(_commands);

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _commands = list.map((e) => Command.fromJson(e as Map<String, dynamic>)).toList();
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_commands.map((c) => c.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  Future<void> add(Command command) async {
    _commands.add(command);
    await _save();
  }

  Future<void> update(Command command) async {
    final index = _commands.indexWhere((c) => c.id == command.id);
    if (index != -1) {
      _commands[index] = command;
      await _save();
    }
  }

  Future<void> delete(String id) async {
    _commands.removeWhere((c) => c.id == id);
    await _save();
  }

  Command? findMatch(String text) {
    final lower = text.toLowerCase().trim();
    for (final cmd in _commands) {
      if (!cmd.enabled) continue;
      if (lower.contains(cmd.triggerPhrase.toLowerCase().trim())) {
        return cmd;
      }
    }
    return null;
  }
}
