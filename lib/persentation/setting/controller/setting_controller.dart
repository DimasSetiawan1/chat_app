import 'package:chat_apps/data/local/isar_service.dart';
import 'package:chat_apps/data/model/user_model.dart';
import 'package:chat_apps/sharing/utils/auth_utils.dart';
import 'package:chat_apps/sharing/utils/user_utils.dart';
import 'package:get/get.dart';

class SettingController extends GetxController {
  final AuthUtils _authUtils = AuthUtils();
  final IsarService _isarService = IsarService.instance;

  final UserUtils _userUtils = UserUtils();

  final isDarkMode = RxBool(Get.isDarkMode);
  final Rxn<UsersModel> user = Rxn<UsersModel>();

  Future<void> getUserData() async {
    await _userUtils.getUserData().then((userData) {
      if (userData != null) {
        user.value = userData;
      }
    });
  }

  // Logout & clear cached user
  void logout() {
    _authUtils.signOut();
    _isarService.clearAllCacheFromDevice();
    Get.offAllNamed('/');
  }

  // Toggle dark mode
  void toggleDarkMode(bool value) {
    isDarkMode.value = value;
  }
}
