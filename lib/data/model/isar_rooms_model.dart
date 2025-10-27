import 'package:isar/isar.dart';

part 'generator/isar_rooms_model.g.dart';

@collection
class IsarRoom {
  // internal isar id (tetap perlu bernama `id`)
  Id id = Isar.autoIncrement;

  // Rooms.id (Firestore room id)
  @Index(unique: true, replace: true, caseSensitive: false)
  late String roomId;

  // Rooms.type: 'trio' | 'group'
  @Index(caseSensitive: false)
  late String type;

  // Rooms.members (disimpan sebagai embedded untuk mapping ke MembersModel)
  List<IsarMember> members = [];

  // Rooms.membersOnline
  @Index(caseSensitive: false)
  late int membersOnline;

  // Rooms.createdAt (String pada entity)
  @Index(caseSensitive: false)
  late String createdAt;

  // Rooms.lastMessage (wajib ada pada entity)
  late IsarLastMessage lastMessage;

  // Rooms.meta (disimpan sebagai JSON agar fleksibel)
  String? metaJson;
}

@embedded
class IsarMember {
  late String uid;
  String? role;       // tutor | parent | student
  String? name;
}


@embedded
class IsarLastMessage {
  late DateTime createdAt;
  String? authorId; 
  String? text;
}
