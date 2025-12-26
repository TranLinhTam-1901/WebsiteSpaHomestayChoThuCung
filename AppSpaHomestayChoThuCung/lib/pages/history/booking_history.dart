import 'package:flutter/material.dart';

/// ================== MÀU DÙNG CHUNG ==================
const kPrimaryPink = Color(0xFFFF6185);
const kLightPink = Color(0xFFFFB6C1);
const kBackgroundPink = Color(0xFFFFF0F5);

/// ================== ENUM ==================
enum AppointmentStatus { pending, confirmed, cancelled, deleted }
enum ServiceCategory { homestay, spa, vet }

/// ================== MODEL ==================
class Appointment {
  final String petName;
  final String petType;
  final String serviceName;
  final ServiceCategory category;
  final AppointmentStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? date;
  final TimeOfDay? time;

  Appointment({
    required this.petName,
    required this.petType,
    required this.serviceName,
    required this.category,
    required this.status,
    this.startDate,
    this.endDate,
    this.date,
    this.time,
  });
}

/// ================== DATA CỨNG ==================
final List<Appointment> demoAppointments = [
  Appointment(
    petName: "Milu",
    petType: "Chó",
    serviceName: "Homestay VIP",
    category: ServiceCategory.homestay,
    status: AppointmentStatus.pending,
    startDate: DateTime.now().add(const Duration(days: 5)),
    endDate: DateTime.now().add(const Duration(days: 8)),
  ),
  Appointment(
    petName: "Mimi",
    petType: "Mèo",
    serviceName: "Spa Trọn Gói",
    category: ServiceCategory.spa,
    status: AppointmentStatus.confirmed,
    date: DateTime.now().add(const Duration(days: 2)),
    time: const TimeOfDay(hour: 9, minute: 30),
  ),
  Appointment(
    petName: "[Đã xóa]",
    petType: "-",
    serviceName: "Khám tổng quát",
    category: ServiceCategory.vet,
    status: AppointmentStatus.cancelled,
    date: DateTime.now().subtract(const Duration(days: 1)),
    time: const TimeOfDay(hour: 14, minute: 0),
  ),
];

/// ================== PAGE ==================
class BookingHistoryPage extends StatelessWidget {
  const BookingHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundPink,
      appBar: AppBar(
        backgroundColor: kLightPink,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Lịch sử đặt lịch 📋",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: demoAppointments.isEmpty
          ? const Center(child: Text("Bạn chưa có lịch hẹn nào"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: demoAppointments.length,
        itemBuilder: (context, index) {
          return _appointmentCard(context, demoAppointments[index]);
        },
      ),
    );
  }

  /// ================== CARD ==================
  Widget _appointmentCard(BuildContext context, Appointment item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLightPink, width: 2),
        boxShadow: [
          BoxShadow(
            color: kLightPink.withOpacity(0.4),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          /// HEADER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: kBackgroundPink,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.petName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "(${item.petType})",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text("Dịch vụ: ${item.serviceName}"),
                  ],
                ),
                _statusBadge(item.status),
              ],
            ),
          ),

          /// BODY
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.schedule, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _timeDisplay(context, item),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          /// FOOTER
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _pillButton(
                  icon: Icons.info_outline,
                  text: "Chi tiết",
                  fillColor: kLightPink,
                  textColor: Colors.black,
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                if (_canEdit(item))
                  _pillButton(
                    icon: Icons.edit,
                    text: "Sửa",
                    outlineColor: Colors.green,
                    onTap: () {},
                  ),
                const SizedBox(width: 8),
                if (_canEdit(item))
                  _pillButton(
                    icon: Icons.close,
                    text: "Hủy",
                    outlineColor: Colors.red,
                    onTap: () {},
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ================== STATUS BADGE ==================
  Widget _statusBadge(AppointmentStatus status) {
    Color color;
    String text;

    switch (status) {
      case AppointmentStatus.pending:
        color = Colors.orange;
        text = "Chờ xác nhận";
        break;
      case AppointmentStatus.confirmed:
        color = Colors.green;
        text = "Đã xác nhận";
        break;
      case AppointmentStatus.cancelled:
        color = Colors.red;
        text = "Đã hủy";
        break;
      case AppointmentStatus.deleted:
        color = Colors.grey;
        text = "Đã xóa";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  /// ================== HELPERS ==================
  String _timeDisplay(BuildContext context, Appointment item) {
    if (item.category == ServiceCategory.homestay) {
      return "⏰ ${_fmt(item.startDate)} - ${_fmt(item.endDate)}";
    } else {
      final date = _fmt(item.date);
      final time = item.time != null ? item.time!.format(context) : "";
      return "⏰ $date $time";
    }
  }

  String _fmt(DateTime? d) =>
      d == null ? "N/A" : "${d.day}/${d.month}/${d.year}";

  bool _canEdit(Appointment item) {
    return item.status == AppointmentStatus.pending;
  }

  /// ================== BUTTON ==================
  Widget _pillButton({
    required IconData icon,
    required String text,
    Color? fillColor,
    Color? outlineColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    final isOutline = outlineColor != null;

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: textColor ?? outlineColor),
      label: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: textColor ?? outlineColor,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: fillColor,
        side: isOutline
            ? BorderSide(color: outlineColor!, width: 2)
            : BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
