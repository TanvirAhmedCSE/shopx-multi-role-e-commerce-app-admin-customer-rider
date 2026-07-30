import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/app_colors.dart';
import '../shell/shell_controller.dart';
import 'dashboard_controller.dart';
import '../top lists/top_customers_list_view.dart';
import '../top lists/top_riders_list_view.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.isRegistered<DashboardController>()
        ? Get.find<DashboardController>()
        : Get.put(DashboardController());
    final shell = Get.find<ShellController>();

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  const spacing = 16.0;

                  int columns;
                  if (width >= 900) {
                    columns = 3;
                  } else if (width >= 600) {
                    columns = 2;
                  } else {
                    columns = 1;
                  }

                  final cardWidth = (width - spacing * (columns - 1)) / columns;

                  return Obx(
                    () => Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: _DashboardCard(
                            title: 'Total Sales',
                            value: '\$${ctrl.totalSales.toStringAsFixed(2)}',
                            icon: Icons.payments_outlined,
                            accent: AppColors.primary,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _DashboardCard(
                            title: 'Total Orders',
                            value: '${ctrl.totalOrders}',
                            icon: Icons.receipt_long_outlined,
                            accent: AppColors.accentTeal,
                            onTap: () => shell.select(4),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _DashboardCard(
                            title: 'Total Products',
                            value: '${ctrl.productsCount.value}',
                            icon: Icons.inventory_2_outlined,
                            accent: AppColors.accentPurple,
                            onTap: () => shell.select(1),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _DashboardCard(
                            title: 'Total Customers',
                            value: '${ctrl.customersCount.value}',
                            icon: Icons.people_outline,
                            accent: AppColors.accentOrange,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _DashboardCard(
                            title: 'Riders',
                            value: '${ctrl.ridersCount.value}',
                            icon: Icons.two_wheeler_outlined,
                            accent: AppColors.accentCyan,
                            onTap: () => shell.select(6),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _DashboardCard(
                            title: 'Pending Orders',
                            value: '${ctrl.pendingOrdersCount}',
                            icon: Icons.hourglass_empty_outlined,
                            accent: AppColors.error,
                            onTap: () => shell.select(4),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _DashboardCard(
                            title: 'Delivered Orders',
                            value: '${ctrl.deliveredOrdersCount}',
                            icon: Icons.check_circle_outline,
                            accent: AppColors.success,
                            onTap: () => shell.select(4),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _DashboardCard(
                            title: 'Top Customers',
                            value: '${ctrl.topCustomerEntries.length}',
                            icon: Icons.emoji_events_outlined,
                            accent: AppColors.accentPurple,
                            onTap: () =>
                                Get.to(() => const TopCustomersListView()),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _DashboardCard(
                            title: 'Top Riders',
                            value: '${ctrl.topRiderEntries.length}',
                            icon: Icons.military_tech_outlined,
                            accent: AppColors.accentOrange,
                            onTap: () =>
                                Get.to(() => const TopRidersListView()),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  const Spacer(),
                  if (onTap != null)
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
