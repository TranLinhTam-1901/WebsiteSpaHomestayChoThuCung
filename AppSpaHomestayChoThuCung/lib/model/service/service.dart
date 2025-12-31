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
      // 1. Map đúng theo Postman (ưu tiên chữ thường)
      serviceId: json['serviceId'] ?? json['ServiceId'] ?? 0,
      name: json['name'] ?? json['Name'] ?? 'Không tên',
      description: json['description'] ?? json['Description'] ?? '',

      // 2. Ép kiểu double an toàn cho giá tiền
      price: (json['price'] ?? json['Price'] ?? 0).toDouble(),

      // 3. Các trường có thể null
      salePrice: (json['salePrice'] ?? json['SalePrice'])?.toDouble(),
      image: json['image'] ?? json['Image'],

      // 4. Xử lý Category:
      // Vì API này chỉ trả về phòng Homestay, ta mặc định là Homestay
      // nếu API không trả về trường category.
      category: _parseCategory(json['category'] ?? json['Category']),

      spaPricing: (json['spaPricing'] ?? json['SpaPricing']) != null
          ? SpaPricingModel.fromJson(json['spaPricing'] ?? json['SpaPricing'])
          : null,
    );
  }

// Hàm phụ để parse category không bị lỗi crash app
  static ServiceCategory _parseCategory(dynamic val) {
    if (val == null) return ServiceCategory.Homestay; // Mặc định cho trang này
    if (val is int) {
      if (val >= 0 && val < ServiceCategory.values.length) {
        return ServiceCategory.values[val];
      }
    }
    return ServiceCategory.Homestay;
  }
}