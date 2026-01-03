import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../model/pet/pet.dart'; // Đảm bảo đúng path model của bạn
import 'package:intl/intl.dart'; // Dòng quan trọng để dùng DateFormat
import 'package:flutter/foundation.dart' show kIsWeb;
import 'pet_update.dart';

class PetDetailPage extends StatelessWidget {
  final int petId;

  const PetDetailPage({Key? key, required this.petId}) : super(key: key);

  // 1. Thêm hàm hiển thị ảnh xử lý logic URL
  Widget _buildPetImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Icon(Icons.pets, size: 70, color: Color(0xFFFF6185));
    }

    String cleanPath = imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl;

    // Nếu chạy trên Web dùng localhost, nếu chạy Android dùng 10.0.2.2
    String domain = kIsWeb ? "localhost" : "10.0.2.2";

    // Lưu ý: Port 7051 thường là HTTPS, nếu chạy Web bạn nên thử HTTP (ví dụ 5051)
    // để tránh lỗi Certificate.
    String fullUrl = "https://$domain:7051/$cleanPath";

    debugPrint("Đang tải ảnh trên ${kIsWeb ? 'Web' : 'Mobile'}: $fullUrl");

    return Image.network(
      fullUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.pets, size: 70, color: Color(0xFFFFB6C1));
      },
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "Chưa có";
    try {
      DateTime dt = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (e) {
      return "Chưa có";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F9),
      appBar: AppBar(
        title: const Text("📋 Chi tiết thú cưng",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFFFF6185),
        elevation: 0,
      ),
      body: FutureBuilder<PetDetail?>(
        future: ApiService.getPetDetails(petId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6185)));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Không tìm thấy thông tin thú cưng"));
          }

          final pet = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.pink.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  // --- PHẦN ẢNH ĐÃ SỬA ---
                  Center(
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFFB6C1), width: 4),
                        color: const Color(0xFFFFF0F5),
                      ),
                      child: ClipOval(
                        child: _buildPetImage(pet.imageUrl), // Truyền imageUrl từ API vào
                      ),
                    ),
                  ),
                  // -----------------------
                  const SizedBox(height: 20),
                  Text(pet.name ?? "Chưa có tên",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFF6185))),
                  const Divider(indent: 40, endIndent: 40),

                  _buildSectionHeader("📋", "Thông tin cơ bản"),
                  _buildInfoRow(context, "Tên:", pet.name, "Loại:", pet.type),
                  _buildInfoRow(context, "Giống:", pet.breed, "Giới tính:", pet.gender == "Male" ? "Đực" : "Cái"),

                  _buildInfoRow(
                      context,
                      "Tuổi:",
                      pet.age != null ? "${pet.age} tuổi" : "Chưa có",
                      "Ngày sinh:",
                      _formatDate(pet.dateOfBirth)
                  ),
                  _buildInfoRow(context, "Màu sắc:", pet.color, "Dấu hiệu:", pet.distinguishingMarks),

                  _buildSectionHeader("⚖️", "Thông tin thể chất"),
                  _buildInfoRow(context, "Cân nặng:", "${pet.weight ?? 0} kg", "Chiều cao:", "${pet.height ?? 0} cm"),

                  _buildSectionHeader("🩺", "Thông tin sức khỏe"),
                  _buildFullWidthInfo("Hồ sơ tiêm phòng:", pet.vaccinationRecords),
                  _buildFullWidthInfo("Tiền sử bệnh:", pet.medicalHistory),
                  _buildFullWidthInfo("Dị ứng:", pet.allergies ?? "Không có"),
                  _buildFullWidthInfo("Chế độ ăn:", pet.dietPreferences ?? "Không có"),
                  _buildFullWidthInfo("Ghi chú sức khỏe:", pet.healthNotes),

                  _buildSectionHeader("🤖", "Kết quả phân tích AI"),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Text(pet.aiAnalysisResult ?? "Chưa được phân tích",
                        style: TextStyle(color: Colors.blue.shade900)),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade500,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                          ),
                          child: const Text("← Quay lại", style: TextStyle(color: Colors.white)),
                        ),
                        // Nút Sửa: Ở đây bạn nên dùng Navigator.push sang trang PetUpdatePage
                        ElevatedButton(
                          onPressed: () async {
                            final pet = snapshot.data!;

                            // Chuyển Model thành Map và gán thêm petId
                            final petMap = pet.toMap();
                            petMap['petId'] = petId;

                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => PetUpdatePage(pet: petMap)),
                            );

                            if (result == true) {
                              // Load lại trang chi tiết
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => PetDetailPage(petId: petId)),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text("🛠️ Sửa", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET HELPERS (Giữ nguyên hoặc cập nhật như dưới) ---

  Widget _buildSectionHeader(String icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, top: 20, bottom: 10),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label1, String? val1, String label2, String? val2) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Row(
        children: [
          Expanded(child: _richTextItem(label1, val1)),
          Expanded(child: _richTextItem(label2, val2)),
        ],
      ),
    );
  }

  Widget _buildFullWidthInfo(String label, String? val) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _richTextItem(label, val),
      ),
    );
  }

  Widget _richTextItem(String label, String? val) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black87, fontSize: 14),
        children: [
          TextSpan(text: "$label ", style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: (val == null || val.isEmpty) ? "Chưa có" : val),
        ],
      ),
    );
  }
}