import 'dart:io'; // 🔥 BẮT BUỘC để dùng HttpOverrides
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'Controller/settings_controller.dart';
import 'Controller/user_controller.dart';
import 'auth_gate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// --- BƯỚC 1: THÊM CLASS NÀY ĐỂ BỎ QUA KIỂM TRA SSL ---
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
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
      themeMode: settings.isDark.value
          ? ThemeMode.dark
          : ThemeMode.light,
      home: const AuthGate(),
    );
  }
}

void main() async {
  // --- BƯỚC 2: CẤU HÌNH HTTP OVERRIDES TRƯỚC KHI CHẠY APP ---
  HttpOverrides.global = MyHttpOverrides();

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

  Get.put(SettingsController());
  Get.put(UserController());

  runApp(const MyApp());
}