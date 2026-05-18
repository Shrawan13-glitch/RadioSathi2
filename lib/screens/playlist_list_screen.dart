import 'package:flutter/material.dart';
import '../services/playlist_service.dart';
import 'create_playlist_screen.dart';
import 'playlist_player_screen.dart';

class PlaylistListScreen extends StatelessWidget {
  final PlaylistService playlistService;

  const PlaylistListScreen({super.key, required this.playlistService});

  @override
  Widget build(BuildContext context) {
    final playlists = playlistService.playlists;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreatePlaylistScreen(
                playlistService: playlistService,
              ),
            ),
          );
          (context as Element).markNeedsBuild();
        },
        child: const Icon(Icons.add),
      ),
      body: playlists.isEmpty
          ? const Center(
              child: Text('No playlists yet. Tap + to create one.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.queue_music),
                    title: Text(playlist.name),
                    subtitle: Text('${playlist.items.length} items'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.play_arrow, color: Colors.green),
                          onPressed: () async {
                            await playlistService.playPlaylist(playlist);
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PlaylistPlayerScreen(
                                    playlistService: playlistService,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreatePlaylistScreen(
                                  playlistService: playlistService,
                                  existing: playlist,
                                ),
                              ),
                            );
                            (context as Element).markNeedsBuild();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await playlistService.delete(playlist.id);
                            (context as Element).markNeedsBuild();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}