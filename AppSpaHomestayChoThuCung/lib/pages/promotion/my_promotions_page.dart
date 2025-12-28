import 'package:flutter/material.dart';

const kPrimaryPink = Color(0xFFFFB6C1);
const kBackgroundPink = Color(0xFFFFF0F5);

class MyPromotion {
  final String title;
  final String code;
  final int discount;
  final bool isPercent;
  final DateTime endDate;
  final bool isUsed;

  MyPromotion({
    required this.title,
    required this.code,
    required this.discount,
    required this.isPercent,
    required this.endDate,
    this.isUsed = false,
  });
}

class MyPromotionsPage extends StatelessWidget {
  const MyPromotionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final promotions = _demoData();

    return Scaffold(
      backgroundColor: kBackgroundPink,

      /// ================= APPBAR =================
      appBar: AppBar(
        backgroundColor: kPrimaryPink,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Khuyến mãi của tôi",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      /// ================= BODY =================
      body: promotions.isEmpty
          ? const Center(
        child: Text(
          "🎁 Bạn chưa có mã khuyến mãi nào",
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: promotions.length,
        itemBuilder: (_, i) {
          final promo = promotions[i];
          final expired = promo.endDate.isBefore(DateTime.now());

          Color statusColor;
          String statusText;

          if (expired) {
            statusColor = Colors.grey;
            statusText = "Hết hạn";
          } else if (promo.isUsed) {
            statusColor = Colors.green;
            statusText = "Đã dùng";
          } else {
            statusColor = Colors.orange;
            statusText = "Còn hiệu lực";
          }

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  /// 🎟 ICON
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: kPrimaryPink.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_offer,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 12),

                  /// 📄 INFO
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promo.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Mã: ${promo.code}",
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          "Giảm ${promo.discount}${promo.isPercent ? "%" : "đ"}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// 👉 ACTIONS
                  Column(
                    children: [
                      if (!expired && !promo.isUsed)
                        IconButton(
                          icon: const Icon(Icons.shopping_cart_outlined),
                          onPressed: () {
                            // TODO: áp dụng mã khi mua hàng
                          },
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          // TODO: xoá mã
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// ================= DEMO DATA =================
  List<MyPromotion> _demoData() {
    return [
      MyPromotion(
        title: "Giảm 10% đơn hàng",
        code: "SALE10",
        discount: 10,
        isPercent: true,
        endDate: DateTime.now().add(const Duration(days: 3)),
      ),
      MyPromotion(
        title: "Giảm 50.000đ",
        code: "PET50",
        discount: 50000,
        isPercent: false,
        endDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}
