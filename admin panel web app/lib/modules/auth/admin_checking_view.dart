import 'package:flutter/material.dart';
import '../../app/app_colors.dart';
import 'auth_controller.dart';

// After email verification, while checking if admin is on email list
// this full-white loading screen is shown. When check is complete AuthGate reactively
// takes to AdminShell or (sign-out if denied) LoginView.
// This widget does not do any navigation itself.
class AdminCheckingView extends StatefulWidget {
  const AdminCheckingView({super.key});

  @override
  State<AdminCheckingView> createState() => _AdminCheckingViewState();
}

class _AdminCheckingViewState extends State<AdminCheckingView> {
  @override
  void initState() {
    super.initState();
    AuthController.to.checkAdminAccess();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}
