/// Pure client-side navigation guard for the existing Partner Home route.
///
/// This is a UX gate only; backend operations must independently authorize
/// the authenticated Partner. It intentionally implements only the existing
/// strict three-field rule and does not define the onboarding status contract.
class PartnerHomeAccessGate {
  const PartnerHomeAccessGate._();

  static bool canEnter({
    required String status,
    required Object? isApproved,
    required Object? isActive,
  }) {
    return status.trim().toLowerCase() == 'approved' &&
        isApproved == true &&
        isActive == true;
  }
}
