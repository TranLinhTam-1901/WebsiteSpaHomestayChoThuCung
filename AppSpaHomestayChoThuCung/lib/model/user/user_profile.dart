class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String role;

  // optional để sau (nếu backend có avatar)
  final String? avatarUrl;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.role,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      role: (json['role'] ?? 'Customer').toString(),
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }
}
