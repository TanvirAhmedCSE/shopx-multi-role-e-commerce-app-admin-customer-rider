import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../shell/admin_shell.dart';
import 'admin_checking_view.dart';
import 'auth_controller.dart';
import 'login_view.dart';
import 'signup_view.dart';
import 'verify_email_view.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.put(AuthController());

    return Obx(() {
      final user = auth.firebaseUser.value;
      if (user == null) {
        return auth.showSignUp.value ? const SignupView() : const LoginView();
      }
      if (!user.emailVerified) return const VerifyEmailView();

      if (auth.adminCheckStatus.value == AdminCheckStatus.verified) {
        return const AdminShell();
      }
      return const AdminCheckingView();
    });
  }
}
