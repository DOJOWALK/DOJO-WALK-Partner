# ADR-003: Firestore Rules Gate for Live Walk Completion

- Status: Confirmed security/configuration gap; remediation design required before release.
- Scope: Partner Live Walk completion writes to `walks/{walkId}` and updates `bookings/{bookingId}`.
- Evidence inspected on branch `chore/notion-aligned-structure`:
  1. `firestore.rules` defines a `/bookings/{bookingId}` match but has no `/walks/{walkId}` match. The final recursive default-deny rule denies all other reads and writes, so a client write to `walks` is denied by these rules.
  2. The assigned-walker booking update allowlist currently permits only `status`, `updatedAt`, `walkSchedules`, `walkNotes`, `peeCount`, `poopCount`, `distance`, and `durationActual`. The current Live Walk batch also writes `completedAt`, `dogReturned`, and `returnLocationVerified`, so that booking update does not satisfy the allowlist. A batch is atomic; if either write is denied, the batch fails.
  3. `functions/index.js` currently exports only the authenticated `checkBackend` callable. It does not implement a trusted Live Walk completion transition.
- Impact: The current client completion batch is incompatible with the inspected rules. Do not assume production Live Walk completion works. This is a repository rules inspection, not a claim that these exact rules are deployed to the Firebase project.
- Required remediation before release:
  1. Confirm which rules file is actually deployed and capture the deployed rules/version.
  2. Design a trusted, authenticated completion endpoint or a carefully constrained rules-based transition. Prefer backend-controlled atomic state transitions for duplicate prevention and authoritative status.
  3. Verify booking ownership/assignment, allowed source status, payload field types, valid timestamps/coordinates, and that one booking cannot create multiple completed walk records.
  4. Keep customer-owned data private; avoid broad `allow write` grants or a permissive `walks` rule.
  5. Add Firestore Rules Unit Tests / Emulator tests for authorized walker, wrong walker, unauthenticated user, missing booking, already-completed booking, duplicate completion, and atomic failure.
  6. Test on the emulator before deployment, then verify the deployed rules and callable behavior in a controlled environment.
- Safety note: Do not weaken default-deny or broaden client write permissions merely to make the current UI pass. Align implementation, policy, backend and tests first.
