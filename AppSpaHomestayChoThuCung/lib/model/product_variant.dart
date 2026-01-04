class ProductVariant {
  final int id;
  final int stockQuantity;
  final Map<String, String> options;

  ProductVariant({
    required this.id,
    required this.stockQuantity,
    required this.options,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'],
      stockQuantity: json['stockQuantity'],
      options: Map<String, String>.from(json['options']),
    );
  }
}
