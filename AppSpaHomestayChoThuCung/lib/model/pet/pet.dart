import 'pet_service_record.dart';

class PetDetail {
  final int? id; // Map với petId trong C#
  final String? name;
  final String? type;
  final String? breed;
  final String? gender;
  final int? age; // Chuyển về int cho đồng bộ với C#
  final String? dateOfBirth;
  final double? weight;
  final double? height;
  final String? color;
  final String? vaccinationRecords;
  final String? aiAnalysisResult;
  final String? distinguishingMarks;
  final String? medicalHistory;
  final String? allergies;
  final String? dietPreferences;
  final String? healthNotes;
  final bool? isDeleted;
  final String? imageUrl;
  final String? userId;
  final List<PetServiceRecord>? serviceRecords;
  final String? ownerName;
  final String? ownerPhone;
  final String? ownerAddress;

  PetDetail({
    this.id,
    this.name,
    this.type,
    this.breed,
    this.gender,
    this.age,
    this.dateOfBirth,
    this.weight,
    this.height,
    this.color,
    this.vaccinationRecords,
    this.aiAnalysisResult,
    this.distinguishingMarks,
    this.medicalHistory,
    this.allergies,
    this.dietPreferences,
    this.healthNotes,
    this.isDeleted,
    this.imageUrl,
    this.userId,
    this.serviceRecords,
    this.ownerName,
    this.ownerPhone,
    this.ownerAddress,
  });

  Map<String, dynamic> toMap() {
    return {
      'petId': id, // Lấy đúng ID của đối tượng
      'name': name ?? "",
      'type': type ?? "",
      'breed': breed ?? "",
      'gender': gender ?? "Male",
      'age': age ?? 0,
      'dateOfBirth': dateOfBirth,
      'weight': weight ?? 0.0,
      'height': height ?? 0.0,
      'color': color ?? "",
      'imageUrl': imageUrl ?? "",
      'vaccinationRecords': vaccinationRecords ?? "",
      'medicalHistory': medicalHistory ?? "",
      'distinguishingMarks': distinguishingMarks ?? "",
      'aiAnalysisResult': aiAnalysisResult ?? "",
      'allergies': allergies ?? "",
      'dietPreferences': dietPreferences ?? "",
      'healthNotes': healthNotes ?? "",
      'userId': userId ?? "",
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'ownerAddress': ownerAddress,
    };
  }

  factory PetDetail.fromJson(Map<String, dynamic> json) {
    return PetDetail(
      // 1. Map ID
      id: json['petId'] ?? json['PetId'],

      name: json['name']?.toString(),
      type: json['type']?.toString(),
      breed: json['breed']?.toString(),
      gender: json['gender']?.toString(),

      // 2. Logic lấy tên chủ linh hoạt
      // - json['ownerName']: Lấy từ API GetAll (trường phẳng)
      // - json['owner']['fullName']: Lấy từ API Details (object lồng)
      ownerName: json['ownerName'] ??
          (json['owner'] != null ? json['owner']['fullName'] : null) ??
          "Chưa có chủ",
      ownerPhone: json['owner'] != null ? json['owner']['phoneNumber']?.toString() : null,
      ownerAddress: json['owner'] != null ? json['owner']['address']?.toString() : null,

      // 3. Ép kiểu số an toàn
      age: json['age'] is int ? json['age'] : int.tryParse(json['age']?.toString() ?? ""),
      weight: json['weight'] != null ? double.tryParse(json['weight'].toString()) : null,
      height: json['height'] != null ? double.tryParse(json['height'].toString()) : null,

      dateOfBirth: json['dateOfBirth']?.toString(),
      color: json['color']?.toString(),
      imageUrl: json['imageUrl']?.toString(),

      // 4. Map các trường thông tin chi tiết (Dùng cho trang Detail)
      vaccinationRecords: json['vaccinationRecords'] ?? json['VaccinationRecords'],
      medicalHistory: json['medicalHistory'] ?? json['MedicalHistory'],
      distinguishingMarks: json['distinguishingMarks'] ?? json['DistinguishingMarks'],
      aiAnalysisResult: json['aiAnalysisResult'] ?? json['AiAnalysisResult'] ?? json['aI_AnalysisResult'],
      allergies: json['allergies'] ?? json['Allergies'],
      dietPreferences: json['dietPreferences'] ?? json['DietPreferences'],
      healthNotes: json['healthNotes'] ?? json['HealthNotes'],

      userId: json['userId']?.toString(),
      isDeleted: json['isDeleted'] ?? false,

      serviceRecords: json['serviceRecords'] != null
          ? (json['serviceRecords'] as List).map((i) => PetServiceRecord.fromJson(i)).toList()
          : null,
    );
  }
}