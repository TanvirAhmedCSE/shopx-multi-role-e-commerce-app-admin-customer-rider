import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProduct {
  final String id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String image;
  final List<String> images;
  final List<bool>
  imagesPng; // true = png (bg-removed): contain, false = jpg/jpeg: cover
  final double rating;
  final int ratingCount;

  AdminProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.image,
    required this.images,
    List<bool>? imagesPng,
    this.rating = 0.0,
    this.ratingCount = 0,
  }) : imagesPng = imagesPng ?? const [];

  Map<String, dynamic> toMap({bool isCreate = false}) => {
    'id': id,
    'title': title,
    'price': price,
    'description': description,
    'category': category,
    'image': image,
    'images': images,
    'imagesPng': imagesPng,
    'rating': rating,
    'ratingCount': ratingCount,
    if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory AdminProduct.fromMap(String docId, Map<String, dynamic> m) {
    final imgs =
        (m['images'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final imgsPng =
        (m['imagesPng'] as List?)?.map((e) => e as bool).toList() ?? [];
    return AdminProduct(
      id: docId,
      title: (m['title'] ?? '') as String,
      price: ((m['price'] ?? 0) as num).toDouble(),
      description: (m['description'] ?? '') as String,
      category: (m['category'] ?? '') as String,
      image: (m['image'] ?? (imgs.isNotEmpty ? imgs.first : '')) as String,
      images: imgs,
      imagesPng: imgsPng,
      rating: ((m['rating'] ?? 0.0) as num).toDouble(),
      ratingCount: ((m['ratingCount'] ?? 0) as num).toInt(),
    );
  }
}
