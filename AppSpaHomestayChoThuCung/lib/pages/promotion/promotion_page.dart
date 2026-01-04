import 'package:flutter/material.dart';
import 'promotion_banner_view.dart';
import 'promotion_voucher_view.dart';
import 'discounted_product_view.dart';

class PromotionPage extends StatelessWidget {
  const PromotionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: const [
        PromotionBannerView(),
        SizedBox(height: 16),
        PromotionVoucherView(),
        SizedBox(height: 16),
        DiscountedProductView(),
      ],
    );
  }
}
