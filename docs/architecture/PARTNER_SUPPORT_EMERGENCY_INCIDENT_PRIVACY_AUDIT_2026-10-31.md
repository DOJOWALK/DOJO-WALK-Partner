# Partner Support, Emergency, Incident & Customer Contact Privacy Audit — 2026-10-31

## Scope and evidence
- Partner repository: `DOJOWALK/DOJO-WALK-Partner`, source branch `chore/notion-aligned-structure`.
- Firebase repository: `DOJOWALK/DOJO-WALK-Firebase`, branch `main`, checked-in `firestore.rules`.
- Inspected:
  - Partner `lib/screens/home/profile_screen.dart`
  - Partner `lib/screens/home/partner_home_screen.dart`
  - Partner `lib/features/onboarding/screens/application_submitted_screen.dart`
  - Partner `lib/features/live_walk/screens/live_walk_screen.dart`
  - Partner `firestore.rules`
  - Firebase `firestore.rules`
- Read-only audit. No source, Firestore data/rules, or deployment changed.

## 1. Support flow

### Evidence
- Before approval, `ApplicationSubmittedScreen` has a Help & Support dialog with categories Application Status, KYC Documents, Personal Details and Other; free-text message is limited to 1,000 characters.
- It creates `support_requests/{autoId}` with `userId`, `walkerId`, category, message, status=open and server timestamps.
- Firebase repository `main/firestore.rules` contains a matching `support_requests` rule:
  - signed-in user only;
  - userId and walkerId must equal auth UID;
  - category allowlist;
  - message 1–1,000 characters;
  - initial status open and timestamps equal request.time;
  - requester/admin can read; only admin can update/delete.
- The Partner repository's own checked-in `firestore.rules` has no `support_requests` match and ends in default deny.
- After onboarding, Partner `ProfileScreen` shows “DOJO Support” but tapping it only displays “DOJO Support will be available here.”
- No support request history, case ID, response thread, status tracking, attachment support or escalation UI was found.

### Findings
- P1: Support works only in the pre-approval application screen; the approved/active Partner profile has a dead-end Support entry.
- P1: Rules differ across repositories. The Firebase main rules allow the support request schema; Partner repo rules do not. Do not deploy Partner rules over the Firebase rules or assume both are interchangeable.
- P2: Submit success confirms the Firestore create operation only; it does not show a case reference, response SLA or who owns the request.
- P2: No evidence of support response/closure lifecycle in Partner UI.

## 2. Emergency and incident reporting

### Evidence
- Search of Partner source for incident and emergency workflow identifiers found no incident-report screen/service or emergency action.
- `LiveWalkScreen` has GPS permission/tracking, return-location check and OTP fallback; it has no visible emergency button for dog escape/missing, bite/injury, walker/customer injury, unsafe handover, customer unavailable or GPS/network failure.
- `walkers/{uid}` schema/rules mention an `emergencyContact` profile field, but no emergency contact use was found in the inspected live-walk or profile screens.
- Firebase `firestore.rules` contains no `incidents` collection match. Default deny applies unless a separately deployed backend/admin SDK path exists.

### Findings
- P0/P1 release blocker: No in-app incident reporting path was found during a live walk. A normal walk completion flow is not a safe substitute for an emergency workflow.
- P1: No evidence of emergency contact display/use, one-tap call/escalation, incident acknowledgement, incident ID, evidence upload or follow-up status.
- P1: No incident collection contract/rules or trusted backend workflow was found in the checked Firebase rules.
- P2: No defined offline fallback or explicit instruction when the app/network/GPS fails during an emergency.

## 3. Customer contact and privacy

### Evidence
- Partner's booking detail and live-walk screens use bookingId, dog name, pickup location and coordinates for walk execution.
- The inspected Partner screens do not show a dedicated customer phone/contact action, masking policy, click-to-call flow or contact-access audit.
- Firestore booking reads in Firebase rules permit an assigned walker to read their assigned booking document. This is document-level access; rules do not automatically hide individual customer fields within that document.
- No customer phone number was identified in the inspected Partner screen extracts, but this limited audit does not establish that no personal contact data exists in all booking documents or other app paths.

