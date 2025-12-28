import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/order/order_model.dart';
import '../model/appointment/appointment.dart';
import '../model/appointment/appointment_detail.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = kIsWeb
      ? 'https://localhost:7051/api'
      : 'https://10.0.2.2:7051/api';

  /// Lấy token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  /// Login
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

  static Future<List<dynamic>> getUserPets() async {
    final token = await getToken();
    // THỬ KIỂM TRA LẠI CHỮ 'Pets' CÓ 's' HAY KHÔNG
    final url = Uri.parse('$baseUrl/Pets/GetUserPets');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      // Nếu vẫn 404, hãy in URL ra console để copy dán vào trình duyệt kiểm tra
      print("Đang gọi: ${url.toString()} - Status: ${response.statusCode}");

      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) { return []; }
  }

// 1. Hàm lấy dữ liệu (Services & Pricings)
  static Future<Map<String, dynamic>> getSpaBookingData() async {
    final token = await getToken(); // Phải lấy token
    final url = Uri.parse('$baseUrl/Appointments/SpaServices');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // THÊM DÒNG NÀY
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // Code map dữ liệu giữ nguyên như cũ...
        return {"services": data, "pricings": data.map((e) => e['spaPricing']).toList()};
      }
      return {"services": [], "pricings": []};
    } catch (e) {
      return {"services": [], "pricings": []};
    }
  }

// 2. Hàm Lưu/Cập nhật (Phải gửi đúng cấu trúc request mà C# chờ)
  static Future<bool> saveSpaBooking(Map<String, dynamic> bookingData, bool isUpdate, {int? id}) async {
    final token = await getToken();
    final url = isUpdate
        ? Uri.parse('$baseUrl/Appointments/UpdateSpa/$id')
        : Uri.parse('$baseUrl/Appointments/BookSpa');

    try {
      final response = await (isUpdate ? http.put : http.post)(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // THÊM DÒNG NÀY
        },
        body: jsonEncode(bookingData),
      );

      print("Response từ Server: ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Lấy lịch sử đơn hàng
  static Future<List<Order>> getOrderHistory() async {
    final token = await getToken();
    if (token == null) throw Exception("Chưa login");

    final url = Uri.parse('$baseUrl/OrderHistory');

    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    } else if (response.statusCode == 401) {
      throw Exception("Unauthorized - token lỗi hoặc hết hạn");
    } else {
      throw Exception('Lỗi API: ${response.statusCode}');
    }
  }

  /// Hủy đơn hàng
  static Future<void> cancelOrder(int id) async {
    final token = await getToken();
    if (token == null) throw Exception("Chưa login");

    final url = Uri.parse('$baseUrl/OrderHistory/cancel/$id');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Hủy đơn thất bại: ${response.statusCode}');
    }
  }

  /// Lấy danh sách lịch hẹn
  static Future<List<Appointment>> getBookingHistory() async {
    final token = await getToken();
    if (token == null) throw Exception("Chưa login");

    final url = Uri.parse('$baseUrl/Appointments/MyAppointments');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Appointment.fromJson(e)).toList();
    } else {
      throw Exception('Lỗi API: ${response.statusCode}');
    }
  }

  /// Lấy chi tiết lịch hẹn
  static Future<AppointmentDetail> getAppointmentDetail(int id) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/Appointments/Details/$id'); // Sửa lại đường dẫn này

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return AppointmentDetail.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Lỗi khi lấy chi tiết: ${response.statusCode}');
    }
  }

  /// Hủy lịch hẹn
  static Future<void> cancelAppointment(int id) async {
    final token = await getToken();
    if (token == null) throw Exception("Chưa login");

    final url = Uri.parse('$baseUrl/Appointments/cancel/$id');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Hủy thất bại: ${response.statusCode}');
    }
  }
}
