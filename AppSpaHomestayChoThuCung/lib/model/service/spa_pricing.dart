class SpaPricingModel {
  final int spaPricingId;
  final int serviceId;
  final double? priceUnder5kg;
  final double? price5To12kg;
  final double? price12To25kg;
  final double? priceOver25kg;

  SpaPricingModel({
    required this.spaPricingId,
    required this.serviceId,
    this.priceUnder5kg,
    this.price5To12kg,
    this.price12To25kg,
    this.priceOver25kg,
  });

  Map<String, dynamic> toJson() {
    return {
      'spaPricingId': spaPricingId,
      'serviceId': serviceId,
      'priceUnder5kg': priceUnder5kg,
      'price5To12kg': price5To12kg,
      'price12To25kg': price12To25kg,
      'priceOver25kg': priceOver25kg,
    };
  }

  factory SpaPricingModel.fromJson(Map<String, dynamic> json) {
    return SpaPricingModel(
      spaPricingId: json['spaPricingId'],
      serviceId: json['serviceId'],
      priceUnder5kg: json['priceUnder5kg']?.toDouble(),
      price5To12kg: json['price5To12kg']?.toDouble(),
      price12To25kg: json['price12To25kg']?.toDouble(),
      priceOver25kg: json['priceOver25kg']?.toDouble(),
    );
  }
}