import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Controller/checkout_controller.dart';
import '../../Controller/promotion_controller.dart';
import '../../model/promotion_model.dart';
import '../../utils/price_utils.dart';

class VoucherSection extends StatelessWidget {
  final CheckoutController controller;
  final double total;

  const VoucherSection({
    super.key,
    required this.controller,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final promoController = Get.find<PromotionController>();

    return Obx(() {
      final selected = controller.selectedPromotion.value;

      return Card(
        child: ListTile(
          leading: const Icon(Icons.confirmation_number, color: Colors.orange),
          title: const Text("Mã giảm giá"),
          subtitle: selected == null
              ? const Text("Chọn voucher để áp dụng")
              : Text("Đã chọn: ${selected.code}"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openVoucherModal(
            context: context,
            promotions: promoController.promotions,
          ),
        ),
      );
    });
  }

  void _openVoucherModal({
    required BuildContext context,
    required List<PromotionModel> promotions,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF6F6F6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.78,
            child: Column(
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Chọn mã giảm giá",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                ),

                // LIST VOUCHERS (không ảnh)
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: promotions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final p = promotions[i];
                      final state = _calcState(p, total);

                      final selectedId = controller.selectedPromotion.value?.id;

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: state.isEligible
                            ? () {
                          controller.setPromotion(p);
                          Navigator.pop(context); // chọn xong đóng modal
                        }
                            : null,
                        child: Opacity(
                          opacity: state.isEligible ? 1.0 : 0.45,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: (selectedId == p.id)
                                    ? Colors.pink
                                    : Colors.black12,
                                width: (selectedId == p.id) ? 1.4 : 1.0,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Badge giảm
                                Container(
                                  width: 56,
                                  height: 56,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.pink.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    p.isPercent
                                        ? "${p.discount.toInt()}%"
                                        : "${(p.discount ~/ 1000)}K",
                                    style: const TextStyle(
                                      color: Colors.pink,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        p.shortDescription ?? p.code,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 6),

                                      if (!state.isEligible)
                                        Text(
                                          state.reason,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        )
                                      else
                                        Text(
                                          "Đơn hiện tại: ${formatPrice(total)}",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                Radio<int>(
                                  value: p.id,
                                  groupValue:
                                  controller.selectedPromotion.value?.id,
                                  onChanged: state.isEligible
                                      ? (_) {
                                    controller.setPromotion(p);
                                    Navigator.pop(context);
                                  }
                                      : null,
                                  activeColor: Colors.pink,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // FOOTER: nút bỏ chọn
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            controller.clearPromotion();
                            Navigator.pop(context);
                          },
                          child: const Text("Bỏ chọn mã"),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  _VoucherState _calcState(PromotionModel p, double total) {
    // 1) Min order
    if (p.minOrderValue != null && total < p.minOrderValue!) {
      return _VoucherState(
        false,
        "Chưa đạt đơn tối thiểu ${formatPrice(p.minOrderValue!)}",
      );
    }

    // 2) Per-user usage
    if (p.maxUsagePerUser != null && p.userUsedCount >= p.maxUsagePerUser!) {
      return _VoucherState(false, "Bạn đã dùng hết lượt của mã này");
    }

    // 3) Global usage (optional)
    if (p.maxUsage != null &&
        p.globalUsedCount != null &&
        p.globalUsedCount! >= p.maxUsage!) {
      return _VoucherState(false, "Mã đã hết lượt sử dụng");
    }

    return _VoucherState(true, "");
  }
}

class _VoucherState {
  final bool isEligible;
  final String reason;
  _VoucherState(this.isEligible, this.reason);
}
