import 'package:flutter/material.dart';
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

  // --- 1. KHAI BÁO BIẾN THỜI GIAN (ĐÃ BỔ SUNG) ---
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
    // Khởi tạo giá trị mặc định ngay lập tức để tránh lỗi undefined trên Web
    _selectedDate = DateTime.now();
    _selectedTime = const TimeOfDay(hour: 9, minute: 0);

    _initControllers();
    _loadData();
  }

  void _initControllers() {
    // CHỈ GIỮ LẠI ĐOẠN NÀY
    _phoneController = TextEditingController(text: widget.appointment?['ownerPhoneNumber'] ?? "");
    _petNameController = TextEditingController();
    _petTypeController = TextEditingController();
    _petBreedController = TextEditingController();
    _petAgeController = TextEditingController();
    _petWeightController = TextEditingController();
  }

  // --- 2. HÀM CHỌN NGÀY/GIỜ ---
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Lấy thông tin Profile trước và gán ngay
      final profile = await ApiService.getUserProfile();
      debugPrint("DEBUG PROFILE: $profile");

      if (profile != null && widget.appointment == null) {
        String phone = profile['phoneNumber']?.toString() ?? "";
        _phoneController.text = phone;
      }

      // 2. Sau đó mới lấy các dữ liệu khác
      final results = await Future.wait([
        ApiService.getPets(),
        ApiService.getSpaBookingData(),
      ]);

      setState(() {
        _userPets = List.from(results[0] as Iterable);
        _userPets.sort((a, b) => (a['name'] ?? "").compareTo(b['name'] ?? ""));

        final rawSpaData = results[1] as Map<String, dynamic>;
        _spaServices = List<ServiceModel>.from(rawSpaData['services']);

        _isLoading = false;

        // Khởi tạo mặc định
        if (_userPets.isNotEmpty) {
          _selectedPetId = widget.appointment?['petId'] ?? _userPets.first['petId'];
          _updatePetFields(_selectedPetId);
        }
        if (_spaServices.isNotEmpty) {
          _selectedService = _spaServices.first;
          _calculatePrice();
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("LỖI TỔNG HỢP: $e");
    }
  }

  void _updatePetFields(int? petId) {
    if (_userPets.isEmpty || petId == null) return;

    final pet = _userPets.firstWhere((p) => p['petId'] == petId, orElse: () => null);

    if (pet != null) {
      setState(() {
        _petNameController.text = pet['name'] ?? "";
        _petTypeController.text = pet['type'] ?? "";
        _petBreedController.text = pet['breed'] ?? ""; // Thêm Giống
        _petAgeController.text = pet['age']?.toString() ?? ""; // Thêm Tuổi
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.pinkAccent)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appointment == null ? "🧼 Đặt lịch Spa" : "✏️ Cập nhật lịch Spa"),
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

              // Thay thế đoạn hiển thị thú cưng cũ bằng đoạn này:
              _buildSectionTitle("🐾", "Chọn thú cưng"),
              const Text("Thú cưng có sẵn", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 5),
              DropdownButtonFormField<int>(
                value: _selectedPetId,
                items: _userPets.map((pet) => DropdownMenuItem<int>(
                  value: pet['petId'],
                  child: Text(pet['name']),
                )).toList(),
                onChanged: (val) {
                  setState(() => _selectedPetId = val);
                  _updatePetFields(val);
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),

              // Hàng 1: Tên thú cưng và Loại
              Row(
                children: [
                  Expanded(child: _buildReadonlyField("Tên thú cưng", _petNameController)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildReadonlyField("Loại", _petTypeController)),
                ],
              ),
              const SizedBox(height: 10),

              // Hàng 2: Giống
              _buildReadonlyField("Giống", _petBreedController),
              const SizedBox(height: 10),

              // Hàng 3: Tuổi và Cân nặng
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
                          suffixText: "kg", // Thêm đơn vị kg như trong hình
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: const OutlineInputBorder()
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildSectionTitle("🧴", "Chọn dịch vụ Spa"),
              DropdownButtonFormField<ServiceModel>(
                value: _selectedService,
                items: _spaServices.map((service) => DropdownMenuItem<ServiceModel>(
                  value: service,
                  child: Text(service.name),
                )).toList(),
                onChanged: (val) {
                  setState(() => _selectedService = val);
                  _calculatePrice();
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle("💰", "Giá dịch vụ"),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade100)
                ),
                child: Text(_calculatedPrice, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle("📅", "Thời gian hẹn"),
              // --- 3. GIAO DIỆN CHỌN NGÀY GIỜ ---
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: "Ngày hẹn", border: OutlineInputBorder()),
                        child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: "Giờ hẹn", border: OutlineInputBorder()),
                        child: Text(_selectedTime.format(context)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade100, // Hồng nhạt chuẩn
                  foregroundColor: Colors.pink.shade700, // Chữ hồng đậm cho dễ đọc
                  minimumSize: const Size(double.infinity, 55),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: Colors.pink.shade200)
                  ),
                ),
                onPressed: _handleBooking,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  widget.appointment == null ? "XÁC NHẬN ĐẶT LỊCH" : "LƯU THAY ĐỔI",
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
          const SnackBar(content: Text("Vui lòng chọn thú cưng và dịch vụ"))
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profile = await ApiService.getUserProfile();

      Map<String, dynamic> bookingData = {
        "UserId": profile?['id'],
        "OwnerPhoneNumber": _phoneController.text,

        // ĐỔI TÊN Ở ĐÂY: Từ PetId thành ExistingPetId
        "ExistingPetId": _selectedPetId,

        // Giữ lại các trường này để thỏa mãn [Required] của Backend
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
      var appId = widget.appointment?['appointmentId'];

      bool success = await ApiService.saveSpaBooking(bookingData, isUpdate, id: appId);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Thao tác thành công! 🎉"))
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Lỗi: Server từ chối dữ liệu. ❌"))
          );
        }
      }
    } catch (e) {
      debugPrint("Lỗi Local: $e");
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