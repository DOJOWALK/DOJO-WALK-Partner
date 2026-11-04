import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_partner/features/profile/utils/partner_identity.dart';

void main() {
  group('partnerIdLabel', () {
    test('returns the assigned ID after trimming whitespace', () {
      expect(partnerIdLabel('  DW-001  '), 'DW-001');
    });

    test('returns Not assigned for null, empty and whitespace values', () {
      expect(partnerIdLabel(null), 'Not assigned');
      expect(partnerIdLabel(''), 'Not assigned');
      expect(partnerIdLabel('   '), 'Not assigned');
    });

    test('returns Not assigned for non-string values', () {
      expect(partnerIdLabel(124), 'Not assigned');
    });
  });
}
