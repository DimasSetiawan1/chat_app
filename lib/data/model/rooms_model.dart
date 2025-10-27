
import 'package:chat_apps/data/model/entity_model.dart';
import 'package:chat_apps/data/model/last_message_model.dart';
import 'package:chat_apps/data/model/members_model.dart';
import 'package:chat_apps/data/model/meta_model.dart';
import 'package:chat_apps/domain/entities/members.dart';
import 'package:chat_apps/domain/entities/rooms.dart';

class RoomsModel implements EntityModel<Rooms> {
  final String id;
  final String type;
  final List<Members> members;
  final int membersOnline;
  final String createdAt;
  final LastMessageModel lastMessage;
  final MetaModel meta;

  const RoomsModel({
    required this.id,
    required this.type,
    required this.members,
    required this.membersOnline,
    required this.createdAt,
    required this.lastMessage,
    required this.meta,
  });

  factory RoomsModel.fromJson(Map<String, dynamic> json) => RoomsModel(
    id: json['id'] ?? '',
    type: json['type'] ?? '',
    members:
        (json['members'] as List?)
            ?.map((e) {
              if (e is Members) {
                return e;
              }
              if (e is Map) {
                final data = Map<String, dynamic>.from(e);
                return MembersModel.fromJson(data).toEntity;
              }
              return null;
            })
            .whereType<Members>()
            .toList() ??
        [],
    membersOnline: json['membersOnline'] ?? 0,
    createdAt: json['createdAt'] ?? '',
    lastMessage: json['lastMessage'] != null
        ? LastMessageModel.fromJson(
            Map<String, dynamic>.from(json['lastMessage'] as Map),
          )
        : LastMessageModel(text: '', authorId: '', createdAt: ''),
    meta: json['meta'] != null
        ? MetaModel.fromJson(Map<String, dynamic>.from(json['meta'] as Map))
        : MetaModel(topic: '', sessionId: ''),
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'members': members
        .map((e) => {"uid": e.uid, "name": e.name, "role": e.role})
        .toList(),
    'membersOnline': membersOnline,
    'createdAt': createdAt,
    'lastMessage': lastMessage.toJson(),
    'meta': meta.toJson(),
  };

  @override
  Rooms get toEntity => Rooms(
    id: id,
    type: type,
    members: members.toList(),
    membersOnline: membersOnline,
    createdAt: createdAt,
    lastMessage: lastMessage.toEntity,
    meta: meta.toEntity,
  );

  RoomsModel copyWith({
    String? id,
    String? type,
    List<Members>? members,
    int? membersOnline,
    String? createdAt,
    LastMessageModel? lastMessage,
    MetaModel? meta,
  }) {
    return RoomsModel(
      id: id ?? this.id,
      type: type ?? this.type,
      members: members ?? this.members,
      membersOnline: membersOnline ?? this.membersOnline,
      createdAt: createdAt ?? this.createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      meta: meta ?? this.meta,
    );
  }
}
