import 'package:isar/isar.dart';

part 'generator/isar_messages_model.g.dart';

@collection
class IsarMessage {
  Id id = Isar.autoIncrement;

  // JSON "id": "b7f3f1c9-..."
  @Index(unique: true, replace: true, caseSensitive: false)
  late String messageId;

  @Index()
  late String authorId;

  late String text;
  late DateTime createdAt;
  late String type; // "text"

  // embedded list of attachment objects
  late List<Attachment> attachments = [];

  // embedded meta object (delivered/read lists)
  Meta? meta;

  // reactions as embedded list of emoji -> list of userIds
  late List<Reaction> reactions = [];

  // timestamps seen in the screenshot
  DateTime? deliveredAt;
  DateTime? sentAt;
  DateTime? seenAt;
  DateTime? updatedAt;
}

@embedded
class Attachment {
  late String type;
  late String url;
  String? thumbnailUrl;
}

@embedded
class Meta {
  late List<String> deliveredTo = [];
  late List<String> readBy = [];
}

@embedded
class Reaction {
  // e.g. "👍" or "🙏"
  late String emoji;

  // list of user ids who reacted
  late List<String> userIds = [];
}
