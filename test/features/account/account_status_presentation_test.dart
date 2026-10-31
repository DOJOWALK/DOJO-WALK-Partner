import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_partner/features/account/account_status_presentation.dart';

void main() {
  group('AccountStatusPresentation', () {
    final cases = <({String name, Map<String, dynamic> data, String label})>[
      (
        name: 'approved and active',
        data: {'status': 'approved', 'isApproved': true, 'isActive': true},
        label: 'Approved & active',
      ),
      (
        name: 'approved but inactive',
        data: {'status': 'approved', 'isApproved': true, 'isActive': false},
        label: 'Account inactive',
      ),
      (
        name: 'approved flags both false',
        data: {'status': 'approved', 'isApproved': false, 'isActive': false},
        label: 'Account status needs review — contact support',
      ),
      (
        name: 'approved but active flag only',
        data: {'status': 'approved', 'isApproved': false, 'isActive': true},
        label: 'Account status needs review — contact support',
      ),
      (
        name: 'under review',
        data: {'status': 'under_review'},
        label: 'Verification in review',
      ),
      (
        name: 'correction required',
        data: {'status': 'correction_required'},
        label: 'Correction required',
      ),
      (
        name: 'rejected',
        data: {'status': 'rejected'},
        label: 'Application not approved',
      ),
      (
        name: 'suspended',
        data: {'status': 'suspended'},
        label: 'Account suspended',
      ),
      (
        name: 'left',
        data: {'status': 'left'},
        label: 'Account closed',
      ),
      (
        name: 'in progress',
        data: {'status': 'in_progress'},
        label: 'Application in progress',
      ),
      (
        name: 'pending',
        data: {'status': 'pending'},
        label: 'Verification pending',
      ),
      (
        name: 'missing status',
        data: <String, dynamic>{},
        label: 'Status unavailable',
      ),
      (
        name: 'unknown status',
        data: {'status': 'awaiting_manual_review'},
        label: 'Account status needs review — contact support',
      ),
      (
        name: 'under review with active flags',
        data: {'status': 'under_review', 'isApproved': true, 'isActive': true},
        label: 'Account status needs review — contact support',
      ),
      (
        name: 'rejected with active flags',
        data: {'status': 'rejected', 'isApproved': true, 'isActive': true},
        label: 'Account status needs review — contact support',
      ),
      (
        name: 'suspended with active flags',
        data: {'status': 'suspended', 'isApproved': true, 'isActive': true},
        label: 'Account suspended',
      ),
      (
        name: 'correction required with active flags',
        data: {'status': 'correction_required', 'isApproved': true, 'isActive': true},
        label: 'Account status needs review — contact support',
      ),
      (
        name: 'left with active flags',
        data: {'status': 'left', 'isApproved': true, 'isActive': true},
        label: 'Account closed',
      ),
    ];

    for (final item in cases) {
      test('maps ${item.name}', () {
        expect(
          AccountStatusPresentation.fromData(item.data).label,
          item.label,
        );
      });
    }

    test('normalizes status whitespace and case', () {
      expect(
        AccountStatusPresentation.fromData({
          'status': '  UNDER_REVIEW ',
        }).label,
        'Verification in review',
      );
    });

    test('does not treat string booleans as true', () {
      expect(
        AccountStatusPresentation.fromData({
          'status': 'approved',
          'isApproved': 'true',
          'isActive': 'true',
        }).label,
        'Account status needs review — contact support',
      );
    });

    test('does not let applicationSubmitted override missing status', () {
      expect(
        AccountStatusPresentation.fromData({
          'applicationSubmitted': true,
        }).label,
        'Status unavailable',
      );
    });

    test('does not treat disabled as a confirmed suspended alias', () {
      expect(
        AccountStatusPresentation.fromData({'status': 'disabled'}).label,
        'Account status needs review — contact support',
      );
    });
  });
}
