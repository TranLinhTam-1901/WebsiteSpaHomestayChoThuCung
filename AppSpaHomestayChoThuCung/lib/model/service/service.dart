import 'service_detail.dart';
import 'spa_pricing.dart';

enum ServiceCategory { Spa, Homestay, Vet }

class ServiceModel {
  final int serviceId;
  final String name;
  final String? description;
  final double price;
  final double? salePrice;
  final String? image;
  final ServiceCategory category;

  // Quan hệ lồng nhau
  final SpaPricingModel? spaPricing;
  final List<ServiceDetailModel>? serviceDetails;

  ServiceModel({
    required this.serviceId,
    required this.name,
    this.description,
    required this.price,
    this.salePrice,
    this.image,
    required this.category,
    this.spaPricing,
    this.serviceDetails,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      serviceId: json['serviceId'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      salePrice: json['salePrice']?.toDouble(),
      image: json['image'],
      // Map string từ API về Enum
      category: ServiceCategory.values.firstWhere(
            (e) => e.toString().split('.').last == json['category'],
        orElse: () => ServiceCategory.Spa,
      ),
      spaPricing: json['spaPricing'] != null
          ? SpaPricingModel.fromJson(json['spaPricing'])
          : null,
      serviceDetails: json['serviceDetails'] != null
          ? (json['serviceDetails'] as List)
          .map((i) => ServiceDetailModel.fromJson(i))
          .toList()
          : null,
    );
  }
}