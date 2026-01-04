import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../Controller/review_controller.dart';

import '../../Controller/product_detail_controller.dart';
import '../../widgets/product_review_section.dart';



class ProductDetailPage extends StatelessWidget {
  final int productId;

  ProductDetailPage({super.key, required this.productId}) {
    final controller = Get.put(ProductDetailController());
    controller.fetchDetail(productId);
    Get.put(ReviewController()).load(productId);
  }

  String formatPrice(num price) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(price)}đ';
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProductDetailController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
        centerTitle: true,
      ),

      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final p = controller.product.value!;
        return CustomScrollView(
          slivers: [

            /// 🖼 IMAGE SLIDER
            SliverToBoxAdapter(
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: PageView.builder(
                  itemCount: p.images.length,
                  itemBuilder: (_, index) {
                    return Image.network(
                      'https://localhost:7051${p.images[index]}',
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
            ),

            /// 📦 INFO
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.trademark,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),

                    /// 💰 PRICE
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatPrice(p.priceReduced ?? p.price),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink,
                          ),
                        ),
                        if (p.priceReduced != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            formatPrice(p.price),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(

                              "${p.discountPercentage.toStringAsFixed(0)}%",
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        ]
                      ],
                    ),
                  ],
                ),
              ),
            ),

            /// 🧩 OPTION GROUPS
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final group in p.optionGroups) ...[
                      const SizedBox(height: 16),
                      Text(
                        group.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: group.values.map((v) {
                          return ChoiceChip(
                            label: Text(v.value),
                            selected: false,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            /// 📝 DESCRIPTION
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const Text(
                      'Mô tả sản phẩm',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p.description ?? '',
                      style: const TextStyle(
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ProductReviewSection(),
              ),
            ),

            /// khoảng trống cho bottom bar
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        );
      }),

      /// 🛒 BOTTOM CTA
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {},
            child: const Text(
              'Mua ngay',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
