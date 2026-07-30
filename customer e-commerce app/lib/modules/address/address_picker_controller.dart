import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/address_model.dart';
import '../../data/services/location_service.dart';

class AddressPickerController extends GetxController {
  static const LatLng defaultPosition = LatLng(
    23.7806,
    90.4074,
  ); // Dhaka center

  final isLoading = false.obs;
  final selectedAddress = Rxn<AddressModel>();
  final markerPosition = Rxn<LatLng>();

  GoogleMapController? mapController;

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> setFromCoordinates(double lat, double lng) async {
    isLoading(true);
    markerPosition.value = LatLng(lat, lng);
    selectedAddress.value = await LocationService.fromCoordinates(lat, lng);
    isLoading(false);
  }

  Future<bool> setFromSearch(String query) async {
    if (query.trim().isEmpty) return false;
    isLoading(true);
    final addr = await LocationService.fromSearchQuery(query.trim());
    isLoading(false);
    if (addr == null) return false;
    selectedAddress.value = addr;
    markerPosition.value = LatLng(addr.latitude, addr.longitude);
    return true;
  }

  Future<bool> useCurrentLocation() async {
    isLoading(true);
    final addr = await LocationService.currentLocation();
    isLoading(false);
    if (addr == null) return false;
    selectedAddress.value = addr;
    markerPosition.value = LatLng(addr.latitude, addr.longitude);
    return true;
  }

  @override
  void onClose() {
    mapController?.dispose();
    super.onClose();
  }
}
