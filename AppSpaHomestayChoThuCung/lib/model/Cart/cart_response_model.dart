import 'cart_item_model.dart';

class CartResponse {
  final List<CartItem> items;
  final int totalQuantity;
  final double totalAmount;

  CartResponse({
    required this.items,
    required this.totalQuantity,
    required this.totalAmount,
  });

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    return CartResponse(
      items: (json['items'] as List)
          .map((e) => CartItem.fromJson(e))
          .toList(),
      totalQuantity: json['totalQuantity'],
      totalAmount: (json['totalAmount'] as num).toDouble(),
    );
  }
}
