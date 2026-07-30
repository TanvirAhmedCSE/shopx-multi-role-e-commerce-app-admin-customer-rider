import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/delivery_order_model.dart';

class FirebaseService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static String? get currentUid => _auth.currentUser?.uid;
  static String? get currentEmail => _auth.currentUser?.email;

  //  Auth — login only, admin creates the account
  static Future<String?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user?.uid;
      if (uid != null) {
        final riderDoc = await _db.collection('riders').doc(uid).get();
        final blocked = riderDoc.data()?['blocked'] as bool? ?? false;
        if (blocked) {
          await _auth.signOut();
          return 'Your rider account has been blocked. Please contact support.';
        }
      }
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

  //  Rider Profile
  static Future<Map<String, dynamic>?> fetchRiderProfile(String uid) async {
    final doc = await _db.collection('riders').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  static Future<void> saveRiderProfile({
    required String uid,
    required String name,
    required String avatarPath,
    String? address,
    double? lat,
    double? lng,
  }) async {
    await _db.collection('riders').doc(uid).set({
      'name': name,
      'avatarPath': avatarPath,
      'address': address ?? '',
      'latitude': lat ?? 0.0,
      'longitude': lng ?? 0.0,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> saveRiderFcmToken(String uid, String token) async {
    await _db.collection('riders').doc(uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  //  Delivery Orders
  static Stream<List<DeliveryOrderModel>> pendingDeliveryOrdersStream() {
    return _db
        .collection('delivery_orders')
        .where('riderStatus', isEqualTo: RiderStatus.pending)
        .orderBy('placedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => DeliveryOrderModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  static Stream<DeliveryOrderModel?> riderActiveOrderStream(String riderId) {
    return _db
        .collection('delivery_orders')
        .where('riderId', isEqualTo: riderId)
        .where(
          'riderStatus',
          whereIn: [RiderStatus.confirmed, RiderStatus.outForDelivery],
        )
        .limit(1)
        .snapshots()
        .map(
          (snap) => snap.docs.isEmpty
              ? null
              : DeliveryOrderModel.fromMap(
                  snap.docs.first.id,
                  snap.docs.first.data(),
                ),
        );
  }

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

  static Future<bool> claimOrder({
    required String orderId,
    required String riderId,
    required String riderName,
  }) async {
    try {
      final ref = _db.collection('delivery_orders').doc(orderId);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) throw Exception('not_found');
        final data = snap.data()!;
        if (data['riderId'] != null) throw Exception('already_claimed');
        tx.update(ref, {
          'riderId': riderId,
          'riderName': riderName,
          'riderStatus': RiderStatus.confirmed,
        });
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> updateDeliveryStatus(
    String orderId,
    String status,
  ) async {
    final data = <String, dynamic>{'riderStatus': status};
    if (status == RiderStatus.delivered) {
      data['deliveredAt'] = FieldValue.serverTimestamp();
    }
    await _db.collection('delivery_orders').doc(orderId).update(data);
  }

  static Stream<List<DeliveryOrderModel>> riderDeliveredHistoryStream(
    String riderId,
  ) {
    return _db
        .collection('delivery_orders')
        .where('riderId', isEqualTo: riderId)
        .where('riderStatus', isEqualTo: RiderStatus.delivered)
        .orderBy('deliveredAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => DeliveryOrderModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  //  Rider Location
  static Future<void> updateRiderLocation(
    String riderId,
    double lat,
    double lng,
  ) async {
    await _db.collection('riders').doc(riderId).set({
      'latitude': lat,
      'longitude': lng,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Mirrors status into all_orders so the customer app sees updates
  static Future<void> appendOrderStatusLog(
    String orderId,
    String status,
    String message,
  ) async {
    await _db.collection('all_orders').doc(orderId).update({
      'statusHistory': FieldValue.arrayUnion([
        {'status': status, 'message': message, 'at': Timestamp.now()},
      ]),
    });
  }
}
