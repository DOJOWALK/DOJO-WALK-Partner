import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_partner/features/profile/profile_verification_status.dart';

void main() {
  group('partnerProfileVerificationLabel', () {
    test('shows verified only for approved status and literal true flags', () {
      expect(
        partnerProfileVerificationLabel(
          status: 'approved',
          isApproved: true,
          isActive: true,
        ),
        'Verified Partner',
      );
    });

    test('normalizes approved status whitespace and case', () {
      expect(
        partnerProfileVerificationLabel(
          status: ' APPROVED ',
          isApproved: true,
          isActive: true,
        ),
        'Verified Partner',
      );
    });

    test('does not verify when either approval flag is false or missing', () {
      for (final values in [
        (true, false),
        (false, true),
        (null, true),
        (true, null),
        ('true', true),
        (true, 'true'),
      ]) {
        expect(
          partnerProfileVerificationLabel(
            status: 'approved',
            isApproved: values.$1,
            isActive: values.$2,
          ),
          'Verification status unavailable',
        );
      }
    });

    test('shows under-review state without implying verification', () {
      expect(
        partnerProfileVerificationLabel(
          status: 'under_review',
          isApproved: false,
          isActive: false,
        ),
        'Under review',
      );
    });

    test('shows in-progress state without implying verification', () {
      expect(
        partnerProfileVerificationLabel(
          status: 'in_progress',
          isApproved: false,
          isActive: false,
        ),
        'Application in progress',
      );
    });

    test('does not infer a label for unknown or missing states', () {
      expect(
        partnerProfileVerificationLabel(
          status: 'suspended',
          isApproved: true,
          isActive: false,
        ),
        'Verification status unavailable',
      );
      expect(
        partnerProfileVerificationLabel(
          status: null,
          isApproved: true,
          isActive: true,
        ),
        'Verification status unavailable',
      );
    });
  });
}
