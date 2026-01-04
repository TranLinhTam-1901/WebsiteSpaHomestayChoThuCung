import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Controller/cart_controller.dart';
import '../../widgets/VoucherBox.dart';
import '../../widgets/cart_item_card.dart';
import '../../widgets/cart_summary_box.dart';

class CartPage extends StatelessWidget {
  CartPage({super.key});

  final controller = Get.put(CartController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6),
      appBar: AppBar(
        title: const Text("Giỏ hàng của bạn"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Get.back(),
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.more_horiz),
        //     onPressed: () {},
        //   )
        // ],
      ),

      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final cart = controller.cart.value;

        if (cart == null || cart.items.isEmpty) {
          return const Center(child: Text("Giỏ hàng trống"));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...cart.items.map(
                  (item) => CartItemCard(item: item),
            ),

            // const SizedBox(height: 12),
            // const VoucherBox(),

            const SizedBox(height: 16),
            CartSummaryBox(cart: cart),


            const SizedBox(height: 80),
          ],
        );
      }),

      bottomNavigationBar: Container(

        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Obx(() => ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: controller.selectedItemIds.isEmpty
                ? Colors.grey
                : const Color(0xFFEE2B5B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: controller.selectedItemIds.isEmpty
              ? null
              : controller.goToCheckout,
          child: const Text(
            "Tiến hành Thanh toán",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        )),

      ),
    );
  }
}
