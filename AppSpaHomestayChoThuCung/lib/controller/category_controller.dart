import 'package:get/get.dart';

import '../model/category/category_model.dart';
import '../services/category_service.dart';

class CategoryController extends GetxController {
  var categories = <CategoryModel>[].obs;
  var selectedCategoryId = 0.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  void loadCategories() async {
    try {
      isLoading.value = true;
      final data = await CategoryService.getCategories();

      categories.assignAll([
        CategoryModel(id: 0, name: 'Tất cả'),
        ...data,
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  void selectCategory(int id) {
    selectedCategoryId.value = id;
  }
}
