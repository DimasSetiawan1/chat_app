import 'dart:convert';
import 'dart:developer';

import 'package:chat_apps/data/model/last_message_model.dart';
import 'package:chat_apps/data/model/meta_model.dart';
import 'package:chat_apps/data/model/rooms_model.dart';
import 'package:chat_apps/domain/entities/members.dart';
import 'package:chat_apps/persentation/home/controller/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final _homeController = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms List'),
        leading: const SizedBox(),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            position: PopupMenuPosition.under,
            offset: const Offset(0, 8),
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  Get.toNamed('/settings');
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: const [
                    Icon(Icons.settings_outlined),
                    SizedBox(width: 12),
                    Text('Pengaturan'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari obrolan',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.1),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                if (value.isEmpty) {
                  _homeController.loadAndSyncRooms();
                } else {
                  // _homeController.searchChats(value);
                }
              },
            ),
          ),
          Obx(() {
            if (_homeController.rooms.isEmpty) {
              return Expanded(
                child: const Center(
                  child: Text.rich(
                    TextSpan(
                      text: 'No chats available.\n',
                      children: [
                        TextSpan(
                          text: 'Start a new room!',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return Expanded(
              child: ListView.separated(
                itemCount: _homeController.rooms.length,
                separatorBuilder: (_, __) => const Divider(height: 0),
                itemBuilder: (context, index) {
                  final rooms = _homeController.rooms;
                  final room = rooms[index];
                  // tambahkan di atas file: import 'dart:convert';
                  String name;
                  String topic = '';
                  String sessionId = '';

                  try {
                    final meta = room.metaJson;
                    if (meta != null && meta.isNotEmpty) {
                      final Map<String, dynamic> parsed =
                          jsonDecode(meta) as Map<String, dynamic>;
                      topic = (parsed['topic'] ?? '').toString();
                      sessionId = (parsed['sessionId'] ?? '').toString();
                    }
                    // tampilkan topic sebagai nama; fallback ke room.name atau empty
                    name = topic.isNotEmpty ? topic : '';
                  } catch (e, st) {
                    log('Gagal parse metaJson for room ${room.id}: $e\n$st');
                    name = '';
                  }
                  final message = room.lastMessage.text;
                  final time = room.createdAt;

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      message!.isNotEmpty ? message : 'Start the conversation',
                      maxLines: 1,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          time.toString().substring(11, 16),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        // if (unread > 0)
                        //   Container(
                        //     margin: const EdgeInsets.only(top: 4),
                        //     padding: const EdgeInsets.symmetric(
                        //       horizontal: 6,
                        //       vertical: 2,
                        //     ),
                        //     decoration: BoxDecoration(
                        //       color: Theme.of(context).colorScheme.primary,
                        //       borderRadius: BorderRadius.circular(12),
                        //     ),
                        //     child: Text(
                        //       '',
                        //       style: TextStyle(
                        //         color:
                        //             Theme.of(context).colorScheme.onPrimary,
                        //         fontSize: 11,
                        //         fontWeight: FontWeight.bold,
                        //       ),
                        //     ),
                        //   ),
                      ],
                    ),
                    onTap: () async {
                      final data = rooms[index];
                      RoomsModel room = RoomsModel(
                        id: data.roomId,
                        type: data.type,
                        membersOnline: 0,
                        createdAt: data.createdAt,
                        lastMessage: LastMessageModel(
                          authorId: data.lastMessage.authorId ?? '',
                          createdAt: data.lastMessage.createdAt
                              .toIso8601String(),
                          text: data.lastMessage.text ?? '',
                        ),
                        members: data.members
                            .map(
                              (member) => Members(
                                name: member.name ?? '',
                                uid: member.uid,
                                role: member.role ?? '',
                              ),
                            )
                            .toList(),
                        meta: MetaModel(topic: topic, sessionId: sessionId),
                      );
                      await Get.toNamed(
                        '/room',
                        arguments: {'room': room.toJson()},
                      );
                      await _homeController.refreshRoomLastMessage(data.roomId);
                    },
                  );
                },
              ),
            );
          }),
        ],
      ),
      floatingActionButton: Obx(() {
        if (_homeController.isTutor.value) {
          return FloatingActionButton(
            onPressed: () async {
              Get.toNamed('/create_room');
            },
            child: const Icon(Icons.add),
          );
        } else {
          return const SizedBox.shrink();
        }
      }),
    );
  }
}
