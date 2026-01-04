import 'package:flutter/material.dart';
import '../../model/Cart/cart_item_model.dart';
import '../../utils/price_utils.dart';

class ProductListSection extends StatelessWidget {
  final List<CartItem> items;

  const ProductListSection({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Danh sách sản phẩm",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...items.map(
              (i) => Card(
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'https://localhost:7051${i.imageUrl}',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                )
              ),
              title: Text(i.productName),
              subtitle: Text(i.variantName),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(formatPrice(i.price)),
                  Text("x${i.quantity}",
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
