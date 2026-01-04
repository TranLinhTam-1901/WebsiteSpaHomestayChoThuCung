import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/login/login_result.dart';

class AuthService {
  static String? jwtToken;
  static String get baseUrl {
    if (kIsWeb) {
      return "https://localhost:7051";
    }
    if (Platform.isAndroid) {
      return "http://10.0.2.2:7051";
    }
    return "http://localhost:7051";
  }

  static Future<LoginResult?> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // ⭐ LƯU TOKEN
      jwtToken = data['token'];

      return LoginResult.fromJson(data);
    }

    return null;
  }


  static Future<bool> register(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    return response.statusCode == 200;
  }

  static Future<String> getUserRole(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    return doc.data()?['role'] ?? 'User';
  }
}
