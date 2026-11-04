String partnerIdLabel(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }

  return 'Not assigned';
}
