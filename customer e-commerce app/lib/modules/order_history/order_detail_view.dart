import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../app/theme.dart';
import '../../data/models/order_model.dart';
import '../../app/routes.dart';
import '../../data/services/firebase_service.dart';
import 'package:get/get.dart';
import '../../data/models/delivery_order_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class _StageInfo {
  final String key;
  final String label;
  final IconData icon;
  final String logMessage;
  const _StageInfo(this.key, this.label, this.icon, this.logMessage);
}

List<_StageInfo> _stagesFor(OrderModel order) {
  const base = [
    _StageInfo(
      DeliveryStatus.orderPlaced,
      'Order Placed',
      Icons.receipt_long_outlined,
      'আপনার অর্ডারটি প্লেস করা হয়েছে',
    ),
    _StageInfo(
      DeliveryStatus.confirmed,
      'Confirm',
      Iconsax.tick_circle,
      'আপনার অর্ডারটি কনফার্ম করা হয়েছে',
    ),
    _StageInfo(
      DeliveryStatus.pickedUp,
      'Picked-up',
      Iconsax.box,
      'অর্ডারটি ওয়্যারহাউজ থেকে পিক-আপ করা হয়েছে',
    ),
    _StageInfo(
      DeliveryStatus.inTransit,
      'In Transit',
      Iconsax.truck,
      'অর্ডারটি আপনার শহরের দিকে যাচ্ছে',
    ),
  ];
  if (order.isHomeDelivery) {
    return [
      ...base,
      const _StageInfo(
        DeliveryStatus.outForDelivery,
        'Out for Delivery',
        Icons.local_shipping_outlined,
        'অর্ডারটি ডেলিভারি হাবে পৌঁছেছে',
      ),
      const _StageInfo(
        DeliveryStatus.delivered,
        'Delivered',
        Icons.home_outlined,
        'অর্ডারটি গ্রাহকের কাছে ডেলিভার করা হয়েছে',
      ),
    ];
  }
  return [
    ...base,
    const _StageInfo(
      DeliveryStatus.delivered,
      'Delivered',
      Icons.home_outlined,
      'অর্ডারটি গ্রাহকের কাছে ডেলিভার করা হয়েছে',
    ),
  ];
}

String _statusLabel(String status) {
  switch (status) {
    case DeliveryStatus.orderPlaced:
      return 'Order Placed';
    case DeliveryStatus.confirmed:
      return 'Order Confirmed';
    case DeliveryStatus.pickedUp:
      return 'Picked Up';
    case DeliveryStatus.inTransit:
      return 'In Transit';
    case DeliveryStatus.outForDelivery:
      return 'Out for Delivery';
    case DeliveryStatus.delivered:
      return 'Delivered';
    default:
      return 'Order Placed';
  }
}

String _effectiveStatus(
  OrderModel order,
  DeliveryOrderModel? dOrder,
  String? liveStatus,
) {
  if (order.isHomeDelivery && dOrder != null) {
    switch (dOrder.riderStatus) {
      case RiderStatus.outForDelivery:
        return DeliveryStatus.outForDelivery;
      case RiderStatus.delivered:
        return DeliveryStatus.delivered;
    }
  }
  return liveStatus ?? order.currentStatus;
}

class OrderDetailView extends StatefulWidget {
  final OrderModel order;
  const OrderDetailView({super.key, required this.order});

