import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum ActionType { radio, ytHandleLive }

class Command {
  final String id;
  String triggerPhrase;
  ActionType actionType;
  Map<String, dynamic> actionParams;
  bool enabled;

  Command({
    String? id,
    required this.triggerPhrase,
    required this.actionType,
    required this.actionParams,
    this.enabled = true,
  }) : id = id ?? _uuid.v4();

  Command copyWith({
    String? triggerPhrase,
    ActionType? actionType,
    Map<String, dynamic>? actionParams,
    bool? enabled,
  }) {
    return Command(
      id: id,
      triggerPhrase: triggerPhrase ?? this.triggerPhrase,
      actionType: actionType ?? this.actionType,
      actionParams: actionParams ?? Map.from(this.actionParams),
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'triggerPhrase': triggerPhrase,
        'actionType': actionType.name,
        'actionParams': actionParams,
        'enabled': enabled,
      };

  factory Command.fromJson(Map<String, dynamic> json) => Command(
        id: json['id'] as String,
        triggerPhrase: json['triggerPhrase'] as String,
        actionType: ActionType.values.byName(json['actionType'] as String),
        actionParams: Map<String, dynamic>.from(json['actionParams'] as Map),
        enabled: json['enabled'] as bool? ?? true,
      );
}
