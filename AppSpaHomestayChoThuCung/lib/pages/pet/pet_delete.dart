import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Controller/pet_controller.dart';

class PetDeletePage extends StatelessWidget {
  final Pet pet;
  final int index;

  const PetDeletePage({Key? key, required this.pet, required this.index}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PetController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Xác nhận xóa"),
        backgroundColor: Colors.redAccent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ảnh thú cưng
              if (pet.imageUrl != null && pet.imageUrl!.isNotEmpty)
                CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage(pet.imageUrl!),
                )
              else
                const CircleAvatar(
                  radius: 60,
                  child: Icon(Icons.pets, size: 50),
                ),
              const SizedBox(height: 16),
              // Text xác nhận
              Text(
                "Bạn có chắc muốn xóa '${pet.name}' không?",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              // Nút hành động
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      controller.deletePetByIndex(index);
                      Get.back(); // quay lại danh sách
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text("Xóa"),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text("Hủy"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
