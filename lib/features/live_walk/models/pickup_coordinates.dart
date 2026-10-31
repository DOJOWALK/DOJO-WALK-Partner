/// Validated pickup coordinates read from the Customer booking snapshot.
class PickupCoordinates {
  const PickupCoordinates({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

/// Reads coordinates from a nested pickupAddress map.
///
/// Numeric values and numeric strings are accepted for compatibility.
/// Missing, malformed, non-finite, and out-of-range values are rejected.
PickupCoordinates? readPickupCoordinates(Map<dynamic, dynamic> address) {
  final latitude = _readCoordinate(address['latitude']);
  final longitude = _readCoordinate(address['longitude']);

  if (latitude == null ||
      longitude == null ||
      !latitude.isFinite ||
      !longitude.isFinite ||
      latitude < -90 ||
      latitude > 90 ||
      longitude < -180 ||
      longitude > 180) {
    return null;
  }

  return PickupCoordinates(
    latitude: latitude,
    longitude: longitude,
  );
}

double? _readCoordinate(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}
