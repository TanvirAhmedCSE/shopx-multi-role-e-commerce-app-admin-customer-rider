import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../modules/bottom_nav/bottom_nav_controller.dart';

class ChatController extends GetxController {
  static ChatController get to => Get.find();

  final _db = FirebaseFirestore.instance;
  final unreadCount = 0.obs;
  final isChatOpen = false.obs;
  StreamSubscription? _chatSub;
  StreamSubscription? _authSub;
  Worker? _navWorker;

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? 'guest';

  DocumentReference get _chatDocRef =>
      _db.collection('support_chat').doc(_currentUid);

  String get unreadLabel =>
      unreadCount.value > 99 ? '99+' : '${unreadCount.value}';

  @override
  void onInit() {
    super.onInit();

    final cachedUser = FirebaseAuth.instance.currentUser;
    if (cachedUser != null && cachedUser.emailVerified) {
      _listenUnread();
    }

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && user.emailVerified) {
        _listenUnread();
      } else {
        closeListener();
        unreadCount.value = 0;
      }
    });

    _navWorker = ever<int>(BottomNavController.to.currentIndex, (index) {
      final opened = index == 1;
      isChatOpen.value = opened;
      if (opened) markAsRead();
    });
  }

  void _listenUnread() {
    _chatSub?.cancel();
    _chatSub = _chatDocRef.snapshots().listen((doc) {
      if (isChatOpen.value) {
        unreadCount.value = 0;
        return;
      }
      final data = doc.data() as Map<String, dynamic>?;
      unreadCount.value = (data?['unreadForUser'] as num?)?.toInt() ?? 0;
    });
  }

  void closeListener() {
    _chatSub?.cancel();
    _chatSub = null;
  }

  Future<void> markAsRead() async {
    unreadCount.value = 0;
    await _chatDocRef.set({'unreadForUser': 0}, SetOptions(merge: true));
  }

  void onChatOpened() {
    isChatOpen.value = true;
    markAsRead();
  }

  void onChatClosed() {
    isChatOpen.value = false;
    markAsRead();
  }

  @override
  void onClose() {
    _navWorker?.dispose();
    _authSub?.cancel();
    _chatSub?.cancel();
    super.onClose();
  }
}
