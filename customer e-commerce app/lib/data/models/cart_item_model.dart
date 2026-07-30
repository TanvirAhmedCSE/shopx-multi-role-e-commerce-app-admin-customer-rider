import 'package:hive/hive.dart';

part 'cart_item_model.g.dart';

@HiveType(typeId: 1)
class CartItem extends HiveObject {
  @HiveField(0)
  final String productId;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double price;

  @HiveField(3)
  final String image;

  @HiveField(4)
  int quantity;

  CartItem({
    required this.productId,
    required this.title,
    required this.price,
    required this.image,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'title': title,
    'price': price,
    'image': image,
    'quantity': quantity,
  };

  factory CartItem.fromMap(Map<String, dynamic> m) => CartItem(
    productId: m['productId'] as String,
    title: m['title'] as String,
    price: (m['price'] as num).toDouble(),
    image: m['image'] as String,
    quantity: (m['quantity'] as num?)?.toInt() ?? 1,
  );
}
