import 'dart:developer';

import 'package:chat_apps/data/local/isar_service.dart';
import 'package:chat_apps/data/model/isar_users_model.dart';
import 'package:chat_apps/data/remote/firestore/users_data_firestore.dart';
import 'package:chat_apps/sharing/utils/auth_utils.dart';
import 'package:get/get.dart';

class SignInController extends GetxController {
  AuthUtils authUtils = AuthUtils();
  final IsarService _isarService = IsarService.instance;
  final UsersDataFirestore _usersDataFirestore = UsersDataFirestore();

  RxBool isLoading = false.obs;
  // Sign In with email and password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    isLoading.value = true;
    try {
      final user = await authUtils.signInWithEmailAndPassword(email, password);
      final getUserData = await _usersDataFirestore.getUserByUid(
        user.user!.uid,
      );

      log('Fetched user data: ${user.user?.uid ?? "No UID"}');

      _isarService.cacheUser(
        IsarUser()
          ..role = getUserData?.role ?? ''
          ..lastSeenAt = getUserData?.lastSeenAt ?? ''
          ..avatarUrl = getUserData?.avatarUrl ?? ''
          ..email = getUserData?.email ?? ''
          ..name = getUserData?.name ?? ''
          ..uid = user.user?.uid ?? '',
      );
      Get.snackbar(
        'Success',
        'Welcome ${user.user?.displayName ?? user.user?.email}',
      );
      isLoading.value = false;
      Get.offAllNamed('/home');
    } catch (err) {
      Get.snackbar('Error', err.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Sign In with Anonymous
  Future<void> signInAnonymously() async {
    try {
      final user = await authUtils.signInAnonymously();
      isLoading.value = true;
      Get.snackbar('Success', 'Welcome ${user?.name ?? "Guest"}');
      Get.offAllNamed('/home');
    } catch (err) {
      Get.snackbar('Error', err.toString());
    }
  }

  // sign out
  Future<void> signOut() async {
    await authUtils.signOut();
    Get.offAllNamed('/');
  }
}
