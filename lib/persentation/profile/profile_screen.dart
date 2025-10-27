
import 'package:chat_apps/persentation/profile/controller/profile_controller.dart';
import 'package:chat_apps/sharing/component/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          const SizedBox(height: 20),
          Center(
            child: Stack(
              children: [
                Obx(
                  () => CircleAvatar(
                    radius: 60,
                    backgroundImage:
                        controller.user.value?.avatarUrl.isNotEmpty == true
                        ? NetworkImage(controller.user.value!.avatarUrl)
                        : null,
                    child: controller.user.value?.avatarUrl.isEmpty == true
                        ? const Icon(Icons.person, size: 60)
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () {
                        controller.pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          CustomTextField(
            controller: controller.nameController,
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person),
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: controller.emailController,
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.email),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              controller.isLoading.value = true;
              controller.user.value = controller.user.value?.copyWith(
                name: controller.nameController.text,
                email: controller.emailController.text,
              );
              controller.updateUserProfile(controller.user.value!);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Obx(
              () => controller.isLoading.value
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Text('Save Changes', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
