import 'package:isar/isar.dart';

part 'generator/isar_users_model.g.dart';

@collection
class IsarUser {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true, caseSensitive: false)
  late String uid;

  @Index(caseSensitive: false)
  late String email;

  late String name;
  late String avatarUrl;
  late String role;

  // Match domain: store as String; default only for createdAt
  late String createdAt = DateTime.now().toIso8601String();
  late String lastSeenAt;
}
