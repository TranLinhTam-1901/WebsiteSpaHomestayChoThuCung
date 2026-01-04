import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../services/admin_api_service.dart';
import '../../../model/appointment/appointment.dart';
import 'detail.dart';

class AppointmentHistoryScreen extends StatefulWidget {
  const AppointmentHistoryScreen({super.key});

  @override
  State<AppointmentHistoryScreen> createState() => _AppointmentHistoryScreenState();
}

class _AppointmentHistoryScreenState extends State<AppointmentHistoryScreen> {
  final Color pinkMain = const Color(0xFFff7aa2);
  final Color pinkLight = const Color(0xFFffe3ec);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<List<Appointment>>(
          future: AdminApiService.getAppointmentHistory(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: pinkMain));
            }
            if (snapshot.hasError) {
              return Center(child: Text("Lỗi: ${snapshot.error}"));
            }
            final appointments = snapshot.data ?? [];
            if (appointments.isEmpty) {
              return const Center(child: Text("Không có lịch sử đặt lịch nào."));
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                return _buildAppointmentCard(appointments[index]);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment item) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: pinkLight, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: pinkLight.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Mã: #${item.appointmentId}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                _buildStatusBadge(item),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                _buildRow(Icons.pets, "Thú cưng", "${item.petName} (${item.petType})"),
                const SizedBox(height: 8),
                _buildRow(Icons.content_paste, "Dịch vụ", item.serviceName),
                const SizedBox(height: 8),
                // LẤY TRỰC TIẾP timeDisplay TỪ API
                _buildRow(Icons.calendar_month, "Thời gian", item.timeDisplay),
                const Divider(height: 20),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: pinkMain),
                    const SizedBox(width: 5),
                    // CHỮ KHÁCH: NHỎ LẠI (Size 12), KHÔNG IN ĐẬM
                    Expanded(
                      child: Text(
                        "Khách: ${item.userName}",
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.normal
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        _buildSmallIconButton(
                            FontAwesomeIcons.circleInfo,
                            Colors.blue.shade200,
                                () => _navigateToDetail(item)
                        ),
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(Appointment item) async {
    final details = await AdminApiService.getAppointmentDetails(item.appointmentId!);
    if (details != null) {
      Get.to(() => AppointmentDetailScreen(details: details));
    }
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: pinkMain),
        const SizedBox(width: 10),
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
      ],
    );
  }

  Widget _buildSmallIconButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Icon(icon, size: 22, color: color),
    );
  }

  Widget _buildStatusBadge(Appointment item) {
    Color color;
    String s = item.status.toLowerCase();
    switch (s) {
      case 'confirmed': color = Colors.green; break;
      case 'pending': color = Colors.orange; break;
      case 'cancelled': color = Colors.red; break;
      case 'deleted': color = Colors.grey; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(
        item.statusDisplay,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}