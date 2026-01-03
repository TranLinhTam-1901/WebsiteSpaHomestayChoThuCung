import 'package:get/get_navigation/src/root/parse_route.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

import '../Api/product_api.dart';

import '../model/product/product_detail_model.dart';

import '../model/product_variant.dart';


class ProductDetailController extends GetxController {
  final _api = ProductApi();

  var isLoading = true.obs;
  var product = Rxn<ProductDetailModel>();
  var currentImageIndex = 0.obs;
  var selectedOptions = <String, String>{}.obs;
  Rxn<ProductVariant> selectedVariant = Rxn<ProductVariant>();
  var quantity = 1.obs;


  /// ➖ giảm số lượng
  void decreaseQty() {
    if (quantity.value > 1) {
      quantity.value--;
    }
  }

  /// ➕ tăng số lượng (có kiểm tra tồn kho)
  void increaseQty(int maxStock) {
    if (quantity.value < maxStock) {
      quantity.value++;
    }
  }

  /// 🔄 reset khi đổi biến thể / load lại
  void resetQty() {
    quantity.value = 1;
  }
  String stockText(int stock) {
    if (stock <= 0) return "Hết hàng";
    if (stock <= 5) return "Còn $stock sản phẩm";
    return "Còn hàng";
  }
  void updateSelectedVariant() {
    final p = product.value;
    if (p == null) return;

    // 🔥 CHƯA CHỌN ĐỦ OPTION GROUP → KHÔNG MATCH
    if (selectedOptions.length != p.optionGroups.length) {
      selectedVariant.value = null;
      return;
    }

    final match = p.variants.firstWhereOrNull((v) {
      return p.optionGroups.every((group) {
        final selectedValue = selectedOptions[group.name];
        return v.options[group.name] == selectedValue;
      });
    });

    selectedVariant.value = match;
  }


  void selectOption(String group, String value) {
    selectedOptions[group] = value;
    updateSelectedVariant();
  }
  Future<void> fetchDetail(int productId) async {
    try {
      isLoading.value = true;
      product.value = await _api.getProductDetail(productId);
    } finally {
      isLoading.value = false;
    }
  }
}
