  import 'package:flutter/material.dart';
  import '../../../model/order/order_model.dart';
  import '../../../services/api_service.dart';
  import '../../../utils/price_utils.dart';
import 'order_detail.dart';

  const kPrimaryPink = Color(0xFFFF6185);
  const kLightPink = Color(0xFFFFB6C1);
  const kBackgroundPink = Color(0xFFFFF0F5);

  class OrderHistoryPage extends StatefulWidget {
    const OrderHistoryPage({super.key});

    @override
    State<OrderHistoryPage> createState() => _OrderHistoryPageState();
  }

  class _OrderHistoryPageState extends State<OrderHistoryPage> {
    late Future<List<Order>> ordersFuture;

    @override
    void initState() {
      super.initState();
      ordersFuture = ApiService.getOrderHistory();
    }

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
        body: FutureBuilder<List<Order>>(
          future: ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Lỗi: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Bạn chưa có đơn hàng nào"));
            } else {
              final orders = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (_, i) => _orderCard(context, orders[i]),
              );
            }
          },
        ),
      );
    }

    Widget _orderCard(BuildContext context, Order o) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        child: Column(
          children: [
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
                      Text("Mã đơn #${o.id}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("${o.orderDate.day}/${o.orderDate.month}/${o.orderDate.year}", style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                  _statusBadge(o.status),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BODY phần người nhận
                  Text(
                    "👤 Người nhận: ${o.customerName}",
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),

                  const SizedBox(height: 8),
                  if (o.discount > 0) ...[
                    Text(
                      "💰 ${formatPrice(o.totalPrice + o.discount)}",
                      style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey),
                    ),
                    Text("💖 ${formatPrice(o.totalPrice)}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    Text("🎟 Mã ${o.promoCode} (-${formatPrice(o.discount)})", style: const TextStyle(color: Colors.green)),
                  ] else
                    Text("💰 ${formatPrice(o.totalPrice)}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text("🛒 Sản phẩm:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...o.items.map((it) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text("${it.name}\n(${it.option}) x${it.quantity}", style: const TextStyle(fontSize: 13))),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (it.discountedPrice < it.price)
                              Text(formatPrice(it.price), style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 12, color: Colors.grey)),
                            Text(formatPrice(it.discountedPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            // FOOTER nút Xem chi tiết với style tương tự CSS
            Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailPage(order: o),
                        ),
                      );
                    },
                    icon: const Icon(Icons.info_outline, size: 16, color: Colors.black),
                    label: const Text(
                      "Xem chi tiết",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                            (states) {
                          if (states.contains(MaterialState.hovered) ||
                              states.contains(MaterialState.pressed)) {
                            return const Color(0xFFFF6185); // hover
                          }
                          return const Color(0xFFFFB6C1); // default
                        },
                      ),
                      foregroundColor: MaterialStateProperty.all(Colors.black),
                      padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      overlayColor: MaterialStateProperty.all(Colors.transparent),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (o.status == OrderStatus.pending)
                    OutlinedButton(
                      onPressed: () async {
                        try {
                          await ApiService.cancelOrder(o.id);

                          // refetch lại dữ liệu mới từ server
                          final updatedOrders = await ApiService.getOrderHistory();

                          setState(() {
                            ordersFuture = Future.value(updatedOrders); // cập nhật lại
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Hủy đơn thành công")),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Hủy đơn thất bại: $e")),
                          );
                        }
                      },

                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
        decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)),
      );
    }
  }
