import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/admin_api_service.dart';
import '../../model/user/user_profile.dart';
import 'detail.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  late Future<List<UserProfile>> _userFuture;
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  static const Color pinkPrimary = Color(0xFFFF6185);
  static const Color bgLight = Color(0xFFFFF9FA);

  @override
  void initState() {
    super.initState();
    // Khởi tạo Future lần đầu không dùng setState để tránh lỗi frame
    _userFuture = _loadData();
  }

  void _refreshUsers() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _userFuture = _loadData();
        });
      }
    });
  }

  Future<List<UserProfile>> _loadData() async {
    final token = await AdminApiService.getToken();
    if (token == null) throw Exception("Unauthorized");
    return await AdminApiService.getUserList(token, search: searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomSearchBar(),
            Expanded(
              child: FutureBuilder<List<UserProfile>>(
                future: _userFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: pinkPrimary));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Lỗi: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                  }

                  final users = snapshot.data ?? [];
                  if (users.isEmpty) {
                    return const Center(child: Text("Trống"));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
                    physics: const BouncingScrollPhysics(),
                    itemCount: users.length,
                    itemBuilder: (context, index) => _buildUserCard(users[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomSearchBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: pinkPrimary.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) {
            // Cập nhật text nhưng không refresh liên tục để tránh lỗi MouseTracker
            searchQuery = val;
          },
          onSubmitted: (val) {
            _refreshUsers(); // Chỉ refresh khi nhấn Enter
          },
          decoration: InputDecoration(
            hintText: "Tìm tên, email...",
            prefixIcon: const Icon(Icons.search, color: pinkPrimary),
            suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  searchQuery = "";
                  _refreshUsers();
                }
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(UserProfile user) {
    bool isAdmin = user.role.toLowerCase().contains('admin');
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: pinkPrimary.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildUserAvatar(isAdmin),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(user.email, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  const SizedBox(height: 6),
                  _buildStatusChip(user.isLocked),
                ],
              ),
            ),
            _buildActionButtons(user, isAdmin),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isLocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isLocked ? Colors.red : Colors.green).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isLocked ? "Đã khóa" : "Hoạt động",
        style: TextStyle(color: isLocked ? Colors.red : Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _handleToggleLock(UserProfile user) async {
    try {
      final token = await AdminApiService.getToken();
      if (token == null) return;

      bool success = user.isLocked
          ? await AdminApiService.unlockUser(token, user.id)
          : await AdminApiService.lockUser(token, user.id);

      if (success) {
        _refreshUsers(); // Đã được bọc addPostFrameCallback bên trong hàm này
      }
    } catch (e) {
      debugPrint("Lỗi cập nhật: $e");
    }
  }

  Widget _buildUserAvatar(bool isAdmin) {
    return Container(
      width: 55, height: 55,
      decoration: BoxDecoration(
        color: (isAdmin ? Colors.orange : pinkPrimary).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(isAdmin ? Icons.admin_panel_settings : Icons.person, color: isAdmin ? Colors.orange : pinkPrimary, size: 26),
    );
  }

  Widget _buildActionButtons(UserProfile user, bool isAdmin) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Nút Khóa/Mở khóa đưa lên trước
        if (!isAdmin) ...[
          _buildCircleBtn(
            icon: user.isLocked ? FontAwesomeIcons.lockOpen : FontAwesomeIcons.lock,
            color: user.isLocked ? Colors.green.shade300 : Colors.red.shade300,
            onTap: () => _handleToggleLock(user),
          ),
          const SizedBox(width: 8), // Khoảng cách giữa hai nút
        ],

        // 2. Nút Sửa đưa ra sau
        _buildCircleBtn(
            icon: FontAwesomeIcons.penToSquare,
            color: Colors.orange.shade300,
            onTap: () async {
              // Chuyển hướng sang trang Edit và chờ kết quả trả về
              bool? refresh = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserEditScreen(user: user)),
              );

              // Nếu trang Edit trả về true, load lại danh sách
              if (refresh == true) {
                _refreshUsers();
              }
            }
        ),
      ],
    );
  }

  Widget _buildCircleBtn({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell( // Dùng InkWell thay cho GestureDetector trên Web để xử lý hover/click tốt hơn
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}