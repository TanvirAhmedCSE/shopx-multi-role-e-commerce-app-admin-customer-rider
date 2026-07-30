import 'package:get/get.dart';
import '../../data/services/firebase_service.dart';
import '../../app/routes.dart';
import '../../modules/profile/rider_profile_controller.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  Future<void> signOut() async {
    await FirebaseService.signOut();
    RiderProfileController.to.clear();
    Get.offAllNamed(AppRoutes.login);
  }
}
