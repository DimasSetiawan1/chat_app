import 'dart:math';
import 'package:chat_apps/data/model/rooms_model.dart';
import 'package:chat_apps/domain/entities/members.dart';
import 'package:chat_apps/persentation/room/controller/room_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:get/get.dart';

class ListUserReactions extends StatelessWidget {
  ListUserReactions({super.key, required this.room, required this.messageId});
  final _chatController = Get.find<RoomController>();
  final RoomsModel? room;
  final String messageId;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RoomController>(
      builder: (controller) {
        final message = controller.messageController.messages.firstWhere(
          (msg) => msg.id == messageId,
          orElse: () => TextMessage(authorId: "", id: messageId, text: ''),
        );

        // Jika tidak ada reaksi, jangan tampilkan apa-apa
        if (message.reactions == null || message.reactions!.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Theme.of(context).cardColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (ctx) {
                  // GetBuilder di dalam bottom sheet
                  return GetBuilder<RoomController>(
                    builder: (c) {
                      final currentMessage = c.messageController.messages
                          .firstWhere(
                            (msg) => msg.id == messageId,
                            orElse: () => message, // fallback
                          );

                      if (currentMessage.reactions == null ||
                          currentMessage.reactions!.isEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.of(ctx).pop();
                        });
                        return const Center(child: CircularProgressIndicator());
                      }

                      final List<(String, String)> allReactions = [];
                      final sortedEmojis =
                          currentMessage.reactions!.keys.toList()..sort();

                      for (final emoji in sortedEmojis) {
                        final users = currentMessage.reactions![emoji]!;
                        final userIds = (users as List<dynamic>).map(
                          (e) => e.toString(),
                        );
                        for (final userId in userIds) {
                          allReactions.add((userId, emoji));
                        }
                      }

                      return Container(
                        padding: const EdgeInsets.all(16),
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                for (final emoji
                                    in currentMessage.reactions!.keys)
                                  Text(
                                    "$emoji ${currentMessage.reactions![emoji]!.length}  ",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.of(ctx).pop(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: ListView.separated(
                                itemCount: allReactions.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final e = allReactions[index];
                                  final member = room!.members.firstWhere(
                                    (m) => m.uid == e.$1,
                                    orElse: () => Members(
                                      uid: e.$1,
                                      name: 'Unknown',
                                      role: '',
                                    ),
                                  );
                                  return ListTile(
                                    onTap: () {
                                      
                                      _chatController.handleRemoveReaction(
                                        roomId: room!.id,
                                        message: currentMessage,
                                        emoji: allReactions[index].$2, // contoh
                                      );
                                    },
                                    leading: CircleAvatar(
                                      radius: 20,
                                      backgroundColor:
                                          Colors.primaries[Random().nextInt(
                                            Colors.primaries.length,
                                          )],
                                      child: Text(
                                        member.name.isNotEmpty
                                            ? member.name[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      member.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: const Text(
                                      "Click here to remove reaction",
                                    ),
                                    trailing: Text(
                                      e.$2,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
            // UI untuk Chip
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: message.reactions!.entries.map((e) {
                return Chip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  label: Text(e.key, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
