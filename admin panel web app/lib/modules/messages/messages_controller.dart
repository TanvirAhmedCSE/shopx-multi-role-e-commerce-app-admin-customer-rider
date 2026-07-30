import 'package:get/get.dart';
import '../../data/models/chat_summary_model.dart';
import '../../data/services/firestore_service.dart';

class MessagesController extends GetxController {
  final conversations = <ChatSummary>[].obs;
  final customerNames = <String, String>{}.obs;
  final customerEmails = <String, String>{}.obs;
  final selectedUid = Rxn<String>();
  final totalUnread = 0.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    FirestoreService.chatConversationsStream().listen((list) {
      conversations.assignAll(list);
      totalUnread.value = list.fold(0, (sum, c) => sum + c.unreadForAdmin);
      for (final c in list) {
        if (!customerNames.containsKey(c.uid)) _loadName(c.uid);
        if (!customerEmails.containsKey(c.uid)) _loadEmail(c.uid);
      }
    });
  }

  Future<void> _loadName(String uid) async {
    final name = await FirestoreService.fetchCustomerName(uid);
    customerNames[uid] = name;
  }

  Future<void> _loadEmail(String uid) async {
    final email = await FirestoreService.fetchRiderEmail(uid);
    customerEmails[uid] = email;
  }

  void selectConversation(String uid) {
    selectedUid.value = uid;
    FirestoreService.markConversationRead(uid);
  }

  String nameFor(String uid) => customerNames[uid] ?? 'Customer';
  String emailFor(String uid) => customerEmails[uid] ?? '';
}
