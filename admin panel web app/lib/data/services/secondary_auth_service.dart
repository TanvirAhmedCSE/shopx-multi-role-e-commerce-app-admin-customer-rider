import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SecondaryAuthService {
  static FirebaseApp? _app;
  static FirebaseAuth? _auth;
  static FirebaseFirestore? _firestore;

  static Future<FirebaseApp> _ensureApp() async {
    return _app ??= await Firebase.initializeApp(
      name: 'RiderCreation',
      options: Firebase.app().options,
    );
  }

  static Future<FirebaseAuth> _instance() async {
    await _ensureApp();
    return _auth ??= FirebaseAuth.instanceFor(app: _app!);
  }

  static Future<FirebaseFirestore> firestore() async {
    await _ensureApp();
    return _firestore ??= FirebaseFirestore.instanceFor(app: _app!);
  }

  static Future<UserCredential> createRiderAccount({
    required String email,
    required String password,
  }) async {
    final auth = await _instance();
    final cred = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user?.sendEmailVerification();
    return cred;
  }

  static Future<void> reloadCurrentUser() async {
    await _auth?.currentUser?.reload();
  }

  static Future<void> resendVerification() async {
    await _auth?.currentUser?.sendEmailVerification();
  }

  static bool get isEmailVerified => _auth?.currentUser?.emailVerified ?? false;

  static User? get currentUser => _auth?.currentUser;

  static Future<void> signOutAndDispose() async {
    await _auth?.signOut();
    await _app?.delete();
    _app = null;
    _auth = null;
    _firestore = null;
  }
}
