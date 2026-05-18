import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist.dart';
import 'radio_service.dart';
import 'youtube_service.dart';
import 'log_service.dart';

class PlaylistService extends ChangeNotifier {
  static const _key = 'playlists';

  final RadioService radioService;
  final YoutubeService youtubeService;
  final LogService logService;

  List<Playlist> _playlists = [];
  bool _loaded = false;

  Playlist? _activePlaylist;
  int _currentIndex = 0;
  bool _queueMode = false;

  PlaylistService({
    required this.radioService,
    required this.youtubeService,
    required this.logService,
  });

  List<Playlist> get playlists => List.unmodifiable(_playlists);
  Playlist? get activePlaylist => _activePlaylist;
  int get currentIndex => _currentIndex;
  bool get hasQueue => _queueMode && _activePlaylist != null;
  PlaylistItem? get currentItem =>
      _activePlaylist != null && _activePlaylist!.items.isNotEmpty
          ? _activePlaylist!.items[_currentIndex]
          : null;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key) ?? [];
      _playlists = raw
          .map((e) => Playlist.fromJson(
              Map<String, dynamic>.from(jsonDecode(e) as Map)))
          .toList();
      _loaded = true;
      logService.i('PLAYLIST: loaded ${_playlists.length} playlists');
    } catch (e) {
      logService.e('PLAYLIST: load error $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = _playlists.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_key, raw);
    } catch (e) {
      logService.e('PLAYLIST: save error $e');
    }
  }

  Future<void> add(Playlist playlist) async {
    _playlists.add(playlist);
    await _save();
    notifyListeners();
  }

  Future<void> update(Playlist playlist) async {
    final idx = _playlists.indexWhere((p) => p.id == playlist.id);
    if (idx != -1) {
      _playlists[idx] = playlist;
      await _save();
      if (_activePlaylist?.id == playlist.id) {
        _activePlaylist = playlist;
        notifyListeners();
      }
    }
  }

  Future<void> delete(String id) async {
    _playlists.removeWhere((p) => p.id == id);
    await _save();
    if (_activePlaylist?.id == id) {
      _activePlaylist = null;
      _queueMode = false;
      notifyListeners();
    }
    notifyListeners();
  }

  Future<void> addItemToPlaylist(String playlistId, PlaylistItem item) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      _playlists[idx].items.add(item);
      await _save();
      if (_activePlaylist?.id == playlistId) {
        _activePlaylist = _playlists[idx];
        notifyListeners();
      }
    }
  }

  Future<void> removeItemFromPlaylist(
      String playlistId, String itemId) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final removedIdx = _playlists[idx].items.indexWhere((i) => i.id == itemId);
      _playlists[idx].items.removeWhere((i) => i.id == itemId);
      await _save();
      if (_activePlaylist?.id == playlistId) {
        _activePlaylist = _playlists[idx];
        if (removedIdx <= _currentIndex &&
            _currentIndex > 0 &&
            _currentIndex >= _activePlaylist!.items.length) {
          _currentIndex = _activePlaylist!.items.length - 1;
        }
        notifyListeners();
      }
    }
  }

  Future<void> reorderPlaylistItems(
      String playlistId, int oldIdx, int newIdx) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final item = _playlists[idx].items.removeAt(oldIdx);
      _playlists[idx].items.insert(
          newIdx > oldIdx ? newIdx - 1 : newIdx, item);
      await _save();
      if (_activePlaylist?.id == playlistId) {
        _activePlaylist = _playlists[idx];
        notifyListeners();
      }
    }
  }

  Future<void> playPlaylist(Playlist playlist, {int startIndex = 0}) async {
    if (playlist.items.isEmpty) {
      logService.w('PLAYLIST: "${playlist.name}" is empty');
      return;
    }

    _activePlaylist = playlist;
    _currentIndex = startIndex;
    _queueMode = true;
    logService.i('PLAYLIST: playing "${playlist.name}" from index $startIndex');
    notifyListeners();
    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    if (_activePlaylist == null || _activePlaylist!.items.isEmpty) return;

    final item = _activePlaylist!.items[_currentIndex];
    logService.i(
        'PLAYLIST: playing item[$_currentIndex] "${item.label}" type=${item.type.name}');

    if (item.type == PlaylistItemType.videoLink) {
      await radioService.play(item.source, stationName: item.label);
    } else if (item.type == PlaylistItemType.ytLive) {
      final result = await youtubeService.resolveLiveStream(item.source);
      if (result != null) {
        final streamUrl = result['streamUrl'] ?? '';
        if (streamUrl.isNotEmpty) {
          final title = result['title'] ?? item.label;
          await radioService.play(streamUrl, stationName: title);
        }
      }
    }
  }

  Future<void> next() async {
    if (_activePlaylist == null) return;
    if (_currentIndex < _activePlaylist!.items.length - 1) {
      _currentIndex++;
      notifyListeners();
      await _playCurrent();
    }
  }

  Future<void> previous() async {
    if (_activePlaylist == null) return;
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
      await _playCurrent();
    }
  }

  Future<void> playItemAt(int index) async {
    if (_activePlaylist == null) return;
    if (index >= 0 && index < _activePlaylist!.items.length) {
      _currentIndex = index;
      notifyListeners();
      await _playCurrent();
    }
  }

  void clearQueue() {
    _activePlaylist = null;
    _currentIndex = 0;
    _queueMode = false;
    notifyListeners();
  }
}