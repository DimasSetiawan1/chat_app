import 'dart:developer';

import 'package:chat_apps/data/model/user_model.dart';
import 'package:chat_apps/sharing/utils/auth_utils.dart';
import 'package:get/get.dart';

class SignupController extends GetxController {
  final AuthUtils _authUtils = AuthUtils();
  final role = ''.obs;

  final RxBool isLoading = false.obs;

  String? get selectedRole => role.value.isEmpty ? null : role.value;

  Future<void> signUpWithEmailAndPassword(
    String fullName,
    String email,
    String password,
  ) async {
    try {
      log(
        'Starting sign up process for email: $email, fullName: $fullName, role: ${role.value}, ',
      );
      isLoading.value = true;

      final user = UsersModel(
        uid: '',
        email: email,
        name: fullName,
        avatarUrl: '',
        lastSeenAt: DateTime.now().toIso8601String(),
        role: role.value,
        createdAt: DateTime.now().toIso8601String(),
      );
      log('Attempting to sign up user: ${user.toJson()}');
      await _authUtils.signUpWithEmailAndPassword(user, password);
      isLoading.value = false;
      Get.snackbar('Success', 'Welcome $fullName!');
      Get.offAllNamed('/home');
    } catch (err) {
      isLoading.value = false;
      Get.snackbar('Error', err.toString());
    }
  }
}
