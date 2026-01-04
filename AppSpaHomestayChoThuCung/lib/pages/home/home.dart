import 'package:baitap1/pages/product/product_detail_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:baitap1/widgets/pawhouse_appbar.dart';
import 'package:baitap1/widgets/pawhouse_drawer.dart';
import 'package:baitap1/widgets/chat_floating.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:intl/intl.dart';
import '../../Api/auth_service.dart';
import '../../Controller/category_controller.dart';
import '../../Controller/product_controller.dart';
import '../../Controller/user_controller.dart';
import '../../auth_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kPrimaryPink = Color(0xFFFFB6C1);
const kBackgroundPink = Color(0xFFFFF0F5);

class Product {
  final int id;
  final String name;
  final String imageUrl;
  final String trademark;
  final int price;
  final int? priceReduced;
  final int? discountPercentage;

  Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.trademark,
    required this.price,
    this.priceReduced,
    this.discountPercentage,
  });
}

class HomeViewModel {
  List<Product> discountedProducts;
  List<Product> catProducts;
  List<Product> dogProducts;

  HomeViewModel({
    required this.discountedProducts,
    required this.catProducts,
    required this.dogProducts,
  });

  factory HomeViewModel.demo() {
    return HomeViewModel(
      discountedProducts: [
        Product(
          id: 1,
          name: "Royal Canin",
          imageUrl: "https://i.imgur.com/8w0YpQO.jpeg",
          trademark: "Royal Canin",
          price: 350000,
          priceReduced: 299000,
          discountPercentage: 15,
        ),
        Product(
          id: 2,
          name: "Pedigree",
          imageUrl: "https://i.imgur.com/Qk8jE1z.jpeg",
          trademark: "Pedigree",
          price: 250000,
          priceReduced: 199000,
          discountPercentage: 20,
        ),
      ],
      catProducts: [
        Product(
          id: 3,
          name: "Me-O",
          imageUrl: "https://i.imgur.com/lX9dY17.jpeg",
          trademark: "Me-O",
          price: 120000,
        ),
        Product(
          id: 4,
          name: "HomeCat",
          imageUrl: "https://i.imgur.com/uQGDDxk.jpeg",
          trademark: "HomeCat",
          price: 90000,
        ),
      ],
      dogProducts: [
        Product(
          id: 5,
          name: "SmartHeart",
          imageUrl: "https://i.imgur.com/sA0T7uB.jpeg",
          trademark: "SmartHeart",
          price: 180000,
        ),
        Product(
          id: 6,
          name: "JerHigh",
          imageUrl: "https://i.imgur.com/BHrg28t.jpeg",
          trademark: "JerHigh",
          price: 70000,
        ),
      ],
    );
  }
}

class HomePage extends StatefulWidget {
  final HomeViewModel model;
  const HomePage({super.key, required this.model});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String? avatarInitial;
  late final UserController userController;

