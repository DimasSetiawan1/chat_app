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
}
