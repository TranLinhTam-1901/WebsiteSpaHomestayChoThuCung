import 'package:flutter/material.dart';
import '../Api/auth_service.dart';
import 'home_page.dart';
import 'setting.dart';
import 'login.dart';

class RegisterPage  extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage > createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final pass2Ctrl = TextEditingController();

  String? errorText;

  void _register() async {
    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();
    final pass2 = pass2Ctrl.text.trim();

    if (name.isEmpty || email.isEmpty || pass.isEmpty || pass2.isEmpty) {
      setState(() => errorText = "Vui lòng điền đầy đủ thông tin");
      return;
    }

    if (pass != pass2) {
      setState(() => errorText = "Mật khẩu không khớp");
      return;
    }

    final ok = await AuthService.register({
      "fullName": name,
      "email": email,
      "password": pass,
      "confirmPassword": pass2,
      "address": "Chưa cập nhật",
      "phoneNumber": "0000000000"
    });

    if (ok) {
      Navigator.pop(context); // quay lại Login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đăng ký thành công, vui lòng đăng nhập")),
      );
    } else {
      setState(() => errorText = "Đăng ký thất bại (email có thể đã tồn tại)");
    }
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(

      body: Stack(
        children: [
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
                        "Đăng Ký",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: "Tên của bạn",
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),

                      TextField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),

                      TextField(
                        controller: passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Mật khẩu",
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),

                      TextField(
                        controller: pass2Ctrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Nhập lại mật khẩu",
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      if (errorText != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          errorText!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pinkAccent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            elevation: 5,
                          ),
                          child: const Text(
                            "Tạo Tài Khoản",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold,
                            color : Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                          );
                        },
                        child: const Text(
                          "Đã có tài khoản? Đăng nhập",
                          style: TextStyle(fontSize: 16, color: Colors.black54),

                        ),
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
