class ProductModel {
  final int id;
  final String name;
  final String imageUrl;
  final String trademark;
  final double price;
  final double? priceReduced;
  final double discountPercentage;

  ProductModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.trademark,
    required this.price,
    this.priceReduced,
    required this.discountPercentage,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      imageUrl: json['imageUrl'],
      trademark: json['trademark'] ?? '',
      price: (json['price'] as num).toDouble(),
      priceReduced: json['priceReduced'] != null
          ? (json['priceReduced'] as num).toDouble()
          : null,
      discountPercentage:
      (json['discountPercentage'] as num).toDouble(),
    );
  }
}
