import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Controller/cart_controller.dart';

const kPrimaryPink = Color(0xFFFFB6C1);
const kBackgroundPink = Color(0xFFFFF0F5);

/// ================= PAGE =================
class ShoppingCartPage extends StatelessWidget {
  ShoppingCartPage({super.key});

  final CartController controller = Get.put(CartController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundPink,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kPrimaryPink,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Giỏ hàng",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      /// 👇 THIẾU BODY Ở ĐÂY
      body: Obx(() {
        if (controller.cartItems.isEmpty) {
          return const Center(
            child: Text(
              "🛍️ Giỏ hàng của bạn đang trống",
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        return Column(
          children: [
            _selectAllRow(),
            Expanded(child: _cartList()),
            _summarySection(),
          ],
        );
      }),
    );
  }

  /// ================= UI FUNCTIONS =================

  Widget _selectAllRow() {
    return Obx(() => CheckboxListTile(
      value: controller.isAllSelected,
      onChanged: (v) => controller.toggleAll(v ?? true),
      title: const Text(
        "Chọn tất cả",
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      activeColor: kPrimaryPink,
      controlAffinity: ListTileControlAffinity.leading,
    ));
  }

  Widget _cartList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: controller.cartItems.length,
      itemBuilder: (context, index) {
        final item = controller.cartItems[index];
        return _cartItem(item);
      },
    );
  }

  Widget _cartItem(CartItem item) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Checkbox(
              value: item.selected,
              onChanged: (v) {
                item.selected = v ?? true;
                controller.cartItems.refresh();
              },
              activeColor: kPrimaryPink,
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    "Hương vị: ${item.flavor}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${item.unitPrice.toStringAsFixed(0)}đ",
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      _qtyButton(Icons.remove, () =>
                          controller.updateQuantity(item, item.quantity - 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          item.quantity.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      _qtyButton(Icons.add, () =>
                          controller.updateQuantity(item, item.quantity + 1)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${item.total.toStringAsFixed(0)}đ",
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  onPressed: () => controller.removeItem(item.id),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: kPrimaryPink),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }

  Widget _summarySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, -2),
          )
        ],
      ),
      child: Column(
        children: [
          Obx(() => Text(
            "Tổng đã chọn: ${controller.totalSelected.toStringAsFixed(0)}đ",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          )),
          const SizedBox(height: 4),
          Obx(() => Text(
            "Tổng giỏ hàng: ${controller.totalOverall.toStringAsFixed(0)}đ",
            style: const TextStyle(color: Colors.grey),
          )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryPink,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {},
              child: const Text(
                "Thanh toán",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}