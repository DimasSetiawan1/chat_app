import 'dart:math' as math;
import 'dart:developer';
import 'package:chat_apps/data/model/rooms_model.dart';
import 'package:chat_apps/data/remote/firestore/room_data_firestore.dart';
import 'package:chat_apps/domain/entities/members.dart';
import 'package:chat_apps/persentation/room/controller/room_controller.dart';
import 'package:chat_apps/persentation/room/widgets/list_user_reaction.dart';
import 'package:chat_apps/persentation/room/widgets/show_profile_user.dart';
import 'package:chat_apps/persentation/room/widgets/show_reaction_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
// core package (controller + model)

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});
  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final _chatController = Get.find<RoomController>();

  RoomsModel? room;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    log('RoomScreen init with args: ${args['room']}');
    if (args['room'] is Map<String, dynamic>) {
      try {
        room = RoomsModel.fromJson(args['room']);
      } catch (_) {
        // handle if args shape is different (e.g. {'room': roomModel})
        if (args['room'] != null && args['room'] is Map) {
          room = RoomsModel.fromJson(Map<String, dynamic>.from(args['room']));
        }
      }
    }

    final uid = _chatController.currentUserId;
    if (room == null || uid.isEmpty) {
      // Get.back();
      return;
    }
    _chatController.watchOnlineMembersCount(room!.id);
    _chatController.getUserById();
    _chatController.currentRoomId = room!.id;
    _chatController.startListeningToMessages(room!.id);
    _currentUserId = uid;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            RoomDataFirestore().decrementMembers(room!.id);
            Get.back();
          },
        ),
        titleSpacing: 0,
        leadingWidth: 40,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors
                  .primaries[math.Random().nextInt(Colors.primaries.length)],
              child: Text(
                room != null && room!.meta.topic.isNotEmpty
                    ? room!.meta.topic[0].toUpperCase()
                    : 'C',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room != null && room!.meta.topic.isNotEmpty
                      ? room!.meta.topic
                      : 'Chat Room',
                  style: const TextStyle(fontSize: 16),
                ),
                Obx(
                  () => Text(
                    '${_chatController.onlineCount.value} Online',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.greenAccent[400],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Chat(
          chatController: _chatController.messageController,
          currentUserId: _currentUserId!,
          onAttachmentTap: () {
            log('Attachment tap not implemented');
          },
          theme: Get.isDarkMode ? ChatTheme.dark() : ChatTheme.light(),
          builders: Builders(
            chatMessageBuilder:
                (
                  context,
                  message,
                  index,
                  animation,
                  child, {
                  bool? isRemoved,
                  required bool isSentByMe,
                  MessageGroupStatus? groupStatus,
                }) {
                  final data = room!.members.firstWhere(
                    (m) => m.uid == message.authorId,
                    orElse: () => Members(
                      uid: message.authorId,
                      name: 'Unknown',
                      role: '',
                    ),
                  );
                  final isSystemMessage = message.authorId == 'tutor';
                  final isFirstInGroup = groupStatus?.isFirst ?? true;
                  final isLastInGroup = groupStatus?.isLast ?? true;
                  final shouldShowAvatar =
                      !isSystemMessage && isLastInGroup && isRemoved != true;
                  final isCurrentUser = message.authorId == _currentUserId;
                  final shouldShowUsername =
                      !isSystemMessage && isFirstInGroup && isRemoved != true;

                  Widget? avatar;
                  if (shouldShowAvatar) {
                    avatar = Padding(
                      padding: EdgeInsets.only(
                        left: isCurrentUser ? 8 : 0,
                        right: isCurrentUser ? 0 : 8,
                      ),
                      child: Avatar(userId: data.uid),
                    );
                  } else if (!isSystemMessage) {
                    avatar = const SizedBox(width: 40);
                  }

                  return ChatMessage(
                    message: message,
                    index: index,
                    bottomWidget:
                        message.reactions == null ||
                            !message.reactions!.isNotEmpty
                        ? null
                        : ListUserReactions(room: room, messageId: message.id),
                    animation: animation,
                    isRemoved: isRemoved,
                    groupStatus: groupStatus,
                    topWidget: shouldShowUsername
                        ? Padding(
                            padding: EdgeInsets.only(
                              bottom: 4,
                              left: isCurrentUser ? 0 : 48,
                              right: isCurrentUser ? 48 : 0,
                            ),
                            child: Username(userId: message.authorId),
                          )
                        : null,
                    leadingWidget: !isCurrentUser
                        ? avatar
                        : isSystemMessage
                        ? null
                        : const SizedBox(width: 40),
                    trailingWidget: isCurrentUser
                        ? avatar
                        : isSystemMessage
                        ? null
                        : const SizedBox(width: 40),
                    receivedMessageScaleAnimationAlignment:
                        (message is SystemMessage)
                        ? Alignment.center
                        : Alignment.centerLeft,
                    receivedMessageAlignment: (message is SystemMessage)
                        ? AlignmentDirectional.center
                        : AlignmentDirectional.centerStart,
                    horizontalPadding: (message is SystemMessage) ? 0 : 8,
                    child: child,
                  );
                },
          ),
          onMessageSend: (String text) {
            log('Sending message: $text');
            _chatController.insertMessage(
              Message.text(
                id: const Uuid().v4(),
                authorId: _currentUserId!,
                createdAt: DateTime.now().toUtc(),
                text: text,
                reactions: {},
                sentAt: DateTime.now().toUtc(),
                seenAt: DateTime.now().toUtc(),
                deliveredAt: DateTime.now().toUtc(),
              ),
            );
          },
          onMessageTap:
              (context, message, {TapUpDetails? details, int index = 0}) {
                final overlay = Overlay.of(context);

                final tapPos =
                    details?.globalPosition ??
                    Offset(
                      MediaQuery.of(context).size.width / 2,
                      MediaQuery.of(context).size.height / 2,
                    );

                const emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
                late OverlayEntry entry;

                entry = OverlayEntry(
                  builder: (ctx) {
                    final size = MediaQuery.of(ctx).size;
                    const popupWidth = 280.0;
                    const popupHeight = 56.0;
                    const margin = 12.0;

                    double left = tapPos.dx - popupWidth / 2;
                    left = left.clamp(margin, size.width - popupWidth - margin);
                    double top = tapPos.dy - popupHeight - 16;
                    if (top < margin) {
                      top = tapPos.dy + 16;
                    }

                    return ShowReactionPopUp(
                      entry: entry,
                      left: left,
                      top: top,
                      popupWidth: popupWidth,
                      popupHeight: popupHeight,
                      emojis: emojis,
                      message: message,
                      roomId: room!.id,
                    );
                  },
                );

                overlay.insert(entry);
              },
          onMessageLongPress:
              (_, message, {LongPressStartDetails? details, int index = 0}) {
                final member = room?.members.firstWhere(
                  (m) => m.uid == message.authorId,
                  orElse: () =>
                      Members(uid: message.authorId, name: 'Unknown', role: ''),
                );

                Get.bottomSheet(
                  ShowProfileUser(
                    member: member!,
                    currentUserId: _currentUserId!,
                  ),
                  isScrollControlled: false,
                );
              },
          userCache: UserCache(),

          resolveUser: (UserID id) async {
            if (id == _currentUserId) {
              return User(
                id: id,
                name: _chatController.currentUser.value?.name,
                imageSource: _chatController.currentUser.value?.uid == id
                    ? _chatController.currentUser.value?.avatarUrl
                    : null,
                createdAt: DateTime.now().toUtc(),
              );
            }
            final member = room?.members.firstWhere(
              (m) => m.uid == id,
              orElse: () => Members(uid: id, name: 'Other', role: 'Member'),
            );
            return User(
              id: id,
              name: member?.name,
              metadata: {'role': member?.role ?? 'Member'},
              imageSource: _chatController.currentUser.value?.uid == id
                  ? _chatController.currentUser.value?.avatarUrl
                  : null,
              createdAt: DateTime.now().toUtc(),
            );
          },
        ),
      ),
    );
  }
}
