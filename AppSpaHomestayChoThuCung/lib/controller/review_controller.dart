import 'package:get/get.dart';
import '../Api/review_api.dart';
import '../model/review_model.dart';

class ReviewController extends GetxController {
  var isLoading = false.obs;
  var averageRating = 0.0.obs;
  var totalReviews = 0.obs;
  var reviews = <ReviewModel>[].obs;

  Future<void> load(int productId) async {
    try {
      isLoading.value = true;
      final res = await ReviewApi.getReviews(productId);
      averageRating.value = res.averageRating;
      totalReviews.value = res.totalReviews;
      reviews.assignAll(res.reviews);
    } finally {
      isLoading.value = false;
    }
  }
}