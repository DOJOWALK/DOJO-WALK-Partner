String partnerProfileVerificationLabel({
  required dynamic status,
  required dynamic isApproved,
  required dynamic isActive,
}) {
  final normalizedStatus =
      status is String ? status.trim().toLowerCase() : '';

  if (normalizedStatus == 'approved' &&
      isApproved == true &&
      isActive == true) {
    return 'Verified Partner';
  }

  if (normalizedStatus == 'under_review') {
    return 'Under review';
  }

  if (normalizedStatus == 'in_progress') {
    return 'Application in progress';
  }

  return 'Verification status unavailable';
}
