import 'package:isar/isar.dart';

part 'generator/isar_messages_model.g.dart';

@collection
class IsarMessage {
  Id id = Isar.autoIncrement;

  // JSON "id": "msg_0001"
  @Index(unique: true, replace: true, caseSensitive: false)
  late String messageId;

  @Index()
  late String authorId;

  late String text;
  late DateTime createdAt;
  late String type; // text 

  // optional
  String? replyTo;  // messageId being replied to
 
  // embedded list of attachment objects
  late List<Attachment> attachments = [];

  // embedded meta object (delivered/read lists)
  Meta? meta;
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
