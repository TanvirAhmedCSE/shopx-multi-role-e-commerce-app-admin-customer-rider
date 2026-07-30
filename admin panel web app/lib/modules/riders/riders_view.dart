import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../app/app_colors.dart';
import '../../data/models/admin_order_model.dart';
import '../../data/services/firestore_service.dart';
import 'riders_controller.dart';

class RidersView extends StatelessWidget {
  const RidersView({super.key});

  static const _breakpoint = 700.0;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.isRegistered<RidersController>()
        ? Get.find<RidersController>()
        : Get.put(RidersController());

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _breakpoint;

        if (isWide) {
          return Row(
            children: [
              _RiderList(ctrl: ctrl, width: 320, onSelect: ctrl.selectRider),
              Container(width: 1, color: AppColors.border),
              Expanded(
                child: Obx(
                  () => ctrl.selectedUid.value == null
                      ? const Center(
                          child: Text(
                            'Select a rider',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : _RiderDetailPanel(
                          key: ValueKey(ctrl.selectedUid.value),
                          uid: ctrl.selectedUid.value!,
                          ctrl: ctrl,
                        ),
                ),
              ),
            ],
          );
        }

        return _RiderList(
          ctrl: ctrl,
          width: double.infinity,
          onSelect: (uid) {
            ctrl.selectRider(uid);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _RiderDetailScreen(uid: uid, ctrl: ctrl),
              ),
            );
          },
        );
      },
    );
  }
}

