import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/promotion_model.dart';
import 'auth_service.dart';

class PromotionApi {
  static const String baseUrl = "https://localhost:7051";

  /// ======================
  /// GET /api/promotions
  /// Danh sách khuyến mãi
  /// ======================
  static Future<List<PromotionModel>> getPromotions() async {
    final token = AuthService.jwtToken;
    if (token == null) {
      throw Exception("Chưa đăng nhập");
    }

    final res = await http.get(
      Uri.parse("$baseUrl/api/promotions"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Không lấy được danh sách khuyến mãi");
    }

    final List data = jsonDecode(res.body);
    return data.map((e) => PromotionModel.fromJson(e)).toList();
  }

  /// ======================
  /// GET /api/promotions/{id}
  /// Chi tiết khuyến mãi
  /// ======================
  static Future<PromotionModel> getPromotionDetail(int id) async {
    final token = AuthService.jwtToken;
    if (token == null) {
      throw Exception("Chưa đăng nhập");
    }

    final res = await http.get(
      Uri.parse("$baseUrl/api/promotions/$id"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      throw Exception(data["message"] ?? "Không lấy được chi tiết khuyến mãi");
    }

    return PromotionModel.fromJson(jsonDecode(res.body));
  }

  /// ======================
  /// POST /api/promotions/{id}/apply
  /// Áp mã (preview)
  /// ======================
  static Future<Map<String, dynamic>> applyPromotion(int id) async {
    final token = AuthService.jwtToken;
    if (token == null) {
      throw Exception("Chưa đăng nhập");
    }

    final res = await http.post(
      Uri.parse("$baseUrl/api/promotions/$id/apply"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    final data = jsonDecode(res.body);

    if (res.statusCode != 200) {
      throw Exception(data["message"] ?? "Áp mã thất bại");
    }

    return data;
  }
}
