import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Đảm bảo đã thêm get vào pubspec.yaml
import 'package:baitap1/controller/category_controller.dart';
import '../../model/category/category_model.dart';

class CategoryManagementScreen extends StatelessWidget {
  // Tìm Controller đã được khởi tạo (hoặc khởi tạo mới)
  final CategoryController controller = Get.put(CategoryController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý Danh Mục'),
        actions: [
          Obx(() => Row(
            children: [
              Text(controller.showHidden.value ? "Hiện mục ẩn" : "Ẩn mục ẩn",
                  style: TextStyle(fontSize: 12)),
              Switch(
                value: controller.showHidden.value,
                onChanged: (value) => controller.toggleShowHidden(),
                activeColor: Colors.green,
              ),
            ],
          )),
          // Nút để load lại dữ liệu thủ công nếu cần
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => controller.loadAllData(), // Gọi hàm của Admin
          )
        ],
      ),
      // Obx sẽ tự động vẽ lại UI khi các biến .obs trong controller thay đổi
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        // SỬA TẠI ĐÂY: Sử dụng getter adminCategories đã lọc từ Controller
        final displayList = controller.adminCategories;

        if (displayList.isEmpty) {
          return Center(child: Text("Không có danh mục nào"));
        }



        return ListView.builder(
          itemCount: displayList.length,
          itemBuilder: (context, index) {
            final category = displayList[index];
            return ListTile(
              title: Text(category.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nút Sửa
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      controller.prepareEdit(category); // Chuyển logic chuẩn bị sang controller
                      showEditCategoryDialog(context);
                    },
                  ),
                  // Nút Xóa
                  // IconButton(
                  //   icon: Icon(Icons.delete),
                  //   onPressed: () => controller.adminDeleteCategory(category.id),
                  // ),
                  // Nút Ẩn/Hiện
                  IconButton(
                    icon: Icon(category.isDeleted ? Icons.visibility_off : Icons.visibility),
                    color: category.isDeleted ? Colors.grey : Colors.blue,
                    onPressed: () => controller.adminToggleHideCategory(category),
                  ),
                ],
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddCategoryDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  // --- Các Dialog hiển thị (Chỉ giữ logic UI) ---

  void showAddCategoryDialog(BuildContext context) {
    final TextEditingController categoryController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thêm Danh Mục'),
        content: TextField(
          controller: categoryController,
          decoration: InputDecoration(labelText: 'Tên danh mục'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (categoryController.text.isNotEmpty) {
                controller.adminAddCategory(categoryController.text);
                Navigator.pop(context);
              }
            },
            child: Text('Thêm'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Hủy')),
        ],
      ),
    );
  }

  void showEditCategoryDialog(BuildContext context) {
    // Lấy tên đang sửa từ controller
    final TextEditingController categoryController =
    TextEditingController(text: controller.adminSelectedCategoryName.value);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chỉnh Sửa Danh Mục'),
        content: TextField(
          controller: categoryController,
          decoration: InputDecoration(labelText: 'Tên danh mục'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (categoryController.text.isNotEmpty) {
                controller.adminUpdateCategory(
                    controller.selectedCategoryId.value,
                    categoryController.text
                );
                Navigator.pop(context);
              }
            },
            child: Text('Cập Nhật'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Hủy')),
        ],
      ),
    );
  }
}