import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/address_model.dart';

class LocationService {
  static const String _apiKey = 'REPLACE';

  // Rough bounding box for Dhaka metro — used for fallback check
  static const double _dhakaMinLat = 23.65;
  static const double _dhakaMaxLat = 23.90;
  static const double _dhakaMinLng = 90.30;
  static const double _dhakaMaxLng = 90.50;

  // TEST MODE: set "true" to enable Home Delivery for the whole of Bangladesh.
  // Set the flag to "false", so the previous Dhaka-only home delivery service logic returns.
  static const bool _testAllowAllBangladesh = false;

  static bool _isInsideDhakaBounds(double lat, double lng) {
    if (_testAllowAllBangladesh) return true;
    return lat >= _dhakaMinLat &&
        lat <= _dhakaMaxLat &&
        lng >= _dhakaMinLng &&
        lng <= _dhakaMaxLng;
  }

  // Public wrapper for use from other files — needed to recompute
  // isInsideDhaka when restoring old lat/lng from Firestore
  static bool isInsideDhaka(double lat, double lng) =>
      _isInsideDhakaBounds(lat, lng);

  static bool _componentsHaveDhaka(List components) {
    if (_testAllowAllBangladesh) return true;
    for (final c in components) {
      final longName = (c['long_name'] as String? ?? '').toLowerCase();
      if (longName.contains('dhaka')) return true;
    }
    return false;
  }

  // Reverse geocodes lat/lng into a detailed AddressModel
  // (uses Google Geocoding API — gives road/block level detail)
  static Future<AddressModel> fromCoordinates(double lat, double lng) async {
    String fullAddress = '';
    String city = '';
    String zip = '';
    bool insideDhaka = _isInsideDhakaBounds(lat, lng);

    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$lat,$lng&key=$_apiKey&language=en',
      );
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final status = data['status'];

        if (status == 'OK') {
          final results = data['results'] as List;
          if (results.isNotEmpty) {
            final best = results[0];
            fullAddress = best['formatted_address'] ?? '';

            final components = best['address_components'] as List? ?? [];
            for (final c in components) {
              final types = (c['types'] as List).cast<String>();
              if (types.contains('locality') ||
                  types.contains('administrative_area_level_2')) {
                city = c['long_name'] ?? '';
              }
              if (types.contains('postal_code')) {
                zip = c['long_name'] ?? '';
              }
            }
            insideDhaka = insideDhaka || _componentsHaveDhaka(components);
          }
        }
        // if status == 'REQUEST_DENIED', fullAddress stays empty,
        // the fallback below (lat,lng) will kick in
      }
    } catch (_) {}

    if (fullAddress.isEmpty) fullAddress = '$lat, $lng';

    return AddressModel(
      fullAddress: fullAddress,
      city: city,
      zip: zip,
      latitude: lat,
      longitude: lng,
      isInsideDhaka: insideDhaka,
    );
  }

  // Forward geocodes a search query into an AddressModel
  static Future<AddressModel?> fromSearchQuery(String query) async {
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=${Uri.encodeComponent(query)}&key=$_apiKey&language=en'
        '&components=country:BD', // biases the search within Bangladesh
      );
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          if (results.isNotEmpty) {
            final loc = results[0]['geometry']['location'];
            return fromCoordinates(
              (loc['lat'] as num).toDouble(),
              (loc['lng'] as num).toDouble(),
            );
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Builds an AddressModel from the device's current GPS location
  static Future<AddressModel?> currentLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return fromCoordinates(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }
}
