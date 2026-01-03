// import 'package:flutter/material.dart';
// import 'pet/pet_profile.dart';
//
// const kPrimaryPink = Color(0xFFFFB6C1);
// const kBackgroundPink = Color(0xFFFFF0F5);
//
// class SettingsPage extends StatelessWidget {
//   const SettingsPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: kBackgroundPink,
//       appBar: AppBar(
//         backgroundColor: kPrimaryPink,
//         elevation: 0,
//         title: const Text(
//           "Cài đặt",
//           style: TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         iconTheme: const IconThemeData(color: Colors.black),
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           /// =======================
//           /// ⭐ CARD CHỨC NĂNG
//           /// =======================
//           Card(
//             elevation: 2,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Column(
//               children: [
//                 _tile(
//                   icon: Icons.palette,
//                   title: "Giao diện",
//                   onTap: () => _showThemeDialog(context),
//                 ),
//                 _divider(),
//
//                 _tile(
//                   icon: Icons.notifications,
//                   title: "Thông báo",
//                   trailing: Switch(
//                     value: true,
//                     activeColor: kPrimaryPink,
//                     onChanged: (val) {
//                       // TODO: bật / tắt thông báo
//                     },
//                   ),
//                 ),
//                 _divider(),
//
//                 /// 🐾 HỒ SƠ THÚ CƯNG
//                 _tile(
//                   icon: Icons.pets,
//                   title: "Hồ sơ thú cưng",
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => PetProfilePage(), // tạo page này
//                       ),
//                     );
//                   },
//                 ),
//                 _divider(),
//
//                 _tile(
//                   icon: Icons.local_offer,
//                   title: "Khuyến mãi của tôi",
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const MyPromotionsPage(),
//                       ),
//                     );
//                   },
//                 ),
//                 _divider(),
//
//                 _tile(
//                   icon: Icons.info,
//                   title: "Về ứng dụng",
//                   onTap: () {
//                     showAboutDialog(
//                       context: context,
//                       applicationName: "PawHouse",
//                       applicationVersion: "1.0.0",
//                       applicationIcon: const Icon(Icons.pets),
//                       children: const [
//                         SizedBox(height: 8),
//                         Text(
//                           "PawHouse – Ứng dụng chăm sóc thú cưng, mua sắm và đặt lịch dịch vụ.",
//                         ),
//                         SizedBox(height: 6),
//                         Text("Liên hệ: support@pawhouse.com"),
//                       ],
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ),
//
//         ],
//       ),
//     );
//   }
//
//   /// =======================
//   /// COMPONENTS
//   /// =======================
//
//   Widget _tile({
//     required IconData icon,
//     required String title,
//     Widget? trailing,
//     VoidCallback? onTap,
//   }) {
//     return ListTile(
//       leading: Icon(icon, color: kPrimaryPink),
//       title: Text(
//         title,
//         style: const TextStyle(fontWeight: FontWeight.w600),
//       ),
//       trailing: trailing ?? const Icon(Icons.chevron_right),
//       onTap: onTap,
//     );
//   }
//
//   Widget _divider() => const Divider(height: 1);
//
//   void _showThemeDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: const Text("Chọn giao diện"),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: const Icon(Icons.light_mode),
//               title: const Text("Sáng"),
//               onTap: () {
//                 // TODO: set light theme
//                 Navigator.pop(context);
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.dark_mode),
//               title: const Text("Tối"),
//               onTap: () {
//                 // TODO: set dark theme
//                 Navigator.pop(context);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