### Findings
- P1: Need a field-level data minimization contract for Partner booking reads. A walker should receive only the minimum operational fields needed for the assigned walk; do not rely on UI hiding to protect fields in a readable Firestore document.
- P1: No approved customer-contact policy or masked relay/call workflow was evidenced in Partner UI. Do not expose raw customer phone numbers by default.
- P1: Pickup address and precise coordinates are sensitive; they should be available only for the assigned occurrence and only when operationally necessary, with retention/access controls.
- P2: Customer contact attempt, purpose, time and outcome should be auditable if a contact feature is later approved.

## 4. Recommended design (proposal only)

1. Add a persistent Partner Support area after login: create case, view case ID, status, response and conversation; preserve the existing pre-approval support flow.
2. Add an always-visible emergency action during an active walk, with distinct incident types and clear severity:
   - dog missing/escape;
   - dog bite/injury or sudden illness;
   - walker/customer injury or threat;
   - customer unavailable / unsafe recipient / handover blocked;
   - GPS/network/device failure;
   - other urgent safety concern.
3. Emergency flow must not require the normal walk-completion path. Capture occurrenceId/walkId, time, last known location and GPS freshness, category, description and optional evidence; create incident through trusted backend with stable idempotency key.
4. Show clear instructions and an acknowledgement/reference ID; notify Central/Admin and designated emergency contacts through approved channels. Provide a fallback phone/contact path configured by the company, not a hard-coded personal number.
5. For customer contact, prefer an approved masked relay or in-app contact channel. Reveal only what is necessary, only to the assigned and eligible Walker, for a bounded time window. Record access and contact events.
6. Define least-privilege data contract for assigned walk occurrence; keep KYC, Aadhaar/PAN, bank details, OTP secrets and unrelated customer profile data inaccessible to Partner.
7. Add offline emergency behavior: retain a local draft, display configured emergency instructions/contact path, retry idempotently when connectivity returns, and clearly state whether the report reached DOJO.
8. Keep emergency notices mandatory even if optional notification preferences are disabled.

## 5. Required tests / release gates

- Approved Partner can submit and track support request; unapproved applicant can still use onboarding support.
- Rules parity test proves the intended deployed rules support the Partner support schema without deploying the Partner repo's default-deny rules accidentally.
- Non-owner cannot read another Partner's support requests; Partner cannot change status/close own case.
- Emergency report can be created once despite retry/double tap; backend assigns stable incident ID and acknowledges receipt.
- Incident alert reaches Admin/Central; failed push has an alternate operational escalation.
- Emergency reporting works during active GPS tracking and does not silently mark the walk complete.
- Test dog escape, bite/injury, unsafe handover, customer unavailable, GPS outage, offline device and app restart.
- Partner cannot read unassigned bookings, other customers' profile data, KYC, bank data or OTP secrets.
- Assigned Partner can read only the approved booking/occurrence fields; test raw document fields, not merely rendered UI.
- Customer phone is masked/withheld unless a separately approved relay workflow authorizes access; log every authorized contact event.
- Verify retention/deletion, access logs, evidence access and incident visibility permissions.

## 6. Ownership and verification boundary

- Partner Team: support UI, emergency UI, safe contact UX and local/offline behavior.
- Firebase Team: support/incident schemas, trusted create/dispatch, authorization, idempotency, privacy field contract and deployed rules.
- Admin Team: case queue, incident acknowledgement/escalation, resolution and audit trail.
- Product/Founder approval required for emergency categories, contact policy, escalation roster, retention and response expectations.
- This is a checked-in source audit, not a production security certification. No deployed-rules fetch, emulator tests, app build, Flutter analyze, device test or incident drill was run. No CI status is claimed.
