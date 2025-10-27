import 'dart:async';
import 'dart:developer';

import 'package:chat_apps/data/local/isar_service.dart';
import 'package:chat_apps/data/model/isar_messages_model.dart';
import 'package:chat_apps/data/remote/firestore/messages_data_firestore.dart';
import 'package:chat_apps/sharing/utils/date_time_convert.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';

/// A [ChatController] implementation that uses Isar for local caching
/// and Firestore for real-time synchronization, inspired by the logic
/// in `RoomController`.
class CustomChatController extends ChatController {
  /// Creates a custom chat controller.
  CustomChatController({
    String? roomId,
    List<Message> initialMessages = const [],
  }) : _messages = List<Message>.from(initialMessages) {
    if (roomId != null) {
      initializeRoom(roomId);
    }
  }

  final _isarService = IsarService.instance;
  final _messagesDataFirestore = MessagesDataFirestore();
  final _operationStreamController =
      StreamController<ChatOperation>.broadcast();
  StreamSubscription<List<Message>>? _firestoreSyncSub;

  String? _roomId;
  List<Message> _messages;

  /// Initializes the controller for a specific room.
  /// Loads messages from the local Isar cache first, then starts
  /// syncing with Firestore in the background.
  Future<void> initializeRoom(String roomId) async {
    if (_roomId == roomId) return; // Already initialized for this room
    _roomId = roomId;

    final cachedIsarMessages = await _isarService.getCachedMessages(roomId);
    final cachedUiMessages = _transformIsarToUi(cachedIsarMessages);
    await setMessages(cachedUiMessages);
    log(
      'CustomChatController: Loaded ${cachedUiMessages.length} messages from cache for room $roomId.',
    );

    _beginFirestoreSync(roomId);
  }

  void _beginFirestoreSync(String roomId) {
    _firestoreSyncSub?.cancel();
    _firestoreSyncSub = _messagesDataFirestore
        .watchMessagesInRoom(roomId)
        .listen(
          (firestoreMessages) async {
            log(
              'CustomChatController: Received ${firestoreMessages.length} messages from Firestore. Syncing...',
            );

            final isarMessages = _transformUiToIsar(firestoreMessages);
            await setMessages(firestoreMessages);

            await _isarService.cacheMessagesForRoom(roomId, isarMessages);
          },
          onError: (e, st) {
            log(
              'CustomChatController: Firestore sync error: $e',
              error: e,
              stackTrace: st,
            );
          },
        );
  }

  @override
  void dispose() {
    _firestoreSyncSub?.cancel();
    _operationStreamController.close();
  }

  @override
  List<Message> get messages => _messages;

  @override
  Stream<ChatOperation> get operationsStream =>
      _operationStreamController.stream;

  @override
  Future<void> insertAllMessages(List<Message> messages, {int? index}) async {
    final newMessages = List<Message>.from(_messages);
    newMessages.insertAll(newMessages.length - 1, messages);
    _messages = newMessages;
    _operationStreamController.add(
      ChatOperation.insertAll(messages, index ?? newMessages.length - 1),
    );
  }

  @override
  Future<void> insertMessage(Message message, {int? index}) async {
    final newMessages = List<Message>.from(_messages);
    newMessages.insert(newMessages.length - 1, message);
    _messages = newMessages;
    _operationStreamController.add(
      ChatOperation.insert(message, index ?? newMessages.length - 1),
    );

    log(
      'CustomChatController: Inserted message ${message.id} locally in room $_roomId.',
    );
    // Kirim ke Firestore jika sudah ada roomId
    if (_roomId != null) {
      try {
        await _messagesDataFirestore.insertMessage(_roomId!, message);
      } catch (e, st) {
        log(
          'CustomChatController: Failed to send message to Firestore: $e',
          stackTrace: st,
        );
      }
    }
  }

  @override
  Future<void> removeMessage(Message message) async {
    final index = _messages.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      final newMessages = List<Message>.from(_messages);
      final removedMessage = newMessages.removeAt(index);
      _messages = newMessages;
      _operationStreamController.add(
        ChatOperation.remove(removedMessage, index),
      );
    }
  }

  @override
  Future<void> setMessages(List<Message> messages) async {
    _messages = List<Message>.from(messages);
    _operationStreamController.add(ChatOperation.set(messages));
  }

  @override
  Future<void> updateMessage(Message oldMessage, Message newMessage) async {
    final index = _messages.indexWhere((m) => m.id == oldMessage.id);
    if (index != -1) {
      final newMessages = List<Message>.from(_messages);
      newMessages[index] = newMessage;
      _messages = newMessages;
      _operationStreamController.add(
        ChatOperation.update(oldMessage, newMessage, index),
      );
    }
    log(
      'CustomChatController: Updated message ${newMessage.id} locally in room $_roomId.',
    );
    if (_roomId != null) {
      try {
        await _messagesDataFirestore.updateMessage(
          _roomId!,
          newMessage.id,
          newMessage.toJson(),
        );
      } catch (e, st) {
        log(
          'CustomChatController: Failed to update message in Firestore: $e',
          stackTrace: st,
        );
      }
    }
  }

  // --- Helper methods from RoomController ---
  /// Refresh last message for a specific room.
  List<Message> _transformIsarToUi(List<IsarMessage> isarMessages) {
    return isarMessages.map((isarMsg) {
        return TextMessage(
          id: isarMsg.messageId,
          authorId: User(id: isarMsg.authorId).toString(),
          text: isarMsg.text,
          createdAt: isarMsg.createdAt,
        );
      }).toList()
      ..sort((a, b) => (b.createdAt ?? 0).toDateTime().compareTo(a.createdAt!));
  }

  /// Transform UI messages to Isar messages for caching.
  List<IsarMessage> _transformUiToIsar(List<Message> uiMessages) {
    return uiMessages.map((msg) {
      final text = msg is TextMessage ? msg.text : '';
      log(
        'Transforming message ${msg.id} of type ${msg.toJson()} to IsarMessage.',
      );
      return IsarMessage()
        ..messageId = msg.id
        ..authorId = msg.authorId
        ..text = text
        ..createdAt = msg.createdAt?.toLocal() ?? DateTime.now()
        ..type = msg.metadata?['type'] ?? 'text';
    }).toList();
  }
}
