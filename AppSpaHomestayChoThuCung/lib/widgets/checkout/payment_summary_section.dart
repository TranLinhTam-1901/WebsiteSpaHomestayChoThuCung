import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Controller/checkout_controller.dart';
import '../../model/Cart/cart_item_model.dart';
import '../../utils/price_utils.dart';

class PaymentSummarySection extends StatelessWidget {
  final List<CartItem> items;
  final CheckoutController controller;

  const PaymentSummarySection({
    super.key,
    required this.items,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (s, i) => s + i.subtotal);

    return Obx(() {
      final promo = controller.selectedPromotion.value;

      double discountAmount = 0;

      if (promo != null) {
        // ✅ phòng hờ: nếu không đủ điều kiện thì không giảm
        final minOk = promo.minOrderValue == null || total >= promo.minOrderValue!;
        final perUserOk =
            promo.maxUsagePerUser == null || promo.userUsedCount < promo.maxUsagePerUser!;
        final globalOk = promo.maxUsage == null ||
            promo.globalUsedCount == null ||
            promo.globalUsedCount! < promo.maxUsage!;

        if (minOk && perUserOk && globalOk) {
          discountAmount = promo.isPercent
              ? total * (promo.discount / 100)
              : promo.discount;

          if (discountAmount > total) discountAmount = total;
        }
      }

      final payTotal = total - discountAmount;

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _row("Tổng tiền hàng", formatPrice(total)),

              if (promo != null && discountAmount > 0)
                _row(
                  "Giảm giá (${promo.code})",
                  "-${formatPrice(discountAmount)}",
                  highlight: true,
                ),

              const Divider(),

              _row(
                "Tổng thanh toán",
                formatPrice(payTotal),
                bold: true,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _row(
      String label,
      String value, {
        bool bold = false,
        bool highlight = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: highlight ? Colors.pink : null,
            ),
          ),
        ],
      ),
    );
  }
}
