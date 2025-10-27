import 'dart:developer';

import 'package:chat_apps/data/model/isar_rooms_model.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../model/isar_messages_model.dart';
import '../model/isar_users_model.dart';

class IsarService {
  IsarService._();
  static final IsarService instance = IsarService._();

  Isar? _isar;
  /// Initialize the Isar database.
  Future<Isar> init() async {
    if (_isar != null && _isar!.isOpen) return _isar!;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [IsarMessageSchema, IsarRoomSchema, IsarUserSchema],
      directory: dir.path,
      name: 'app_db',
      inspector: false,
    );
    return _isar!;
  }
  /// Get the Isar database instance.
  Isar get db {
    final v = _isar;
    if (v == null || !v.isOpen) {
      throw StateError(
        'Isar is not initialized. Call await IsarService.instance.init() first.',
      );
    }
    return v;
  }


/// Close the Isar database.
  Future<void> close() async {
    final v = _isar;
    if (v != null && v.isOpen) {
      await v.close();
      _isar = null;
    }
  }

  /// Rooms cache 
  Future<void> cacheRooms(IsarRoom rooms) async {
    try {
      final isar = db;
      await isar.writeTxn(() async {
        await isar.isarRooms.put(rooms);
      });
    } catch (e) {
      log('Error caching rooms: $e');
      rethrow;
    }
  }
  /// Rooms cache 
  Future<void> cacheMultipleRooms(List<IsarRoom> rooms) async {
    try {
      final isar = db;
      await isar.writeTxn(() async {
        await isar.isarRooms.putAll(rooms);
      });
    } catch (e) {
      log('Error caching rooms: $e');
      rethrow;
    }
  }

  /// Get cache user from local Isar database.
  Future<IsarUser?> getCachedUser() async {
    final isar = db;
    final users = await isar.isarUsers.where().findAll();
    return users.isNotEmpty ? users.first : null;
  }

  /// Insert and Update user data locally.
  Future<void> cacheUser(IsarUser user) async {
    try {
      final isar = db;
      await isar.writeTxn(() async {
        await isar.isarUsers.put(user);
      });
    } catch (e) {
      log('Error caching user: $e');
    }
  }

  /// Clear cached user data.
  Future<void> clearCachedUser() async {
    try {
      final isar = db;
      await isar.writeTxn(() async {
        await isar.isarUsers.clear();
      });
    } catch (e) {
      log('Error clearing cached user: $e');
    }
  }

  // Get cached rooms
  Future<List<IsarRoom>> getCachedRooms() async {
    final isar = db;
    // urutkan by updatedAt desc jika ada
    final rooms = await isar.isarRooms.where().findAll();
    rooms.sort((a, b) {
      final au = a.createdAt;
      final bu = b.createdAt;
      return bu.compareTo(au);
    });
    return rooms;
  }

  // Watch rooms stream
  Stream<List<IsarRoom>> watchRooms() {
    try {
      final isar = db;
      return isar.isarRooms.where().watch().map((rooms) {
        rooms.sort((a, b) {
          final au = a.createdAt;
          final bu = b.createdAt;
          return bu.compareTo(au);
        });
        return rooms;
      });
    } catch (e) {
      log('Error watching rooms: $e');
      return Stream.error("Something went wrong");
    }
  }

  // Messages cache
  Future<void> cacheMessages(
    String messageId,
    List<IsarMessage> messages,
  ) async {
    try {
      final isar = db;
      await isar.writeTxn(() async {
        await isar.isarMessages.putAll(messages);
        // optional: jaga hanya 20 terakhir per room
        final all = await isar.isarMessages
            .where()
            .messageIdEqualTo(messageId)
            .findAll();
        if (all.length > 20) {
          final toDelete = all.skip(20).map((e) => e.id).toList();
          if (toDelete.isNotEmpty) {
            await isar.isarMessages.deleteAll(toDelete);
          }
        }
      });
    } catch (e) {
      log('Error caching messages: $e');
    }
  }

  /// get cached messages by room id
 Future<List<IsarMessage>> getCachedMessages(String roomId) async {
    final isar = db;
    // 1. Cari room-nya terlebih dahulu
    final room = await isar.isarRooms.where().roomIdEqualTo(roomId).findFirst();

    if (room != null) {
      // 2. Muat semua message yang terhubung dengan room ini
      // IsarLinks bersifat lazy-loaded, jadi data baru ditarik saat diakses.
      final messages = await room.messages.filter().sortByCreatedAt().findAll();
      return messages.toList();
    }

    // Jika room tidak ditemukan di cache, kembalikan list kosong
    return [];
  }


  /// cached message 
  Stream<List<IsarMessage>> watchCachedMessages(String roomId) {
    final isar = db;
    final roomQuery = isar.isarRooms.where().roomIdEqualTo(roomId);

    return roomQuery.watch(fireImmediately: true).asyncMap((rooms) async {
      final room = rooms.isNotEmpty ? rooms.first : null;

      if (room != null) {
        final messages = await room.messages.filter().sortByCreatedAt().findAll();
        return messages.toList();
      } else {
        return [];
      }
    });
  }

  Future<void> cacheMessagesForRoom(
    String roomId,
    List<IsarMessage> messages,
  ) async {
    try {
      final isar = db;
      await isar.writeTxn(() async {
        // 1. Dapatkan object Room dari database berdasarkan roomId.
        var room = await isar.isarRooms.where().roomIdEqualTo(roomId).findFirst();

        // --- PERBAIKAN DI SINI ---
        // 2. Jika room belum ada di cache, buat instance baru DAN LANGSUNG SIMPAN.
        if (room == null) {
          final newRoom = IsarRoom()
            ..roomId = roomId
            ..type = 'unknown'
            ..createdAt = DateTime.now().toIso8601String();
          
          // Simpan room baru ke database agar "dikenali" oleh Isar.
          await isar.isarRooms.put(newRoom);
          
          // Ambil kembali room yang sudah "dikenali" Isar.
          room = await isar.isarRooms.where().roomIdEqualTo(roomId).findFirst();
        }

        // 3. Sekarang 'room' dijamin sudah ada dan "dikenali" Isar.
        if (room != null) {
          // 4. Simpan semua message ke dalam collection IsarMessage.
          await isar.isarMessages.putAll(messages);

          // 5. Hubungkan message-message ini ke room.
          room.messages.addAll(messages);

          // 6. Simpan perubahan pada link di dalam room. Ini sekarang akan berhasil.
          await room.messages.save();
          log('Cached ${messages.length} messages and linked to room $roomId');
        } else {
          // Ini seharusnya tidak akan pernah terjadi dengan logika di atas.
          log('Failed to create or find room $roomId.');
        }
      });
    } catch (e, s) {
      log('Error caching messages for room: $e', stackTrace: s);
      rethrow;
    }
  }
  
}
