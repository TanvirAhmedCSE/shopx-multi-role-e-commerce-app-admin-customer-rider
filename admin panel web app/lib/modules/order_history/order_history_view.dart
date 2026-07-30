import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/app_colors.dart';
import '../../data/models/admin_order_model.dart';
import '../../data/models/rider_status.dart';
import 'order_history_controller.dart';
import 'package:flutter/services.dart';

class OrderHistoryView extends StatelessWidget {
  const OrderHistoryView({super.key});

  static const _statusOrder = [
    'confirmed',
    'picked_up',
    'in_transit',
    'delivered',
  ];

  static const _filters = [
    {'label': 'All', 'value': 'all'},
    {'label': 'Pending', 'value': 'pending'},
    {'label': 'Confirmed', 'value': 'confirmed'},
    {'label': 'Picked-up', 'value': 'picked_up'},
    {'label': 'In Transit', 'value': 'in_transit'},
    {'label': 'Available for Delivery', 'value': 'available_for_delivery'},
    {'label': 'Out for Delivery', 'value': 'out_for_delivery'},
    {'label': 'Delivered', 'value': 'delivered'},
  ];

  static const _filterLabels = {
    'all': 'All',
    'pending': 'Pending',
    'confirmed': 'Confirmed',
    'picked_up': 'Picked-up',
    'in_transit': 'In Transit',
    'available_for_delivery': 'Available for Delivery',
    'out_for_delivery': 'Out for Delivery',
    'delivered': 'Delivered',
  };

  double _scaleFor(double width) => (width / 1300).clamp(0.72, 1.0);

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.isRegistered<OrderHistoryController>()
        ? Get.find<OrderHistoryController>()
        : Get.put(OrderHistoryController());

