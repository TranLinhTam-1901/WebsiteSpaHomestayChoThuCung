class UserProfile {
  final String id;
  final String fullName;
  final String userName; // Mới: Thêm để giống Backend
  final String email;
  final String phone;
  final String address;
  final String role;
  final bool isLocked;   // Mới: Rất quan trọng cho trang Quản lý
  final String? publicKey; // Mới: Dùng cho Blockchain
  final DateTime? createdAt; // Mới
  final String? avatarUrl;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.userName,
    required this.email,
    required this.phone,
    required this.address,
    required this.role,
    this.isLocked = false,
    this.publicKey,
    this.createdAt,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['FullName'] ?? '').toString(),
      userName: (json['userName'] ?? json['UserName'] ?? '').toString(),
      email: (json['email'] ?? json['Email'] ?? '').toString(),

      phone: (json['phoneNumber'] ?? json['phone'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),

      role: (json['role'] ?? json['Role'] ?? 'Customer').toString(),
      isLocked: json['isLocked'] == true || json['IsLocked'] == true,
      publicKey: json['publicKey']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['CreatedAt'] != null ? DateTime.parse(json['CreatedAt']) : null),
    );
  }
}