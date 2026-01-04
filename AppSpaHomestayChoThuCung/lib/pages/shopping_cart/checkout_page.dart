import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Controller/checkout_controller.dart';
import '../../model/Cart/cart_item_model.dart';

import '../../widgets/checkout/address_section.dart';
import '../../widgets/checkout/product_list_section.dart';
import '../../widgets/checkout/voucher_section.dart';
import '../../widgets/checkout/payment_method_section.dart';
import '../../widgets/checkout/payment_summary_section.dart';
import '../../widgets/checkout/bottom_checkout_bar.dart';

class CheckoutPage extends StatelessWidget {
  final List<CartItem> items;

  CheckoutPage({
    super.key,
    required this.items,
  }) {
    // ✅ CHỈ TẠO 1 LẦN DUY NHẤT
    if (!Get.isRegistered<CheckoutController>()) {
      Get.put(CheckoutController());
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CheckoutController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thanh toán"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AddressSection(),
                const SizedBox(height: 12),
                ProductListSection(items: items),
                const SizedBox(height: 12),
                VoucherSection(
                  controller: controller,
                  total: items.fold<double>(0, (s, i) => s + i.subtotal),
                ),

                const SizedBox(height: 12),
                const PaymentMethodSection(),
                const SizedBox(height: 12),
                PaymentSummarySection(
                  items: items,
                  controller: controller,
                ),

              ],
            ),
          ),
          BottomCheckoutBar(items: items),
        ],
      ),
    );
  }
}
