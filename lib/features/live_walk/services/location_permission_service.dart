import 'package:geolocator/geolocator.dart';

class LocationPermissionService {
  const LocationPermissionService._();

  /// Checks whether device location services are enabled.
  static Future<bool> isLocationServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  /// Requests foreground location permission when needed.
  static Future<LocationPermission> requestPermission() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  /// Returns true when foreground location permission is available.
  static Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Opens the Android app settings page.
  static Future<bool> openAppSettings() async {
    return Geolocator.openAppSettings();
  }

  /// Opens the device location settings page.
  static Future<bool> openLocationSettings() async {
    return Geolocator.openLocationSettings();
  }

  /// Checks service availability and requests permission if necessary.
  static Future<bool> ensureLocationPermission() async {
    final serviceEnabled = await isLocationServiceEnabled();

    if (!serviceEnabled) {
      return false;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }
}