  @override
  void initState() {
    super.initState();
    Get.put(ProductController());
    Get.put(CategoryController());
    userController = Get.find<UserController>();
    userController.loadProfile();
    // 2️⃣ Lấy tên đầu từ Firebase
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.displayName != null) {
      avatarInitial = user.displayName![0].toUpperCase();  // Lấy chữ cái đầu
    } else {
      avatarInitial = user?.email?[0].toUpperCase();  // Nếu không có displayName, lấy từ email
    }
  }

  /// Drawer selected screen
  Widget? _drawerScreen;

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Xóa hết isLoggedIn và jwt_token

    AuthService.jwtToken = null; // Xóa trên RAM
    Get.find<UserController>().profile.value = null; // Xóa profile

    Get.offAll(() => const AuthGate());
  }

  void _openDrawerScreen(Widget screen) {
    setState(() {
      _drawerScreen = screen;
    });
    Navigator.pop(context); // đóng Drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundPink,
      appBar: const PawHouseAppBar(),
      drawer: PawHouseDrawer(
        onTapItem: _drawerScreen != null
            ? (screen) => _openDrawerScreen(screen)
            : null,
        onLogout: _logout,
      ),
      floatingActionButton: ChatFloatingButton(),

      /// BODY
      body: _drawerScreen ??
          IndexedStack(
            index: _currentIndex,
            children: [
              _homeTab(),       // Footer Tab 1: Trang chủ
              _productTab(),    // Footer Tab 2: Sản phẩm
              _promotionTab(),  // Footer Tab 3: Khuyến mãi
            ],
          ),

      /// FOOTER
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: kPrimaryPink,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        selectedIconTheme: const IconThemeData(color: Colors.black),
        unselectedIconTheme: const IconThemeData(color: Colors.black54),
        selectedLabelStyle: const TextStyle(color: Colors.black),
        unselectedLabelStyle: const TextStyle(color: Colors.black54),
        onTap: (i) {
          setState(() {
            _currentIndex = i;
            _drawerScreen = null; // reset drawer screen khi quay lại footer tab
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Trang chủ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: "Sản phẩm",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: "Khuyến mãi",
          ),
        ],
      ),
    );
  }

  /// TAB HOME
  Widget _homeTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _banner(),
          _title("Sản phẩm cho Mèo"),
          _horizontalList(widget.model.catProducts),
          _title("Sản phẩm cho Chó"),
          _horizontalList(widget.model.dogProducts),
        ],
      ),
    );
  }
  /// TAP PRODUCT
  Widget _productTab() {
    final productController = Get.find<ProductController>();
    final categoryController = Get.find<CategoryController>();

    String formatPrice(num price) {
      final formatter = NumberFormat('#,###', 'vi_VN');
      return '${formatter.format(price)}đ';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔘 CATEGORY FILTER (scroll ngang)
        SizedBox(
          height: 46,
          child: Obx(() {
            if (categoryController.isLoading.value) {
              return const SizedBox(); // hoặc shimmer/loading nhỏ
            }

            final cats = categoryController.categories;

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cats.length,
              itemBuilder: (_, i) {
                final c = cats[i];
                final selected =
                    c.id == categoryController.selectedCategoryId.value;

                return _chip(
                  c.name,
                  selected: selected,
                  onTap: () {
                    categoryController.selectCategory(c.id);

                    productController.loadProducts(
                      categoryId: c.id == 0 ? null : c.id,
                    );
                  },
                );
              },
            );
          }),
        ),

        const SizedBox(height: 12),

        // 🏷 TITLE
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Sản phẩm nổi bật",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 📦 GRID PRODUCTS
        Expanded(
          child:Obx(() {
            if (productController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final list = productController.products;

            if (list.isEmpty) {
              return const Center(child: Text("Chưa có sản phẩm"));
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260, // mỗi card max ~260px
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,

              ),

              itemBuilder: (_, i) {
                final p = list[i];

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Get.to(() => ProductDetailPage(productId: p.id));
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 🖼 IMAGE + BADGE
                        Expanded(
                          child:Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),


                                 child: Container(
                                  color: Colors.white,
                                  padding: const EdgeInsets.all(12),
                                  alignment: Alignment.center,
                                  child: Image.network(
                                    'https://localhost:7051${p.imageUrl}',
                                    fit: BoxFit.cover, // ✅ không méo
                                    errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image_not_supported),
                                  ),
                                ),

                            ),

                            if (p.discountPercentage != null && p.discountPercentage! > 0)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "-${p.discountPercentage}%",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                          ],
                        ),
                        ),
                        // 📄 INFO
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(16),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min, // 🔥 QUAN TRỌNG
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.trademark,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              const SizedBox(height: 6),

                              if (p.priceReduced != null && p.priceReduced! < p.price)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      formatPrice(p.priceReduced!),
                                      style: const TextStyle(
                                        color: Colors.pink,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      formatPrice(p.price),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  formatPrice(p.price),
                                  style: const TextStyle(
                                    color: Colors.pink,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),



                      ],
                    ),
                  ),
                );
              },
            );
          }),
    )
      ],
    );
  }

  /// TAB PROMOTION
  Widget _promotionTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.model.discountedProducts.length,
      itemBuilder: (_, i) {
        final p = widget.model.discountedProducts[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Image.network(p.imageUrl, width: 60),
            title: Text(
              p.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Giảm ${p.discountPercentage}% • ${p.priceReduced}đ",
              style: const TextStyle(color: kPrimaryPink),
            ),
          ),
        );
      },
    );
  }

  /// UI COMPONENTS
  Widget _banner() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 180,
        autoPlay: true,
        viewportFraction: 1,
      ),
      items: [
        "assets/images/pro_service_1.webp",
        "assets/images/pro_service_2.webp",
        "assets/images/pro_service_3.webp",
        "assets/images/pro_service_4.webp",
        "assets/images/pro_service_5.webp",
        "assets/images/pro_service_6.webp",
      ].map((url) {
        return Image.network(url, fit: BoxFit.fill, width: double.infinity);
      }).toList(),
    );
  }

  Widget _horizontalList(List<Product> list) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        itemBuilder: (_, i) {
          final p = list[i];
          return Container(
            width: 150,
            margin: const EdgeInsets.only(left: 12),
            child: Column(
              children: [
                Expanded(
                  child: Image.network(p.imageUrl, fit: BoxFit.cover),
                ),
                const SizedBox(height: 6),
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _title(String text) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _chip(
      String text, {
        bool selected = false,
        VoidCallback? onTap,
      }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(text),
        selected: selected,
        onSelected: (_) => onTap?.call(),
        selectedColor: Colors.pink,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.grey[700],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
