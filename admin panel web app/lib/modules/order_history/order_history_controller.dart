import 'package:get/get.dart';
import '../../data/models/admin_order_model.dart';
import '../../data/models/rider_status.dart';
import '../../data/services/firestore_service.dart';

class OrderHistoryController extends GetxController {
  final orders = <AdminOrder>[].obs;
  final riderStatuses = <String, String>{}.obs;

  //  Search & Filter state
  final searchQuery = ''.obs;
  final selectedFilter = 'all'.obs;

  static const statusOrder = [
    'confirmed',
    'picked_up',
    'in_transit',
    'delivered',
  ];

  static const statusMessages = {
    'confirmed': 'আপনার অর্ডারটি কনফার্ম করা হয়েছে',
    'picked_up': 'অর্ডারটি ওয়্যারহাউজ থেকে পিক-আপ করা হয়েছে',
    'in_transit': 'অর্ডারটি আপনার শহরের দিকে যাচ্ছে',
    'delivered': 'অর্ডারটি গ্রাহকের কাছে ডেলিভার করা হয়েছে',
  };

  int get selectedFilterCount {
    if (selectedFilter.value == 'all') return orders.length;
    return orders
        .where(
          (o) =>
              latestStatus(o, riderStatuses[o.orderId]) == selectedFilter.value,
        )
        .length;
  }

  @override
  void onInit() {
    super.onInit();
    FirestoreService.allOrdersStream().listen((list) {
      orders.assignAll(list);
    });
    FirestoreService.riderStatusesStream().listen((map) {
      riderStatuses.assignAll(map);
    });
  }

  Future<void> setStatus(AdminOrder order, String status) async {
    final message = statusMessages[status] ?? '';
    await FirestoreService.updateOrderStatus(
      orderId: order.orderId,
      status: status,
      message: message,
    );
  }

  Future<void> markAvailableForDelivery(AdminOrder order) async {
    await FirestoreService.markAvailableForDelivery(order);
  }

  //  Filtered results
  List<AdminOrder> get filteredOrders {
    return orders.where((order) {
      // search by order id
      if (searchQuery.value.trim().isNotEmpty) {
        final q = searchQuery.value.trim().toLowerCase();
        if (!order.orderId.toLowerCase().contains(q)) return false;
      }
      // status filter
      if (selectedFilter.value != 'all') {
        final riderStatus = riderStatuses[order.orderId];
        if (latestStatus(order, riderStatus) != selectedFilter.value) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  int get pendingCount => orders
      .where((o) => latestStatus(o, riderStatuses[o.orderId]) == 'pending')
      .length;

  bool isPendingOrder(AdminOrder order) =>
      latestStatus(order, riderStatuses[order.orderId]) == 'pending';

  String latestStatus(AdminOrder order, String? riderStatus) {
    if (order.isHomeDelivery) {
      if (riderStatus == RiderStatus.delivered) return 'delivered';
      if (riderStatus == RiderStatus.outForDelivery) {
        return 'out_for_delivery';
      }
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
}
