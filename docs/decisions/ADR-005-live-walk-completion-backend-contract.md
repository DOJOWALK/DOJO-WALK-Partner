# ADR-005: Live Walk Completion Backend Contract

- Status: Proposed implementation contract; not implemented.
- Depends on: ADR-002 (idempotency), ADR-003 (rules gate), ADR-004 (deployment configuration).
- Scope: Replace direct client writes to `walks` and completion fields on `bookings` with one trusted completion operation.
- Current code evidence:
  - Partner UI writes a random `walks/{randomId}` document and updates `bookings/{bookingId}` in one client batch.
  - Current repository rules have no `/walks/{walkId}` match and the assigned-walker allowlist excludes fields the batch updates.
  - The only exported callable is `checkBackend`; no completion endpoint currently exists.
  - The repository deployment config does not identify a Firestore rules file.
- Notion policy alignment check (checked 2026-10-30):
  - POL-007 — Live Walk & Safe Handover Policy is marked Draft — Founder approval required. It says the backend must validate actor, assignment, permitted state transitions and duplicate requests; completion requires safe return, authorized recipient, required handover evidence and backend validation.
  - POL-006 — Customer Booking & Eligibility Policy is marked Draft — Founder approval required. It says server state is authoritative and customer-facing “Completed” requires approved completion/handover requirements.
  - POL-026 — Walker Availability, Booking Assignment & Replacement Policy is marked Draft — not approved, implemented or tested. It requires backend-controlled transitions and idempotent retries.
  - Therefore, no exact allowed source booking status, duration limits, required evidence schema, or emergency override is treated as approved by this repository change. These must be confirmed by Founder/CEO before coding those constraints.
- Required callable contract (proposed):
  - Input: non-empty `bookingId`, stable client `completionRequestId`, walk observations (duration, distance, pee/poop counts, route, start/end location when available, start verification flags, return-location verification result).
  - Identity: derive `walkerId` exclusively from verified Firebase Auth context; never trust a client-supplied walker ID.
  - Authorization: booking must exist and its assigned `walkerId` must equal the authenticated UID; reject missing, unassigned, or differently assigned bookings.
  - State transition: only permit the policy-approved active booking status to transition to completed. The allowed source status must be confirmed against the approved Notion booking/Live Walk policy before coding.
  - Idempotency: in a Firestore transaction, check a stable booking-to-walk reference or completion request record. Repeated requests for the same completion return the existing result; do not create another walk record. A different request against an already completed booking must not create another walk.
  - Atomic persistence: create/update the walk record and booking status/timestamps in the same trusted transaction. Preserve existing legacy records and do not overwrite an existing completed walk without a reviewed migration policy.
  - Validation: bound numeric values; validate GeoPoint/route coordinates; cap route points; validate count/duration ranges; distinguish absent GPS from verified GPS; never fabricate `startedAt`.
  - Response: return stable `walkId`, booking status and whether the response is an idempotent replay. Do not return sensitive customer fields unnecessarily.
  - Audit: use server timestamps and server-side audit records where the approved schema provides them; client must not write audit logs.
- Required tests:
  1. Assigned authenticated walker completes a valid active booking.
  2. Unauthenticated caller is rejected.
  3. Wrong walker is rejected.
  4. Missing booking and unsupported booking status are rejected.
  5. Two concurrent requests for one booking produce one walk record.
  6. Retry after an ambiguous network response returns the same walk ID.
  7. Already-completed booking cannot produce a second walk.
  8. Invalid coordinates, route size, duration and counts are rejected.
  9. Missing GPS start remains explicitly unverified; no synthetic start timestamp is written.
  10. Transaction failure leaves booking and walk state unchanged.
- Release gates:
  - Confirm the exact approved Notion policy and status vocabulary.
  - Confirm shared production schema and deployed rules source.
  - Implement callable plus client integration; add Firebase Emulator tests and CI.
  - Deploy only after rules/function review and controlled staging verification.
- Safety boundary: This ADR is a contract for implementation, not evidence that the backend or production security has been fixed.
