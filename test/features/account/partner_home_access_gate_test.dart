import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_partner/features/account/partner_home_access_gate.dart';

void main() {
  group('PartnerHomeAccessGate', () {
    test('allows only approved with both literal true flags', () {
      expect(
        PartnerHomeAccessGate.canEnter(
          status: 'approved',
          isApproved: true,
          isActive: true,
        ),
        isTrue,
      );
    });

    test('normalizes status whitespace and case without relaxing flags', () {
      expect(
        PartnerHomeAccessGate.canEnter(
          status: ' APPROVED ',
          isApproved: true,
          isActive: true,
        ),
        isTrue,
      );
    });

    test('blocks every non-approved status', () {
      for (final status in <String>[
        'in_progress',
        'pending',
        'under_review',
        'correction_required',
        'rejected',
        'suspended',
        'inactive',
        'left',
        '',
        'unknown',
      ]) {
        expect(
          PartnerHomeAccessGate.canEnter(
            status: status,
            isApproved: true,
            isActive: true,
          ),
          isFalse,
          reason: 'status=$status must not enter Home',
        );
      }
    });

    test('blocks when either approval flag is false or missing', () {
      for (final flags in <({Object? approved, Object? active})>[
        (approved: false, active: true),
        (approved: true, active: false),
        (approved: false, active: false),
        (approved: null, active: true),
        (approved: true, active: null),
      ]) {
        expect(
          PartnerHomeAccessGate.canEnter(
            status: 'approved',
            isApproved: flags.approved,
            isActive: flags.active,
          ),
          isFalse,
        );
      }
    });

    test('does not coerce string booleans', () {
      expect(
        PartnerHomeAccessGate.canEnter(
          status: 'approved',
          isApproved: 'true',
          isActive: 'true',
        ),
        isFalse,
      );
    });
  });
}
