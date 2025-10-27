import 'package:chat_apps/data/local/isar_service.dart';
import 'package:chat_apps/firebase_options.dart';
import 'package:chat_apps/sharing/component/mychat.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await IsarService.instance.init();
  await SharedPreferences.getInstance();
  final IsarService isarService = IsarService.instance;
  final isLoggedInUser = await isarService.getCachedUser();
  final initialRoute = isLoggedInUser != null ? '/home' : '/';
  runApp(MyChat(initialRoute: initialRoute));
}
