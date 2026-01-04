import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../model/pet/pet.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'pet_update.dart';

// Hằng số màu sắc đồng bộ toàn app
const kLightPink = Color(0xFFFFB6C1);
const kPrimaryPink = Color(0xFFFF6185);
const kBackgroundLight = Color(0xFFF9F9F9);

class PetDetailPage extends StatelessWidget {
  final int petId;

  const PetDetailPage({super.key, required this.petId});

  // Hàm xử lý ảnh chuyên nghiệp hơn
  Widget _buildPetImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: kLightPink.withOpacity(0.1),
        child: const Icon(Icons.pets, size: 60, color: kPrimaryPink),
      );
    }
    String cleanPath = imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl;
    String domain = kIsWeb ? "localhost" : "10.0.2.2";
    String fullUrl = "https://$domain:7051/$cleanPath";

    return Image.network(
      fullUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: kLightPink.withOpacity(0.1),
        child: const Icon(Icons.pets, size: 60, color: kPrimaryPink),
      ),
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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: kBackgroundLight,
      appBar: AppBar(
        title: const Text("Hồ sơ chi tiết",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: Colors.black)),
        backgroundColor: kLightPink,
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: FutureBuilder<PetDetail?>(
        future: ApiService.getPetDetails(petId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kLightPink));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Không tìm thấy thông tin"));
          }

          final pet = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                // 1. AVATAR & TÊN CHÍNH
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.pinkAccent, width: 5),
                          boxShadow: [
                            BoxShadow(color: kLightPink.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                          ],
                        ),
                        child: ClipOval(child: _buildPetImage(pet.imageUrl)),
                      ),
                      const SizedBox(height: 12),
                      Text(pet.name ?? "Chưa đặt tên",
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Text("${pet.type} • ${pet.breed}",
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // 2. CARD THÔNG TIN CƠ BẢN
                _buildDetailCard(
                  title: "Thông tin cơ bản",
                  icon: Icons.badge_outlined,
                  content: Column(
                    children: [
                      _infoRow("Giới tính", pet.gender == "Male" ? "Đực" : "Cái"),
                      _infoRow("Tuổi", pet.age != null ? "${pet.age} tuổi" : "Chưa có"),
                      _infoRow("Ngày sinh", _formatDate(pet.dateOfBirth)),
                      _infoRow("Màu sắc", pet.color ?? "Chưa có"),
                      _infoRow("Cân nặng", "${pet.weight ?? 0} kg"),
                      _infoRow("Chiều cao", "${pet.height ?? 0} cm"),
                    ],
                  ),
                ),

                // 3. CARD SỨC KHỎE
                _buildDetailCard(
                  title: "Tình trạng sức khỏe",
                  icon: Icons.health_and_safety_outlined,
                  content: Column(
                    children: [
                      _infoRow("Dấu hiệu", pet.distinguishingMarks ?? "Không có"),
                      _infoRow("Tiêm phòng", pet.vaccinationRecords ?? "Chưa cập nhật"),
                      _infoRow("Tiền sử bệnh", pet.medicalHistory ?? "Không có"),
                      _infoRow("Dị ứng", pet.allergies ?? "Không có"),
                      _infoRow("Chế độ ăn", pet.dietPreferences ?? "Không có"),
                      _infoRow("Ghi chú sức khỏe", pet.healthNotes ?? "Không có"),
                    ],
                  ),
                ),

                // 4. KẾT QUẢ AI (NỔI BẬT)
                _buildDetailCard(
                  title: "Phân tích AI",
                  icon: Icons.auto_awesome_outlined,
                  color: Colors.blue.shade50,
                  content: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      pet.aiAnalysisResult ?? "Dữ liệu đang được hệ thống phân tích...",
                      style: TextStyle(color: Colors.blue.shade900, height: 1.5, fontSize: 13),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 5. NÚT THAO TÁC
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDelete(context, petId),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text("Xóa hồ sơ"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final petDetail = snapshot.data!;
                          final petMap = petDetail.toMap();
                          petMap['petId'] = petId;
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => PetUpdatePage(pet: petMap)),
                          );
                          if (result == true) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => PetDetailPage(petId: petId)),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryPink,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Chỉnh sửa", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // Hàm xử lý xóa hồ sơ
  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Xác nhận xóa?"),
        content: const Text("Hồ sơ thú cưng sẽ bị xóa vĩnh viễn và không thể hoàn tác."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy")
          ),
          TextButton(
              onPressed: () async {
                Navigator.pop(context); // Đóng dialog xác nhận

                // 1. Hiển thị loading nhẹ hoặc chặn người dùng bấm nhiều lần
                bool success = await ApiService.deletePet(id);

                if (success) {
                  if (context.mounted) {
                    // 2. Thông báo xóa thành công
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Đã xóa hồ sơ thú cưng")),
                    );
                    // 3. Quay lại trang danh sách và gửi kèm tín hiệu 'true'
                    Navigator.pop(context, true);
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Lỗi: Không thể xóa hồ sơ")),
                    );
                  }
                }
              },
              child: const Text("Xóa ngay", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  // --- WIDGET CẤU TRÚC CARD ---
  Widget _buildDetailCard({required String title, required IconData icon, required Widget content, Color? color}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: kPrimaryPink),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const Divider(height: 24),
          content,
        ],
      ),
    );
  }

  // --- DÒNG THÔNG TIN GỌN GÀNG ---
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              (value.isEmpty || value == "null") ? "Chưa có" : value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}