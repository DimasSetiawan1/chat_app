import 'package:chat_apps/persentation/profile/binding/profile_binding.dart';
import 'package:chat_apps/persentation/room/binding/create_room_binding.dart';
import 'package:chat_apps/persentation/room/binding/room_binding.dart';
import 'package:chat_apps/persentation/room/widgets/create_room_screen.dart';
import 'package:chat_apps/persentation/room/widgets/room_screen.dart';
import 'package:chat_apps/persentation/home/binding/home_binding.dart';
import 'package:chat_apps/persentation/home/widgets/home_screen.dart';
import 'package:chat_apps/persentation/signin/binding/signin_binding.dart';
import 'package:chat_apps/persentation/signin/widgets/signin_screen.dart';
import 'package:chat_apps/persentation/profile/profile_screen.dart';
import 'package:chat_apps/persentation/setting/binding/setting_binding.dart';
import 'package:chat_apps/persentation/setting/widgets/setting_screen.dart';
import 'package:chat_apps/persentation/signup/binding/signup_binding.dart';
import 'package:chat_apps/persentation/signup/widgets/signup_screen.dart';
import 'package:chat_apps/sharing/component/routes/routes_name.dart';
import 'package:get/get.dart';

class AppRoutes {
  const AppRoutes._();
  static List<GetPage<dynamic>> get pages => [
    GetPage(
      name: RoutesName.initial,
      page: () => SigninScreen(),
      binding: SigninBinding(),
    ),
    GetPage(
      name: RoutesName.signin,
      page: () => SigninScreen(),
      binding: SigninBinding(),
    ),
    GetPage(
      name: RoutesName.signup,
      page: () => SignupScreen(),
      binding: SignupBinding(),
    ),
    GetPage(
      name: RoutesName.home,
      page: () => HomeScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: RoutesName.settings,
      page: () => SettingScreen(),
      binding: SettingBinding(),
    ),

    GetPage(
      name: RoutesName.room,
      page: () => RoomScreen(),
      binding: RoomBinding(),
    ),
    GetPage(
      name: RoutesName.createRoom,
      page: () => CreateRoomScreen(),
      binding: CreateRoomBinding(),
    ),

    // GetPage(
    //   name: RoutesName.room,
    //   page: () => MessageScreen(),
    //   binding: MessageBinding(),
    // ),
    GetPage(
      name: RoutesName.profile,
      page: () => ProfileScreen(),
      binding: ProfileBinding(),
    ),
  ];
}
