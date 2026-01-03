import 'package:get/get.dart';
import '../Api/product_api.dart';
import '../model/product_model.dart';

class ProductController extends GetxController {
  final _api = ProductApi();

  var products = <ProductModel>[].obs;
  var isLoading = false.obs;
  var selectedCategoryId = 0.obs; // 0 = tất cả
  var activePromotionCode = RxnString();
  var activePromotionId = RxnInt(); // null = không lọc promo
  var isPromotionMode = false.obs;  // để UI biết đang lọc

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    print("🔥 PRODUCT CONTROLLER FILE LOADED");

    try {
      isLoading.value = true;

      final data = await _api.getProducts();
      print("Loaded ${data.length} products");

      products.assignAll(data);
    } catch (e, s) {
      print("❌ FETCH PRODUCTS ERROR: $e");
      print(s);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchByCategory(int categoryId) async {
    try {
      isLoading.value = true;
      selectedCategoryId.value = categoryId;

      final data = await _api.getProductsByCategory(categoryId);
      products.assignAll(data);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadProducts({int? categoryId}) async {
    try {
      isLoading.value = true;

      List<ProductModel> data;

      if (categoryId == null) {
        data = await _api.getProducts();
      } else {
        data = await _api.getProductsByCategory(categoryId);
      }

      products.assignAll(data);
    } catch (e) {
      print('❌ loadProducts error: $e');
      products.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchByPromotion(int promotionId, {String? promoCode,int? categoryId}) async {
    try {
      isLoading.value = true;

      activePromotionId.value = promotionId;
      isPromotionMode.value = true;
      activePromotionCode.value = promoCode;

      // giữ category hiện tại nếu bạn muốn
      if (categoryId != null) selectedCategoryId.value = categoryId;

      final data = await _api.getProductsByPromotion(
        promotionId,
        categoryId: categoryId ?? selectedCategoryId.value,
      );

      products.assignAll(data);
    } catch (e, s) {
      print("❌ FETCH PROMO PRODUCTS ERROR: $e");
      print(s);
      products.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> exitPromotionMode() async {
    activePromotionId.value = null;
    activePromotionCode.value = null;
    isPromotionMode.value = false;

    // quay về list theo category hiện tại
    await loadProducts(categoryId: selectedCategoryId.value == 0 ? null : selectedCategoryId.value);
  }

  Future<void> clearPromotionFilter() async {
    activePromotionId.value = null;
    isPromotionMode.value = false;

    // load lại theo category hiện tại (0 = all)
    if (selectedCategoryId.value == 0) {
      await fetchProducts();
    } else {
      await fetchByCategory(selectedCategoryId.value);
    }
  }


}