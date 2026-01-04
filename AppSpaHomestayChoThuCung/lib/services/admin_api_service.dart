import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // Để dùng kIsWeb
import '../model/pet/pet.dart';
import '../model/appointment/appointment.dart';
import '../model/order/order.dart';
import '../model/user/user_profile.dart';
import '../model/blockchain/blockchain_record.dart';

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

  static Map<String, String> _getHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, String>> _getAuthenticatedHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token ?? ""}',
    };
  }

  /// USER ///

  static Future<List<UserProfile>> getUserList(String token, {String search = ""}) async {
    final url = Uri.parse("$baseUrl/admin/User/list?search=$search");

    final response = await http.get(url, headers: _getHeaders(token));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => UserProfile.fromJson(item)).toList();
    } else {
      // Log lỗi để debug
      debugPrint("HTML Error from Server: ${response.body}");
      throw Exception("Lỗi kết nối Server: ${response.statusCode}");
    }
  }

  static Future<Map<String, dynamic>> getUserDetails(String token, String id) async {
    final url = Uri.parse("$baseUrl/admin/User/details/$id");

    final response = await http.get(url, headers: _getHeaders(token));

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // Trả về { "user": ..., "allRoles": [...] }
    } else {
      throw Exception("Không thể lấy thông tin chi tiết");
    }
  }

  static Future<bool> editUser(String token, UserProfile user) async {
    // Thử chính xác chữ U viết hoa trong User
    final url = Uri.parse("$baseUrl/admin/User/edit");

    // Nếu vẫn 404, hãy thử viết thường toàn bộ (phổ biến trong cấu hình .NET)
    // final url = Uri.parse("$baseUrl/api/admin/user/edit");

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'Id': user.id,
        'UserName': user.userName,
        'FullName': user.fullName,
        'Email': user.email,
        'PhoneNumber': user.phone,
        'Address': user.address,
        'Role': user.role,
        'IsLocked': user.isLocked,
      }),
    );

    print("StatusCode thực tế: ${response.statusCode}");
    return response.statusCode == 200;
  }

  static Future<bool> lockUser(String token, String id) async {
    final url = Uri.parse("$baseUrl/admin/User/lock/$id");

    final response = await http.post(url, headers: _getHeaders(token));

    return response.statusCode == 200;
  }

  static Future<bool> unlockUser(String token, String id) async {
    final url = Uri.parse("$baseUrl/admin/User/unlock/$id");

    final response = await http.post(url, headers: _getHeaders(token));

    return response.statusCode == 200;
  }

  /// BLOCKCHAIN ///

  static Future<List<BlockchainRecord>> getBlockchainLogs() async {
    try {
      final token = await getToken();
      print("Đang gọi API: $baseUrl/admin/Blockchain");

      final response = await http.get(
        Uri.parse('$baseUrl/admin/Blockchain'),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
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

  static Future<Map<String, dynamic>> getPetBlockchain(int petId) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/admin/Blockchain/pet/$petId');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Lỗi server: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Không thể kết nối API: $e');
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

      // Đảm bảo URL khớp với Route [HttpGet("{id}")] của Admin Controller
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

  /// APPOINTMENT ///

  static Future<List<Appointment>> getPendingAppointments() async {
    try {
      final token = await getToken(); // Đảm bảo lấy token đúng cách
      if (token == null) throw Exception("Token không tồn tại");

      final url = Uri.parse("$baseUrl/admin/Appointment/pending");
      final response = await http.get(
        url,
        headers: _getHeaders(token), // Sử dụng chung hàm helper _getHeaders
      );

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        // Chuyển đổi JSON sang List<Appointment> ngay tại đây
        return body.map((item) => Appointment.fromJson(item)).toList();
      } else {
        print("Lỗi API Pending: ${response.body}"); // Log lỗi từ Server trả về
        throw Exception("Lỗi lấy danh sách chờ: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception tại getPendingAppointments: $e");
      rethrow;
    }
  }

  static Future<List<Appointment>> getAppointmentHistory() async {
    try {
      final token = await getToken();
      if (token == null) throw Exception("Token null");

      final url = Uri.parse("$baseUrl/admin/Appointment/history");
      final response = await http.get(url, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        // Kiểm tra nếu data là List (đề phòng trường hợp API trả về object bọc ngoài)
        if (data is List) {
          return data.map((item) => Appointment.fromJson(item)).toList();
        } else {
          return [];
        }
      } else {
        print("Lỗi API History: ${response.body}");
        throw Exception("Không thể tải lịch sử lịch hẹn: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception tại getAppointmentHistory: $e");
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getAppointmentDetails(int id) async {
    try {
      final url = Uri.parse("$baseUrl/admin/Appointment/$id");
      final response = await http.get(url, headers: await _getAuthenticatedHeaders());

      if (response.statusCode == 200) {
        // Trả về Map để dùng Appointment.fromJson(details) ở trang Detail
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("Lỗi getAppointmentDetails: $e");
      return null;
    }
  }

  static Future<bool> acceptAppointment(int id) async {
    final url = Uri.parse("$baseUrl/admin/Appointment/accept/$id");
    final response = await http.post(url, headers: await _getAuthenticatedHeaders());

    if (response.statusCode == 200) {
      return true;
    } else {
      debugPrint("Lỗi duyệt: ${response.body}");
      return false;
    }
  }

  static Future<bool> cancelAppointment(int id) async {
    final url = Uri.parse("$baseUrl/admin/Appointment/cancel/$id");
    final response = await http.post(url, headers: await _getAuthenticatedHeaders());

    if (response.statusCode == 200) {
      return true;
    } else {
      debugPrint("Lỗi hủy: ${response.body}");
      return false;
    }
  }

  /// ORDERS ///

  static Future<List<Order>> getOrders() async {
    try {
      // Sửa URL: Thêm /admin/orders
      final url = Uri.parse("$baseUrl/admin/Orders");
      final response = await http.get(
        url,
        headers: await _getAuthenticatedHeaders(), // Dùng hàm đã có của bạn
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Order.fromJson(json)).toList();
      } else {
        debugPrint("Lỗi GetOrders: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error GetOrders: $e");
      return [];
    }
  }

  static Future<Order?> getOrderDetails(int id) async {
    try {
      // Sửa URL: Thêm /admin/orders
      final url = Uri.parse("$baseUrl/admin/Orders/$id");
      final response = await http.get(
        url,
        headers: await _getAuthenticatedHeaders(),
      );

      if (response.statusCode == 200) {
        return Order.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint("Error OrderDetails: $e");
      return null;
    }
  }

  static Future<bool> confirmOrder(int id) async {
    try {
      // Khớp với Route [HttpPost("confirm/{id}")] ở Backend
      final url = Uri.parse("$baseUrl/admin/Orders/confirm/$id");
      final response = await http.post(
        url,
        headers: await _getAuthenticatedHeaders(),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        debugPrint("Lỗi xác nhận đơn: ${error['message']}");
        return false;
      }
    } catch (e) {
      debugPrint("Error ConfirmOrder: $e");
      return false;
    }
  }

  static Future<bool> cancelOrder(int id) async {
    try {
      // Khớp với Route [HttpPost("cancel/{id}")] ở Backend
      final url = Uri.parse("$baseUrl/admin/Orders/cancel/$id");
      final response = await http.post(
        url,
        headers: await _getAuthenticatedHeaders(),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        debugPrint("Lỗi hủy đơn: ${error['message']}");
        return false;
      }
    } catch (e) {
      debugPrint("Error CancelOrder: $e");
      return false;
    }
  }
}
