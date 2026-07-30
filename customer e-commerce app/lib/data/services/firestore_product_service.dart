import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class FirestoreProductService {
  static final _db = FirebaseFirestore.instance;

  static Stream<List<ProductModel>> productsStream() {
    return _db
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ProductModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  static Stream<List<String>> categoriesStream() {
    return _db
        .collection('categories')
        .orderBy('name')
        .snapshots()
        .map(
          (snap) => [
            'all',
            ...snap.docs.map((d) => d.data()['name'] as String),
          ],
        );
  }

  static Stream<ProductModel?> productStream(String id) {
    return _db
        .collection('products')
        .doc(id)
        .snapshots()
        .map(
          (doc) =>
              doc.exists ? ProductModel.fromMap(doc.id, doc.data()!) : null,
        );
  }

  static Stream<int?> userRatingStream(String productId, String uid) {
    return _db
        .collection('products')
        .doc(productId)
        .collection('ratings')
        .doc(uid)
        .snapshots()
        .map(
          (doc) => doc.exists ? (doc.data()?['rating'] as num?)?.toInt() : null,
        );
  }

  static Future<void> rateProduct({
    required String productId,
    required String uid,
    required int stars,
  }) async {
    final productRef = _db.collection('products').doc(productId);
    final ratingRef = productRef.collection('ratings').doc(uid);

    await _db.runTransaction((tx) async {
      final ratingSnap = await tx.get(ratingRef);
      final productSnap = await tx.get(productRef);
      if (!productSnap.exists) throw Exception('product_not_found');

      final data = productSnap.data() as Map<String, dynamic>;
      final currentAvg = (data['rating'] as num?)?.toDouble() ?? 0.0;
      final currentCount = (data['ratingCount'] as num?)?.toInt() ?? 0;

      double newAvg;
      int newCount;

      if (ratingSnap.exists) {
        final oldStars = ((ratingSnap.data()?['rating'] as num?) ?? 0)
            .toDouble();
        newCount = currentCount;
        newAvg = newCount == 0
            ? stars.toDouble()
            : (currentAvg * currentCount - oldStars + stars) / newCount;
      } else {
        newCount = currentCount + 1;
        newAvg = (currentAvg * currentCount + stars) / newCount;
      }

      tx.set(ratingRef, {
        'rating': stars,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.update(productRef, {'rating': newAvg, 'ratingCount': newCount});
    });
  }
}
