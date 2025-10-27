import 'package:chat_apps/data/model/entity_model.dart';
import 'package:chat_apps/domain/entities/user.dart';

class UsersModel implements EntityModel<Users> {
  final String uid;
  final String name;
  final String avatarUrl;
  final String role;
  final String email;
  final String createdAt;
  final String lastSeenAt;

  const UsersModel({
    required this.uid,
    required this.name,
    required this.avatarUrl,
    required this.role,
    required this.email,
    required this.createdAt,
    required this.lastSeenAt,
  });

  factory UsersModel.fromJson(Map<String, dynamic> json) => UsersModel(
    uid: json['uid'] ?? '',
    name: json['name'] ?? '',
    avatarUrl: json['avatarUrl'] ?? '',
    role: json['role'] ?? '',
    email: json['email'] ?? '',
    createdAt: json['createdAt'] ?? '',
    lastSeenAt: json['lastSeenAt'] ?? '',
  );

  @override
  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'avatarUrl': avatarUrl,
    'role': role,
    'email': email,
    'createdAt': createdAt,
    'lastSeenAt': lastSeenAt,
  };

  UsersModel copyWith({
    String? uid,
    String? name,
    String? avatarUrl,
    String? role,
    String? email,
    String? createdAt,
    String? lastSeenAt,
  }) {
    return UsersModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  @override
  Users get toEntity => Users(
    uid: uid,
    name: name,
    avatarUrl: avatarUrl,
    role: role,
    email: email,
    createdAt: createdAt,
    lastSeenAt: lastSeenAt,
  );
}
