import 'package:intl/intl.dart';

enum OrderStatus { pending, confirmed, cancelled }

OrderStatus parseStatus(String status) {
  final s = status.toLowerCase();
  if (s.contains('pending') || s.contains('choxacnhan')) return OrderStatus.pending;
  if (s.contains('confirmed') || s.contains('daxacnhan')) return OrderStatus.confirmed;
  if (s.contains('cancelled') || s.contains('dahuy')) return OrderStatus.cancelled;
  return OrderStatus.pending;
}

class OrderItem {
  final String name;
  final String option;
  final int quantity;
  final int price;
  final int discountedPrice;

  OrderItem({
    required this.name,
    required this.option,
    required this.quantity,
    required this.price,
    required this.discountedPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      // Hỗ trợ cả 'productName' (từ Detail) và 'name' (từ Admin List)
      name: (json['productName'] ?? json['name'] ?? '').toString(),
      // Hỗ trợ cả 'variantName' (từ Detail) và 'option' (từ Admin List)
      option: (json['variantName'] ?? json['option'] ?? '').toString(),
      quantity: (json['quantity'] ?? 0).toDouble().toInt(),
      price: (json['price'] ?? 0).toDouble().toInt(),
      discountedPrice: (json['discountedPrice'] ?? json['price'] ?? 0).toDouble().toInt(),
    );
  }
}

class Order {
  final int id;
  final DateTime orderDate;
  final int originalPrice;
  final int discount;
  final int totalPrice;
  final OrderStatus status;
  final String bankStatus;

  final String customerName; // Người nhận
  final String senderName;   // Người đặt
  final String phoneNumber;
  final String shippingAddress;
  final String paymentMethod;
  final String notes;

  final List<OrderItem> items;
  final String? promoCode;
  final int itemCount;

  Order({
    required this.id, required this.orderDate, required this.originalPrice,
    required this.discount, required this.totalPrice, required this.status,
    required this.bankStatus, required this.customerName, required this.senderName,
    required this.phoneNumber, required this.shippingAddress, required this.paymentMethod,
    required this.notes, required this.items, this.promoCode, required this.itemCount,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      // 1. Xử lý mảng sản phẩm (Hỗ trợ cả 'details' và 'items')
      var list = (json['details'] as List? ?? json['items'] as List? ?? []);
      List<OrderItem> parsedItems = list
          .map((i) => OrderItem.fromJson(i))
          .toList();

      // 2. Xử lý logic Giá gốc (Nếu API không trả originalPrice, tự tính bằng Total + Discount)
      int total = (json['totalPrice'] ?? 0).toDouble().toInt();
      int disc = (json['discount'] ?? 0).toDouble().toInt();
      int origin = json['originalPrice'] != null
          ? (json['originalPrice'] as num).toInt()
          : (total + disc);

      // 3. Xử lý Promo Code
      String? code = json['promoCode']?.toString();
      var promos = json['promotions'] as List? ?? [];
      if (code == null && promos.isNotEmpty) {
        code = promos[0]['promotionName']?.toString();
      }

      // 4. XỬ LÝ MÚI GIỜ (FIX TRIỆT ĐỂ)
      String dateStr = (json['orderDate'] ?? DateTime.now().toIso8601String()).toString();
      // Nếu server trả về thiếu chữ 'Z' (giờ UTC), ta thêm vào để .toLocal() cộng đúng 7 tiếng
      if (!dateStr.contains('Z') && !dateStr.contains('+')) {
        dateStr = '${dateStr}Z';
      }
      DateTime finalDate = DateTime.parse(dateStr).toLocal();

      return Order(
        id: (json['id'] ?? 0).toInt(),
        orderDate: finalDate,
        originalPrice: origin,
        discount: disc,
        totalPrice: total,
        status: parseStatus((json['status'] ?? 'pending').toString()),
        bankStatus: (json['bankStatus'] ?? 'ChuaThanhToan').toString(),

        // Người nhận (Luôn là customerName ngoài cùng)
        customerName: (json['customerName'] ?? '').toString(),

        // Người đặt (Lấy từ object customer, nếu không có thì dùng customerName)
        senderName: (json['senderName'] ?? json['customer']?['fullName'] ?? 'Khách lẻ').toString(),

        phoneNumber: (json['phoneNumber'] ?? '').toString(),
        shippingAddress: (json['shippingAddress'] ?? json['shippingAddress'] ??
            '').toString(),
        paymentMethod: (json['paymentMethod'] ?? '').toString(),
        notes: (json['notes'] ?? '').toString(),

        items: parsedItems,
        promoCode: code,
        itemCount: (json['itemCount'] ?? parsedItems.length).toInt(),
      );
    }
    catch (e, stack) {
      // HÀM BẮT LỖI: In ra console để biết lỗi tại đâu
      print("❌ Lỗi Parse Order ID ${json['id']}: $e");
      print("Chi tiết lỗi: $stack");
      rethrow;
    }
  }
}