class Appointment {
  final int? appointmentId;
  final String status;

  // Spa + Vet
  final DateTime? appointmentDate;
  final String? appointmentTime;

  // Homestay
  final DateTime? startDate;
  final DateTime? endDate;

  final int? serviceId;
  final String serviceName;

  final int? petId;
  final String petName;
  final String petType;
  final String? petBreed;

  final String? userId;
  final String userName;

  final String? note; // Vet
  final String? ownerPhoneNumber;

  Appointment({
    this.appointmentId,
    required this.status,
    this.appointmentDate,
    this.appointmentTime,
    this.startDate,
    this.endDate,
    this.serviceId,
    required this.serviceName,
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
    return Appointment(
      appointmentId: json['appointmentId'] ?? json['AppointmentId'],

      status: json['status']?.toString() ?? '',

      appointmentDate: _parseDateSafe(
        json['appointmentDate'] ?? json['AppointmentDate'],
      ),

      appointmentTime:
      json['appointmentTime'] ?? json['AppointmentTime'],

      startDate: _parseDateSafe(
        json['startDate'] ?? json['StartDate'],
      ),

      endDate: _parseDateSafe(
        json['endDate'] ?? json['EndDate'],
      ),

      serviceId: json['serviceId'] ?? json['ServiceId'],
      serviceName: json['serviceName'] ?? json['ServiceName'] ?? '',

      petId: json['petId'] ?? json['PetId'],
      petName: json['petName']
          ?? json['PetName']
          ?? json['deletedPetName']
          ?? json['DeletedPetName']
          ?? '[Thú cưng đã xoá]',

      petType: json['petType']
          ?? json['PetType']
          ?? json['deletedPetType']
          ?? json['DeletedPetType']
          ?? '-',

      petBreed: json['petBreed'] ?? json['PetBreed'],

      userId: json['userId'] ?? json['UserId'],
      userName: json['userName'] ?? json['UserName'] ?? '',

      note: json['note'],
      ownerPhoneNumber: json['ownerPhoneNumber'],
    );
  }

  // ================== GETTERS (QUAN TRỌNG) ==================

  /// ✔ xác định Homestay hay không
  bool get isHomestay => startDate != null && endDate != null;

  /// ✔ hiển thị trạng thái cho UI
  String get statusDisplay {
    final s = status.toLowerCase();

    switch (s) {
      case '0':
      case 'pending':
        return 'Chờ xác nhận';
      case '1':
      case 'confirmed':
        return 'Đã xác nhận';
      case '2':
      case '3':
      case 'cancelled':
      case 'canceled':
        return 'Đã hủy';
      case '4':
      case 'deleted':
        return 'Đã xóa';
      default:
        return status;
    }
  }

  /// ✔ hiển thị thời gian hẹn (Spa / Vet)
  String get appointmentTimeDisplay {
    if (appointmentDate == null) return 'N/A';

    final d = appointmentDate!;
    final date =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    return appointmentTime != null && appointmentTime!.isNotEmpty
        ? '$date $appointmentTime'
        : date;
  }

  /// ✔ dùng cho nút Sửa / Hủy
  bool get isPending =>
      status.toLowerCase() == 'pending' || status == '0';

  /// ✔ kiểm tra có thể hủy không
  bool get canCancel {
    if (!isPending) return false;

    final now = DateTime.now();

    if (isHomestay && startDate != null) {
      return startDate!.difference(now).inDays >= 2;
    }

    if (!isHomestay && appointmentDate != null) {
      return appointmentDate!.difference(now).inDays >= 1;
    }

    return false;
  }

  // ================== PARSE DATE ==================
  static DateTime? _parseDateSafe(dynamic input) {
    if (input == null) return null;

    try {
      if (input is String && input.contains('/')) {
        final parts = input.split('/');
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
      return DateTime.parse(input.toString());
    } catch (_) {
      return null;
    }
  }
}
