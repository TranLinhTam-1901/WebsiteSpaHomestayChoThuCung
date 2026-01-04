import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class CategoryApi {
  static const String baseUrl = "https://localhost:7051"; // URL của API

  // ======================
  // GET ALL CATEGORIES
  // ======================
  static Future<List<Map<String, dynamic>>> getCategories() async {
    final token = AuthService.jwtToken;
    if (token == null) {
      throw Exception("Chưa đăng nhập");
    }

    final res = await http.get(
      Uri.parse("$baseUrl/api/admin/categories"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Không thể lấy danh sách danh mục");
    }

    // CHỈ CẦN THẾ NÀY: Trả về toàn bộ để Controller tự xử lý lọc
    List<dynamic> data = jsonDecode(res.body);
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  // ======================
  // ADD CATEGORY
  // ======================
  static Future<void> addCategory({
    required String name,
    required bool isDeleted,
  }) async {
    final token = AuthService.jwtToken;
    if (token == null) {
      throw Exception("Chưa đăng nhập");
    }

    final res = await http.post(
      Uri.parse("$baseUrl/api/admin/categories"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "name": name,
        "isDeleted": isDeleted,
      }),
    );

    if (res.statusCode != 201) {
      throw Exception("Thêm danh mục thất bại: ${res.body}");
    }
  }

  // ======================
  // UPDATE CATEGORY
  // ======================
  static Future<void> updateCategory({
    required int id,
    required String name,
    required bool isDeleted,
  }) async {
    final token = AuthService.jwtToken;
    if (token == null) {
      throw Exception("Chưa đăng nhập");
    }

    final res = await http.put(
      Uri.parse("$baseUrl/api/admin/categories/$id"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "id": id,
        "name": name,
        "isDeleted": isDeleted,
      }),
    );

    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception("Cập nhật danh mục thất bại: ${res.body}");
    }
  }

  // ======================
  // HIDE CATEGORY
  // ======================
  static Future<void> hideCategory(int id) async {
    final token = AuthService.jwtToken;
    if (token == null) {
      throw Exception("Chưa đăng nhập");
    }

    final res = await http.patch(
      Uri.parse("$baseUrl/api/admin/categories/$id/hide"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if ( res.statusCode != 204 && res.statusCode != 200) {
      throw Exception("Ẩn danh mục thất bại: ${res.body}");
    }
  }

  static Future<void> showCategory(int id) async {
    final token = AuthService.jwtToken;
    final res = await http.patch(
      Uri.parse("$baseUrl/api/admin/categories/$id/show"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception("Hiện danh mục thất bại");
    }
  }
  // ======================
  // DELETE CATEGORY
  // ======================
  static Future<void> deleteCategory(int id) async {
    final token = AuthService.jwtToken;
    if (token == null) {
      throw Exception("Chưa đăng nhập");
    }

    final res = await http.delete(
      Uri.parse("$baseUrl/api/admin/categories/$id"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode != 204) {
      throw Exception("Xóa danh mục thất bại: ${res.body}");
    }
  }
}
