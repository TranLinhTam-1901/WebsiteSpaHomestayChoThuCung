import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../Controller/cart_controller.dart';
import '../../Controller/review_controller.dart';

import '../../Controller/product_detail_controller.dart';
import '../../utils/price_utils.dart';
import '../../widgets/product_review_section.dart';
import '../shopping_cart/shopping_cart_page.dart';
import '../utils/price_utils.dart';



class ProductDetailPage extends StatelessWidget {
  final int productId;

  final productController = Get.put(ProductDetailController());
  final cartController = Get.put(CartController());

  ProductDetailPage({super.key, required this.productId}) {
    // final controller = Get.put(ProductDetailController());
    productController.fetchDetail(productId);
    Get.put(ReviewController()).load(productId);

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

        final p = controller.product.value;
        if (p == null) {
          return const Center(child: Text("Đang tải sản phẩm..."));
        }

        return CustomScrollView(

        slivers: [

            /// 🖼 IMAGE SLIDER
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 🔳 Card ảnh (bo góc + shadow)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AspectRatio(
                          aspectRatio: 4 / 5,
                          child: PageView.builder(
                            itemCount: p.images.length,
                            onPageChanged: (index) {
                              controller.currentImageIndex.value = index;
                            },
                            itemBuilder: (_, index) {
                              return Image.network(
                                'https://localhost:7051${p.images[index]}',
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 🔘 DOT INDICATOR
                    Obx(() {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          p.images.length,
                              (index) {
                            final isActive =
                                controller.currentImageIndex.value == index;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: isActive ? 10 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFFE91E63) // màu hồng như hình
                                    : Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ],

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


                    const SizedBox(height: 8),

                    /// 📦 STOCK STATUS (gộp cho cả có & không biến thể)
                    // Obx(() {
                    //   // CASE 1: KHÔNG có biến thể
                    //   final p = controller.product.value;
                    //   if (p == null) return const SizedBox();
                    //
                    //   // 🔹 KHÔNG có biến thể
                    //   if (p.variants.isEmpty) {
                    //     final stock = p.stockQuantity;
                    //     return Text(
                    //       controller.stockText(stock),
                    //       style: TextStyle(
                    //         fontSize: 13,
                    //         fontWeight: FontWeight.w600,
                    //         color: stock <= 5 ? Colors.red : Colors.green,
                    //       ),
                    //     );
                    //   }
                    //
                    //   // 🔹 CÓ biến thể
                    //   final v = controller.selectedVariant.value;
                    //   if (v == null) {
                    //     return const Text(
                    //       "Vui lòng chọn phân loại",
                    //       style: TextStyle(fontSize: 13, color: Colors.grey),
                    //     );
                    //   }
                    //
                    //   return Text(
                    //     controller.stockText(v.stockQuantity),
                    //     style: TextStyle(
                    //       fontSize: 13,
                    //       fontWeight: FontWeight.w600,
                    //       color: v.stockQuantity <= 5 ? Colors.red : Colors.green,
                    //     ),
                    //   );
                    // }),
                    /// ✅ Ẩn tồn kho, chỉ nhắc chọn phân loại nếu có biến thể
                    Obx(() {
                      final p = controller.product.value;
                      if (p == null) return const SizedBox();

                      if (p.variants.isNotEmpty && controller.selectedVariant.value == null) {
                        return const Text(
                          "Vui lòng chọn phân loại",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        );
                      }

                      return const SizedBox.shrink();
                    }),


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
                          return Obx(() {
                            final isSelected =
                                controller.selectedOptions[group.name] == v.value;
                            return ChoiceChip(
                              label: Text(v.value),
                              selected: isSelected,
                              showCheckmark: false,
                              selectedColor: Colors.pink.withOpacity(0.15),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.pink : Colors.black,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  controller.selectOption(group.name, v.value);
                                }
                              },
                            );
                          });
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

      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),

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
        child: Obx(() {
          final p = controller.product.value;
          if (p == null) return const SizedBox();

          final hasVariants = p.variants.isNotEmpty;
          final v = controller.selectedVariant.value;

          // ✅ Chỉ bắt buộc chọn phân loại (nếu có variants)
          final canBuy = (!hasVariants || v != null);

          return Row(
            children: [
              /// 🔢 CHỌN SỐ LƯỢNG
              Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.grey.shade100,
                ),
                child: Row(
                  children: [
                    _qtyBtn(
                      icon: Icons.remove,
                      onTap: controller.decreaseQty,
                    ),
                    SizedBox(
                      width: 36,
                      child: Center(
                        child: Text(
                          controller.quantity.value.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    _qtyBtn(
                      icon: Icons.add,
                      // ✅ tạm không giới hạn theo stock (vì bạn muốn bỏ kho)
                      onTap: () => controller.increaseQty(999999),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              /// 🛒 THÊM VÀO GIỎ
              SizedBox(
                height: 48,
                width: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.withOpacity(0.1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: canBuy && !cartController.isLoading.value
                      ? () async {
                    final ok = await cartController.addToCart(
                      productId: p.id,
                      quantity: controller.quantity.value,
                      variantId: controller.selectedVariant.value?.id,
                    );

                    if (!ok) {
                      Get.snackbar(
                        "Thêm thất bại",
                        "Số lượng trong kho không đủ (hãy thử giảm số lượng)",
                        snackPosition: SnackPosition.BOTTOM,
                      );
                      return; // ✅ STOP, không chuyển giỏ, không hiện success
                    }

                    Get.snackbar(
                      "Thành công",
                      "Đã thêm sản phẩm vào giỏ",
                      snackPosition: SnackPosition.BOTTOM,
                    );

                    Get.to(() => CartPage());
                  }
                      : null,

                  child: const Icon(
                    Icons.add_shopping_cart,
                    color: Colors.pink,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              /// 🛍️ MUA NGAY
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canBuy ? Colors.pink : Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: canBuy
                        ? () {
                      final cartController = Get.find<CartController>();
                      cartController.buyNow(
                        productId: p.id,
                        quantity: controller.quantity.value,
                        variantId: controller.selectedVariant.value?.id,
                      );
                    }
                        : null,
                    child: const Text(
                      'Mua ngay',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),

      ),


    );
  }
}
Widget _qtyBtn({
  required IconData icon,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: SizedBox(
      width: 40,
      height: 48,
      child: Icon(
        icon,
        size: 20,
        color: Colors.grey.shade700,
      ),
    ),
  );
}
