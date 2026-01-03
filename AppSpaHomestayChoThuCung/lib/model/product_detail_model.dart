import 'package:baitap1/model/product_variant.dart';

class ProductDetailModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final double? priceReduced;
  final String trademark;
  final List<String> images;
  final List<OptionGroup> optionGroups;
  final int discountPercentage;
  final List<ProductVariant> variants;
  final int stockQuantity;



  ProductDetailModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.priceReduced,
    required this.trademark,
    required this.images,
    required this.optionGroups,
    required this.discountPercentage,
    required this.variants,
    required this.stockQuantity
  });

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    return ProductDetailModel(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      priceReduced: json['priceReduced'] == null
          ? null
          : (json['priceReduced'] as num).toDouble(),
      discountPercentage: json['discountPercentage'] ?? 0,
      trademark: json['trademark'],
      images: List<String>.from(json['images']),
      optionGroups: (json['optionGroups'] as List)
          .map((e) => OptionGroup.fromJson(e))
          .toList(),
      variants: (json['variants'] as List)
          .map((e) => ProductVariant.fromJson(e))
          .toList(),
      stockQuantity: (json['stockQuantity'] ?? 0) as int,
    );
  }

}

class OptionGroup {
  final int id;
  final String name;
  final List<OptionValue> values;

  OptionGroup({
    required this.id,
    required this.name,
    required this.values,
  });

  factory OptionGroup.fromJson(Map<String, dynamic> json) {
    return OptionGroup(
      id: json['id'],
      name: json['name'],
      values: (json['values'] as List)
          .map((e) => OptionValue.fromJson(e))
          .toList(),
    );
  }
}

class OptionValue {
  final int id;
  final String value;

  OptionValue({required this.id, required this.value});

  factory OptionValue.fromJson(Map<String, dynamic> json) {
    return OptionValue(
      id: json['id'],
      value: json['value'],
    );
  }
}
