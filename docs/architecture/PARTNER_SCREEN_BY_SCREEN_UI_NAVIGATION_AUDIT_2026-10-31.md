# Partner App Navigation & Screen-by-Screen UI Audit — 2026-10-31

## Scope
Repository DOJOWALK/DOJO-WALK-Partner, source branch chore/notion-aligned-structure. Read-only source review of primary app screens and navigation entry points. This consolidates previous feature audits; it does not replace their detailed findings.

## Screen inventory and current source status

| Area / screen | Source status | Main gap / note | Priority |
|---|---|---|---|
| Splash | Screen exists; routes into auth flow | Verify cold-start, logged-in and network/error routing on device | P2 |
| Mobile Login | OTP sign-in flow exists | Verify runtime auth errors, resend, rate limits and accessibility | P2 |
| OTP | OTP verification screen exists | Verify expiry/resend/attempt UX and duplicate submission | P1 |
| Account Check | Reads walker approval/activation state | Client gate is not a security boundary; backend/rules must enforce protected operations | P0 |
| Work Location | Zone selection screen exists | Verify active approved zones and stale/empty/error states | P1 |
| Personal Details | Form exists | Verify edit/resume behavior and validation | P2 |
| Live Selfie | Camera + ML Kit face framing exists | Face detection is not identity proof, liveness or anti-spoof verification | P1 |
| KYC Documents | Aadhaar/PAN capture/upload exists | Re-entry hydration, partial upload cleanup, reviewer privacy and retention gaps | P1 |
| Current Address | Address form exists | Verify authoritative zone/address mapping and resume state | P2 |
| Review & Submit | Submission validation and pending state exist | Server-side submission authorization and immutable review workflow need verification | P1 |
| Application Submitted | Status stream and support form exist | Support is applicant-only in current UI; no case history or response thread | P1 |
| Partner Home | Home, today's overview and work cards exist | Booking schedule contract mismatch; notification bell and leave request are placeholders | P1 |
| Schedule | Static confirmed-walk empty state | No assigned booking calendar/data stream; availability is separate | P1 |
| Working Schedule | Reads/writes walkers/{uid}.workingSchedule | No visible approval gate, effective date/change policy or assigned-walk conflict handling | P1 |
| Earnings | Static “Awaiting verified records” placeholder | No ledger, statement, payout history or dispute UI; policy remains draft | P1 |
| Profile | Profile details and personal details navigation exist | Verified badge hard-coded; KYC, support and settings are placeholders | P1 |
| Walk Details | Booking detail + navigation action exists | Directly writes booking status accepted; no explicit offer accept/decline or trusted revalidation | P1 |
| Navigation to Pickup | Progress buttons exist | Map area is a static map icon placeholder, not live route navigation; direct status writes | P1 |
| Live Walk | GPS stream, route in memory, return check, OTP fallback | Start/completion authorization, background/server GPS, trusted OTP, idempotency, emergency workflow | P0 |
| Walk Summary | Summary screen exists | Validate data source and error handling; no evidence of trusted server summary | P2 |
| Walk Completed | Summary and Done action exist | Earnings pending verification; completion backend/rules mismatch previously identified | P0 |

## Navigation map
- Bottom navigation: Home, Schedule, Earnings, Profile.
- Home booking card → WalkDetailsScreen.
- Walk Details primary action → NavigationScreen.
- Navigation flow: Mark Arrived → Mark Dog Received → Start Walk → LiveWalkScreen.
- Live Walk completion → WalkCompletedScreen; Done returns to Partner Home.
- Schedule → Manage availability → WorkingScheduleScreen.
- Profile → Personal Details works; Documents & KYC, Notification preferences, DOJO Support and Settings show Coming Soon/placeholders.
- Home notification bell shows a pending-feature message; “Need a day off?” also shows a pending-feature message.

## Consolidated critical findings

### P0 — Release blockers / resolve before live operations
1. Live walk completion batch conflicts with inspected Partner Firestore rules: no matching /walks/{walkId} allow rule was found in the inspected Partner rules, and booking update allowlist excludes completion fields. Deployed Firebase rules are unverified. Do not widen client rules to make the batch pass.
2. Live walk starts client-side without visible trusted backend validation of stable assigned occurrence, assigned walker, eligibility and allowed state. Nullable bookingId risks orphan walk records.
3. Completion is not cross-session idempotent; a new screen State generates a new random walk document ID.
4. No live-walk emergency/incident reporting UI was found.
5. Client OTP comparison is not a trusted, one-time, rate-limited backend consume operation.

