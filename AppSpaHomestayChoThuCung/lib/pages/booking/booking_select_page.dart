import 'package:flutter/material.dart';
import 'book_homestay.dart';
import 'book_spa.dart';
import 'book_vet.dart';

const kPrimaryPink = Color(0xFFFF6185);
const kLightPink = Color(0xFFFFB6C1);
const kBackgroundPink = Color(0xFFFFF0F5);

class BookingSelectPage extends StatelessWidget {
  const BookingSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundPink,
      appBar: AppBar(
        backgroundColor: kLightPink,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Chọn dịch vụ đặt lịch",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Bạn muốn đặt lịch dịch vụ nào?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            /// 🏠 Homestay
            _serviceCard(
              context,
              icon: Icons.house_rounded,
              title: "Đặt lịch Homestay",
              desc: "Nơi nghỉ ngơi thoải mái cho thú cưng.",
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HomestayBookingPage(),
                  ),
                );
              },
            ),

            /// 💖 Spa
            _serviceCard(
              context,
              icon: Icons.spa,
              title: "Đặt lịch Spa",
              desc: "Chăm sóc & làm đẹp cho thú cưng.",
              color: Colors.pink,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SpaBookingPage(),
                  ),
                );
              },
            ),

            /// 🏥 Vet
            _serviceCard(
              context,
              icon: Icons.local_hospital,
              title: "Đặt lịch Thú y",
              desc: "Khám & điều trị cho thú cưng.",
              color: Colors.redAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VetBookingPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _serviceCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String desc,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
