import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum PlaylistItemType { videoLink, ytLive }

class PlaylistItem {
  final String id;
  PlaylistItemType type;
  String label;
  String source;

  PlaylistItem({
    String? id,
    required this.type,
    required this.label,
    required this.source,
  }) : id = id ?? _uuid.v4();

  PlaylistItem copyWith({
    PlaylistItemType? type,
    String? label,
    String? source,
  }) {
    return PlaylistItem(
      id: id,
      type: type ?? this.type,
      label: label ?? this.label,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'label': label,
        'source': source,
      };

  factory PlaylistItem.fromJson(Map<String, dynamic> json) => PlaylistItem(
        id: json['id'] as String,
        type: PlaylistItemType.values.byName(json['type'] as String),
        label: json['label'] as String,
        source: json['source'] as String,
      );
}

class Playlist {
  final String id;
  String name;
  List<PlaylistItem> items;
  DateTime createdAt;

  Playlist({
    String? id,
    required this.name,
    List<PlaylistItem>? items,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        items = items ?? [],
        createdAt = createdAt ?? DateTime.now();

  Playlist copyWith({
    String? name,
    List<PlaylistItem>? items,
  }) {
    return Playlist(
      id: id,
      name: name ?? this.name,
      items: items ?? List.from(this.items),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': items.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
        id: json['id'] as String,
        name: json['name'] as String,
        items: (json['items'] as List)
            .map((e) => PlaylistItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}