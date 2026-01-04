import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../model/order/order.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  final Color pinkMain = const Color(0xFFFF6185);
  final Color pinkLight = const Color(0xFFFFB6C1);
  final Color pinkExtraLight = const Color(0xFFFFF0F5);

  // Hàm format tiền tệ
  String formatPrice(num price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ', decimalDigits: 0).format(price);
  }

  @override
  Widget build(BuildContext context) {
    // 1. Lấy dữ liệu từ Model (Đã có logic xử lý fallback bên trong Model)
    final int originalPrice = order.originalPrice;

    // 2. Định dạng ngày giờ (Sử dụng orderDate đã toLocal() từ Model)
    String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Chi tiết đơn hàng",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
        centerTitle: true,
        backgroundColor: pinkLight,
        elevation: 0,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Thông tin chung
            _buildSectionCard(
              title: "📑 Đơn hàng #${order.id}",
              child: Column(
                children: [
                  // HIỆN: Người đặt (fullName từ customer object)
                  _buildInfoRow("Người đặt", order.senderName),
                  _buildInfoRow("Ngày đặt", formattedDate),
                  const Divider(),
                  _buildInfoRow("Giá gốc", formatPrice(originalPrice)),
                  if (order.discount > 0)
                    _buildInfoRow("Giảm giá (${order.promoCode ?? 'KM'})", "-${formatPrice(order.discount)}", color: Colors.red),
                  _buildInfoRow("Thành tiền", formatPrice(order.totalPrice),
                      color: Colors.green, isBold: true),
                  const Divider(),
                  _buildStatusRow(order.status),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Thông tin giao hàng
            _buildSectionCard(
              title: "📍 Thông tin giao hàng",
              child: Column(
                children: [
                  // HIỆN: Người nhận (customerName)
                  _buildInfoRow("Người nhận", order.customerName),
                  // HIỆN: Số điện thoại (phoneNumber)
                  _buildInfoRow("Số điện thoại", order.phoneNumber.isEmpty ? "Chưa cung cấp" : order.phoneNumber),
                  // HIỆN: Địa chỉ (shippingAddress)
                  _buildInfoRow("Địa chỉ", order.shippingAddress.isEmpty ? "Chưa cung cấp" : order.shippingAddress),
                  // HIỆN: Phương thức (paymentMethod)
                  _buildInfoRow("Phương thức", order.paymentMethod.isEmpty ? "COD" : order.paymentMethod),
                  // HIỆN: Ghi chú (notes)
                  if (order.notes.isNotEmpty && order.notes != "null")
                    _buildInfoRow("Ghi chú", order.notes),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. Chi tiết sản phẩm (Dùng order.items đã map từ 'details' hoặc 'items')
            _buildSectionCard(
              title: "🛍️ Chi tiết sản phẩm (${order.itemCount})",
              child: order.items.isEmpty
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text("Không có dữ liệu sản phẩm")),
              )
                  : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: order.items.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // HIỆN: Tên sản phẩm (name/productName)
                              Text(item.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 4),
                              // HIỆN: Phân loại (option/variantName)
                              if (item.option.isNotEmpty)
                                Text("Phân loại: ${item.option}",
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              Text("Số lượng: x${item.quantity}",
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // HIỆN: Giá sản phẩm (discountedPrice nếu có giảm, hoặc price)
                            if (item.discountedPrice < item.price)
                              Text(formatPrice(item.price),
                                  style: const TextStyle(fontSize: 11, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                            Text(formatPrice(item.discountedPrice * item.quantity),
                                style: TextStyle(color: pinkMain, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI Components GIỮ NGUYÊN HOÀN TOÀN LAYOUT ---

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pinkLight.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: pinkExtraLight,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(width: 20),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: color ?? Colors.black,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(OrderStatus status) {
    Color badgeColor = Colors.orange;
    String statusText = "Chờ xác nhận";
    if (status == OrderStatus.confirmed) {
      badgeColor = Colors.green;
      statusText = "Đã xác nhận";
    } else if (status == OrderStatus.cancelled) {
      badgeColor = Colors.red;
      statusText = "Đã hủy";
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Trạng thái", style: TextStyle(color: Colors.grey, fontSize: 13)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(20)),
          child: Text(statusText,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      {required String label, required IconData icon, required Color color, required VoidCallback onPressed}) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: const StadiumBorder(),
      ),
    );
  }

  void _confirmAction(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Xác nhận", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Bạn có chắc chắn muốn $message"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Quay lại", style: TextStyle(color: Colors.grey))),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Đồng ý", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}