import 'pet_service_record.dart';

class PetDetail {
  final String? name;
  final String? type;
  final String? breed;
  final String? gender;
  final String? age;
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
  final List<PetServiceRecord>? serviceRecords;

  PetDetail({
    this.name,
    this.type,
    this.breed,
    this.gender,
    this.age,
    this.weight,
    this.height,
    this.color,
    this.vaccinationRecords,
    this.aiAnalysisResult,
    this.distinguishingMarks, // Sửa dấu ; thành dấu ,
    this.medicalHistory,      // Sửa dấu ; thành dấu ,
    this.allergies,           // Sửa dấu ; thành dấu ,
    this.dietPreferences,      // Sửa dấu ; thành dấu ,
    this.healthNotes,         // Sửa dấu ; thành dấu ,
    this.isDeleted,
    this.serviceRecords,
  });

  factory PetDetail.fromJson(Map<String, dynamic> json) {
    return PetDetail(
      name: json['name']?.toString(),
      type: json['type']?.toString(),
      breed: json['breed']?.toString(),
      gender: json['gender']?.toString(),
      age: json['age']?.toString(),

      // Xử lý số thực an toàn
      weight: json['weight'] != null ? double.tryParse(json['weight'].toString()) : null,
      height: json['height'] != null ? double.tryParse(json['height'].toString()) : null,

      color: json['color']?.toString(),
      vaccinationRecords: json['vaccinationRecords']?.toString(),

      // Map các trường đặc biệt từ C# (đề phòng API trả về PascalCase hoặc Snake_case)
      aiAnalysisResult: (json['ai_AnalysisResult'] ?? json['AI_AnalysisResult'] ?? json['aiAnalysisResult'])?.toString(),
      distinguishingMarks: (json['distinguishingMarks'] ?? json['distinguishing_Marks'])?.toString(),
      medicalHistory: (json['medicalHistory'] ?? json['medical_History'])?.toString(),
      allergies: json['allergies']?.toString(),
      dietPreferences: (json['dietPreferences'] ?? json['diet_Preferences'])?.toString(),
      healthNotes: (json['healthNotes'] ?? json['health_Notes'])?.toString(),

      // Logic xác định thú cưng đã xóa
      isDeleted: json['isDeleted'] ?? (json['deletedPet'] != null),

      // Parse danh sách lịch sử dịch vụ
      serviceRecords: (json['serviceRecords'] ?? json['service_Records']) != null
          ? ( (json['serviceRecords'] ?? json['service_Records']) as List)
          .map((i) => PetServiceRecord.fromJson(i))
          .toList()
          : null,
    );
  }
}