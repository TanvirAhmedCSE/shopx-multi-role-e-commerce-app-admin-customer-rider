import 'package:get/get.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/location_service.dart';

class RiderProfileController extends GetxController {
  static RiderProfileController get to => Get.find();

  final name = ''.obs;
  final avatarPath = ''.obs;
  final address = ''.obs;
  final lat = Rxn<double>();
  final lng = Rxn<double>();
  final insideDhaka = false.obs;

  Future<void> loadFromFirestore(String uid) async {
    final data = await FirebaseService.fetchRiderProfile(uid);
    if (data == null) return;

    name.value = data['name'] as String? ?? '';
    avatarPath.value = data['avatarPath'] as String? ?? '';
    address.value = data['address'] as String? ?? '';

    final la = (data['latitude'] as num?)?.toDouble();
    final ln = (data['longitude'] as num?)?.toDouble();
    if (la != null && ln != null && (la != 0.0 || ln != 0.0)) {
      lat.value = la;
      lng.value = ln;
      insideDhaka.value = LocationService.isInsideDhaka(la, ln);
    }
  }

  void clear() {
    name.value = '';
    avatarPath.value = '';
    address.value = '';
    lat.value = null;
    lng.value = null;
    insideDhaka.value = false;
  }
}
