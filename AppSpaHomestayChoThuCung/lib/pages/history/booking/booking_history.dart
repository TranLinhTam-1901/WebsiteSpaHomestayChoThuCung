import 'package:flutter/material.dart';
import '../../../model/appointment/appointment.dart';
import '../../../services/api_service.dart';
import 'booking_detail.dart';
import '../../booking/book_spa.dart';
import '../../booking/book_homestay.dart';
import '../../booking/book_vet.dart';

const kPrimaryPink = Color(0xFFFF6185);
const kLightPink = Color(0xFFFFB6C1);
const kBackgroundPink = Color(0xFFFFF0F5);

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
    return Scaffold(
      backgroundColor: kBackgroundPink,
      appBar: AppBar(
        backgroundColor: kLightPink,
        elevation: 0,
        title: const Text(
          "📅 Lịch sử đặt lịch",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<List<Appointment>>(
        future: appointmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Bạn chưa có lịch hẹn nào"));
          }

          final list = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) => _appointmentCard(context, list[i]),
          );
        },
      ),
    );
  }

  // ================= CARD =================
  Widget _appointmentCard(BuildContext context, Appointment a) {
    final now = DateTime.now();
    final statusKey = _normalizeStatus(a.status);

    final isHomestay = a.startDate != null && a.endDate != null;

    bool canEditOrCancel = false;
    if (statusKey == 'pending') {
      if (isHomestay && a.startDate != null) {
        canEditOrCancel = a.startDate!.difference(now).inDays >= 2;
      } else if (!isHomestay && a.appointmentDate != null) {
        canEditOrCancel = a.appointmentDate!.difference(now).inDays >= 1;
      }
    }

    final petName =
    a.petName.isNotEmpty ? a.petName : "[Đã xóa]";
    final petType =
    a.petType.isNotEmpty ? a.petType : "-";

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: kLightPink, width: 2),
      ),
      child: Column(
        children: [
          // ===== HEADER =====
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              color: kBackgroundPink,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== TÊN THÚ CƯNG =====
                      Text(
                        petName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // ===== DỊCH VỤ =====
                      Text(
                        "🐾 $petType • ${a.serviceName}",
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // ===== NGÀY / GIỜ (ĐƯA LÊN ĐÂY) =====
                      Text(
                        isHomestay
                            ? "🏠 ${_formatDate(a.startDate)} → ${_formatDate(a.endDate)}"
                            : "⏰ ${_formatDate(a.appointmentDate)} ${a.appointmentTime ?? ''}",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),

                      if (a.petName.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            "⚠️ Thú cưng đã bị xoá",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.redAccent,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _statusBadge(a.status),
              ],
            ),
          ),

          // ===== FOOTER =====
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                const Spacer(), // ⭐ đẩy toàn bộ nút sang phải
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _actionButton(
                      label: "Xem chi tiết",
                      icon: Icons.info_outline,
                      bg: kLightPink,
                      textColor: Colors.black,
                      onTap: () async {
                        try {
                          final detail = await ApiService.getAppointmentDetail(a.appointmentId!);
                          if (!context.mounted) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingDetailPage(appointmentId: detail.appointmentId!),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Không tải được chi tiết lịch hẹn: $e'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },

                    ),
                    if (canEditOrCancel)
                      _outlineButton(
                        label: "Sửa",
                        color: Colors.green,
                        onTap: () async {
                          // 1. Khai báo targetPage có thể null hoặc gán mặc định để tránh lỗi compile
                          Widget? targetPage;

                          // 2. Lấy category trực tiếp từ thuộc tính phẳng của Model Appointment
                          String category = a.serviceCategory ?? "";

                          if (category == "Spa") {
                            targetPage = SpaBookingPage(appointment: a.toJson());
                          } else if (category == "Vet") {
                            targetPage = VetBookingPage(appointment: a.toJson());
                          } else if (category == "Homestay" || a.isHomestay) {
                            // Ưu tiên check category chuỗi, nếu null thì check qua logic date (isHomestay)
                            targetPage = HomestayBookingPage(appointment: a.toJson());
                          }

                          // 3. Chỉ chuyển trang nếu tìm thấy trang đích phù hợp
                          if (targetPage != null) {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => targetPage!),
                            );

                            if (result == true) {
                              setState(() {
                                appointmentsFuture = ApiService.getBookingHistory();
                              });
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Không xác định được loại dịch vụ để chỉnh sửa"))
                            );
                          }
                        },
                      ),

                    if (canEditOrCancel)
                      _outlineButton(
                        label: "Hủy",
                        color: Colors.red,
                        onTap: () async {
                          if (a.appointmentId == null) return;

                          // Sử dụng thuộc tính canCancel có sẵn trong Model 176 dòng của bạn để chặn sớm
                          if (!a.canCancel) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Không thể hủy lịch sát giờ quy định!"))
                            );
                            return;
                          }

                          bool confirm = await showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Xác nhận hủy"),
                              content: const Text("Bạn có chắc chắn muốn hủy lịch hẹn này không?"),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text("Không")
                                ),
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text("Có, hủy ngay", style: TextStyle(color: Colors.red))
                                ),
                              ],
                            ),
                          ) ?? false;

                          if (confirm) {
                            // Gọi API Service
                            bool success = await ApiService.cancelAppointment(a.appointmentId!);
                            if (success) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Đã hủy lịch hẹn thành công! 🎉"))
                                );
                                setState(() {
                                  appointmentsFuture = ApiService.getBookingHistory();
                                });
                              }
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Lỗi: Server từ chối yêu cầu hủy. ❌"))
                                );
                              }
                            }
                          }
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= BUTTONS =================
  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color bg,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: textColor),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      style: TextButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25)),
      ),
    );
  }

  Widget _outlineButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  // ================= HELPERS =================
  Widget _statusBadge(String status) {
    final s = _normalizeStatus(status);

    late Color c;
    late String text;

    switch (s) {
      case 'pending':
        c = Colors.orange;
        text = "Chờ xác nhận";
        break;
      case 'confirmed':
        c = Colors.green;
        text = "Đã xác nhận";
        break;
      case 'cancelled':
        c = Colors.red;
        text = "Đã hủy";
        break;
      case 'deleted':
        c = Colors.grey;
        text = "Đã xóa";
        break;
      default:
        c = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style:
        TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  String _formatDate(DateTime? d) {
    if (d == null) return "N/A";
    return "${d.day}/${d.month}/${d.year}";
  }

  String _normalizeStatus(String raw) {
    final s = raw.toLowerCase();
    if (s == '0' || s == 'pending') return 'pending';
    if (s == '1' || s == 'confirmed') return 'confirmed';
    if (s == '3' || s == 'cancelled' || s == 'canceled') return 'cancelled';
    if (s == '4' || s == 'deleted') return 'deleted';
    return raw;
  }
}
