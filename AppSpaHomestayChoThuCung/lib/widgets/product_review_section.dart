import 'package:baitap1/widgets/write_review_page.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Controller/review_controller.dart';
import '../Controller/product_detail_controller.dart';
import 'package:intl/intl.dart';

class ProductReviewSection extends StatefulWidget {
  const ProductReviewSection({super.key});

  @override
  State<ProductReviewSection> createState() => _ProductReviewSectionState();
}

class _ProductReviewSectionState extends State<ProductReviewSection> {
  bool showAll = false;

  String formatDateTime(DateTime time) {
    return DateFormat('dd/MM/yyyy HH:mm').format(time);
  }

  @override
  Widget build(BuildContext context) {

    return GetX<ReviewController>(
      builder: (rc) {
        final reviews = rc.reviews;
        final visibleReviews =
        showAll ? reviews : reviews.take(3).toList();


        if (rc.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// ===== HEADER =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Đánh giá & Nhận xét",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// ===== SUMMARY + CTA =====
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// SCORE BOX (FIX)
                Container(
                  constraints: const BoxConstraints(minWidth: 100),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        rc.averageRating.value.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          5,
                              (i) => Icon(
                            i < rc.averageRating.value.round()
                                ? Icons.star
                                : Icons.star_border,
                            size: 16,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${rc.totalReviews.value} đánh giá",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                /// CTA
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Chia sẻ trải nghiệm của bạn về sản phẩm này.",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final p = Get.find<ProductDetailController>().product.value!;

                            Get.to(() => WriteReviewPage(
                              productId: p.id,
                              productName: p.name,
                              productImage: p.images.isNotEmpty ? p.images.first : null,
                              optionText: p.optionGroups.isNotEmpty
                                  ? p.optionGroups.first.name
                                  : null,
                            ));
                          },



                          icon: const Icon(Icons.edit, color: Colors.pink),
                          label: const Text(
                            "Viết đánh giá",
                            style: TextStyle(
                              color: Colors.pink,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.pink.withOpacity(0.08),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            /// ===== COMMENT LIST =====
            if (rc.reviews.isEmpty)
              const Text(
                "Chưa có đánh giá nào",
                style: TextStyle(color: Colors.grey),
              ),
            ...visibleReviews.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 24),

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// AVATAR (FIX)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.pink.shade100,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      r.userName.isNotEmpty
                          ? r.userName[0].toUpperCase()
                          : "?",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// CONTENT
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// 👤 USER NAME (TRÁI)
                            Expanded(
                              child: Text(
                                r.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            /// 🕒 TIME (PHẢI)
                            Text(
                              formatDateTime(r.createdDate),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: List.generate(
                            5,
                                (i) => Icon(
                              i < r.rating
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 14,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(r.comment),
                        if (r.images.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 64,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: r.images.map((img) {
                                return Padding(
                                  padding:
                                  const EdgeInsets.only(right: 8),
                                  child: ClipRRect(
                                    borderRadius:
                                    BorderRadius.circular(8),
                                    child: Image.network(
                                      "https://localhost:7051$img",
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            )),
            /// ===== XEM TẤT CẢ / THU GỌN =====
            if (reviews.length > 3)
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      showAll = !showAll;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        showAll ? "Thu gọn" : "Xem tất cả đánh giá",
                        style: const TextStyle(
                          color: Colors.pink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        showAll
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.pink,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
