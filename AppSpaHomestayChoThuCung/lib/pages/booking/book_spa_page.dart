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

class SpaService {
  final String name;
  final int under5;
  final int from5to12;
  final int from12to25;
  final int over25;

  SpaService({
    required this.name,
    required this.under5,
    required this.from5to12,
    required this.from12to25,
    required this.over25,
  });

  int priceByWeight(double weight) {
    if (weight < 5) return under5;
    if (weight < 12) return from5to12;
    if (weight < 25) return from12to25;
    return over25;
  }
}

class SpaBookingPage extends StatefulWidget {
  const SpaBookingPage({super.key});

  @override
  State<SpaBookingPage> createState() => _SpaBookingPageState();
}

class _SpaBookingPageState extends State<SpaBookingPage> {
  final phoneCtrl = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  /// ===== DATA CỨNG =====
  final pets = [
    Pet("Milu", "Chó", "Poodle", 3, 4.5),
    Pet("Mimi", "Mèo", "Anh lông ngắn", 2, 6.2),
    Pet("Lucky", "Chó", "Husky", 4, 28),
  ];

  final services = [
    SpaService(
      name: "Spa (Tắm sấy vệ sinh)",
      under5: 330000,
      from5to12: 440000,
      from12to25: 610000,
      over25: 850000,
    ),
    SpaService(
      name: "Grooming (Spa + Cắt tỉa)",
      under5: 500000,
      from5to12: 690000,
      from12to25: 930000,
      over25: 1300000,
    ),
    SpaService(
      name: "Shave (Spa + Cạo lông)",
      under5: 420000,
      from5to12: 570000,
      from12to25: 770000,
      over25: 1000000,
    ),
  ];

  late Pet selectedPet;
  late SpaService selectedService;

  @override
  void initState() {
    super.initState();
    selectedPet = pets.first;
    selectedService = services.first;
  }

  int get calculatedPrice =>
      selectedService.priceByWeight(selectedPet.weight);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundPink,
      appBar: AppBar(
        backgroundColor: kLightPink,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Đặt lịch Spa 🧼",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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

          _pinkCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section("🧴 Dịch vụ Spa"),
                DropdownButtonFormField<SpaService>(
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
                  "${calculatedPrice.toStringAsFixed(0)} VNĐ",
                  isPrice: true,
                ),
              ],
            ),
          ),

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
      lastDate: DateTime.now().add(const Duration(days: 60)),
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
      const SnackBar(content: Text("Đặt lịch Spa thành công (demo)")),
    );
  }
}