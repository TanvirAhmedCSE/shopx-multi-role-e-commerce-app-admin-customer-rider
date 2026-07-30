import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/product_model.dart';
import '../../data/services/hive_service.dart';
import '../../data/services/firebase_service.dart';
import 'package:flutter/material.dart';

class CartController extends GetxController {
  final cartItems = <CartItem>[].obs;
  Box<CartItem>? _cartBox;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    final uid = _uid;
    if (uid != null && Hive.isBoxOpen('cart_$uid')) {
      _cartBox = HiveService.cartBox(uid);
      cartItems.assignAll(_cartBox!.values.toList());
      _syncFromFirestore(uid);
    }
  }

  void reloadForUser(String uid) {
    _cartBox = HiveService.cartBox(uid);
    cartItems.assignAll(_cartBox!.values.toList());
    _syncFromFirestore(uid);
  }

  Future<void> _syncFromFirestore(String uid) async {
    try {
      final remoteItems = await FirebaseService.fetchCart(uid);
      if (remoteItems.isEmpty) return;
      await _cartBox?.clear();
      for (final item in remoteItems) {
        await _cartBox?.add(item);
      }
      cartItems.assignAll(_cartBox!.values.toList());
    } catch (_) {}
  }

  void toggleCart(ProductModel product) {
    if (isInCart(product.id)) {
      removeFromCart(product.id);
      Get.snackbar(
        'Removed from Cart',
        product.title,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      );
    } else {
      final item = CartItem(
        productId: product.id,
        title: product.title,
        price: product.price,
        image: product.image,
      );
      _cartBox?.add(item);
      cartItems.add(item);
      cartItems.refresh();
      final uid = _uid;
      if (uid != null) FirebaseService.saveCartItem(uid, item);
      Get.snackbar(
        'Added to Cart',
        product.title,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      );
    }
  }

  void removeFromCart(String productId) {
    final item = cartItems.firstWhereOrNull((e) => e.productId == productId);
    if (item != null) {
      final key = _cartBox?.keys.firstWhere(
        (k) => _cartBox!.get(k)?.productId == productId,
        orElse: () => null,
      );
      if (key != null) _cartBox?.delete(key);
      cartItems.remove(item);
      final uid = _uid;
      if (uid != null) FirebaseService.removeCartItem(uid, productId);
    }
  }

  void increment(String productId) {
    final item = cartItems.firstWhereOrNull((e) => e.productId == productId);
    if (item != null) {
      item.quantity++;
      final key = _cartBox?.keys.firstWhere(
        (k) => _cartBox!.get(k)?.productId == productId,
        orElse: () => null,
      );
      if (key != null) _cartBox?.put(key, item);
      cartItems.refresh();
      final uid = _uid;
      if (uid != null) FirebaseService.saveCartItem(uid, item);
    }
  }

  void decrement(String productId) {
    final item = cartItems.firstWhereOrNull((e) => e.productId == productId);
    if (item != null) {
      if (item.quantity > 1) {
        item.quantity--;
        final key = _cartBox?.keys.firstWhere(
          (k) => _cartBox!.get(k)?.productId == productId,
          orElse: () => null,
        );
        if (key != null) _cartBox?.put(key, item);
        cartItems.refresh();
        final uid = _uid;
        if (uid != null) FirebaseService.saveCartItem(uid, item);
      } else {
        removeFromCart(productId);
      }
    }
  }

  void clearCart() {
    _cartBox?.clear();
    cartItems.clear();
    final uid = _uid;
    if (uid != null) FirebaseService.clearCartFirestore(uid);
  }

  bool isInCart(String productId) =>
      cartItems.any((e) => e.productId == productId);

  double get totalPrice =>
      cartItems.fold(0, (sum, e) => sum + (e.price * e.quantity));

  int get totalItems => cartItems.fold(0, (sum, e) => sum + e.quantity);
}
