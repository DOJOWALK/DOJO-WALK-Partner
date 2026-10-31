/// Safe, presentation-only account status labels for the Partner app.
///
/// This mapper does not authorize access or decide navigation. Keep account
/// access checks separate and fail closed until the backend contract is final.
class AccountStatusPresentation {
  const AccountStatusPresentation._(this.label);

  final String label;

  static AccountStatusPresentation fromData(Map<String, dynamic> data) {
    final rawStatus = data['status'];
    final status = rawStatus is String
        ? rawStatus.trim().toLowerCase()
        : '';

    // Only literal booleans are accepted; strings like "true" are not flags.
    final isApproved = data['isApproved'] == true;
    final isActive = data['isActive'] == true;

    if (status == 'suspended') {
      return const AccountStatusPresentation._('Account suspended');
    }
    if (status == 'left') {
      return const AccountStatusPresentation._('Account closed');
    }

    if (status == 'approved') {
      if (isApproved && isActive) {
        return const AccountStatusPresentation._('Approved & active');
      }
      if (isApproved && !isActive) {
        return const AccountStatusPresentation._('Account inactive');
      }
      return const AccountStatusPresentation._(
        'Account status needs review — contact support',
      );
    }

    // Explicit terminal/action states must not be overwritten by flags.
    if (status == 'rejected' && !isApproved && !isActive) {
      return const AccountStatusPresentation._('Application not approved');
    }
    if (status == 'correction_required' && !isApproved && !isActive) {
      return const AccountStatusPresentation._('Correction required');
    }
    if (status == 'under_review' && !isApproved && !isActive) {
      return const AccountStatusPresentation._('Verification in review');
    }
    if (status == 'in_progress' && !isApproved && !isActive) {
      return const AccountStatusPresentation._('Application in progress');
    }
    if (status == 'pending' && !isApproved && !isActive) {
      return const AccountStatusPresentation._('Verification pending');
    }

    if (status.isEmpty) {
      return const AccountStatusPresentation._('Status unavailable');
    }

    // Legacy/unconfirmed values and contradictory flag combinations are
    // intentionally not translated into a reassuring or active state.
    return const AccountStatusPresentation._(
      'Account status needs review — contact support',
    );
  }
}
