import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import '../../app/theme.dart';
import '../../data/models/delivery_order_model.dart';
import '../../data/services/firebase_service.dart';

class TrackingView extends StatefulWidget {
  const TrackingView({super.key});
  @override
  State<TrackingView> createState() => _TrackingViewState();
}

class _TrackingViewState extends State<TrackingView> {
  static const String _apiKey = 'REPLACE';

  late final DeliveryOrderModel order;
  GoogleMapController? _mapCtrl;
  LatLng? _riderPos;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _loaded = false;
  String? _riderAvatarUrl;

  LatLng? _lastRoutedFrom;

  @override
  void initState() {
    super.initState();
    order = Get.arguments as DeliveryOrderModel;
    _listenRider();
    _loadRiderAvatar();
  }

  Future<void> _loadRiderAvatar() async {
    final riderId = order.riderId;
    if (riderId == null) return;
    try {
      final profile = await FirebaseService.fetchRiderProfile(riderId);
      final url = profile?['avatarPath'] as String?;
      if (mounted && url != null && url.trim().isNotEmpty) {
        setState(() => _riderAvatarUrl = url);
      }
    } catch (_) {}
  }

  void _listenRider() {
    if (order.riderId == null) return;
    FirebaseService.riderLocationStream(order.riderId!).listen((loc) {
      if (loc == null || !mounted) return;
      final riderLatLng = LatLng(loc['latitude']!, loc['longitude']!);
      final destLatLng = LatLng(order.latitude, order.longitude);

      setState(() {
        _riderPos = riderLatLng;
        _loaded = true;
        _markers = {
          Marker(
            markerId: const MarkerId('rider'),
            position: riderLatLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
            infoWindow: InfoWindow(title: order.riderName ?? 'Rider'),
          ),
          Marker(
            markerId: const MarkerId('dest'),
            position: destLatLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(title: order.fullName),
          ),
        };

        if (_polylines.isEmpty) {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: [riderLatLng, destLatLng],
              color: const Color(0xFF1565C0),
              width: 4,
              patterns: [PatternItem.dash(20), PatternItem.gap(10)],
            ),
          };
        }
      });

      _mapCtrl?.animateCamera(CameraUpdate.newLatLng(riderLatLng));
      _maybeFetchRoute(riderLatLng, destLatLng);
    });
  }

  void _maybeFetchRoute(LatLng from, LatLng dest) {
    if (_lastRoutedFrom != null &&
        _distanceMeters(_lastRoutedFrom!, from) < 10) {
      // before: 30 meters
      return;
    }
    _fetchRoute(from, dest);
  }

  Future<void> _fetchRoute(LatLng origin, LatLng dest) async {
    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${dest.longitude},${dest.latitude}'
        '?overview=full&geometries=polyline',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        debugPrint('[Tracking] OSRM HTTP ${res.statusCode}: ${res.body}');
        return;
      }

      final data = jsonDecode(res.body);
      if (data['code'] != 'Ok') {
        debugPrint('[Tracking] OSRM status: ${data['code']}');
        return;
      }

      final routes = data['routes'] as List;
      if (routes.isEmpty) return;

      final overviewPolyline = routes[0]['geometry'] as String?;
      if (overviewPolyline == null) return;

      final points = _decodePolyline(overviewPolyline);
      if (!mounted) return;

      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: const Color(0xFF1565C0),
            width: 4,
          ),
        };
      });

      _lastRoutedFrom = origin;
    } catch (e) {
      debugPrint('[Tracking] route fetch error: $e');
    }
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLng = _deg2rad(b.longitude - a.longitude);
    final h =
        (1 - math.cos(dLat)) / 2 +
        math.cos(_deg2rad(a.latitude)) *
            math.cos(_deg2rad(b.latitude)) *
            (1 - math.cos(dLng)) /
            2;
    final clamped = h < 0 ? 0.0 : (h > 1 ? 1.0 : h);
    return 2 * earthRadius * math.asin(math.sqrt(clamped));
  }

  double _deg2rad(double deg) => deg * (math.pi / 180);

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final destLatLng = LatLng(order.latitude, order.longitude);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Live Tracking'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: destLatLng, zoom: 15),
            onMapCreated: (c) => _mapCtrl = c,
            markers: _markers,
            polylines: _polylines,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          if (!_loaded)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)),
            ),

          if (_riderPos != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rider: ${_riderPos!.latitude.toStringAsFixed(6)}, '
                        '${_riderPos!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: (_riderAvatarUrl != null)
                            ? Image.network(
                                _riderAvatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.delivery_dining_rounded,
                                  color: Color(0xFF1565C0),
                                  size: 22,
                                ),
                                loadingBuilder: (context, child, progress) =>
                                    progress == null
                                    ? child
                                    : const Center(
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF1565C0),
                                          ),
                                        ),
                                      ),
                              )
                            : const Icon(
                                Icons.delivery_dining_rounded,
                                color: Color(0xFF1565C0),
                                size: 22,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.riderName ?? 'Your Rider',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Text(
                              'On the way to you',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFF9800,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Out for Delivery',
                          style: TextStyle(
                            color: Color(0xFFFF9800),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(
                        Iconsax.location,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapCtrl?.dispose();
    super.dispose();
  }
}
