import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:intl/intl.dart';

import '../../Controller/product_detail_controller.dart';

class ProductDetailPage extends StatelessWidget {
  final int productId;

  String formatPrice(num price) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(price)}đ';
  }

  ProductDetailPage({super.key, required this.productId}) {
    final controller = Get.put(ProductDetailController());
    controller.fetchDetail(productId);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProductDetailController>();

    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết sản phẩm")),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final p = controller.product.value!;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🖼 IMAGE SLIDER
              SizedBox(
                height: 300,
                child: PageView(
                  children: p.images.map((img) {
                    return Image.network(
                      'https://localhost:7051$img',
                      fit: BoxFit.cover,
                    );
                  }).toList(),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),

                    Text(p.trademark,
                        style: const TextStyle(color: Colors.grey)),

                    const SizedBox(height: 8),

                    Text(
                      formatPrice(p.priceReduced ?? p.price),
                      style: const TextStyle(
                          fontSize: 20,
                          color: Colors.pink,
                          fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 16),

                    // 🧩 OPTION GROUPS
                    for (final group in p.optionGroups) ...[
                      Text(group.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      Wrap(
                        spacing: 8,
                        children: group.values
                            .map((v) => ChoiceChip(
                          label: Text(v.value),
                          selected: false,
                        ))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              )
            ],
          ),
        );
      }),
    );
  }
}
