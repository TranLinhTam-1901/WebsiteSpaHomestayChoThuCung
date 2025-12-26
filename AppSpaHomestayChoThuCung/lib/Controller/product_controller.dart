import 'package:get/get.dart';
import '../Api/product_api.dart';
import '../model/product_model.dart';

class ProductController extends GetxController {
  final _api = ProductApi();

  var products = <ProductModel>[].obs;
  var isLoading = false.obs;


  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
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

}