    return LayoutBuilder(
      builder: (context, constraints) {
        final s = _scaleFor(constraints.maxWidth);

        return Padding(
          padding: EdgeInsets.all(32 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order History',
                style: TextStyle(
                  fontSize: 22 * s,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 5 * s),

              //  Selected filter count
              Obx(
                () => Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_filterLabels[ctrl.selectedFilter.value]}: ${ctrl.selectedFilterCount} '
                    '${ctrl.selectedFilterCount == 1 ? 'order' : 'orders'}',
                    style: TextStyle(
                      fontSize: 12.5 * s,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12 * s),

              //  Search bar
              _SearchBar(ctrl: ctrl, scale: s),
              SizedBox(height: 12 * s),

              //  Filter chips
              SizedBox(
                height: 36 * s,
                child: Obx(
                  () => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((f) {
                        final selected =
                            ctrl.selectedFilter.value == f['value'];
                        final isPendingChip = f['value'] == 'pending';
                        final pendingCount = ctrl.pendingCount;
                        return Padding(
                          padding: EdgeInsets.only(right: 8 * s),
                          child: GestureDetector(
                            onTap: () =>
                                ctrl.selectedFilter.value = f['value']!,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: EdgeInsets.symmetric(horizontal: 14 * s),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(18 * s),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    f['label']!,
                                    style: TextStyle(
                                      fontSize: 12 * s,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  if (isPendingChip && pendingCount > 0) ...[
                                    SizedBox(width: 6 * s),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6 * s,
                                        vertical: 1 * s,
                                      ),
                                      constraints: BoxConstraints(
                                        minWidth: 18 * s,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? Colors.white
                                            : AppColors.error,
                                        borderRadius: BorderRadius.circular(
                                          9 * s,
                                        ),
                                      ),
                                      child: Text(
                                        pendingCount > 99
                                            ? '99+'
                                            : '$pendingCount',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 9 * s,
                                          fontWeight: FontWeight.w700,
                                          color: selected
                                              ? AppColors.primary
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20 * s),

              Expanded(
                child: Obx(() {
                  final list = ctrl.filteredOrders;
                  if (list.isEmpty) {
                    return const Center(
                      child: Text(
                        'No orders found',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) => _orderRow(context, ctrl, list[i], s),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _orderRow(
    BuildContext context,
    OrderHistoryController ctrl,
    AdminOrder order,
    double s,
  ) {
    final isPending = ctrl.isPendingOrder(order);
    return Container(
      margin: EdgeInsets.only(bottom: 10 * s),
      padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 12 * s),
      decoration: BoxDecoration(
        color: isPending ? Colors.grey.shade200 : AppColors.surface,
        borderRadius: BorderRadius.circular(10 * s),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Order ID stays fully visible, never scrolls or shrinks below scale.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _showOrderDialog(context, order),
                child: Text(
                  '#${order.orderId.substring(0, 8).toUpperCase()}',
                  style: TextStyle(
                    fontSize: 14 * s,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(width: 6 * s),
              IconButton(
                icon: Icon(Icons.info_outline_rounded, size: 16 * s),
                tooltip: 'View Details',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: AppColors.textSecondary,
                onPressed: () => _showOrderDialog(context, order),
              ),
            ],
          ),
          SizedBox(width: 12 * s),
          // Status buttons get remaining space; scroll horizontally if they
          // don't fit even after scaling, so nothing ever overflows.
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: _statusButtons(ctrl, order, s),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusButtons(
    OrderHistoryController ctrl,
    AdminOrder order,
    double s,
  ) {
    final currentIndex = _statusOrder.indexOf(order.currentStatus);

    final finalBtn = order.isHomeDelivery
        ? _availableForDeliveryBtn(order, ctrl, s)
        : _deliveredBtn(
            order,
            ctrl,
            s,
            done: currentIndex >= _statusOrder.indexOf('delivered'),
          );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _statusBtn(
          'Confirm',
          'confirmed',
          order,
          ctrl,
          s,
          done: currentIndex >= _statusOrder.indexOf('confirmed'),
        ),
        SizedBox(width: 6 * s),
        _statusBtn(
          'Picked-up',
          'picked_up',
          order,
          ctrl,
          s,
          done: currentIndex >= _statusOrder.indexOf('picked_up'),
        ),
        SizedBox(width: 6 * s),
        _statusBtn(
          'In Transit',
          'in_transit',
          order,
          ctrl,
          s,
          done: currentIndex >= _statusOrder.indexOf('in_transit'),
        ),
        SizedBox(width: 6 * s),
        finalBtn,
        if (order.isHomeDelivery) ...[
          SizedBox(width: 6 * s),
          Obx(() {
            final riderStatus = ctrl.riderStatuses[order.orderId];
            final isOutForDelivery =
                riderStatus == RiderStatus.outForDelivery ||
                riderStatus == RiderStatus.delivered;
            final isDelivered = riderStatus == RiderStatus.delivered;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _riderStatusBtn('Out for Delivery', isOutForDelivery, s),
                SizedBox(width: 6 * s),
                _riderStatusBtn('Delivered', isDelivered, s),
              ],
            );
          }),
        ],
      ],
    );
  }

  Widget _statusBtn(
    String label,
    String statusKey,
    AdminOrder order,
    OrderHistoryController ctrl,
    double s, {
    required bool done,
  }) {
    return SizedBox(
      height: 32 * s,
      child: ElevatedButton(
        onPressed: done ? null : () => ctrl.setStatus(order, statusKey),
        style: ElevatedButton.styleFrom(
          backgroundColor: done ? AppColors.success : AppColors.surface,
          disabledBackgroundColor: AppColors.success,
          disabledForegroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          side: BorderSide(color: done ? AppColors.success : AppColors.border),
          padding: EdgeInsets.symmetric(horizontal: 10 * s),
          textStyle: TextStyle(fontSize: 11 * s, fontWeight: FontWeight.w600),
        ),
        child: Text(
          done ? (label == 'Confirm' ? 'Confirmed ✓' : '$label ✓') : label,
        ),
      ),
    );
  }

  Widget _availableForDeliveryBtn(
    AdminOrder order,
    OrderHistoryController ctrl,
    double s,
  ) {
    final done = order.availableForDelivery;
    return SizedBox(
      height: 32 * s,
      child: ElevatedButton(
        onPressed: done ? null : () => ctrl.markAvailableForDelivery(order),
        style: ElevatedButton.styleFrom(
          backgroundColor: done ? AppColors.success : AppColors.surface,
          disabledBackgroundColor: AppColors.success,
          disabledForegroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          side: BorderSide(color: done ? AppColors.success : AppColors.border),
          padding: EdgeInsets.symmetric(horizontal: 10 * s),
          textStyle: TextStyle(fontSize: 11 * s, fontWeight: FontWeight.w600),
        ),
        child: Text(
          done ? 'Available For Delivery ✓' : 'Available For Delivery',
        ),
      ),
    );
  }

  Widget _deliveredBtn(
    AdminOrder order,
    OrderHistoryController ctrl,
    double s, {
    required bool done,
  }) {
    return SizedBox(
      height: 32 * s,
      child: ElevatedButton(
        onPressed: done ? null : () => ctrl.setStatus(order, 'delivered'),
        style: ElevatedButton.styleFrom(
          backgroundColor: done ? AppColors.success : AppColors.surface,
          disabledBackgroundColor: AppColors.success,
          disabledForegroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          side: BorderSide(color: done ? AppColors.success : AppColors.border),
          padding: EdgeInsets.symmetric(horizontal: 10 * s),
          textStyle: TextStyle(fontSize: 11 * s, fontWeight: FontWeight.w600),
        ),
        child: Text(done ? 'Delivered ✓' : 'Delivered'),
      ),
    );
  }

  Widget _riderStatusBtn(String label, bool active, double s) {
    return SizedBox(
      height: 32 * s,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: active
              ? AppColors.success
              : AppColors.surface,
          disabledForegroundColor: active
              ? Colors.white
              : AppColors.textPrimary,
          elevation: 0,
          side: BorderSide(
            color: active ? AppColors.success : AppColors.border,
          ),
          padding: EdgeInsets.symmetric(horizontal: 10 * s),
          textStyle: TextStyle(fontSize: 11 * s, fontWeight: FontWeight.w600),
        ),
        child: Text(active ? '$label ✓' : label),
      ),
    );
  }

  void _showOrderDialog(BuildContext context, AdminOrder order) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Order #${order.orderId.substring(0, 8).toUpperCase()}'),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 16),
              tooltip: 'Copy Order ID',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: AppColors.textSecondary,
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(
                    text: '#${order.orderId.substring(0, 8).toUpperCase()}',
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order ID copied'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ],
        ),
        content: SizedBox(
          width: 640,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogTitle('Items Ordered'),
                const SizedBox(height: 8),
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: item.image.isEmpty
                              ? Container(
                                  width: 40,
                                  height: 40,
                                  color: AppColors.background,
                                )
                              : Image.network(
                                  item.image,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '×${item.quantity}  \$${(item.price * item.quantity).toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24),
                _dialogTitle('Delivery Address'),
                const SizedBox(height: 8),
                Text('Name: ${order.fullName}'),
                Text('Address: ${order.address}'),
                if (order.city.isNotEmpty) Text('City: ${order.city}'),
                if (order.zip.isNotEmpty) Text('ZIP: ${order.zip}'),
                const Divider(height: 24),
                _dialogTitle('Shipping Method'),
                const SizedBox(height: 8),
                Text('Method: ${order.shippingLabel}'),
                Text('Estimated: ${order.shippingTime}'),
                const Divider(height: 24),
                _dialogTitle('Payment Summary'),
                const SizedBox(height: 8),
                _summaryRow(
                  'Subtotal',
                  '\$${order.subtotal.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 6),
                _summaryRow(
                  'Shipping',
                  order.shippingCost == 0
                      ? 'FREE'
                      : '\$${order.shippingCost.toStringAsFixed(2)}',
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '\$${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _dialogTitle(String t) => Text(
    t,
    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
  );

  Widget _summaryRow(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    ],
  );
}

//  Search bar
class _SearchBar extends StatelessWidget {
  final OrderHistoryController ctrl;
  final double scale;
  const _SearchBar({required this.ctrl, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44 * scale,
      padding: EdgeInsets.symmetric(horizontal: 14 * scale),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10 * scale),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 18 * scale, color: AppColors.textSecondary),
          SizedBox(width: 8 * scale),
          Expanded(
            child: TextField(
              onChanged: ctrl.searchQuery,
              decoration: InputDecoration(
                hintText: 'Search by Order ID...',
                hintStyle: TextStyle(
                  fontSize: 13 * scale,
                  color: AppColors.textSecondary,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              style: TextStyle(
                fontSize: 13 * scale,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Obx(
            () => ctrl.searchQuery.value.isNotEmpty
                ? GestureDetector(
                    onTap: () => ctrl.searchQuery.value = '',
                    child: Icon(
                      Icons.close_rounded,
                      size: 18 * scale,
                      color: AppColors.textSecondary,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
