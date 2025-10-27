// ...existing code...

import 'dart:async';
import 'dart:developer';

import 'package:chat_apps/data/model/user_model.dart';
import 'package:chat_apps/data/remote/firestore/room_data_firestore.dart';
import 'package:chat_apps/data/remote/firestore/users_data_firestore.dart';
import 'package:chat_apps/domain/entities/last_message.dart';
import 'package:chat_apps/domain/entities/members.dart';
import 'package:chat_apps/domain/entities/meta.dart';
import 'package:chat_apps/sharing/utils/auth_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

class CreateRoomController extends GetxController {
  final _roomData = RoomDataFirestore();
  final _usersData = UsersDataFirestore();
  final _authUtils = AuthUtils();
  final roomName = TextEditingController();

  get currentUserEmail => _authUtils.currentUser?.email ?? '';

  final roomType = 'trio'.obs;
  final Rxn<UsersModel> selectedStudent = Rxn<UsersModel>();
  final Rxn<UsersModel> selectedParent = Rxn<UsersModel>();
  final isLoading = false.obs;
  final RxList<UsersModel> groupUsers = <UsersModel>[].obs;
  Timer? _debounce;

  /// Search users by email prefix
  Future<List<UsersModel>> searchUsers(String query, String role) async {
    final completer = Completer<List<UsersModel>>();

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Mulai timer baru
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        // Panggil fungsi pencarian asli setelah timer selesai
        final users = await _usersData.searchByEmailPrefix(query, role);
        final nonEmpty = users.where((u) {
          if (u.email != currentUserEmail) {
            return u.email.trim().isNotEmpty;
          }
          return false;
        }).toList();
        completer.complete(nonEmpty);
      } catch (e) {
        log('Error searching users: $e');
        completer.complete([]);
      }
    });

    return completer.future;
  }

  // Group room user management
  void addUserToGroup(UsersModel email) {
    if (!groupUsers.contains(email)) {
      groupUsers.add(email);
    }
  }

  // Remove user from group room
  void removeUserFromGroup(UsersModel email) {
    groupUsers.remove(email);
  }

  // Clear all users from group room
  void clearGroupUsers() {
    groupUsers.clear();
  }

  // Create room based on type
  Future<void> createRoom() async {
    isLoading.value = true;
    if (_authUtils.currentUser == null) {
      Get.snackbar('Error', 'No authenticated user found');
      isLoading.value = false;
      return;
    }
    try {
      if (roomType.value == 'trio') {
        final selectedTutor = await _usersData.getByEmail(currentUserEmail);
        if (selectedParent.value == null ||
            selectedStudent.value == null ||
            selectedTutor == null) {
          Get.snackbar('Error', 'All users must exist');
          return;
        }
        final members = [
          Members(
            uid: selectedStudent.value!.uid,
            role: 'student',
            name: selectedStudent.value!.name,
          ),
          Members(
            uid: selectedTutor.uid,
            role: 'tutor',
            name: selectedTutor.name,
          ),
          Members(
            uid: selectedParent.value!.uid,
            role: 'parent',
            name: selectedParent.value!.name,
          ),
        ];
        final LastMessage lastMessage = LastMessage(
          text: "",
          authorId: "",
          createdAt: DateTime.now().toUtc().toString(),
        );
        final meta = Meta(topic: roomName.text, sessionId: Uuid().v4());
        final room = await _roomData.createOrGetTrioRoom(
          type: "trio",
          members: members,
          membersOnline: 1,
          lastMessage: lastMessage,
          meta: meta,
          createdAt: DateTime.now(),
        );
        Get.toNamed('/chat', arguments: {'room': room.toJson()});
      } else {
        final currentUserData = await _usersData.getByEmail(currentUserEmail);
        if (currentUserData == null) {
          Get.snackbar('Error', 'Current user data not found');
          // Get.offAllNamed('/login');
          return;
        }
        if (groupUsers.isEmpty) {
          Get.snackbar('Error', 'Add at least one user to the group');
          return;
        }
        final List<Members> members = [
          Members(
            uid: currentUserData.uid,
            role: currentUserData.role,
            name: currentUserData.name,
          ),
        ];
        members.addAll(
          groupUsers.map(
            (u) => Members(uid: u.uid, role: u.role, name: u.name),
          ),
        );
        final LastMessage lastMessage = LastMessage(
          text: "",
          authorId: "",
          createdAt: DateTime.now().toUtc().toString(),
        );
        final meta = Meta(topic: roomName.text, sessionId: Uuid().v4());

        final room = await _roomData.createOrGetTrioRoom(
          type: "group",
          members: members,
          membersOnline: 1,
          lastMessage: lastMessage,
          meta: meta,
          createdAt: DateTime.now(),
        );
        log('Created group room: ${room.toJson()}');

        Get.toNamed('/chat', arguments: {'room': room.toJson()});
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
