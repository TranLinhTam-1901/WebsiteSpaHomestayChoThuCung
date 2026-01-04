class CategoryModel {
  final int id;
  final String name;
  final bool isDeleted;
  CategoryModel({
    required this.id,
    required this.name,
    required this.isDeleted,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      isDeleted: json['isDeleted'] ?? false,
    );
  }
}
