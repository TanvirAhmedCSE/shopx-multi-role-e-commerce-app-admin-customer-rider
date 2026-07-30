class AdminOrderItem {
  final String title;
  final double price;
  final int quantity;
  final String image;

  AdminOrderItem({
    required this.title,
    required this.price,
    required this.quantity,
    required this.image,
  });

  factory AdminOrderItem.fromMap(Map<String, dynamic> m) => AdminOrderItem(
    title: m['title'] as String? ?? '',
    price: (m['price'] as num?)?.toDouble() ?? 0.0,
    quantity: (m['quantity'] as num?)?.toInt() ?? 1,
    image: m['image'] as String? ?? '',
  );
}

class AdminOrder {
  final String orderId;
  final String userId;
  final String fullName;
  final String address;
  final String city;
  final String zip;
  final double latitude;
  final double longitude;
  final List<AdminOrderItem> items;
  final double subtotal;
  final double shippingCost;
  final double total;
  final String shippingLabel;
  final String shippingTime;
  final String shippingType;
  final DateTime placedAt;
  final String currentStatus;
  final bool availableForDelivery;
  final String fcmToken;

  AdminOrder({
    required this.orderId,
    required this.userId,
    required this.fullName,
    required this.address,
    required this.city,
    required this.zip,
    required this.latitude,
    required this.longitude,
    required this.items,
    required this.subtotal,
    required this.shippingCost,
    required this.total,
    required this.shippingLabel,
    required this.shippingTime,
    required this.shippingType,
    required this.placedAt,
    required this.currentStatus,
    required this.availableForDelivery,
    required this.fcmToken,
  });

  bool get isHomeDelivery => shippingType == 'home_delivery';

  factory AdminOrder.fromMap(String id, Map<String, dynamic> m) {
    final itemsList = (m['items'] as List? ?? [])
        .map((e) => AdminOrderItem.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    return AdminOrder(
      orderId: id,
      userId: m['userId'] as String? ?? '',
      fullName: m['fullName'] as String? ?? '',
      address: m['address'] as String? ?? '',
      city: m['city'] as String? ?? '',
      zip: m['zip'] as String? ?? '',
      latitude: (m['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (m['longitude'] as num?)?.toDouble() ?? 0.0,
      items: itemsList,
      subtotal: (m['subtotal'] as num?)?.toDouble() ?? 0.0,
      shippingCost: (m['shippingCost'] as num?)?.toDouble() ?? 0.0,
      total: (m['total'] as num?)?.toDouble() ?? 0.0,
      shippingLabel: m['shippingLabel'] as String? ?? '',
      shippingTime: m['shippingTime'] as String? ?? '',
      shippingType: m['shippingType'] as String? ?? 'courier',
      placedAt:
          DateTime.tryParse(m['placedAt'] as String? ?? '') ?? DateTime.now(),
      currentStatus: m['currentStatus'] as String? ?? 'order_placed',
      availableForDelivery: m['availableForDelivery'] as bool? ?? false,
      fcmToken: m['fcmToken'] as String? ?? '',
    );
  }
}
