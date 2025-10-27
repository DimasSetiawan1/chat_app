import 'dart:developer';

import 'package:chat_apps/data/model/user_model.dart';
import 'package:chat_apps/sharing/utils/date_time_convert.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersDataFirestore {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('users');

  // Tambahkan method untuk menyimpan token FCM
  Future<void> saveFcmToken(String uid, String token) async {
    final doc = _col.doc(uid);
    await doc.update({
      'fcmTokens': FieldValue.arrayUnion([token]),
    });
  }

  // Parse DocumentSnapshot -> UsersModel
  UsersModel _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UsersModel.fromJson({
      'uid': data['uid'] ?? doc.id,
      'name': data['name'] ?? '',
      'avatarUrl': data['avatarUrl'] ?? '',
      'role': data['role'] ?? '',
      'email': (data['email'] ?? '').toString(),
      'createdAt': data['createdAt'].toString(),
      'lastSeenAt': data['lastSeenAt'].toString(),
    });
  }

  /// Create user profile to firestore.
  // Catatan: email disimpan lower-case agar pencarian konsisten (tanpa field tambahan).
  Future<void> createUser(UsersModel user) async {
    final doc = _col.doc(user.uid);
    final payload = <String, dynamic>{
      'uid': user.uid,
      'name': user.name,
      'avatarUrl': user.avatarUrl,
      'role': user.role,
      'email': user.email.toLowerCase(),
      // Jika kosong, pakai serverTimestamp. Jika sudah ada string, kirim string apa adanya.
      'createdAt': (user.createdAt.isEmpty)
          ? DateTime.now().toUtc()
          : user.createdAt,
      'lastSeenAt': (user.lastSeenAt.isEmpty)
          ? DateTime.now().toUtc()
          : user.lastSeenAt,
    };

    // Firestore rules: users.create hanya izinkan key whitelist di atas.
    await doc.set(payload);
  }

  /// Update field non-sensitif (name, avatarUrl, lastSeenAt) sesuai rules
  Future<void> updateProfile({
    required String uid,
    String? name,
    String? avatarUrl,
    String? email,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
    if (email != null) data['email'] = email.toLowerCase();
    if (data.isEmpty) return;
    log('Updating user profile for $uid with data: $data');
    await _col.doc(uid).update(data);
  }

  // Get user by UID
  Future<UsersModel?> getUserByUid(String uid) async {
    final snap = await _col.doc(uid).get();
    if (!snap.exists) return null;
    return _fromDoc(snap);
  }

  // Watch user by UID
  Stream<UsersModel?> watchByUid(String uid) {
    return _col.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return _fromDoc(doc);
    });
  }

  // Update lastSeenAt ke waktu sekarang
  Future<void> touchLastSeen(String uid) async {
    await _col.doc(uid).update({'lastSeenAt': FieldValue.serverTimestamp()});
  }

  // Cari user by email (exact, case-insensitive karena kita simpan lower-case)
  Future<UsersModel?> getByEmail(String email) async {
    final q = email.trim().toLowerCase();
    if (q.isEmpty) return null;
    final snap = await _col.where('email', isEqualTo: q).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return _fromDoc(snap.docs.first);
  }

  // Prefix search email tanpa field tambahan (orderBy + startAt/endAt)
  Future<List<UsersModel>> searchByEmailPrefix(
    String query,
    String role, {
    int limit = 10,
  }) async {
    try {
      final q = query.trim().toLowerCase();
      if (q.isEmpty) return [];
      final end = '$q\uf8ff';
      final QuerySnapshot<Map<String, dynamic>> snap;
      if (role == 'any') {
        snap = await _col
            .orderBy('email')
            .startAt([q])
            .endAt([end])
            .limit(limit)
            .get();
        return snap.docs.map(_fromDoc).toList();
      } else {
        snap = await _col
            .orderBy('email')
            .startAt([q])
            .endAt([end])
            .where('role', isEqualTo: role)
            .limit(limit)
            .get();
      }

      return snap.docs.map(_fromDoc).toList();
    } catch (e) {
      log('Error searching users by email prefix: $e');
      return [];
    }
  }
}
