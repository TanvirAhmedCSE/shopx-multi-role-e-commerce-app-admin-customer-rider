import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/app_colors.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/secondary_auth_service.dart';
import 'rider_setup_profile_view.dart';
import '../auth/login_view.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum _AddRiderState { form, waitingVerification, verified }

class AddRiderSignupView extends StatefulWidget {
  final bool justAddedRider;
  const AddRiderSignupView({super.key, this.justAddedRider = false});

  @override
  State<AddRiderSignupView> createState() => _AddRiderSignupViewState();
}

class _AddRiderSignupViewState extends State<AddRiderSignupView> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String _emailErr = '', _passErr = '', _confirmErr = '', _generalErr = '';
  bool _signing = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  _AddRiderState _state = _AddRiderState.form;
  Timer? _verifyTimer;

  @override
  void initState() {
    super.initState();
    if (widget.justAddedRider) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Get.snackbar(
          'Success',
          'New Rider Added Successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      });
    }
  }

  @override
  void dispose() {
    _verifyTimer?.cancel();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    bool ok = true;
    setState(() {
      _emailErr = '';
      _passErr = '';
      _confirmErr = '';
      _generalErr = '';
    });
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _emailErr = 'Email is required');
      ok = false;
    } else if (!RegExp(
      r'^[\w.-]+@[\w.-]+\.\w+$',
    ).hasMatch(_emailCtrl.text.trim())) {
      setState(() => _emailErr = 'Enter a valid email');
      ok = false;
    }
    if (_passCtrl.text.isEmpty) {
      setState(() => _passErr = 'Password is required');
      ok = false;
    } else if (_passCtrl.text.length < 6) {
      setState(() => _passErr = 'Minimum 6 characters');
      ok = false;
    }
    if (_confirmCtrl.text != _passCtrl.text) {
      setState(() => _confirmErr = 'Passwords do not match');
      ok = false;
    }
    return ok;
  }

  Future<void> _signUp() async {
    if (!_validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _signing = true;
      _generalErr = '';
    });

    try {
      final cred = await SecondaryAuthService.createRiderAccount(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      final uid = cred.user?.uid;
      if (uid != null) {
        await FirestoreService.saveNewRiderUserProfile(
          db: await SecondaryAuthService.firestore(),
          uid: uid,
          email: _emailCtrl.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _signing = false;
        _generalErr = _authError(e);
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _signing = false;
      _state = _AddRiderState.waitingVerification;
    });
    _startPolling();
  }

  void _startPolling() {
    _verifyTimer?.cancel();
    _verifyTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        await SecondaryAuthService.reloadCurrentUser();
        if (SecondaryAuthService.isEmailVerified && mounted) {
          _verifyTimer?.cancel();
          setState(() => _state = _AddRiderState.verified);
          await Future.delayed(const Duration(milliseconds: 1200));
          if (!mounted) return;
          Get.off(() => const RiderSetupProfileView());
        }
      } catch (_) {}
    });
  }

  Future<void> _resendEmail() async {
    try {
      await SecondaryAuthService.resendVerification();
      if (!mounted) return;
      Get.snackbar(
        'Email Sent',
        'Verification email resent!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } catch (_) {
      Get.snackbar(
        'Error',
        'Could not resend. Try again shortly.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  String _authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Add Rider'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: SizedBox(
            width: 380,
            child: _state == _AddRiderState.form
                ? _buildForm()
                : _state == _AddRiderState.waitingVerification
                ? _buildWaitingCard()
                : _buildSuccessCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Create Rider Account',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Rider needs to verify their email before profile setup',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Rider Email',
            errorText: _emailErr.isEmpty ? null : _emailErr,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _passCtrl,
          obscureText: _obscurePass,
          decoration: InputDecoration(
            labelText: 'Password',
            errorText: _passErr.isEmpty ? null : _passErr,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePass
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _confirmCtrl,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            errorText: _confirmErr.isEmpty ? null : _confirmErr,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ),
        if (_generalErr.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            _generalErr,
            style: const TextStyle(color: AppColors.error, fontSize: 12.5),
          ),
        ],
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: _signing ? null : _signUp,
            child: _signing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Create Rider Account'),
          ),
        ),

        const SizedBox(height: 10),
        if (widget.justAddedRider)
          Center(
            child: TextButton.icon(
              onPressed: () => Get.to(() => const LoginView()),
              icon: const Icon(Icons.person_outline, size: 18),
              label: const Text('Go to Admin Login'),
            ),
          ),
      ],
    );
  }

  Widget _buildWaitingCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          const Text(
            'Waiting for email verification',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _emailCtrl.text.trim(),
            style: const TextStyle(color: AppColors.primary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          const Text(
            'Rider এর email এ verification link পাঠানো হয়েছে। লিংকে ক্লিক '
            'করলে এই screen automatic এগিয়ে যাবে।',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          TextButton(
            onPressed: _resendEmail,
            child: const Text('Resend email'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Email verified!',
            style: TextStyle(
              color: AppColors.success,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Setting up rider profile…',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
