import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../services/admin_api_service.dart';
import '../../../model/appointment/appointment.dart';
import 'detail.dart';

class PendingAppointmentsScreen extends StatefulWidget {
  const PendingAppointmentsScreen({super.key});

  @override
  State<PendingAppointmentsScreen> createState() => _PendingAppointmentsScreenState();
}

class _PendingAppointmentsScreenState extends State<PendingAppointmentsScreen> {
  final Color pinkMain = const Color(0xFFff7aa2);
  final Color pinkLight = const Color(0xFFffe3ec);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<List<Appointment>>(
          future: AdminApiService.getAppointmentHistory(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: pinkMain));
            }
            if (snapshot.hasError) return Center(child: Text("Lỗi: ${snapshot.error}"));

            final pendingList = snapshot.data?.where((e) => e.isPending).toList() ?? [];

            if (pendingList.isEmpty) {
              return const Center(child: Text("Không có đơn hàng nào chờ xác nhận."));
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
              itemCount: pendingList.length,
              itemBuilder: (context, index) => _buildAppointmentCard(pendingList[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment item) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: pinkLight, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: pinkLight.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Mã: #${item.appointmentId}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                _buildStatusBadge(item), // Badge nhỏ giống 100% History
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                _buildRow(Icons.pets, "Thú cưng", "${item.petName} (${item.petType})"),
                const SizedBox(height: 8),
                _buildRow(Icons.content_paste, "Dịch vụ", item.serviceName),
                const SizedBox(height: 8),
                _buildRow(Icons.calendar_month, "Thời gian", item.timeDisplay),
                const Divider(height: 20),

                // DÒNG CUỐI: TÊN KHÁCH + 3 ICON HÀNH ĐỘNG
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: pinkMain),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        "Khách: ${item.userName}",
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.normal
                        ),
                      ),
                    ),
                    // CỤM 3 ICON NÚT BẤM NHỎ GỌN
                    Row(
                      children: [
                        // 1. Nút Xác nhận - Nhỏ gọn bằng nút chi tiết
                        _buildSmallIconButton(
                          FontAwesomeIcons.check,
                          Colors.green.shade400, // Đậm hơn một chút để rõ nét
                              () => _handleAccept(item.appointmentId!),
                        ),

                        const SizedBox(width: 15), // Tăng khoảng cách một chút cho thoáng

                        // 2. Nút Hủy - Nhỏ gọn bằng nút chi tiết
                        _buildSmallIconButton(
                          FontAwesomeIcons.xmark,
                          Colors.red.shade400,
                              () => _handleCancel(item.appointmentId!),
                        ),

                        const SizedBox(width: 15),

                        // 3. Nút Chi tiết - Giữ nguyên của bạn
                        _buildSmallIconButton(
                          FontAwesomeIcons.circleInfo,
                          Colors.blue.shade200,
                              () => _navigateToDetail(item),
                        ),
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget bổ trợ để tạo Icon Button nhỏ gọn
  Widget _buildSmallIconButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Icon(icon, size: 22, color: color),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: pinkMain),
        const SizedBox(width: 10),
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
      ],
    );
  }

  Widget _buildStatusBadge(Appointment item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)),
      child: const Text(
        "Chờ xác nhận",
        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  // 1. Hàm Xác nhận đơn
  void _handleAccept(int id) async {
    // Hiện loading để Admin không bấm loạn xạ
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    bool success = await AdminApiService.acceptAppointment(id);

    if (!mounted) return;
    Navigator.pop(context); // Đóng loading

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Đã xác nhận lịch #$id"), backgroundColor: Colors.green),
      );
      setState(() {}); // Load lại trang để mất đơn vừa duyệt
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Lỗi khi xác nhận lịch"), backgroundColor: Colors.red),
      );
    }
  }

  // 2. Hàm Hủy đơn (Có thêm Dialog xác nhận cho chắc chắn)
  void _handleCancel(int id) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận hủy"),
        content: Text("Bạn có chắc chắn muốn hủy lịch #$id không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Quay lại")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Hủy lịch", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      bool success = await AdminApiService.cancelAppointment(id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("🗑️ Đã hủy lịch #$id")));
        setState(() {}); // Refresh danh sách
      }
    }
  }

  // 3. Hàm Xem chi tiết
  void _navigateToDetail(Appointment item) async {
    final details = await AdminApiService.getAppointmentDetails(item.appointmentId!);
    if (details != null) {
      Get.to(() => AppointmentDetailScreen(details: details));
    }
  }
}