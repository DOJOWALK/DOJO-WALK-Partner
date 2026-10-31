# Partner App Flow Audit — 2026-10-31

- Repository: `DOJOWALK/DOJO-WALK-Partner`
- Audit branch: `audit/partner-flow-2026-10-31`
- Compared against: `chore/notion-aligned-structure`
- Status: source-level audit only. No shared Firebase schema, rules, policy, or production behavior is approved by this document.
- Safety: no production data, deployed rules, Cloud Functions, or shared collection names were changed.

## Scope inspected

Authentication: `mobile_login_screen.dart`, `otp_screen.dart`, `account_check_screen.dart`.
Onboarding: `work_location_screen.dart`, `personal_details_screen.dart`, `live_selfie_screen.dart`, `kyc_documents_screen.dart`, `current_address_screen.dart`, `review_submit_screen.dart`, `application_submitted_screen.dart`.
Operations: `partner_home_screen.dart`, `navigation_screen.dart`, `walk_details_screen.dart`, `live_walk_screen.dart`, `schedule_screen.dart`, `working_schedule_screen.dart`, `earnings_screen.dart`, `profile_screen.dart`.

## Findings

### P1 — Partner Home booking date field mismatch risk

The inspected Customer booking contract records `scheduledAt` (and schedule structures), while Partner Home filters today's bookings using only `data['date']`. If current Customer bookings do not also materialize a compatible `date` field, valid assigned bookings can be omitted from Partner Home. This is a cross-repository contract risk, not proof of a live production failure.

Required: agree the canonical scheduled date/time fields with Customer and Firebase teams; add fixtures for one-time and recurring bookings; test timezone/day-boundary behavior before changing the query.

### P1 — Client directly writes authoritative booking lifecycle statuses

`NavigationScreen` directly updates `bookings/{bookingId}.status` to `accepted`, `picked_up`, and `walking`. The inspected flow does not first re-read and validate that the authenticated Partner is still the assigned walker, nor does it show a trusted backend transition command. Client-side UI sequencing is not an authorization boundary.

Required: Firebase team to define trusted start/arrival/pickup transition commands, allowed transitions, assignment checks, event audit records, and rules that deny unauthorized client status mutation. Do not change status strings until the approved state machine is documented.

### P1 — Automatic phone verification bypasses explicit account routing

In `MobileLoginScreen.verificationCompleted`, successful credential sign-in clears loading and shows a success message, but does not navigate to `AccountCheckScreen` as the manual OTP path does. Verify whether the app root auth gate reliably handles this path; otherwise a successfully authenticated Partner may remain on the login screen or miss pending/approved account routing.

Required: test Android automatic verification and manual OTP paths; both must converge on one account-state router. Avoid duplicating navigation logic in the callbacks.

### P1 — Onboarding service-location collection contract needs confirmation

`WorkLocationScreen` reads active service areas from the `zones` collection and expects `city`, `area`, `state`, and a zone-name field. The current company location-management design references the central location catalogue and a State/UT → District → City → Zone hierarchy. Confirm whether `zones` is a deliberate published/derived collection or an outdated parallel source. Do not rename or migrate collections from the Partner app.

Required: Firebase/Admin team to document the approved published-zone read model, document IDs, activation field, and access rules. Partner should consume that contract.

### P1 — Live Walk lifecycle remains blocked for production

The inspected Partner flow writes booking statuses from the client and Live Walk completion writes a walk record plus booking completion fields. The existing POL-007 source audit already records missing server-authoritative assignment, active-booking, pickup, handover, and idempotency validation in the inspected screen. A missing booking ID must never result in an ordinary completed operational walk without a linked booking or an explicitly approved exception.

Required: trusted backend start/complete commands, assignment and active-state validation, pickup/handover evidence, idempotency, audited events, and Emulator tests. Keep Production NO-GO until these are proven.

### P2 — Schedule screen is currently an empty-state shell

`ScheduleScreen` displays a confirmed-walk empty state and links to working availability, but does not load confirmed booking records. Home separately queries today's bookings. This creates fragmented operational visibility.

Required: once the booking schema is approved, extract a shared read-only booking repository/service and use it in Home and Schedule, with clear confirmed/pending/failed states.

### P2 — Earnings screen is intentionally unconnected

`EarningsScreen` correctly avoids fabricated balances and says verified records are pending. It currently has no ledger/payout query. This is not a UI bug; it is an integration dependency.

Required: Firebase team to provide an authoritative, auditable earnings ledger and weekly payout contract. Partner must not calculate payable amounts from client-side walk duration or customer payment documents.

### P2 — Application submission and KYC need end-to-end security validation

Onboarding screens write the Partner profile and upload identity documents/selfie to Firebase Storage. Source UI checks for required documents and application data, but this audit does not establish deployed Storage/Firestore rules, private document access, server-side verification, or a complete reviewer decision audit trail.

Required: verify owner-only upload/read paths, admin-review access, file size/type limits, immutable review evidence, correction/rejection flow, and no access to another Partner's identity documents. Do not expose document download URLs publicly.

### P2 — Working availability is distinct from assignment

The working schedule stores a weekly day/time map in the Partner document. It must not be treated as a confirmed booking or as proof of assignment. The existing UI correctly explains this distinction; backend assignment must remain authoritative.

Required: confirm schedule schema, weekly change limits and effective-time rules against approved POL-026 before integrating assignment offers.

## Duplicate-code / architecture assessment

- No safe basis found in this source pass to delete screens or collections.
- The Home booking query and Schedule empty-state are separate read paths; consolidate only after the canonical booking contract is agreed.
- Lifecycle status writes are duplicated across navigation and live-walk completion responsibilities; centralize behind trusted backend commands, not a new client-side helper that merely wraps direct writes.
- Keep existing legacy walk records and compatibility readers until backend consumers and migration behavior are audited.

## Integration owners / next actions

1. Firebase Team: canonical booking schedule fields, approved lifecycle state machine, server commands, rules and Emulator tests.
2. Customer Team: confirm current booking payload includes the canonical scheduled date/time fields for all booking types.
3. Admin Team: confirm approved zone publication/read model and live tracking source.
4. Partner Team: route automatic and manual auth through the same account gate; add tests for home date parsing and onboarding states after contracts are confirmed.
5. Product/Founder approval: finalize controlling POL-006, POL-007 and POL-026 before production lifecycle changes.

## Verification status

- Source files inspected on the audit branch's base feature branch.
- This document does not claim Flutter Analyze, full test suite, Android device QA, Emulator E2E, or production Firebase integration was run as part of this audit.
- Existing pickup-coordinate regression CI result is separate evidence and does not clear the lifecycle or cross-app integration gates.
- No PR merged; no branch deleted; no production deployment or data mutation.
