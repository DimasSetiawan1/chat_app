import 'package:chat_apps/domain/entities/attachment.dart';

class Messages {
  final String id;
  final String roomId;
  final String authorId;
  final String text;
  final String createdAt;
  final String type;
  final String replyTo;
  final List<Attachments> attachments;
  const Messages({
    required this.id,
    required this.roomId,
    required this.authorId,
    required this.text,
    required this.createdAt,
    required this.type,
    required this.replyTo,
    required this.attachments,
  });
}