import 'package:flutter/foundation.dart';

class LogService extends ChangeNotifier {
  final List<LogEntry> _entries = [];
  final int maxEntries;

  LogService({this.maxEntries = 200});

  List<LogEntry> get entries => List.unmodifiable(_entries);

  void i(String message) => _add('INFO', message);
  void w(String message) => _add('WARN', message);
  void e(String message) => _add('ERROR', message);

  void _add(String level, String message) {
    _entries.insert(0, LogEntry(level, message, DateTime.now()));
    if (_entries.length > maxEntries) {
      _entries.removeLast();
    }
    notifyListeners();
    debugPrint('[$level] $message');
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }
}

class LogEntry {
  final String level;
  final String message;
  final DateTime timestamp;

  LogEntry(this.level, this.message, this.timestamp);

  String get formatted =>
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}.${timestamp.millisecond.toString().padLeft(3, '0')} [$level] $message';
}
