import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/checkout_controller.dart';

class AddressSection extends StatelessWidget {
  AddressSection({super.key});

  final CheckoutController controller = Get.find<CheckoutController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final p = controller.profile.value;
      if (p == null) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text("Đang tải địa chỉ..."),
          ),
        );
      }

      // ✅ ĐẶT Ở ĐÂY – ĐÚNG VỊ TRÍ
      final hasAddress = p.address.trim().isNotEmpty;

      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.pink),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      "Địa chỉ nhận hàng",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _showEditAddressSheet(context, controller);
                    },
                    child: const Text("Thay đổi"),
                  ),
                ],
              ),
              const Divider(),

              // ✅ DÙNG BIẾN Ở ĐÂY
              if (!hasAddress) ...[
                const Text(
                  "Chưa có địa chỉ nhận hàng",
                  style: TextStyle(color: Colors.redAccent),
                ),
              ] else ...[
                Text(
                  "${p.fullName} | ${p.phone}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  p.address,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      );
    });

  }

  void _showEditAddressSheet(
      BuildContext context,
      CheckoutController controller,
      ) {
    final p = controller.profile.value!;
    final nameCtrl = TextEditingController(text: p.fullName);
    final phoneCtrl = TextEditingController(text: p.phone);
    final addressCtrl = TextEditingController(text: p.address);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Cập nhật địa chỉ nhận hàng",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Họ tên"),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: "Số điện thoại"),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),

              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: "Địa chỉ"),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      child: const Text("Hủy"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (addressCtrl.text.trim().isEmpty) {
                          Get.snackbar(
                            "Thiếu địa chỉ",
                            "Vui lòng nhập địa chỉ nhận hàng",
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          return;
                        }

                        await controller.updateUserProfile(
                          fullName: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          address: addressCtrl.text.trim(),
                        );

                        if (Get.isBottomSheetOpen == true) {
                          Get.until((route) => !Get.isBottomSheetOpen!);
                        }
                      },

                      child: const Text("Lưu"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

}
