import '../pet/pet.dart';
import '../pet/deleted_pet.dart';

class AppointmentDetail {
  final int appointmentId;
  final int status; // Postman trả về số (0, 1, 2)
  final String? appointmentDate;
  final String? appointmentTime;
  final String? serviceName;
  final String? serviceCategory; // Cần API trả về cái này
  final String? startDate;
  final String? endDate;
  final String? createdDate;
  final String? ownerPhoneNumber;
  final String? note;
  final PetDetail? pet;
  final DeletedPet? deletedPet;

  AppointmentDetail({
    required this.appointmentId,
    required this.status,
    this.appointmentDate,
    this.appointmentTime,
    this.serviceName,
    this.serviceCategory,
    this.startDate,
    this.endDate,
    this.createdDate,
    this.ownerPhoneNumber,
    this.note,
    this.pet,
    this.deletedPet,
  });

  factory AppointmentDetail.fromJson(Map<String, dynamic> json) {
    return AppointmentDetail(
      appointmentId: json['appointmentId'] ?? 0,
      status: json['status'] ?? 0,
      appointmentDate: json['appointmentDate']?.toString(), // Ép kiểu chuỗi
      appointmentTime: json['appointmentTime']?.toString(),
      serviceName: json['serviceName']?.toString(),
      serviceCategory: json['serviceCategory']?.toString(),
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
      createdDate: json['createdDate']?.toString(),
      ownerPhoneNumber: json['ownerPhoneNumber']?.toString(),
      note: json['note']?.toString(),
      pet: json['pet'] != null ? PetDetail.fromJson(json['pet']) : null,
    );
  }

// Cập nhật getter statusDisplay để khớp với các mã code (0, 1, 2, 4...)
  String get statusDisplay {
    switch (status) {
      case 0: return 'Chờ xác nhận';
      case 1: return 'Đã xác nhận';
      case 2:
      case 3: return 'Đã hủy';
      case 4: return 'Đã xóa';
      default: return 'Không xác định';
    }
  }

  bool get isHomestay => serviceCategory == 'Homestay' || startDate != null;
}