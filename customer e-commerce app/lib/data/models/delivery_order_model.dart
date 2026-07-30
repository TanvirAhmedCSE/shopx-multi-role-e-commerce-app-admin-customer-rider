import 'order_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RiderStatus {
  static const pending = 'pending';
  static const confirmed = 'confirmed';
  static const outForDelivery = 'out_for_delivery';
  static const delivered = 'delivered';
}

class DeliveryOrderModel {
  final String orderId;
  final String userId;
  final String userFcmToken;
  final String fullName;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final List<OrderItem> items;
  final double total;
  final DateTime placedAt;
  final String riderStatus;
  final String? riderId;
  final String? riderName;
  final DateTime? deliveredAt;

  const DeliveryOrderModel({
    required this.orderId,
    required this.userId,
    required this.userFcmToken,
    required this.fullName,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.items,
    required this.total,
    required this.placedAt,
    this.riderStatus = RiderStatus.pending,
    this.riderId,
    this.riderName,
    this.deliveredAt,
  });

  factory DeliveryOrderModel.fromMap(String id, Map<String, dynamic> m) =>
      DeliveryOrderModel(
        orderId: id,
        userId: m['userId'] as String,
        userFcmToken: (m['userFcmToken'] as String?) ?? '',
        fullName: m['fullName'] as String,
        address: m['address'] as String,
        city: (m['city'] as String?) ?? '',
        latitude: (m['latitude'] as num).toDouble(),
        longitude: (m['longitude'] as num).toDouble(),
        items: (m['items'] as List)
            .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        total: (m['total'] as num).toDouble(),
        placedAt: DateTime.parse(m['placedAt'] as String),
        riderStatus: (m['riderStatus'] as String?) ?? RiderStatus.pending,
        riderId: m['riderId'] as String?,
        riderName: m['riderName'] as String?,
        deliveredAt: (m['deliveredAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userFcmToken': userFcmToken,
    'fullName': fullName,
    'address': address,
    'city': city,
    'latitude': latitude,
    'longitude': longitude,
    'items': items.map((e) => e.toMap()).toList(),
    'total': total,
    'placedAt': placedAt.toIso8601String(),
    'riderStatus': riderStatus,
    'riderId': riderId,
    'riderName': riderName,
  };
}
