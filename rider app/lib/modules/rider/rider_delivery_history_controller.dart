import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../data/models/delivery_order_model.dart';
import '../../data/services/firebase_service.dart';

class RiderDeliveryHistoryController extends GetxController {
  final history = <DeliveryOrderModel>[].obs;
  final isLoading = true.obs;

  StreamSubscription? _sub;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    _sub = FirebaseService.riderDeliveredHistoryStream(_uid).listen(
      (list) {
        history.assignAll(list);
        isLoading(false);
      },
      onError: (e) {
        isLoading(false);
      },
    );
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
