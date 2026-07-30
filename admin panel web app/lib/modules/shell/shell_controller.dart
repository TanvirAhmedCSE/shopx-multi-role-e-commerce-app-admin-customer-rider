import 'package:get/get.dart';

class ShellController extends GetxController {
  final selectedIndex = 0.obs;
  void select(int i) => selectedIndex.value = i;

  // Only relevant when the sidebar is in narrow or overlay mode
  // controls whether it's currently slid into view or hidden off-screen.
  final isSidebarOpen = false.obs;
  void toggleSidebar() => isSidebarOpen.value = !isSidebarOpen.value;
  void closeSidebar() => isSidebarOpen.value = false;
}
