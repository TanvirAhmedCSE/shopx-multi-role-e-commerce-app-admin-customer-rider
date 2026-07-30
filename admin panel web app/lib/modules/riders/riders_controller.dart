import 'package:get/get.dart';
import '../../data/models/rider_info_model.dart';
import '../../data/services/firestore_service.dart';

class RidersController extends GetxController {
  final riders = <RiderInfo>[].obs;
  final riderEmails = <String, String>{}.obs;
  final selectedUid = Rxn<String>();
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    FirestoreService.ridersStream().listen((list) {
      riders.assignAll(list);
      for (final r in list) {
        if (!riderEmails.containsKey(r.uid)) _loadEmail(r.uid);
      }
    });
  }

  Future<void> _loadEmail(String uid) async {
    final email = await FirestoreService.fetchRiderEmail(uid);
    riderEmails[uid] = email;
  }

  void selectRider(String uid) => selectedUid.value = uid;

  RiderInfo? riderByUid(String uid) {
    try {
      return riders.firstWhere((r) => r.uid == uid);
    } catch (_) {
      return null;
    }
  }
}
