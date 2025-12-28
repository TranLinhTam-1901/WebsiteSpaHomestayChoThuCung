enum OrderStatus { pending, confirmed, cancelled }

OrderStatus parseStatus(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
    case 'choxacnhan': // backend trả "ChoXacNhan"
      return OrderStatus.pending;
    case 'confirmed':
    case 'daxacnhan': // backend trả "DaXacNhan"
      return OrderStatus.confirmed;
    case 'cancelled':
    case 'dahuy': // backend trả "DaHuy"
      return OrderStatus.cancelled;
    default:
      return OrderStatus.pending;
  }
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

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    name: json['name'] ?? '',
    option: json['option'] ?? '',
    quantity: (json['quantity'] ?? 0).toInt(),
    price: (json['price'] ?? 0).toInt(),
    discountedPrice: (json['discountedPrice'] ?? 0).toInt(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'option': option,
    'quantity': quantity,
    'price': price,
    'discountedPrice': discountedPrice,
  };
}

class Order {
  final int id;
  final DateTime orderDate;
  final String customerName;
  final String phoneNumber;
  final String shippingAddress;
  final String paymentMethod;
  final String notes;
  final OrderStatus status;
  final int totalPrice;
  final int discount;
  final String? promoCode;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.orderDate,
    required this.customerName,
    required this.phoneNumber,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.notes,
    required this.status,
    required this.totalPrice,
    required this.discount,
    this.promoCode,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: (json['id'] ?? 0).toInt(),
    orderDate: DateTime.parse(json['orderDate'] ?? DateTime.now().toIso8601String()),
    customerName: json['customerName'] ?? '',
    phoneNumber: json['phoneNumber'] ?? '',
    shippingAddress: json['shippingAddress'] ?? '',
    paymentMethod: json['paymentMethod'] ?? '',
    notes: json['notes'] ?? '',
    status: parseStatus(json['status'] ?? 'pending'),
    totalPrice: (json['totalPrice'] ?? 0).toInt(),
    discount: (json['discount'] ?? 0).toInt(),
    promoCode: json['promoCode'],
    items: (json['items'] as List<dynamic>?)
        ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
        .toList() ??
        [],
  );
}
