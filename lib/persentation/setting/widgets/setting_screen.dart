import 'dart:developer';
import 'dart:math' as math;

import 'package:chat_apps/data/local/shared_preference_service.dart';
import 'package:chat_apps/persentation/setting/controller/setting_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final _settingController = Get.find<SettingController>();

  @override
  void initState() {
    super.initState();
    _settingController.getUserData();
  }

  @override
  Widget build(BuildContext context) {
    log('${_settingController.user.value}');
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Obx(
                () => CircleAvatar(
                  radius: 28,
                  backgroundImage:
                      _settingController.user.value?.avatarUrl.isNotEmpty ==
                          true
                      ? NetworkImage(_settingController.user.value!.avatarUrl)
                      : null,
                  child:
                      _settingController.user.value?.avatarUrl.isNotEmpty ==
                          true
                      ? null
                      : Icon(Icons.person, size: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _settingController.user.value?.name ??
                            "Guest ${math.Random().nextInt(1000)}",
                        style: TextStyle(
                          fontSize: 16,
                          // fontWeight: FontWeight.w600,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _settingController.user.value?.email ??
                            "guest@gmail.com",
                        style: TextStyle(
                          color: Colors.grey,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                }),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  await Get.toNamed('/profile');

                  _settingController.getUserData();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Appearance',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          Obx(
            () => SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.dark_mode),
              title: const Text('Dark Mode'),
              subtitle: const Text('Toggle dark mode'),
              value: _settingController.isDarkMode.value,
              onChanged: (v) {
                _settingController.toggleDarkMode(v);
                SharedPreferenceService.setThemeMode(v);
                Get.changeThemeMode(v ? ThemeMode.dark : ThemeMode.light);
              },
            ),
          ),

          const SizedBox(height: 8),
          const Text('About', style: TextStyle(fontWeight: FontWeight.w600)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline),
            title: const Text('About Chat Apps'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Chat Apps',
              applicationVersion: '1.0.0',
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Exit', style: TextStyle(color: Colors.red)),
            onTap: () {
              Get.defaultDialog(
                title: 'Logout',
                middleText: 'Are you sure you want to logout?',
                textCancel: 'Cancel',
                textConfirm: 'Logout',
                // confirmTextColor: Colors.white,
                onConfirm: () {
                  _settingController.logout();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
