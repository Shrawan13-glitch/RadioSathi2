import 'package:flutter/material.dart';
import '../services/log_service.dart';

class LogViewerScreen extends StatefulWidget {
  final LogService logService;

  const LogViewerScreen({super.key, required this.logService});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    widget.logService.addListener(_onLogsChanged);
  }

  @override
  void dispose() {
    widget.logService.removeListener(_onLogsChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onLogsChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.logService.entries;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              widget.logService.clear();
              setState(() {});
            },
          ),
        ],
      ),
      body: entries.isEmpty
          ? const Center(child: Text('No logs yet'))
          : ListView.builder(
              controller: _scrollController,
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade800, width: 0.5),
                    ),
                  ),
                  child: Text(
                    entry.formatted,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: entry.level == 'ERROR'
                          ? Colors.red.shade300
                          : entry.level == 'WARN'
                              ? Colors.orange.shade300
                              : Colors.green.shade300,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
