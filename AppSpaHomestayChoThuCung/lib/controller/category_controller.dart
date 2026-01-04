  import 'package:get/get.dart';
  import '../Api/category_api.dart';
  import '../model/category_model.dart';
  import '../services/category_service.dart';

  class CategoryController extends GetxController {
    // var categories = <CategoryModel>[].obs;
    var allCategoriesRaw = <CategoryModel>[].obs;
    var selectedCategoryId = 0.obs;
    var isLoading = false.obs;
    var adminSelectedCategoryName = "".obs;
    var showHidden = false.obs;
    void toggleShowHidden() => showHidden.value = !showHidden.value;
    @override
    void onInit() {
      super.onInit();
      loadAllData(); // Chỉ dùng một hàm load duy nhất để đồng bộ
    }


  // Getter này tự tạo ra danh sách cho User từ nguồn allCategoriesRaw
    List<CategoryModel> get userCategories {
      // 1. Luôn bắt đầu bằng mục "Tất cả"
      List<CategoryModel> listForUser = [
        CategoryModel(id: 0, name: 'Tất cả', isDeleted: false)
      ];

      // 2. Lọc các mục CHƯA BỊ ẨN (isDeleted == false) từ dữ liệu gốc
      final activeItems = allCategoriesRaw.where((c) => c.isDeleted == false);

      // 3. Nối chúng vào sau mục "Tất cả"
      listForUser.addAll(activeItems);

      return listForUser;
    }

    Future<void> loadAllData() async {
      try {
        isLoading.value = true;
        print("--- Đang gọi API lấy danh mục ---");
        List<Map<String, dynamic>> data = await CategoryApi.getCategories();
        print("Dữ liệu thô từ API: $data"); // Kiểm tra xem console có hiện gì không

        var list = data.map((e) => CategoryModel.fromJson(e)).toList();
        allCategoriesRaw.assignAll(list);

        print("Số lượng danh mục sau khi convert: ${allCategoriesRaw.length}");
      } catch (e) {
        print("Lỗi load data: $e");
      } finally {
        isLoading.value = false;
      }
    }

    // Getter này sẽ giúp lọc những gì hiển thị trên màn hình Admin
    // 2. DÀNH CHO ADMIN: Phải trả về TOÀN BỘ để Admin còn thấy mục ẩn mà "Hiện" lại
    List<CategoryModel> get adminCategories {
      if (showHidden.value) {
        // Nếu bật Switch: Hiện tất cả (cả true và false)
        return allCategoriesRaw.toList();
      } else {
        // Nếu tắt Switch: Chỉ hiện mục đang hoạt động (false)
        return allCategoriesRaw.where((c) => c.isDeleted == false).toList();
      }
    }

    Future<void> adminAddCategory(String name) async {
      try {
        await CategoryApi.addCategory(name: name, isDeleted: false);
        await loadAllData(); // Refresh lại danh sách
        Get.snackbar("Thành công", "Đã thêm danh mục $name");
      } catch (e) {
        Get.snackbar("Lỗi", "Không thể thêm danh mục");
      }
    }

    Future<void> adminUpdateCategory(int id, String name) async {
      try {
        await CategoryApi.updateCategory(id: id, name: name, isDeleted: false);
        await loadAllData();
        Get.snackbar("Thành công", "Đã cập nhật danh mục");
      } catch (e) {
        Get.snackbar("Lỗi", "Cập nhật thất bại");
      }
    }

    Future<void> adminToggleHideCategory(CategoryModel category) async {
      try {
        if (category.isDeleted) {
          await CategoryApi.showCategory(category.id);
        } else {
          await CategoryApi.hideCategory(category.id);
        }
        if (selectedCategoryId.value == category.id) {
          selectedCategoryId.value = 0; // Tự động nhảy về "Tất cả"
        }

        await loadAllData(); // Cập nhật lại cho Product Tab của User
      } catch (e) {
        Get.snackbar("Lỗi", "Thao tác thất bại");
      }
    }

    Future<void> adminDeleteCategory(int id) async {
      try {
        await CategoryApi.deleteCategory(id);
        await loadAllData();
        Get.snackbar("Thành công", "Đã xóa danh mục");
      } catch (e) {
        Get.snackbar("Lỗi", "Xóa thất bại");
      }
    }

    // Hàm chọn để sửa (để không lẫn với selectCategory hiển thị sản phẩm)
    void prepareEdit(CategoryModel category) {
      selectedCategoryId.value = category.id;
      adminSelectedCategoryName.value = category.name;
    }

    void selectCategory(int id) {
      selectedCategoryId.value = id;
    }
  }
