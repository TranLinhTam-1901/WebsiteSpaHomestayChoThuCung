import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import bắt buộc
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Hằng số màu sắc đồng bộ
const kLightPink = Color(0xFFFFB6C1);
const kPrimaryPink = Color(0xFFFF6185);
const kBackgroundLight = Color(0xFFF9F9F9);

class PetUpdatePage extends StatefulWidget {
  final Map<String, dynamic> pet;

  const PetUpdatePage({Key? key, required this.pet}) : super(key: key);

  @override
  _PetUpdatePageState createState() => _PetUpdatePageState();
}

class _PetUpdatePageState extends State<PetUpdatePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _breedController;
  late TextEditingController _colorController;
  late TextEditingController _marksController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _ageController;
  late TextEditingController _vaccinationController;
  late TextEditingController _medicalHistoryController;
  late TextEditingController _allergiesController;
  late TextEditingController _dietController;
  late TextEditingController _healthNotesController;
  late TextEditingController _aiResultController;

  String _selectedType = "Chó";
  String _selectedGender = "Male";
  DateTime? _selectedDate;
  File? _imageFile;
  Uint8List? _webImageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    _nameController = TextEditingController(text: widget.pet['name']);
    _breedController = TextEditingController(text: widget.pet['breed']);
    _colorController = TextEditingController(text: widget.pet['color']);
    _marksController = TextEditingController(text: widget.pet['distinguishingMarks']);
    _weightController = TextEditingController(text: widget.pet['weight']?.toString());
    _heightController = TextEditingController(text: widget.pet['height']?.toString());
    _ageController = TextEditingController(text: widget.pet['age']?.toString());
    _vaccinationController = TextEditingController(text: widget.pet['vaccinationRecords']);
    _medicalHistoryController = TextEditingController(text: widget.pet['medicalHistory']);
    _allergiesController = TextEditingController(text: widget.pet['allergies']);
    _dietController = TextEditingController(text: widget.pet['dietPreferences']);
    _healthNotesController = TextEditingController(text: widget.pet['healthNotes']);
    _aiResultController = TextEditingController(text: widget.pet['aI_AnalysisResult']);

    _selectedType = widget.pet['type'] ?? "Chó";
    _selectedGender = widget.pet['gender'] ?? "Male";

    if (widget.pet['dateOfBirth'] != null) {
      _selectedDate = DateTime.parse(widget.pet['dateOfBirth']);
    }
  }

  void _calculateAge(DateTime dob) {
    DateTime today = DateTime.now();
    int years = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      years--;
    }
    setState(() {
      _ageController.text = years > 0 ? years.toString() : "0";
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => _webImageBytes = bytes);
      } else {
        setState(() => _imageFile = File(pickedFile.path));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundLight,
      appBar: AppBar(
        title: const Text("Chỉnh sửa hồ sơ",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: Colors.black)),
        centerTitle: true,
        backgroundColor: kLightPink,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- 1. AVATAR CHỌN ẢNH (GIỐNG TRANG ADD) ---
              _buildImageHeader(),
              const SizedBox(height: 20),

              // --- 2. THÔNG TIN CƠ BẢN ---
              _buildFormSection(
                title: "Thông tin cơ bản",
                icon: Icons.pets,
                children: [
                  _buildModernField("Tên thú cưng *", _nameController, isRequired: true),
                  Row(
                    children: [
                      Expanded(child: _buildModernDropdown("Loại", ['Chó', 'Mèo'], _selectedType, (v) => setState(() => _selectedType = v!))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildModernDropdown("Giới tính", ['Male', 'Female'], _selectedGender, (v) => setState(() => _selectedGender = v!))),
                    ],
                  ),
                  _buildModernField("Giống", _breedController),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                              _calculateAge(picked);
                            }
                          },
                          child: AbsorbPointer(
                            child: _buildModernField(
                                "Ngày sinh",
                                TextEditingController(text: _selectedDate == null ? "" : DateFormat('dd/MM/yyyy').format(_selectedDate!)),
                                icon: Icons.calendar_today
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _buildModernField("Tuổi", _ageController, readOnly: true)),
                    ],
                  ),
                  _buildModernField("Màu sắc", _colorController),
                ],
              ),

              // --- 3. THỂ CHẤT ---
              _buildFormSection(
                title: "Thể chất & Nhận dạng",
                icon: Icons.monitor_weight_outlined,
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildModernField("Cân nặng (kg)", _weightController, keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildModernField("Chiều cao (cm)", _heightController, keyboardType: TextInputType.number)),
                    ],
                  ),
                  _buildModernField("Dấu hiệu nhận dạng", _marksController),
                ],
              ),

              // --- 4. SỨC KHỎE ---
              _buildFormSection(
                title: "Sức khỏe & Dinh dưỡng",
                icon: Icons.health_and_safety_outlined,
                children: [
                  _buildModernField("Tiêm phòng", _vaccinationController, maxLines: 2),
                  _buildModernField("Tiền sử bệnh", _medicalHistoryController, maxLines: 2),
                  _buildModernField("Dị ứng", _allergiesController, maxLines: 2),
                  _buildModernField("Chế độ ăn", _dietController, maxLines: 2),
                  _buildModernField("Ghi chú sức khỏe", _healthNotesController, maxLines: 2),
                ],
              ),

              // --- 5. AI RESULT (READ ONLY) ---
              _buildAISection(),

              const SizedBox(height: 24),

              // --- 6. ACTIONS ---
              _buildSubmitButtons(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- REUSABLE COMPONENTS (ĐỒNG BỘ VỚI TRANG ADD) ---

  Widget _buildFormSection({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: kPrimaryPink),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernField(String label, TextEditingController controller, {bool isRequired = false, bool readOnly = false, IconData? icon, TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          prefixIcon: icon != null ? Icon(icon, size: 18, color: Colors.pinkAccent) : null,
          filled: true,
          fillColor: kBackgroundLight,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kLightPink, width: 1)),
        ),
        validator: (v) => isRequired && (v == null || v.isEmpty) ? "Vui lòng nhập $label" : null,
      ),
    );
  }

  Widget _buildImageHeader() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.pinkAccent, width: 3),
              boxShadow: [BoxShadow(color: kLightPink.withOpacity(0.2), blurRadius: 10)],
            ),
            child: ClipOval(
              child: (_imageFile != null || _webImageBytes != null)
                  ? (kIsWeb ? Image.memory(_webImageBytes!, fit: BoxFit.cover) : Image.file(_imageFile!, fit: BoxFit.cover))
                  : (widget.pet['imageUrl'] != null
                  ? Image.network("https://10.0.2.2:7051${widget.pet['imageUrl']}", fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Icon(Icons.pets, size: 50, color: Colors.pinkAccent))
                  : const Icon(Icons.pets, size: 50, color: Colors.pinkAccent)),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: kPrimaryPink, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDropdown(String label, List<String> items, String value, Function(String?) onChanged) {
    String displayValue = value;
    if (label == "Giới tính") {
      displayValue = (value == "Male") ? "Đực" : (value == "Female" ? "Cái" : value);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: kBackgroundLight, borderRadius: BorderRadius.circular(12)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: items.contains(value) ? value : items.first,
            isExpanded: true,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            items: items.map((e) {
              String text = e;
              if (label == "Giới tính") text = (e == "Male") ? "Đực" : "Cái";
              return DropdownMenuItem(value: e, child: Text(text));
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildAISection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text("Kết quả AI trước đó", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          Text(_aiResultController.text.isEmpty ? "Chưa có dữ liệu" : _aiResultController.text,
              style: TextStyle(fontSize: 13, color: Colors.blue.shade900)),
        ],
      ),
    );
  }

  Widget _buildSubmitButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.red.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Hủy bỏ", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryPink,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Cập nhật ngay", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // Giữ nguyên logic _submitForm của bạn...
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: kPrimaryPink)),
      );

      Map<String, String> data = {
        "PetId": widget.pet['petId']?.toString() ?? "0",
        "UserId": widget.pet['userId']?.toString() ?? "",
        "Name": _nameController.text.trim(),
        "Type": _selectedType,
        "Breed": _breedController.text.trim(),
        "Gender": _selectedGender,
        "Age": _ageController.text.trim(),
        "Weight": _weightController.text.trim(),
        "Height": _heightController.text.trim(),
        "Color": _colorController.text.trim(),
        "DistinguishingMarks": _marksController.text.trim(),
        "VaccinationRecords": _vaccinationController.text.trim(),
        "MedicalHistory": _medicalHistoryController.text.trim(),
        "Allergies": _allergiesController.text.trim(),
        "DietPreferences": _dietController.text.trim(),
        "HealthNotes": _healthNotesController.text.trim(),
        "DateOfBirth": _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : "",
      };

      bool success = await ApiService.updatePet(
          int.parse(data["PetId"]!),
          data,
          _imageFile,
          webImageBytes: _webImageBytes
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🎉 Cập nhật thành công!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Cập nhật thất bại. Vui lòng thử lại!"), backgroundColor: Colors.red),
        );
      }
    }
  }
}