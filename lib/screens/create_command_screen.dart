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
    }
  }

  @override
  void dispose() {
    _triggerController.dispose();
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

  Future<void> _save() async {
    final phrase = _triggerController.text.trim();
    if (phrase.isEmpty) return;
    if (_selectedStation == null) return;

    final cmd = Command(
      triggerPhrase: phrase,
      actionType: _actionType,
      actionParams: _selectedStation!,
    );

    if (widget.existing != null) {
      await widget.commandService.update(
        widget.existing!.copyWith(
          triggerPhrase: phrase,
          actionType: _actionType,
          actionParams: _selectedStation!,
        ),
      );
    } else {
      await widget.commandService.add(cmd);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing != null ? 'Edit Command' : 'New Command')),
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
                  title: Text(_selectedStation!['name'] ?? ''),
                  subtitle: Text(_selectedStation!['country'] ?? ''),
                ),
              ),
            ...ListTile.divideTiles(
              color: Colors.grey.shade300,
              tiles: _searchResults
                  .where((s) =>
                      s['name'] != _selectedStation?['name'])
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
                              'streamUrl': s['url_resolved'] ?? s['url'] ?? '',
                              'country': s['country'] ?? '',
                              'tags': s['tags'] ?? '',
                            };
                            _searchResults = [];
                          });
                        },
                      )),
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
