import 'package:get/get.dart';
import '../../data/models/admin_order_model.dart';
import '../../data/models/admin_product_model.dart';
import '../../data/models/rider_status.dart';
import '../../data/services/firestore_service.dart';
import '../categories/categories_controller.dart';

class ProductStat {
  final String title;
  final String? id;
  final String? category;
  final String image;
  final double price;
  final double rating;
  final int quantity;
  final double revenue;

  ProductStat({
    required this.title,
    required this.id,
    required this.category,
    required this.image,
    required this.price,
    required this.rating,
    required this.quantity,
    required this.revenue,
  });

  String get categoryLabel =>
      category == null ? '—' : CategoriesController.splitNameIcon(category!).$1;
}

class CategoryStat {
  final String category;
  final int totalQuantity;
  final ProductStat topProduct;

  CategoryStat({
    required this.category,
    required this.totalQuantity,
    required this.topProduct,
  });

  String get categoryLabel => CategoriesController.splitNameIcon(category).$1;
}

class SalesPoint {
  final DateTime bucketStart;
  final String label;
  final double amount;

  SalesPoint({
    required this.bucketStart,
    required this.label,
    required this.amount,
  });
}

class AnalyticsController extends GetxController {
  final orders = <AdminOrder>[].obs;
  final riderStatuses = <String, String>{}.obs;
  final products = <AdminProduct>[].obs;

  @override
  void onInit() {
    super.onInit();
    FirestoreService.allOrdersStream().listen((list) => orders.assignAll(list));
    FirestoreService.riderStatusesStream().listen(
      (map) => riderStatuses.assignAll(map),
    );
    FirestoreService.productsStream().listen(
      (list) => products.assignAll(list),
    );
  }

  //  Status helper
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

  List<AdminOrder> get _salesOrders =>
      orders.where((o) => _latestStatus(o) != 'pending').toList();

  //  Time-series (Monthly / Weekly / Daily)
  List<SalesPoint> get dailySales => _dailyOrWeekly(
    bucketCount: 14,
    step: const Duration(days: 1),
    keyFor: (d) => DateTime(d.year, d.month, d.day),
    labelFor: (d) => '${d.day}/${d.month}',
  );

  List<SalesPoint> get weeklyRevenue => _dailyOrWeekly(
    bucketCount: 8,
    step: const Duration(days: 7),
    keyFor: _startOfWeek,
    labelFor: (d) => '${d.day}/${d.month}',
  );

  List<SalesPoint> get monthlySales => _monthlyBucketedSales(months: 6);

  double get lastDayRevenue {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    return _salesOrders
        .where((o) => !o.placedAt.isBefore(startOfToday))
        .fold(0.0, (sum, o) => sum + o.total);
  }

  double get lastWeekRevenue {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final windowStart = startOfToday.subtract(const Duration(days: 6));
    return _salesOrders
        .where((o) => !o.placedAt.isBefore(windowStart))
        .fold(0.0, (sum, o) => sum + o.total);
  }

  double get lastMonthRevenue =>
      monthlySales.isEmpty ? 0.0 : monthlySales.last.amount;

  DateTime _startOfWeek(DateTime d) {
    final date = DateTime(d.year, d.month, d.day);
    return date.subtract(Duration(days: date.weekday - 1)); // Monday start
  }

  List<SalesPoint> _dailyOrWeekly({
    required int bucketCount,
    required Duration step,
    required DateTime Function(DateTime) keyFor,
    required String Function(DateTime) labelFor,
  }) {
    final todayKey = keyFor(DateTime.now());
    final totalsByKey = <DateTime, double>{};
    for (final o in _salesOrders) {
      final key = keyFor(o.placedAt);
      totalsByKey[key] = (totalsByKey[key] ?? 0) + o.total;
    }

    return [
      for (int i = bucketCount - 1; i >= 0; i--)
        () {
          final bucketDate = todayKey.subtract(step * i);
          return SalesPoint(
            bucketStart: bucketDate,
            label: labelFor(bucketDate),
            amount: totalsByKey[bucketDate] ?? 0.0,
          );
        }(),
    ];
  }

  List<SalesPoint> _monthlyBucketedSales({required int months}) {
    final now = DateTime.now();
    final totalsByKey = <DateTime, double>{};
    for (final o in _salesOrders) {
      final key = DateTime(o.placedAt.year, o.placedAt.month);
      totalsByKey[key] = (totalsByKey[key] ?? 0) + o.total;
    }

    const monthLabels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return [
      for (int i = months - 1; i >= 0; i--)
        () {
          final d = DateTime(now.year, now.month - i);
          final key = DateTime(d.year, d.month);
          return SalesPoint(
            bucketStart: key,
            label: monthLabels[d.month - 1],
            amount: totalsByKey[key] ?? 0.0,
          );
        }(),
    ];
  }

  Map<String, ProductStat> _aggregateProducts({required bool includePending}) {
    final productByTitle = <String, AdminProduct>{
      for (final p in products) p.title: p,
    };
    final relevantOrders = includePending ? orders : _salesOrders;

    final agg = <String, ProductStat>{};
    for (final order in relevantOrders) {
      for (final item in order.items) {
        final match = productByTitle[item.title];
        final existing = agg[item.title];
        agg[item.title] = ProductStat(
          title: item.title,
          id: match?.id,
          category: match?.category,
          image: match?.image ?? item.image,
          price: match?.price ?? item.price,
          rating: match?.rating ?? 0.0,
          quantity: (existing?.quantity ?? 0) + item.quantity,
          revenue: (existing?.revenue ?? 0) + item.price * item.quantity,
        );
      }
    }
    return agg;
  }

  List<ProductStat> get mostOrderedProducts {
    final agg = _aggregateProducts(includePending: true).values.toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));
    return agg.take(20).toList();
  }

  List<ProductStat> get topRevenueProducts {
    final agg = _aggregateProducts(includePending: false).values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    return agg.take(20).toList();
  }

  List<ProductStat> get highestRatedProducts {
    final rated =
        products.where((p) => p.rating >= 3.0 && p.rating <= 5.0).toList()
          ..sort((a, b) => b.rating.compareTo(a.rating));
    return rated
        .take(20)
        .map(
          (p) => ProductStat(
            title: p.title,
            id: p.id,
            category: p.category,
            image: p.image,
            price: p.price,
            rating: p.rating,
            quantity: 0,
            revenue: 0,
          ),
        )
        .toList();
  }

  List<CategoryStat> get bestSellingCategories {
    final agg = _aggregateProducts(includePending: true);
    final byCategory = <String, List<ProductStat>>{};
    for (final stat in agg.values) {
      if (stat.category == null) continue;
      byCategory.putIfAbsent(stat.category!, () => []).add(stat);
    }

    final result = <CategoryStat>[];
    byCategory.forEach((category, list) {
      list.sort((a, b) => b.quantity.compareTo(a.quantity));
      final totalQty = list.fold<int>(0, (s, p) => s + p.quantity);
      result.add(
        CategoryStat(
          category: category,
          totalQuantity: totalQty,
          topProduct: list.first,
        ),
      );
    });

    result.sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));
    return result.take(5).toList();
  }
}
