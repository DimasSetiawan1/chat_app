import 'package:chat_apps/domain/entities/last_message.dart';
import 'package:chat_apps/domain/entities/members.dart';
import 'package:chat_apps/domain/entities/meta.dart';

class Rooms {
  final String id;
  final String type;
  final List<Members> members;
  final int membersOnline;
  final String createdAt;
  final LastMessage lastMessage;
  final Meta meta;
  const Rooms({
    required this.id,
    required this.type,
    required this.members,
    required this.membersOnline,
    required this.createdAt,
    required this.lastMessage,
    required this.meta,
  });
}