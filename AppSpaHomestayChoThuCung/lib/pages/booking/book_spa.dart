import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class SpaBookingPage extends StatefulWidget {
  final dynamic initialData;
  final bool isUpdate;

  const SpaBookingPage({Key? key, this.initialData, this.isUpdate = false}) : super(key: key);

  @override
  _SpaBookingPageState createState() => _SpaBookingPageState();
}

class _SpaBookingPageState extends State<SpaBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final Color pinkColor = const Color(0xFFE91E63);

  List<dynamic> _userPets = [];
  List<dynamic> _spaServices = [];
  List<dynamic> _spaPricings = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _petNameController = TextEditingController();
  final TextEditingController _petTypeController = TextEditingController();
  final TextEditingController _petBreedController = TextEditingController();
  final TextEditingController _petAgeController = TextEditingController();
  final TextEditingController _petWeightController = TextEditingController();

  dynamic _selectedPet;
  dynamic _selectedService;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Lấy dữ liệu đồng thời
      final results = await Future.wait([
        ApiService.getUserPets(),
        ApiService.getSpaBookingData(),
      ]);

      setState(() {
        _userPets = results[0] as List<dynamic>;
        final metadata = results[1] as Map<String, dynamic>;
        _spaServices = metadata['services'] ?? [];
        _spaPricings = metadata['pricings'] ?? [];

        // 2. Logic gán mặc định cho đặt lịch mới
        if (!widget.isUpdate) {
          if (_userPets.isNotEmpty) {
            _selectedPet = _userPets.first;
            _fillPetFields(_selectedPet);
          }
          if (_spaServices.isNotEmpty) {
            _selectedService = _spaServices.first;
          }
        }
        // 3. Logic gán cho cập nhật lịch cũ
        else if (widget.initialData != null) {
          _fillUpdateData();
        }

        _isLoading = false;
      });
    } catch (e) {
      print("CRITICAL ERROR: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = "Lỗi kết nối hoặc cấu trúc dữ liệu: $e";
      });
    }
  }

  void _fillPetFields(dynamic pet) {
    if (pet == null) return;
    setState(() {
      // Tìm cả camelCase và PascalCase để tránh null
      _petNameController.text = (pet['name'] ?? pet['Name'] ?? "").toString();
      _petTypeController.text = (pet['type'] ?? pet['Type'] ?? "").toString();
      _petBreedController.text = (pet['breed'] ?? pet['Breed'] ?? "").toString();
      _petAgeController.text = (pet['age'] ?? pet['Age'] ?? "").toString();
      _petWeightController.text = (pet['weight'] ?? pet['Weight'] ?? "0").toString();
    });
  }

  void _fillUpdateData() {
    final data = widget.initialData;
    _phoneController.text = (data['ownerPhoneNumber'] ?? data['OwnerPhoneNumber'] ?? "").toString();

    // Parse Date/Time
    try {
      String? dateStr = data['appointmentDate'] ?? data['AppointmentDate'];
      if (dateStr != null) {
        _selectedDate = dateStr.contains('T') ? DateTime.parse(dateStr) : DateFormat('dd/MM/yyyy').parse(dateStr);
      }
    } catch (e) { print("Date Parse Error: $e"); }

    // Map Pet & Service
    if (_userPets.isNotEmpty) {
      final targetPetId = data['petId'] ?? data['PetId'];
      _selectedPet = _userPets.firstWhere(
            (p) => (p['petId'] ?? p['PetId']) == targetPetId,
        orElse: () => _userPets.first,
      );
      _fillPetFields(_selectedPet);
    }

    if (_spaServices.isNotEmpty) {
      final targetServiceId = data['serviceId'] ?? data['ServiceId'];
      _selectedService = _spaServices.firstWhere(
            (s) => (s['serviceId'] ?? s['ServiceId']) == targetServiceId,
        orElse: () => _spaServices.first,
      );
    }
  }

  // Tìm và sửa hàm này trong trang SpaBookingPage của bạn
  String _calculatePrice() {
    if (_selectedService == null || _spaPricings.isEmpty) return "0 VNĐ";

    final weight = double.tryParse(_petWeightController.text) ?? 0;
    final currentSId = _selectedService['serviceId'] ?? _selectedService['ServiceId'];

    // Tìm pricing dựa trên serviceId
    final pricing = _spaPricings.firstWhere(
          (p) => (p['serviceId'] ?? p['ServiceId']) == currentSId,
      orElse: () => null,
    );

    if (pricing == null) return "Liên hệ báo giá";

    // Kiểm tra tên trường từ Backend trả về (thường là viết hoa chữ đầu trong C#)
    double p5 = (pricing['priceUnder5kg'] ?? pricing['PriceUnder5kg'] ?? 0).toDouble();
    double p12 = (pricing['price5To12kg'] ?? pricing['Price5To12kg'] ?? 0).toDouble();
    double p25 = (pricing['price12To25kg'] ?? pricing['Price12To25kg'] ?? 0).toDouble();
    double pOver = (pricing['priceOver25kg'] ?? pricing['PriceOver25kg'] ?? 0).toDouble();

    double price = 0;
    if (weight < 5) price = p5;
    else if (weight <= 12) price = p12;
    else if (weight <= 25) price = p25;
    else price = pOver;

    return NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ', decimalDigits: 0).format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.isUpdate ? "✏️ Sửa lịch Spa" : "🧼 Đặt lịch Spa",
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 10),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _loadAllData, child: const Text("Thử lại")),
            ],
          ),
        ),
      );
    }

    if (_userPets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pets, size: 80, color: Colors.grey),
            const Text("Bạn chưa có thú cưng nào được đăng ký!"),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Quay lại")),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("🐾", "Chọn thú cưng"),
            _buildPetDropdown(),
            const SizedBox(height: 10),
            _buildPetDetailsGrid(),
            const SizedBox(height: 20),
            _buildSectionTitle("🧴", "Chọn dịch vụ Spa"),
            _buildServiceDropdown(),
            const SizedBox(height: 20),
            _buildSectionTitle("💰", "Giá dịch vụ dự kiến"),
            _buildPriceDisplay(),
            const SizedBox(height: 20),
            _buildSectionTitle("📅", "Thời gian hẹn"),
            _buildDateTimeRow(),
            const SizedBox(height: 30),
            _buildSubmitButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- Các Widget thành phần ---
  Widget _buildSectionTitle(String icon, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [Text(icon, style: const TextStyle(fontSize: 20)), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
  );

  Widget _buildPetDropdown() => DropdownButtonFormField<dynamic>(
    value: _selectedPet,
    isExpanded: true,
    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
    items: _userPets.map((pet) => DropdownMenuItem(value: pet, child: Text((pet['name'] ?? pet['Name'] ?? "Chưa đặt tên").toString()))).toList(),
    onChanged: (val) { setState(() { _selectedPet = val; _fillPetFields(val); }); },
  );

  Widget _buildServiceDropdown() => DropdownButtonFormField<dynamic>(
    value: _selectedService,
    isExpanded: true,
    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
    items: _spaServices.map((s) => DropdownMenuItem(value: s, child: Text((s['name'] ?? s['Name'] ?? "Dịch vụ").toString()))).toList(),
    onChanged: (val) => setState(() => _selectedService = val),
  );

  Widget _buildPetDetailsGrid() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      _buildInfoItem("Giống", _petBreedController.text),
      _buildInfoItem("Nặng", "${_petWeightController.text} kg"),
      _buildInfoItem("Tuổi", _petAgeController.text),
    ]),
  );

  Widget _buildInfoItem(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)), Text(value.isEmpty ? "..." : value, style: const TextStyle(fontWeight: FontWeight.bold))]);

  Widget _buildPriceDisplay() => Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(10)), child: Center(child: Text(_calculatePrice(), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 24))));

  Widget _buildDateTimeRow() => Row(children: [
    Expanded(child: InkWell(onTap: _pickDate, child: _buildTimeBox("Ngày hẹn", DateFormat('dd/MM/yyyy').format(_selectedDate)))),
    const SizedBox(width: 15),
    Expanded(child: InkWell(onTap: _pickTime, child: _buildTimeBox("Giờ hẹn", _selectedTime.format(context)))),
  ]);

  Widget _buildTimeBox(String label, String value) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]));

  Widget _buildSubmitButton() => ElevatedButton(
      onPressed: _handleSave,
      style: ElevatedButton.styleFrom(backgroundColor: pinkColor, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      child: Text(widget.isUpdate ? "LƯU THAY ĐỔI" : "XÁC NHẬN ĐẶT LỊCH", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
  );

  // Logic Chọn Ngày/Giờ/Lưu
  Future<void> _pickDate() async { DateTime? p = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30))); if (p != null) setState(() => _selectedDate = p); }
  Future<void> _pickTime() async { TimeOfDay? t = await showTimePicker(context: context, initialTime: _selectedTime); if (t != null) setState(() => _selectedTime = t); }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final int? apptId = widget.isUpdate ? widget.initialData['appointmentId'] ?? widget.initialData['AppointmentId'] : null;
    final Map<String, dynamic> data = {
      "ServiceId": _selectedService['serviceId'] ?? _selectedService['ServiceId'],
      "ExistingPetId": _selectedPet['petId'] ?? _selectedPet['PetId'],
      "AppointmentDate": DateFormat('yyyy-MM-dd').format(_selectedDate),
      "AppointmentTime": "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00",
      "OwnerPhoneNumber": _phoneController.text,
      "PetName": _petNameController.text,
      "PetType": _petTypeController.text,
      "PetBreed": _petBreedController.text,
      "PetAge": _petAgeController.text,
      "PetWeight": double.tryParse(_petWeightController.text) ?? 0,
    };

    _showLoading();
    try {
      final success = await ApiService.saveSpaBooking(data, widget.isUpdate, id: apptId);
      Navigator.pop(context);
      if (success) _showSuccessDialog(); else _showErrorSnackBar("Không thể lưu lịch hẹn.");
    } catch (e) { Navigator.pop(context); _showErrorSnackBar("Lỗi: $e"); }
  }

  void _showLoading() => showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
  void _showErrorSnackBar(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));
  void _showSuccessDialog() { showDialog(context: context, builder: (_) => AlertDialog(title: const Text("Thành công"), content: const Text("Lịch hẹn của bạn đã được xử lý."), actions: [TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context, true); }, child: const Text("OK"))])); }
}