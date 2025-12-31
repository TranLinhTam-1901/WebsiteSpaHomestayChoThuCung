import 'dart:convert';
import '../model/order/order_model.dart';
import '../model/appointment/appointment.dart';
import '../model/appointment/appointment_detail.dart';
import '../model/pet/pet.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // Để dùng kIsWeb
import 'dart:io'; // Để sửa lỗi Undefined class 'File'
import 'package:http_parser/http_parser.dart'; // Để sửa lỗi 'MediaType'
import '../model/service/service.dart';

class ApiService {
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

  /// PET ///

  static Future<List<dynamic>> getPets() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/Pet'); // Khớp với [Route("api/Pet")]

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Lỗi GetPets: $e");
      return [];
    }
  }

  static Future<PetDetail?> getPetDetails(int id) async {
    // Sửa từ _getToken() thành getToken() cho đồng bộ với các hàm khác
    final token = await getToken();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Pet/$id'), // Lưu ý: Thêm /Pet/ nếu baseUrl của bạn chỉ là .../api
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return PetDetail.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint("Lỗi GetPetDetails: $e");
      return null;
    }
  }

  static Future<bool> addPet(Map<String, String> petData, File? imageFile, {Uint8List? webImageBytes}) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/Pet/Add');

    try {
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields.addAll(petData);

      if (kIsWeb && webImageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'imageFile', webImageBytes, filename: 'pet_image.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
      } else if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('imageFile', imageFile.path));
      }

      var streamedResponse = await request.send();
      // Chuyển stream phản hồi thành chuỗi text để đọc nội dung
      final responseBody = await streamedResponse.stream.bytesToString();

      print("DEBUG: Status Code = ${streamedResponse.statusCode}");

      // TRƯỜNG HỢP 1: Thành công chuẩn (200-299)
      if (streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300) {
        return true;
      }

      // TRƯỜNG HỢP 2: Lỗi 500 nhưng thực tế đã lưu xong (dựa vào nội dung JSON bạn gửi)
      if (streamedResponse.statusCode == 500 && responseBody.contains("Thêm thành công!")) {
        print("CẢNH BÁO: Server bị lỗi vòng lặp JSON nhưng dữ liệu đã lưu xong.");
        return true;
      }

      // TRƯỜNG HỢP 3: Lỗi thực sự
      print("SERVER ERROR DETAILS: $responseBody");
      return false;

    } catch (e) {
      print("Lỗi AddPet: $e");
      return false;
    }
  }

  static Future<bool> updatePet(int id, Map<String, String> petData, File? imageFile, {Uint8List? webImageBytes}) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/Pet/Update/$id');

    try {
      var request = http.MultipartRequest('PUT', url);
      request.headers['Authorization'] = 'Bearer $token';

      // Thêm các trường dữ liệu
      request.fields.addAll(petData);

      // Xử lý file ảnh (Hỗ trợ cả Mobile và Web)
      if (kIsWeb && webImageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'imageFile',
          webImageBytes,
          filename: 'update_pet.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
      } else if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'imageFile',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      // Gửi request
      var streamedResponse = await request.send();
      // Chuyển stream thành chuỗi để kiểm tra nội dung
      final responseBody = await streamedResponse.stream.bytesToString();

      print("DEBUG Update: Status Code = ${streamedResponse.statusCode}");

      // TRƯỜNG HỢP 1: Thành công chuẩn (200 OK)
      if (streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300) {
        return true;
      }

      // TRƯỜNG HỢP 2: Phòng thủ lỗi vòng lặp JSON (500 nhưng nội dung báo thành công)
      if (streamedResponse.statusCode == 500 && responseBody.contains("Cập nhật thành công!")) {
        print("CẢNH BÁO: Server lỗi JSON nhưng đã cập nhật xong DB.");
        return true;
      }

      print("LỖI UPDATE: $responseBody");
      return false;
    } catch (e) {
      print("Exception UpdatePet: $e");
      return false;
    }
  }

  static Future<bool> deletePet(int id) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/Pet/Delete/$id');

    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// APPOINTMENT ///

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

  static Future<bool> cancelAppointment(int id) async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse("$baseUrl/Appointments/Cancel/$id"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) return true;

      // Nếu lỗi 400 (do quy định thời gian), Backend trả về thông báo
      debugPrint("Lỗi hủy: ${response.body}");
      return false;
    } catch (e) {
      debugPrint("Lỗi kết nối Cancel: $e");
      return false;
    }
  }

  /// SPA ///

  static Future<Map<String, dynamic>> getSpaBookingData() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/Appointments/SpaServices');

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // Ép kiểu Json sang Model ngay tại đây để bên ngoài dễ dùng
        List<ServiceModel> services = data.map((e) => ServiceModel.fromJson(e)).toList();
        return {"services": services};
      }
    } catch (e) {
      debugPrint("Lỗi API SpaServices: $e");
    }
    return {"services": <ServiceModel>[]};
  }

  static Future<bool> saveSpaBooking(Map<String, dynamic> bookingData, bool isUpdate, {dynamic id}) async {
    final token = await getToken();
    final url = isUpdate
        ? Uri.parse('$baseUrl/Appointments/UpdateSpa/$id')
        : Uri.parse('$baseUrl/Appointments/BookSpa');

    try {
      final response = await (isUpdate ? http.put : http.post)(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(bookingData),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        // DÒNG QUAN TRỌNG: In lỗi để biết Backend đang thiếu gì
        debugPrint("❌ LỖI SERVER (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ LỖI KẾT NỐI: $e");
      return false;
    }
  }

  /// HOMESTAY ///

  static Future<Map<String, dynamic>> getHomestayBookingData() async {
    // Đảm bảo có chữ 's' sau chữ Appointment
    final String url = "$baseUrl/Appointments/GetHomestayServices";

    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("URL đang gọi: $url");
      debugPrint("Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Lấy danh sách từ key "services" (chữ thường theo Postman bạn gửi)
        final List<dynamic> list = responseData['services'] ?? [];

        List<ServiceModel> services = list.map((item) => ServiceModel.fromJson(item)).toList();

        debugPrint("Số lượng dịch vụ đã load thành công: ${services.length}");
        return {"services": services};
      }
    } catch (e) {
      debugPrint("Lỗi kết nối API: $e");
    }
    return {"services": <ServiceModel>[]};
  }

  static Future<bool> saveHomestayBooking(Map<String, dynamic> data, bool isUpdate, {int? id}) async {
    try {
      final token = await getToken();

      // 1. SỬA TẠI ĐÂY: Dùng Appointments (số nhiều) và bỏ chữ api thừa nếu baseUrl đã có
      // Giả sử baseUrl = "https://10.0.2.2:7051/api"
      final url = isUpdate
          ? "$baseUrl/Appointments/UpdateHomestay/$id"
          : "$baseUrl/Appointments/BookHomestay";

      debugPrint("Đang gửi yêu cầu đến URL: $url");

      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };
      final body = jsonEncode(data);

      // 2. CHỌN PHƯƠNG THỨC: isUpdate dùng PUT, tạo mới dùng POST
      final response = isUpdate
          ? await http.put(Uri.parse(url), headers: headers, body: body)
          : await http.post(Uri.parse(url), headers: headers, body: body);

      debugPrint("Save Homestay Status: ${response.statusCode}");
      debugPrint("Save Homestay Response: ${response.body}");

      // Thông thường StatusCode thành công là 200 hoặc 201
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Lỗi kết nối saveHomestayBooking: $e");
      return false;
    }
  }

  /// VET ///

  static Future<Map<String, dynamic>> getVetBookingData() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse("$baseUrl/Appointments/GetVetServices"), // Đảm bảo URL khớp với Backend
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {"services": []};
    } catch (e) {
      debugPrint("Lỗi getVetBookingData: $e");
      return {"services": []};
    }
  }

  static Future<bool> saveVetBooking(Map<String, dynamic> data, bool isUpdate, {int? id}) async {
    try {
      final token = await getToken();

      // 1. Sửa URL khớp với Backend (Appointments có s)
      // Lưu ý: Nếu baseUrl của bạn chưa có "/api", hãy giữ nguyên "/api/Appointments/..."
      final url = isUpdate
          ? "$baseUrl/Appointments/UpdateVet/$id"
          : "$baseUrl/Appointments/BookVet";

      debugPrint("Gửi yêu cầu Vet đến: $url");

      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };
      final body = jsonEncode(data);

      // 2. Sửa: Update dùng PUT, Tạo mới dùng POST
      final response = isUpdate
          ? await http.put(Uri.parse(url), headers: headers, body: body)
          : await http.post(Uri.parse(url), headers: headers, body: body);

      debugPrint("Vet Response Status: ${response.statusCode}");
      debugPrint("Vet Response Body: ${response.body}");

      // Trả về true nếu thành công (200 OK hoặc 201 Created)
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Lỗi kết nối saveVetBooking: $e");
      return false;
    }
  }

  /// HISTORY ///

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
}
