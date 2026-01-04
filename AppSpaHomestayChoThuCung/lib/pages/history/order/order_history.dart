import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../model/order/order.dart';
import '../../../services/api_service.dart';
import 'order_detail.dart';

// Hằng số màu sắc đồng bộ
const kLightPink = Color(0xFFFFB6C1);
const kBackgroundLight = Color(0xFFF9F9F9);

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

  // Hàm format tiền tệ
  String _formatPrice(num price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: kBackgroundLight,
      appBar: AppBar(
        title: const Text(
          "Lịch sử mua hàng",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: kLightPink,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            ordersFuture = ApiService.getOrderHistory();
          });
        },
        child: FutureBuilder<List<Order>>(
          future: ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: kLightPink));
            } else if (snapshot.hasError) {
              return Center(child: Text("Lỗi: ${snapshot.error}", style: const TextStyle(color: Colors.grey)));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 70, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text("Bạn chưa có đơn hàng nào", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            final orders = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: orders.length,
              itemBuilder: (_, i) => _orderCard(context, orders[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _orderCard(BuildContext context, Order o) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // HEADER: Mã đơn và Ngày đặt
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Đơn hàng #${o.id}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    // Dùng trực tiếp như thế này là nó tự ra 14:24 (thay vì 07:24)
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(o.orderDate),
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
                _statusBadge(o.status),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),

          // BODY: Thông tin sản phẩm tóm tắt
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(o.customerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 12),

                // Hiển thị danh sách sản phẩm (tối đa 2 sản phẩm đầu tiên để gọn card)
                ...o.items.take(2).map((it) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart_outlined, size: 14, color: Colors.pinkAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text("${it.name} x${it.quantity}",
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Text(_formatPrice(it.discountedPrice * it.quantity),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )),
                if (o.items.length > 2)
                  Text("... và ${o.items.length - 2} sản phẩm khác",
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text("Tổng thanh toán: ", style: TextStyle(fontSize: 13)),
                    Text(_formatPrice(o.totalPrice),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  ],
                ),
              ],
            ),
          ),

          // FOOTER: Các nút thao tác
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _actionButton(
                  label: "Chi tiết",
                  icon: Icons.info_outline,
                  color: Colors.blueGrey,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => OrderDetailPage(order: o)));
                  },
                ),
                if (o.status == OrderStatus.pending) ...[
                  const SizedBox(width: 8),
                  _actionButton(
                    label: "Hủy đơn",
                    icon: Icons.cancel_outlined,
                    color: Colors.redAccent,
                    onTap: () => _handleCancelOrder(o.id),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(OrderStatus s) {
    Color c;
    String text;
    switch (s) {
      case OrderStatus.pending: c = Colors.orange; text = "Chờ xác nhận"; break;
      case OrderStatus.confirmed: c = Colors.green; text = "Đã nhận đơn"; break;
      case OrderStatus.cancelled: c = Colors.red; text = "Đã hủy"; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  void _handleCancelOrder(int orderId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Hủy đơn hàng"),
        content: const Text("Bạn có chắc chắn muốn hủy đơn hàng này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Quay lại")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Xác nhận hủy", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await ApiService.cancelOrder(orderId);
        final updatedOrders = await ApiService.getOrderHistory();
        setState(() { ordersFuture = Future.value(updatedOrders); });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã hủy đơn hàng thành công")));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    }
  }
}