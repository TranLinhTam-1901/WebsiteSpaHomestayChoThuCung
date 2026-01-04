import 'package:flutter/material.dart';
import 'dart:convert'; // Bắt buộc phải có để dùng json.decode và JsonEncoder
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/admin_api_service.dart';
import '../../model/Blockchain/blockchain_record.dart'; // Đường dẫn tới file model của bạn

class PetBlockchainScreen extends StatefulWidget {
  final int petId;
  final String petName;

  const PetBlockchainScreen({
    super.key,
    required this.petId,
    required this.petName
  });

  @override
  State<PetBlockchainScreen> createState() => _PetBlockchainScreenState();
}

class _PetBlockchainScreenState extends State<PetBlockchainScreen> {
  late Future<Map<String, dynamic>> _blockchainFuture;

  @override
  void initState() {
    super.initState();
    _blockchainFuture = AdminApiService.getPetBlockchain(widget.petId);
  }

  // Hàm xác định màu sắc dựa trên hành động (Operation)
  Color _getStatusColor(String operation) {
    String op = operation.toUpperCase();
    if (op.contains('ADD') || op.contains('CONFIRM')) return Colors.green;
    if (op.contains('UPDATE')) return Colors.orange;
    return Colors.red; // DELETE hoặc các lỗi khác
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          "Blockchain: ${widget.petName}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFB6C1),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _blockchainFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6185)));
          }

          if (snapshot.hasError || !snapshot.hasData || (snapshot.data!['records'] as List).isEmpty) {
            return _buildEmptyState();
          }

          final List<dynamic> rawRecords = snapshot.data!['records'];
          // Map dữ liệu sang Model BlockchainRecord bạn đã viết
          final records = rawRecords.map((json) => BlockchainRecord.fromJson(json)).toList();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            itemCount: records.length,
            itemBuilder: (context, index) {
              return _buildTimelineItem(records[index], index == records.length - 1);
            },
          );
        },
      ),
    );
  }

  Widget _buildTimelineItem(BlockchainRecord record, bool isLast) {
    Color statusColor = _getStatusColor(record.operation);

    return IntrinsicHeight(
      child: Row(
        children: [
          // Cột Timeline (Đường kẻ và nút tròn)
          Column(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor, width: 3),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: statusColor.withOpacity(0.3)),
                ),
            ],
          ),
          const SizedBox(width: 15),

          // Nội dung Card bản ghi
          Expanded(
            child: GestureDetector(
              onTap: () => _showBlockDetails(record),
              child: Container(
                margin: const EdgeInsets.only(bottom: 25),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Block #${record.blockNumber}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pinkAccent),
                        ),
                        _buildStatusBadge(record.operation, statusColor),
                      ],
                    ),
                    const Divider(height: 24),
                    _infoRow(Icons.category_outlined, "Loại: ${record.recordType}"),
                    _infoRow(Icons.access_time_rounded, "Lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(record.timestamp.toLocal())}"),
                    _infoRow(Icons.person_outline, "Bởi: ${record.performedBy ?? 'Hệ thống'}"),
                    const SizedBox(height: 10),
                    const Text(
                      "Chạm để xem mã Hash minh bạch ➔",
                      style: TextStyle(fontSize: 11, color: Colors.blue, fontStyle: FontStyle.italic),
                      maxLines: 1, // Đảm bảo không nhảy dòng làm tràn card
                      overflow: TextOverflow.ellipsis, // Nếu quá dài sẽ hiện "..."
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 13))),
        ],
      ),
    );
  }

  // --- HIỂN THỊ CHI TIẾT MÃ HASH ---
  void _showBlockDetails(BlockchainRecord record) {
    // Xác định màu sắc dựa trên hành động (Operation)
    Color getStatusColor(String op) {
      op = op.toUpperCase();
      if (op.contains('ADD') || op.contains('CONFIRM')) return Colors.green;
      if (op.contains('UPDATE') || op.contains('EDIT')) return Colors.orange;
      return Colors.red; // DELETE hoặc mặc định
    }

    Color statusColor = getStatusColor(record.operation);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        // Tăng chiều cao lên 0.85 để dễ nhìn hơn trên mobile
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh gạch ngang nhỏ trên đầu modal cho đẹp
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const Text("🔗 Thông tin xác thực Blockchain",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 30),

            // Bọc phần nội dung vào Expanded và ScrollView để không bị lỗi overflow
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge trạng thái mới
                    const Text("Hành động", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        record.operation,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _detailItem("Mã Hash hiện tại", record.hash, isCode: true, color: Colors.blue[700]),
                    _detailItem("Mã Hash trước đó", record.previousHash, isCode: true, color: Colors.blueGrey),

                    const Text(
                      "DỮ LIỆU GỐC (JSON)",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black, letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 8),
                    _buildJsonBox(record.dataJson), // Gọi hàm làm đẹp JSON tại đây
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6185),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  padding: const EdgeInsets.all(15),
                  elevation: 0,
                ),
                child: const Text("Xác nhận minh bạch",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailItem(String label, String value, {bool isCode = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: Colors.black,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCode ? Colors.grey[50] : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: SelectableText(
              value.isEmpty ? "N/A" : value,
              style: TextStyle(
                fontFamily: isCode ? 'monospace' : null,
                fontSize: 13,
                color: color ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FontAwesomeIcons.linkSlash, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text("Chưa có hồ sơ được ghi vào chuỗi khối", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildJsonBox(String rawJson) {
    String prettyJson = "";
    try {
      // 1. Giải mã chuỗi String thành Map/List
      var decoded = json.decode(rawJson);

      // 2. Định dạng lại với thụt đầu dòng (indent).
      // LƯU Ý: Không dùng 'const' ở đây.
      prettyJson = JsonEncoder.withIndent('  ').convert(decoded);
    } catch (e) {
      prettyJson = rawJson; // Nếu lỗi parse thì hiện chuỗi thô
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Nền tối kiểu Carbon
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // Cho phép cuộn ngang nếu dòng quá dài
        child: SelectableText(
          prettyJson,
          style: const TextStyle(
            color: Colors.white, // Màu xanh dương nhạt (giống VS Code)
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}