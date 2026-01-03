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

  List<dynamic> _userPets = [];
  List<ServiceModel> _vetServices = [];

  late TextEditingController _phoneController;
  late TextEditingController _petNameController;
  late TextEditingController _petTypeController;
  late TextEditingController _petBreedController;
  late TextEditingController _petAgeController;
  late TextEditingController _petWeightController;
  late TextEditingController _noteController;

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

  // --- GIỮ NGUYÊN LOGIC XỬ LÝ ---
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
        _selectedDate = dateStr.contains('/') ? DateFormat('dd/MM/yyyy').parse(dateStr) : DateTime.parse(dateStr);
        String timeStr = widget.appointment!['appointmentTime'] ?? "08:00";
        final parts = timeStr.split(':');
        _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (e) { debugPrint("Lỗi parse thời gian: $e"); }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await ApiService.getUserProfile();
      if (profile != null && widget.appointment == null) {
        _phoneController.text = profile['phoneNumber']?.toString() ?? "";
      }
      final results = await Future.wait([ApiService.getPets(), ApiService.getVetBookingData()]);
      setState(() {
        _userPets = List.from(results[0] as Iterable);
        _userPets.sort((a, b) => (a['name'] ?? "").toString().toLowerCase().compareTo((b['name'] ?? "").toString().toLowerCase()));
        final rawData = results[1] as Map<String, dynamic>;
        _vetServices = (rawData['services'] as List).map((s) => ServiceModel.fromJson(s)).toList();
        if (_userPets.isNotEmpty) {
          _selectedPetId = widget.appointment?['petId'] ?? _userPets.first['petId'];
          _updatePetFields(_selectedPetId);
        }
        if (_vetServices.isNotEmpty) {
          int? targetId = widget.appointment?['serviceId'];
          _selectedService = _vetServices.firstWhere((s) => s.serviceId == targetId, orElse: () => _vetServices.first);
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
        "UserId": profile?['id'],
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thao tác thành công! 🎉"), backgroundColor: Colors.green));
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi: Server từ chối dữ liệu"), backgroundColor: Colors.red));
      }
    } catch (e) { debugPrint("Lỗi Local: $e"); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  // --- UI CẢI TIẾN ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.pinkAccent)));

    return Scaffold(
      backgroundColor: Colors.grey[50], // Nền xám nhạt cho app chuyên nghiệp
      appBar: AppBar(
        title: Text(
          widget.appointment == null ? "🩺 Đặt lịch thú y" : "✏️ Cập nhật thú y",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 19,
            color: Colors.black, // Chữ trắng trên nền hồng phấn rất nổi
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFB6C1), // ✅ Màu kLightPink bạn chọn
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20), // Bo góc cho mềm mại
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildCard(
                title: "Thông tin liên lạc",
                icon: Icons.person_outline,
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
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
                      style: const TextStyle(color: Colors.black, fontSize: 15),
                      items: _userPets.map((p) => DropdownMenuItem<int>(
                          value: p['petId'], child: Text(p['name'] ?? "Không tên"))).toList(),
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
                title: "Dịch vụ & Ghi chú",
                icon: Icons.medical_services_outlined,
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      value: _selectedService?.serviceId,
                      isExpanded: true,
                      items: _vetServices.map((s) => DropdownMenuItem<int>(
                          value: s.serviceId, child: Text(s.name))).toList(),
                      onChanged: (val) => setState(() => _selectedService = _vetServices.firstWhere((s) => s.serviceId == val)),
                      decoration: _inputDecoration("Dịch vụ cần thực hiện", Icons.vaccines_outlined),
                    ),
                    const SizedBox(height: 12),
                    _buildPriceDisplay(),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: _inputDecoration("Triệu chứng hoặc yêu cầu thêm...", null),
                    ),
                  ],
                ),
              ),

              _buildCard(
                title: "Thời gian hẹn",
                icon: Icons.calendar_today_outlined,
                child: _buildDateTimePicker(),
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

  // --- WIDGET HELPER ---

  Widget _buildCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))
        ],
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
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, size: 20, color: Colors.grey) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.pinkAccent)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _buildReadonlyField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildPriceDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.pink.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Tổng chi phí dự kiến:", style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.w500)),
          Text("${NumberFormat("#,###").format(_selectedService?.price ?? 0)}đ",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return Row(
      children: [
        Expanded(
          child: _timePickerBox(
            label: "Ngày",
            value: DateFormat('dd/MM/yyyy').format(_selectedDate),
            icon: Icons.calendar_month,
            onTap: _pickDate,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _timePickerBox(
            label: "Giờ",
            value: _selectedTime.format(context),
            icon: Icons.access_time,
            onTap: _pickTime,
          ),
        ),
      ],
    );
  }

  Widget _timePickerBox({required String label, required String value, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(icon, size: 16, color: Colors.pinkAccent),
                const SizedBox(width: 8),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainButton() {
    const kLightPink = Color(0xFFFFB6C1); // Khai báo lại màu bạn chọn

    return ElevatedButton(
      onPressed: _handleBooking,
      style: ElevatedButton.styleFrom(
        backgroundColor: kLightPink, // ✅ Đổi sang hồng phấn
        foregroundColor: Colors.black87, // ✅ Đổi sang chữ đen (nhìn sang và dễ đọc)
        minimumSize: const Size(double.infinity, 55),
        elevation: 0, // Giảm elevation để nhìn nút phẳng và hiện đại hơn
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Text(
        widget.appointment == null ? "XÁC NHẬN ĐẶT LỊCH" : "CẬP NHẬT LỊCH HẸN",
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: Colors.pinkAccent)), child: child!),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: Colors.pinkAccent)), child: child!),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }
}