# ADR-002: Live Walk Idempotency and Duplicate-Record Prevention

- Status: Proposed; implementation is not approved or validated yet.
- Scope: Partner app Live Walk completion writes to Firestore `walks` and updates the related `bookings` document.
- Context: The current screen creates a random `walks` document ID when its State object is initialized. A retry in the same screen reuses that ID, but a newly created screen instance can generate a different ID for the same booking. This means client-side batch writes alone do not guarantee one walk record per booking across screen recreation, process restart, or concurrent sessions.
- Decision direction: Treat a booking's walk completion as an idempotent state transition, not merely as a client-side pair of writes. The trusted backend should enforce the one-active/one-completed-walk invariant with an atomic transaction or equivalent conditional operation. A stable booking-to-walk reference may be used, but must be designed alongside existing legacy records and migration behavior.
- Required safeguards before implementation:
  1. Inspect Firestore rules and backend consumers of `walks` and `bookings`; do not assume the client can safely enforce all invariants.
  2. Define behavior for an existing completed walk, an already-completed booking, a missing booking document, a failed commit, and a retry after an ambiguous network response.
  3. Preserve existing legacy random-ID walk records; do not silently overwrite a completed walk or create a second one when retrying.
  4. Keep safety/handover records and incident escalation available even when a booking-state conflict occurs; never report completion as successful unless the authoritative write confirms it.
  5. Add tests for repeated taps, screen recreation, duplicate sessions, concurrent completion attempts, failed batch/transaction, and retry after an uncertain response.
- Current implementation: The client writes the walk record and booking completion in one Firestore batch when a trimmed booking ID is present. This prevents a partial pair of writes within that batch, but does not by itself prevent duplicates across different screen instances.
- Release gate: This ADR is not a production guarantee. Do not mark duplicate prevention complete until the trusted state transition, rules, automated tests, and Firebase emulator/device validation are evidenced.
