import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

import '../Api/product_api.dart';
import '../model/product/product_detail_model.dart';

class ProductDetailController extends GetxController {
  final _api = ProductApi();

  var isLoading = true.obs;
  var product = Rxn<ProductDetailModel>();

  Future<void> fetchDetail(int productId) async {
    try {
      isLoading.value = true;
      product.value = await _api.getProductDetail(productId);
    } finally {
      isLoading.value = false;
    }
  }
}
