import 'package:get/get.dart';
import '../Api/promotion_api.dart';
import '../model/promotion/promotion_model.dart';

class PromotionController extends GetxController {
  var promotions = <PromotionModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPromotions();
  }

  Future<void> fetchPromotions() async {
    try {
      isLoading.value = true;
      promotions.value = await PromotionApi.getPromotions();
    } catch (e) {
      print("❌ Promotion error: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
