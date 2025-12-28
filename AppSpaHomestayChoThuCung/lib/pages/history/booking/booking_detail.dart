import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import '../../../model/appointment/appointment_detail.dart';

// Đồng bộ hằng số màu sắc
const kPrimaryPink = Color(0xFFFF6185);
const kLightPink = Color(0xFFFFB6C1);
const kBackgroundPink = Color(0xFFFFF0F5);

class BookingDetailPage extends StatelessWidget {
  final int appointmentId;

  const BookingDetailPage({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundPink, // Đổi màu nền trang
      appBar: AppBar(
        title: const Text(
          '📋 Chi tiết lịch đặt',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kLightPink, // Đổi màu AppBar giống History
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<AppointmentDetail>(
        future: ApiService.getAppointmentDetail(appointmentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryPink));
          } else if (snapshot.hasError) {
            return const Center(child: Text('❌ Lỗi tải dữ liệu', style: TextStyle(color: Colors.redAccent)));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Không có dữ liệu'));
          }

          final detail = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                // 1. THÔNG TIN LỊCH ĐẶT
                _buildCardSection(
                  title: 'Thông tin lịch đặt',
                  icon: Icons.event_available,
                  content: _buildInfoTable([
                    _tableRow('Mã lịch đặt', detail.appointmentId.toString()),
                    _tableRow('Dịch vụ', detail.serviceName ?? 'N/A'),
                    _tableRow('Loại dịch vụ', detail.serviceCategory ?? 'N/A'),
                    _tableRow('Trạng thái', detail.statusDisplay, isStatus: true),
                    if (detail.isHomestay) ...[
                      _tableRow('Ngày nhận', detail.startDate ?? 'N/A'),
                      _tableRow('Ngày trả', detail.endDate ?? 'N/A'),
                    ] else ...[
                      _tableRow('Thời gian hẹn',
                          '${detail.appointmentDate ?? 'N/A'} ${detail.appointmentTime ?? ''}'),
                    ],
                    _tableRow('Thời điểm đặt', detail.createdDate ?? 'N/A'),
                    _tableRow('SĐT liên hệ', detail.ownerPhoneNumber ?? 'N/A'),
                    _tableRow('Ghi chú', (detail.note == null || detail.note!.isEmpty) ? 'Không có' : detail.note!),
                  ]),
                ),

                const SizedBox(height: 20),

                // 1. Cập nhật tiêu đề Card dựa trên trạng thái xóa
                _buildCardSection(
                  title: (detail.pet?.isDeleted ?? false)
                      ? 'Thông tin thú cưng (Đã xóa)'
                      : 'Thông tin thú cưng',
                  icon: Icons.pets,
                  content: _buildPetDetails(detail),
                ),

                const SizedBox(height: 20),

                // 2. Logic ẩn/hiện Lịch sử dịch vụ giống như @if trong C#
                if (!(detail.pet?.isDeleted ?? false))
                  _buildCardSection(
                    title: 'Lịch sử dịch vụ của thú cưng',
                    icon: Icons.history,
                    content: _buildServiceHistory(detail),
                  )
                else
                  _buildCardSection(
                    title: 'Lịch sử dịch vụ',
                    icon: Icons.history_toggle_off,
                    content: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Thú cưng đã bị xóa nên lịch sử dịch vụ không còn hiển thị.',
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54),
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

  Widget _buildPetDetails(AppointmentDetail detail) {
    final p = detail.pet;
    if (p == null) return const Padding(padding: EdgeInsets.all(16), child: Text("Không có thông tin thú cưng"));

    final bool isDeleted = p.isDeleted ?? false;

    // Việt hóa giới tính
    String genderVietnamese = "N/A";
    if (p.gender?.toLowerCase() == 'male') genderVietnamese = "Đực";
    else if (p.gender?.toLowerCase() == 'female') genderVietnamese = "Cái";

    // Các hàng thông tin cơ bản
    List<TableRow> rows = [
      _tableRow('Tên thú cưng', p.name ?? 'N/A'),
      _tableRow('Loại', p.type ?? 'N/A'),
      _tableRow('Giống', p.breed ?? 'N/A'),
      _tableRow('Giới tính', genderVietnamese),
      _tableRow('Tuổi', p.age?.toString() ?? 'N/A'),
      _tableRow('Cân nặng', p.weight != null ? '${p.weight} kg' : 'N/A'),
    ];

    if (!isDeleted) {
      // Nếu chưa xóa thì thêm các hàng chi tiết vào Table
      rows.addAll([
        _tableRow('Dấu hiệu nhận dạng', p.distinguishingMarks ?? 'N/A'),
        _tableRow('Tiêm phòng', p.vaccinationRecords ?? 'N/A'),
        _tableRow('Lịch sử bệnh', p.medicalHistory ?? 'N/A'),
        _tableRow('Dị ứng', p.allergies ?? 'N/A'),
        _tableRow('Chế độ ăn', p.dietPreferences ?? 'N/A'),
        _tableRow('Ghi chú sức khỏe', p.healthNotes ?? 'N/A'),
        _tableRow('Kết quả AI', p.aiAnalysisResult ?? 'N/A'),
      ]);
    } else {
      // Nếu đã xóa thì thêm hàng Ghi chú vào Table
      rows.add(_tableRow('Ghi chú', 'Đã bị xóa', isStatus: true));
    }

    return Column(
      children: [
        _buildInfoTable(rows), // Hiển thị bảng trước
        if (isDeleted) // Nếu xóa thì hiện dòng thông báo full width ở dưới bảng
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: kBackgroundPink, width: 1)),
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
    );
  }

  Widget _buildServiceHistory(AppointmentDetail detail) {
    final records = detail.pet?.serviceRecords ?? [];
    if (records.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Chưa có lịch sử dịch vụ.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54)),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 40,
        headingRowColor: MaterialStateProperty.all(kLightPink.withOpacity(0.5)),
        columns: const [
          DataColumn(label: Text('Dịch vụ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          DataColumn(label: Text('Ngày dùng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          DataColumn(label: Text('Giá tiền', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        ],
        rows: records.map((r) {
          return DataRow(cells: [
            DataCell(Text(r.serviceName ?? 'N/A', style: const TextStyle(fontSize: 12))),
            DataCell(Text(r.dateUsed?.toString() ?? 'N/A', style: const TextStyle(fontSize: 12))),
            DataCell(Text(
              r.price != null
                  ? NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(r.price)
                  : 'Miễn phí',
              style: const TextStyle(fontSize: 12),
            )),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildCardSection({required String title, required IconData icon, required Widget content}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kLightPink, width: 2),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: kPrimaryPink.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: kBackgroundPink, // Header Card cùng màu nền App
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: kPrimaryPink, size: 20),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          content,
        ],
      ),
    );
  }

  Widget _buildInfoTable(List<TableRow> rows) {
    return Table(
      columnWidths: const {0: FixedColumnWidth(130)},
      children: rows,
    );
  }

  TableRow _tableRow(String label, String value, {bool isStatus = false}) {
    Color valueColor = Colors.black87;

    if (isStatus) {
      // Chuyển tất cả về chữ thường để so sánh chính xác nhất
      final lowerValue = value.toLowerCase();

      if (lowerValue.contains('chờ')) {
        valueColor = Colors.orange;
      } else if (lowerValue.contains('xác nhận')) {
        // Lưu ý: 'đã xác nhận' chứa 'xác nhận'
        valueColor = Colors.green;
      } else if (lowerValue.contains('hủy')) {
        valueColor = Colors.red;
      } else if (lowerValue.contains('xóa')) {
        valueColor = Colors.grey;
      }
    }

    return TableRow(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: kBackgroundPink, width: 1)),
          ),
          child: Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 13)),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: kBackgroundPink, width: 1)),
          ),
          child: Text(
            value,
            style: TextStyle(
                fontWeight: isStatus ? FontWeight.bold : FontWeight.normal,
                color: valueColor, // Bây giờ màu sẽ thay đổi chính xác
                fontSize: 13
            ),
          ),
        ),
      ],
    );
  }
}