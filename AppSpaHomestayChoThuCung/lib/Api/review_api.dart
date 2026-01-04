import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../model/review/review_model.dart';
import 'auth_service.dart';

class ReviewApi {
  static const String baseUrl = "https://localhost:7051";

  static Future<ReviewResponse> getReviews(int productId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/api/products/$productId/reviews"),
    );

    if (res.statusCode != 200) {
      throw Exception("Không lấy được review");
    }

    return ReviewResponse.fromJson(jsonDecode(res.body));
  }

  /// ======================
  /// POST REVIEW (THÊM)
  /// ======================
  static Future<void> postReview({
    required int productId,
    required int rating,
    required String comment,
    required List<XFile> images,
  }) async {
    final uri = Uri.parse("$baseUrl/api/reviews");
    final request = http.MultipartRequest("POST", uri);
    final token = AuthService.jwtToken;
    if (token == null) {
      throw Exception("Chưa đăng nhập");
    }
    request.headers.addAll({
      "Authorization": "Bearer $token",
    });

    request.fields["targetId"] = productId.toString();

    request.fields["rating"] = rating.toString();
    request.fields["comment"] = comment;

    for (final img in images) {
      if (kIsWeb) {
        final bytes = await img.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(

            "reviewImages",

            bytes,
            filename: img.name,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            "reviewImages",

            img.path,
          ),
        );
      }
    }

    final res = await request.send();
    if (res.statusCode != 200) {
      final body = await res.stream.bytesToString();
      throw Exception("Upload review thất bại: $body");

    }
  }

}
