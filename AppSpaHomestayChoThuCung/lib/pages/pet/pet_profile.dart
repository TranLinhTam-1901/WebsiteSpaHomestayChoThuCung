import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../model/pet/pet.dart';
import '../../services/api_service.dart'; // Import service đã tách
import 'pet_detail.dart';
import 'pet_add.dart';
import 'pet_update.dart';

class PetProfilePage extends StatefulWidget {
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
    // Không cần setState ở đây nếu bạn chỉ muốn khởi tạo lại Future
    _petFuture = ApiService.getPets();
    setState(() {}); // Chỉ để báo Flutter vẽ lại giao diện với Future mới
  }

  // Hàm xử lý giới tính giống logic C# của bạn
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
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F9), // Tương ứng màu nền nhẹ trong CSS
      appBar: AppBar(
        title: const Text("🐶 Hồ sơ thú cưng của tôi",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFF6185), // Màu hồng chủ đạo
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
            tooltip: "Thêm thú cưng mới",
            onPressed: () async {
              // Đợi kết quả trả về từ trang AddPetPage
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddPetPage()),
              );

              // Nếu result là true (do ta đã pop(true)), thì mới load lại danh sách
              if (result == true) {
                _loadPets();
              }
            },
          ),
          const SizedBox(width: 10), // Khoảng cách nhỏ ở góc phải
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "🐾 Danh sách thú cưng",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6185),
              ),
            ),
            const SizedBox(height: 4),
            Container(width: 80, height: 4, color: const Color(0xFFFFB6C1)),
            const SizedBox(height: 20),

            // Card bọc lấy bảng dữ liệu
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFB6C1), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB6C1).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: FutureBuilder<List<dynamic>>(
                future: _petFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(50.0),
                      child: Center(child: CircularProgressIndicator(color: Color(0xFFFF6185))),
                    );
                  } else if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(child: Text("Chưa có thú cưng nào được thêm 🐶🐱")),
                    );
                  }

                  final pets = snapshot.data!;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(const Color(0xFFFFE4E9)),
                      columnSpacing: 20,
                      columns: const [
                        DataColumn(label: Text('Tên', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Loại', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Giống', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Cân nặng', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Giới tính', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: pets.map((pet) {
                        return DataRow(cells: [
                          DataCell(Text(pet['name'] ?? "")),
                          DataCell(Text(pet['type'] ?? "")),
                          DataCell(Text(pet['breed'] ?? "")),
                          DataCell(Text("${pet['weight']} kg")),
                          DataCell(Text(_getGenderText(pet['gender']))),
                          DataCell(Row(
                            children: [
                              // Nút Chi tiết (Màu hồng nhạt)
                              _buildActionButton(
                                icon: FontAwesomeIcons.infoCircle,
                                color: const Color(0xFFFFB6C1),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PetDetailPage(petId: pet['petId']),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 5),
                              // Nút Sửa (Màu xanh)
                              _buildActionButton(
                                icon: FontAwesomeIcons.edit,
                                color: Colors.green,
                                isOutline: true,
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => PetUpdatePage(pet: pet)),
                                  );

                                  // Khi quay lại từ trang Update với giá trị true
                                  if (result == true) {
                                    _loadPets();
                                  }
                                },
                              ),
                              const SizedBox(width: 5),
                              // Nút Xóa (Màu đỏ)
                              _buildActionButton(
                                icon: FontAwesomeIcons.trashAlt,
                                color: Colors.red,
                                isOutline: true,
                                onTap: () => _confirmDelete(pet['petId']),
                              ),
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget helper tạo nút bấm giống CSS của bạn
  Widget _buildActionButton({required IconData icon, required Color color, bool isOutline = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isOutline ? Colors.transparent : color,
          border: isOutline ? Border.all(color: color, width: 2) : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, size: 14, color: isOutline ? color : Colors.black),
      ),
    );
  }

  // Hàm xác nhận xóa
  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa?"),
        content: const Text("Bạn có chắc chắn muốn xóa thú cưng này không?"),
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