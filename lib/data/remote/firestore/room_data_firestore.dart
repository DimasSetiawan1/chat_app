import 'dart:developer';

import 'package:chat_apps/data/local/isar_service.dart';
import 'package:chat_apps/data/model/isar_rooms_model.dart';
import 'package:chat_apps/data/model/last_message_model.dart';
import 'package:chat_apps/data/model/meta_model.dart';
import 'package:chat_apps/data/model/rooms_model.dart';
import 'package:chat_apps/domain/entities/last_message.dart';
import 'package:chat_apps/domain/entities/members.dart';
import 'package:chat_apps/domain/entities/meta.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomDataFirestore {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('rooms');
  final IsarService _isarService = IsarService.instance;


  /// update Last Message in room
  Future<void> updateLastMessage(
      String roomId, LastMessageModel lastMessage) async {
    try {
      await _col.doc(roomId).update({
        'lastMessage': lastMessage.toJson(),
      });
    } catch (e, st) {
      log('Error updating last message in Firestore: $e', stackTrace: st);
    }
  }


  // watch online members count
  Stream<int> watchMembersOnline(String roomId) {
    return _col.doc(roomId).snapshots().map((docSnap) {
      final data = docSnap.data();
      if (data == null) return 0;
      final count = data['membersOnline'];
      if (count is int) {
        return count;
      }
      return 0;
    });
  }

  // watch room list for a user
  Stream<List<RoomsModel>> watchRoomList({
    required String uid,
    int limit = 50,
  }) {
    try {
      if (uid.isEmpty) {
        log('watchChatList: currentUser uid is null/empty');
        return const Stream.empty();
      }

      return _col
          .where('memberUids', arrayContains: uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .handleError((e) {
            log('watchRoomList stream error: $e uid: $uid');
          })
          .map((snap) {
            final result = <RoomsModel>[];
            for (final doc in snap.docs) {
              final data = doc.data();
              final memberUids =
                  (data['memberUids'] as List?)?.whereType<String>().toList() ??
                  const <String>[];

              if (!memberUids.contains(uid)) continue;

              final map = <String, dynamic>{
                ...data,
                'id': data['id'] ?? doc.id,
              };
              result.add(RoomsModel.fromJson(map));
            }
            return result;
          });
    } catch (e, st) {
      log('Error in watchChatList: $e', stackTrace: st);
      return const Stream.empty();
    }
  }

  

  //create a new room
  /// Type : 'trio' or 'group'
  /// members : list of user ids,  role and names
  /// membersKey : merge of user ids as keys for easy searching
  /// meta : additional data like : topic , session id
  Future<RoomsModel> createOrGetTrioRoom({
    required String type,
    required List<Members> members,
    required int membersOnline,
    required DateTime createdAt,
    LastMessage? lastMessage,
    Meta? meta,
  }) async {
    try {
      final roomData = RoomsModel(
        id: '',
        type: type,
        members: members,
        membersOnline: membersOnline,
        createdAt: createdAt.toIso8601String(),
        lastMessage: lastMessage != null
            ? LastMessageModel(
                text: lastMessage.text,
                authorId: lastMessage.authorId,
                createdAt: lastMessage.createdAt,
              )
            : LastMessageModel(
                text: '',
                authorId: '',
                createdAt: DateTime.now().toIso8601String(),
              ),
        meta: meta != null
            ? MetaModel(topic: meta.topic, sessionId: meta.sessionId ?? "")
            : MetaModel(topic: '', sessionId: ''),
      );
      final memberUids = members.map((m) => m.uid).toList();
      final Map<String, dynamic> roomJson = roomData.toJson();
      roomJson['memberUids'] = memberUids;
      roomJson['membersOnline'] = 0;
      log('Creating room with data: $roomJson');
      final docRef = await _col.add(roomJson);
      roomData.copyWith(id: docRef.id);
      _col.doc(docRef.id).update({'id': docRef.id});

      final isarLastMessage = IsarLastMessage()
        ..authorId = roomData.lastMessage.authorId
        ..createdAt = DateTime.parse(roomData.lastMessage.createdAt)
        ..text = roomData.lastMessage.text;
      // insert to local
      await _isarService.cacheRooms(
        IsarRoom()
          ..roomId = docRef.id
          ..createdAt = roomData.createdAt
          ..type = roomData.type
          ..members = roomData.members
              .map(
                (m) => IsarMember()
                  ..uid = m.uid
                  ..name = m.name
                  ..role = m.role,
              )
              .toList()
          ..membersOnline = roomData.membersOnline
          ..lastMessage = isarLastMessage
          ..createdAt = roomData.createdAt
          ..metaJson =
              '{"topic":"${roomData.meta.topic}","sessionId":"${roomData.meta.sessionId}"}',
      );
      log('Room created with ID: ${docRef.id}');
      return roomData.copyWith(id: docRef.id);
    } catch (e) {
      log('Error creating room: $e');
      return Future.error('Something went wrong');
    }
  }
}
