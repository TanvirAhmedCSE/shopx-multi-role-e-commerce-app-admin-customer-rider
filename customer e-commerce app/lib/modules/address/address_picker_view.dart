import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
import '../../app/theme.dart';
import '../../data/models/address_model.dart';
import 'address_picker_controller.dart';

const _kPickerTag = 'address_picker';

class AddressSearchView extends StatefulWidget {
  const AddressSearchView({super.key});

  @override
  State<AddressSearchView> createState() => _AddressSearchViewState();
}

class _AddressSearchViewState extends State<AddressSearchView> {
  final _searchCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  AddressPickerController _ctrl() =>
      Get.put(AddressPickerController(), tag: _kPickerTag);

  Future<void> _goToMap() async {
    _ctrl();
    final result = await Get.to<AddressModel>(
      () => const AddressMapView(),
      arguments: {'controllerTag': _kPickerTag},
    );
    Get.delete<AddressPickerController>(tag: _kPickerTag);
    if (result != null && mounted) Get.back(result: result);
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _busy = true);
    final ok = await _ctrl().useCurrentLocation();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      Get.snackbar(
        'Location unavailable',
        'লোকেশন এক্সেস করা যায়নি, location permission চালু আছে কিনা চেক করুন।',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    await _goToMap();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Select delivery address'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _optionTile(
              icon: Icons.map_outlined,
              title: 'Set On Map',
              onTap: _busy ? null : _goToMap,
            ),
            const SizedBox(height: 12),
            _optionTile(
              icon: Icons.my_location,
              title: 'Current Location',
              onTap: _busy ? null : _useCurrentLocation,
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Iconsax.arrow_right_3,
              size: 16,
              color: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}

class AddressMapView extends StatefulWidget {
  const AddressMapView({super.key});

  @override
  State<AddressMapView> createState() => _AddressMapViewState();
}

class _AddressMapViewState extends State<AddressMapView> {
  late final AddressPickerController ctrl;
  LatLng? _pendingCenter;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map?;
    final tag = args?['controllerTag'] as String?;
    ctrl = tag != null
        ? Get.find<AddressPickerController>(tag: tag)
        : Get.put(AddressPickerController());

    if (ctrl.selectedAddress.value == null) {
      final initial =
          ctrl.markerPosition.value ?? AddressPickerController.defaultPosition;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ctrl.setFromCoordinates(initial.latitude, initial.longitude);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial =
        ctrl.markerPosition.value ?? AddressPickerController.defaultPosition;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: initial, zoom: 16),
            onMapCreated: ctrl.onMapCreated,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onCameraMove: (pos) => _pendingCenter = pos.target,
            onCameraIdle: () {
              if (_pendingCenter != null) {
                ctrl.setFromCoordinates(
                  _pendingCenter!.latitude,
                  _pendingCenter!.longitude,
                );
              }
            },
          ),

          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 170),
              child: Icon(
                Icons.location_on,
                size: 44,
                color: AppColors.primary,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, size: 18),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Obx(() {
                final addr = ctrl.selectedAddress.value;
                final loading = ctrl.isLoading.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Help us find you easily',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Move the pin to your building address for a smooth delivery',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Iconsax.location,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              loading
                                  ? 'Finding address...'
                                  : (addr?.fullAddress ??
                                        'Move the map to set pin'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (addr == null || loading)
                            ? null
                            : () => Get.back(result: addr),
                        child: const Text('Save address'),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
