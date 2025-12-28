class ServiceDetailModel {
  final int serviceDetailId;
  final int serviceId;
  final String name;
  final double price;
  final double? salePrice;

  ServiceDetailModel({
    required this.serviceDetailId,
    required this.serviceId,
    required this.name,
    required this.price,
    this.salePrice,
  });

  factory ServiceDetailModel.fromJson(Map<String, dynamic> json) {
    return ServiceDetailModel(
      serviceDetailId: json['serviceDetailId'],
      serviceId: json['serviceId'],
      name: json['name'],
      price: (json['price'] ?? 0).toDouble(),
      salePrice: json['salePrice']?.toDouble(),
    );
  }
}