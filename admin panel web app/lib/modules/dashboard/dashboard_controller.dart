import 'package:get/get.dart';
import '../../data/models/admin_order_model.dart';
import '../../data/models/rider_info_model.dart';
import '../../data/models/rider_status.dart';
import '../../data/services/firestore_service.dart';

class DashboardController extends GetxController {
  final orders = <AdminOrder>[].obs;
  final riderStatuses = <String, String>{}.obs;
  final riderDeliveredCounts = <String, int>{}.obs;
  final ridersList = <RiderInfo>[].obs;
  final productsCount = 0.obs;
  final customersCount = 0.obs;
  final ridersCount = 0.obs;

  final customerNames = <String, String>{}.obs;
  final customerEmails = <String, String>{}.obs;
  final riderEmails = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    FirestoreService.allOrdersStream().listen((list) => orders.assignAll(list));
    FirestoreService.riderStatusesStream().listen(
      (map) => riderStatuses.assignAll(map),
    );
    FirestoreService.riderDeliveredCountsStream().listen(
      (map) => riderDeliveredCounts.assignAll(map),
    );
    FirestoreService.productsStream().listen(
      (list) => productsCount.value = list.length,
    );
    FirestoreService.customersCountStream().listen(
      (count) => customersCount.value = count,
    );
    FirestoreService.ridersStream().listen((list) {
      ridersList.assignAll(list);
      ridersCount.value = list.length;
    });
  }

  double get totalSales => orders
      .where((o) => _latestStatus(o) != 'pending')
      .fold(0.0, (sum, o) => sum + o.total);

  int get totalOrders => orders.length;

  String _latestStatus(AdminOrder order) {
    final riderStatus = riderStatuses[order.orderId];
    if (order.isHomeDelivery) {
      if (riderStatus == RiderStatus.delivered) return 'delivered';
      if (riderStatus == RiderStatus.outForDelivery) return 'out_for_delivery';
      if (order.availableForDelivery) return 'available_for_delivery';
    } else {
      if (order.currentStatus == 'delivered') return 'delivered';
    }

    switch (order.currentStatus) {
      case 'in_transit':
        return 'in_transit';
      case 'picked_up':
        return 'picked_up';
      case 'confirmed':
        return 'confirmed';
      default:
        return 'pending';
    }
  }

  int get pendingOrdersCount =>
      orders.where((o) => _latestStatus(o) == 'pending').length;

  int get deliveredOrdersCount =>
      orders.where((o) => _latestStatus(o) == 'delivered').length;

  //  Top Customers
  Map<String, double> get _customerTotals {
    final map = <String, double>{};
    for (final o in orders) {
      if (_latestStatus(o) == 'pending') continue;
      if (o.userId.isEmpty) continue;
      map[o.userId] = (map[o.userId] ?? 0) + o.total;
    }
    return map;
  }

  List<MapEntry<String, double>> get topCustomerEntries {
    final entries = _customerTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(3).toList();
  }

  Future<void> loadCustomerInfo(String uid) async {
    if (customerNames.containsKey(uid) && customerEmails.containsKey(uid)) {
      return;
    }
    final name = await FirestoreService.fetchCustomerName(uid);
    final email = await FirestoreService.fetchRiderEmail(uid);
    customerNames[uid] = name;
    customerEmails[uid] = email;
  }

  //  Top Riders
  List<MapEntry<RiderInfo, int>> get topRiderEntries {
    final entries =
        ridersList
            .map((r) => MapEntry(r, riderDeliveredCounts[r.uid] ?? 0))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(3).toList();
  }

  Future<void> loadRiderEmail(String uid) async {
    if (riderEmails.containsKey(uid)) return;
    final email = await FirestoreService.fetchRiderEmail(uid);
    riderEmails[uid] = email;
  }
}
