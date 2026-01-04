import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // Để dùng kIsWeb
import '../model/pet/pet.dart';
import '../model/Blockchain/blockchain_record.dart';

class AdminApiService {
  static const String baseUrl = kIsWeb
      ? 'https://localhost:7051/api'
      : 'https://10.0.2.2:7051/api';

  /// LOGIN ///

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<bool> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/Auth/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      return true;
    } else {
      return false;
    }
  }

  /// USER ///

  static Future<Map<String, dynamic>?> getUserProfile() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/Appointments/Profile');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<dynamic>> getUserPets() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/Pets/MyPets'); // Giả định endpoint lấy pet của user

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// BLOCKCHAIN ///

  static Future<List<BlockchainRecord>> getBlockchainLogs() async {
    try {
      print("Đang gọi API: $baseUrl/admin/Blockchain");

      final response = await http.get(
        Uri.parse('$baseUrl/admin/Blockchain'),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);
        List<dynamic> list = (decodedData is List) ? decodedData : (decodedData['records'] ?? []);
        return list.map((item) => BlockchainRecord.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print("Lỗi ApiService: $e");
      return [];
    }
  }

  /// PET ///

  static Future<List<PetDetail>> getAllPets() async {
    try {
      final token = await getToken();
      final url = Uri.parse('$baseUrl/admin/Pet'); // Kiểm tra lại URL này

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List<dynamic> list;
        if (decoded is Map && decoded.containsKey('data')) {
          list = decoded['data']; // Nếu API bọc trong "data"
        } else {
          list = decoded; // Nếu API trả về mảng trực tiếp
        }

        return list.map((item) => PetDetail.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Lỗi getAllPets: $e");
      return [];
    }
  }

  static Future<PetDetail?> getPetDetails(int id) async {
    try {
      final token = await getToken();
      if (token == null) {
        debugPrint("❌ LỖI: Token Admin không tồn tại!");
        return null;
      }

      // Đảm bảo URL khớp với Route [HttpGet("{id}")] của Admin controller
      final url = Uri.parse('$baseUrl/admin/Pet/$id');

      debugPrint("🚀 Admin đang lấy chi tiết Pet ID: $id");

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(response.body);

        // Kiểm tra flag success từ API trả về (C# trả về success: true)
        if (decodedData['success'] == true && decodedData['data'] != null) {
          debugPrint("✅ Lấy dữ liệu thành công cho Pet: ${decodedData['data']['name']}");
          return PetDetail.fromJson(decodedData['data']);
        }

        // Trường hợp API trả về trực tiếp Object không bọc success/data (dự phòng)
        return PetDetail.fromJson(decodedData);
      } else if (response.statusCode == 404) {
        debugPrint("⚠️ Không tìm thấy Pet ID: $id (404)");
        return null;
      } else {
        debugPrint("❌ Lỗi Server (${response.statusCode}): ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("🚑 Lỗi kết nối hoặc Parse JSON: $e");
      return null;
    }
  }

  static Future<bool> deletePet(int id) async {
    try {
      final token = await getToken();
      final url = Uri.parse('$baseUrl/Pet/$id');

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}
