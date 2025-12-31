import 'package:get/get.dart';
import '../Api/product_api.dart';
import '../model/product_model.dart';

class ProductController extends GetxController {
  final _api = ProductApi();

  var products = <ProductModel>[].obs;
  var isLoading = false.obs;
  var selectedCategoryId = 0.obs; // 0 = tất cả



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

}