  @override
  State<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<OrderDetailView> {
  bool _showAllLogs = false;
  DeliveryOrderModel? _deliveryOrder;
  String? _liveStatus;
  List<Map<String, dynamic>> _liveHistory = [];
  StreamSubscription<DeliveryOrderModel?>? _deliverySub;
  StreamSubscription<Map<String, dynamic>?>? _statusSub;

  @override
  void initState() {
    super.initState();
    if (widget.order.isHomeDelivery) {
      _deliverySub =
          FirebaseService.userDeliveryOrderStream(widget.order.orderId).listen((
            d,
          ) {
            if (!mounted) return;
            setState(() => _deliveryOrder = d);
          });
    }
    _statusSub = FirebaseService.orderStatusStream(widget.order.orderId).listen(
      (data) {
        if (!mounted || data == null) return;
        setState(() {
          _liveStatus = data['currentStatus'] as String?;
          _liveHistory = (data['statusHistory'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
      },
    );
  }

  @override
  void dispose() {
    _deliverySub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final effectiveStatus = _effectiveStatus(
      order,
      _deliveryOrder,
      _liveStatus,
    );
    final stages = _stagesFor(order);
    int currentIndex = stages.indexWhere((s) => s.key == effectiveStatus);
    if (currentIndex == -1) currentIndex = 0;

    final isDelivered = effectiveStatus == DeliveryStatus.delivered;

    final logs = [
      for (final h in _liveHistory.reversed)
        (
          label: (h['message'] as String?) ?? '',
          time: (h['at'] is Timestamp)
              ? (h['at'] as Timestamp).toDate()
              : order.placedAt,
        ),
    ];
    final visibleLogs = _showAllLogs ? logs : logs.take(2).toList();

    final canTrack =
        order.isHomeDelivery &&
        effectiveStatus == DeliveryStatus.outForDelivery &&
        _deliveryOrder?.riderId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const BackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order Details'),
            Text(
              '#${order.orderId.substring(0, 8).toUpperCase()}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDelivered ? AppColors.success : AppColors.primary)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (isDelivered ? AppColors.success : AppColors.primary)
                      .withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          (isDelivered ? AppColors.success : AppColors.primary)
                              .withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDelivered ? Iconsax.tick_circle : Iconsax.truck,
                      color: isDelivered
                          ? AppColors.success
                          : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statusLabel(effectiveStatus),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDelivered
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                      ),
                      Text(
                        _formatDate(order.placedAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (canTrack)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: GestureDetector(
                  onTap: () => Get.toNamed(
                    AppRoutes.tracking,
                    arguments: _deliveryOrder,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delivery_dining_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Track Live Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Iconsax.arrow_right_3,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Timeline
            _sectionTitle('Timeline'),
            const SizedBox(height: 16),
            _timelineRow(stages, currentIndex),

            const SizedBox(height: 16),
            ...visibleLogs.map((log) => _logEntry(log.label, log.time)),
            if (logs.length > 2)
              GestureDetector(
                onTap: () => setState(() => _showAllLogs = !_showAllLogs),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _showAllLogs ? 'Show Less' : 'Load More',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Icon(
                        _showAllLogs
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Items
            _sectionTitle('Items Ordered'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: order.items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final isLast = i == order.items.length - 1;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 60,
                                height: 60,
                                color: const Color(0xFFF5F5F5),
                                padding: const EdgeInsets.all(6),
                                child: CachedNetworkImage(
                                  imageUrl: item.image,
                                  fit: BoxFit.contain,
                                  errorWidget: (_, __, ___) => const Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 20,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '\$${item.price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Text(
                                        ' × ',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        const Divider(
                          height: 1,
                          color: AppColors.divider,
                          indent: 14,
                          endIndent: 14,
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Shipping Info
            _sectionTitle('Delivery Address'),
            const SizedBox(height: 12),
            _infoCard(
              icon: Iconsax.location,
              children: [
                _infoRow('Name', order.fullName),
                _infoRow('Address', order.address),
                if (order.city.isNotEmpty) _infoRow('City', order.city),
                if (order.zip.isNotEmpty) _infoRow('ZIP', order.zip),
              ],
            ),

            const SizedBox(height: 20),

            // Shipping method
            _sectionTitle('Shipping Method'),
            const SizedBox(height: 12),
            _infoCard(
              icon: Iconsax.truck,
              children: [
                _infoRow('Method', order.shippingLabel),
                _infoRow('Estimated', order.shippingTime),
              ],
            ),

            const SizedBox(height: 20),

            // Price summary
            _sectionTitle('Payment Summary'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _summaryRow(
                    'Subtotal',
                    '\$${order.subtotal.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 8),
                  _summaryRow(
                    'Shipping',
                    order.shippingCost == 0
                        ? 'FREE'
                        : '\$${order.shippingCost.toStringAsFixed(2)}',
                    valueColor: order.shippingCost == 0
                        ? AppColors.success
                        : null,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: AppColors.divider, height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '\$${order.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _timelineRow(List<_StageInfo> stages, int currentIndex) {
    return Row(
      children: List.generate(stages.length, (i) {
        final done = i <= currentIndex;
        final isLast = i == stages.length - 1;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: done ? AppColors.primary : AppColors.divider,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        stages[i].icon,
                        size: 16,
                        color: done ? Colors.white : AppColors.textLight,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: done && (i + 1) <= currentIndex
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                stages[i].label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: done ? FontWeight.w700 : FontWeight.w400,
                  color: done ? AppColors.textPrimary : AppColors.textLight,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _logEntry(String label, DateTime time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _formatDateTime(time),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: -0.3,
    ),
  );

  Widget _infoCard({required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
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
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dt) {
    const months = [
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
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
