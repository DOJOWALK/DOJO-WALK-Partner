import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_partner/features/live_walk/utils/walk_booking_reference.dart';

void main() {
  group('hasWalkBookingReference', () {
    test('accepts a non-empty booking ID', () {
      expect(hasWalkBookingReference('booking-123'), isTrue);
    });

    test('rejects null, empty, and whitespace-only IDs', () {
      expect(hasWalkBookingReference(null), isFalse);
      expect(hasWalkBookingReference(''), isFalse);
      expect(hasWalkBookingReference('   '), isFalse);
    });

    test('does not reject a valid ID with surrounding whitespace', () {
      expect(hasWalkBookingReference(' booking-123 '), isTrue);
    });
  });
}
