import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  final Function(String) onTap;
  final String currentPage;
  final VoidCallback onLogout;

  const AdminSidebar({
    super.key,
    required this.onTap,
    required this.currentPage,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(right: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
        ),
        child: Column(
          children: [
            _buildSidebarHeader(),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildMenuItem(context, "Blockchain", Icons.auto_awesome_mosaic_rounded),
                  _buildMenuItem(context, "Hồ sơ thú cưng", Icons.pets_rounded),
                  _buildMenuItem(context, "CSKH", Icons.support_agent_rounded),
                  _buildMenuItem(context, "Danh Mục", Icons.category),

                  const Divider(color: Color(0xFFEEEEEE), height: 30),

                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text("v1.0.2 - PetChain", style: TextStyle(color: Colors.grey, fontSize: 10)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      height: 150,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      alignment: Alignment.bottomLeft,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFFFF6185),
            child: Icon(Icons.admin_panel_settings, color: Colors.white),
          ),
          SizedBox(height: 12),
          Text(
            "ADMIN PANEL",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFFFF6185),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon) {
    bool isSelected = currentPage == title;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFF6185).withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFFFF6185) : Colors.grey.shade600,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFF6185) : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: () {
          // Thực hiện chuyển trang
          onTap(title);

          // Kiểm tra và đóng Drawer nếu đang mở
          final scaffold = Scaffold.maybeOf(context);
          if (scaffold != null && scaffold.hasDrawer && scaffold.isDrawerOpen) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}