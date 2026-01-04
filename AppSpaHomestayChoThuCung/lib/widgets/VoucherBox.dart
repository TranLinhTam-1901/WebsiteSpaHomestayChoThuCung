import 'package:flutter/material.dart';

class VoucherBox extends StatelessWidget {
  const VoucherBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F1F1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.confirmation_number,
                  size: 18,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Mã giảm giá",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () {
              // TODO: mở màn chọn voucher
            },
            child: const Text(
              "Chọn mã ›",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFEE2B5B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
