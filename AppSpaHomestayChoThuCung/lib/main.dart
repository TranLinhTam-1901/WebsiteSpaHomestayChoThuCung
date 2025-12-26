import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'Controller/settings_controller.dart';
import 'Controller/user_controller.dart';
import 'auth_gate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  // await Auth.load(); // login (nếu có)
  Get.put(SettingsController()); // ⭐ inject controller
  Get.put(UserController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "PawHouse",
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: settings.isDark.value ? ThemeMode.dark : ThemeMode.light,

      // 1. Chỉ định trang chủ rõ ràng
      home: const AuthGate(),

      // 2. Đăng ký Route name để tránh lỗi "Could not navigate to initial route" khi F5
      getPages: [
        GetPage(name: '/', page: () => const AuthGate()),
        GetPage(name: '/AuthGate', page: () => const AuthGate()),
      ],
    );
  }
}
