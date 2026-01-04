import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Api/auth_service.dart';
import '../../admin/home/admin_home.dart';
import '../../auth/google_auth_service.dart';
import '../../auth_gate.dart';
import 'Register.dart';
import 'package:get/get.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final userController = TextEditingController();
  final passController = TextEditingController();
  bool _isGoogleLoading = false;

  void _login() async {
    final email = userController.text.trim();
    final password = passController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đủ thông tin")),
      );
      return;
    }

    final result = await AuthService.login(email, password);

    if (result != null) {
      // ⭐ THAY THẾ TỪ ĐÂY:
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true); // Lưu trạng thái đăng nhập
      await prefs.setString('jwt_token', result.token);
      // Điều hướng dứt khoát về AuthGate để nó dẫn vào HomePage
      if (result.role == 'Admin') {
        // Nếu là Admin thì tùy bạn điều hướng, nhưng vẫn nên lưu isLoggedIn
        Get.offAll(() => const AdminHomeScreen());
      } else {
        Get.offAll(() => const AuthGate());
      }
    }
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sai email hoặc mật khẩu")),
      );
    }
  }

  void _goRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(

      body: Stack(
        children: [
          // Background gradient
          Container(
            height: size.height,
            width: size.width,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 15,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                shadowColor: Colors.black45,
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Đăng nhập",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Tài khoản
                      TextField(
                        controller: userController,
                        decoration: const InputDecoration(
                          labelText: "Tài khoản",
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Mật khẩu
                      TextField(
                        controller: passController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Mật khẩu",
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Nút đăng nhập
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pinkAccent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            elevation: 5,
                          ),
                          child: const Text(
                            "Đăng nhập",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Nút đăng ký
                      TextButton(
                        onPressed: _goRegister,
                        child: const Text(
                          "Chưa có tài khoản? Đăng ký",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ),


                      ElevatedButton.icon(

                        icon: const Icon(Icons.login),
                        label: const Text("Đăng nhập bằng Google"),
                        onPressed: _isGoogleLoading
                            ? null
                            : () async {
                          setState(() => _isGoogleLoading = true);
                          try
                          {
                            final userCredential =
                            await GoogleAuthService.signInWithGoogle();

                            final user = userCredential.user;

                            if (user != null) {
                              await AuthService.googleLogin(
                                email: user.email!,
                                fullName: user.displayName ?? "",
                                firebaseUid: user.uid,
                                avatarUrl: user.photoURL,
                              );
                              print("✅ Google login Firebase + Backend login SQL");
                              print("Email: ${user.email}");


                              // 2. Lưu trạng thái vào bộ nhớ máy để không bị văng khi F5
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('isLoggedIn', true);

                              // 4. Chuyển trang về AuthGate
                              Get.offAll(() => const AuthGate());
                            }
                          } catch (e) {
                            print("❌ Google login lỗi: $e");
                          }
                          finally {
                            setState(() => _isGoogleLoading = false);
                          }
                        },
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
