import 'package:flutter/material.dart';

class Product {
  final int id;
  final String name;
  final String imageUrl;
  final String trademark;
  final double price;
  final double? priceReduced;
  final double discountPercentage;
  bool isFavorite;

  Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.trademark,
    required this.price,
    this.priceReduced,
    this.discountPercentage = 0,
    this.isFavorite = false,
  });
}

class AllProductsPage extends StatefulWidget {
  final List<Product> products;

  const AllProductsPage({super.key, required this.products});

  @override
  State<AllProductsPage> createState() => _AllProductsPageState();
}

class _AllProductsPageState extends State<AllProductsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        title: const Text("🏪 Tất cả sản phẩm"),
        backgroundColor: Colors.pink,
      ),
      body: widget.products.isEmpty
          ? const Center(
        child: Text(
          "Không tìm thấy sản phẩm nào",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: widget.products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // mobile chuẩn
            childAspectRatio: 0.65,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            return _productCard(widget.products[index]);
          },
        ),
      ),
    );
  }

  Widget _productCard(Product p) {
    bool hasSale = p.priceReduced != null &&
        p.priceReduced! > 0 &&
        p.priceReduced! < p.price;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    print("Đi tới chi tiết ${p.id}");
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.network(
                      'https://localhost:7051${p.imageUrl}',
                      fit: BoxFit.cover,
                    )
                    ,
                  ),
                ),

                /// ❤️ FAVORITE
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      p.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: p.isFavorite ? Colors.red : Colors.pink,
                    ),
                    onPressed: () {
                      setState(() {
                        p.isFavorite = !p.isFavorite;
                      });

                      /// 👉 sau này gọi API ToggleFavorite ở đây
                    },
                  ),
                ),

                /// 🔥 DISCOUNT
                if (hasSale)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.pink,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${p.discountPercentage.toStringAsFixed(0)}%",
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Text(
                  p.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  "Thương hiệu: ${p.trademark}",
                  style: const TextStyle(
                      fontSize: 12, color: Colors.pink),
                ),
                const SizedBox(height: 6),

                /// 💰 PRICE
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: hasSale
                      ? Column(
                    children: [
                      Text(
                        "${p.priceReduced!.toStringAsFixed(0)}đ",
                        style: const TextStyle(
                            color: Colors.pink,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${p.price.toStringAsFixed(0)}đ",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  )
                      : Text(
                    "${p.price.toStringAsFixed(0)}đ",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.pink,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
