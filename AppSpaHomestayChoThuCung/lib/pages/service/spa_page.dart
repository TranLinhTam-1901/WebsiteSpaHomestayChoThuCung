import 'package:flutter/material.dart';

const kPrimaryPink = Color(0xFFFFB6C1);
const kBackgroundPink = Color(0xFFFFF0F5);
const kDarkText = Color(0xFF333333);

class SpaPage extends StatelessWidget {
  const SpaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundPink,
      appBar: AppBar(
        backgroundColor: kPrimaryPink,
        elevation: 0,
        title: const Text(
          "Dịch vụ Spa 🧼",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _introSection(),
          const SizedBox(height: 20),
          _priceTable(),
          const SizedBox(height: 20),
          _otherServices(),
          const SizedBox(height: 20),
          _monthlyPackage(),
          const SizedBox(height: 30),
          _bookButton(context),
        ],
      ),
    );
  }

  /// ================= INTRO =================
  Widget _introSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            Text(
              "🐾 Dịch Vụ Spa Cho Thú Cưng 🐾",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "PawHouse cung cấp dịch vụ spa cao cấp giúp thú cưng thư giãn, "
                  "sạch sẽ và khỏe mạnh với đội ngũ chuyên nghiệp và sản phẩm an toàn.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// ================= PRICE TABLE =================
  Widget _priceTable() {
    final rows = [
      ["Dưới 5kg", "330.000", "500.000", "420.000"],
      ["5kg - 12kg", "440.000", "690.000", "570.000"],
      ["12kg - 25kg", "610.000", "930.000", "770.000"],
      ["Trên 25kg", "850.000", "1.300.000", "1.000.000"],
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _sectionTitle("💰 Bảng giá Spa"),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                MaterialStateProperty.all(kPrimaryPink.withOpacity(0.6)),
                columns: const [
                  DataColumn(label: Text("Trọng lượng")),
                  DataColumn(label: Text("Spa")),
                  DataColumn(label: Text("Grooming")),
                  DataColumn(label: Text("Shave")),
                ],
                rows: rows
                    .map(
                      (r) => DataRow(
                    cells: r.map((c) => DataCell(Text(c))).toList(),
                  ),
                )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= OTHER SERVICES =================
  Widget _otherServices() {
    final services = [
      "Cắt móng – 80.000",
      "Vệ sinh tai – 60.000",
      "Vệ sinh răng miệng – 55.000",
      "Gỡ rối – 50.000 ~ 700.000",
      "Tắm đặc trị – 50.000",
      "Phụ thu check-in trễ – 70.000",
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _sectionTitle("✨ Dịch vụ khác"),
            const SizedBox(height: 10),
            ...services.map(
                  (s) => ListTile(
                leading: const Icon(Icons.pets, color: kPrimaryPink),
                title: Text(s),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= MONTHLY PACKAGE =================
  Widget _monthlyPackage() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            Text(
              "🛁 GÓI TẮM THÁNG",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "10 lần tắm spa – Giảm 15%\n(Sử dụng trong 90 ngày)",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// ================= BOOK BUTTON =================
  Widget _bookButton(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryPink,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      icon: const Icon(Icons.calendar_month),
      label: const Text(
        "Đặt lịch Spa ngay",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        // TODO: Navigator.push tới trang đặt lịch
      },
    );
  }

  /// ================= COMMON =================
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }
}
