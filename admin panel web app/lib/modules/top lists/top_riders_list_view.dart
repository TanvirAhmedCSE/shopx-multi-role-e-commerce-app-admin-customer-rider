import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/app_colors.dart';
import '../dashboard/dashboard_controller.dart';

class TopRidersListView extends StatefulWidget {
  const TopRidersListView({super.key});

  @override
  State<TopRidersListView> createState() => _TopRidersListViewState();
}

class _TopRidersListViewState extends State<TopRidersListView> {
  late final DashboardController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = Get.isRegistered<DashboardController>()
        ? Get.find<DashboardController>()
        : Get.put(DashboardController());
    for (final e in ctrl.topRiderEntries) {
      ctrl.loadRiderEmail(e.key.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Top 3 Riders'),
      ),
      body: Obx(() {
        final entries = ctrl.topRiderEntries;
        for (final e in entries) {
          ctrl.loadRiderEmail(e.key.uid);
        }

        if (entries.isEmpty) {
          return const Center(
            child: Text(
              'No riders yet',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final entry = entries[i];
            final rider = entry.key;
            final delivered = entry.value;
            final email = ctrl.riderEmails[rider.uid] ?? '';
            final hasImage = rider.avatarPath.trim().isNotEmpty;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: AppColors.accentOrange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.border,
                    backgroundImage: hasImage
                        ? NetworkImage(rider.avatarPath)
                        : null,
                    child: hasImage
                        ? null
                        : const Icon(
                            Icons.person,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rider.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (email.isNotEmpty)
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
                  Text(
                    '$delivered delivered',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
