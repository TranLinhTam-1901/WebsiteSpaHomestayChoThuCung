import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import '../../../model/service/service.dart';

class VetBookingPage extends StatefulWidget {
  final Map<String, dynamic>? appointment;

  const VetBookingPage({super.key, this.appointment});

  @override
  State<VetBookingPage> createState() => _VetBookingPageState();
}

class _VetBookingPageState extends State<VetBookingPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  // Dữ liệu từ API
  List<dynamic> _userPets = [];
  List<ServiceModel> _vetServices = [];

  // Controllers
  late TextEditingController _phoneController;
  late TextEditingController _petNameController;
  late TextEditingController _petTypeController;
  late TextEditingController _petBreedController;
  late TextEditingController _petAgeController;
  late TextEditingController _petWeightController;
  late TextEditingController _noteController;

  // Trạng thái chọn
  int? _selectedPetId;
  ServiceModel? _selectedService;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);

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
    _noteController = TextEditingController(text: widget.appointment?['note'] ?? "");

    if (widget.appointment != null) {
      try {
        String dateStr = widget.appointment!['appointmentDate'] ?? "";
        _selectedDate = dateStr.contains('/')
            ? DateFormat('dd/MM/yyyy').parse(dateStr)
            : DateTime.parse(dateStr);

        String timeStr = widget.appointment!['appointmentTime'] ?? "08:00";
        final parts = timeStr.split(':');
        _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (e) {
        debugPrint("Lỗi parse thời gian: $e");
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Lấy Profile để lấy SĐT và UserId (Sửa lỗi 400)
      final profile = await ApiService.getUserProfile();
      if (profile != null && widget.appointment == null) {
        _phoneController.text = profile['phoneNumber']?.toString() ?? "";
      }

      // 2. Lấy danh sách thú cưng và dịch vụ
      final results = await Future.wait([
        ApiService.getPets(),
        ApiService.getVetBookingData(),
      ]);

      setState(() {
        // --- SẮP XẾP THÚ CƯNG THEO TÊN (A-Z) ---
        _userPets = List.from(results[0] as Iterable);
        _userPets.sort((a, b) => (a['name'] ?? "").toString().toLowerCase().compareTo((b['name'] ?? "").toString().toLowerCase()));

        final rawData = results[1] as Map<String, dynamic>;
        _vetServices = (rawData['services'] as List)
            .map((s) => ServiceModel.fromJson(s))
            .toList();

        // 3. Khởi tạo Pet và Dịch vụ mặc định
        if (_userPets.isNotEmpty) {
          _selectedPetId = widget.appointment?['petId'] ?? _userPets.first['petId'];
          _updatePetFields(_selectedPetId);
        }

        if (_vetServices.isNotEmpty) {
          int? targetId = widget.appointment?['serviceId'];
          _selectedService = _vetServices.firstWhere(
                (s) => s.serviceId == targetId,
            orElse: () => _vetServices.first,
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Lỗi loadData: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updatePetFields(int? petId) {
    if (petId == null || _userPets.isEmpty) return;
    final pet = _userPets.firstWhere((p) => p['petId'] == petId, orElse: () => null);

    if (pet != null) {
      setState(() {
        _petNameController.text = (pet['name'] ?? "").toString();
        _petTypeController.text = (pet['type'] ?? "").toString();
        _petBreedController.text = (pet['breed'] ?? "").toString();

        // Đảm bảo lấy đúng key từ JSON (Thường là 'age' hoặc 'petAge')
        var ageValue = pet['age'] ?? pet['petAge'];
        _petAgeController.text = (ageValue != null) ? ageValue.toString() : "0";

        var weightValue = pet['weight'] ?? pet['petWeight'];
        _petWeightController.text = (weightValue != null) ? weightValue.toString() : "0";
      });
    }
  }

  void _handleBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPetId == null || _selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn thú cưng và dịch vụ")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final profile = await ApiService.getUserProfile();
      final String formattedTime = "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}";

      Map<String, dynamic> bookingData = {
        "UserId": profile?['id'], // QUAN TRỌNG: Thêm UserId để sửa lỗi 400
        "OwnerPhoneNumber": _phoneController.text,
        "ExistingPetId": _selectedPetId,
        "PetName": _petNameController.text,
        "PetType": _petTypeController.text,
        "PetBreed": _petBreedController.text,
        "PetAge": int.tryParse(_petAgeController.text) ?? 0,
        "PetWeight": double.tryParse(_petWeightController.text) ?? 0,
        "ServiceId": _selectedService!.serviceId,
        "Note": _noteController.text,
        "AppointmentDate": DateFormat('yyyy-MM-dd').format(_selectedDate),
        "AppointmentTime": formattedTime,
      };

      bool isUpdate = widget.appointment != null;
      int? appId = widget.appointment?['appointmentId'];

      bool success = await ApiService.saveVetBooking(bookingData, isUpdate, id: appId);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thao tác thành công! 🎉")));
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi: Server từ chối dữ liệu (400/500)")));
      }
    } catch (e) {
      debugPrint("Lỗi Local: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI Components ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.pinkAccent)));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appointment == null ? "🩺 Đặt lịch thú y" : "✏️ Cập nhật thú y"),
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("👤", "Thông tin chủ nuôi"),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: "Số điện thoại", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),

              _buildSectionTitle("🐾", "Chọn thú cưng"),
              DropdownButtonFormField<int>(
                value: _selectedPetId,
                isExpanded: true,
                items: _userPets.map((p) => DropdownMenuItem<int>(
                    value: p['petId'], child: Text(p['name'] ?? "Không tên"))).toList(),
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
                  Expanded(child: _buildReadonlyField("Cân nặng (kg)", _petWeightController)),
                ],
              ),

              const SizedBox(height: 20),
              _buildSectionTitle("💉", "Chọn dịch vụ thú y"),
              DropdownButtonFormField<int>(
                value: _selectedService?.serviceId,
                isExpanded: true,
                items: _vetServices.map((s) => DropdownMenuItem<int>(
                    value: s.serviceId, child: Text(s.name))).toList(),
                onChanged: (val) => setState(() => _selectedService = _vetServices.firstWhere((s) => s.serviceId == val)),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              _buildPriceDisplay(),

              const SizedBox(height: 20),
              _buildSectionTitle("📝", "Ghi chú"),
              TextFormField(controller: _noteController, maxLines: 2, decoration: const InputDecoration(hintText: "Nhập triệu chứng...", border: OutlineInputBorder())),

              const SizedBox(height: 20),
              _buildSectionTitle("📅", "Thời gian hẹn"),
              _buildDateTimePicker(),

              const SizedBox(height: 35),
              ElevatedButton.icon(
                onPressed: _handleBooking,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(widget.appointment == null ? "XÁC NHẬN ĐẶT LỊCH" : "LƯU THAY ĐỔI"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade100)),
      child: Text("${NumberFormat("#,###").format(_selectedService?.price ?? 0)} VNĐ",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
    );
  }

  Widget _buildDateTimePicker() {
    return Row(
      children: [
        Expanded(child: InkWell(onTap: _pickDate, child: InputDecorator(decoration: const InputDecoration(labelText: "Ngày hẹn", border: OutlineInputBorder()),
            child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate))))),
        const SizedBox(width: 10),
        Expanded(child: InkWell(onTap: _pickTime, child: InputDecorator(decoration: const InputDecoration(labelText: "Giờ hẹn", border: OutlineInputBorder()),
            child: Text(_selectedTime.format(context))))),
      ],
    );
  }

  Widget _buildSectionTitle(String icon, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text("$icon $title", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
  );

  Widget _buildReadonlyField(String label, TextEditingController controller) => TextFormField(
    controller: controller, readOnly: true,
    decoration: InputDecoration(labelText: label, filled: true, fillColor: Colors.grey.shade100, border: const OutlineInputBorder()),
  );

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }
}