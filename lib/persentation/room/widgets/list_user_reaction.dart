import 'dart:math';

import 'package:chat_apps/data/model/rooms_model.dart';
import 'package:chat_apps/domain/entities/members.dart';
import 'package:chat_apps/persentation/room/controller/room_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:get/get.dart';

class ListUserReactions extends StatelessWidget {
  const ListUserReactions({
    super.key,
    required this.room,
    required this.messageId,
    required this.message,
  });
  final RoomsModel? room;
  final String messageId;
  final Message message;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RoomController>(
      builder: (controller) {
        if (message.reactions == null || message.reactions!.isEmpty) {
          return const SizedBox.shrink();
        }

        return GetBuilder<RoomController>(
          builder: (controller) {
            final currentMessage = message;

            if (currentMessage.reactions == null ||
                currentMessage.reactions!.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              });
              return Container(
                padding: const EdgeInsets.all(24),
                height: 200,
                child: Center(
                  child: Text(
                    'No reactions',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
            }

            final sortedEmojis = currentMessage.reactions!.keys.toList();

            return Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: InkWell(
                onTap: () {
                  Get.bottomSheet(
                    Container(
                      padding: const EdgeInsets.all(16),
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              for (final emoji in sortedEmojis)
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
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.builder(
                              itemCount: sortedEmojis.length,
                              itemBuilder: (_, index) {
                                final emoji = sortedEmojis[index];
                                final userIds =
                                    currentMessage.reactions![emoji]!;
                                final reactingMembers = userIds
                                    .map(
                                      (uid) => room!.members.firstWhere(
                                        (m) => m.uid == uid,
                                        orElse: () => Members(
                                          uid: uid,
                                          name: 'Unknown User',
                                          role: '?',
                                        ),
                                      ),
                                    )
                                    .toList();

                                final names = reactingMembers
                                    .map((m) => m.name)
                                    .join(', ');

                                final member = reactingMembers.isNotEmpty
                                    ? reactingMembers.first
                                    : null;

                                if (member == null) {
                                  return const SizedBox.shrink();
                                }

                                return ListTile(
                                  // Key harus unik per emoji
                                  key: ValueKey('reaction-type-$emoji'),
                                  onTap: () async {
                                    // await controller.handleRemoveReaction(
                                    //   roomId: room!.id,
                                    //   message: currentMessage,
                                    //   emoji: emoji,
                                    // );
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
                                    // Tampilkan SEMUA nama pengguna yang bereaksi
                                    names,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text('Reacted with $emoji'),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    backgroundColor: Colors.black87,
                  );
                },
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
                      label: Text(
                        '${e.key} ${e.value.length}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
