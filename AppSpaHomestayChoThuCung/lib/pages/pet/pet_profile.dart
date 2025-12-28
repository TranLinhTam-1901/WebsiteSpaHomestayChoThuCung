import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Controller/pet_controller.dart';
import 'pet_add.dart';
import 'pet_update.dart';
import 'pet_delete.dart';
import 'pet_detail.dart';

const kDarkPink = Color(0xFFFF6185);
const kPrimaryPink = Color(0xFFFFB6C1);
const kBackgroundPink = Color(0xFFFFF0F5);

class PetProfilePage extends StatelessWidget {
  PetProfilePage({Key? key}) : super(key: key);

  final controller = Get.put(PetController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundPink,
      appBar: AppBar(
        backgroundColor: kPrimaryPink,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Hồ sơ thú cưng",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          /// ➕ THÊM THÚ CƯNG
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () {
              Get.to(() => const PetAddPage());
            },
          ),
        ],
      ),

      body: Obx(() {
        if (controller.pets.isEmpty) {
          return const Center(
            child: Text(
              "Chưa có thú cưng nào 🐶🐱",
              style: TextStyle(color: Colors.black54),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.pets.length,
          itemBuilder: (context, index) {
            final pet = controller.pets[index];
            return _petCard(pet, index); // ✅ bây giờ pet là Pet object
          },
        );

      }),
    );
  }

  void _confirmDelete(int index) {
    // Lấy Pet từ controller
    final pet = controller.pets[index];

    // Hiển thị dialog xác nhận
    Get.defaultDialog(
      title: "Xác nhận xóa",
      middleText: "Bạn có chắc muốn xóa \"${pet.name}\" không?",
      textCancel: "Hủy",
      textConfirm: "Xóa",
      confirmTextColor: Colors.white,
      onConfirm: () {
        controller.deletePetByIndex(index);
        Get.back(); // đóng dialog
      },
    );
  }

  /// =======================
  /// 🐾 PET CARD
  /// =======================
  Widget _petCard(Pet pet, int index) {
    String genderText = pet.gender == "male"
        ? "Đực"
        : pet.gender == "female"
        ? "Cái"
        : "Không rõ";

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: kPrimaryPink,
                  child: Icon(Icons.pets, color: Colors.black),
                ),
                const SizedBox(width: 12),
                Text(
                  pet.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow("Loại", pet.type),
            _infoRow("Giống", pet.breed),
            _infoRow("Cân nặng", "${pet.weight} kg"),
            _infoRow("Giới tính", genderText),
            _infoRow(
              "Ngày sinh",
                "${pet.dateOfBirth?.day ?? '-'}"
                    "/${pet.dateOfBirth?.month ?? '-'}"
                    "/${pet.dateOfBirth?.year ?? '-'}"

            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _actionButton(
                  icon: Icons.info,
                  label: "Chi tiết",
                  color: kDarkPink,
                  onTap: () {
                    final pet = controller.pets[index];
                    Get.to(() => PetDetailPage(pet: pet));
                  },
                ),

                _actionButton(
                  icon: Icons.edit,
                  label: "Sửa",
                  color: Colors.green,
                  onTap: () {
                    final pet = controller.pets[index];
                    Get.to(() => PetUpdatePage(pet: pet, index: index));
                  },
                ),

                _actionButton(
                  icon: Icons.delete,
                  label: "Xóa",
                  color: Colors.red,
                  onTap: () {
                    // Lấy Map<String, dynamic> từ controller
                    final pet = controller.pets[index];
                    // Chuyển sang trang xóa
                    Get.to(() => PetDeletePage(pet: pet, index: index));
                  },
                ),
              ],
            ),
          ],
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
            child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 5,
            child: Text(value, style: const TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
