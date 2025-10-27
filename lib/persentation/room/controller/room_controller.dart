import 'dart:async';
import 'dart:developer';

import 'package:chat_apps/data/local/isar_service.dart';
import 'package:chat_apps/data/model/isar_messages_model.dart';
import 'package:chat_apps/data/model/user_model.dart';
import 'package:chat_apps/data/remote/firestore/messages_data_firestore.dart';
import 'package:chat_apps/data/remote/firestore/room_data_firestore.dart';
import 'package:chat_apps/data/remote/firestore/users_data_firestore.dart';
import 'package:chat_apps/persentation/room/controller/custom_chat_controller.dart';
import 'package:chat_apps/sharing/utils/auth_utils.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:get/get.dart';

class RoomController extends GetxController {
  final _messagesDataFirestore = MessagesDataFirestore();
  // final _roomDataFirestore = RoomDataFirestore();
  final messageController = CustomChatController();
  final _usersDataFirestore = UsersDataFirestore();

  final _auth = AuthUtils();

  String get currentUserId => _auth.currentUser?.uid ?? '';

  final RxBool isLoading = false.obs;

  String? currentRoomId;

  final Rxn<List<UsersModel>> currentUser = Rxn<List<UsersModel>>();

  // internal reactive list of core Message (flutter_chat_core.Message)
  final RxList<Message> _messages = <Message>[].obs;

  /// add reaction to message
  void handleAddReaction({
    required Message message,
    required String emoji,
    required String roomId,
  }) {
    final currentReactions = message.reactions ?? {};
    final currentUsers = currentReactions[emoji] ?? <String>[];

    final userHasReacted = currentUsers.contains(currentUserId);

    // Only proceed if the reaction state will change
    if ((userHasReacted && currentUsers.length == 1) || !userHasReacted) {
      final updatedReactions = Map<String, List<String>>.from(currentReactions);
      final users = List<String>.from(currentUsers);

      if (userHasReacted) {
        users.remove(currentUserId);
      } else {
        users.add(currentUserId);
      }

      if (users.isEmpty) {
        updatedReactions.remove(emoji);
      } else {
        updatedReactions[emoji] = users;
      }

      final updatedMessage = message.copyWith(reactions: updatedReactions);

      try {
        final messageIndex = _messages.indexWhere((m) => m.id == message.id);
        if (messageIndex == -1) {
          messageController.updateMessage(message, updatedMessage);
          return;
        }

        final trueOldMessage = _messages[messageIndex];

        messageController.updateMessage(trueOldMessage, updatedMessage);

        _messages[messageIndex] = updatedMessage;

        update();
      } catch (e) {
        log('Error during optimistic update: $e');
        messageController.updateMessage(message, updatedMessage);
      }
      update();
      _messagesDataFirestore.createOrUpdateReaction(roomId, updatedMessage);
    }
  }

  /// get data user by id
  Future<void> getUserById(List<String> userIds) async {
    try {
      final users = await Future.wait(
        userIds.map((id) => _usersDataFirestore.getUserByUid(id)),
      );
      for (var user in users) {
        if (user != null && user.avatarUrl.isNotEmpty) {
          currentUser.value = users.whereType<UsersModel>().toList();
          update();
        }
      }
    } catch (e) {
      log('Error getting user by id: $e');
    }
  }
}
