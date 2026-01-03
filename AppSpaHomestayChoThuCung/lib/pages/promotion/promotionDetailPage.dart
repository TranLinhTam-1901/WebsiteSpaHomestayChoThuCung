import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../model/promotion_model.dart';
import '../../utils/price_utils.dart';
import '../home_page.dart';

class PromotionDetailPage extends StatelessWidget {
  final PromotionModel promotion;

  const PromotionDetailPage({
    super.key,
    required this.promotion,
  });

  String formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }

  int remainingDays() {
    final diff = promotion.endDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFB6C1),
        elevation: 0,
        title: const Text(
          "Chi tiết ưu đãi",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// ======================
            /// BLOCK 1: BANNER IMAGE
            /// ======================
            if (promotion.image != null && promotion.image!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                child: Image.network(
                  'https://localhost:7051/images/promotions/${promotion.image}',
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 220,
                    color: Colors.grey.shade300,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            /// ======================
            /// BLOCK 2: SUMMARY CARD
            /// ======================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
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
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.timer,
                                size: 14, color: Colors.red),
                            const SizedBox(width: 4),
                            Text(
                              "Kết thúc trong ${remainingDays()} ngày",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text(
                      promotion.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          promotion.isPercent
                              ? "Giảm ${promotion.discount}%"
                              : "Giảm ${formatPrice(promotion.discount)}",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// ======================
            /// BLOCK 4: INFO GRID
            /// ======================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _infoItem(
                    "Thời gian bắt đầu",
                    formatDate(promotion.startDate),
                  ),
                  _infoItem(
                    "Thời gian kết thúc",
                    formatDate(promotion.endDate),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _infoItem(
                    "Đơn tối thiểu",
                    promotion.minOrderValue != null
                        ? formatPrice(promotion.minOrderValue!)
                        : "Không yêu cầu",
                  ),
                  _infoItem(
                    "Hình thức",
                    promotion.isPercent ? "Giảm %" : "Giảm tiền",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// ======================
            /// BLOCK 5: DESCRIPTION
            /// ======================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Mô tả chi tiết",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                promotion.description ??
                    "Ưu đãi hấp dẫn dành cho khách hàng khi mua sắm tại PawHouse.",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// CONDITIONS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Điều kiện áp dụng",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  _ConditionItem("Áp dụng cho sản phẩm phù hợp chương trình"),
                  _ConditionItem("Không áp dụng đồng thời nhiều mã"),
                  _ConditionItem("Mỗi tài khoản sử dụng tối đa 1 lần"),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),

      /// ======================
      /// BLOCK 6: APPLY BUTTON
      /// ======================
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              Get.offAll(
                    () => HomePage(model: HomeViewModel.demo()),
                arguments: {
                  'goToTab': 'product',
                  'promotionId': promotion.id,
                  'promoCode': promotion.code,
                },
              );

            },

            child: const Text(
              "Áp dụng ngay →",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// INFO ITEM
  Widget _infoItem(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CONDITION ITEM
class _ConditionItem extends StatelessWidget {
  final String text;
  const _ConditionItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              color: Colors.green, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
