import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class CartApi {
  static const String baseUrl = "https://localhost:7051";

  /// ======================
  /// GET CART
  /// ======================
  static Future<Map<String, dynamic>> getCart() async {
    final token = AuthService.jwtToken;
    if (token == null) {
      throw Exception("Chưa đăng nhập");
    }

    final res = await http.get(
      Uri.parse("$baseUrl/api/cart"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Không lấy được giỏ hàng");
    }

    return jsonDecode(res.body);
  }


  static Future<void> addToCart({
    required int productId,
    required int quantity,
    int? variantId,
  }) async {
    final token = AuthService.jwtToken;
    if (token == null) {
      throw Exception("Chưa đăng nhập");
    }

    final res = await http.post(
      Uri.parse("$baseUrl/api/cart/add"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "productId": productId,
        "quantity": quantity,
        "variantId": variantId,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("Thêm vào giỏ hàng thất bại: ${res.body}");
    }
  }
  /// ======================
  /// UPDATE CART
  /// ======================
  static Future<void> updateCart({
    required int cartItemId,
    required int quantity,
  }) async {
    final token = AuthService.jwtToken;
    if (token == null) {
      throw Exception("Chưa đăng nhập");
    }

    final res = await http.put(
      Uri.parse("$baseUrl/api/cart/update"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "cartItemId": cartItemId,
        "quantity": quantity,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("Cập nhật giỏ hàng thất bại: ${res.body}");
    }
  }

  /// ======================
  /// REMOVE CART ITEM
  /// ======================
  static Future<void> removeCartItem(int cartItemId) async {
    final token = AuthService.jwtToken;
    if (token == null) {
      throw Exception("Chưa đăng nhập");
    }

    final res = await http.delete(
      Uri.parse("$baseUrl/api/cart/remove/$cartItemId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Xóa sản phẩm thất bại: ${res.body}");
    }
  }


  static Future<Map<String, dynamic>> buyNow({
    required int productId,
    required int quantity,
    int? variantId,
  }) async {
    final token = AuthService.jwtToken;
    if (token == null) throw Exception("Chưa đăng nhập");

    final res = await http.post(
      Uri.parse("$baseUrl/api/cart/buynow"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "productId": productId,
        "quantity": quantity,
        "variantId": variantId,
      }),
    );

    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      throw Exception(data["message"] ?? "BuyNow thất bại");
    }

    return jsonDecode(res.body);
  }

}
