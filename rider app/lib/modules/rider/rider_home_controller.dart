import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/address_model.dart';
import '../../data/models/delivery_order_model.dart';
import '../../data/services/firebase_service.dart';
import '../../modules/profile/rider_profile_controller.dart';
import '../../app/theme.dart';

class RiderHomeController extends GetxController {
  static RiderHomeController get to => Get.find();

  static const double _maxDistanceKm = 5.0;

  final _rawPendingOrders = <DeliveryOrderModel>[].obs;
  final activeOrder = Rxn<DeliveryOrderModel>();
  final isClaiming = false.obs;

  StreamSubscription? _pendingSub;
  StreamSubscription? _activeSub;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  RxString get riderAddress => RiderProfileController.to.address;
  Rxn<double> get riderLat => RiderProfileController.to.lat;
  Rxn<double> get riderLng => RiderProfileController.to.lng;
  RxBool get riderInsideDhaka => RiderProfileController.to.insideDhaka;

  List<DeliveryOrderModel> get pendingOrders {
    final lat = riderLat.value;
    final lng = riderLng.value;
    if (lat == null || lng == null) return [];
    return _rawPendingOrders.where((o) {
      final d = _distanceKm(lat, lng, o.latitude, o.longitude);
      return d <= _maxDistanceKm;
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    if (riderAddress.value.isEmpty) {
      RiderProfileController.to.loadFromFirestore(_uid);
    }
    _listenPending();
    _listenActive();
  }

  void _listenPending() {
    _pendingSub = FirebaseService.pendingDeliveryOrdersStream().listen(
      (list) => _rawPendingOrders.assignAll(list),
      onError: (e) => debugPrint('[RiderHome] pending stream error: $e'),
    );
  }

  void _listenActive() {
    _activeSub = FirebaseService.riderActiveOrderStream(_uid).listen(
      (o) => activeOrder.value = o,
      onError: (e) => debugPrint('[RiderHome] active stream error: $e'),
    );
  }

  Future<void> claimOrder(DeliveryOrderModel order) async {
    if (isClaiming.value) return;
    isClaiming(true);
    final ok = await FirebaseService.claimOrder(
      orderId: order.orderId,
      riderId: _uid,
      riderName: RiderProfileController.to.name.value,
    );
    isClaiming(false);
    if (!ok) {
      Get.snackbar(
        'Already Taken',
        'অন্য একজন rider এই order টি নিয়ে গেছে।',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  Future<void> updateAddress(AddressModel addr) async {
    RiderProfileController.to.address.value = addr.fullAddress;
    RiderProfileController.to.lat.value = addr.latitude;
    RiderProfileController.to.lng.value = addr.longitude;
    RiderProfileController.to.insideDhaka.value = addr.isInsideDhaka;
    await FirebaseService.saveRiderProfile(
      uid: _uid,
      name: RiderProfileController.to.name.value,
      avatarPath: RiderProfileController.to.avatarPath.value,
      address: addr.fullAddress,
      lat: addr.latitude,
      lng: addr.longitude,
    );
  }

  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final h =
        (1 - math.cos(dLat)) / 2 +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            (1 - math.cos(dLng)) /
            2;
    final clamped = h < 0 ? 0.0 : (h > 1 ? 1.0 : h);
    return 2 * earthRadius * math.asin(math.sqrt(clamped));
  }

  double _deg2rad(double deg) => deg * (math.pi / 180);

  @override
  void onClose() {
    _pendingSub?.cancel();
    _activeSub?.cancel();
    super.onClose();
  }
}
