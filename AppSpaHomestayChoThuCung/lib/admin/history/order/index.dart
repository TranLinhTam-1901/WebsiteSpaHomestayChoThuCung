import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../model/order/order.dart';
import '../../../services/admin_api_service.dart';
import 'detail.dart';
import 'package:get/get.dart';

class AdminOrderListScreen extends StatefulWidget {
  const AdminOrderListScreen({super.key});

  @override
  State<AdminOrderListScreen> createState() => _AdminOrderListScreenState();
}

class _AdminOrderListScreenState extends State<AdminOrderListScreen> {
  final Color pinkMain = const Color(0xFFff7aa2);
  final Color pinkLight = const Color(0xFFFFB6C1);
  final Color greyBg = const Color(0xFFF8F9FA);

  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final results = await AdminApiService.getOrders();
      debugPrint("Dữ liệu đơn hàng nhận được: ${results.length} đơn");
      setState(() {
        _orders = results;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Lỗi tại UI: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: greyBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: pinkMain))
                  : RefreshIndicator(
                onRefresh: _fetchOrders,
                child: _orders.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    return _buildOrderCard(_orders[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pinkLight.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Mã đơn & Ngày đặt
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Mã đơn: #${order.id}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                _buildStatusBadge(order.status),
              ],
            ),
          ),
          const Divider(height: 1),

          // 2. PHẦN GIỮA: Thông tin Khách hàng, Số lượng & Thanh toán
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoSummary(Icons.person_outline, "Khách hàng:", order.senderName),
                const SizedBox(height: 10),
                _buildInfoSummary(Icons.shopping_bag_outlined, "Số lượng:", "${order.itemCount} sản phẩm"),
                const SizedBox(height: 10),
                _buildInfoSummary(
                  Icons.payment_outlined,
                  "Thanh toán:",
                  order.paymentMethod == "COD" ? "Tiền mặt (COD)" : "Chuyển khoản",
                  valueColor: order.paymentMethod == "COD" ? Colors.blueGrey : Colors.blue,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 3. Footer: Tiền bên trái, Nút bên phải (Y như cũ)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Cột tiền bên trái
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Thành tiền", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(order.totalPrice),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 15),
                    ),
                  ],
                ),
                // Hàng nút bên phải
                Row(
                  children: [
                    // Nút Duyệt
                    if (order.status == OrderStatus.pending)
                      _buildActionButton(
                        label: "Duyệt",
                        color: Colors.green,
                        textColor: Colors.white,
                        onTap: () => _showConfirmDialog(
                          title: "Xác nhận đơn hàng",
                          content: "Bạn có chắc chắn muốn xác nhận đơn #${order.id}?",
                          onConfirm: () => _handleConfirm(order.id),
                        ),
                      ),

                    // Nút Hủy (giữ nguyên logic gốc của bạn)
                    if (order.status == OrderStatus.pending || order.status == OrderStatus.confirmed) ...[
                      const SizedBox(width: 8),
                      _buildActionButton(
                        label: order.status == OrderStatus.confirmed ? "Hủy (Hoàn)" : "Hủy đơn",
                        color: Colors.redAccent,
                        textColor: Colors.white,
                        onTap: () => _showConfirmDialog(
                          title: "Hủy đơn hàng",
                          content: order.status == OrderStatus.confirmed
                              ? "Đơn hàng đã xác nhận. Hủy đơn này sẽ hoàn lại số lượng sản phẩm vào kho?"
                              : "Bạn có chắc muốn hủy đơn hàng này không?",
                          onConfirm: () => _handleCancel(order.id),
                        ),
                      ),
                    ],

                    const SizedBox(width: 8),

                    // Nút Chi tiết
                    _buildActionButton(
                      label: "Chi tiết",
                      color: pinkLight,
                      textColor: Colors.black,
                      onTap: () async {
                        Get.dialog(
                          const Center(child: CircularProgressIndicator(color: Color(0xFFFF6185))),
                          barrierDismissible: false,
                        );
                        final fullOrder = await AdminApiService.getOrderDetails(order.id);
                        Get.back();
                        if (fullOrder != null) {
                          Get.to(() => OrderDetailScreen(order: fullOrder), transition: Transition.rightToLeft);
                        }
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Hàm bổ trợ hiển thị thông tin tóm tắt (Nhớ thêm hàm này vào class)
  Widget _buildInfoSummary(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? Colors.black87),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // Hàm hiển thị hộp thoại xác nhận trước khi thực hiện hành động quan trọng
  void _showConfirmDialog({required String title, required String content, required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Đóng")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: pinkMain),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text("Đồng ý", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Xử lý Hủy đơn
  Future<void> _handleCancel(int id) async {
    setState(() => _isLoading = true);
    bool success = await AdminApiService.cancelOrder(id);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Đã hủy đơn hàng thành công")),
        );
      }
      _fetchOrders();
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Không thể hủy đơn hàng")),
        );
      }
    }
  }

  // Xử lý Xác nhận đơn (Cập nhật lại từ code cũ để đồng bộ Loading)
  Future<void> _handleConfirm(int id) async {
    setState(() => _isLoading = true);
    bool success = await AdminApiService.confirmOrder(id);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Đã xác nhận đơn hàng")),
        );
      }
      _fetchOrders();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color color;
    String text;
    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        text = "Chờ duyệt";
        break;
      case OrderStatus.confirmed:
        color = Colors.green;
        text = "Đã xác nhận";
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        text = "Đã hủy";
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildActionButton({required String label, required Color color, required Color textColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FontAwesomeIcons.boxOpen, size: 80, color: pinkLight.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text("Không có đơn hàng nào", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}