import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import '../../Controller/checkout_controller.dart';
import '../../model/Cart/cart_item_model.dart';
import '../../utils/price_utils.dart';
import 'package:get/get.dart';
import '../../Controller/checkout_controller.dart';

class BottomCheckoutBar extends StatelessWidget {
  final List<CartItem> items;

  const BottomCheckoutBar({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (s, i) => s + i.subtotal);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: const [
          BoxShadow(blurRadius: 8, color: Colors.black12),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tổng cộng",
                    style: TextStyle(color: Colors.grey)),
                Text(
                  formatPrice(total),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final checkout = Get.find<CheckoutController>();
              await checkout.placeOrder(items: items); // ✅ gọi API checkout ở controller
            },
            child: const Text("Đặt hàng"),
          ),
        ],
      ),
    );
  }
}
