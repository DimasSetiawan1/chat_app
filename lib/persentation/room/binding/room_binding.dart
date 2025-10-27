import 'package:chat_apps/persentation/room/controller/room_controller.dart';
import 'package:get/get.dart';

class RoomBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RoomController());
  }
}
