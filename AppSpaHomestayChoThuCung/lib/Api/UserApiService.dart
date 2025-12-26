  import 'dart:convert';
  import 'package:flutter/foundation.dart';
  import 'package:http/http.dart' as http;
  import 'dart:io';

  import '../model/user_profile.dart';

  class UserApiService {
    static String get baseUrl {
      // ✅ đồng bộ với AuthService của bạn
      if (kIsWeb) return "https://localhost:7051";
      if (Platform.isAndroid) return "http://10.0.2.2:7051";
      return "https://localhost:7051";
    }

    static Future<UserProfile> getMyProfile(String token) async {
      final uri = Uri.parse("$baseUrl/api/users/me");

      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return UserProfile.fromJson(data);
      }

      // debug dễ hiểu
      throw Exception(
        "getMyProfile failed: ${response.statusCode} - ${response.body}",
      );
    }
  }
