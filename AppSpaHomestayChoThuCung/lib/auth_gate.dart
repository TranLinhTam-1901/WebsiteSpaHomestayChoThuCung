import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Api/auth_service.dart';
import 'pages/home/home.dart';
import 'pages/home/login.dart';
import 'package:baitap1/controller/user_controller.dart';
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: SharedPreferences.getInstance().then((p) async {
        bool loggedIn = p.getBool('isLoggedIn') ?? false;
        if (loggedIn) {
          // Đợi một chút để Firebase kịp khôi phục session (chỉ dành cho Google Login)
          if (AuthService.jwtToken == null) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
          // Nạp lại JWT từ máy (nếu có)
          await Get.find<UserController>().restoreSession();

          // Gọi hàm loadProfile mới đã sửa ở trên
          await Get.find<UserController>().loadProfile();
        }
        
        return loggedIn;
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.data == true) {
          return HomePage(model: HomeViewModel.demo());
        }
        return const LoginPage();
      },
    );
  }
}