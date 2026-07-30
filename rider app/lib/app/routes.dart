import 'package:get/get.dart';
import '../modules/auth/login_view.dart';
import '../modules/rider/rider_home_view.dart';
import '../modules/splash/splash_view.dart';

class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const riderHome = '/rider-home';

  static final pages = [
    GetPage(name: splash, page: () => const SplashView()),
    GetPage(name: login, page: () => const LoginView()),
    GetPage(name: riderHome, page: () => const RiderHomeView()),
  ];
}
