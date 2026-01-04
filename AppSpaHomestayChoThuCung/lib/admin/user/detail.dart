import 'package:flutter/material.dart';
import '../../model/user/user_profile.dart';
import '../../services/admin_api_service.dart';

class UserEditScreen extends StatefulWidget {
  final UserProfile user;
  const UserEditScreen({super.key, required this.user});

  @override
  State<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends State<UserEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _userNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  String? _selectedRole;
  bool _isLoading = false;

  // Trong UserEditScreen
  final List<String> _allRoles = ["Admin", "Customer"]; // Chỉ để lại 2 role này
  static const Color pinkPrimary = Color(0xFFFF6185);
  static const Color pinkLight = Color(0xFFFFB6C1);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName);
    _userNameController = TextEditingController(text: widget.user.userName);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone);
    _addressController = TextEditingController(text: widget.user.address);

    // Logic an toàn cho Dropdown
    _selectedRole = _allRoles.contains(widget.user.role)
        ? widget.user.role
        : _allRoles.first;
  }

  Future<void> _saveUser() async {
    // 1. Kiểm tra Form
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    print("Đang bắt đầu lưu..."); // Thêm log để kiểm tra

    try {
      final token = await AdminApiService.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi: Không tìm thấy Token")));
        setState(() => _isLoading = false);
        return;
      }

      final updatedUser = UserProfile(
        id: widget.user.id,
        fullName: _nameController.text.trim(),
        userName: _userNameController.text.trim(), // Không được để trống
        email: _emailController.text.trim(),       // Không được để trống
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        role: _selectedRole ?? "User",
        isLocked: widget.user.isLocked,
      );

      bool success = await AdminApiService.editUser(token, updatedUser);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Cập nhật thành công!")));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Cập nhật thất bại từ Server")));
        }
      }
    } catch (e) {
      print("Lỗi xảy ra: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi kết nối: $e")));
      }
    } finally {
      // Rất quan trọng: Đảm bảo isLoading luôn về false dù thành công hay thất bại
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text("Chỉnh sửa tài khoản",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
        centerTitle: true,
        backgroundColor: pinkLight,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 15),
              // --- PHẦN 1: AVATAR HEADER ---
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: pinkPrimary.withOpacity(0.1),
                      child: const Icon(Icons.person, size: 50, color: pinkPrimary),
                    ),
                    const SizedBox(height: 10),
                    Text(widget.user.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Text("ID: User System", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // --- PHẦN 2: CÁC MỤC TIMELINE ---
              _buildTimelineSection(
                icon: Icons.person_outline,
                title: "Thông tin cá nhân",
                isLast: false,
                content: Column(
                  children: [
                    _buildInputField("Họ và tên", _nameController, Icons.edit_note),
                    _buildInputField("Tên đăng nhập", _userNameController, Icons.badge_outlined),
                    _buildInputField("Email", _emailController, Icons.email_outlined),
                  ],
                ),
              ),

              _buildTimelineSection(
                icon: Icons.contact_phone_outlined,
                title: "Liên lạc & Địa chỉ",
                isLast: false,
                content: Column(
                  children: [
                    _buildInputField("Số điện thoại", _phoneController, Icons.phone_android),
                    _buildInputField("Địa chỉ", _addressController, Icons.location_on_outlined),
                  ],
                ),
              ),

              _buildTimelineSection(
                icon: Icons.vpn_key_outlined,
                title: "Phân quyền hệ thống",
                isLast: true,
                content: _buildRoleDropdown(),
              ),

              const SizedBox(height: 30),

              // --- PHẦN 3: NÚT BẤM ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  // Nếu _isLoading là true thì onPressed nhận null (nút bị khóa/mờ đi)
                  // Nếu _isLoading là false thì gọi hàm _saveUser
                  onPressed: _isLoading ? null : () => _saveUser(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pinkPrimary,
                    disabledBackgroundColor: Colors.grey.shade400, // Màu khi nút bị khóa
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: _isLoading ? 0 : 5, // Tắt bóng đổ khi đang loading
                    shadowColor: pinkPrimary.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text(
                    "Xác nhận thay đổi",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineSection({required IconData icon, required String title, required Widget content, bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 18, height: 18,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: pinkPrimary, width: 3),
                ),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: pinkPrimary.withOpacity(0.2))),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 25),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 16, color: pinkPrimary),
                      const SizedBox(width: 8),
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: pinkPrimary, fontSize: 13)),
                    ],
                  ),
                  const Divider(height: 20),
                  content,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        // Tự động hiện bàn phím số nếu là Số điện thoại
        keyboardType: label.contains("Số điện thoại") ? TextInputType.phone : TextInputType.text,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
          prefixIcon: Icon(icon, color: pinkPrimary.withOpacity(0.5), size: 18),
          border: InputBorder.none,
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: pinkPrimary)),
        ),
        // Thêm validator để không cho để trống
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Vui lòng nhập $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: const InputDecoration(
        border: InputBorder.none,
        prefixIcon: Icon(Icons.admin_panel_settings_outlined, color: Colors.orange, size: 18),
      ),
      icon: const Icon(Icons.arrow_drop_down, color: pinkPrimary),
      items: _allRoles.map((role) => DropdownMenuItem(value: role, child: Text(role, style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: (val) => setState(() => _selectedRole = val),
    );
  }
}