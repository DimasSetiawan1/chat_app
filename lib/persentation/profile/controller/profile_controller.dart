import 'dart:developer';
import 'dart:io';

import 'package:chat_apps/data/model/user_model.dart';
import 'package:chat_apps/data/remote/firebase_storage/firebase_storage_service.dart';
import 'package:chat_apps/sharing/utils/user_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ProfileController extends GetxController {
  final TextEditingController nameController = TextEditingController(text: '');
  final TextEditingController emailController = TextEditingController(text: '');
  Rx<UsersModel?> user = Rxn<UsersModel>();
  final FirebaseStorageService _firebaseStorageService =
      FirebaseStorageService();
  final ImagePicker _picker = ImagePicker();
  final RxBool isLoading = false.obs;
  final UserUtils _userUtils = UserUtils();

  @override
  void onInit() {
    _userUtils.getUserData().then((userData) {
      if (userData != null) {
        user.value = userData;
        nameController.text = userData.name;
        emailController.text = userData.email;
        update();
      }
    });
    super.onInit();
  }

  /// Updates the user profile with new data.
  Future<void> updateUserProfile(UsersModel updatedUser) async {
    try {
      await _userUtils.updateUserProfile(updatedUser);
      user.value = updatedUser;
      isLoading.value = false;
      Get.snackbar(
        'Success',
        'Profile updated successfully.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      log('Error updating user profile: $e');
    }
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (image != null) {
        _firebaseStorageService.uploadImage(File(image.path), image.name).then((
          downloadUrl,
        ) {
          if (downloadUrl != null) {
            user.value = user.value?.copyWith(avatarUrl: downloadUrl);
            update();
          } else {
            log('Failed to upload image.');
          }
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
