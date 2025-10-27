import 'package:chat_apps/data/model/entity_model.dart';
import 'package:chat_apps/domain/entities/members.dart';

class MembersModel implements EntityModel<Members> {
  final String uid;
  final String role;
  final String name;

  const MembersModel({
    required this.uid,
    required this.role,
    required this.name,
  });

  factory MembersModel.fromJson(Map<String, dynamic> json) => MembersModel(
    uid: json['uid'] ?? '',
    role: json['role'] ?? '',
    name: json['name'] ?? '',
  );

  @override
  Map<String, dynamic> toJson() => {'uid': uid, 'role': role, 'name': name};

  @override
  Members get toEntity => Members(uid: uid, role: role, name: name);
}
