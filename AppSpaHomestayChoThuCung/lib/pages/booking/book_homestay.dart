import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../model/service/service.dart';
import '../../../services/api_service.dart';

class HomestayBookingPage extends StatefulWidget {
  final Map<String, dynamic>? appointment;

  const HomestayBookingPage({super.key, this.appointment});

  @override
  State<HomestayBookingPage> createState() => _HomestayBookingPageState();
}

class _HomestayBookingPageState extends State<HomestayBookingPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));

  List<dynamic> _userPets = [];
  List<ServiceModel> _homestayServices = [];

  late TextEditingController _phoneController;
  late TextEditingController _petNameController;
  late TextEditingController _petTypeController;
  late TextEditingController _petBreedController;
  late TextEditingController _petAgeController;
  late TextEditingController _petWeightController;

  int? _selectedPetId;
  ServiceModel? _selectedService;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadData();
  }

  void _initControllers() {
    _phoneController = TextEditingController(text: widget.appointment?['ownerPhoneNumber'] ?? "");
    _petNameController = TextEditingController();
    _petTypeController = TextEditingController();
    _petBreedController = TextEditingController();
    _petAgeController = TextEditingController();
    _petWeightController = TextEditingController();

    if (widget.appointment != null) {
      // Ép kiểu DateTime từ chuỗi String của API
      _startDate = DateTime.parse(widget.appointment!['startDate'] ?? DateTime.now().toString());
      _endDate = DateTime.parse(widget.appointment!['endDate'] ?? DateTime.now().add(const Duration(days: 1)).toString());
    }
  }

  Future<void> _pickStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await ApiService.getUserProfile();
      if (profile != null && widget.appointment == null) {
        _phoneController.text = profile['phoneNumber']?.toString() ?? "";
      }

      final results = await Future.wait([
        ApiService.getPets(),
        ApiService.getHomestayBookingData(),
      ]);

      setState(() {
        // 1. Xử lý danh sách Pet
        _userPets = List.from(results[0] as Iterable);
        _userPets.sort((a, b) => (a['name'] ?? "").compareTo(b['name'] ?? ""));

        // 2. Xử lý danh sách Dịch vụ (Bóc tách từ key "services" như Postman)
        final rawData = results[1] as Map<String, dynamic>;
        _homestayServices = List<ServiceModel>.from(rawData['services'] ?? []);

        // 3. Khởi tạo giá trị Pet được chọn
        if (_userPets.isNotEmpty) {
          _selectedPetId = widget.appointment?['petId'] ?? _userPets.first['petId'];
          _updatePetFields(_selectedPetId);
        }

        // 4. Khởi tạo giá trị Dịch vụ được chọn
        if (_homestayServices.isNotEmpty) {
          int? targetId;
          if (widget.appointment != null) {
            targetId = widget.appointment!['serviceId'];
          } else {
            targetId = _homestayServices.first.serviceId;
          }

          // Tìm đúng thực thể từ danh sách để biến _selectedService không bị null
          _selectedService = _homestayServices.firstWhere(
                (s) => s.serviceId == targetId,
            orElse: () => _homestayServices.first,
          );
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("LỖI LOAD DATA HOMESTAY: $e");
    }
  }

  void _updatePetFields(int? petId) {
    if (_userPets.isEmpty || petId == null) return;
    final pet = _userPets.firstWhere((p) => p['petId'] == petId, orElse: () => null);
    if (pet != null) {
      setState(() {
        _petNameController.text = pet['name'] ?? "";
        _petTypeController.text = pet['type'] ?? "";
        _petBreedController.text = pet['breed'] ?? "";
        _petAgeController.text = pet['age']?.toString() ?? "";
        _petWeightController.text = pet['weight']?.toString() ?? "0";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.pinkAccent)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appointment == null ? "🏨 Đặt lịch Homestay" : "✏️ Cập nhật Homestay"),
        backgroundColor: Colors.pinkAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("👤", "Thông tin chủ nuôi"),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Số điện thoại", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),

              _buildSectionTitle("🐾", "Chọn thú cưng"),
              DropdownButtonFormField<int>(
                value: _selectedPetId,
                items: _userPets.map((pet) => DropdownMenuItem<int>(
                  value: pet['petId'],
                  child: Text(pet['name'] ?? "Không tên"),
                )).toList(),
                onChanged: (val) {
                  setState(() => _selectedPetId = val);
                  _updatePetFields(val);
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(child: _buildReadonlyField("Tên thú cưng", _petNameController)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildReadonlyField("Loại", _petTypeController)),
                ],
              ),
              const SizedBox(height: 10),
              _buildReadonlyField("Giống", _petBreedController),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildReadonlyField("Tuổi", _petAgeController)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _petWeightController,
                      readOnly: true,
                      decoration: InputDecoration(
                          labelText: "Cân nặng",
                          suffixText: "kg",
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: const OutlineInputBorder()
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildSectionTitle("🛏️", "Chọn loại phòng"),
              _homestayServices.isEmpty
                  ? const Text("Đang tải danh sách phòng...")
                  : DropdownButtonFormField<int>( // Sử dụng kiểu int
                value: _selectedService?.serviceId,
                isExpanded: true,
                hint: const Text("Chọn loại phòng"),
                items: _homestayServices.map((service) {
                  return DropdownMenuItem<int>(
                    value: service.serviceId, // Dùng ID làm value
                    child: Text(service.name),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    // Tìm lại đối tượng trong danh sách dựa trên ID vừa chọn
                    _selectedService = _homestayServices.firstWhere((s) => s.serviceId == val);
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle("📅", "Thời gian lưu trú"),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickStartDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: "Ngày bắt đầu", border: OutlineInputBorder()),
                        child: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: _pickEndDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: "Ngày kết thúc", border: OutlineInputBorder()),
                        child: Text(DateFormat('dd/MM/yyyy').format(_endDate)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade100,
                  foregroundColor: Colors.pink.shade700,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: Colors.pink.shade200)
                  ),
                ),
                onPressed: _handleBooking,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  widget.appointment == null ? "XÁC NHẬN ĐẶT PHÒNG" : "LƯU THAY ĐỔI",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _handleBooking() async {
    if (_selectedPetId == null || _selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vui lòng chọn đầy đủ thú cưng và loại phòng")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final profile = await ApiService.getUserProfile();

      // TẠO JSON CHUẨN ĐỂ C# MAPPING VÀO ENTITY
      Map<String, dynamic> bookingData = {
        "UserId": profile?['id'],
        "UserName": profile?['fullName'] ?? "",
        "OwnerPhoneNumber": _phoneController.text,
        "ExistingPetId": _selectedPetId,
        "PetName": _petNameController.text,
        "PetType": _petTypeController.text,
        "PetBreed": _petBreedController.text,
        "ServiceId": _selectedService!.serviceId,
        "ServiceName": _selectedService!.name,
        // Gửi ISO String là đúng cho Backend DateTime,
        // nhưng C# khi lưu Blockchain sẽ tự convert sang dd/MM/yyyy theo code của bạn
        "StartDate": _startDate.toIso8601String(),
        "EndDate": _endDate.toIso8601String(),
        "Status": 0,
        "Note": ""
      };

      debugPrint("JSON GỬI LÊN: ${jsonEncode(bookingData)}");

      bool isUpdate = widget.appointment != null;
      var appId = widget.appointment?['appointmentId'] ?? widget.appointment?['AppointmentId'];

      bool success = await ApiService.saveHomestayBooking(bookingData, isUpdate, id: appId);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thao tác thành công! 🎉")));
          Navigator.pop(context, true); // Quan trọng: Trả về true để trang trước load lại danh sách
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi: Server không chấp nhận dữ liệu!")));
        }
      }
    } catch (e) {
      debugPrint("Lỗi Submit Homestay: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSectionTitle(String icon, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text("$icon $title", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
  );

  Widget _buildReadonlyField(String label, TextEditingController controller) => TextFormField(
    controller: controller,
    readOnly: true,
    decoration: InputDecoration(labelText: label, filled: true, fillColor: Colors.grey.shade100, border: const OutlineInputBorder()),
  );
}