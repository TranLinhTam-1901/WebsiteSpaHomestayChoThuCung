import 'package:flutter/material.dart';
import '../../model/user/user_profile.dart';

const kPrimaryPink = Color(0xFFFFB6C1);

class ProfilePage extends StatelessWidget {
  final UserProfile profile;

  const ProfilePage({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tài khoản cá nhân"),
        backgroundColor: kPrimaryPink,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// 👤 AVATAR
            CircleAvatar(
              radius: 45,
              backgroundColor: kPrimaryPink,
              child: Text(
                profile.fullName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Text(
              profile.fullName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              profile.email,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 30),

            /// 📦 THÔNG TIN
            _infoCard(
              icon: Icons.person,
              title: "Họ và tên",
              value: profile.fullName,
            ),
            _infoCard(
              icon: Icons.email,
              title: "Email",
              value: profile.email,
            ),
            _infoCard(
              icon: Icons.phone,
              title: "Số điện thoại",
              value: profile.phone,
            ),

            const SizedBox(height: 20),

            /// ✏️ SỬA THÔNG TIN
            _actionButton(
              icon: Icons.edit,
              text: "Chỉnh sửa thông tin",
              onTap: () {
                // TODO: sang trang edit
              },
            ),

            _actionButton(
              icon: Icons.lock_outline,
              text: "Đổi mật khẩu",
              onTap: () {
                // TODO
              },
            ),

          ],
        ),
      ),
    );
  }

  /// CARD INFO
  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: kPrimaryPink),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }

  /// ACTION BUTTON
  Widget _actionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color color = kPrimaryPink,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}
