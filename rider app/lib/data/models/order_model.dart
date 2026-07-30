class OrderItem {
  final String title;
  final double price;
  final int quantity;
  final String image;

  OrderItem({
    required this.title,
    required this.price,
    required this.quantity,
    required this.image,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'price': price,
    'quantity': quantity,
    'image': image,
  };

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
    title: m['title'] as String,
    price: (m['price'] as num).toDouble(),
    quantity: m['quantity'] as int,
    image: m['image'] as String,
  );
}

class DeliveryStatus {
  static const orderPlaced = 'order_placed';
  static const confirmed = 'confirmed';
  static const pickedUp = 'picked_up';
  static const inTransit = 'in_transit';
  static const outForDelivery = 'out_for_delivery';
  static const delivered = 'delivered';
}
