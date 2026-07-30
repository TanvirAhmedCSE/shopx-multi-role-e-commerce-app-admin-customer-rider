import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/app_colors.dart';
import '../../data/services/secondary_auth_service.dart';
import '../auth/auth_gate.dart';

class RiderSetupFinishingView extends StatefulWidget {
  const RiderSetupFinishingView({super.key});

  @override
  State<RiderSetupFinishingView> createState() =>
      _RiderSetupFinishingViewState();
}

class _RiderSetupFinishingViewState extends State<RiderSetupFinishingView> {
  @override
  void initState() {
    super.initState();
    _finish();
  }

  Future<void> _finish() async {
    await Future.delayed(const Duration(milliseconds: 600));
    await SecondaryAuthService.signOutAndDispose();
    if (!mounted) return;

    Get.offAll(() => const AuthGate());

    Get.snackbar(
      'Success',
      'New Rider Added Successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}