### P1 — Functional and integration gaps
1. Customer booking writes scheduledAt, preferredTime, walkSchedules, selectedDates/dateSchedules; Partner Home filters only legacy date and sorts startTime. Assigned walks can be omitted.
2. No explicit booking offer inbox / Accept / Decline / expiry UI; Navigate action currently also updates status to accepted.
3. Schedule tab is not an assigned-work calendar.
4. Working Schedule writes availability directly; no visible approved/active eligibility check or conflict/change governance.
5. Earnings and payout are placeholders; POL-013 and POL-033/034 remain drafts, so do not hard-code rates, incentives or payout cadence.
6. FCM client integration and push delivery path were not found; Home bell and Profile preferences are placeholders.
7. Approved Partner Support is a placeholder; only pre-approval support form writes a request.
8. Profile displays a hard-coded “Verified” badge; status mapping is inconsistent with Account Check.
9. KYC upload/resume, privacy and reviewer authorization need end-to-end verification.
10. Navigation map is a static icon placeholder; no turn-by-turn route or live map implementation is evidenced in that screen.

### P2 — UX quality and resilience
1. Add explicit loading, retry, empty, permission-denied, offline and stale-data states consistently.
2. Audit silent catches/default profile fallbacks so network/permission errors are not presented as valid empty data.
3. Verify accessibility: text scaling, contrast, touch targets, semantics and TalkBack.
4. Verify Android back handling, app lifecycle/resume, deep links and session expiry across flows.
5. Confirm time formatting, timezone and service-local date display.
6. Validate duplicate taps, slow network, interrupted uploads and process death.

## Screen-by-screen QA checklist
- [ ] Splash: cold launch, warm launch, signed-out, signed-in approved, pending, suspended, network timeout.
- [ ] Login/OTP: invalid number, wrong/expired OTP, resend cooldown, repeated taps, auth offline.
- [ ] Account Check: every status combination; protected backend calls denied when not approved/active.
- [ ] Onboarding: save/resume each step, camera/storage denial, partial upload failure, duplicate submit, correction request.
- [ ] Home: immediate, one-time scheduled, selected multi-date and regular daily/multiple-walk fixtures; empty vs failed load.
- [ ] Offer: accept, decline, expired, superseded, concurrent accept, duplicate tap, replacement.
- [ ] Schedule: upcoming/past/active/cancelled assignments; separate availability; timezone and overnight policy.
- [ ] Working Schedule: pending/unapproved account, assigned conflict, approved change limit/effective date, offline save.
- [ ] Earnings: only backend-verified ledger items; adjustments, hold, failed payout, paid receipt, dispute.
- [ ] Profile: accurate approval/KYC state; secure document access; support case history; logout/token cleanup.
- [ ] Navigation: real map/route or approved non-map experience; permission denial and pickup coordinate errors.
- [ ] Live Walk: server start token, GPS freshness/background behavior, route gaps, app kill/restart, emergency action, safe handover, trusted OTP, exactly-once completion.
- [ ] Summary/Completed: server-confirmed values, retry-safe completion, no misleading payout confirmation.
- [ ] Cross-cutting: notification permission, push and inbox, offline queue, privacy redaction, audit logs.

## Duplicate-code / cleanup guardrails
- This audit does not authorize deleting or moving source files. First build a route/import/reference graph and tests; then consolidate one feature at a time.
- Keep one canonical booking occurrence contract shared by Customer, Partner, Admin and Firebase. Do not add another Partner-only booking schema.
- Keep support, incident, notifications and earnings collections backend-owned with explicit contracts and rules. Do not create duplicate collections or broaden client permissions as a shortcut.
- Keep feature-specific detailed audit docs as evidence; this consolidated matrix is the single navigation/UI backlog index, not a replacement for source audits.

## Evidence references
- PARTNER_HOME_BOOKING_SCHEDULE_CONTRACT_AUDIT_2026-10-31.md
- PARTNER_AVAILABILITY_SCHEDULE_POLICY_AUDIT_2026-10-31.md
- PARTNER_EARNINGS_PAYOUT_UI_AUDIT_2026-10-31.md
- PARTNER_PROFILE_KYC_VERIFICATION_AUDIT_2026-10-31.md
- PARTNER_BOOKING_OFFER_ASSIGNMENT_ACCEPTANCE_AUDIT_2026-10-31.md
- PARTNER_LIVE_WALK_GPS_HANDOVER_AUDIT_2026-10-31.md
- PARTNER_NOTIFICATIONS_PUSH_DELIVERY_AUDIT_2026-10-31.md
- PARTNER_SUPPORT_EMERGENCY_INCIDENT_PRIVACY_AUDIT_2026-10-31.md

## Verification boundary
Findings are source-level observations from the named branch and previously inspected Firebase repository files. No full Flutter analyze/test/build, emulator suite, device QA, accessibility run, deployed-rules inspection or production workflow verification was run for this consolidated audit. No CI status is claimed. No app source, Firebase data/rules, or deployment was changed.
