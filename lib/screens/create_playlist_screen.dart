import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../services/playlist_service.dart';

class CreatePlaylistScreen extends StatefulWidget {
  final PlaylistService playlistService;
  final Playlist? existing;

  const CreatePlaylistScreen({
    super.key,
    required this.playlistService,
    this.existing,
  });

  @override
  State<CreatePlaylistScreen> createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends State<CreatePlaylistScreen> {
  final _nameController = TextEditingController();
  final _linkController = TextEditingController();
  final _labelController = TextEditingController();
  PlaylistItemType _itemType = PlaylistItemType.videoLink;
  List<PlaylistItem> _items = [];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!.name;
      _items = List.from(widget.existing!.items);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _linkController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  void _addItem() {
    if (_linkController.text.trim().isEmpty) return;
    final label = _labelController.text.trim().isNotEmpty
        ? _labelController.text.trim()
        : _linkController.text.trim();

    setState(() {
      _items.add(PlaylistItem(
        type: _itemType,
        label: label,
        source: _linkController.text.trim(),
      ));
      _linkController.clear();
      _labelController.clear();
    });
  }

  bool _validate() {
    return _nameController.text.trim().isNotEmpty;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    if (widget.existing != null) {
      await widget.playlistService.update(
        widget.existing!.copyWith(
          name: _nameController.text.trim(),
          items: _items,
        ),
      );
    } else {
      await widget.playlistService.add(Playlist(
        name: _nameController.text.trim(),
        items: _items,
      ));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing != null ? 'Edit Playlist' : 'New Playlist'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Playlist Name',
              hintText: 'e.g. My Favorites',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Add Item',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<PlaylistItemType>(
            initialValue: _itemType,
            decoration: const InputDecoration(
              labelText: 'Type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: PlaylistItemType.videoLink,
                child: Text('Video/Audio Link'),
              ),
              DropdownMenuItem(
                value: PlaylistItemType.ytLive,
                child: Text('YouTube Live'),
              ),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _itemType = v);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _linkController,
            decoration: InputDecoration(
              labelText: _itemType == PlaylistItemType.ytLive
                  ? 'YouTube Handle'
                  : 'Stream URL',
              hintText: _itemType == PlaylistItemType.ytLive
                  ? 'e.g. @BBCNews'
                  : 'https://example.com/stream.m3u8',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Label (optional)',
              hintText: 'e.g. Morning Vibes',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
            label: const Text('Add to Playlist'),
          ),
          const SizedBox(height: 24),
          if (_items.isNotEmpty) ...[
            const Text('Items',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              onReorder: (oldIdx, newIdx) {
                setState(() {
                  if (newIdx > oldIdx) newIdx--;
                  final item = _items.removeAt(oldIdx);
                  _items.insert(newIdx, item);
                });
              },
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  key: ValueKey(item.id),
                  child: ListTile(
                    leading: Icon(
                      item.type == PlaylistItemType.videoLink
                          ? Icons.link
                          : Icons.play_circle,
                    ),
                    title: Text(item.label),
                    subtitle: Text(
                      item.type == PlaylistItemType.ytLive
                          ? 'YT Live — ${item.source}'
                          : item.source,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() => _items.removeAt(index));
                          },
                        ),
                        const Icon(Icons.drag_handle),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}