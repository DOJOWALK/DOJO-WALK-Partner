import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_partner/features/live_walk/models/pickup_coordinates.dart';

void main() {
  group('readPickupCoordinates', () {
    test('accepts valid numeric latitude and longitude', () {
      final result = readPickupCoordinates({
        'latitude': 28.6139,
        'longitude': 77.2090,
      });

      expect(result, isNotNull);
      expect(result!.latitude, 28.6139);
      expect(result.longitude, 77.2090);
    });

    test('accepts numeric strings for legacy compatibility', () {
      final result = readPickupCoordinates({
        'latitude': '28.6139',
        'longitude': '77.2090',
      });

      expect(result, isNotNull);
      expect(result!.latitude, 28.6139);
      expect(result.longitude, 77.2090);
    });

    test('rejects an address with missing coordinates', () {
      expect(readPickupCoordinates({'address': 'Noida'}), isNull);
    });

    test('rejects a partial coordinate pair', () {
      expect(
        readPickupCoordinates({'latitude': 28.6}),
        isNull,
      );
    });

    test('rejects malformed coordinate values', () {
      expect(
        readPickupCoordinates({
          'latitude': 'north',
          'longitude': 'east',
        }),
        isNull,
      );
    });

    test('rejects non-finite coordinates', () {
      expect(
        readPickupCoordinates({
          'latitude': double.nan,
          'longitude': 77.2,
        }),
        isNull,
      );
      expect(
        readPickupCoordinates({
          'latitude': 28.6,
          'longitude': double.infinity,
        }),
        isNull,
      );
    });

    test('rejects coordinates outside geographic bounds', () {
      expect(
        readPickupCoordinates({
          'latitude': 90.1,
          'longitude': 77.2,
        }),
        isNull,
      );
      expect(
        readPickupCoordinates({
          'latitude': 28.6,
          'longitude': -180.1,
        }),
        isNull,
      );
    });

    test('accepts valid geographic boundary values', () {
      final result = readPickupCoordinates({
        'latitude': -90,
        'longitude': 180,
      });

      expect(result, isNotNull);
      expect(result!.latitude, -90);
      expect(result.longitude, 180);
    });
  });
}
