import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/product_model.dart';
import '../../data/services/hive_service.dart';
import '../../data/services/firebase_service.dart';
import 'package:flutter/material.dart';

class FavoritesController extends GetxController {
  final favorites = <ProductModel>[].obs;
  Box<ProductModel>? _favBox;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    final uid = _uid;
    if (uid != null && Hive.isBoxOpen('favorites_$uid')) {
      _favBox = HiveService.favBox(uid);
      favorites.assignAll(_favBox!.values.toList());
      _syncFromFirestore(uid);
    }
  }

  void reloadForUser(String uid) {
    _favBox = HiveService.favBox(uid);
    favorites.assignAll(_favBox!.values.toList());
    _syncFromFirestore(uid);
  }

  Future<void> _syncFromFirestore(String uid) async {
    try {
      final remote = await FirebaseService.fetchFavorites(uid);
      if (remote.isEmpty) return;
      await _favBox?.clear();
      for (final p in remote) {
        await _favBox?.add(p);
      }
      favorites.assignAll(_favBox!.values.toList());
    } catch (_) {}
  }

  void toggle(ProductModel product) {
    final uid = _uid;
    if (isFavorite(product.id)) {
      final key = _favBox?.keys.firstWhere(
        (k) => (_favBox!.get(k) as ProductModel).id == product.id,
      );
      _favBox?.delete(key);
      favorites.removeWhere((p) => p.id == product.id);
      if (uid != null) FirebaseService.removeFavorite(uid, product.id);
      Get.snackbar(
        'Removed from Favorites',
        product.title,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      );
    } else {
      final newProduct = ProductModel(
        id: product.id,
        title: product.title,
        price: product.price,
        description: product.description,
        category: product.category,
        image: product.image,
        rating: product.rating,
        ratingCount: product.ratingCount,
      );
      _favBox?.add(newProduct);
      favorites.add(newProduct);
      if (uid != null) FirebaseService.saveFavorite(uid, newProduct);
      Get.snackbar(
        'Added to Favorites',
        product.title,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      );
    }
    favorites.refresh();
  }

  bool isFavorite(String id) => favorites.any((p) => p.id == id);
}
