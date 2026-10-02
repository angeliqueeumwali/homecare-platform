import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String? address;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.address,
  });
}

/// Thrown when the current position could not be determined. The [message] is
/// safe to show to the user, so the UI can display it directly.
class LocationException implements Exception {
  final String message;

  const LocationException(this.message);

  @override
  String toString() => message;
}

class LocationService {
  /// Requests permission if needed and returns the current position.
  ///
  /// Emulators often have no GPS fix, so callers must surface the failure and
  /// keep the manual lat/long entry fields available.
  static Future<LocationResult> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        'Location services are turned off. Enable them in your device '
        'settings, or enter the coordinates manually.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationException(
        'Location permission was denied. Allow it in settings, or enter the '
        'coordinates manually.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Location permission is permanently denied. Enable it in your device '
        'settings, or enter the coordinates manually.',
      );
    }

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } on TimeoutException {
      throw const LocationException(
        'Timed out while getting your location. Check the emulator GPS '
        'settings, or enter the coordinates manually.',
      );
    } catch (_) {
      throw const LocationException(
        'Could not get your current location. Enter the coordinates manually.',
      );
    }

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      address: await _reverseGeocode(position.latitude, position.longitude),
    );
  }

  /// Reverse geocoding is a nicety: if it fails we still return coordinates.
  static Future<String?> _reverseGeocode(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isEmpty) return null;
      final place = placemarks.first;
      final parts = <String?>[
        place.name,
        place.street,
        place.subLocality,
        place.locality,
      ].where((p) => p != null && p.isNotEmpty).toSet().toList();
      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  /// Converts a typed address into coordinates so customers never have to
  /// enter latitude or longitude themselves.
  static Future<LocationResult> geocodeAddress(String address) async {
    final query = address.trim();
    if (query.isEmpty) {
      throw const LocationException('Please enter an address first.');
    }

    List<Location> matches;
    try {
      matches = await locationFromAddress(query);
    } catch (_) {
      throw const LocationException(
        'Could not find that address. Try adding a city or district, or use '
        'your current location.',
      );
    }

    if (matches.isEmpty) {
      throw const LocationException(
        'Could not find that address. Try adding a city or district, or use '
        'your current location.',
      );
    }

    final best = matches.first;
    return LocationResult(
      latitude: best.latitude,
      longitude: best.longitude,
      address: query,
    );
  }
}
