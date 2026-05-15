import 'package:flutter/material.dart';
import '../models/command.dart';
import '../services/command_service.dart';
import 'create_command_screen.dart';

class CommandsScreen extends StatefulWidget {
  final CommandService commandService;

  const CommandsScreen({super.key, required this.commandService});

  @override
  State<CommandsScreen> createState() => _CommandsScreenState();
}

class _CommandsScreenState extends State<CommandsScreen> {
  @override
  Widget build(BuildContext context) {
    final commands = widget.commandService.commands;
    return Scaffold(
      appBar: AppBar(title: const Text('Commands')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateCommandScreen(
                  commandService: widget.commandService),
            ),
          );
          setState(() {});
        },
        child: const Icon(Icons.add),
      ),
      body: commands.isEmpty
          ? const Center(
              child: Text('No commands yet. Tap + to add one.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: commands.length,
              itemBuilder: (context, index) {
                final cmd = commands[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      cmd.actionType == ActionType.radio
                          ? Icons.radio
                          : cmd.actionType == ActionType.ytHandleLive
                              ? Icons.play_circle
                              : Icons.question_mark,
                      color: cmd.enabled ? null : Colors.grey,
                    ),
                    title: Text(cmd.triggerPhrase),
                    subtitle: Text(
                      cmd.actionType == ActionType.radio
                          ? 'Radio — ${cmd.actionParams['stationName'] ?? ''}'
                          : cmd.actionType == ActionType.ytHandleLive
                              ? 'YT Live — ${cmd.actionParams['handle'] ?? ''}'
                              : '',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: cmd.enabled,
                          onChanged: (v) async {
                            await widget.commandService
                                .update(cmd.copyWith(enabled: v));
                            setState(() {});
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await widget.commandService.delete(cmd.id);
                            setState(() {});
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
