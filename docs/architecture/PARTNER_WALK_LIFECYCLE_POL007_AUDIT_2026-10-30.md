# Partner Walk Lifecycle vs POL-007 — Source Audit

- Checked: 2026-10-30
- Status: Draft technical audit; no production schema or behavior approval.
- Notion evidence: [Cross-App Live Tracking & Booking Data Contract — Readiness](https://app.notion.com/p/409756abedb9811bad58c5aea088be62?pvs=204)
- Controlling policy: [POL-007 — Live Walk & Safe Handover](https://app.notion.com/p/404756abedb981e39c4fce3b3cb47457?pvs=204), currently Draft — Founder approval required.

## Source reviewed

Repository: `DOJOWALK/DOJO-WALK-Partner`  
Branch: `chore/notion-aligned-structure`  
File: `lib/features/live_walk/screens/live_walk_screen.dart`  
Blob: `f035fa3410500ea9c798955c92e93c075a4e6132`

## Findings

### Start path

- The screen requests device location permission, checks GPS availability and starts its location stream after an accepted GPS fix.
- In this screen, no server-authoritative validation is demonstrated for current walker assignment, booking active/not-cancelled status, required pickup identity/recipient/safety checks or duplicate start protection.
- `bookingId` is nullable on the widget. The inspected start path does not reject a missing booking reference before GPS tracking begins.

### Completion path

- `_endWalk()` writes a `walks/{walkId}` record from the client.
- When a booking ID exists, the client batches the walk write with an update setting `bookings/{bookingId}.status` to `completed` and writing completion/handover fields.
- No trusted backend validation is visible in this screen for current assignment, allowed lifecycle transition, authorized recipient, required handover evidence or idempotency.
- When bookingId is missing, the inspected code writes a completed walk record without a booking link. This can create an orphan operational record.

## POL-007 requirements not demonstrated by this screen

- Backend must validate authenticated assigned walker and active booking before start.
- Required pickup identity, recipient and safety checks must be captured before start.
- Start, pause/resume, completion and handover events must be server-recorded and auditable.
- Backend must validate every state transition and reject duplicate requests.
- Completion requires safe return and authorized handover; elapsed time alone is not enough.
- Client must not set authoritative booking status directly.

## Required work after policy and schema approval

- [ ] Define canonical lifecycle states and permitted transitions in Notion/data dictionary.
- [ ] Require a booking reference for normal walks; define any manual/legacy exception explicitly.
- [ ] Add a trusted backend start command with assignment, booking state, pickup-check and idempotency guards.
- [ ] Add a trusted backend completion command with recipient/handover validation and idempotency.
- [ ] Deny client writes to authoritative booking status/completion fields in Firestore Rules.
- [ ] Add Rules/Functions Emulator tests for missing booking ID, wrong/reassigned walker, cancelled booking, incomplete pickup checks, unauthorized handover, duplicate completion and retry after network failure.
- [ ] Verify completion cannot create duplicate payout/notification events.

## Release gate

**NO-GO for production lifecycle integration.** This audit records source evidence only. It does not authorize changing draft policy, Firestore Rules, collections or production data. Do not invent status names or bypass approval.