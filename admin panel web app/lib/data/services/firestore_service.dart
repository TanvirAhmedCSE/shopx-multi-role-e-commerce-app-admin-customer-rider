import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_product_model.dart';
import '../models/chat_summary_model.dart';
import '../models/admin_order_model.dart';
import '../models/rider_status.dart';
import '../models/rider_info_model.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;
  static final _products = _db.collection('products');
  static final _categories = _db.collection('categories');

  //  Products
  static Stream<List<AdminProduct>> productsStream() {
    return _products
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AdminProduct.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  static Future<bool> idExists(String id) async {
    final doc = await _products.doc(id).get();
    return doc.exists;
  }

  static Future<void> createProduct(AdminProduct product) async {
    await _products.doc(product.id).set(product.toMap(isCreate: true));
  }

  static Future<void> updateProduct(AdminProduct product) async {
    await _products.doc(product.id).update(product.toMap());
  }

  static Future<void> deleteProduct(String id) async {
    await _products.doc(id).delete();
  }

  //  Categories
  static Stream<List<String>> categoriesStream() {
    return _categories
        .orderBy('name')
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => d.data()['name'] as String).toList(),
        );
  }

  static Future<bool> addCategory(String name) async {
    final id = name.trim().toLowerCase();
    if (id.isEmpty) return false;
    final doc = _categories.doc(id);
    final existing = await doc.get();
    if (existing.exists) return false;
    await doc.set({
      'name': name.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  static Future<void> deleteCategory(String name) async {
    await _categories.doc(name.trim().toLowerCase()).delete();
  }

  static Future<void> updateCategory({
    required String oldRaw,
    required String newName,
    required String newIcon,
  }) async {
    final newCombined = '${newName.trim()}-${newIcon.trim()}';
    final oldId = oldRaw.trim().toLowerCase();
    final newId = newCombined.trim().toLowerCase();

    if (oldId == newId) {
      await _categories.doc(oldId).set({
        'name': newCombined,
      }, SetOptions(merge: true));
      return;
    }

    final clash = await _categories.doc(newId).get();
    if (clash.exists) {
      throw Exception('This category already exists');
    }

    final batch = _db.batch();
    batch.set(_categories.doc(newId), {
      'name': newCombined,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.delete(_categories.doc(oldId));

    final affected = await _products.where('category', isEqualTo: oldRaw).get();
    for (final doc in affected.docs) {
      batch.update(doc.reference, {'category': newCombined});
    }

    await batch.commit();
  }

  //  Support Chat
  static Stream<List<ChatSummary>> chatConversationsStream() {
    return _db
        .collection('support_chat')
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) {
                final data = d.data();
                final ts = data['lastMessageAt'] as Timestamp?;
                return ChatSummary(
                  uid: d.id,
                  lastMessage: (data['lastMessage'] ?? '') as String,
                  lastMessageType:
                      (data['lastMessageType'] ?? 'text') as String,
                  lastTime: ts?.toDate(),
                  messageCount: (data['messageCount'] as num?)?.toInt() ?? 0,
                  unreadForAdmin:
                      (data['unreadForAdmin'] as num?)?.toInt() ?? 0,
                );
              })
              .where((c) => c.messageCount > 1)
              .toList(),
        );
  }

  static Stream<QuerySnapshot> chatMessagesStream(String uid) {
    return _db
        .collection('support_chat')
        .doc(uid)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  static Future<void> sendChatReply(String uid, String text) async {
    final ref = _db.collection('support_chat').doc(uid);
    await ref.collection('messages').add({
      'text': text,
      'sender': 'employee',
      'timestamp': FieldValue.serverTimestamp(),
    });
    await ref.set({
      'lastMessage': text,
      'lastMessageType': 'text',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'messageCount': FieldValue.increment(1),
      'unreadForUser': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  static Future<void> markConversationRead(String uid) async {
    await _db.collection('support_chat').doc(uid).set({
      'unreadForAdmin': 0,
    }, SetOptions(merge: true));
  }

  static Future<void> sendChatImages(String uid, List<String> imageUrls) async {
    final ref = _db.collection('support_chat').doc(uid);
    await ref.collection('messages').add({
      'type': 'image',
      'imageUrls': imageUrls,
      'sender': 'employee',
      'timestamp': FieldValue.serverTimestamp(),
    });
    await ref.set({
      'lastMessage': imageUrls.length > 1
          ? '${imageUrls.length} photos'
          : 'Photo',
      'lastMessageType': 'image',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'messageCount': FieldValue.increment(1),
      'unreadForUser': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  static Future<String> fetchCustomerName(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    final name = doc.data()?['name'] as String?;
    return (name == null || name.trim().isEmpty) ? 'Customer' : name;
  }

  //  Order History
  static Stream<List<AdminOrder>> allOrdersStream() {
    return _db
        .collection('all_orders')
        .orderBy('placedAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => AdminOrder.fromMap(d.id, d.data())).toList(),
        );
  }

  static Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    required String message,
  }) async {
    await _db.collection('all_orders').doc(orderId).update({
      'currentStatus': status,
      'statusHistory': FieldValue.arrayUnion([
        {'status': status, 'message': message, 'at': Timestamp.now()},
      ]),
    });
  }

  static Future<void> markAvailableForDelivery(AdminOrder order) async {
    await _db.collection('all_orders').doc(order.orderId).update({
      'availableForDelivery': true,
    });
    await _db.collection('delivery_orders').doc(order.orderId).set({
      'userId': order.userId,
      'userFcmToken': order.fcmToken,
      'fullName': order.fullName,
      'address': order.address,
      'city': order.city,
      'latitude': order.latitude,
      'longitude': order.longitude,
      'items': order.items
          .map(
            (e) => {
              'title': e.title,
              'price': e.price,
              'quantity': e.quantity,
              'image': e.image,
            },
          )
          .toList(),
      'total': order.total,
      'placedAt': order.placedAt.toIso8601String(),
      'riderStatus': 'pending',
    });
  }

  static Future<AdminOrder?> fetchOrderById(String orderId) async {
    final doc = await _db.collection('all_orders').doc(orderId).get();
    if (!doc.exists) return null;
    return AdminOrder.fromMap(doc.id, doc.data()!);
  }

  //  Rider Status (for admin tracking)
  static Stream<Map<String, String>> riderStatusesStream() {
    return _db
        .collection('delivery_orders')
        .snapshots()
        .map(
          (snap) => {
            for (final d in snap.docs)
              d.id: (d.data()['riderStatus'] as String?) ?? RiderStatus.pending,
          },
        );
  }

  static Stream<Map<String, int>> riderDeliveredCountsStream() {
    return _db
        .collection('delivery_orders')
        .where('riderStatus', isEqualTo: RiderStatus.delivered)
        .snapshots()
        .map((snap) {
          final counts = <String, int>{};
          for (final d in snap.docs) {
            final riderId = d.data()['riderId'] as String?;
            if (riderId == null) continue;
            counts[riderId] = (counts[riderId] ?? 0) + 1;
          }
          return counts;
        });
  }

  //  Customers
  static Stream<int> customersCountStream() {
    return _db
        .collection('users')
        .where('userType', isEqualTo: 'customer')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  //  Riders
  static Stream<List<RiderInfo>> ridersStream() {
    return _db
        .collection('riders')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => RiderInfo.fromMap(d.id, d.data())).toList(),
        );
  }

  static Future<String> fetchRiderEmail(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    final email = doc.data()?['email'] as String?;
    return (email == null || email.trim().isEmpty) ? 'No email' : email;
  }

  static Stream<List<Map<String, dynamic>>> riderDeliveredHistoryStream(
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
              .map(
                (d) => {
                  'orderId': d.id,
                  'deliveredAt': (d.data()['deliveredAt'] as Timestamp?)
                      ?.toDate(),
                },
              )
              .toList(),
        );
  }

  static Future<void> setRiderBlocked(String uid, bool blocked) async {
    await _db.collection('riders').doc(uid).set({
      'blocked': blocked,
    }, SetOptions(merge: true));
  }

  //  Add Rider Flow (admin creates rider account)
  static Future<void> saveNewRiderUserProfile({
    required FirebaseFirestore db,
    required String uid,
    required String email,
  }) async {
    await db.collection('users').doc(uid).set({
      'name': '',
      'avatarPath': '',
      'email': email,
      'userType': 'rider',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> saveRiderSetupProfile({
    required FirebaseFirestore db,
    required String uid,
    required String name,
    required String avatarUrl,
  }) async {
    await db.collection('users').doc(uid).set({
      'name': name,
      'avatarPath': avatarUrl,
    }, SetOptions(merge: true));

    await db.collection('riders').doc(uid).set({
      'name': name,
      'avatarPath': avatarUrl,
      'address': '',
      'latitude': 0.0,
      'longitude': 0.0,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
