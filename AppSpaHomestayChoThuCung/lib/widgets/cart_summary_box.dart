import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import '../controller/cart_controller.dart';
import '../model/Cart/cart_response_model.dart';
import '../utils/price_utils.dart';

class CartSummaryBox extends StatelessWidget {
  final CartResponse cart;
  const CartSummaryBox({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CartController>();
    return Obx(() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F1F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Chi tiết thanh toán",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _row(
            "Tổng tiền hàng (${controller.selectedTotalQuantity} sản phẩm)",
            formatPrice(controller.selectedTotalAmount),
          ),
          // const SizedBox(height: 8),
          // 🔹 PHƯƠNG THỨC THANH TOÁN (COD)
          // _row(
          //   "Phương thức thanh toán",
          //   "COD",
          // ),


          const Divider(height: 24),

          _row(
            "Tổng thanh toán",
            formatPrice(controller.selectedTotalAmount),
            bold: true,
            valueColor: const Color(0xFFEE2B5B),
          ),
        ],
      ),
    );
    });
  }

  Widget _row(
      String label,
      String value, {
        bool bold = false,
        Color? valueColor,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
