import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Controller/product_controller.dart';
import '../../model/product_model.dart';
import 'package:intl/intl.dart';

import '../../utils/price_utils.dart';
import '../product/product_detail_page.dart';

class DiscountedProductView extends StatelessWidget {
  const DiscountedProductView({super.key});

  @override
  Widget build(BuildContext context) {
    final productController = Get.find<ProductController>();


    return Obx(() {
      final discountedProducts = productController.products
          .where((p) =>
      p.priceReduced != null &&
          p.priceReduced! > 0 &&
          p.priceReduced! < p.price)
          .toList();

      if (discountedProducts.isEmpty) return const SizedBox();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ===== TITLE =====
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Sản phẩm giảm giá",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 12),

          /// ===== GRID =====
          GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shrinkWrap: true, // 🔥 QUAN TRỌNG
            physics: const NeverScrollableScrollPhysics(),
            itemCount: discountedProducts.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (_, i) {
              final p = discountedProducts[i];

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Get.to(() => ProductDetailPage(productId: p.id));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      /// IMAGE + BADGE
                      Expanded(
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Image.network(
                                  'https://localhost:7051${p.imageUrl}',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image_not_supported),
                                ),
                              ),
                            ),

                            /// DISCOUNT BADGE
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "-${p.discountPercentage}%",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// INFO
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              p.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                              const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),

                            /// 🏷 TRADEMARK
                            Text(
                              p.trademark,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  formatPrice(p.priceReduced!),
                                  style: const TextStyle(
                                    color: Colors.pink,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  formatPrice(p.price),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                    decoration:
                                    TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      );
    });
  }
}