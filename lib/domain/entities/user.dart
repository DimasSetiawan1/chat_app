class Users {
  final String uid;
  final String name;
  final String avatarUrl;
  final String role;
  final String email;
  final String createdAt;
  final String lastSeenAt;
  const Users({
    required this.uid,
    required this.name,
    required this.avatarUrl,
    required this.role,
    required this.email,
    required this.createdAt,
    required this.lastSeenAt,
  });
}