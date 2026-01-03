import 'package:baitap1/Controller/product_detail_controller.dart';
import 'package:get/get.dart';
import '../Api/product_api.dart';
import '../model/Cart/cart_item_model.dart';
import '../model/Cart/cart_response_model.dart';
import '../model/product_variant.dart';
import '../pages/shopping_cart/checkout_page.dart';
import '../services/cart_api_service.dart';
import 'checkout_controller.dart';

class CartController extends GetxController {
  final _api = CartApiService();

  var cart = Rxn<CartResponse>();
  var isLoading = false.obs;
  var selectedItemIds = <int>{}.obs;

  String variantDisplayName(Map<String, String> options) {
    if (options.isEmpty) return "Mặc định";
    return options.values.join(" - ");
  }

  double get selectedTotalAmount {
    final cartData = cart.value;
    if (cartData == null) return 0;

    return cartData.items
        .where((i) => selectedItemIds.contains(i.cartItemId))
        .fold(0, (sum, i) => sum + i.subtotal);
  }

  int get selectedTotalQuantity {
    final cartData = cart.value;
    if (cartData == null) return 0;

    return cartData.items
        .where((i) => selectedItemIds.contains(i.cartItemId))
        .fold(0, (sum, i) => sum + i.quantity);
  }

  final _productApi = ProductApi();


  void toggleSelect(int cartItemId) {
    if (selectedItemIds.contains(cartItemId)) {
      selectedItemIds.remove(cartItemId);
    } else {
      selectedItemIds.add(cartItemId);
    }
  }

  bool isSelected(int cartItemId) {
    return selectedItemIds.contains(cartItemId);
  }

  Future<bool> addToCart({
    required int productId,
    required int quantity,
    int? variantId,
  }) async {
    try {
      isLoading.value = true;

      await _api.addToCart(
        productId: productId,
        quantity: quantity,
        variantId: variantId,
      );

      await loadCart();
      return true;
      // Get.snackbar(
      //   "Thành công",
      //   "Đã thêm sản phẩm vào giỏ hàng",
      //   snackPosition: SnackPosition.BOTTOM,
      // );
    } catch (e) {
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadCart() async {
    isLoading.value = true;
    final data = await _api.getCart();
    cart.value = CartResponse.fromJson(data);
    isLoading.value = false;
  }

  Future<void> updateQty(int cartItemId, int qty) async {
    await _api.updateCart(cartItemId, qty);
    await loadCart();
  }

  Future<void> removeItem(int cartItemId) async {
    await _api.removeCart(cartItemId);
    await loadCart();
  }
  Future<void> buyNow({
    required int productId,
    required int quantity,
    int? variantId,
  }) async {
    try {
      isLoading.value = true;

      // 1️⃣ Gọi API BuyNow chỉ để CHECK
      await _api.buyNow(
        productId: productId,
        quantity: quantity,
        variantId: variantId,
      );
      final productController = Get.find<ProductDetailController>();

      // 2️⃣ LẤY DATA TỪ PRODUCT DETAIL ĐANG CÓ
      final product = productController.product.value!;
      final variant = variantId == null
          ? null
          : product.variants.firstWhereOrNull((v) => v.id == variantId);

      final price = product.price; // variant KHÔNG có priceOverride


      // 3️⃣ Điều hướng Checkout bằng CartItem CHUẨN
      Get.to(() => CheckoutPage(
        items: [
          CartItem(
            cartItemId: -1,
            productId: product.id,
            productName: product.name,
            imageUrl: product.images.isNotEmpty ? product.images.first : "",
            variantId: variant?.id,
            variantName: variant == null
                ? "Mặc định"
                : variant.options.values.join(" - "),
            price: price,
            quantity: quantity,
            stockAvailable: variant?.stockQuantity ?? product.stockQuantity,
            isOutOfStock: false,
            subtotal: price * quantity,
          )
        ],
      ),

      );
    } catch (e) {
      Get.snackbar(
        "Không thể mua ngay",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }




  void goToCheckout() {
    if (selectedItemIds.isEmpty) {
      Get.snackbar(
        "Chưa chọn sản phẩm",
        "Vui lòng chọn ít nhất 1 sản phẩm để thanh toán",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final selectedItems = cart.value!.items
        .where((i) => selectedItemIds.contains(i.cartItemId))
        .toList();



    Get.to(() => CheckoutPage(items: selectedItems));
  }

  @override
  void onInit() {
    loadCart();
    super.onInit();
  }
}
