import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Controller/promotion_controller.dart';
import '../../utils/price_utils.dart';
import '../home_page.dart';

class PromotionVoucherView extends StatelessWidget {
  const PromotionVoucherView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PromotionController>();

    return Obx(() {
      final vouchers = controller.promotions.where((p) =>
      p.image == null ||
          p.image!.isEmpty ||
          p.image == "default-promo.jpg"
      ).toList();


      if (vouchers.isEmpty) return const SizedBox();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ===== TITLE =====
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              "Kho voucher",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          /// ===== VOUCHER LIST =====
          /// ===== VOUCHER LIST (HORIZONTAL) =====
          SizedBox(
            height: 110, // ⚠️ bắt buộc
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: vouchers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                final p = vouchers[index];
                return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      // ✅ Điều hướng về Home và chuyển sang tab Product + lọc theo promotionId
                      Get.offAll(
                            () => HomePage(model: HomeViewModel.demo()),
                        arguments: {
                          'goToTab': 'product',
                          'promotionId': p.id,
                          'promoCode': p.code,// ✅ voucher đang là p
                        },
                      );
                    },
                 child: Container(
                  width: 300, // mỗi ticket
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      /// LEFT DISCOUNT
                      Container(
                        width: 90,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF4D88),
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              p.isPercent
                                  ? "${p.discount.toInt()}%"
                                  : formatPrice(p.discount),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              "OFF",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// CONTENT
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                p.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.shortDescription ?? "",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "HSD: ${_formatDate(p.endDate)}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    "Sử dụng",
                                    style: TextStyle(
                                      color: Colors.pink,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                );
              },
            ),
          ),

        ],
      );

    });
  }

  /// Format date dd/MM
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}";
  }
}
