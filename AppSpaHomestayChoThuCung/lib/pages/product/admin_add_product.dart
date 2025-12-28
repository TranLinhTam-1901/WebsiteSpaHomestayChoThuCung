import 'package:flutter/material.dart';
import '../login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminAddProductPage extends StatelessWidget {
  const AdminAddProductPage({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("role");

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin • Thêm sản phẩm"),
        backgroundColor: Colors.redAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Đăng xuất",
            onPressed: () => _logout(context),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                const Text(
                  "Thông tin sản phẩm",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // Tên sản phẩm
                TextField(
                  decoration: const InputDecoration(
                    labelText: "Tên sản phẩm",
                    prefixIcon: Icon(Icons.shopping_bag),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 15),

                // Giá
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Giá (VNĐ)",
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 15),

                // Danh mục
                DropdownButtonFormField<String>(
                  items: const [
                    DropdownMenuItem(value: "dog", child: Text("Chó")),
                    DropdownMenuItem(value: "cat", child: Text("Mèo")),
                  ],
                  onChanged: null,
                  decoration: const InputDecoration(
                    labelText: "Danh mục",
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 15),

                // Hình ảnh
                TextField(
                  decoration: const InputDecoration(
                    labelText: "URL hình ảnh",
                    prefixIcon: Icon(Icons.image),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 15),

                // Mô tả
                TextField(
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: "Mô tả sản phẩm",
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 25),

                // Button lưu (chưa xử lý)
                ElevatedButton.icon(
                  onPressed: null, // ❌ CHƯA XỬ LÝ
                  icon: const Icon(Icons.save),
                  label: const Text("Lưu sản phẩm"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
