import 'dart:developer';

import 'package:chat_apps/data/local/isar_service.dart';
import 'package:chat_apps/data/model/isar_users_model.dart';
import 'package:chat_apps/data/model/user_model.dart';
import 'package:chat_apps/data/remote/firestore/users_data_firestore.dart';
import 'package:chat_apps/sharing/utils/auth_utils.dart';

class UserUtils {
  final IsarService _isarService = IsarService.instance;
  final AuthUtils _authUtils = AuthUtils();
  final UsersDataFirestore _usersDataFirestore = UsersDataFirestore();

  /// Fetches user data, prioritizing local cache over Firestore.
  /// Returns [UsersModel] if found, otherwise null.
  Future<UsersModel?> getUserData() async {
    // 1. Try to get user from local cache
    final getUserFromCache = await _isarService.getCachedUser();
    if (getUserFromCache != null) {
      return UsersModel(
        uid: getUserFromCache.uid,
        name: getUserFromCache.name,
        email: getUserFromCache.email,
        avatarUrl: getUserFromCache.avatarUrl,
        role: getUserFromCache.role,
        lastSeenAt: getUserFromCache.lastSeenAt,
        createdAt: getUserFromCache.createdAt,
      );
    }

    // 2. If not in cache, fetch from Firestore
    log('Fetching user data from Firestore');
    final currentUser = _authUtils.currentUser;
    if (currentUser != null) {
      final fetchedUser = await _usersDataFirestore.getUserByUid(
        currentUser.uid,
      );
      if (fetchedUser != null) {
        // Cache the fetched user for future use
        await _isarService.cacheUser(
          IsarUser()
            ..uid = fetchedUser.uid
            ..name = fetchedUser.name
            ..email = fetchedUser.email
            ..avatarUrl = fetchedUser.avatarUrl
            ..role = fetchedUser.role
            ..createdAt = fetchedUser.createdAt
            ..lastSeenAt = fetchedUser.lastSeenAt,
        );
        return fetchedUser;
      }
    }
    // 3. Return null if user is not found anywhere
    return null;
  }

  /// Edit and update user profile both in Firestore and local cache.
  Future<void> updateUserProfile(UsersModel updatedUser) async {
    try {
      // First, update the local cache. This ensures the change is saved
      // even if the device is offline.
      await _isarService.cacheUser(
        IsarUser()
          ..uid = updatedUser.uid
          ..name = updatedUser.name
          ..email = updatedUser.email
          ..avatarUrl = updatedUser.avatarUrl
          ..role = updatedUser.role
          ..createdAt = updatedUser.createdAt
          ..lastSeenAt = updatedUser.lastSeenAt,
      );
      log('user : ${updatedUser.uid}');

      // Then, attempt to update Firestore. Firestore's offline persistence
      // will handle syncing when the connection is restored.
      await _usersDataFirestore.updateProfile(
        uid: updatedUser.uid,
        name: updatedUser.name,
        email: updatedUser.email,
        avatarUrl: updatedUser.avatarUrl,
      );
      // log('');

      log('User profile updated successfully');
    } catch (e) {
      log('Error updating user profile: $e');
      rethrow;
    }
  }


  
}
