import 'dart:async';
import 'dart:developer';

import 'package:chat_apps/data/model/user_model.dart';
import 'package:chat_apps/data/remote/firestore/messages_data_firestore.dart';
import 'package:chat_apps/data/remote/firestore/room_data_firestore.dart';
import 'package:chat_apps/data/remote/firestore/users_data_firestore.dart';
import 'package:chat_apps/sharing/utils/auth_utils.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:get/get.dart';

class RoomController extends GetxController {
  final _messagesDataFirestore = MessagesDataFirestore();
  final _roomDataFirestore = RoomDataFirestore();
  final messageController = InMemoryChatController();
  final _usersDataFirestore = UsersDataFirestore();
  final _auth = AuthUtils();

  String get currentUserId => _auth.currentUser?.uid ?? '';

  String? currentRoomId;

  final Rxn<UsersModel> currentUser = Rxn<UsersModel>();

  // internal reactive list of core Message (flutter_chat_core.Message)
  final RxList<Message> _messages = <Message>[].obs;

  final RxInt onlineCount = 0.obs;

  StreamSubscription<List<Message>>? _sub;

  // start listening to messages in a room
  void startListeningToMessages(String roomId) {
    _sub?.cancel();
    _sub = _messagesDataFirestore
        .watchMessagesInRoom(roomId)
        .listen(
          (newMessages) {
            final existingMessageIds = _messages.map((m) => m.id).toSet();

            for (final message in newMessages) {
              if (existingMessageIds.contains(message.id)) {
                final oldMessage = _messages.firstWhere(
                  (m) => m.id == message.id,
                );
                if (oldMessage != message) {
                  messageController.updateMessage(message, oldMessage);
                }
              } else {
                messageController.insertMessage(message, animated: true);
              }
            }

            final newMessageIds = newMessages.map((m) => m.id).toSet();
            for (final oldMessage in _messages) {
              if (!newMessageIds.contains(oldMessage.id)) {
                messageController.removeMessage(oldMessage);
              }
            }

            _messages.assignAll(newMessages);
            update();
          },
          onError: (e, st) {
            log('messages stream error: $e', error: e, stackTrace: st);
          },
        );
  }

  /// add reaction to message
  void handleAddReaction({
    required Message message,
    required String emoji,
    required String roomId,
  }) {
    final updatedReactions = Map<String, List<String>>.from(
      message.reactions ?? {},
    );

    final users = List<String>.from(updatedReactions[emoji] ?? []);

    if (users.contains(currentUserId)) {
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
        messageController.updateMessage(updatedMessage, message);
        return;
      }

      final trueOldMessage = _messages[messageIndex];

      messageController.updateMessage(updatedMessage, trueOldMessage);

      _messages[messageIndex] = updatedMessage;

      update();
    } catch (e) {
      log('Error during optimistic update: $e');
      messageController.updateMessage(updatedMessage, message);
    }
    update();

    _messagesDataFirestore.addReactionToMessage(roomId, updatedMessage);
  }

  // remove reaction
  void handleRemoveReaction({
    required Message message,
    required String emoji,
    required String roomId,
  }) {
    final updatedReactions = Map<String, List<String>>.from(
      message.reactions ?? {},
    );

    final users = List<String>.from(updatedReactions[emoji] ?? []);

    users.remove(currentUserId);

    if (users.isEmpty) {
      updatedReactions.remove(emoji);
    } else {
      updatedReactions[emoji] = users;
    }

    // Optimistic Update: Perbarui UI secara lokal dulu agar terasa instan
    final updatedMessage = message.copyWith(reactions: updatedReactions);
    try {
      final messageIndex = _messages.indexWhere((m) => m.id == message.id);
      if (messageIndex == -1) {
        messageController.updateMessage(updatedMessage, message);
        return;
      }

      final trueOldMessage = _messages[messageIndex];

      // 1. Lakukan optimistic update pada UI
      messageController.updateMessage(updatedMessage, trueOldMessage);

      // 2. Lakukan optimistic update pada state internal (_messages)
      _messages[messageIndex] = updatedMessage;

      // 3. Trigger GetBuilder
      update();
    } catch (e) {
      log('Error during optimistic update: $e');
      messageController.updateMessage(updatedMessage, message);
    }
    update();

    // Kirim perubahan ke Firestore
    _messagesDataFirestore.addReactionToMessage(roomId, updatedMessage);
  }

  // watch online members count
  void watchOnlineMembersCount(String roomId) {
    _roomDataFirestore
        .watchMembersOnline(roomId)
        .listen(
          (count) {
            onlineCount.value = count;
          },
          onError: (e, st) {
            log(
              'online members count stream error: $e',
              error: e,
              stackTrace: st,
            );
          },
        );
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  // Insert message to firestore
  Future<void> insertMessage(Message message, {int? index}) async {
    if (currentRoomId != null) {
      try {
        await _messagesDataFirestore.insertMessage(currentRoomId!, message);
      } catch (e) {
        log('Error inserting message: $e', error: e);
      }
    } else {
      log('insertMessage aborted: currentRoomId is null');
    }
  }

  /// get data user by id
  Future<void> getUserById() async {
    try {
      final user = await _usersDataFirestore.getUserByUid(currentUserId);
      currentUser.value = user;
    } catch (e) {
      log('Error getting user by id: $e');
      // Get.snackbar('Error', 'Failed to get user data.');
    }
  }
}
