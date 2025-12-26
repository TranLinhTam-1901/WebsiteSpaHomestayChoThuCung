import 'package:flutter/material.dart';

const kPrimaryPink = Color(0xFFFF6185);
const kLightPink = Color(0xFFFFB6C1);
const kBackgroundPink = Color(0xFFFFF0F5);

class PriceItem {
  final String label;
  final String price;

  PriceItem(this.label, this.price);
}

class HomestayPage extends StatelessWidget {
  const HomestayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundPink,
      appBar: AppBar(
        backgroundColor: kLightPink,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Dịch vụ Homestay 🏨",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _introSection(),
          const SizedBox(height: 24),

          /// DOG HOMESTAY
          _sectionTitle("🐶 Dog Homestay 🏠"),
          _dogDaycareCard(context),

          const SizedBox(height: 24),

          /// POLICY
          _policySection(),

          const SizedBox(height: 24),

          /// CAT HOMESTAY
          _sectionTitle("🐱 Cat Homestay 🏠"),
          _catHomestayCard(context),
        ],
      ),
    );
  }

  /// =======================
  /// INTRO
  /// =======================
  Widget _introSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            Text(
              "🏨 Dịch vụ Homestay tại PawHouse",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kPrimaryPink,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              "PawHouse cung cấp dịch vụ lưu trú cao cấp cho thú cưng với không gian sạch sẽ, an toàn và tiện nghi. "
                  "Có phòng riêng, khu vui chơi và đội ngũ chăm sóc tận tâm mỗi ngày.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// =======================
  /// SECTION TITLE
  /// =======================
  Widget _sectionTitle(String title) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            color: kLightPink,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// =======================
  /// DOG DAYCARE
  /// =======================
  Widget _dogDaycareCard(BuildContext context) {
    final prices = [
      PriceItem("Dưới 5kg", "190.000"),
      PriceItem("5kg – 8kg", "210.000"),
      PriceItem("8kg – 12kg", "240.000"),
      PriceItem("12kg – 18kg", "280.000"),
      PriceItem("18kg – 25kg", "320.000"),
      PriceItem("Trên 25kg", "375.000"),
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ExpansionTile(
        title: const Text(
          "Daycare (Gửi trong ngày)",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          ...prices.map(
                (e) => _priceRow(e.label, e.price),
          ),
          const SizedBox(height: 12),
          const Text(
            "Daycare là dịch vụ chăm sóc thú cưng trong ngày, không qua đêm.",
          ),
          const SizedBox(height: 12),
          _bookHomestayButton(context),
        ],
      ),
    );
  }

  /// =======================
  /// POLICY
  /// =======================
  Widget _policySection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ExpansionTile(
        title: const Text(
          "📌 Điều khoản áp dụng",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: const [
          Text("Gói lưu trú dài hạn:"),
          SizedBox(height: 6),
          Text("• 1 tuần: OFF 10%"),
          Text("• 2 tuần: OFF 15%"),
          Text("• 1 tháng: OFF 20% + Free 1 Spa"),
          SizedBox(height: 12),
          Text("Giờ check-in: 9:00 AM"),
          Text("Giờ check-out: 11:00 AM"),
          Text("Checkout trễ tính phí Daycare"),
        ],
      ),
    );
  }

  /// =======================
  /// CAT HOMESTAY
  /// =======================
  Widget _catHomestayCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ExpansionTile(
        title: const Text(
          "Các loại phòng cho mèo",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          _catRoom(
            "Standard Room",
            ["1 mèo – 200.000"],
            "Phòng tiêu chuẩn, đầy đủ tiện nghi cơ bản.",
          ),
          _catRoom(
            "Deluxe Room",
            ["1 mèo – 250.000", "2 mèo – 375.000"],
            "Phòng rộng rãi, có khu vui chơi riêng.",
          ),
          _catRoom(
            "Superior Room",
            ["1 mèo – 350.000", "2 mèo – 525.000", "3 mèo – 700.000"],
            "Phòng cao cấp, view đẹp, không gian thoải mái.",
          ),
          const SizedBox(height: 12),
          _bookHomestayButton(context),
        ],
      ),
    );
  }

  Widget _catRoom(String title, List<String> prices, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: kPrimaryPink,
            ),
          ),
          ...prices.map((e) => Text("• $e")),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            price,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _bookHomestayButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: kLightPink,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        icon: const Icon(Icons.calendar_month),
        label: const Text(
          "Đặt lịch Homestay ngay",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: () {
          // TODO: Navigator.push tới trang đặt lịch Homestay
        },
      ),
    );
  }
}
