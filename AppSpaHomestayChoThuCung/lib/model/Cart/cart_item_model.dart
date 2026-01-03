class CartItem {
  final int cartItemId;
  final int productId;
  final String productName;
  final String imageUrl;

  final int? variantId;
  final String variantName;

  final double price;
  int quantity;
  final int stockAvailable;
  final bool isOutOfStock;

  final double subtotal;

  CartItem({
    required this.cartItemId,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.variantName,
    required this.price,
    required this.quantity,
    required this.stockAvailable,
    required this.isOutOfStock,
    required this.subtotal,
    this.variantId,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      cartItemId: json['cartItemId'],
      productId: json['productId'],
      productName: json['productName'],
      imageUrl: json['imageUrl'],
      variantId: json['variantId'],
      variantName: json['variantName'],
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'],
      stockAvailable: json['stockAvailable'],
      isOutOfStock: json['isOutOfStock'],
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }
}
