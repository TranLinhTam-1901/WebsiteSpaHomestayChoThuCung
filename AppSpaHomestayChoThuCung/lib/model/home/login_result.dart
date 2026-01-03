class LoginResult {
  final String token;
  final String role;
  final String email;
  final String userId;

  LoginResult({
    required this.token,
    required this.role,
    required this.email,
    required this.userId,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      token: json['token'],
      role: json['user']['role'],
      email: json['user']['email'],
      userId: json['user']['id'],
    );
  }
}
