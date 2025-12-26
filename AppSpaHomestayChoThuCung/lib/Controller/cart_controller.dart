import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// ================= MODEL =================
class CartItem {
  final int id;
  final String name;
  final String imageUrl;
  final double price;
  final double? priceReduced;
  int quantity;
  final String flavor;
  bool selected;

  CartItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.priceReduced,
    required this.quantity,
    required this.flavor,
    this.selected = true,
  });

  double get unitPrice =>
      (priceReduced != null && priceReduced! > 0) ? priceReduced! : price;

  double get total => unitPrice * quantity;
}

/// ================= CONTROLLER =================
class CartController extends GetxController {
  var cartItems = <CartItem>[].obs;

  @override
  void onInit() {
    super.onInit();

    /// DỮ LIỆU CỨNG
    cartItems.addAll([
      CartItem(
        id: 1,
        name: "Pate cho mèo Whiskas",
        imageUrl:
        "https://cdn-icons-png.flaticon.com/512/616/616408.png",
        price: 25000,
        priceReduced: 20000,
        quantity: 2,
        flavor: "Cá ngừ",
      ),
      CartItem(
        id: 2,
        name: "Hạt cho chó Pedigree",
        imageUrl:
        "https://cdn-icons-png.flaticon.com/512/616/616430.png",
        price: 150000,
        quantity: 1,
        flavor: "Gà nướng",
      ),
    ]);
  }

  bool get isAllSelected =>
      cartItems.isNotEmpty &&
          cartItems.every((e) => e.selected);

  double get totalSelected =>
      cartItems.where((e) => e.selected).fold(0, (s, e) => s + e.total);

  double get totalOverall =>
      cartItems.fold(0, (s, e) => s + e.total);

  void toggleAll(bool value) {
    for (var e in cartItems) {
      e.selected = value;
    }
    cartItems.refresh();
  }

  void updateQuantity(CartItem item, int qty) {
    if (qty < 1) return;
    item.quantity = qty;
    cartItems.refresh();
  }

  void removeItem(int id) {
    cartItems.removeWhere((e) => e.id == id);
  }
}
