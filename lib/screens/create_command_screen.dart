import 'package:flutter/material.dart';
import '../models/command.dart';
import '../services/command_service.dart';
import '../services/radio_service.dart';

class CreateCommandScreen extends StatefulWidget {
  final CommandService commandService;
  final Command? existing;

  const CreateCommandScreen({
    super.key,
    required this.commandService,
    this.existing,
  });

  @override
  State<CreateCommandScreen> createState() => _CreateCommandScreenState();
}

class _CreateCommandScreenState extends State<CreateCommandScreen> {
  final _triggerController = TextEditingController();
  final _ytHandleController = TextEditingController();
  final _radioService = RadioService();
  ActionType _actionType = ActionType.radio;
  Map<String, dynamic>? _selectedStation;
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _triggerController.text = widget.existing!.triggerPhrase;
      _actionType = widget.existing!.actionType;
      _selectedStation = Map.from(widget.existing!.actionParams);
      if (_actionType == ActionType.ytHandleLive) {
        _ytHandleController.text =
            widget.existing!.actionParams['handle'] as String? ?? '';
      }
    }
  }

  @override
  void dispose() {
    _triggerController.dispose();
    _ytHandleController.dispose();
    _radioService.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_searchQuery.isEmpty) return;
    setState(() => _searching = true);
    final results = await _radioService.searchStations(_searchQuery);
    setState(() {
      _searchResults = results;
      _searching = false;
    });
  }

  bool _validate() {
    if (_triggerController.text.trim().isEmpty) {
      return false;
    }
    if (_actionType == ActionType.radio && _selectedStation == null) {
      return false;
    }
    if (_actionType == ActionType.ytHandleLive &&
        _ytHandleController.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    final phrase = _triggerController.text.trim();
    Map<String, dynamic> params;

    if (_actionType == ActionType.radio) {
      params = _selectedStation!;
    } else {
      final handle = _ytHandleController.text.trim();
      params = {
        'handle': handle.startsWith('@') ? handle : '@$handle',
      };
    }

    if (widget.existing != null) {
      await widget.commandService.update(
        widget.existing!.copyWith(
          triggerPhrase: phrase,
          actionType: _actionType,
          actionParams: params,
        ),
      );
    } else {
      await widget.commandService.add(Command(
        triggerPhrase: phrase,
        actionType: _actionType,
        actionParams: params,
      ));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(widget.existing != null ? 'Edit Command' : 'New Command')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _triggerController,
            decoration: const InputDecoration(
              labelText: 'Trigger phrase',
              hintText: 'e.g. play radio',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ActionType>(
            initialValue: _actionType,
            decoration: const InputDecoration(
              labelText: 'Action',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: ActionType.radio,
                child: Text('Radio'),
              ),
              DropdownMenuItem(
                value: ActionType.ytHandleLive,
                child: Text('YT Handle Live'),
              ),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  _actionType = v;
                  _selectedStation = null;
                  _searchResults = [];
                });
              }
            },
          ),
          const SizedBox(height: 24),
          if (_actionType == ActionType.radio) ...[
            const Text('Select Radio Station',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search stations...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _searchQuery = v,
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _searching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  onPressed: _search,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedStation != null)
              Card(
                color: Colors.green.shade50,
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(_selectedStation!['stationName'] ?? ''),
                  subtitle: Text(_selectedStation!['country'] ?? ''),
                ),
              ),
            ...ListTile.divideTiles(
              color: Colors.grey.shade300,
              tiles: _searchResults
                  .where(
                      (s) => s['name'] != _selectedStation?['stationName'])
                  .map((s) => ListTile(
                        dense: true,
                        title: Text(s['name'] ?? 'Unknown'),
                        subtitle: Text(
                            '${s['country'] ?? ''} — ${s['language'] ?? ''}'),
                        trailing: Text(
                          s['bitrate'] != null
                              ? '${s['bitrate']} kbps'
                              : '',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedStation = {
                              'stationName': s['name'] ?? '',
                              'streamUrl': s['url_resolved'] ??
                                  s['url'] ??
                                  '',
                              'country': s['country'] ?? '',
                              'tags': s['tags'] ?? '',
                            };
                            _searchResults = [];
                          });
                        },
                      )),
            ),
          ],
          if (_actionType == ActionType.ytHandleLive) ...[
            const Text('YouTube Handle',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _ytHandleController,
              decoration: const InputDecoration(
                hintText: 'e.g. @BBCNews or just BBCNews',
                border: OutlineInputBorder(),
                prefixText: 'youtube.com/',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The app will look for the /live stream of this channel.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save Command'),
          ),
        ],
      ),
    );
  }
}
