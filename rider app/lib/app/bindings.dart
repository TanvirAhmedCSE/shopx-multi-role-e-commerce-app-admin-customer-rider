import 'package:get/get.dart';
import '../modules/auth/auth_controller.dart';
import '../modules/profile/rider_profile_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(RiderProfileController(), permanent: true);
    Get.put(AuthController(), permanent: true);
  }
}
