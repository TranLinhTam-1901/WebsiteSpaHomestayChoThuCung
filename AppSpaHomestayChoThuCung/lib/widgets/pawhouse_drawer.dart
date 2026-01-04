import 'package:flutter/material.dart';
import 'package:baitap1/pages/home/setting.dart';
import 'package:get/get.dart';
import 'package:baitap1/controller/user_controller.dart';
import '../pages/service/homestay_page.dart';
import '../pages/service/spa_page.dart';
import '../pages/service/vet_page.dart';
import '../pages/booking/booking_select.dart';
import '../pages/history/booking/booking_history.dart';
import '../pages/history/order/order_history.dart';
import '../pages/profile/profile_page.dart';

class PawHouseDrawer extends StatelessWidget {
  final void Function(Widget screen)? onTapItem; // ⭐ callback khi chọn item
  final VoidCallback? onLogout;

  const PawHouseDrawer({super.key, this.onTapItem,this.onLogout,});

  static const Color kPrimaryPink = Color(0xFFFFB6C1);
  static const Color kBackgroundPink = Color(0xFFFFF0F5);

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();
    return Drawer(
      backgroundColor: kBackgroundPink,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: kPrimaryPink),
            child: Obx(() {
              final profile = userController.profile.value;

              if (profile == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🌸 LOGO
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 50,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// 👤 AVATAR + TÊN (BẤM ĐƯỢC)
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfilePage(profile: profile),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white,
                          child: Text(
                            profile.fullName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.black54),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),

          // Drawer – Dịch vụ
          _item("Homestay", Icons.hotel, () {
            Navigator.pop(context); // đóng Drawer
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomestayPage()),
            );
          }),
          _item("Spa", Icons.spa, () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SpaPage()),
            );
          }),
          _item("Vet", Icons.local_hospital, () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VetPage()),
            );
          }),
          const Divider(),

          // Drawer – Lịch sử
          _item("Đặt lịch", Icons.calendar_month, () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const BookingSelectPage(),
              ),
            );
          }),

          _item("Lịch sử đặt lịch", Icons.event_note, () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const BookingHistoryPage(),
              ),
            );
          }),

          _item("Lịch sử đặt hàng", Icons.receipt_long, () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderHistoryPage(),
              ),
            );
          }),

          const Divider(),

          // // Drawer – Cài đặt
          // _item("Cài đặt", Icons.settings, () {
          //   Navigator.pop(context); // Đóng drawer
          //   Navigator.push(
          //     context,
          //     MaterialPageRoute(builder: (_) => SettingsPage()),
          //   );
          // }),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              "Đăng xuất",
              style: TextStyle(color: Colors.red),
            ),
            onTap: onLogout,
          ),

        ],
      ),
    );
  }

  ListTile _item(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(color: Colors.black87)),
      onTap: onTap,
    );
  }
}
