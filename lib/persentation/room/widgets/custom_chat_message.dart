import 'package:chat_apps/data/model/rooms_model.dart';
import 'package:chat_apps/domain/entities/members.dart';
import 'package:chat_apps/persentation/room/widgets/list_user_reaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

class CustomChatMessage extends StatelessWidget {
  const CustomChatMessage({
    super.key,
    required this.room,
    required this.message,
    required this.data,
    required this.index,
    required this.animation,
    required this.child,
    this.isRemoved,
    required this.isSentByMe,
    this.groupStatus,
    required this.isCurrentUser,
  });

  final RoomsModel? room;
  final Message message;
  final int index;
  final Animation<double> animation;
  final Widget child;
  final Members data;
  final bool? isRemoved;
  final bool isSentByMe;
  final MessageGroupStatus? groupStatus;
  final bool isCurrentUser;
 
  @override
  Widget build(BuildContext context) {
    final isSystemMessage = message.authorId == 'tutor';
  final isFirstInGroup = groupStatus?.isFirst ?? true;
  final isLastInGroup = groupStatus?.isLast ?? true;
  final shouldShowAvatar =
      !isSystemMessage && isLastInGroup && isRemoved != true;
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
      bottomWidget: message.reactions == null || !message.reactions!.isNotEmpty
          ? null
          : ListUserReactions(room: room, messageId: message.id, message: message),
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
      receivedMessageScaleAnimationAlignment: (message is SystemMessage)
          ? Alignment.center
          : Alignment.centerLeft,
      receivedMessageAlignment: (message is SystemMessage)
          ? AlignmentDirectional.center
          : AlignmentDirectional.centerStart,
      horizontalPadding: (message is SystemMessage) ? 0 : 8,
      child: child,
    );
  }
}