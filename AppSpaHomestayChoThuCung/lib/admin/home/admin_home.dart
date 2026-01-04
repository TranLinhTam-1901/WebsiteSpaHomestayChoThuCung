import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controller/user_controller.dart';
import '../../Api/auth_service.dart';
import '../../auth_gate.dart';
import 'admin_sidebar.dart';
import '../blockchain/index.dart';
import '../pet/index.dart';
import '../user/index.dart';
import '../history/appointment/index.dart';
import '../history/appointment/pending.dart';
import '../history/order/index.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  String _selectedPage = "Blockchain";

  // ✅ KHỞI TẠO KEY NGAY TẠI ĐÂY ĐỂ TRÁNH LỖI NULL
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ✅ HÀM LOGOUT ĐƯỢC CẬP NHẬT
  Future<void> _handleLogout() async {
    // Đóng drawer an toàn bằng Key
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeDrawer();
    }

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header màu hồng với Icon
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFFFF6185),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.white, size: 40),
            ),

            const SizedBox(height: 20),

            const Text(
              "Xác nhận đăng xuất",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),

            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Bạn có chắc chắn muốn thoát quyền Quản trị và quay lại màn hình đăng nhập không?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
              child: Row(
                children: [
                  // Nút Hủy
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFFF6185)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Get.back(),
                      child: const Text("Hủy", style: TextStyle(color: Color(0xFFFF6185))),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Nút Đăng xuất
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: const Color(0xFFFF6185),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        try {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();

                          AuthService.jwtToken = null;

                          if (Get.isRegistered<UserController>()) {
                            Get.find<UserController>().profile.value = null;
                          }

                          await FirebaseAuth.instance.signOut();

                          Get.offAll(() => const AuthGate());
                        } catch (e) {
                          debugPrint("Logout Error: $e");
                        }
                      },
                      child: const Text("Đăng xuất", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updatePage(String pageName) {
    setState(() {
      _selectedPage = pageName;
    });
    // Đóng drawer sau khi chọn trang trên Mobile
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeDrawer();
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isDesktop = screenWidth > 1100;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFDFDFD),
      drawer: isDesktop ? null : AdminSidebar(
        onTap: _updatePage,
        currentPage: _selectedPage,
        onLogout: _handleLogout,
      ),
      body: Row(
        children: [
          if (isDesktop)
            SizedBox(
              width: 280,
              child: AdminSidebar(
                onTap: _updatePage,
                currentPage: _selectedPage,
                onLogout: _handleLogout,
              ),
            ),
          Expanded(
            child: Column(
              children: [
                // 1. Đưa TopBar lên trên cùng, bọc SafeArea chỉ cho phần TOP
                // Điều này giúp TopBar không bị che bởi tai thỏ nhưng vẫn sát mép
                Container(
                  color: Colors.white,
                  child: SafeArea(
                    bottom: false, // Chỉ tránh tai thỏ phía trên
                    child: _buildCustomTopBar(isDesktop),
                  ),
                ),

                // 2. Nội dung chính bên dưới
                Expanded(
                  child: _buildMainBody(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Trong AdminHomeScreen
  Widget _buildCustomTopBar(bool isDesktop) {
    return Container(
      height: 60, // Cố định chiều cao để tất cả các trang đều có mốc như nhau
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            IconButton(
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              icon: const Icon(Icons.menu_rounded, color: Color(0xFFFF6185)),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _selectedPage, // Bỏ toUpperCase cho đỡ thô giống History
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D)),
            ),
          ),
          _buildTopUser(),
        ],
      ),
    );
  }

  Widget _buildTopUser() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("Admin", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text("Quản trị viên", style: TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
        const SizedBox(width: 8),
        const CircleAvatar(
          radius: 15,
          backgroundColor: Color(0xFFFFF0F5),
          child: Icon(Icons.person, color: Color(0xFFFF6185), size: 18),
        ),
        const SizedBox(width: 5),
        IconButton(
          onPressed: _handleLogout,
          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
        ),
      ],
    );
  }

  Widget _buildMainBody() {
    switch (_selectedPage) {
      case "Blockchain":
        return const BlockchainLogPage();

      case "Lịch sử đặt lịch":
      // Trang hiển thị toàn bộ lịch sử (có phân trang/lọc)
        return const AppointmentHistoryScreen();

      case "Xác nhận lịch":
      // Trang tập trung vào các đơn mới cần Admin duyệt
        return const PendingAppointmentsScreen();

      case "Quản lý tài khoản":
        return const UserManagementPage();

      case "Hồ sơ thú cưng":
        return const PetManagementScreen();

      case "Quản lý đơn hàng":
        return const AdminOrderListScreen();

      case "CSKH":
        return const Center(child: Text("Trang Chăm sóc khách hàng"));

      default:
        return const Center(child: Text("Trang đang phát triển"));
    }
  }
}