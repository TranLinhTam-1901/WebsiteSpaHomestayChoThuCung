import 'package:flutter/material.dart';
import '../../../model/order/order_model.dart';
import '../../../services/api_service.dart';
import '../../../utils/price_utils.dart';

const kPrimaryPink = Color(0xFFFF6185);
const kLightPink = Color(0xFFFFB6C1);
const kBackgroundPink = Color(0xFFFFF0F5);

class OrderDetailPage extends StatelessWidget {
  final Order order;

  const OrderDetailPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundPink,
      appBar: AppBar(
        backgroundColor: kLightPink,
        elevation: 0,
        title: Text(
          "📦 Chi tiết đơn hàng #${order.id}",
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Thông tin tổng quan
            _sectionTitle("📋 Thông tin tổng quan"),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRow("Mã đơn hàng", "#${order.id}"),
                    _infoRow(
                        "Ngày đặt",
                        "${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}"),
                    _infoRow(
                      "Tổng tiền",
                      order.discount > 0
                          ? "${formatPrice(order.totalPrice + order.discount) } → ${formatPrice(order.totalPrice)}"
                          : formatPrice(order.totalPrice),
                      isPrice: true,
                      discount: order.discount,
                    ),
                    _infoRow("Trạng thái", _statusText(order.status),
                        badgeColor: _statusColor(order.status)),
                  ],
                ),
              ),
            ),

            // Thông tin người nhận
            _sectionTitle("🚚 Thông tin người nhận & giao hàng"),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRow("Tên người nhận", order.customerName),
                    _infoRow("Số điện thoại", order.phoneNumber ?? "Chưa có"),
                    _infoRow("Địa chỉ giao hàng", order.shippingAddress ?? "Chưa có"),
                    _infoRow("Phương thức thanh toán", order.paymentMethod ?? "Chưa có"),
                    _infoRow("Ghi chú", order.notes?.isEmpty ?? true ? "Không có" : order.notes!),
                  ],
                ),
              ),
            ),

            // Chi tiết sản phẩm
            _sectionTitle("🧾 Chi tiết dịch vụ / sản phẩm"),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: order.items.map((it) => _productRow(it)).toList(),
                ),
              ),
            ),

            // Khuyến mãi
            if (order.discount > 0 && order.promoCode != null)
              _sectionTitle("🎁 Thông tin khuyến mãi"),
            if (order.discount > 0 && order.promoCode != null)
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _infoRow("Mã khuyến mãi", order.promoCode!),
                      _infoRow("Giá trị giảm", formatPrice(order.discount)),
                    ],
                  ),
                ),
              ),

          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryPink)),
      ),
    );
  }

  Widget _infoRow(String label, String value,
      {bool isPrice = false, int discount = 0, Color? badgeColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 140,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(
            child: badgeColor != null
                ? Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(value,
                  style: TextStyle(
                      color: badgeColor, fontWeight: FontWeight.bold)),
            )
                : isPrice && discount > 0
                ? RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                      text:
                      "${(int.parse(value.split('→')[0].replaceAll(RegExp(r'[^0-9]'), ''))).toString()} đ ",
                      style: const TextStyle(
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough)),
                  TextSpan(
                      text:
                      " ${order.totalPrice.toStringAsFixed(0)} đ",
                      style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            )
                : Text(value),
          ),
        ],
      ),
    );
  }

  Widget _productRow(OrderItem it) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text("${it.name} (${it.option})",
                  style: const TextStyle(fontSize: 13))),
          Expanded(child: Text("${it.quantity}", textAlign: TextAlign.center)),
          Expanded(
              child: it.discountedPrice < it.price
                  ? Text(formatPrice(it.price),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                      fontSize: 12))
                  : Text(formatPrice(it.price), textAlign: TextAlign.center)),
          Expanded(
              child: Text(formatPrice(it.discountedPrice),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold))),
          Expanded(child: Text("${it.option}", textAlign: TextAlign.center)),
          Expanded(
              child: Text(formatPrice(it.quantity * it.discountedPrice),
                  textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  String _statusText(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return "Chờ xác nhận";
      case OrderStatus.confirmed:
        return "Đã xác nhận";
      case OrderStatus.cancelled:
        return "Đã hủy";
    }
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
}
