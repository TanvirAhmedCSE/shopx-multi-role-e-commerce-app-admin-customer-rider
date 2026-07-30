import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/delivery_order_model.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/models/order_model.dart';

class RiderConfirmDetailController extends GetxController {
  final String orderId;
  RiderConfirmDetailController(this.orderId);

  final order = Rxn<DeliveryOrderModel>();
  final isUpdating = false.obs;

  StreamSubscription? _orderSub;
  StreamSubscription<Position>? _locationSub;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    _orderSub = FirebaseService.userDeliveryOrderStream(orderId).listen((o) {
      order.value = o;
    });
  }

  Future<void> markOutForDelivery() async {
    if (isUpdating.value) return;
    isUpdating(true);
    await FirebaseService.updateDeliveryStatus(
      orderId,
      RiderStatus.outForDelivery,
    );
    await FirebaseService.appendOrderStatusLog(
      orderId,
      DeliveryStatus.outForDelivery,
      'অর্ডারটি আপনার ঠিকানার উদ্দেশ্যে রওনা হয়েছে',
    );
    _startLocationUpdates();

    final o = order.value;
    if (o != null && o.userId.isNotEmpty) {
      await NotificationService.sendPushToUser(
        targetUid: o.userId,
        title: '🛵 Your order is on the way!',
        body: 'Your rider is heading to your location.',
      );
    }
    isUpdating(false);
  }

  Future<void> markDelivered() async {
    if (isUpdating.value) return;
    isUpdating(true);
    await FirebaseService.updateDeliveryStatus(orderId, RiderStatus.delivered);
    await FirebaseService.appendOrderStatusLog(
      orderId,
      DeliveryStatus.delivered,
      'অর্ডারটি গ্রাহকের কাছে ডেলিভার করা হয়েছে',
    );
    _stopLocationUpdates();

    final o = order.value;
    if (o != null && o.userId.isNotEmpty) {
      await NotificationService.sendPushToUser(
        targetUid: o.userId,
        title: '✅ Order Delivered!',
        body: 'Your order has been delivered successfully.',
      );
    }
    isUpdating(false);
    Get.back();
  }

  void _startLocationUpdates() {
    // realtime movement listener
    _locationSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // 10 meters
          ),
        ).listen((pos) {
          FirebaseService.updateRiderLocation(
            _uid,
            pos.latitude,
            pos.longitude,
          );
        });
  }

  void _stopLocationUpdates() {
    _locationSub?.cancel();
    _locationSub = null;
  }

  @override
  void onClose() {
    _orderSub?.cancel();
    _stopLocationUpdates();
    super.onClose();
  }
}
