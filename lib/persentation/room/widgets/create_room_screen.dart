import 'package:chat_apps/data/model/user_model.dart';
import 'package:chat_apps/persentation/room/controller/create_room_controller.dart';
import 'package:chat_apps/sharing/component/widgets/custom_autocomplete.dart';
import 'package:chat_apps/sharing/component/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateRoomScreen extends StatelessWidget {
  const CreateRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CreateRoomController>();
    if (controller.currentUserEmail.isEmpty) {
      Get.offAllNamed('/login');
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Create Room')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Room Name
                CustomTextField(
                  controller: controller.roomName,
                  labelText: 'Room Name',
                  keyboardType: TextInputType.text,
                  prefixIcon: const Icon(Icons.chat),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: const ValueKey('room-type-dropdown'),
                  initialValue: controller.roomType.value,
                  decoration: InputDecoration(
                    labelText: 'Room Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'group', child: Text('Group')),
                    DropdownMenuItem(value: 'trio', child: Text('Trio')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      controller.roomType.value = v;
                      controller.clearGroupUsers();
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (controller.roomType.value == 'trio') ...[
                  CustomAutocomplete<UsersModel>(
                    displayStringForOption: (user) => user.email,
                    labelText: 'Student Email',
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return Future.value([]);
                      } else {
                        return controller.searchUsers(
                          textEditingValue.text,
                          'student',
                        );
                      }
                    },
                    onSelected: (users) {
                      controller.selectedStudent.value = users;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Parent
                  CustomAutocomplete<UsersModel>(
                    displayStringForOption: (user) => user.email,
                    labelText: 'Parent Email',
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return Future.value([]);
                      } else {
                        return controller.searchUsers(
                          textEditingValue.text,
                          'parent',
                        );
                      }
                    },
                    onSelected: (users) {
                      controller.selectedParent.value = users;
                    },
                  ),
                ] else ...[
                  // Group autocomplete add
                  CustomAutocomplete<UsersModel>(
                    labelText: 'Add User by Email',
                    onSelected: (user) {
                      controller.addUserToGroup(user);
                    },
                    // 5. Perbaiki displayStringForOption agar menampilkan email
                    displayStringForOption: (user) => user.email,
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return Future.value([]);
                      } else {
                        return controller.searchUsers(
                          textEditingValue.text,
                          'any',
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Obx(() {
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Text(
                            'Selected Users:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            key: const ValueKey('group-users-wrap'),
                            spacing: 8,
                            runSpacing: 6,
                            children: controller.groupUsers.map((user) {
                              final localPart = user.email.contains('@')
                                  ? user.email.split('@')[0]
                                  : user.email;
                              final display = localPart.split('.').first;
                              return ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 120,
                                ),
                                child: Chip(
                                  key: ValueKey('group-user-${user.email}'),
                                  label: Text(
                                    display,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  labelPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                  onDeleted: () =>
                                      controller.removeUserFromGroup(user),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: controller.isLoading.value
                          ? null
                          : () => controller.createRoom(),
                      child: controller.isLoading.value
                          ? const CircularProgressIndicator()
                          : const Text('Create Room'),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
