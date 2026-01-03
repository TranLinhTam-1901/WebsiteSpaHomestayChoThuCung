import 'package:baitap1/pages/promotion/promotionDetailPage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Controller/promotion_controller.dart';

class PromotionBannerView extends StatelessWidget {
  const PromotionBannerView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PromotionController>();

    return Obx(() {
      // 🔹 Chỉ lấy promotion có ảnh
      final banners = controller.promotions
          .where((p) =>
          p.image != null &&
          p.image!.isNotEmpty &&
              p.image != "default-promo.jpg"
      )
          .toList();

      if (banners.isEmpty) return const SizedBox();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ===== TITLE =====
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Nổi bật",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 12),

          /// ===== HORIZONTAL BANNER LIST =====
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: banners.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final p = banners[i];

                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Get.to(() => PromotionDetailPage(
                      promotion: p, // ✅ truyền promotion hiện tại
                    ));
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        /// IMAGE
                        Image.network(
                          "https://localhost:7051/images/promotions/${p.image}",
                          width: 320,
                          height: 180,
                          fit: BoxFit.cover,
                        ),

                        /// OVERLAY GRADIENT
                        Container(
                          width: 320,
                          height: 180,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.65),
                              ],
                            ),
                          ),
                        ),

                        /// HOT DEAL BADGE
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.pink,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "HOT DEAL",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        /// TEXT INFO
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.shortDescription ?? "",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
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
          ),
        ],
      );
    });
  }
}