class _RiderList extends StatelessWidget {
  final RidersController ctrl;
  final double width;
  final void Function(String uid) onSelect;
  const _RiderList({
    required this.ctrl,
    required this.width,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 16),
            child: Text(
              'Riders',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              onChanged: (v) => ctrl.searchQuery.value = v,
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final query = ctrl.searchQuery.value.trim().toLowerCase();
              final emails = ctrl.riderEmails;
              final all = ctrl.riders;
              final list = query.isEmpty
                  ? all
                  : all.where((r) {
                      final email = (emails[r.uid] ?? '').toLowerCase();
                      return r.name.toLowerCase().contains(query) ||
                          email.contains(query);
                    }).toList();
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    query.isEmpty
                        ? 'No riders yet'
                        : 'No riders match "${ctrl.searchQuery.value}"',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              return ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.border),
                itemBuilder: (_, i) {
                  final r = list[i];
                  return Obx(() {
                    final selected = ctrl.selectedUid.value == r.uid;
                    final email = ctrl.riderEmails[r.uid] ?? 'Loading...';
                    return ListTile(
                      selected: selected,
                      selectedTileColor: AppColors.primary.withValues(
                        alpha: 0.08,
                      ),
                      leading: _RiderAvatar(url: r.avatarPath, radius: 20),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (r.blocked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Blocked',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      onTap: () => onSelect(r.uid),
                    );
                  });
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _RiderDetailScreen extends StatelessWidget {
  final String uid;
  final RidersController ctrl;
  const _RiderDetailScreen({required this.uid, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Obx(() => Text(ctrl.riderByUid(uid)?.name ?? 'Rider')),
      ),
      body: _RiderDetailPanel(uid: uid, ctrl: ctrl),
    );
  }
}

class _RiderDetailPanel extends StatefulWidget {
  final String uid;
  final RidersController ctrl;
  const _RiderDetailPanel({super.key, required this.uid, required this.ctrl});

  @override
  State<_RiderDetailPanel> createState() => _RiderDetailPanelState();
}

class _RiderDetailPanelState extends State<_RiderDetailPanel> {
  bool _updating = false;

  //  Delivered History order-id search
  final _orderSearchCtrl = TextEditingController();
  String _orderSearchQuery = '';

  @override
  void dispose() {
    _orderSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmAndToggleBlock(bool currentlyBlocked) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(currentlyBlocked ? 'Unblock Rider?' : 'Block Rider?'),
        content: Text(
          currentlyBlocked
              ? 'This rider will be able to log in again.'
              : 'This rider will no longer be able to log in. Their account '
                    'and delivery records will NOT be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(currentlyBlocked ? 'Unblock' : 'OK'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _updating = true);
    try {
      await FirestoreService.setRiderBlocked(widget.uid, !currentlyBlocked);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rider = widget.ctrl.riderByUid(widget.uid);
      final email = widget.ctrl.riderEmails[widget.uid] ?? '';
      final blocked = rider?.blocked ?? false;

      return LayoutBuilder(
        builder: (context, constraints) {
          final headerNarrow = constraints.maxWidth < 420;

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: headerNarrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _riderNameEmail(
                            rider?.name ?? 'Rider',
                            email,
                            rider?.avatarPath,
                          ),
                          const SizedBox(height: 12),
                          _blockButton(blocked),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _riderNameEmail(
                              rider?.name ?? 'Rider',
                              email,
                              rider?.avatarPath,
                            ),
                          ),
                          _blockButton(blocked),
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Delivered History',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: FirestoreService.riderDeliveredHistoryStream(
                        widget.uid,
                      ),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.length ?? 0;
                        return Text(
                          'Total Delivered: $count Orders',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _OrderSearchBar(
                  controller: _orderSearchCtrl,
                  onChanged: (v) => setState(() => _orderSearchQuery = v),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FirestoreService.riderDeliveredHistoryStream(
                    widget.uid,
                  ),
                  builder: (context, snapshot) {
                    final all = snapshot.data ?? [];
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        all.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (all.isEmpty) {
                      return const Center(
                        child: Text(
                          'No delivered orders yet',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }

                    final q = _orderSearchQuery.trim().toLowerCase();
                    final list = q.isEmpty
                        ? all
                        : all
                              .where(
                                (m) => (m['orderId'] as String)
                                    .toLowerCase()
                                    .contains(q),
                              )
                              .toList();

                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          'No orders match "$_orderSearchQuery"',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final orderId = list[i]['orderId'] as String;
                        final deliveredAt = list[i]['deliveredAt'] as DateTime?;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '#${orderId.substring(0, 8).toUpperCase()}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.info_outline_rounded,
                                      size: 16,
                                    ),
                                    tooltip: 'View Details',
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    color: AppColors.textSecondary,
                                    onPressed: () => _showOrderDetailsDialog(
                                      context,
                                      orderId,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _fmt(deliveredAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _riderNameEmail(String name, String email, String? avatarUrl) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RiderAvatar(url: avatarUrl, radius: 24),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                email,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _blockButton(bool blocked) {
    return ElevatedButton(
      onPressed: _updating ? null : () => _confirmAndToggleBlock(blocked),
      style: ElevatedButton.styleFrom(
        backgroundColor: blocked ? AppColors.primary : AppColors.error,
        foregroundColor: Colors.white,
      ),
      child: _updating
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(blocked ? 'Unblock Rider' : 'Block Rider'),
    );
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    const m = [
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
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  //  Order details dialog
  void _showOrderDetailsDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (_) => FutureBuilder<AdminOrder?>(
        future: FirestoreService.fetchOrderById(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              content: SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          final order = snapshot.data;
          if (order == null) {
            return AlertDialog(
              title: const Text('Order Not Found'),
              content: const Text(
                'This order could not be loaded. It may have been removed.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          }
          return _OrderDetailsDialog(order: order);
        },
      ),
    );
  }
}

//  Order-id search bar (Delivered History)
class _OrderSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _OrderSearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintText: 'Search by Order ID...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) => value.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      controller.clear();
                      onChanged('');
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
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

//  Full order details dialog
class _OrderDetailsDialog extends StatelessWidget {
  final AdminOrder order;
  const _OrderDetailsDialog({required this.order});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
              _summaryRow('Subtotal', '\$${order.subtotal.toStringAsFixed(2)}'),
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
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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

class _RiderAvatar extends StatelessWidget {
  final String? url;
  final double radius;
  const _RiderAvatar({required this.url, required this.radius});

  @override
  Widget build(BuildContext context) {
    final hasImage = url != null && url!.trim().isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.border,
      backgroundImage: hasImage ? NetworkImage(url!) : null,
      child: hasImage
          ? null
          : Icon(Icons.person, size: radius, color: AppColors.textSecondary),
    );
  }
}
