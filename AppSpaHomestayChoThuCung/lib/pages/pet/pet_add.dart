import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart'; // Đảm bảo đường dẫn đúng
import 'dart:typed_data'; // Để dùng Uint8List
import 'package:flutter/foundation.dart' show kIsWeb; // Để dùng kIsWeb

class AddPetPage extends StatefulWidget {
  const AddPetPage({super.key});

  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers cho các ô nhập liệu
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _marksController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _vaccineController = TextEditingController();
  final TextEditingController _medicalController = TextEditingController();
  final TextEditingController _allergyController = TextEditingController();
  final TextEditingController _dietController = TextEditingController();
  final TextEditingController _healthNoteController = TextEditingController();
  final TextEditingController _aiResultController = TextEditingController();

  String _selectedType = 'Chó';
  String _selectedGender = 'Male';
  File? _imageFile;
  bool _isAnalyzing = false;
  Uint8List? _webImageBytes;

  // 1. Logic chọn ngày sinh và tính tuổi
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFFF6185)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
        _calculateAge(picked);
      });
    }
  }

  void _calculateAge(DateTime dob) {
    DateTime today = DateTime.now();
    int years = today.year - dob.year;
    int months = today.month - dob.month;
    if (today.day < dob.day) months--;
    if (months < 0) {
      years--;
      months += 12;
    }
    if (months >= 6) years++;
    _ageController.text = years > 0 ? years.toString() : "<1";
  }

  // 2. Logic chọn ảnh
// Cập nhật lại hàm chọn ảnh
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _webImageBytes = bytes;
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // 3. Logic gọi AI Phân tích (Giả lập gọi đến API AI của bạn)
  Future<void> _analyzeWithAI() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Vui lòng chọn ảnh trước!")));
      return;
    }

    setState(() => _isAnalyzing = true);

    // Gọi hàm analyze từ ApiService bạn đã viết
    // Ở đây tôi mô phỏng kết quả trả về
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _aiResultController.text = "Giống: Poodle, Màu: Trắng, Loại: Chó...";
      _breedController.text = "Poodle";
      _colorController.text = "Trắng";
      _selectedType = "Chó";
      _isAnalyzing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F9),
      appBar: AppBar(
        title: const Text("🐶 Thêm hồ sơ thú cưng", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFF6185),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("📋", "Thông tin cơ bản"),
                _buildTextField("Tên thú cưng", _nameController, isRequired: true),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _buildDropdown("Loại", ['Chó', 'Mèo'], _selectedType, (v) => setState(() => _selectedType = v!))),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField("Giống", _breedController)),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          child: _buildTextField("Ngày sinh", _dobController, icon: Icons.calendar_today),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField("Tuổi", _ageController, readOnly: true)),
                  ],
                ),
                const SizedBox(height: 15),
                _buildDropdown("Giới tính", ['Male', 'Female'], _selectedGender, (v) => setState(() => _selectedGender = v!)),
                _buildTextField("Màu sắc", _colorController),
                _buildTextField("Dấu hiệu nhận dạng", _marksController),

                _buildSectionTitle("⚖️", "Thông tin thể chất"),
                Row(
                  children: [
                    Expanded(child: _buildTextField("Cân nặng (kg)", _weightController, keyboardType: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField("Chiều cao (cm)", _heightController, keyboardType: TextInputType.number)),
                  ],
                ),

                _buildSectionTitle("🩺", "Thông tin sức khỏe"),
                _buildTextField("Hồ sơ tiêm phòng", _vaccineController, maxLines: 2),
                _buildTextField("Tiền sử bệnh", _medicalController, maxLines: 2),
                _buildTextField("Dị ứng", _allergyController, maxLines: 2),
                _buildTextField("Chế độ ăn", _dietController, maxLines: 2),
                _buildTextField("Ghi chú sức khỏe", _healthNoteController, maxLines: 2),

                _buildSectionTitle("📸", "Hình ảnh"),
                _buildImagePicker(),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _analyzeWithAI,
                    icon: _isAnalyzing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.psychology),
                    label: const Text("🔍 Phân tích ảnh bằng AI"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  ),
                ),
                _buildTextField("Kết quả phân tích AI", _aiResultController, maxLines: 3, readOnly: true),

                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("← Quay lại", style: TextStyle(color: Colors.grey))),
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6185),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      ),
                      child: const Text("💾 Lưu hồ sơ", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildSectionTitle(String icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isRequired = false, bool readOnly = false, IconData? icon, TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              suffixIcon: icon != null ? Icon(icon, size: 20) : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
            validator: (v) => isRequired && (v == null || v.isEmpty) ? "Không được để trống" : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: _imageFile != null || _webImageBytes != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: kIsWeb
              ? Image.memory(_webImageBytes!, fit: BoxFit.cover) // Cách hiển thị tốt nhất trên Web
              : Image.file(_imageFile!, fit: BoxFit.cover),  // Dùng cho Mobile
        )
            : const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload, size: 40, color: Colors.grey),
            Text("Nhấn để chọn ảnh"),
          ],
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {

      // 1. Hiện Loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFFF6185))),
      );

      Map<String, String> data = {
        "Name": _nameController.text.trim(),
        "Type": _selectedType,
        "Breed": _breedController.text.trim(),
        "DateOfBirth": _dobController.text,
        "Gender": _selectedGender,
        "Color": _colorController.text.trim(),
        "DistinguishingMarks": _marksController.text.trim(),
        "VaccinationRecords": _vaccineController.text.trim(),
        "MedicalHistory": _medicalController.text.trim(),
        "Allergies": _allergyController.text.trim(),
        "DietPreferences": _dietController.text.trim(),
        "HealthNotes": _healthNoteController.text.trim(),
        "AI_AnalysisResult": _aiResultController.text.trim(),
        "Age": (_ageController.text.isEmpty || _ageController.text == "<1") ? "0" : _ageController.text,
        "Weight": _weightController.text.isEmpty ? "0.0" : _weightController.text.replaceAll(',', '.'),
        "Height": _heightController.text.isEmpty ? "0.0" : _heightController.text.replaceAll(',', '.'),
        "UserId": "placeholder",
      };

      try {
        // 2. Gọi API
        bool success = await ApiService.addPet(data, _imageFile, webImageBytes: _webImageBytes);

        // 3. Luôn đóng Loading trước
        if (mounted) Navigator.of(context, rootNavigator: true).pop();

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("✅ Lưu thành công!"), backgroundColor: Colors.green),
            );
            // QUAY LẠI TRANG DANH SÁCH
            Navigator.pop(context, true);
          }
        } else {
          // TRƯỜNG HỢP CỦA BẠN: Lưu được nhưng API báo false
          // Ta vẫn sẽ ép nó quay lại trang danh sách sau khi báo lỗi
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("⚠️ Lưu xong nhưng có cảnh báo từ Server"), backgroundColor: Colors.orange),
            );
            // Vẫn quay lại để người dùng thấy dữ liệu mới đã lưu
            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        print("Lỗi submit: $e");
      }
    }
  }
}