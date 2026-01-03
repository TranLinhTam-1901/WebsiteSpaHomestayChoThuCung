import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/admin_api_service.dart';
import '../../model/pet/pet.dart';
import 'detail.dart';

class PetManagementScreen extends StatefulWidget {
  const PetManagementScreen({super.key});

  @override
  _PetManagementScreenState createState() => _PetManagementScreenState();
}

class _PetManagementScreenState extends State<PetManagementScreen> {
  late Future<List<PetDetail>> _petFuture;

  static const Color pinkPrimary = Color(0xFFFF6185);
  static const Color bgLight = Color(0xFFFFF9FA);

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  void _loadPets() {
    setState(() {
      _petFuture = AdminApiService.getAllPets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        // Bỏ hoàn toàn Column Header, chỉ còn danh sách đổ từ trên xuống
        child: FutureBuilder<List<PetDetail>>(
          future: _petFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: pinkPrimary));
            }

            final pets = snapshot.data ?? [];
            if (pets.isEmpty) {
              return Center(
                child: Text("Trống", style: TextStyle(color: pinkPrimary.withOpacity(0.5))),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 80), // Padding dưới để không bị FAB đè
              physics: const BouncingScrollPhysics(),
              itemCount: pets.length,
              itemBuilder: (context, index) {
                final pet = pets[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: pinkPrimary.withOpacity(0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Icon đại diện bé
                        Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            color: pinkPrimary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(FontAwesomeIcons.paw, color: pinkPrimary, size: 22),
                        ),
                        const SizedBox(width: 15),
                        // Thông tin
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pet.name ?? "Không tên",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: Color(0xFF2D2D2D)
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pet.type ?? "Thú cưng",
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                              ),
                              const SizedBox(height: 6), // Khoảng cách nhỏ

                              // HIỂN THỊ TÊN CHỦ SỞ HỮU Ở ĐÂY
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 14, color: Color(0xFFFF6185)),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Chủ: ${pet.ownerName}",
                                    style: const TextStyle(
                                        color: Color(0xFFFF6185),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Nút Info & Xóa
                        Row(
                          children: [
                            _buildActionBtn(FontAwesomeIcons.circleInfo, Colors.blue.shade200, () {
                              final petId = pet.id; // Bây giờ id đã được map từ json['petId']

                              if (petId != null && petId != 0) {
                                debugPrint("🚀 Đang mở ID: $petId");
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => PetDetailScreen(petId: petId)),
                                );
                              } else {
                                debugPrint("❌ ID vẫn null. Kiểm tra lại Model hoặc API Danh sách");
                              }
                            }),
                            const SizedBox(width: 8),
                            _buildActionBtn(FontAwesomeIcons.trashCan, pinkPrimary.withOpacity(0.7), () => _confirmDelete(pet.id ?? 0)),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      // Nút Thêm vẫn giữ ở góc dưới để thao tác
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: pinkPrimary,
        elevation: 3,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Xóa bé?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (await AdminApiService.deletePet(id)) _loadPets();
              },
              child: const Text("Xóa", style: TextStyle(color: pinkPrimary, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}