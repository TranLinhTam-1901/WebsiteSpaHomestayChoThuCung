import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Controller/pet_controller.dart';

const kDarkPink = Color(0xFFFF6185);
const kPrimaryPink = Color(0xFFFFB6C1);
const kBackgroundPink = Color(0xFFFFF0F5);

class PetDetailPage extends StatelessWidget {
  final Pet  pet; // dùng pet hiện tại của bạn (Pet hoặc Map)

  const PetDetailPage({Key? key, required this.pet}) : super(key: key);

  String _text(String? value) =>
      (value == null || value.trim().isEmpty) ? "Chưa có" : value;

  String _number(dynamic value, String unit) =>
      value != null ? "$value $unit" : "Chưa có";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundPink,
      appBar: AppBar(
        backgroundColor: kPrimaryPink,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "📋 Chi tiết thú cưng",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: () {
              // TODO: sang trang sửa thú cưng
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: kPrimaryPink.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🐾 ẢNH THÚ CƯNG
              Center(
                child: pet.imageUrl != null && pet.imageUrl!.isNotEmpty
                    ? CircleAvatar(
                  radius: 75,
                  backgroundImage: NetworkImage(pet.imageUrl!), // thêm !
                )
                    : const CircleAvatar(
                  radius: 75,
                  backgroundColor: kBackgroundPink,
                  child: Icon(Icons.pets, size: 48, color: kDarkPink),
                ),
              ),

              const SizedBox(height: 24),

              /// 📋 THÔNG TIN CƠ BẢN
              _sectionTitle("📋 Thông tin cơ bản"),
              _infoRow("Tên thú cưng", _text(pet.name)),
              _infoRow("Loại", _text(pet.type)),
              _infoRow("Giống", _text(pet.breed)),
              _infoRow(
                "Giới tính",
                pet.gender == "Male"
                    ? "Đực"
                    : pet.gender == "Female"
                    ? "Cái"
                    : "Chưa có",
              ),
              _infoRow(
                "Tuổi",
                pet.age != null
                    ? (pet.age == 0 ? "< 1 tuổi" : "${pet.age} tuổi")
                    : "Chưa có",
              ),
              _infoRow(
                "Ngày sinh",
                pet.dateOfBirth != null
                    ? "${pet.dateOfBirth!.day}/${pet.dateOfBirth!.month}/${pet.dateOfBirth!.year}"
                    : "Chưa có",
              ),
              _infoRow("Màu sắc", _text(pet.color)),
              _infoRow("Dấu hiệu nhận dạng", _text(pet.distinguishingMarks)),

              const SizedBox(height: 20),

              /// ⚖️ THÔNG TIN THỂ CHẤT
              _sectionTitle("⚖️ Thông tin thể chất"),
              _infoRow("Cân nặng", _number(pet.weight, "kg")),
              _infoRow("Chiều cao", _number(pet.height, "cm")),

              const SizedBox(height: 20),

              /// 🩺 SỨC KHỎE
              _sectionTitle("🩺 Thông tin sức khỏe"),
              _paragraph("Hồ sơ tiêm phòng", _text(pet.vaccinationRecords)),
              _paragraph("Tiền sử bệnh", _text(pet.medicalHistory)),
              _paragraph("Dị ứng", _text(pet.allergies)),
              _paragraph("Chế độ ăn", _text(pet.dietPreferences)),
              _paragraph("Ghi chú sức khỏe", _text(pet.healthNotes)),

              const SizedBox(height: 20),

              /// 🤖 AI
              _sectionTitle("🤖 Kết quả phân tích AI"),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                    pet.aiAnalysisResult != null && pet.aiAnalysisResult!.isNotEmpty
                        ? pet.aiAnalysisResult!
                        : "Chưa được phân tích",

                    style: const TextStyle(color: Colors.black87),
                ),
              ),

              const SizedBox(height: 28),

              /// 🔘 NÚT
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Padding(
                      padding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text("← Quay lại"),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: sang trang sửa
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Padding(
                      padding:
                      EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      child: Text("🛠️ Sửa"),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  /// ================= HELPERS =================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: kDarkPink,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paragraph(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87),
          children: [
            TextSpan(
              text: "$title: ",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
