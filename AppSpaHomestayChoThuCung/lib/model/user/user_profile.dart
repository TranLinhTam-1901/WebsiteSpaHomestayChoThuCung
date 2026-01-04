class UserProfile {
  final String id;
  final String fullName;
  final String userName;   // Mới: Đồng bộ với ASP.NET Identity
  final String email;
  final String phone;
  final String address;
  final String role;
  final bool isLocked;     // Mới: Quản lý trạng thái tài khoản
  final String? publicKey; // Mới: Blockchain integration
  final DateTime? createdAt;
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

  // Factory hỗ trợ map dữ liệu linh hoạt từ Backend
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['FullName'] ?? '').toString(),
      userName: (json['userName'] ?? json['UserName'] ?? '').toString(),
      email: (json['email'] ?? json['Email'] ?? '').toString(),
      // Backend thường trả về PhoneNumber thay vì phone
      phone: (json['phoneNumber'] ?? json['phone'] ?? json['Phone'] ?? '').toString(),
      address: (json['address'] ?? json['Address'] ?? '').toString(),
      role: (json['role'] ?? json['Role'] ?? 'Customer').toString(),
      isLocked: json['isLocked'] == true || json['IsLocked'] == true,
      publicKey: (json['publicKey'] ?? json['PublicKey'])?.toString(),
      avatarUrl: (json['avatarUrl'] ?? json['AvatarUrl'])?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : (json['CreatedAt'] != null
          ? DateTime.tryParse(json['CreatedAt'].toString())
          : null),
    );
  }

  // Giữ lại copyWith để dễ dàng update state trong Flutter
  UserProfile copyWith({
    String? id,
    String? fullName,
    String? userName,
    String? email,
    String? phone,
    String? address,
    String? role,
    bool? isLocked,
    String? publicKey,
    DateTime? createdAt,
    String? avatarUrl,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      role: role ?? this.role,
      isLocked: isLocked ?? this.isLocked,
      publicKey: publicKey ?? this.publicKey,
      createdAt: createdAt ?? this.createdAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  // Chuyển ngược lại JSON nếu cần gửi dữ liệu lên Backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'userName': userName,
      'email': email,
      'phoneNumber': phone,
      'address': address,
      'role': role,
      'isLocked': isLocked,
      'publicKey': publicKey,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}