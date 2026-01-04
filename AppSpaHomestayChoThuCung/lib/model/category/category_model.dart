class Category {
  final int id;
  final String name;
  bool isDeleted;

  Category({
    required this.id,
    required this.name,
    this.isDeleted = false,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isDeleted': isDeleted,
    };
  }
}
