import 'package:flutter/material.dart';

class PaymentMethodSection extends StatelessWidget {
  const PaymentMethodSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Phương thức thanh toán",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.payments, color: Colors.pink),
              title: Text("Thanh toán khi nhận hàng (COD)"),
              trailing: Icon(Icons.check_circle, color: Colors.pink),
            ),
          ],
        ),
      ),
    );
  }
}
