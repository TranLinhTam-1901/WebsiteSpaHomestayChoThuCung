class PromotionModel {
  final int id;
  final String title;
  final String code;
  final String? shortDescription;
  final String? description;
  final double discount;
  final bool isPercent;
  final double? minOrderValue;
  final DateTime startDate;
  final DateTime endDate;
  final String? image;
  final int? maxUsagePerUser;
  final int userUsedCount;

  final int? maxUsage;
  final int? globalUsedCount;
  final bool? isPrivate;

  PromotionModel({
    required this.id,
    required this.title,
    required this.code,
    this.shortDescription,
    this.description,
    required this.discount,
    required this.isPercent,
    this.minOrderValue,
    required this.startDate,
    required this.endDate,
    this.image,
    this.maxUsagePerUser,
    required this.userUsedCount,
    this.maxUsage,
    this.globalUsedCount,
    this.isPrivate,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: json['id'],
      title: json['title'],
      code: json['code'],
      shortDescription: json['shortDescription'],
      description: json['description']?.toString(),
      discount: (json['discount'] as num).toDouble(),
      isPercent: json['isPercent'],
      minOrderValue: json['minOrderValue'] == null
          ? null
          : (json['minOrderValue'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      image: json['image'],
      maxUsagePerUser: json['maxUsagePerUser'] == null ? null : (json['maxUsagePerUser'] as num).toInt(),
      userUsedCount: (json['userUsedCount'] ?? 0) as int,

      maxUsage: json['maxUsage'] == null ? null : (json['maxUsage'] as num).toInt(),
      globalUsedCount: (json['globalUsedCount'] ?? 0) as int,
      isPrivate: (json['isPrivate'] ?? false) as bool,
    );
  }
}
