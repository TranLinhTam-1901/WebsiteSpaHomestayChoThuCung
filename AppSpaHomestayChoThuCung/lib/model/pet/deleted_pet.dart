class DeletedPet {
  final int id;                 // Id (DeletedPet)
  final int originalPetId;      // Id pet gốc

  final String name;            // Tên thú cưng
  final String type;            // Loại (chó, mèo…)
  final String? breed;          // Giống
  final String? gender;         // Giới tính
  final int? age;               // Tuổi
  final double? weight;         // Cân nặng
  final String? imageUrl;       // Ảnh

  final String userId;          // Chủ sở hữu
  final DateTime deletedAt;     // Thời điểm xóa
  final String? deletedBy;      // Ai xóa

  DeletedPet({
    required this.id,
    required this.originalPetId,
    required this.name,
    required this.type,
    this.breed,
    this.gender,
    this.age,
    this.weight,
    this.imageUrl,
    required this.userId,
    required this.deletedAt,
    this.deletedBy,
  });

  factory DeletedPet.fromJson(Map<String, dynamic> json) {
    return DeletedPet(
      id: json['id'],
      originalPetId: json['originalPetId'],
      name: json['name'],
      type: json['type'],
      breed: json['breed'],
      gender: json['gender'],
      age: json['age'],
      weight: json['weight'] != null
          ? (json['weight'] as num).toDouble()
          : null,
      imageUrl: json['imageUrl'],
      userId: json['userId'],
      deletedAt: DateTime.parse(json['deletedAt']),
      deletedBy: json['deletedBy'],
    );
  }
}