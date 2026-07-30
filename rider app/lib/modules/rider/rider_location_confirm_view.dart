import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
import '../../app/theme.dart';
import '../../data/models/address_model.dart';
import '../../data/services/location_service.dart';

// Locked location-confirm screen for Rider's "Out for Delivery" flow.
class RiderLocationConfirmView extends StatefulWidget {
  const RiderLocationConfirmView({super.key});

  @override
  State<RiderLocationConfirmView> createState() =>
      _RiderLocationConfirmViewState();
}

class _RiderLocationConfirmViewState extends State<RiderLocationConfirmView> {
  GoogleMapController? _mapCtrl;
  AddressModel? _address;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    final addr = await LocationService.currentLocation();
    if (!mounted) return;
    setState(() {
      _address = addr;
      _loading = false;
    });
    if (addr != null) {
      _mapCtrl?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(addr.latitude, addr.longitude), 17),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)),
            )
          else if (_address == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'লোকেশন পাওয়া যায়নি। GPS/Location permission চেক করুন।',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(_address!.latitude, _address!.longitude),
                zoom: 17,
              ),
              onMapCreated: (c) => _mapCtrl = c,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: {
                Marker(
                  markerId: const MarkerId('current'),
                  position: LatLng(_address!.latitude, _address!.longitude),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
                ),
              },
            ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => Get.back(result: false),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Confirm your current location',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'এই লোকেশনটাই কাস্টমারকে ট্র্যাকিং এর জন্য দেখানো হবে',
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
                            _loading
                                ? 'Finding your location...'
                                : (_address?.fullAddress ??
                                      'Location not found'),
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
                      onPressed: (_address == null || _loading)
                          ? null
                          : () => Get.back(result: true),
                      child: const Text('Save Address'),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
