import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/user_controller.dart';
import '../controller/cart_controller.dart';
import '../pages/shopping_cart/shopping_cart_page.dart';

final CartController cartController =
Get.put(CartController(), permanent: true);

class PawHouseAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const PawHouseAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();
    return AppBar(
      backgroundColor: const Color(0xFFFFB6C1), // ✅ #FFF0F5
      elevation: 1,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Obx(() {
        final profile = userController.profile.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "PawHouse",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: 1,
              ),
            ),
            if (profile != null)
              Text(
                "Xin chào, ${profile.fullName}",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
          ],
        );
      }),

      actions: [
        IconButton(
          icon: const Icon(Icons.favorite_border, color: Colors.black),
          onPressed: () {},
        ),

        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () {
                Get.to(() => CartPage());
              },
            ),
            // Positioned(
            //   right: 6,
            //   top: 6,
            //   child: Obx(() {
            //     if (cartController.cartItems.isEmpty) {
            //       return const SizedBox.shrink();
            //     }
            //     return Container(
            //       padding: const EdgeInsets.all(4),
            //       decoration: BoxDecoration(
            //         color: Colors.red,
            //         borderRadius: BorderRadius.circular(10),
            //       ),
            //       child: Text(
            //         cartController.cartItems.length.toString(),
            //         style: const TextStyle(
            //           color: Colors.white,
            //           fontSize: 10,
            //         ),
            //       ),
            //     );
            //   }),
            // ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
