import 'package:baitap1/pages/home/home.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

import '../Api/UserApiService.dart';
import '../Api/auth_service.dart';
import '../model/promotion_model.dart';
import '../model/user/user_profile.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/Cart/cart_item_model.dart';
import '../pages/history/order/order_history.dart';
import 'cart_controller.dart';

class CheckoutController extends GetxController {
  final Rxn<PromotionModel> selectedPromotion = Rxn<PromotionModel>();
  final promoCode = ''.obs; // gửi lên API checkout

  final isLoading = false.obs;
  final Rxn<UserProfile> profile = Rxn<UserProfile>();

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }


  Future<void> placeOrder({required List<CartItem> items}) async {
    try {
      isLoading.value = true;

      final token = AuthService.jwtToken;
      if (token == null) throw Exception("Chưa đăng nhập");

      // ✅ Detect BuyNow vs Cart:
      // BuyNow của bạn đang set cartItemId = -1
      final isBuyNow = items.length == 1 && items.first.cartItemId == -1;

      final body = <String, dynamic>{
        "promoCode": promoCode.value.trim().isEmpty ? null : promoCode.value.trim(),
        "paymentMethod": "COD", // TODO: lấy từ UI PaymentMethodSection nếu bạn có state
        "notes": "",
        "isBuyNowCheckout": isBuyNow,
      };

      if (isBuyNow) {
        final i = items.first;
        body.addAll({
          "buyNowProductId": i.productId,
          "buyNowQuantity": i.quantity,
          "buyNowVariantId": i.variantId, // có thể null
          "buyNowFlavor": "", // nếu bạn có flavor thì gán vào đây
        });
      } else {
        body.addAll({
          "selectedCartItemIds": items.map((e) => e.cartItemId).toList(),
        });
      }

      final res = await http.post(
        Uri.parse("https://localhost:7051/api/checkout"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode != 200) {
        throw Exception(data["message"] ?? "Đặt hàng thất bại");
      }

      Get.snackbar("Thành công", data["message"] ?? "Đặt hàng thành công");
      if (Get.isRegistered<CartController>()) {
        await Get.find<CartController>().loadCart(); // load lại từ server (server đã xóa cart)
      }

      Get.offAll(() => HomePage(model: HomeViewModel.demo()));


    } catch (e) {
      Get.snackbar("Lỗi", e.toString());
    } finally {
      isLoading.value = false;
    }
  }


  void setPromotion(PromotionModel p) {
    selectedPromotion.value = p;
    promoCode.value = p.code;
  }

  void clearPromotion() {
    selectedPromotion.value = null;
    promoCode.value = '';
  }
  Future<void> loadUserProfile() async {
    isLoading.value = true;
    try {
      final token = AuthService.jwtToken;
      if (token == null) throw Exception("Chưa đăng nhập");

      final data = await UserApiService.getMyProfile(token);
      profile.value = data;
    } finally {
      isLoading.value = false;
    }
  }


  Future<void> updateUserProfile({
    required String fullName,
    required String phone,
    required String address,
  }) async {
    try {
      isLoading.value = true;

      final token = AuthService.jwtToken;
      if (token == null) {
        throw Exception("Chưa đăng nhập");
      }

      // ✅ GỌI API TRƯỚC
      final updatedProfile = await UserApiService.updateMyProfile(
        token: token,
        fullName: fullName,
        phone: phone,
        address: address,
      );

      // ✅ CHỈ UPDATE STATE KHI API OK
      // profile.value = updatedProfile;
      // profile.refresh();
      await loadUserProfile();


      Get.snackbar(
        "Thành công",
        "Đã cập nhật địa chỉ nhận hàng",
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print("Update profile error: $e");

      Get.snackbar(
        "Lỗi",
        "Không thể cập nhật địa chỉ. Vui lòng thử lại",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }


}
