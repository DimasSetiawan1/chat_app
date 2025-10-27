import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:chat_apps/data/local/isar_service.dart';
import 'package:chat_apps/data/model/isar_rooms_model.dart';
import 'package:chat_apps/data/model/rooms_model.dart';
import 'package:chat_apps/data/remote/firestore/messages_data_firestore.dart';
import 'package:chat_apps/data/remote/firestore/room_data_firestore.dart';
import 'package:chat_apps/data/remote/firestore/users_data_firestore.dart';
import 'package:chat_apps/sharing/utils/auth_utils.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  final AuthUtils _authUtils = AuthUtils();
  final UsersDataFirestore _userDataFirestore = UsersDataFirestore();
  final RoomDataFirestore _roomDataFirestore = RoomDataFirestore();
  final MessagesDataFirestore _messagesDataFirestore = MessagesDataFirestore();
  final IsarService _isarService = IsarService.instance;

  // 1. Hapus RxList<RoomsModel> yang lama, kita hanya akan pakai satu list.
  // RxList<RoomsModel> roomList = <RoomsModel>[].obs;

  // 2. Ini akan menjadi satu-satunya sumber kebenaran untuk UI daftar room.
  final rooms = <IsarRoom>[].obs;

  StreamSubscription<List<RoomsModel>>? _roomSub;
  RxBool isLoading = false.obs;
  RxBool isTutor = false.obs;
  RxString roleUser = "".obs;

  @override
  void onInit() {
    super.onInit();
    checkUserRole();
    // 3. Panggil fungsi baru yang menerapkan pola Isar-first.
    loadAndSyncRooms();
  }

  /// Pola Isar-First: Memuat room dari cache, lalu menyinkronkan dengan Firestore.
  Future<void> loadAndSyncRooms() async {
    isLoading.value = true;
    try {
      // Langkah 1: Coba muat dari cache Isar terlebih dahulu untuk UI yang instan.
      final cachedRooms = await _isarService.getCachedRooms();
      if (cachedRooms.isNotEmpty) {
        log('Loaded ${cachedRooms.length} rooms from Isar cache.');
        rooms.assignAll(cachedRooms);
        getLastMessagesForRooms(cachedRooms);
      }
    } catch (e) {
      log('Error loading rooms from cache: $e');
    } finally {
      // Walaupun cache ada, kita tetap lanjut untuk sinkronisasi.
      isLoading.value = false;
    }

    // Langkah 2: Selalu dengarkan perubahan dari Firestore di latar belakang.
    _syncRoomsFromFirestore();
  }

  /// Mendengarkan stream dari Firestore dan menyimpan hasilnya ke Isar.
  void _syncRoomsFromFirestore() {
    final currentUser = _authUtils.currentUser;
    if (currentUser == null) {
      log('Cannot sync rooms, no authenticated user.');
      return;
    }

    _roomSub?.cancel();
    _roomSub = _roomDataFirestore
        .watchRoomList(uid: currentUser.uid, limit: 20)
        .listen(
          (firestoreRooms) async {
            log(
              'Received ${firestoreRooms.length} rooms from Firestore stream.',
            );

            // Ambil cache sekarang sebagai map untuk merge
            final cached = await _isarService.getCachedRooms();
            final cachedMap = {for (var r in cached) r.roomId: r};

            // Konversi RoomsModel dari Firestore menjadi IsarRoom, tapi jangan timpa lastMessage
            final isarRooms = firestoreRooms.map((roomModel) {
              final existing = cachedMap[roomModel.id];
              final hasFm = roomModel.lastMessage.text.isNotEmpty;

              final isarRoom = IsarRoom()
                ..roomId = roomModel.id
                ..type = roomModel.type
                ..membersOnline = roomModel.membersOnline
                ..createdAt = roomModel.createdAt.toString()
                ..lastMessage = IsarLastMessage()
                ..metaJson = jsonEncode({
                  'topic': roomModel.meta.topic,
                  'sessionId': roomModel.meta.sessionId,
                });

              isarRoom.members = roomModel.members
                  .map(
                    (member) => IsarMember()
                      ..uid = member.uid
                      ..role = member.role
                      ..name = member.name,
                  )
                  .toList();

              // Jika Firestore punya lastMessage, pakai itu. Jika tidak, gunakan cached lastMessage bila ada.
              if (hasFm) {
                isarRoom.lastMessage = IsarLastMessage()
                  ..authorId = roomModel.lastMessage.authorId
                  ..createdAt = DateTime.parse(roomModel.lastMessage.createdAt)
                  ..text = roomModel.lastMessage.text;
              } else if (existing?.lastMessage != null) {
                final lm = existing!.lastMessage;
                isarRoom.lastMessage = IsarLastMessage()
                  ..authorId = lm.authorId
                  ..createdAt = lm.createdAt
                  ..text = lm.text;
              }

              return isarRoom;
            }).toList();

            // Simpan ke Isar (pastikan cacheMultipleRooms juga menyimpan nested object dengan benar)
            await _isarService.cacheMultipleRooms(isarRooms);

            // Perbarui UI dengan data terbaru
            rooms.assignAll(isarRooms);
          },
          onError: (e) {
            log('Error in room stream: $e');
          },
        );
  }

  /// Pembaruan last message untuk setiap room dalam daftar.
  Future<void> refreshRoomLastMessage(String roomId) async {
    try {
      final lastMessage = await _messagesDataFirestore.getLastMessage(roomId);
      if (lastMessage == null) return;

      // update Isar cache: ambil cache semua lalu update item yang cocok
      final cached = await _isarService.getCachedRooms();
      final idx = cached.indexWhere((r) => r.roomId == roomId);
      if (idx != -1) {
        final r = cached[idx];
        r.lastMessage = IsarLastMessage()
          ..authorId = lastMessage.authorId
          ..createdAt = DateTime.parse(lastMessage.createdAt)
          ..text = lastMessage.text;
        // Simpan kembali room yang diupdate
        await _isarService.cacheMultipleRooms([r]);
      }

      // update observable list agar UI ter-refresh
      final localIdx = rooms.indexWhere((r) => r.roomId == roomId);
      if (localIdx != -1) {
        final r = rooms[localIdx];
        r.lastMessage = IsarLastMessage()
          ..authorId = lastMessage.authorId
          ..createdAt = DateTime.parse(lastMessage.createdAt)
          ..text = lastMessage.text;
        rooms.refresh();
      }
    } catch (e) {
      log('Error refreshing last message for $roomId: $e');
    }
  }

  /// Mengambil pesan terakhir untuk daftar room yang diberikan.
  Future<void> getLastMessagesForRooms(List<IsarRoom> roomList) async {
    try {
      for (final room in roomList) {
        if (room.roomId.isNotEmpty) {
          final lastMessage = await _messagesDataFirestore.getLastMessage(
            room.roomId,
          );
          if (lastMessage != null) {
            room.lastMessage = IsarLastMessage()
              ..authorId = lastMessage.authorId
              ..createdAt = DateTime.parse(lastMessage.createdAt)
              ..text = lastMessage.text;

            await _roomDataFirestore.updateLastMessage(
              room.roomId,
              lastMessage,
            );
          }
        }
      }
      // Perbarui UI lagi setelah mendapatkan last message
      rooms.assignAll(roomList);
    } catch (e) {
      log('Error getting last messages: $e');
    }
  }

  @override
  void onClose() {
    _roomSub?.cancel();
    super.onClose();
  }

  // --- FUNGSI LAINNYA (TIDAK BERUBAH) ---
  Future<String> currentUserName() async {
    final user = await _isarService.getCachedUser();
    return user?.name ?? user?.email ?? 'Guest';
  }

  // void markUserOnline(String roomId) {
  //   final currentUser = _authUtils.currentUser;
  //   if (currentUser == null) return;
  //   _roomDataFirestore.incrementMembers(roomId);
  // }

  bool get isGuest {
    final currentUser = _authUtils.currentUser;
    if (currentUser == null) return true;
    return currentUser.isAnonymous;
  }

  Future<void> checkUserRole() async {
    if (_authUtils.currentUser == null) return;
    final user = await _userDataFirestore.getUserByUid(
      _authUtils.currentUser!.uid,
    );
    roleUser.value = user?.role ?? "";
    isTutor.value = user?.role == "tutor";
  }
}
