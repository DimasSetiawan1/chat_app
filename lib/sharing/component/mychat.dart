import 'package:chat_apps/data/local/shared_preference_service.dart';
import 'package:chat_apps/sharing/component/routes/routes.dart';
import 'package:chat_apps/sharing/themes/themes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyChat extends StatelessWidget {
  const MyChat({super.key, required this.initialRoute});
  final String initialRoute;
  @override
  Widget build(BuildContext context) {
    ThemeMode isDarkMode = ThemeMode.system;
    SharedPreferenceService.getThemeMode().then((value) {
      isDarkMode = value;
    });
    return GetMaterialApp(
      initialRoute: initialRoute,
      getPages: AppRoutes.pages,
      darkTheme: AppTheme.darkTheme,
      theme: AppTheme.lightTheme,
      themeMode: isDarkMode,
      debugShowCheckedModeBanner: false,
    );
  }
}
