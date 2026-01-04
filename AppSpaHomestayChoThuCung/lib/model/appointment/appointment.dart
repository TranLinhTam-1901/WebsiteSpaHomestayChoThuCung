import 'package:intl/intl.dart';

class Appointment {
  final int? appointmentId;
  final String status;

  // BIẾN MỚI: Để hứng trực tiếp chuỗi "30/01/2026..." từ Postman
  final String? timeDisplayFromApi;

  // Spa + Vet
  final DateTime? appointmentDate;
  final String? appointmentTime;

  // Homestay
  final DateTime? startDate;
  final DateTime? endDate;

  final int? serviceId;
  final String serviceName;
  final String? serviceCategory;

  final int? petId;
  final String petName;
  final String petType;
  final String? petBreed;

  final String? userId;
  final String userName;

  final String? note;
  final String? ownerPhoneNumber;

  Appointment({
    this.appointmentId,
    required this.status,
    this.timeDisplayFromApi, // Thêm vào constructor
    this.appointmentDate,
    this.appointmentTime,
    this.startDate,
    this.endDate,
    this.serviceId,
    required this.serviceName,
    this.serviceCategory,
    this.petId,
    required this.petName,
    required this.petType,
    this.petBreed,
    this.userId,
    required this.userName,
    this.note,
    this.ownerPhoneNumber,
  });

  // ================== FROM JSON ==================
  factory Appointment.fromJson(Map<String, dynamic> json) {
    // 1. Xử lý tên khách hàng
    String uName = json['customerName'] ?? json['userName'] ?? '';
    if (json['user'] != null) {
      uName = json['user']['fullName'] ?? uName;
    }

    // 2. XỬ LÝ THÚ CƯNG (Fix lỗi thú cưng bị xóa)
    // Backend của bạn giờ đã gộp Pet hoặc DeletedPet vào key "pet"
    final petData = json['pet'];
    String pName = json['petName'] ?? '';
    String pType = json['petType'] ?? '-';
    String pBreed = json['petBreed'] ?? '';

    if (petData != null) {
      pName = petData['name'] ?? pName;
      pType = petData['type'] ?? pType;
      pBreed = petData['breed'] ?? pBreed;
    } else if (json['petName'] == null) {
      // Trường hợp xấu nhất nếu cả 2 đều null
      pName = "Thú cưng không xác định";
    }

    return Appointment(
      appointmentId: json['appointmentId'] ?? json['AppointmentId'],
      status: json['status']?.toString() ?? '',
      timeDisplayFromApi: json['TimeDisplay'] ?? json['timeDisplay'],
      appointmentDate: _parseDateSafe(json['appointmentDate']),
      appointmentTime: json['appointmentTime'],
      startDate: _parseDateSafe(json['startDate']),
      endDate: _parseDateSafe(json['endDate']),
      serviceName: json['serviceName'] ?? (json['service'] != null ? json['service']['name'] : 'N/A'),
      serviceCategory: json['serviceCategory']?.toString(),
      userName: uName,
      petName: pName,
      petType: pType,
      petBreed: pBreed,
      ownerPhoneNumber: json['ownerPhoneNumber'] ?? (json['user'] != null ? json['user']['phoneNumber'] : null),
      note: json['note'],
    );
  }

  // ================== TO JSON ==================
  Map<String, dynamic> toJson() {
    return {
      'appointmentId': appointmentId,
      'status': status,
      'appointmentDate': appointmentDate?.toIso8601String(),
      'appointmentTime': appointmentTime,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'serviceId': serviceId,
      'serviceName': serviceName,
      'serviceCategory': serviceCategory,
      'petId': petId,
      'petName': petName,
      'petType': petType,
      'petBreed': petBreed,
      'userId': userId,
      'userName': userName,
      'note': note,
      'ownerPhoneNumber': ownerPhoneNumber,
    };
  }

  // ================== CÁC GETTER MỚI (BỔ SUNG CHO ADMIN) ==================

  String get customerName => userName;
  String get serviceType => serviceCategory ?? "Vet";

  // FIX: Ưu tiên lấy chuỗi timeDisplay có sẵn từ API để hiện đúng ngày
  String get timeDisplay {
    if (timeDisplayFromApi != null && timeDisplayFromApi!.isNotEmpty) {
      return timeDisplayFromApi!;
    }
    // Nếu không có thì mới chạy logic cũ
    if (isHomestay) {
      if (startDate == null || endDate == null) return "Chưa rõ ngày";
      final start = DateFormat('dd/MM').format(startDate!);
      final end = DateFormat('dd/MM').format(endDate!);
      return "$start - $end";
    } else {
      if (appointmentDate == null) return 'N/A';
      final d = appointmentDate!;
      final date = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
      return (appointmentTime != null && appointmentTime!.isNotEmpty)
          ? '$date $appointmentTime'
          : date;
    }
  }

  // ================== GETTERS CŨ (GIỮ NGUYÊN 100%) ==================
  bool get isHomestay => startDate != null && endDate != null;

  String get statusDisplay {
    final s = status.toLowerCase();
    switch (s) {
      case '0': case 'pending': return 'Chờ xác nhận';
      case '1': case 'confirmed': return 'Đã xác nhận';
      case '2': case '3': case 'cancelled': case 'canceled': return 'Đã hủy';
      case '4': case 'deleted': return 'Đã xóa';
      default: return status;
    }
  }

  String get appointmentTimeDisplay {
    if (appointmentDate == null) return 'N/A';
    final d = appointmentDate!;
    final date = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    return appointmentTime != null && appointmentTime!.isNotEmpty ? '$date $appointmentTime' : date;
  }

  bool get isPending => status.toLowerCase() == 'pending' || status == '0';

  bool get canCancel {
    if (!isPending) return false;
    final now = DateTime.now();
    if (isHomestay && startDate != null) return startDate!.difference(now).inDays >= 2;
    if (!isHomestay && appointmentDate != null) return appointmentDate!.difference(now).inDays >= 1;
    return false;
  }

  // ================== PARSE DATE ==================
  static DateTime? _parseDateSafe(dynamic input) {
    if (input == null) return null;
    try {
      if (input is String && input.contains('/')) {
        final parts = input.split('/');
        return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }
      return DateTime.parse(input.toString());
    } catch (_) {
      return null;
    }
  }
}