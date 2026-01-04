import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../model/order/order.dart';

// Hằng số màu sắc đồng bộ
const kLightPink = Color(0xFFFFB6C1);
const kBackgroundLight = Color(0xFFF9F9F9);

class OrderDetailPage extends StatelessWidget {
  final Order order;

  const OrderDetailPage({super.key, required this.order});

  // Hàm format tiền tệ
  String _formatPrice(num price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  @override
  Widget build(BuildContext context) {
    // Chỉnh status bar đồng bộ
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: kBackgroundLight,
      appBar: AppBar(
        title: const Text(
          "Chi tiết đơn hàng",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: kLightPink,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // 1. CARD TRẠNG THÁI & MÃ ĐƠN
            _buildSectionCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Mã đơn hàng", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      Text("#${order.id}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  _statusBadge(order.status),
                ],
              ),
            ),

            // 2. CARD THÔNG TIN GIAO HÀNG
            _buildSectionCard(
              title: "Thông tin giao hàng",
              icon: Icons.local_shipping_outlined,
              child: Column(
                children: [
                  _infoTile("Người nhận", order.customerName),
                  _infoTile("Số điện thoại", order.phoneNumber ?? "Không có"),
                  _infoTile("Địa chỉ", order.shippingAddress ?? "Không có"),
                  _infoTile("Thanh toán", order.paymentMethod ?? "Không có"),
                  _infoTile("Ghi chú", order.notes?.isEmpty ?? true ? "Không có" : order.notes!),
                ],
              ),
            ),

            // 3. CARD DANH SÁCH SẢN PHẨM
            _buildSectionCard(
              title: "Sản phẩm đã đặt",
              icon: Icons.shopping_bag_outlined,
              child: Column(
                children: [
                  ...order.items.map((it) => _buildProductItem(it)),
                ],
              ),
            ),

            // 4. CARD TỔNG KẾT THANH TOÁN
            _buildSectionCard(
              title: "Chi tiết thanh toán",
              icon: Icons.payments_outlined,
              child: Column(
                children: [
                  _priceRow("Tạm tính", (order.totalPrice + order.discount)),
                  if (order.discount > 0)
                    _priceRow("Giảm giá (${order.promoCode ?? 'KM'})", -order.discount, isDiscount: true),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Tổng thanh toán", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(_formatPrice(order.totalPrice),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.redAccent)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- WIDGET CẤU TRÚC CARD ---
  Widget _buildSectionCard({String? title, IconData? icon, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Icon(icon, size: 18, color: Colors.pinkAccent),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const Divider(height: 20),
          ],
          child,
        ],
      ),
    );
  }

  // --- DÒNG THÔNG TIN ---
  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // --- DÒNG SẢN PHẨM ---
  Widget _buildProductItem(OrderItem it) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: kLightPink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: Colors.pinkAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    it.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                ),
                const SizedBox(height: 4),
                Text(
                  // Kiểm tra: Nếu option không rỗng và khác "null"
                  (it.option.isNotEmpty && it.option != "null")
                      ? "Loại: ${it.option}  |  x${it.quantity}" // Hiện đầy đủ
                      : "Số lượng: x${it.quantity}",            // Chỉ hiện số lượng
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatPrice(it.discountedPrice * it.quantity),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              if (it.discountedPrice < it.price)
                Text(_formatPrice(it.price * it.quantity),
                    style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  // --- DÒNG GIÁ TIỀN ---
  Widget _priceRow(String label, num value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            (isDiscount ? "- " : "") + _formatPrice(value.abs()),
            style: TextStyle(
                color: isDiscount ? Colors.green : Colors.black87,
                fontSize: 13,
                fontWeight: isDiscount ? FontWeight.bold : FontWeight.normal
            ),
          ),
        ],
      ),
    );
  }

  // --- BADGE TRẠNG THÁI ---
  Widget _statusBadge(OrderStatus s) {
    Color c;
    String text;
    switch (s) {
      case OrderStatus.pending: c = Colors.orange; text = "Chờ xác nhận"; break;
      case OrderStatus.confirmed: c = Colors.green; text = "Đã nhận đơn"; break;
      case OrderStatus.cancelled: c = Colors.red; text = "Đã hủy"; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}