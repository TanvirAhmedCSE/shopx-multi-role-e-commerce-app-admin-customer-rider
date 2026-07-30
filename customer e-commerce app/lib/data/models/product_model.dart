import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'product_model.g.dart';

@HiveType(typeId: 0)
class ProductModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double price;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final String category;

  @HiveField(5)
  final String image;

  @HiveField(6)
  final double rating;

  @HiveField(7)
  final int ratingCount;

  @HiveField(8)
  final List<String> images;

  @HiveField(9)
  final List<bool> imagesPng;

  ProductModel({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.image,
    required this.rating,
    required this.ratingCount,
    List<String>? images,
    List<bool>? imagesPng,
  }) : images = images ?? const [],
       imagesPng = imagesPng ?? const [];

  factory ProductModel.fromMap(String id, Map<String, dynamic> m) {
    final images =
        (m['images'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final imagesPng =
        (m['imagesPng'] as List?)?.map((e) => e as bool).toList() ?? [];
    return ProductModel(
      id: id,
      title: (m['title'] as String?) ?? '',
      price: (m['price'] as num?)?.toDouble() ?? 0.0,
      description: (m['description'] as String?) ?? '',
      category: (m['category'] as String?) ?? '',
      image: (m['image'] as String?) ?? (images.isNotEmpty ? images.first : ''),
      rating: (m['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (m['ratingCount'] as num?)?.toInt() ?? 0,
      images: images,
      imagesPng: imagesPng,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'price': price,
    'description': description,
    'category': category,
    'image': image,
    'images': images,
    'imagesPng': imagesPng,
    'rating': rating,
    'ratingCount': ratingCount,
  };

  List<String> get galleryImages => images.isNotEmpty ? images : [image];

  bool _fallbackIsPng(String url) =>
      url.toLowerCase().split('?').first.endsWith('.png');

  BoxFit fitFor(int galleryIndex) {
    if (galleryIndex < imagesPng.length) {
      return imagesPng[galleryIndex] ? BoxFit.contain : BoxFit.cover;
    }
    final url = galleryIndex < galleryImages.length
        ? galleryImages[galleryIndex]
        : image;
    return _fallbackIsPng(url) ? BoxFit.contain : BoxFit.cover;
  }

  BoxFit get mainFit => fitFor(0);
}
