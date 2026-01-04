import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/api_service.dart';
import 'pet_detail.dart';
import 'pet_add.dart';
import 'pet_update.dart';

// Hằng số màu sắc đồng bộ
const kLightPink = Color(0xFFFFB6C1);
const kPrimaryPink = Color(0xFFFF6185);
const kBackgroundLight = Color(0xFFF9F9F9);

class PetProfilePage extends StatefulWidget {
  const PetProfilePage({super.key});

  @override
  _PetProfilePageState createState() => _PetProfilePageState();
}

class _PetProfilePageState extends State<PetProfilePage> {
  late Future<List<dynamic>> _petFuture;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  void _loadPets() {
    setState(() {
      _petFuture = ApiService.getPets();
    });
  }

  String _getGenderText(String? gender) {
    if (gender == null) return "Không rõ";
    switch (gender.toLowerCase()) {
      case 'male': return 'Đực';
      case 'female': return 'Cái';
      default: return 'Không rõ';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Chỉnh status bar đồng bộ
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: kBackgroundLight,
      appBar: AppBar(
        title: const Text(
          "Hồ sơ thú cưng",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: kLightPink,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black, size: 26),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddPetPage()),
              );
              if (result == true) _loadPets();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadPets(),
        color: kPrimaryPink,
        child: FutureBuilder<List<dynamic>>(
          future: _petFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: kLightPink));
            } else if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            final pets = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pets.length,
              itemBuilder: (context, index) => _buildPetCard(pets[index]),
            );
          },
        ),
      ),
    );
  }

  // --- GIAO DIỆN THẺ THÚ CƯNG ---
  Widget _buildPetCard(dynamic pet) {
    String gender = _getGenderText(pet['gender']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar giả định hoặc Icon loại thú cưng
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: kLightPink.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    pet['type'].toString().toLowerCase().contains('mèo')
                        ? FontAwesomeIcons.cat
                        : FontAwesomeIcons.dog,
                    color: Colors.pinkAccent,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Thông tin chính
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet['name'] ?? "Không tên",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${pet['type']} • ${pet['breed']}",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Badge giới tính
                _buildGenderBadge(gender),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // Thông số phụ (Cân nặng)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(FontAwesomeIcons.weightScale, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Text("${pet['weight']} kg", style: const TextStyle(fontSize: 13, color: Colors.black87)),
                const Spacer(),
                // Nhóm nút bấm
                _buildSmallActionBtn(
                    icon: Icons.visibility_outlined,
                    color: Colors.blueGrey,
                    onTap: () async {
                      // Thêm await ở đây để đợi kết quả từ trang Detail trả về
                      final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PetDetailPage(petId: pet['petId']))
                      );

                      // Nếu xóa thành công ở trang Detail, nó sẽ trả về true
                      if (result == true) {
                        _loadPets(); // Gọi hàm tải lại danh sách
                      }
                    }
                ),
                const SizedBox(width: 12),
                _buildSmallActionBtn(
                    icon: Icons.edit_outlined,
                    color: Colors.green,
                    onTap: () async {
                      final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => PetUpdatePage(pet: pet)));
                      if (result == true) _loadPets();
                    }
                ),
                const SizedBox(width: 12),
                _buildSmallActionBtn(
                    icon: Icons.delete_outline,
                    color: Colors.redAccent,
                    onTap: () => _confirmDelete(pet['petId'])
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderBadge(String gender) {
    Color color = gender == 'Cái' ? Colors.pinkAccent : Colors.blueAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        gender,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSmallActionBtn({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FontAwesomeIcons.paw, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("Chưa có thú cưng nào", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Xác nhận xóa?"),
        content: const Text("Hồ sơ thú cưng sẽ bị xóa vĩnh viễn và không thể hoàn tác."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          TextButton(
              onPressed: () async {
                Navigator.pop(context);
                bool success = await ApiService.deletePet(id);
                if (success) _loadPets();
              },
              child: const Text("Xóa", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}