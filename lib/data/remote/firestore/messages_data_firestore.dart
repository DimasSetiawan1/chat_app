import 'dart:async';
import 'dart:developer';
import 'package:chat_apps/data/model/last_message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';

class MessagesDataFirestore {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('rooms');

  // search messages by text content
  Future<List<QueryDocumentSnapshot>> searchMessagesByText(
    String query, {
    int limit = 50,
  }) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final snap = await _db
        .collection('conversations')
        .where('messages.text', isEqualTo: q)
        .limit(limit)
        .get();
    return snap.docs;
  }

  /// get last message from firestore
  Future<LastMessageModel?> getLastMessage(String roomId) async {
    try {
      final messagesRef = _col.doc(roomId).collection('messages');
      final querySnap = await messagesRef
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (querySnap.docs.isEmpty) {
        return null;
      }
      final data = querySnap.docs.first.data();
      return LastMessageModel.fromJson(data);
    } catch (e, st) {
      log('Error getting last message from Firestore: $e', stackTrace: st);
      return null;
    }
  }

  // watch messages in a room
  Stream<List<Message>> watchMessagesInRoom(String roomId) {
    try {
      if (roomId.isEmpty) {
        log('watchMessagesInRoom: roomId is null/empty');
        return const Stream.empty();
      }

      return _col
          .doc(roomId)
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .handleError((e) {
            log('watchMessagesInRoom stream error: $e');
          })
          .map((snap) {
            final result = <Message>[];
            for (final doc in snap.docs) {
              final data = doc.data();
              result.add(
                Message.fromJson(
                  data.map((key, value) {
                    if (key == 'createdAt' ||
                        key == 'deliveredAt' ||
                        key == 'readAt' ||
                        key == 'updatedAt') {
                      return MapEntry(
                        key,
                        DateTime.tryParse(
                          value.toString(),
                        )?.millisecondsSinceEpoch,
                      );
                    }
                    return MapEntry(key, value);
                  }),
                ),
              );
            }
            return result;
          });
    } catch (e, st) {
      log('Error in watchMessagesInRoom: $e', stackTrace: st);
      return const Stream.empty();
    }
  }

  // Insert message to firestore
  Future<void> insertMessage(String roomId, Message message) async {
    try {
      final messagesRef = _col.doc(roomId).collection('messages');
      log('Inserting message to Firestore: ${message.toJson()}');
      messagesRef.doc(message.id).set(message.toJson());
    } catch (e, st) {
      log('Error inserting message to Firestore: $e', stackTrace: st);
    }
  }

  // Remove message from firestore
  Future<void> removeMessage(String roomId, String messageId) async {
    try {
      final messageRef = _col.doc(roomId).collection('messages').doc(messageId);
      await messageRef.delete();
    } catch (e, st) {
      log('Error removing message from Firestore: $e', stackTrace: st);
    }
  }

  // Update message in firestore
  Future<void> updateMessage(
    String roomId,
    String messageId,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      final messageRef = _col.doc(roomId).collection('messages').doc(messageId);
      await messageRef.update(updatedData);
    } catch (e, st) {
      log('Error updating message in Firestore: $e', stackTrace: st);
    }
  }

  // Create Or Update reaction to message
  Future<void> createOrUpdateReaction(String roomId, Message message) async {
    try {
      final messageRef = _col
          .doc(roomId)
          .collection('messages')
          .doc(message.id);
      log(
        'Creating or updating reaction to message in Firestore: ${message.reactions} to message ${message.id} in room $roomId',
      );
      await messageRef.update({
        'reactions': message.reactions,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e, st) {
      log('Error adding reaction to message in Firestore: $e', stackTrace: st);
    }
  }
}
