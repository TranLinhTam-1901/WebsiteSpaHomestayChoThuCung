import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import '../../../model/appointment/appointment_detail.dart';

const kLightPink = Color(0xFFFFB6C1);
const kBackgroundLight = Color(0xFFF9F9F9);

class BookingDetailPage extends StatelessWidget {
  final int appointmentId;

  const BookingDetailPage({super.key, required this.appointmentId});

  // Hàm helper để check dữ liệu trống
  String _validate(String? value) {
    if (value == null || value.trim().isEmpty || value == 'N/A') {
      return "Không có";
    }
    return value;
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
          'Chi tiết lịch đặt',
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
      body: FutureBuilder<AppointmentDetail>(
        future: ApiService.getAppointmentDetail(appointmentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kLightPink));
          } else if (snapshot.hasError) {
            return const Center(child: Text('Lỗi tải dữ liệu', style: TextStyle(color: Colors.grey)));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Không có dữ liệu'));
          }

          final detail = snapshot.data!;
          final bool isPetDeleted = detail.pet?.isDeleted ?? false;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                // 1. CARD THÔNG TIN LỊCH HẸN
                _buildCardSection(
                  title: 'Thông tin lịch đặt',
                  icon: Icons.event_note_outlined,
                  content: Column(
                    children: [
                      _infoTile('Mã lịch', '#${detail.appointmentId}'),
                      _infoTile('Dịch vụ', _validate(detail.serviceName)),
                      _infoTile('Phân loại', _validate(detail.serviceCategory)),
                      _infoTile('Trạng thái', _validate(detail.statusDisplay), isStatus: true),
                      if (detail.isHomestay) ...[
                        _infoTile('Ngày nhận', _validate(detail.startDate)),
                        _infoTile('Ngày trả', _validate(detail.endDate)),
                      ] else ...[
                        _infoTile('Thời gian', '${_validate(detail.appointmentDate)} | ${_validate(detail.appointmentTime)}'),
                      ],
                      _infoTile('SĐT liên hệ', _validate(detail.ownerPhoneNumber)),
                      _infoTile('Ghi chú', _validate(detail.note)),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. CARD THÔNG TIN THÚ CƯNG
                _buildCardSection(
                  title: isPetDeleted ? 'Thú cưng (Đã xóa)' : 'Thông tin thú cưng',
                  icon: Icons.pets_outlined,
                  content: _buildPetDetails(detail),
                ),

                const SizedBox(height: 16),

                // 3. CARD LỊCH SỬ DỊCH VỤ
                if (!isPetDeleted)
                  _buildCardSection(
                    title: 'Lịch sử dịch vụ thú cưng',
                    icon: Icons.history_outlined,
                    content: _buildServiceHistory(detail),
                  )
                else
                  _buildCardSection(
                    title: 'Lịch sử dịch vụ',
                    icon: Icons.history_toggle_off,
                    content: const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Thú cưng đã bị xóa nên lịch sử dịch vụ không còn hiển thị.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 13),
                      ),
                    ),
                  ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardSection({required String title, required IconData icon, required Widget content}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: Colors.pinkAccent, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          content,
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value, {bool isStatus = false}) {
    Color valColor = Colors.black87;
    if (isStatus) {
      final s = value.toLowerCase();
      if (s.contains('chờ')) valColor = Colors.orange;
      else if (s.contains('xác nhận')) valColor = Colors.green;
      else if (s.contains('hủy')) valColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: isStatus ? FontWeight.bold : FontWeight.w500,
                color: valColor,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetDetails(AppointmentDetail detail) {
    final p = detail.pet;
    if (p == null) return const Padding(padding: EdgeInsets.all(16), child: Text("Không có dữ liệu"));

    final bool isDeleted = p.isDeleted ?? false;

    // 1. Xử lý Giới tính
    String gender = "Không có";
    if (p.gender?.toLowerCase() == 'male') gender = "Đực";
    else if (p.gender?.toLowerCase() == 'female') gender = "Cái";

    // 2. Xử lý các trường số kèm đơn vị (Logic đồng bộ)
    String ageDisplay = (p.age != null) ? "${p.age} tuổi" : "Không có";
    String weightDisplay = (p.weight != null) ? "${p.weight} kg" : "Không có";
    String heightDisplay = (p.height != null) ? "${p.height} cm" : "Không có";

    return Column(
      children: [
        // --- NHÓM THÔNG TIN CƠ BẢN ---
        _infoTile('Tên thú cưng', _validate(p.name)),
        _infoTile('Loại/Giống', '${_validate(p.type)} | ${_validate(p.breed)}'),
        _infoTile('Giới tính', gender),
        _infoTile('Tuổi', ageDisplay),
        _infoTile('Cân nặng', weightDisplay),

        if (!isDeleted) ...[
          // --- NHÓM THÔNG TIN CHI TIẾT (Hiển thị đầy đủ khi chưa xóa) ---
          _infoTile('Chiều cao', heightDisplay),
          _infoTile('Màu lông', _validate(p.color)), // Thêm Màu lông
          _infoTile('Dấu hiệu nhận dạng', _validate(p.distinguishingMarks)),
          _infoTile('Tiêm phòng', _validate(p.vaccinationRecords)),
          _infoTile('Lịch sử bệnh', _validate(p.medicalHistory)),
          _infoTile('Dị ứng', _validate(p.allergies)),
          _infoTile('Chế độ ăn', _validate(p.dietPreferences)),
          _infoTile('Ghi chú sức khỏe', _validate(p.healthNotes)),
          _infoTile('Kết quả AI', _validate(p.aiAnalysisResult)),
        ] else ...[
          // Thông báo khi thú cưng đã bị xóa
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
            ),
            child: const Text(
              "Các thông tin khác không còn hiển thị vì thú cưng đã bị xóa.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildServiceHistory(AppointmentDetail detail) {
    final records = detail.pet?.serviceRecords ?? [];
    if (records.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text('Chưa có lịch sử dịch vụ.', style: TextStyle(color: Colors.grey, fontSize: 13)),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 25,
          headingRowHeight: 40,
          horizontalMargin: 16,
          columns: const [
            DataColumn(label: Text('Dịch vụ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Ngày dùng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Giá tiền', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          ],
          rows: records.map((r) {
            return DataRow(cells: [
              DataCell(Text(_validate(r.serviceName), style: const TextStyle(fontSize: 12))),
              DataCell(Text(_validate(r.dateUsed?.toString()), style: const TextStyle(fontSize: 12))),
              DataCell(Text(
                r.price != null ? NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(r.price) : 'Không có',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}