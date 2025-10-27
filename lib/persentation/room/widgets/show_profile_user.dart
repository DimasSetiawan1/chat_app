import 'dart:math';

import 'package:chat_apps/domain/entities/members.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShowProfileUser extends StatelessWidget {
  const ShowProfileUser({
    super.key,
    required this.member,
    required String currentUserId,
  }) : _currentUserId = currentUserId;

  final Members member;
  final String _currentUserId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors
                    .primaries[Random().nextInt(Colors.primaries.length)],
                child: Text(
                  (member.name[0]).toUpperCase(),
                  // style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Chip(
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          label: Text(
                            member.role.isNotEmpty ? member.role : 'No role',
                            style: const TextStyle(
                              fontSize: 14,
                              // color: Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.blueGrey,
                        ),
                        if (member.uid == _currentUserId)
                          Chip(
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            label: const Text(
                              'You',
                              style: TextStyle(
                                fontSize: 12,
                                // color: Colors.white,
                              ),
                            ),
                            backgroundColor: Colors.green,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
