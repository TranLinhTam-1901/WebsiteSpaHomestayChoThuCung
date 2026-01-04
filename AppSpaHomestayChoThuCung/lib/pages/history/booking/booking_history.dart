import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../model/appointment/appointment.dart';
import '../../../services/api_service.dart';
import 'booking_detail.dart';
import '../../booking/book_spa.dart';
import '../../booking/book_homestay.dart';
import '../../booking/book_vet.dart';

// Hằng số màu sắc đồng bộ
const kLightPink = Color(0xFFFFB6C1);
const kBackgroundLight = Color(0xFFF9F9F9);

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  late Future<List<Appointment>> appointmentsFuture;

  @override
  void initState() {
    super.initState();
    appointmentsFuture = ApiService.getBookingHistory();
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
          "Lịch sử đặt lịch",
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
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            appointmentsFuture = ApiService.getBookingHistory();
          });
        },
        child: FutureBuilder<List<Appointment>>(
          future: appointmentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: kLightPink));
            }
            if (snapshot.hasError) {
              return Center(child: Text("Lỗi: ${snapshot.error}", style: const TextStyle(color: Colors.grey)));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 60, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text("Bạn chưa có lịch hẹn nào", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            final list = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: list.length,
              itemBuilder: (_, i) => _appointmentCard(context, list[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _appointmentCard(BuildContext context, Appointment a) {
    final now = DateTime.now();
    final statusKey = _normalizeStatus(a.status);
    final isHomestay = a.startDate != null && a.endDate != null;

    // Logic kiểm tra quyền chỉnh sửa/hủy
    bool canEditOrCancel = false;
    if (statusKey == 'pending') {
      if (isHomestay && a.startDate != null) {
        canEditOrCancel = a.startDate!.difference(now).inDays >= 2;
      } else if (!isHomestay && a.appointmentDate != null) {
        canEditOrCancel = a.appointmentDate!.difference(now).inDays >= 1;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          children: [
            // HEADER CỦA CARD (Tên thú cưng và Trạng thái)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: kLightPink.withOpacity(0.2),
                        radius: 18,
                        child: const Icon(Icons.pets, color: Colors.pinkAccent, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.petName.isNotEmpty ? a.petName : "[Đã xóa]",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            a.serviceCategory ?? "Dịch vụ",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _statusBadge(a.status),
                ],
              ),
            ),

            const Divider(height: 1, indent: 16, endIndent: 16),

            // NỘI DUNG CHI TIẾT
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _infoRow(Icons.settings_suggest_outlined, "Dịch vụ", a.serviceName),
                  const SizedBox(height: 8),
                  _infoRow(
                    isHomestay ? Icons.calendar_today_outlined : Icons.access_time_outlined,
                    isHomestay ? "Thời gian" : "Lịch hẹn",
                    isHomestay
                        ? "${_formatDate(a.startDate)} → ${_formatDate(a.endDate)}"
                        : "${_formatDate(a.appointmentDate)}  |  ${a.appointmentTime ?? ''}",
                  ),
                ],
              ),
            ),

            // NÚT THAO TÁC
            Container(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  const Spacer(),
                  _actionButton(
                    label: "Chi tiết",
                    icon: Icons.info_outline,
                    color: Colors.grey.shade700,
                    onTap: () async {
                      try {
                        final detail = await ApiService.getAppointmentDetail(a.appointmentId!);
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => BookingDetailPage(appointmentId: detail.appointmentId!)),
                        );
                      } catch (e) {
                        _showMsg(context, "Không tải được chi tiết");
                      }
                    },
                  ),
                  if (canEditOrCancel) ...[
                    const SizedBox(width: 8),
                    _actionButton(
                      label: "Sửa",
                      icon: Icons.edit_outlined,
                      color: Colors.green,
                      onTap: () => _handleEdit(context, a),
                    ),
                    const SizedBox(width: 8),
                    _actionButton(
                      label: "Hủy",
                      icon: Icons.cancel_outlined,
                      color: Colors.redAccent,
                      onTap: () => _handleCancel(context, a),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Row hiển thị thông tin nhỏ
  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  // Nút bấm kiểu Flat hiện đại
  Widget _actionButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final s = _normalizeStatus(status);
    late Color c;
    late String text;

    switch (s) {
      case 'pending': c = Colors.orange; text = "Chờ duyệt"; break;
      case 'confirmed': c = Colors.green; text = "Đã nhận"; break;
      case 'cancelled': c = Colors.red; text = "Đã hủy"; break;
      case 'deleted': c = Colors.grey; text = "Đã xóa"; break;
      default: c = Colors.grey; text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  // --- LOGIC XỬ LÝ ---

  void _handleEdit(BuildContext context, Appointment a) async {
    Widget? targetPage;
    String category = a.serviceCategory ?? "";
    if (category == "Spa") targetPage = SpaBookingPage(appointment: a.toJson());
    else if (category == "Vet") targetPage = VetBookingPage(appointment: a.toJson());
    else if (category == "Homestay" || a.isHomestay) targetPage = HomestayBookingPage(appointment: a.toJson());

    if (targetPage != null) {
      final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => targetPage!));
      if (result == true) setState(() { appointmentsFuture = ApiService.getBookingHistory(); });
    }
  }

  void _handleCancel(BuildContext context, Appointment a) async {
    if (!a.canCancel) {
      _showMsg(context, "Không thể hủy lịch sát giờ!");
      return;
    }
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Xác nhận hủy"),
        content: const Text("Bạn có chắc chắn muốn hủy lịch hẹn này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Quay lại")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Hủy lịch", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      bool success = await ApiService.cancelAppointment(a.appointmentId!);
      if (success) {
        _showMsg(context, "Đã hủy lịch thành công 🎉");
        setState(() { appointmentsFuture = ApiService.getBookingHistory(); });
      }
    }
  }

  void _showMsg(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  String _formatDate(DateTime? d) => d == null ? "N/A" : DateFormat('dd/MM/yyyy').format(d);

  String _normalizeStatus(String raw) {
    final s = raw.toLowerCase();
    if (s == '0' || s == 'pending') return 'pending';
    if (s == '1' || s == 'confirmed') return 'confirmed';
    if (s == '3' || s == 'cancelled' || s == 'canceled') return 'cancelled';
    if (s == '4' || s == 'deleted' || s == 'deleted') return 'deleted';
    return raw;
  }
}