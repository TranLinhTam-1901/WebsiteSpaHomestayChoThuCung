import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../model/appointment/appointment.dart';

class AppointmentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> details;

  const AppointmentDetailScreen({super.key, required this.details});

  final Color pinkMain = const Color(0xFFff7aa2);
  final Color pinkLight = const Color(0xFFFFB6C1);
  final Color greyBg = const Color(0xFFF8F9FA);

  String _formatDateNice(String? dateStr) {
    if (dateStr == null || dateStr.startsWith("0001")) return "N/A";
    try {
      DateTime dt = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (e) {
      return "N/A";
    }
  }

  String _formatCreatedDate(dynamic val) {
    if (val == null) return 'N/A';
    try {
      DateTime dt = DateTime.parse(val.toString());
      return DateFormat('dd/MM/yyyy  HH:mm').format(dt);
    } catch (_) {
      return "N/A";
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = Appointment.fromJson(details);
    final bool isHomestay = details['serviceCategory'] == "Homestay";

    return Scaffold(
      backgroundColor: greyBg,
      appBar: AppBar(
        title: const Text("Chi tiết lịch đặt",
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
            _buildStatusHeader(item),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: "Thông tin dịch vụ",
              icon: FontAwesomeIcons.paw,
              children: [
                _buildInfoRow(FontAwesomeIcons.hashtag, "Mã đơn hàng", "#${item.appointmentId}"),
                _buildInfoRow(FontAwesomeIcons.dog, "Thú cưng", "${item.petName} (${item.petType})"),
                _buildInfoRow(FontAwesomeIcons.scissors, "Dịch vụ", item.serviceName),
                const Divider(height: 20, thickness: 0.5),
                if (isHomestay) ...[
                  _buildInfoRow(FontAwesomeIcons.calendarCheck, "Ngày nhận phòng", _formatDateNice(details['startDate'])),
                  _buildInfoRow(FontAwesomeIcons.calendarMinus, "Ngày trả phòng", _formatDateNice(details['endDate'])),
                ] else ...[
                  _buildInfoRow(FontAwesomeIcons.clock, "Thời gian hẹn", "${_formatDateNice(details['appointmentDate'])}  ${details['appointmentTime']?.substring(0, 5) ?? ''}"),
                ],
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: "Thông tin liên hệ",
              icon: FontAwesomeIcons.userLarge,
              children: [
                _buildInfoRow(FontAwesomeIcons.userCircle, "Khách hàng", item.userName),
                _buildInfoRow(FontAwesomeIcons.phone, "Số điện thoại", item.ownerPhoneNumber ?? 'N/A'),
                _buildInfoRow(FontAwesomeIcons.calendarPlus, "Ngày đặt đơn", _formatCreatedDate(details['createdDate'])),
                if (details['note'] != null && details['note'].toString().isNotEmpty)
                  _buildInfoRow(FontAwesomeIcons.commentDots, "Ghi chú", details['note']),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(Appointment item) {
    String statusStr = item.statusDisplay.toLowerCase();

    IconData iconData;
    Color statusColor;

    if (item.isPending) {
      iconData = FontAwesomeIcons.hourglassHalf;
      statusColor = Colors.orange;
    } else if (statusStr.contains("hủy")) {
      iconData = FontAwesomeIcons.xmark; // Dấu X cho hủy
      statusColor = Colors.red;
    } else if (statusStr.contains("xóa")) {
      iconData = FontAwesomeIcons.trashCan; // Thùng rác cho xóa
      statusColor = Colors.grey; // Màu xám cho xóa
    } else {
      iconData = FontAwesomeIcons.check;
      statusColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(iconData, color: statusColor, size: 20),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("TRẠNG THÁI ĐƠN HÀNG", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              Text(item.statusDisplay.toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: statusColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(children: [
              Icon(icon, size: 16, color: pinkMain),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800])),
            ]),
          ),
          const Divider(height: 1, thickness: 0.5),
          Padding(padding: const EdgeInsets.all(16), child: Column(children: children)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 24,
            child: Icon(icon, size: 13, color: Colors.grey[400]),
          ),
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}