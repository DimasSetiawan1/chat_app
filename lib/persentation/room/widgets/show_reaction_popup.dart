import 'dart:developer';

import 'package:chat_apps/persentation/room/controller/room_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:get/get.dart';

class ShowReactionPopUp extends StatelessWidget {
  const ShowReactionPopUp({
    super.key,
    required this.entry,
    required this.left,
    required this.top,
    required this.popupWidth,
    required this.popupHeight,
    required this.emojis,
    required this.message,
    required this.roomId,
  });

  final OverlayEntry entry;
  final double left;
  final double top;
  final double popupWidth;
  final double popupHeight;
  final List<String> emojis;
  final Message message;
  final String roomId;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RoomController>();
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => entry.remove(),
          ),
        ),
        Positioned(
          left: left,
          top: top,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: popupWidth,
              height: popupHeight,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                // color: Colors.grey[900],
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(blurRadius: 12, offset: const Offset(0, 6)),
                ],
                border: Border.all(color: Colors.white10, width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: emojis.map((e) {
                  return GestureDetector(
                    onTap: () {
                      controller.handleAddReaction(
                        message: message,
                        emoji: e,
                        roomId: roomId,
                      );

                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Reacted $e',
                            style: const TextStyle(color: Colors.white),
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.black87.withValues(
                            alpha: 0.9,
                          ),
                          duration: const Duration(milliseconds: 900),
                        ),
                      );
                      entry.remove();
                    },
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 100),
                      scale: 1.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
