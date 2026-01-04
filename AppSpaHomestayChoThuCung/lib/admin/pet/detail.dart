import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../model/pet/pet.dart';
import '../../services/admin_api_service.dart';

class PetDetailScreen extends StatefulWidget {
  final int petId;
  const PetDetailScreen({super.key, required this.petId});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  static const Color pinkPrimary = Color(0xFFFF6185);
  static const Color pinkLight = Color(0xFFFFF0F3);
  static const Color textDark = Color(0xFF2D2D2D);

  Widget _buildPetImage(String? imageUrl) {
    String domain = kIsWeb ? "localhost" : "10.0.2.2";
    String fullUrl = "https://$domain:7051/${imageUrl?.startsWith('/') ?? false ? imageUrl!.substring(1) : imageUrl ?? ""}";

    return Stack(
      children: [
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            color: pinkLight,
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
            child: (imageUrl == null || imageUrl.isEmpty)
                ? const Icon(FontAwesomeIcons.paw, size: 100, color: pinkPrimary)
                : Image.network(fullUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(FontAwesomeIcons.paw, size: 100, color: pinkPrimary)),
          ),
        ),
        // Nút Back đè lên ảnh cho hiện đại
        Positioned(
          top: 40,
          left: 20,
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.9),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: pinkPrimary, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<PetDetail?>(
        future: AdminApiService.getPetDetails(widget.petId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: pinkPrimary));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Không tìm thấy dữ liệu bé"));
          }

          final pet = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildPetImage(pet.imageUrl),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Tên và Tag
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(pet.name ?? "N/A", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textDark)),
                              Text(pet.breed ?? "Chưa rõ giống", style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                            ],
                          ),
                          _buildTag(pet.type ?? "Pet"),
                        ],
                      ),
                      const SizedBox(height: 25),

                      // Quick Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatCard("Tuổi", "${pet.age}", "", FontAwesomeIcons.cakeCandles),
                          _buildStatCard("Cân nặng", "${pet.weight}", "Kg", FontAwesomeIcons.weightScale),
                          _buildStatCard("Giới tính", pet.gender == "Male" ? "Đực" : "Cái", "",
                              pet.gender == "Male" ? FontAwesomeIcons.mars : FontAwesomeIcons.venus),
                        ],
                      ),
                      const SizedBox(height: 30),

                      _buildInfoGroup("THÔNG TIN CHỦ SỞ HỮU", [
                        _buildDetailRow(FontAwesomeIcons.userCheck, "Họ và tên", pet.ownerName),
                        // Nếu bạn đã map ownerPhone và address trong Model PetDetail
                        _buildDetailRow(FontAwesomeIcons.phone, "Số điện thoại", pet.ownerPhone ?? "Chưa có"),
                        _buildDetailRow(FontAwesomeIcons.locationDot, "Địa chỉ", pet.ownerAddress ?? "Chưa cập nhật"),
                      ]),

                      const SizedBox(height: 30),

                      // Group 1: Y tế
                      _buildInfoGroup("HỒ SƠ Y TẾ", [
                        _buildDetailRow(FontAwesomeIcons.syringe, "Tiêm chủng", pet.vaccinationRecords),
                        _buildDetailRow(FontAwesomeIcons.virusSlash, "Dị ứng", pet.allergies),
                        _buildDetailRow(FontAwesomeIcons.notesMedical, "Tiền sử bệnh", pet.medicalHistory),
                        _buildDetailRow(FontAwesomeIcons.calendarDay, "Ngày sinh", pet.dateOfBirth != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(pet.dateOfBirth!)) : "N/A"),
                      ]),

                      const SizedBox(height: 20),

                      // Group 2: Thói quen
                      _buildInfoGroup("ĐẶC ĐIỂM & THÓI QUEN", [
                        _buildDetailRow(FontAwesomeIcons.fingerprint, "Dấu hiệu", pet.distinguishingMarks),
                        _buildDetailRow(FontAwesomeIcons.utensils, "Chế độ ăn", pet.dietPreferences),
                        _buildDetailRow(FontAwesomeIcons.commentMedical, "Ghi chú sức khỏe", pet.healthNotes),
                        _buildDetailRow(FontAwesomeIcons.palette, "Màu sắc", pet.color),
                      ]),

                      const SizedBox(height: 20),

                      // Group 3: AI Analysis (Nổi bật)
                      _buildSectionTitle("AI PHÂN TÍCH CHUYÊN SÂU ✨"),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.blue.shade50, Colors.white]),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Text(
                          pet.aiAnalysisResult ?? "Chưa có dữ liệu từ AI. Hãy cập nhật thông tin để AI phân tích sức khỏe bé tốt hơn.",
                          style: TextStyle(color: Colors.blue.shade900, height: 1.5, fontSize: 15),
                        ),
                      ),

                      const SizedBox(height: 35),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.edit_note, color: Colors.white),
                              label: const Text("CẬP NHẬT HỒ SƠ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: pinkPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                elevation: 5,
                                shadowColor: pinkPrimary.withOpacity(0.4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          _buildDeleteIconBtn(pet.id ?? 0),
                        ],
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildStatCard(String label, String value, String unit, IconData icon) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.28,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: pinkLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pinkPrimary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: pinkPrimary, size: 20),
          const SizedBox(height: 8),
          Text("$value $unit", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildInfoGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, spreadRadius: 2)],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: pinkPrimary.withOpacity(0.7)),
          const SizedBox(width: 12),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600, color: textDark)),
          Expanded(child: Text(value ?? "Chưa có", style: const TextStyle(color: Colors.black54))),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: pinkPrimary, borderRadius: BorderRadius.circular(30)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 12, top: 10),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: pinkPrimary.withOpacity(0.8), letterSpacing: 1.2)),
    );
  }

  Widget _buildDeleteIconBtn(int id) {
    return InkWell(
      onTap: () => _confirmDelete(id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.red.shade100)),
        child: Icon(FontAwesomeIcons.trashCan, color: Colors.red.shade400, size: 20),
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Xác nhận xóa"),
        content: const Text("Dữ liệu của bé sẽ biến mất vĩnh viễn. Bạn chắc chứ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Xóa bé", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}