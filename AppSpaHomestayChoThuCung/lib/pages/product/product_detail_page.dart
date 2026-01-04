import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/cart_controller.dart';
import '../../controller/review_controller.dart';
import '../../controller/product_detail_controller.dart';
import '../../utils/price_utils.dart';
import '../../widgets/product_review_section.dart';

class ProductDetailPage extends StatelessWidget {
  final int productId;

  // Khởi tạo các controller một lần duy nhất tại constructor
  ProductDetailPage({super.key, required this.productId}) {
    Get.put(ProductDetailController());
    Get.put(CartController());
    Get.put(ReviewController()).load(productId);

    // Gọi fetch dữ liệu ngay khi vào trang
    Get.find<ProductDetailController>().fetchDetail(productId);
  }

  @override
  Widget build(BuildContext context) {
    // Truy xuất các instance đã tồn tại
    final controller = Get.find<ProductDetailController>();
    final cartController = Get.find<CartController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
        centerTitle: true,
      ),
      body: Obx(() {
        // --- TRẠNG THÁI LOADING ---
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final p = controller.product.value;
        if (p == null) {
          return const Center(child: Text("Không tìm thấy sản phẩm"));
        }

        return CustomScrollView(
          slivers: [
            /// 🖼 IMAGE SLIDER & INDICATOR
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
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
                            onPageChanged: (index) => controller.currentImageIndex.value = index,
                            itemBuilder: (_, index) {
                              return Image.network(
                                'https://localhost:7051${p.images[index]}',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported, size: 50),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Dot Indicator (Không cần Obx riêng vì đã nằm trong Obx body)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(p.images.length, (index) {
                        final isActive = controller.currentImageIndex.value == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 10 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isActive ? Colors.pink : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),

            /// 📦 THÔNG TIN TÊN & GIÁ
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(p.trademark, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatPrice(p.priceReduced ?? p.price),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.pink),
                        ),
                        if (p.priceReduced != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            formatPrice(p.price),
                            style: const TextStyle(fontSize: 14, color: Colors.grey, decoration: TextDecoration.lineThrough),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Nhắc chọn phân loại
                    if (p.variants.isNotEmpty && controller.selectedVariant.value == null)
                      const Text(
                        "Vui lòng chọn phân loại",
                        style: TextStyle(fontSize: 13, color: Colors.redAccent, fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
              ),
            ),

            /// 🧩 OPTION GROUPS (Phân loại sản phẩm)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final group in p.optionGroups) ...[
                      const SizedBox(height: 16),
                      Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: group.values.map((v) {
                          final isSelected = controller.selectedOptions[group.name] == v.value;
                          return ChoiceChip(
                            label: Text(v.value),
                            selected: isSelected,
                            selectedColor: Colors.pink.withOpacity(0.15),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.pink : Colors.black,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              if (selected) controller.selectOption(group.name, v.value);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            /// 📝 MÔ TẢ & REVIEW
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const Text('Mô tả sản phẩm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(p.description ?? 'Chưa có mô tả', style: const TextStyle(color: Colors.grey, height: 1.5)),
                    const SizedBox(height: 20),
                    ProductReviewSection(),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        );
      }),
      bottomNavigationBar: _buildBottomBar(controller, cartController),
    );
  }

  /// 🛒 BOTTOM BAR (Tách ra để dễ quản lý)
  Widget _buildBottomBar(ProductDetailController controller, CartController cartController) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -4))],
      ),
      child: Obx(() {
        final p = controller.product.value;
        if (p == null) return const SizedBox.shrink();

        final hasVariants = p.variants.isNotEmpty;
        final v = controller.selectedVariant.value;
        final canBuy = (!hasVariants || v != null);

        return Row(
          children: [
            // Nút chọn số lượng
            Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.grey.shade100,
              ),
              child: Row(
                children: [
                  _qtyBtn(icon: Icons.remove, onTap: controller.decreaseQty),
                  SizedBox(
                    width: 36,
                    child: Center(child: Text("${controller.quantity.value}", style: const TextStyle(fontWeight: FontWeight.bold))),
                  ),
                  _qtyBtn(icon: Icons.add, onTap: () => controller.increaseQty(999)),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Nút Thêm vào giỏ
            SizedBox(
              height: 48, width: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.withOpacity(0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: (canBuy && !cartController.isLoading.value) ? () async {
                  final ok = await cartController.addToCart(
                    productId: p.id,
                    quantity: controller.quantity.value,
                    variantId: v?.id,
                  );
                  if (ok) {
                    Get.snackbar("Thành công", "Đã thêm vào giỏ hàng", snackPosition: SnackPosition.BOTTOM);
                  }
                } : null,
                child: const Icon(Icons.add_shopping_cart, color: Colors.pink),
              ),
            ),
            const SizedBox(width: 12),

            // Nút Mua ngay
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canBuy ? Colors.pink : Colors.grey.shade400,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: canBuy ? () => cartController.buyNow(
                    productId: p.id,
                    quantity: controller.quantity.value,
                    variantId: v?.id,
                  ) : null,
                  child: const Text('Mua ngay', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _qtyBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(width: 40, height: 48, child: Icon(icon, size: 20, color: Colors.grey.shade700)),
    );
  }
}