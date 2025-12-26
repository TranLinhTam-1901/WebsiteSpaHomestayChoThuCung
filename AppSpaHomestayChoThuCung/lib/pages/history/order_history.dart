import 'package:flutter/material.dart';

const kPrimaryPink = Color(0xFFFF6185);
const kLightPink = Color(0xFFFFB6C1);
const kBackgroundPink = Color(0xFFFFF0F5);

/// ================= MODEL =================
enum OrderStatus { pending, confirmed, cancelled }

class OrderItem {
  final String name;
  final String option;
  final int quantity;
  final int price;
  final int discountedPrice;

  OrderItem({
    required this.name,
    required this.option,
    required this.quantity,
    required this.price,
    required this.discountedPrice,
  });
}

class Order {
  final int id;
  final DateTime orderDate;
  final String customer;
  final OrderStatus status;
  final int totalPrice;
  final int discount;
  final String? promoCode;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.orderDate,
    required this.customer,
    required this.status,
    required this.totalPrice,
    required this.discount,
    this.promoCode,
    required this.items,
  });
}

/// ================= PAGE =================
class OrderHistoryPage extends StatelessWidget {
  OrderHistoryPage({super.key});

  /// ===== DATA CỨNG =====
  final orders = <Order>[
    Order(
      id: 1001,
      orderDate: DateTime.now().subtract(const Duration(days: 1)),
      customer: "Nguyễn Văn A",
      status: OrderStatus.pending,
      totalPrice: 450000,
      discount: 50000,
      promoCode: "PET50",
      items: [
        OrderItem(
          name: "Thức ăn cho chó",
          option: "Gói 1kg",
          quantity: 1,
          price: 300000,
          discountedPrice: 250000,
        ),
        OrderItem(
          name: "Sữa tắm thú cưng",
          option: "Hương lavender",
          quantity: 1,
          price: 200000,
          discountedPrice: 200000,
        ),
      ],
    ),
    Order(
      id: 1002,
      orderDate: DateTime.now().subtract(const Duration(days: 5)),
      customer: "Trần Thị B",
      status: OrderStatus.confirmed,
      totalPrice: 320000,
      discount: 0,
      items: [
        OrderItem(
          name: "Đồ chơi cho mèo",
          option: "Chuột bông",
          quantity: 2,
          price: 160000,
          discountedPrice: 160000,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundPink,
      appBar: AppBar(
        backgroundColor: kLightPink,
        elevation: 0,
        title: const Text(
          "Lịch sử đặt hàng 📦",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: orders.isEmpty
          ? const Center(child: Text("Bạn chưa có đơn hàng nào"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (_, i) => _orderCard(context, orders[i]),
      ),
    );
  }

  /// ================= CARD =================
  Widget _orderCard(BuildContext context, Order o) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Column(
        children: [
          /// HEADER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: kBackgroundPink,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Mã đơn #${o.id}",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      "${o.orderDate.day}/${o.orderDate.month}/${o.orderDate.year}",
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
                _statusBadge(o.status),
              ],
            ),
          ),

          /// BODY
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("👤 Người nhận: ${o.customer}"),
                const SizedBox(height: 8),

                if (o.discount > 0) ...[
                  Text(
                    "💰 ${(o.totalPrice + o.discount).toStringAsFixed(0)} đ",
                    style: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    "💖 ${o.totalPrice.toStringAsFixed(0)} đ",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "🎟 Mã ${o.promoCode} (-${o.discount.toStringAsFixed(0)} đ)",
                    style: const TextStyle(color: Colors.green),
                  ),
                ] else
                  Text(
                    "💰 ${o.totalPrice.toStringAsFixed(0)} đ",
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),

                const SizedBox(height: 12),
                const Text(
                  "🛒 Sản phẩm:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                ...o.items.map(
                      (it) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "${it.name}\n(${it.option}) x${it.quantity}",
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (it.discountedPrice < it.price)
                              Text(
                                "${it.price} đ",
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            Text(
                              "${it.discountedPrice} đ",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// FOOTER
          Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Xem chi tiết (demo)")),
                    );
                  },
                  child: const Text("Xem chi tiết"),
                ),
                if (o.status == OrderStatus.pending)
                  OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Hủy đơn (demo)")),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text("Hủy đơn"),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ================= HELPERS =================
  Widget _statusBadge(OrderStatus s) {
    Color c;
    String text;

    switch (s) {
      case OrderStatus.pending:
        c = Colors.orange;
        text = "Chờ xác nhận";
        break;
      case OrderStatus.confirmed:
        c = Colors.green;
        text = "Đã xác nhận";
        break;
      case OrderStatus.cancelled:
        c = Colors.red;
        text = "Đã hủy";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration:
      BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(
        text,
        style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
