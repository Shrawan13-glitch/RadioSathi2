import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../services/playlist_service.dart';

class PlaylistPlayerScreen extends StatefulWidget {
  final PlaylistService playlistService;

  const PlaylistPlayerScreen({super.key, required this.playlistService});

  @override
  State<PlaylistPlayerScreen> createState() => _PlaylistPlayerScreenState();
}

class _PlaylistPlayerScreenState extends State<PlaylistPlayerScreen> {
  @override
  void initState() {
    super.initState();
    widget.playlistService.addListener(_onChange);
  }

  void _onChange() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.playlistService.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playlist = widget.playlistService.activePlaylist;
    if (playlist == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Playlist')),
        body: const Center(child: Text('No playlist playing')),
      );
    }

    final items = playlist.items;
    final index = widget.playlistService.currentIndex;
    final current = widget.playlistService.currentItem;

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              widget.playlistService.clearQueue();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (current != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Column(
                children: [
                  Icon(
                    current.type == PlaylistItemType.videoLink
                        ? Icons.link
                        : Icons.play_circle,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    current.label,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${index + 1} of ${items.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filled(
                        onPressed: index > 0
                            ? () => widget.playlistService.previous()
                            : null,
                        icon: const Icon(Icons.skip_previous),
                        iconSize: 32,
                      ),
                      const SizedBox(width: 16),
                      IconButton.filled(
                        onPressed: index < items.length - 1
                            ? () => widget.playlistService.next()
                            : null,
                        icon: const Icon(Icons.skip_next),
                        iconSize: 32,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                final isActive = i == index;
                return Card(
                  color: isActive
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  child: ListTile(
                    leading: Icon(
                      isActive
                          ? Icons.play_circle_filled
                          : (item.type == PlaylistItemType.videoLink
                              ? Icons.link
                              : Icons.play_circle_outline),
                      color: isActive ? Theme.of(context).colorScheme.primary : null,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.bold : null,
                      ),
                    ),
                    subtitle: Text(
                      item.type == PlaylistItemType.ytLive
                          ? 'YT Live — ${item.source}'
                          : item.source,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: isActive
                        ? const Icon(Icons.equalizer)
                        : IconButton(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () =>
                                widget.playlistService.playItemAt(i),
                          ),
                    onTap: () => widget.playlistService.playItemAt(i),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}