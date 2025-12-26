import 'package:flutter/material.dart';

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

class MyPromotionsPage extends StatefulWidget {
  const MyPromotionsPage({super.key});

  @override
  State<MyPromotionsPage> createState() => _MyPromotionsPageState();
}

class _MyPromotionsPageState extends State<MyPromotionsPage> {
  int _currentIndex = 2; // 🔥 đang ở tab Khuyến mãi

  @override
  Widget build(BuildContext context) {
    final promotions = _demoData();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Khuyến mãi của tôi"),
        backgroundColor: Colors.pink,
        centerTitle: true,
      ),

      /// =========================
      /// BODY
      /// =========================
      body: promotions.isEmpty
          ? const Center(
        child: Text(
          "Bạn chưa lưu mã khuyến mãi nào.",
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: promotions.length,
        itemBuilder: (_, i) {
          final promo = promotions[i];
          final expired =
          promo.endDate.isBefore(DateTime.now());

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                promo.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Mã: ${promo.code}",
                    style: const TextStyle(color: Colors.pink),
                  ),
                  Text(
                    "Giảm ${promo.discount}${promo.isPercent ? "%" : "đ"}",
                  ),
                  Text(
                    expired
                        ? "Hết hạn"
                        : promo.isUsed
                        ? "Đã dùng"
                        : "Còn hiệu lực",
                    style: TextStyle(
                      color: expired
                          ? Colors.grey
                          : promo.isUsed
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!expired && !promo.isUsed)
                    IconButton(
                      icon: const Icon(Icons.shopping_cart),
                      onPressed: () {},
                    ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          );
        },
      ),

      /// =========================
      /// FOOTER (BOTTOM NAV)
      /// =========================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => _currentIndex = index);

          /// 👉 sau này bạn điều hướng ở đây
          /// Navigator.pushReplacement(...)
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Trang chủ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: "Sản phẩm",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: "Khuyến mãi",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Cài đặt",
          ),
        ],
      ),
    );
  }

  /// =========================
  /// DEMO DATA
  /// =========================
  List<MyPromotion> _demoData() {
    return [
      MyPromotion(
        title: "Giảm 10%",
        code: "SALE10",
        discount: 10,
        isPercent: true,
        endDate: DateTime.now().add(const Duration(days: 3)),
      ),
      MyPromotion(
        title: "Giảm 50K",
        code: "PET50",
        discount: 50000,
        isPercent: false,
        endDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}
