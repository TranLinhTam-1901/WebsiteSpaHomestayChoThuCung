import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/admin_api_service.dart';
import 'detail.dart';
import '../../model/blockchain/blockchain_record.dart';

class BlockchainLogPage extends StatefulWidget {
  const BlockchainLogPage({super.key});

  @override
  State<BlockchainLogPage> createState() => _BlockchainLogPageState();
}

class _BlockchainLogPageState extends State<BlockchainLogPage> {
  List<BlockchainRecord> allRecords = [];
  bool isLoading = true;
  int currentPage = 1;
  int itemsPerPage = 8;

  static const Color pinkPrimary = Color(0xFFFF6185);
  static const Color dangerRed = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _fetchBlockchainData();
  }

  Future<void> _fetchBlockchainData() async {
    setState(() => isLoading = true);
    try {
      final data = await AdminApiService.getBlockchainLogs();
      setState(() {
        allRecords = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Lỗi tại Page: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalPages = (allRecords.length / itemsPerPage).ceil();
    int startIdx = (currentPage - 1) * itemsPerPage;
    int endIdx = startIdx + itemsPerPage;
    if (endIdx > allRecords.length) endIdx = allRecords.length;

    List<BlockchainRecord> currentRecords = allRecords.isEmpty
        ? []
        : allRecords.sublist(startIdx, endIdx);

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      // SafeArea giúp nội dung không bị dính vào tai thỏ/thanh trạng thái
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchBlockchainData,
          color: pinkPrimary,
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: pinkPrimary))
              : Column(
            children: [
              // Đã bỏ hoàn toàn _buildTopHeader() ở đây
              Expanded(
                child: allRecords.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  // Thêm padding trên để không sát mép quá
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                  itemCount: currentRecords.length,
                  itemBuilder: (context, index) {
                    return _buildLogCard(currentRecords[index]);
                  },
                ),
              ),
              if (totalPages > 1) _buildPagination(totalPages),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogCard(BlockchainRecord block) {
    Color actionColor = Colors.grey;
    IconData actionIcon = FontAwesomeIcons.clockRotateLeft;
    String op = block.operation.toUpperCase();

    // Logic: CANCEL và DELETE màu đỏ + Icon dấu X
    if (op.contains("CREATE") || op.contains("ADD")) {
      actionColor = Colors.green;
      actionIcon = FontAwesomeIcons.circlePlus;
    } else if (op.contains("UPDATE") || op.contains("EDIT")) {
      actionColor = Colors.orange;
      actionIcon = FontAwesomeIcons.penToSquare;
    } else if (op.contains("DELETE") || op.contains("CANCEL")) {
      actionColor = dangerRed;
      actionIcon = FontAwesomeIcons.circleXmark;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15), // Bo góc nhẹ hơn cho hiện đại
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: actionColor.withOpacity(0.12)),
      ),
      child: InkWell(
        onTap: () {
          // Chờ cho frame hiện tại vẽ xong rồi mới push trang mới
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BlockchainDetailPage(record: block)),
            );
          });
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: actionColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(actionIcon, color: actionColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Block #${block.blockNumber}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
                            _buildBadge(op, actionColor),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text("${block.recordType}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D2D2D))),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, thickness: 0.5),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time_filled_rounded, size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(DateFormat('dd/MM HH:mm').format(block.timestamp),
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    ],
                  ),
                  const Text("Chi tiết >", style: TextStyle(color: pinkPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text("Dữ liệu trống", style: TextStyle(color: Colors.grey)),
    );
  }

  Widget _buildPagination(int total) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10, top: 5),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(total, (index) {
            int page = index + 1;
            bool isCurrent = page == currentPage;
            return GestureDetector(
              onTap: () => setState(() => currentPage = page),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isCurrent ? pinkPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isCurrent ? pinkPrimary : Colors.grey.shade200),
                ),
                child: Text(page.toString(),
                    style: TextStyle(color: isCurrent ? Colors.white : pinkPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            );
          }),
        ),
      ),
    );
  }
}