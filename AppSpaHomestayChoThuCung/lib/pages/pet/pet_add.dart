import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

// Hằng số màu sắc đồng bộ
const kLightPink = Color(0xFFFFB6C1);
const kPrimaryPink = Color(0xFFFF6185);
const kBackgroundLight = Color(0xFFF9F9F9);

class AddPetPage extends StatefulWidget {
  const AddPetPage({super.key});

  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _dobController = TextEditingController();
  final _ageController = TextEditingController();
  final _colorController = TextEditingController();
  final _marksController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _vaccineController = TextEditingController();
  final _medicalController = TextEditingController();
  final _allergyController = TextEditingController();
  final _dietController = TextEditingController();
  final _healthNoteController = TextEditingController();
  final _aiResultController = TextEditingController();

  String _selectedType = 'Chó';
  String _selectedGender = 'Male';
  File? _imageFile;
  Uint8List? _webImageBytes;
  bool _isAnalyzing = false;

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
      backgroundColor: kBackgroundLight,
      appBar: AppBar(
        title: const Text(
          "Tạo hồ sơ thú cưng",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 19,
            color: Colors.black, // Chuyển sang màu trắng để nổi bật trên nền hồng
          ),
        ),
        centerTitle: true,
        backgroundColor: kLightPink,
        elevation: 0,
        // Thêm bo góc dưới để đồng bộ với trang Chi tiết/Lịch sử
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        // Đổi màu icon quay lại thành trắng
        iconTheme: const IconThemeData(color: Colors.black),
        // Đảm bảo status bar (pin, sóng) có màu trắng cho dễ nhìn
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- 1. CHỌN ẢNH (AVATAR STYLE) ---
              _buildImageHeader(),
              const SizedBox(height: 20),

              // --- 2. THÔNG TIN CƠ BẢN ---
              _buildFormSection(
                title: "Thông tin cơ bản",
                icon: Icons.pets,
                children: [
                  // 1. Tên thú cưng chiếm trọn 1 hàng
                  _buildModernField("Tên thú cưng *", _nameController, isRequired: true),

                  // 2. Hàng chứa LOẠI và GIỚI TÍNH
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LOẠI (Bên trái)
                      Expanded(
                        child: _buildModernDropdown(
                            "Loại",
                            ['Chó', 'Mèo'],
                            _selectedType,
                                (v) => setState(() => _selectedType = v!)
                        ),
                      ),

                      const SizedBox(width: 12),

                      // GIỚI TÍNH (Bên phải)
                      Expanded(
                        child: _buildModernDropdown(
                          "Giới tính",
                          ['Đực', 'Cái'],
                          _selectedGender == 'Male' ? 'Đực' : 'Cái',
                              (v) {
                            setState(() {
                              _selectedGender = (v == 'Đực') ? 'Male' : 'Female';
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  // 3. Giống chiếm trọn 1 hàng (Hoặc bạn có thể gộp với Màu sắc nếu muốn)
                  _buildModernField("Giống", _breedController),

                  // 4. Hàng chứa NGÀY SINH và TUỔI
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectDate(context),
                          child: AbsorbPointer(
                            child: _buildModernField("Ngày sinh", _dobController, icon: Icons.calendar_today),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _buildModernField("Tuổi", _ageController, readOnly: true)),
                    ],
                  ),

                  // 5. Màu sắc chiếm trọn 1 hàng
                  _buildModernField("Màu sắc", _colorController),
                ],
              ),

              // --- 3. THÔNG TIN THỂ CHẤT ---
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

              // --- 4. SỨC KHỎE & DINH DƯỠNG ---
              _buildFormSection(
                title: "Sức khỏe & Dinh dưỡng",
                icon: Icons.health_and_safety_outlined,
                children: [
                  _buildModernField("Tiêm phòng", _vaccineController, maxLines: 2),
                  _buildModernField("Tiền sử bệnh", _medicalController, maxLines: 2),
                  _buildModernField("Dị ứng", _allergyController, maxLines: 2),
                  _buildModernField("Chế độ ăn", _dietController, maxLines: 2),
                  _buildModernField("Ghi chú sức khỏe", _healthNoteController, maxLines: 2),
                ],
              ),

              // --- 5. TRÍ TUỆ NHÂN TẠO AI ---
              _buildAISection(),

              const SizedBox(height: 24),

              // --- 6. NÚT LƯU ---
              _buildSubmitButtons(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  // Widget tiêu đề nhóm thông tin
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

  // Widget Input Field hiện đại
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
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kLightPink, width: 1)),
        ),
        validator: (v) => isRequired && (v == null || v.isEmpty) ? "Vui lòng nhập $label" : null,
      ),
    );
  }

  // Logic Widgets giữ nguyên (Dropdown, SelectDate...)
  Widget _buildModernDropdown(String label, List<String> items, String value, Function(String?) onChanged) {
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
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  // AI Section
  Widget _buildAISection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text("Phân tích thông minh AI", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              const Spacer(),
              _isAnalyzing
                  ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
                  : TextButton(onPressed: _analyzeWithAI, child: const Text("Bắt đầu")),
            ],
          ),
          _buildModernField("Kết quả phân tích", _aiResultController, readOnly: true, maxLines: 2),
        ],
      ),
    );
  }

  // Nút Submit
  Widget _buildSubmitButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.red.shade300), // Viền xám nhạt
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              foregroundColor: Colors.red.shade700, // Màu chữ xám đậm hơn chút
            ),
            child: const Text(
              "Hủy bỏ",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
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
            child: const Text("Lưu hồ sơ ngay", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // Header chọn ảnh
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
                  : const Icon(Icons.pets, size: 50, color: Colors.pinkAccent),
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