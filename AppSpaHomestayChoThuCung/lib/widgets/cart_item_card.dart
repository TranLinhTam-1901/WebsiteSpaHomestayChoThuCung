import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controller/cart_controller.dart';
import '../model/Cart/cart_item_model.dart';
import 'package:intl/intl.dart';

import '../utils/price_utils.dart';

class CartItemCard extends StatelessWidget {
  final CartItem item;
  const CartItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CartController>();

    return Opacity(
      opacity: item.isOutOfStock ? 0.6 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F1F1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ CHECKBOX
            Obx(() => Checkbox(
              value: controller.isSelected(item.cartItemId),
              onChanged: item.isOutOfStock
                  ? null
                  : (_) => controller.toggleSelect(item.cartItemId),
              activeColor: const Color(0xFFEE2B5B),
            )),

            // IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                'https://localhost:7051${item.imageUrl}',
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    width: 88,
                    height: 88,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image),
                  );
                },
              ),

            ),

            const SizedBox(width: 12),

            // INFO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        color: Colors.grey,
                        onPressed: () =>
                            controller.removeItem(item.cartItemId),
                      )
                    ],
                  ),

                  Text(
                    item.variantName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                       formatPrice(item.price),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEE2B5B),
                        ),
                      ),

                      if (!item.isOutOfStock)
                        _QuantityBox(item: item),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _QuantityBox extends StatelessWidget {
  final CartItem item;
  const _QuantityBox({required this.item});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CartController>();

    return Container(
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          _btn(Icons.remove, () {
            if (item.quantity > 1) {
              controller.updateQty(
                item.cartItemId,
                item.quantity - 1,
              );
            }
          }),
          SizedBox(
            width: 32,
            child: Center(
              child: Text(
                item.quantity.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          _btn(Icons.add, () {
            if (item.quantity < item.stockAvailable) {
              controller.updateQty(
                item.cartItemId,
                item.quantity + 1,
              );
            }
          }),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 32,
        child: Icon(icon, size: 18, color: Colors.grey),
      ),
    );
  }
}
