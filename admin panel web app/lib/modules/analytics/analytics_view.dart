import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/app_colors.dart';
import 'analytics_controller.dart';

class AnalyticsView extends StatelessWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.isRegistered<AnalyticsController>()
        ? Get.find<AnalyticsController>()
        : Get.put(AnalyticsController());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analytics',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),

          //  Trend charts
          LayoutBuilder(
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
                      child: _TrendCard(
                        title: 'Monthly Sales',
                        color: AppColors.primary,
                        points: ctrl.monthlySales,
                        latestValue: ctrl.lastMonthRevenue,
                        latestLabel: "This month's revenue",
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _TrendCard(
                        title: 'Weekly Revenue',
                        color: AppColors.accentTeal,
                        points: ctrl.weeklyRevenue,
                        latestValue: ctrl.lastWeekRevenue,
                        latestLabel: "This week's revenue",
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _TrendCard(
                        title: 'Daily Sales',
                        color: AppColors.accentPurple,
                        points: ctrl.dailySales,
                        latestValue: ctrl.lastDayRevenue,
                        latestLabel: "Today's revenue",
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 28),

          Obx(
            () => _ProductStatTable(
              title: 'Most Ordered Products',
              subtitle: 'By total quantity ordered',
              icon: Icons.local_fire_department_outlined,
              accent: AppColors.error,
              stats: ctrl.mostOrderedProducts,
              metricLabel: 'Qty Ordered',
              metricFor: (s) => '${s.quantity}',
            ),
          ),
          const SizedBox(height: 20),

          Obx(
            () => _ProductStatTable(
              title: 'Top Revenue Products',
              subtitle: 'By total revenue',
              icon: Icons.trending_up_rounded,
              accent: AppColors.success,
              stats: ctrl.topRevenueProducts,
              metricLabel: 'Revenue',
              metricFor: (s) => '\$${s.revenue.toStringAsFixed(2)}',
            ),
          ),
          const SizedBox(height: 20),

          Obx(
            () => _ProductStatTable(
              title: 'Highest Rated Products',
              subtitle: 'Rating between 3.0 and 5.0',
              icon: Icons.star_rounded,
              accent: AppColors.accentOrange,
              stats: ctrl.highestRatedProducts,
              metricLabel: 'Rating',
              metricFor: (s) => s.rating.toStringAsFixed(1),
            ),
          ),
          const SizedBox(height: 20),

          Obx(
            () => _BestSellingCategoriesTable(
              categories: ctrl.bestSellingCategories,
            ),
          ),
        ],
      ),
    );
  }
}

//  Trend chart card
class _TrendCard extends StatelessWidget {
  final String title;
  final Color color;
  final List<SalesPoint> points;
  final double latestValue;
  final String latestLabel;

  const _TrendCard({
    required this.title,
    required this.color,
    required this.points,
    required this.latestValue,
    required this.latestLabel,
  });

  @override
  Widget build(BuildContext context) {
    final maxY = points.isEmpty
        ? 100.0
        : (points.map((p) => p.amount).reduce((a, b) => a > b ? a : b) * 1.2)
              .clamp(10.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: points.isEmpty
                ? const Center(
                    child: Text(
                      'No data yet',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: (points.length / 4)
                                .clamp(1, points.length)
                                .toDouble(),
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= points.length)
                                return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  points[i].label,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => AppColors.textPrimary,
                          getTooltipItems: (spots) => spots
                              .map(
                                (s) => LineTooltipItem(
                                  '\$${s.y.toStringAsFixed(2)}',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (int i = 0; i < points.length; i++)
                              FlSpot(i.toDouble(), points[i].amount),
                          ],
                          isCurved: true,
                          color: color,
                          barWidth: 2.5,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                latestLabel,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '\$${latestValue.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

//  Product table (Most Ordered / Top Revenue / Highest Rated)
class _ProductStatTable extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<ProductStat> stats;
  final String metricLabel;
  final String Function(ProductStat) metricFor;

  const _ProductStatTable({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.stats,
    required this.metricLabel,
    required this.metricFor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 17),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (stats.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Center(
                child: Text(
                  'No data yet',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    AppColors.background,
                  ),
                  columns: [
                    const DataColumn(label: Text('Rank')),
                    const DataColumn(label: Text('')),
                    const DataColumn(label: Text('Name')),
                    const DataColumn(label: Text('ID')),
                    const DataColumn(label: Text('Category')),
                    const DataColumn(label: Text('Price')),
                    const DataColumn(label: Text('Rating')),
                    DataColumn(label: Text(metricLabel)),
                  ],
                  rows: [
                    for (int i = 0; i < stats.length; i++)
                      _statRow(i + 1, stats[i]),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  DataRow _statRow(int rank, ProductStat s) {
    return DataRow(
      cells: [
        DataCell(_RankBadge(rank: rank)),
        DataCell(
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: s.image.isEmpty
                ? Container(width: 36, height: 36, color: AppColors.background)
                : Image.network(
                    s.image,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 180,
            child: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(Text(s.id ?? '—')),
        DataCell(Text(s.categoryLabel)),
        DataCell(Text('\$${s.price.toStringAsFixed(2)}')),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 15,
                color: AppColors.accentOrange,
              ),
              const SizedBox(width: 3),
              Text(s.rating.toStringAsFixed(1)),
            ],
          ),
        ),
        DataCell(
          SizedBox(
            width: 110,
            child: Text(
              metricFor(s),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

//  Best Selling Categories
class _BestSellingCategoriesTable extends StatelessWidget {
  final List<CategoryStat> categories;
  const _BestSellingCategoriesTable({required this.categories});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Text(
              'Best Selling Categories',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Text(
              'By total quantity ordered, with the top product in each category',
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ),
          if (categories.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Center(
                child: Text(
                  'No data yet',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  for (int i = 0; i < categories.length; i++) ...[
                    _categoryRow(i + 1, categories[i]),
                    if (i != categories.length - 1) const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _categoryRow(int rank, CategoryStat c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _RankBadge(rank: rank),
          const SizedBox(width: 14),
          SizedBox(
            width: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.categoryLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${c.totalQuantity} sold',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.border),
          const SizedBox(width: 14),
          Expanded(child: _bestProductInCategory(c.topProduct)),
        ],
      ),
    );
  }

  Widget _bestProductInCategory(ProductStat s) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: s.image.isEmpty
              ? Container(width: 44, height: 44, color: AppColors.surface)
              : Image.network(
                  s.image,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Wrap(
                spacing: 10,
                runSpacing: 2,
                children: [
                  _miniField('ID', s.id ?? '—'),
                  _miniField('Category', s.categoryLabel),
                  _miniField('Price', '\$${s.price.toStringAsFixed(2)}'),
                  _miniField('Rating', s.rating.toStringAsFixed(1)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniField(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isTop3 ? AppColors.primary : AppColors.background,
        shape: BoxShape.circle,
        border: isTop3 ? null : Border.all(color: AppColors.border),
      ),
      child: Text(
        '$rank',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isTop3 ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}
