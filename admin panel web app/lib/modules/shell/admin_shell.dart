import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/app_colors.dart';
import '../auth/auth_controller.dart';
import '../categories/categories_view.dart';
import '../products/products_list_view.dart';
import 'shell_controller.dart';
import '../messages/messages_view.dart';
import '../messages/messages_controller.dart';
import '../order_history/order_history_view.dart';
import '../order_history/order_history_controller.dart';
import '../dashboard/dashboard_view.dart';
import '../analytics/analytics_view.dart';
import '../riders/riders_view.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  static const _sidebarWidth = 230.0;

  static const _breakpoint = 800.0;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ShellController());
    final messagesCtrl = Get.isRegistered<MessagesController>()
        ? Get.find<MessagesController>()
        : Get.put(MessagesController());
    final orderHistoryCtrl = Get.isRegistered<OrderHistoryController>()
        ? Get.find<OrderHistoryController>()
        : Get.put(OrderHistoryController());

    final content = Obx(() {
      switch (ctrl.selectedIndex.value) {
        case 1:
          return const ProductsListView();
        case 2:
          return const CategoriesView();
        case 3:
          return const MessagesView();
        case 4:
          return const OrderHistoryView();
        case 5:
          return const AnalyticsView();
        case 6:
          return const RidersView();
        default:
          return const DashboardView();
      }
    });

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _breakpoint;

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Sidebar(
                  ctrl: ctrl,
                  messagesCtrl: messagesCtrl,
                  orderHistoryCtrl: orderHistoryCtrl,
                ),
                Expanded(child: content),
              ],
            );
          }

          return Obx(() {
            final open = ctrl.isSidebarOpen.value;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  width: open ? _sidebarWidth : 0,
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(),
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.centerLeft,
                      minWidth: _sidebarWidth,
                      maxWidth: _sidebarWidth,
                      child: _Sidebar(
                        ctrl: ctrl,
                        messagesCtrl: messagesCtrl,
                        orderHistoryCtrl: orderHistoryCtrl,
                        onNavItemTap: ctrl.closeSidebar,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: ctrl.toggleSidebar,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 26,
                    color: AppColors.sidebarBg,
                    alignment: Alignment.center,
                    child: Icon(
                      open ? Icons.chevron_left : Icons.chevron_right,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                Expanded(child: content),
              ],
            );
          });
        },
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final ShellController ctrl;
  final MessagesController messagesCtrl;
  final OrderHistoryController orderHistoryCtrl;

  final VoidCallback? onNavItemTap;

  const _Sidebar({
    required this.ctrl,
    required this.messagesCtrl,
    required this.orderHistoryCtrl,
    this.onNavItemTap,
  });

  @override
  Widget build(BuildContext context) {
    void select(int i) {
      ctrl.select(i);
      onNavItemTap?.call();
    }

    return Container(
      width: 230,
      color: AppColors.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Text(
              'ShopX Admin',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Obx(
            () => Column(
              children: [
                _NavItem(
                  label: 'Dashboard',
                  icon: Icons.dashboard_outlined,
                  selected: ctrl.selectedIndex.value == 0,
                  onTap: () => select(0),
                ),
                _NavItem(
                  label: 'Products',
                  icon: Icons.inventory_2_outlined,
                  selected: ctrl.selectedIndex.value == 1,
                  onTap: () => select(1),
                ),
                _NavItem(
                  label: 'Categories',
                  icon: Icons.category_outlined,
                  selected: ctrl.selectedIndex.value == 2,
                  onTap: () => select(2),
                ),
                _NavItem(
                  label: 'Messages',
                  icon: Icons.forum_outlined,
                  selected: ctrl.selectedIndex.value == 3,
                  onTap: () => select(3),
                  trailing: Obx(() {
                    final count = messagesCtrl.totalUnread.value;
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      constraints: const BoxConstraints(minWidth: 20),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }),
                ),
                _NavItem(
                  label: 'Order History',
                  icon: Icons.receipt_long_outlined,
                  selected: ctrl.selectedIndex.value == 4,
                  onTap: () => select(4),
                  trailing: Obx(() {
                    final count = orderHistoryCtrl.pendingCount;
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      constraints: const BoxConstraints(minWidth: 20),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }),
                ),
                _NavItem(
                  label: 'Analytics',
                  icon: Icons.bar_chart_rounded,
                  selected: ctrl.selectedIndex.value == 5,
                  onTap: () => select(5),
                ),
                _NavItem(
                  label: 'Riders',
                  icon: Icons.two_wheeler_outlined,
                  selected: ctrl.selectedIndex.value == 6,
                  onTap: () => select(6),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            child: _NavItem(
              label: AuthController.to.firebaseUser.value?.email ?? 'Sign out',
              icon: Icons.logout,
              selected: false,
              onTap: () => AuthController.to.signOut(),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withValues(alpha: 0.08) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 19,
              color: selected ? AppColors.sidebarActive : AppColors.sidebarText,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? AppColors.sidebarActive
                      : AppColors.sidebarText,
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
