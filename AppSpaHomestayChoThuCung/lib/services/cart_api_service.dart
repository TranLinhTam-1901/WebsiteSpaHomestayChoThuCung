import '../Api/cart_api.dart';

class CartApiService {
  /// GET CART
  Future<Map<String, dynamic>> getCart() async {
    return await CartApi.getCart();
  }


  Future<void> addToCart({
    required int productId,
    required int quantity,
    int? variantId,
  }) async {
    await CartApi.addToCart(
      productId: productId,
      quantity: quantity,
      variantId: variantId,
    );
  }

  /// UPDATE CART
  Future<void> updateCart(int cartItemId, int quantity) async {
    await CartApi.updateCart(
      cartItemId: cartItemId,
      quantity: quantity,
    );
  }

  /// REMOVE CART ITEM
  Future<void> removeCart(int cartItemId) async {
    await CartApi.removeCartItem(cartItemId);
  }

  Future<Map<String, dynamic>> buyNow({
    required int productId,
    required int quantity,
    int? variantId,
  }) async {
    return await CartApi.buyNow(
      productId: productId,
      quantity: quantity,
      variantId: variantId,
    );
  }

}
