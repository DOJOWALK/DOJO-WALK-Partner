// PROPOSAL / TEST DATA ONLY — not the approved Team 01 v0.4 DTO.
// This test-local resolver documents expected route behavior for joint review.
// Do not import this into production code or use it to infer Firestore fields.

import 'package:flutter_test/flutter_test.dart';

enum _MockOnboardingStep {
  workLocation,
  personalDetails,
  liveSelfie,
  kycDocuments,
  currentAddress,
  reviewSubmit,
}

enum _MockDestination {
  startWorkLocation,
  resumeWorkLocation,
  resumePersonalDetails,
  resumeLiveSelfie,
  resumeKycDocuments,
  resumeCurrentAddress,
  resumeReviewSubmit,
  applicationSubmitted,
  correctionTask,
  partnerHome,
  support,
}

class _MockApplication {
  const _MockApplication({
    this.status,
    this.resumeStep,
    this.isApproved,
    this.isActive,
    this.revision,
    this.expectedRevision,
    this.correctionFields = const <String>[],
  });

  final String? status;
  final _MockOnboardingStep? resumeStep;
  final Object? isApproved;
  final Object? isActive;
  final int? revision;
  final int? expectedRevision;
  final List<String> correctionFields;
}

_MockDestination _resolveMockRoute(_MockApplication? application) {
  if (application == null) return _MockDestination.startWorkLocation;

  final status = application.status?.trim().toLowerCase();
  if (status == 'approved') {
    return application.isApproved == true && application.isActive == true
        ? _MockDestination.partnerHome
        : _MockDestination.support;
  }

  if (status == 'in_progress') {
    if (application.revision == null ||
        application.expectedRevision == null ||
        application.revision != application.expectedRevision ||
        application.resumeStep == null) {
      return _MockDestination.support;
    }
    return switch (application.resumeStep!) {
      _MockOnboardingStep.workLocation =>
        _MockDestination.resumeWorkLocation,
      _MockOnboardingStep.personalDetails =>
        _MockDestination.resumePersonalDetails,
      _MockOnboardingStep.liveSelfie => _MockDestination.resumeLiveSelfie,
      _MockOnboardingStep.kycDocuments => _MockDestination.resumeKycDocuments,
      _MockOnboardingStep.currentAddress =>
        _MockDestination.resumeCurrentAddress,
      _MockOnboardingStep.reviewSubmit => _MockDestination.resumeReviewSubmit,
    };
  }

  if (status == 'correction_required') {
    return application.correctionFields.isNotEmpty &&
            application.resumeStep != null
        ? _MockDestination.correctionTask
        : _MockDestination.support;
  }

  if (status == 'under_review' ||
      status == 'pending' ||
      status == 'rejected' ||
      status == 'suspended' ||
      status == 'left') {
    return _MockDestination.applicationSubmitted;
  }

  return _MockDestination.support;
}

void main() {
  group('Onboarding route contract proposal — mock only', () {
    test('starts the first step when no application exists', () {
      expect(_resolveMockRoute(null), _MockDestination.startWorkLocation);
    });

    test('resumes each backend-provided step for a matching revision', () {
      final expected = <_MockOnboardingStep, _MockDestination>{
        _MockOnboardingStep.workLocation: _MockDestination.resumeWorkLocation,
        _MockOnboardingStep.personalDetails:
            _MockDestination.resumePersonalDetails,
        _MockOnboardingStep.liveSelfie: _MockDestination.resumeLiveSelfie,
        _MockOnboardingStep.kycDocuments: _MockDestination.resumeKycDocuments,
        _MockOnboardingStep.currentAddress:
            _MockDestination.resumeCurrentAddress,
        _MockOnboardingStep.reviewSubmit: _MockDestination.resumeReviewSubmit,
      };

      for (final entry in expected.entries) {
        expect(
          _resolveMockRoute(_MockApplication(
            status: 'in_progress',
            resumeStep: entry.key,
            revision: 4,
            expectedRevision: 4,
          )),
          entry.value,
          reason: 'resumeStep=${entry.key}',
        );
      }
    });

    test('fails closed for missing, stale, or mismatched resume data', () {
      final cases = <_MockApplication>[
        const _MockApplication(status: 'in_progress'),
        const _MockApplication(
          status: 'in_progress',
          resumeStep: _MockOnboardingStep.personalDetails,
          revision: 3,
          expectedRevision: 4,
        ),
        const _MockApplication(
          status: 'in_progress',
          resumeStep: _MockOnboardingStep.personalDetails,
          revision: 4,
        ),
      ];

      for (final application in cases) {
        expect(_resolveMockRoute(application), _MockDestination.support);
      }
    });

    test('correction route requires both a step and scoped correction fields',
        () {
      expect(
        _resolveMockRoute(const _MockApplication(
          status: 'correction_required',
          resumeStep: _MockOnboardingStep.kycDocuments,
          correctionFields: <String>['kycDocuments'],
        )),
        _MockDestination.correctionTask,
      );
      expect(
        _resolveMockRoute(const _MockApplication(
          status: 'correction_required',
          resumeStep: _MockOnboardingStep.kycDocuments,
        )),
        _MockDestination.support,
      );
      expect(
        _resolveMockRoute(const _MockApplication(
          status: 'correction_required',
          correctionFields: <String>['kycDocuments'],
        )),
        _MockDestination.support,
      );
    });

    test('only approved plus two literal true flags reaches Home', () {
      expect(
        _resolveMockRoute(const _MockApplication(
          status: 'approved',
          isApproved: true,
          isActive: true,
        )),
        _MockDestination.partnerHome,
      );
      for (final application in <_MockApplication>[
        const _MockApplication(
          status: 'approved',
          isApproved: true,
          isActive: false,
        ),
        const _MockApplication(
          status: 'approved',
          isApproved: false,
          isActive: true,
        ),
        const _MockApplication(
          status: 'approved',
          isApproved: 'true',
          isActive: 'true',
        ),
      ]) {
        expect(_resolveMockRoute(application), _MockDestination.support);
      }
    });

    test('known non-draft statuses stay on the submitted/status route', () {
      for (final status in <String>[
        'pending',
        'under_review',
        'rejected',
        'suspended',
        'left',
      ]) {
        expect(
          _resolveMockRoute(_MockApplication(status: status)),
          _MockDestination.applicationSubmitted,
          reason: 'status=$status',
        );
      }
    });

    test('unknown or malformed status fails closed to Support', () {
      for (final status in <String?>[null, '', 'unknown', 'disabled']) {
        expect(
          _resolveMockRoute(_MockApplication(status: status)),
          _MockDestination.support,
        );
      }
    });
  });
}
