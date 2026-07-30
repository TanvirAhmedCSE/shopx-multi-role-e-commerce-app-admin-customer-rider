import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

enum AdminCheckStatus { idle, checking, verified }

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final _auth = FirebaseAuth.instance;
  final firebaseUser = Rxn<User>();
  final isLoading = false.obs;

  final showSignUp = false.obs;

  final adminCheckStatus = AdminCheckStatus.idle.obs;

  final showNotAdminSnackbar = false.obs;

  String? _lastUid;

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.userChanges());

    ever(firebaseUser, (User? user) {
      if (user?.uid != _lastUid) {
        _lastUid = user?.uid;
        adminCheckStatus.value = AdminCheckStatus.idle;
      }
    });
  }

  Future<String?> signUp(String email, String password) async {
    try {
      isLoading(true);
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user?.sendEmailVerification();
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    } finally {
      isLoading(false);
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      isLoading(true);
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    } finally {
      isLoading(false);
    }
  }

  Future<void> resendVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    }
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
    firebaseUser.value = _auth.currentUser;
  }

  Future<void> checkAdminAccess() async {
    if (adminCheckStatus.value != AdminCheckStatus.idle) return;
    adminCheckStatus.value = AdminCheckStatus.checking;
    try {
      await FirebaseFirestore.instance
          .collection('admin_only_check')
          .doc('verify')
          .get();
      adminCheckStatus.value = AdminCheckStatus.verified;
    } catch (_) {
      showNotAdminSnackbar.value = true;
      await signOut();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    adminCheckStatus.value = AdminCheckStatus.idle;
  }

  String _authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak (min 6 characters).';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}
