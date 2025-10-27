import 'package:chat_apps/data/model/attachment_model.dart';
import 'package:chat_apps/data/model/entity_model.dart';
import 'package:chat_apps/domain/entities/message.dart';

class MessagesModel implements EntityModel<Messages> {
  final String id;
  final String roomId;
  final String authorId;
  final String text;
  final String createdAt;
  final String type;
  final String replyTo;
  final List<AttachmentsModel> attachments;

  const MessagesModel({
    required this.id,
    required this.roomId,
    required this.authorId,
    required this.text,
    required this.createdAt,
    required this.type,
    required this.replyTo,
    required this.attachments,
  });

  factory MessagesModel.fromJson(Map<String, dynamic> json) => MessagesModel(
    id: json['id'] ?? '',
    roomId: json['roomId'] ?? '',
    authorId: json['authorId'] ?? '',
    text: json['text'] ?? '',
    createdAt: json['createdAt'] ?? '',
    type: json['type'] ?? '',
    replyTo: json['replyTo'] ?? '',
    attachments:
        (json['attachments'] as List?)
            ?.map((e) => AttachmentsModel.fromJson(e))
            .toList() ??
        [],
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'roomId': roomId,
    'authorId': authorId,
    'text': text,
    'createdAt': createdAt,
    'type': type,
    'replyTo': replyTo,
    'attachments': attachments.map((e) => e.toJson()).toList(),
  };

  @override
  Messages get toEntity => Messages(
    id: id,
    roomId: roomId,
    authorId: authorId,
    text: text,
    createdAt: createdAt,
    type: type,
    replyTo: replyTo,
    attachments: attachments.map((e) => e.toEntity).toList(),
  );
}
