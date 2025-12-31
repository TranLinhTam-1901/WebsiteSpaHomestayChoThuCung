class ReviewResponse {
  final double averageRating;
  final int totalReviews;
  final List<ReviewModel> reviews;

  ReviewResponse({
    required this.averageRating,
    required this.totalReviews,
    required this.reviews,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    return ReviewResponse(
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      reviews: (json['reviews'] as List)
          .map((e) => ReviewModel.fromJson(e))
          .toList(),
    );
  }
}

class ReviewModel {
  final int id;
  final int rating;
  final String comment;
  final String userName;
  final List<String> images;

  ReviewModel({
    required this.id,
    required this.rating,
    required this.comment,
    required this.userName,
    required this.images,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'],
      rating: json['rating'],
      comment: json['comment'] ?? '',
      userName: json['userName'] ?? 'Ẩn danh',
      images: List<String>.from(json['images'] ?? []),
    );
  }
}
