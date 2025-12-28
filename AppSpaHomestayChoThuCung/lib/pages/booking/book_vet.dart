import 'package:flutter/material.dart';

const kPrimaryPink = Color(0xFFFF6185);
const kLightPink = Color(0xFFFFB6C1);
const kBackgroundPink = Color(0xFFFFF0F5);

/// =====================
/// MODEL
/// =====================
class Pet {
  final String name;
  final String type;
  final String breed;
  final int age;
  final double weight;

  Pet(this.name, this.type, this.breed, this.age, this.weight);
}

class VetService {
  final String name;
  final int price;

  VetService(this.name, this.price);
}

class VetBookingPage extends StatefulWidget {
  const VetBookingPage({super.key});

  @override
  State<VetBookingPage> createState() => _VetBookingPageState();
}

class _VetBookingPageState extends State<VetBookingPage> {
  final phoneCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  /// ===== DATA CỨNG =====
  final pets = [
    Pet("Milu", "Chó", "Poodle", 3, 5.2),
    Pet("Mimi", "Mèo", "Anh lông ngắn", 2, 3.8),
  ];

  final services = [
    VetService("Khám tổng quát", 150000),
    VetService("Tiêm phòng", 200000),
    VetService("Xét nghiệm máu", 350000),
  ];

  late Pet selectedPet;
  late VetService selectedService;

  @override
  void initState() {
    super.initState();
    selectedPet = pets.first;
    selectedService = services.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundPink,
      appBar: AppBar(
        backgroundColor: kLightPink,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "🩺 Đặt lịch Thú y",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// 👤 Chủ nuôi
          _pinkCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section("👤 Thông tin chủ nuôi"),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Số điện thoại",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),

          /// 🐾 Thú cưng
          _pinkCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section("🐾 Chọn thú cưng"),
                DropdownButtonFormField<Pet>(
                  value: selectedPet,
                  decoration: const InputDecoration(
                    labelText: "Thú cưng",
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: OutlineInputBorder(),
                  ),
                  items: pets
                      .map(
                        (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.name),
                    ),
                  )
                      .toList(),
                  onChanged: (val) => setState(() => selectedPet = val!),
                ),

                const SizedBox(height: 12),
                _readonly("Loại", selectedPet.type),
                _readonly("Giống", selectedPet.breed),
                _readonly("Tuổi", "${selectedPet.age}"),
                _readonly("Cân nặng", "${selectedPet.weight} kg"),
              ],
            ),
          ),

          /// 💉 Dịch vụ
          _pinkCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section("💉 Dịch vụ thú y"),
                DropdownButtonFormField<VetService>(
                  value: selectedService,
                  items: services
                      .map(
                        (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.name),
                    ),
                  )
                      .toList(),
                  onChanged: (val) =>
                      setState(() => selectedService = val!),
                  decoration:
                  const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                _readonly(
                  "Giá dịch vụ",
                  "${selectedService.price.toStringAsFixed(0)} VNĐ",
                  isPrice: true,
                ),
              ],
            ),
          ),

          /// 📝 Ghi chú
          _pinkCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section("📝 Ghi chú"),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "Nhập triệu chứng hoặc yêu cầu...",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),

          /// 📅 Thời gian
          _pinkCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section("📅 Thời gian"),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          selectedDate == null
                              ? "Chọn ngày"
                              : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                        ),
                        onPressed: _pickDate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: Text(
                          selectedTime == null
                              ? "Chọn giờ"
                              : selectedTime!.format(context),
                        ),
                        onPressed: _pickTime,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// 📅 Submit
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: kLightPink,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: _submit,
            icon: const Icon(Icons.event_available),
            label: const Text(
              "Đặt lịch ngay",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

        ],
      ),
    );
  }

  /// ================= HELPERS =================
  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: kPrimaryPink,
        ),
      ),
    );
  }

  Widget _pinkCard(Widget child) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _readonly(String label, String value, {bool isPrice = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        style: TextStyle(
          color: isPrice ? Colors.red : Colors.black,
          fontWeight: isPrice ? FontWeight.bold : FontWeight.normal,
        ),
        decoration: InputDecoration(
          labelText: label, // ⭐ CHỮ NHỎ PHÍA TRÊN
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDate: DateTime.now(),
    );
    if (date != null) setState(() => selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) setState(() => selectedTime = time);
  }

  void _submit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đặt lịch thú y thành công (demo)")),
    );
  }
}