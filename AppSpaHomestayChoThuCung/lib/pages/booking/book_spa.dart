import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Thêm để chỉnh status bar
import 'package:intl/intl.dart';
import '../../../model/service/service.dart';
import '../../../services/api_service.dart';

class SpaBookingPage extends StatefulWidget {
  final Map<String, dynamic>? appointment;

  const SpaBookingPage({super.key, this.appointment});

  @override
  State<SpaBookingPage> createState() => _SpaBookingPageState();
}

class _SpaBookingPageState extends State<SpaBookingPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  // Hằng số màu sắc đồng bộ
  static const kLightPink = Color(0xFFFFB6C1);

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

  List<dynamic> _userPets = [];
  List<ServiceModel> _spaServices = [];

  late TextEditingController _phoneController;
  late TextEditingController _petNameController;
  late TextEditingController _petTypeController;
  late TextEditingController _petBreedController;
  late TextEditingController _petAgeController;
  late TextEditingController _petWeightController;

  int? _selectedPetId;
  ServiceModel? _selectedService;
  String _calculatedPrice = "0 VNĐ";

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTime = const TimeOfDay(hour: 9, minute: 0);
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
        ApiService.getSpaBookingData(),
      ]);

      setState(() {
        _userPets = List.from(results[0] as Iterable);
        _userPets.sort((a, b) => (a['name'] ?? "").compareTo(b['name'] ?? ""));

        final rawSpaData = results[1] as Map<String, dynamic>;
        _spaServices = List<ServiceModel>.from(rawSpaData['services']);

        if (_userPets.isNotEmpty) {
          _selectedPetId = widget.appointment?['petId'] ?? _userPets.first['petId'];
          _updatePetFields(_selectedPetId);
        }
        if (_spaServices.isNotEmpty) {
          _selectedService = _spaServices.first;
          _calculatePrice();
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
        _calculatePrice();
      });
    }
  }

  void _calculatePrice() {
    if (_selectedService == null || _selectedService!.spaPricing == null) return;
    double weight = double.tryParse(_petWeightController.text) ?? 0;
    double price = 0;
    var pricing = _selectedService!.spaPricing!;

    if (weight < 5) price = pricing.priceUnder5kg ?? 0;
    else if (weight <= 12) price = pricing.price5To12kg ?? 0;
    else if (weight <= 25) price = pricing.price12To25kg ?? 0;
    else price = pricing.priceOver25kg ?? 0;

    setState(() {
      _calculatedPrice = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ', decimalDigits: 0).format(price);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Chỉnh status bar đồng bộ
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: kLightPink)));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.appointment == null ? "🧼 Đặt lịch Spa" : "✏️ Cập nhật Spa",
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
                        child: Text(pet['name']),
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
                title: "Dịch vụ Spa",
                icon: Icons.bubble_chart_outlined,
                child: Column(
                  children: [
                    DropdownButtonFormField<ServiceModel>(
                      value: _selectedService,
                      isExpanded: true,
                      items: _spaServices.map((service) => DropdownMenuItem<ServiceModel>(
                        value: service,
                        child: Text(service.name),
                      )).toList(),
                      onChanged: (val) {
                        setState(() => _selectedService = val);
                        _calculatePrice();
                      },
                      decoration: _inputDecoration("Gói dịch vụ", Icons.spa_outlined),
                    ),
                    const SizedBox(height: 15),
                    _buildPriceDisplay(),
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

  // --- HELPER WIDGETS (ĐỒNG BỘ VỚI VET) ---

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

  Widget _buildPriceDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: kLightPink.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Giá dịch vụ:", style: TextStyle(fontWeight: FontWeight.w500)),
          Text(_calculatedPrice, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return Row(
      children: [
        Expanded(child: _timePickerBox(label: "Ngày", value: DateFormat('dd/MM/yyyy').format(_selectedDate), icon: Icons.calendar_month, onTap: _pickDate)),
        const SizedBox(width: 12),
        Expanded(child: _timePickerBox(label: "Giờ", value: _selectedTime.format(context), icon: Icons.access_time, onTap: _pickTime)),
      ],
    );
  }

  Widget _timePickerBox({required String label, required String value, required IconData icon, required VoidCallback onTap}) {
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
        widget.appointment == null ? "XÁC NHẬN ĐẶT LỊCH" : "LƯU THAY ĐỔI",
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  // --- LOGIC PICKER ---
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
      builder: (context, child) => Theme(data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: kLightPink)), child: child!),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _handleBooking() async {
    if (_selectedPetId == null || _selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn thú cưng và dịch vụ")));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final profile = await ApiService.getUserProfile();
      Map<String, dynamic> bookingData = {
        "UserId": profile?['id'],
        "OwnerPhoneNumber": _phoneController.text,
        "ExistingPetId": _selectedPetId,
        "PetName": _petNameController.text,
        "PetType": _petTypeController.text,
        "PetWeight": double.tryParse(_petWeightController.text) ?? 0,
        "PetBreed": _petBreedController.text,
        "ServiceId": _selectedService!.serviceId,
        "AppointmentDate": DateFormat('yyyy-MM-dd').format(_selectedDate),
        "AppointmentTime": "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}",
        "TotalPrice": double.tryParse(_calculatedPrice.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
        "Status": "Pending"
      };
      bool isUpdate = widget.appointment != null;
      bool success = await ApiService.saveSpaBooking(bookingData, isUpdate, id: widget.appointment?['appointmentId']);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thao tác thành công! 🎉"), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}