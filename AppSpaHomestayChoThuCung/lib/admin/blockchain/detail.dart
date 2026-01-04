import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../model/Blockchain/blockchain_record.dart';

class BlockchainDetailPage extends StatelessWidget {
  final BlockchainRecord record;

  const BlockchainDetailPage({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    String prettyJson = "";
    try {
      var decoded = json.decode(record.dataJson);
      prettyJson = const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (e) {
      prettyJson = record.dataJson;
    }

    // --- LOGIC MÀU SẮC THEO YÊU CẦU ---
    Color actionColor = Colors.grey;
    String op = record.operation.toUpperCase();

    if (op.contains("CREATE") || op.contains("ADD")) {
      actionColor = Colors.green; // ADD là màu xanh lá
    } else if (op.contains("UPDATE") || op.contains("EDIT")) {
      actionColor = const Color(0xFFFFB300); // UPDATE là màu vàng hổ phách (dễ nhìn hơn vàng thuần)
    } else if (op.contains("DELETE") || op.contains("CANCEL")) {
      actionColor = Colors.red; // DELETE là màu đỏ
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      body: SafeArea(
        child: Column(
          children: [
            // Thanh điều hướng (Bỏ AppBar truyền thống)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
                  ),
                  const Text(
                    "CHI TIẾT BLOCKCHAIN",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card thông tin chính (Màu động theo hành động)
                    _buildMainCard(actionColor),

                    const SizedBox(height: 25),
                    const _SectionTitle(title: "🛡️ CHỮ KÝ SỐ (HASH)"),
                    const SizedBox(height: 12),
                    _buildHashBox("Mã Hash hiện tại", record.hash, context),
                    const SizedBox(height: 12),
                    _buildHashBox("Mã Hash trước đó", record.previousHash, context),

                    const SizedBox(height: 25),
                    const _SectionTitle(title: "📄 DỮ LIỆU JSON (TRẮNG)"),
                    const SizedBox(height: 12),
                    _buildJsonBox(prettyJson), // Chữ trắng nền tối
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem("BLOCK NUMBER", "#${record.blockNumber}"),
              _buildInfoItem("HÀNH ĐỘNG", record.operation),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(color: Colors.white30, thickness: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem("ĐỐI TƯỢNG", record.recordType),
              _buildInfoItem("THỜI GIAN", DateFormat('HH:mm dd/MM/yyyy').format(record.timestamp)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildHashBox(String label, String hash, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: hash));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã sao chép mã Hash")));
                },
                child: const Icon(Icons.copy_rounded, size: 16, color: Colors.blue),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(hash, style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black54, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildJsonBox(String jsonContent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Nền tối Carbon
        borderRadius: BorderRadius.circular(15),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          jsonContent,
          style: const TextStyle(
            color: Colors.white, // CHỮ TRẮNG THEO YÊU CẦU
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

// Widget tiêu đề phụ nhỏ gọn
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey, letterSpacing: 0.5),
    );
  }
}