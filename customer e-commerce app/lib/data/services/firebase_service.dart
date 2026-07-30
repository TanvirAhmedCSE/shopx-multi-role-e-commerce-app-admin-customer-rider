import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/delivery_order_model.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class FirebaseService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static String? get currentUid => _auth.currentUser?.uid;
  static String? get currentEmail => _auth.currentUser?.email;

  //  Auth
  static Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    }
  }

  static Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    }
  }

  static Future<void> signOut() => _auth.signOut();

  static Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    }
  }

  static String _authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }

  //  User Profile
  static Future<void> saveUserProfile({
    required String uid,
    required String name,
    required String avatarPath,
  }) async {
    await _db.collection('users').doc(uid).set({
      'name': name,
      'avatarPath': avatarPath,
      'email': currentEmail ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> fetchUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  static Future<void> syncEmail(String uid, String email) async {
    await _db.collection('users').doc(uid).set({
      'email': email,
    }, SetOptions(merge: true));
  }

  static Future<void> saveFcmToken(String uid, String token) async {
    await _db.collection('users').doc(uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  //  Customer Orders
  static Future<void> saveOrder(String uid, OrderModel order) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('orders')
        .doc(order.orderId)
        .set(order.toMap());
  }

  static Future<List<OrderModel>> fetchOrders(String uid) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('orders')
        .orderBy('placedAt', descending: true)
        .get();
    return snap.docs.map((d) => OrderModel.fromMap(d.data())).toList();
  }

  //  Order Status (admin-controlled mirror)
  static Future<void> saveAllOrder({
    required String uid,
    required OrderModel order,
    required String fcmToken,
  }) async {
    await _db.collection('all_orders').doc(order.orderId).set({
      'userId': uid,
      'fcmToken': fcmToken,
      'fullName': order.fullName,
      'address': order.address,
      'city': order.city,
      'zip': order.zip,
      'latitude': order.latitude,
      'longitude': order.longitude,
      'items': order.items.map((e) => e.toMap()).toList(),
      'subtotal': order.subtotal,
      'shippingCost': order.shippingCost,
      'total': order.total,
      'shippingLabel': order.shippingLabel,
      'shippingTime': order.shippingTime,
      'shippingType': order.shippingType,
      'placedAt': order.placedAt.toIso8601String(),
      'currentStatus': order.currentStatus,
      'availableForDelivery': false,
      'statusHistory': [
        {
          'status': DeliveryStatus.orderPlaced,
          'message': 'আপনার অর্ডারটি প্লেস করা হয়েছে',
          'at': Timestamp.now(),
        },
      ],
    });
  }

  static Stream<Map<String, dynamic>?> orderStatusStream(String orderId) {
    return _db
        .collection('all_orders')
        .doc(orderId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  //  Delivery Orders (Rider-managed, customer-side read only)
  static Future<void> saveDeliveryOrder(DeliveryOrderModel order) async {
    await _db
        .collection('delivery_orders')
        .doc(order.orderId)
        .set(order.toMap());
  }

  // User: exact delivery order — real-time
  static Stream<DeliveryOrderModel?> userDeliveryOrderStream(String orderId) {
    return _db
        .collection('delivery_orders')
        .doc(orderId)
        .snapshots()
        .map(
          (doc) => doc.exists
              ? DeliveryOrderModel.fromMap(doc.id, doc.data()!)
              : null,
        );
  }

  //  Rider Location (read-only stream for customer tracking)
  static Stream<Map<String, double>?> riderLocationStream(String riderId) {
    return _db.collection('riders').doc(riderId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final d = doc.data()!;
      return {
        'latitude': (d['latitude'] as num).toDouble(),
        'longitude': (d['longitude'] as num).toDouble(),
      };
    });
  }

  static Future<Map<String, dynamic>?> fetchRiderProfile(String uid) async {
    final doc = await _db.collection('riders').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  //  Cart (Firestore sync)
  static Future<void> saveCartItem(String uid, CartItem item) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('cart')
        .doc(item.productId)
        .set(item.toMap());
  }

  static Future<void> removeCartItem(String uid, String productId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('cart')
        .doc(productId)
        .delete();
  }

  static Future<void> clearCartFirestore(String uid) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('cart')
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  static Future<List<CartItem>> fetchCart(String uid) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('cart')
        .get();
    return snap.docs.map((d) => CartItem.fromMap(d.data())).toList();
  }

  //  Favorites (Firestore sync)
  static Future<void> saveFavorite(String uid, ProductModel product) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(product.id)
        .set(product.toMap());
  }

  static Future<void> removeFavorite(String uid, String productId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(productId)
        .delete();
  }

  static Future<List<ProductModel>> fetchFavorites(String uid) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .get();
    return snap.docs.map((d) => ProductModel.fromMap(d.id, d.data())).toList();
  }
}
