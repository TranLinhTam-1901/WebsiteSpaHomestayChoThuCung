import 'package:flutter/material.dart';

class ServiceDetail {
  final String name;
  final double price;
  final double? salePrice;

  ServiceDetail({
    required this.name,
    required this.price,
    this.salePrice,
  });
}

class Service {
  final String name;
  final List<ServiceDetail> details;

  Service({
    required this.name,
    required this.details,
  });
}

final vetServices = [
  Service(
    name: "Khám tổng quát",
    details: [
      ServiceDetail(
        name: "Khám sức khỏe cơ bản",
        price: 150000,
      ),
      ServiceDetail(
        name: "Khám chuyên sâu",
        price: 300000,
        salePrice: 250000,
      ),
    ],
  ),

  Service(
    name: "Tiêm phòng",
    details: [
      ServiceDetail(
        name: "Vaccine 5 bệnh",
        price: 400000,
      ),
      ServiceDetail(
        name: "Vaccine 7 bệnh",
        price: 550000,
        salePrice: 500000,
      ),
    ],
  ),

  Service(
    name: "Xét nghiệm",
    details: [
      ServiceDetail(
        name: "Xét nghiệm máu",
        price: 200000,
      ),
      ServiceDetail(
        name: "Xét nghiệm nước tiểu",
        price: 180000,
      ),
      ServiceDetail(
        name: "Xét nghiệm ký sinh trùng",
        price: 250000,
        salePrice: 220000,
      ),
    ],
  ),

  Service(
    name: "Phẫu thuật",
    details: [
      ServiceDetail(
        name: "Triệt sản chó",
        price: 1200000,
        salePrice: 1000000,
      ),
      ServiceDetail(
        name: "Triệt sản mèo",
        price: 800000,
        salePrice: 650000,
      ),
    ],
  ),

  Service(
    name: "Điều trị",
    details: [
      ServiceDetail(
        name: "Điều trị da liễu",
        price: 350000,
      ),
      ServiceDetail(
        name: "Điều trị tiêu hóa",
        price: 300000,
      ),
      ServiceDetail(
        name: "Điều trị hô hấp",
        price: 400000,
        salePrice: 360000,
      ),
    ],
  ),
];

const kPrimaryPink = Color(0xFFFF6185);
const kLightPink = Color(0xFFFFB6C1);
const kBackgroundPink = Color(0xFFFFF0F5);

class VetPage  extends StatelessWidget {
  const VetPage ({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundPink,
      appBar: AppBar(
        backgroundColor: kLightPink,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Dịch vụ thú y 🩺",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle(),
          const SizedBox(height: 20),
          ...vetServices.map(_serviceCard).toList(),
        ],
      ),
    );
  }

  /// =======================
  /// TITLE
  /// =======================
  Widget _sectionTitle() {
    return Column(
      children: const [
        Text(
          "Dịch vụ thú y 🩺",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: kPrimaryPink,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        SizedBox(
          width: 60,
          height: 4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: kLightPink,
              borderRadius: BorderRadius.all(Radius.circular(2)),
            ),
          ),
        ),
      ],
    );
  }

  /// =======================
  /// SERVICE CARD
  /// =======================
  Widget _serviceCard(Service service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE0DCD0)),
      ),
      child: Column(
        children: [
          /// HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: kLightPink,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Text(
              service.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),

          /// DIVIDER
          const Divider(
            height: 0,
            thickness: 2,
            color: kPrimaryPink,
          ),

          /// DETAILS
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: service.details.map(_serviceRow).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// =======================
  /// SERVICE ROW
  /// =======================
  Widget _serviceRow(ServiceDetail detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              detail.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _priceWidget(detail),
        ],
      ),
    );
  }

  /// =======================
  /// PRICE
  /// =======================
  Widget _priceWidget(ServiceDetail detail) {
    if (detail.salePrice != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatPrice(detail.price),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          Text(
            _formatPrice(detail.salePrice!),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: kPrimaryPink,
            ),
          ),
        ],
      );
    }

    return Text(
      _formatPrice(detail.price),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  String _formatPrice(double price) {
    return "${price.toStringAsFixed(0)} đ";
  }
}
