/// Validates that a Partner walk has a usable parent booking reference.
///
/// This is a fail-closed guard only; it does not validate assignment or task
/// authorization, which must be enforced by the approved backend contract.
bool hasWalkBookingReference(String? bookingId) =>
    bookingId != null && bookingId.trim().isNotEmpty;
