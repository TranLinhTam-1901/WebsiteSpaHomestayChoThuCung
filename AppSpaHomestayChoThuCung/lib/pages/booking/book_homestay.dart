import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Hằng số màu sắc đồng bộ
  static const kLightPink = Color(0xFFFFB6C1);

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
      _startDate = DateTime.parse(widget.appointment!['startDate'] ?? DateTime.now().toString());
      _endDate = DateTime.parse(widget.appointment!['endDate'] ?? DateTime.now().add(const Duration(days: 1)).toString());
    }
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
        _userPets = List.from(results[0] as Iterable);
        _userPets.sort((a, b) => (a['name'] ?? "").compareTo(b['name'] ?? ""));

        final rawData = results[1] as Map<String, dynamic>;
        _homestayServices = List<ServiceModel>.from(rawData['services'] ?? []);

        if (_userPets.isNotEmpty) {
          _selectedPetId = widget.appointment?['petId'] ?? _userPets.first['petId'];
          _updatePetFields(_selectedPetId);
        }

        if (_homestayServices.isNotEmpty) {
          int? targetId = widget.appointment?['serviceId'] ?? _homestayServices.first.serviceId;
          _selectedService = _homestayServices.firstWhere(
                (s) => s.serviceId == targetId,
            orElse: () => _homestayServices.first,
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("LỖI LOAD DATA: $e");
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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: kLightPink)));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.appointment == null ? "🏨 Đặt lịch Homestay" : "✏️ Cập nhật Homestay",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: kLightPink,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildCard(
                title: "Thông tin chủ nuôi",
                icon: Icons.person_outline,
                child: TextFormField(
                  controller: _phoneController,
                  decoration: _inputDecoration("Số điện thoại liên hệ", Icons.phone_android),
                ),
              ),

              _buildCard(
                title: "Thú cưng của bạn",
                icon: Icons.pets_outlined,
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      value: _selectedPetId,
                      isExpanded: true,
                      items: _userPets.map((pet) => DropdownMenuItem<int>(
                        value: pet['petId'],
                        child: Text(pet['name'] ?? "Không tên"),
                      )).toList(),
                      onChanged: (val) {
                        setState(() => _selectedPetId = val);
                        _updatePetFields(val);
                      },
                      decoration: _inputDecoration("Chọn thú cưng", Icons.expand_more),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: _buildReadonlyField("Loại", _petTypeController)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildReadonlyField("Giống", _petBreedController)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildReadonlyField("Tuổi", _petAgeController)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildReadonlyField("Cân nặng (kg)", _petWeightController)),
                      ],
                    ),
                  ],
                ),
              ),

              _buildCard(
                title: "Loại phòng Homestay",
                icon: Icons.bed_outlined,
                child: DropdownButtonFormField<int>(
                  value: _selectedService?.serviceId,
                  isExpanded: true,
                  hint: const Text("Chọn loại phòng"),
                  items: _homestayServices.map((service) {
                    return DropdownMenuItem<int>(
                      value: service.serviceId,
                      child: Text(service.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedService = _homestayServices.firstWhere((s) => s.serviceId == val);
                    });
                  },
                  decoration: _inputDecoration("Chọn phòng lưu trú", Icons.meeting_room_outlined),
                ),
              ),

              _buildCard(
                title: "Thời gian lưu trú",
                icon: Icons.date_range_outlined,
                child: _buildDateRangePicker(),
              ),

              const SizedBox(height: 20),
              _buildMainButton(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ĐỒNG BỘ ---

  Widget _buildCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.pinkAccent),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, size: 20, color: Colors.grey) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kLightPink)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _buildReadonlyField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return Row(
      children: [
        Expanded(child: _datePickerBox(label: "Ngày bắt đầu", value: DateFormat('dd/MM/yyyy').format(_startDate), icon: Icons.login, onTap: _pickStartDate)),
        const SizedBox(width: 12),
        Expanded(child: _datePickerBox(label: "Ngày kết thúc", value: DateFormat('dd/MM/yyyy').format(_endDate), icon: Icons.logout, onTap: _pickEndDate)),
      ],
    );
  }

  Widget _datePickerBox({required String label, required String value, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(children: [Icon(icon, size: 16, color: Colors.pinkAccent), const SizedBox(width: 8), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]),
          ],
        ),
      ),
    );
  }

  Widget _buildMainButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: kLightPink,
        foregroundColor: Colors.black87,
        minimumSize: const Size(double.infinity, 55),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: _handleBooking,
      child: Text(
        widget.appointment == null ? "XÁC NHẬN ĐẶT PHÒNG" : "LƯU THAY ĐỔI",
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  // --- LOGIC PICKER ---

  Future<void> _pickStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: Colors.pinkAccent)), child: child!),
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
      builder: (context, child) => Theme(data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: Colors.pinkAccent)), child: child!),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  void _handleBooking() async {
    if (_selectedPetId == null || _selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn đầy đủ thú cưng và loại phòng")));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final profile = await ApiService.getUserProfile();
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
        "StartDate": _startDate.toIso8601String(),
        "EndDate": _endDate.toIso8601String(),
        "Status": 0,
        "Note": ""
      };
      bool isUpdate = widget.appointment != null;
      bool success = await ApiService.saveHomestayBooking(bookingData, isUpdate, id: widget.appointment?['appointmentId'] ?? widget.appointment?['AppointmentId']);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thao tác thành công! 🎉"), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}