import 'package:flutter/material.dart';

const kPrimaryPink = Color(0xFFFF6185);
const kLightPink = Color(0xFFFFB6C1);
const kBackgroundPink = Color(0xFFFFF0F5);

/// =======================
/// MODELS
/// =======================
class Pet {
  final String name;
  final String type;
  final String breed;
  final int age;
  final double weight;

  Pet(this.name, this.type, this.breed, this.age, this.weight);
}

class HomestayService {
  final String name;

  HomestayService(this.name);
}

/// =======================
/// PAGE
/// =======================
class HomestayBookingPage extends StatefulWidget {
  const HomestayBookingPage({super.key});

  @override
  State<HomestayBookingPage> createState() => _HomestayBookingPageState();
}

class _HomestayBookingPageState extends State<HomestayBookingPage> {
  final phoneCtrl = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  /// ===== DATA CỨNG =====
  final pets = [
    Pet("Milu", "Chó", "Poodle", 3, 4.5),
    Pet("Mimi", "Mèo", "Anh lông ngắn", 2, 6.0),
    Pet("Lucky", "Chó", "Husky", 4, 28),
  ];

  final services = [
    HomestayService("Standard Room"),
    HomestayService("Deluxe Room"),
    HomestayService("Superior Room"),
  ];

  late Pet selectedPet;
  late HomestayService selectedService;

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
          "Đặt lịch Homestay 🏠",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
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

          const SizedBox(height: 20),

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

          const SizedBox(height: 20),

          _section("🛏️ Loại phòng Homestay"),
          DropdownButtonFormField<HomestayService>(
            value: selectedService,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: services
                .map(
                  (s) => DropdownMenuItem(
                value: s,
                child: Text(s.name),
              ),
            )
                .toList(),
            onChanged: (val) => setState(() => selectedService = val!),
          ),

          const SizedBox(height: 20),

          _section("📅 Thời gian lưu trú"),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    startDate == null
                        ? "Ngày bắt đầu"
                        : _formatDate(startDate!),
                  ),
                  onPressed: () => _pickStartDate(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.event),
                  label: Text(
                    endDate == null
                        ? "Ngày kết thúc"
                        : _formatDate(endDate!),
                  ),
                  onPressed: () => _pickEndDate(context),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kPrimaryPink,
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _readonly(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      "${d.day}/${d.month}/${d.year}";

  Future<void> _pickStartDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      initialDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        startDate = date;
        if (endDate != null && endDate!.isBefore(date)) {
          endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate(BuildContext context) async {
    if (startDate == null) return;

    final date = await showDatePicker(
      context: context,
      firstDate: startDate!,
      lastDate: startDate!.add(const Duration(days: 180)),
      initialDate: startDate!,
    );
    if (date != null) setState(() => endDate = date);
  }

  void _submit() {
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn đủ ngày lưu trú")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đặt lịch Homestay thành công (demo)")),
    );
  }
}
