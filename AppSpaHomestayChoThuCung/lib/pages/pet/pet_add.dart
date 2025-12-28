import 'package:flutter/material.dart';

const kPrimaryPink = Color(0xFFFF7AA2);

class PetAddPage extends StatefulWidget {
  const PetAddPage({super.key});

  @override
  State<PetAddPage> createState() => _PetAddPageState();
}

class _PetAddPageState extends State<PetAddPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final nameCtrl = TextEditingController();
  final breedCtrl = TextEditingController();
  final colorCtrl = TextEditingController();
  final markCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final heightCtrl = TextEditingController();
  final vaccineCtrl = TextEditingController();
  final medicalCtrl = TextEditingController();
  final allergyCtrl = TextEditingController();
  final dietCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  final aiCtrl = TextEditingController();

  String petType = "Chó";
  String gender = "Male";
  DateTime? birthDate;
  int? age;

  // ======================
  // 📅 Date Picker
  // ======================
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2020),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        birthDate = picked;
        age = DateTime.now().year - picked.year;
      });
    }
  }

  // ======================
  // 🤖 Fake AI
  // ======================
  void _analyzeAI() {
    setState(() {
      aiCtrl.text = "🐶 Chó lông ngắn, khỏe mạnh, không phát hiện bất thường.";
    });
  }

  // ======================
  // 💾 Submit
  // ======================
  void _submit() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Đã lưu hồ sơ thú cưng")),
      );
    }
  }

  // ======================
  // UI
  // ======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🐶 Thêm hồ sơ thú cưng"),
        backgroundColor: kPrimaryPink,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section("📋 Thông tin cơ bản"),

                  _input("Tên thú cưng", nameCtrl, required: true),

                  _dropdown(
                    "Loại",
                    petType,
                    ["Chó", "Mèo"],
                        (v) => setState(() => petType = v),
                  ),

                  _input("Giống", breedCtrl),

                  GestureDetector(
                    onTap: _pickDate,
                    child: AbsorbPointer(
                      child: _input(
                        "Ngày sinh",
                        TextEditingController(
                          text: birthDate == null
                              ? ""
                              : "${birthDate!.day}/${birthDate!.month}/${birthDate!.year}",
                        ),
                      ),
                    ),
                  ),

                  _row(
                    _dropdown(
                      "Giới tính",
                      gender,
                      ["Male", "Female"],
                          (v) => setState(() => gender = v),
                    ),
                    _input(
                      "Tuổi",
                      TextEditingController(text: age?.toString() ?? ""),
                      enabled: false,
                    ),
                  ),

                  _input("Màu sắc", colorCtrl),
                  _input("Dấu hiệu nhận dạng", markCtrl),

                  _section("⚖️ Thông tin thể chất"),
                  _row(
                    _input("Cân nặng (kg)", weightCtrl),
                    _input("Chiều cao (cm)", heightCtrl),
                  ),

                  _section("🩺 Thông tin sức khỏe"),
                  _textarea("Tiêm phòng", vaccineCtrl),
                  _textarea("Tiền sử bệnh", medicalCtrl),
                  _textarea("Dị ứng", allergyCtrl),
                  _textarea("Chế độ ăn", dietCtrl),
                  _textarea("Ghi chú sức khỏe", noteCtrl),

                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: _analyzeAI,
                    icon: const Icon(Icons.psychology),
                    label: const Text("Phân tích ảnh bằng AI"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  _textarea("Kết quả AI", aiCtrl, readOnly: true),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("← Quay lại"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryPink,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text("💾 Lưu hồ sơ"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ======================
  // Components
  // ======================
  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(title,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _input(
      String label,
      TextEditingController ctrl, {
        bool required = false,
        bool enabled = true,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        enabled: enabled,
        validator: required
            ? (v) => v == null || v.isEmpty ? "Không được để trống" : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _textarea(
      String label,
      TextEditingController ctrl, {
        bool readOnly = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: 3,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _dropdown(
      String label,
      String value,
      List<String> items,
      Function(String) onChanged,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => onChanged(v!),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _row(Widget a, Widget b) {
    return Row(
      children: [
        Expanded(child: a),
        const SizedBox(width: 12),
        Expanded(child: b),
      ],
    );
  }
}
