import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../data/services/firestore_product_service.dart';

class ProductRatingController extends GetxController {
  final String productId;
  ProductRatingController(this.productId);

  final avgRating = 0.0.obs;
  final ratingCount = 0.obs;
  final userRating = 0.obs; // 0 = hasn't rated yet
  final isSubmitting = false.obs;

  StreamSubscription? _productSub;
  StreamSubscription? _userRatingSub;

  @override
  void onInit() {
    super.onInit();
    _productSub = FirestoreProductService.productStream(productId).listen((p) {
      if (p != null) {
        avgRating.value = p.rating;
        ratingCount.value = p.ratingCount;
      }
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _userRatingSub = FirestoreProductService.userRatingStream(productId, uid)
          .listen((r) {
            userRating.value = r ?? 0;
          });
    }
  }

  Future<void> submitRating(int stars) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || isSubmitting.value || stars < 1) return;

    isSubmitting(true);
    try {
      await FirestoreProductService.rateProduct(
        productId: productId,
        uid: uid,
        stars: stars,
      );
    } catch (_) {
      Get.snackbar(
        'Error',
        'Rating দেওয়া যায়নি, আবার চেষ্টা করো।',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isSubmitting(false);
    }
  }

  @override
  void onClose() {
    _productSub?.cancel();
    _userRatingSub?.cancel();
    super.onClose();
  }
}
