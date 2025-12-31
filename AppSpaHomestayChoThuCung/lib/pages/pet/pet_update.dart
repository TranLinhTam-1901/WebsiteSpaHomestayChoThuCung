import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PetUpdatePage extends StatefulWidget {
  final Map<String, dynamic> pet; // Nhận dữ liệu pet hiện tại từ trang trước

  const PetUpdatePage({Key? key, required this.pet}) : super(key: key);

  @override
  _PetUpdatePageState createState() => _PetUpdatePageState();
}

class _PetUpdatePageState extends State<PetUpdatePage> {
  final _formKey = GlobalKey<FormState>();

  // --- Controllers ---
  late TextEditingController _nameController;
  late TextEditingController _breedController;
  late TextEditingController _colorController;
  late TextEditingController _marksController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _ageController;

  // Các trường sức khỏe giống trên Web
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
    // Khởi tạo dữ liệu ban đầu từ widget.pet
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
      _calculateAge(_selectedDate!);
    }
  }

  // Logic tính tuổi tự động
  void _calculateAge(DateTime dob) {
    DateTime today = DateTime.now();
    int years = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      years--;
    }
    setState(() {
      _ageController.text = years > 0 ? years.toString() : (years == 0 ? "0" : "0");
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        // Nếu là Web, đọc dưới dạng bytes
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
        });
      } else {
        // Nếu là Mobile, dùng File như cũ
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFFF6185))),
      );

      // ĐỒNG BỘ TÊN TRƯỜNG CHÍNH XÁC VỚI BACKEND C#
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

        // CÁC TRƯỜNG BẠN ĐANG LỖI - PHẢI VIẾT HOA CHỮ ĐẦU (PASCAL CASE)
        "Color": _colorController.text.trim(),
        "DistinguishingMarks": _marksController.text.trim(),
        "VaccinationRecords": _vaccinationController.text.trim(),
        "MedicalHistory": _medicalHistoryController.text.trim(),
        "Allergies": _allergiesController.text.trim(),
        "DietPreferences": _dietController.text.trim(),
        "HealthNotes": _healthNotesController.text.trim(),

        // ĐỊNH DẠNG NGÀY SINH: Chỉ lấy phần ngày YYYY-MM-DD nếu Backend không nhận ISO8601 đầy đủ
        "DateOfBirth": _selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
            : "",
      };

      // Gọi API với đủ tham số cho cả Web và Mobile
      bool success = await ApiService.updatePet(
          int.parse(data["PetId"]!),
          data,
          _imageFile,
          webImageBytes: _webImageBytes
      );

      if (!mounted) return;
      Navigator.pop(context); // Đóng loading

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("✏️ Cập nhật thông tin thú cưng", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFFFB6C1),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SECTION 1: THÔNG TIN CƠ BẢN
                  _buildHeader("📋 Thông tin cơ bản"),

                  _buildTextField(_nameController, "Tên thú cưng", isRequired: true),
                  const SizedBox(height: 10), // Thêm khoảng cách sau ô Tên

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start, // Căn lề trên để không bị lệch khi báo lỗi
                    children: [
                      Expanded(child: _buildDropdownType()),
                      const SizedBox(width: 15), // Khoảng cách giữa Loại và Giới tính
                      Expanded(child: _buildDropdownGender()),
                    ],
                  ),
                  const SizedBox(height: 16), // KHOẢNG CÁCH QUAN TRỌNG: Ngăn cách hàng trên với khung Giống

                  _buildTextField(_breedController, "Giống"),
                  const SizedBox(height: 10),

                  _buildDatePicker(),
                  const SizedBox(height: 10),
                  _buildTextField(_ageController, "Tuổi", readOnly: true),
                  _buildTextField(_colorController, "Màu sắc"),
                  _buildTextField(_marksController, "Dấu hiệu nhận dạng"),

                  _buildHeader("⚖️ Thông tin thể chất"),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_weightController, "Cân nặng (kg)", isNumber: true)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildTextField(_heightController, "Chiều cao (cm)", isNumber: true)),
                    ],
                  ),

                  _buildHeader("🩺 Thông tin sức khỏe"),
                  _buildTextArea(_vaccinationController, "Hồ sơ tiêm phòng"),
                  _buildTextArea(_medicalHistoryController, "Tiền sử bệnh"),
                  _buildTextArea(_allergiesController, "Dị ứng"),
                  _buildTextArea(_dietController, "Chế độ ăn"),
                  _buildTextArea(_healthNotesController, "Ghi chú sức khỏe"),

                  _buildHeader("🤖 Phân tích AI"),
                  _buildTextArea(_aiResultController, "Kết quả phân tích AI", readOnly: true),

                  _buildHeader("📷 Hình ảnh"),
                  _buildImagePickerSection(),

                  const SizedBox(height: 30),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- UI Helper Widgets ---

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isRequired = false, bool readOnly = false, bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: readOnly,
          fillColor: readOnly ? Colors.grey[100] : null,
        ),
        validator: isRequired ? (v) => (v == null || v.isEmpty) ? "Vui lòng nhập $label" : null : null,
      ),
    );
  }

  Widget _buildTextArea(TextEditingController controller, String label, {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: 3,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: readOnly,
          fillColor: readOnly ? Colors.grey[50] : null,
        ),
      ),
    );
  }

  Widget _buildDropdownType() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      items: ["Chó", "Mèo"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) => setState(() => _selectedType = v!),
      decoration: InputDecoration(labelText: "Loại", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  Widget _buildDropdownGender() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      items: const [
        DropdownMenuItem(value: "Male", child: Text("Đực")),
        DropdownMenuItem(value: "Female", child: Text("Cái")),
      ],
      onChanged: (v) => setState(() => _selectedGender = v!),
      decoration: InputDecoration(labelText: "Giới tính", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  Widget _buildDatePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 5),
      child: ListTile(
        shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
        title: Text(_selectedDate == null ? "Chọn ngày sinh" : "Ngày sinh: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}"),
        trailing: const Icon(Icons.calendar_today, color: Colors.pinkAccent),
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
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return Center(
      child: Column(
        children: [
          // Ưu tiên hiển thị ảnh mới vừa chọn
          if (kIsWeb && _webImageBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.memory(_webImageBytes!, height: 150, width: 200, fit: BoxFit.cover),
            )
          else if (!kIsWeb && _imageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.file(_imageFile!, height: 150, width: 200, fit: BoxFit.cover),
            )
          // Nếu chưa chọn ảnh mới, hiển thị ảnh cũ từ server
          else if (widget.pet['imageUrl'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  "https://10.0.2.2:7051${widget.pet['imageUrl']}",
                  height: 150,
                  width: 200,
                  fit: BoxFit.cover,
                  // Xử lý lỗi nếu URL ảnh không tồn tại
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, size: 80, color: Colors.grey),
                ),
              )
            else
              const Icon(Icons.pets, size: 80, color: Colors.grey),

          TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image),
            label: const Text("Thay đổi ảnh"),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 25)),
          child: const Text("Hủy"),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6185), shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12)),
          child: const Text("💾 Cập nhật", style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
      ],
    );
  }
}