import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ⭐ Thêm import này
import '../Api/UserApiService.dart';
import '../Api/auth_service.dart';
import '../model/user/user_profile.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ⭐ Nhớ thêm import này
class UserController extends GetxController {
  var isLoading = false.obs;
  final Rxn<UserProfile> profile = Rxn<UserProfile>();

  @override
  void onInit() {
    super.onInit();
    // Tự động khôi phục session khi app khởi động lại
    restoreSession();
  }

  /// Khôi phục JWT từ SharedPreferences nạp lại vào AuthService
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('jwt_token');

    if (savedToken != null && AuthService.jwtToken == null) {
      // Nạp lại token vào biến RAM của AuthService
      AuthService.jwtToken = savedToken;
      print("✅ Đã khôi phục JWT từ SharedPreferences");

      // Sau khi nạp token, tự động load profile
      await loadProfile();
    }
  }

  Future<void> loadProfile() async {
    try {
      isLoading.value = true;

      // 1. Kiểm tra JWT (Dành cho đăng nhập API thủ công)
      final token = AuthService.jwtToken;

      if (token != null) {
        profile.value = await UserApiService.getMyProfile(token);
        print("✅ Đã load Profile từ API bằng JWT");
        return; // Thoát hàm nếu đã có dữ liệu
      }

      // 2. Nếu không có JWT, kiểm tra Firebase User (Dành cho đăng nhập Google)
      // Firebase sẽ mất một chút thời gian để khôi phục session sau khi F5
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser != null) {
        print("ℹ️ Đang khôi phục dữ liệu từ Firebase cho: ${firebaseUser.email}");
        profile.value = UserProfile(
          id: firebaseUser.uid,
          fullName: firebaseUser.displayName ?? "Người dùng Google",
          userName: firebaseUser.email ?? "", // 👈 THÊM DÒNG NÀY (Lấy email làm userName tạm thời)
          email: firebaseUser.email ?? "",
          phone: "",
          address: "",
          avatarUrl: firebaseUser.photoURL ?? "",
          role: 'User',
          isLocked: false, // Thêm các giá trị mặc định nếu cần
        );
        return;
      }

      print("❌ Không tìm thấy JWT và cũng không có User Firebase");
    } catch (e) {
      print("❌ loadProfile error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  bool get isLoggedIn => profile.value != null;
}