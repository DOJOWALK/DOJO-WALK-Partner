# Partner / Walker UI — Notion Alignment Checklist

Canonical reference: [DOJO WALK — Unified UI/UX Design System](https://app.notion.com/p/405756abedb9819db5abcb5196a2f23d)

## Design direction
Modern Premium, minimal, action-first mobile UI. Live Walk is map-centric; keep the most important action obvious and safety controls clear.

## Shared tokens
- Orange: #FF7900
- Warm background: #FFFAF5
- Primary text: #252525
- White surfaces, subtle borders/shadows, readable typography, rounded cards and consistent icon style.
- Motion should be purposeful and should not block critical actions.
- Use shared orange-alpha tokens for brand/accent surfaces instead of one-off warm hex values.
- Keep semantic status colors (success, warning, error, disabled) meaningful; do not recolor status indicators orange merely to force brand consistency.

## Partner screen requirements
- Home: real next walk, current status, availability, next best action, no fabricated metrics.
- Schedule: today's assigned walks, clear confirmed/pending distinctions, availability management.
- Onboarding: applicant/review/verified status; do not allow work before required checks, training and authorized activation.
- Booking offers: clearly show offer vs accepted assignment; prevent duplicate/ambiguous actions.
- Live Walk: map/route, booking and pet instructions, GPS freshness, safe start/complete flow, return/handover confirmation and incident reporting.
- Earnings: verified records only; separate earnings from customer payment; show payout status from trusted data.
- Profile/support/incidents: clear status and permission-aware access, minimal customer data exposure.

## Required states
Loading, empty, error, permission denied, pending/review, disabled action with reason, and confirmed success. Do not show success until trusted operation confirms it. Do not substitute query failures with zero amounts or fake booking data.

## Policy dependencies
- POL-025 — Walker recruitment, verification, onboarding and training.
- POL-026 — Walker availability, booking assignment and replacement.
- POL-013 — Walker earnings and payout.
Draft policies remain draft; this document does not approve business rules.

## Screen-by-screen implementation audit

### Reviewed / changed in the working branch
- [x] Shared Material 3 theme tokens added for orange, warm background, primary/muted text and borders.
- [x] Mobile login and OTP screens use the shared warm background and shared neutral border/background tokens where applicable.
- [x] Account-check screen uses shared background/border tokens for reviewed neutral surfaces.
- [x] Work-location, KYC document, live-selfie, current-address, review-submit and application-submitted screens use shared background/border tokens for reviewed neutral surfaces; selected/accent surfaces in work-location, KYC documents and current-address now use shared orange-alpha tokens.
- [x] Schedule screen no longer fabricates booking cards; it explains that confirmed walks appear when available.
- [x] Home distinguishes booking-query failure from a genuinely empty day, shows a retry action, and avoids displaying zero walk/hour metrics while the query is unavailable.
- [x] Home no longer claims a fixed “Working” state; it reflects whether a schedule is configured and offers a Manage action.
- [x] Notification and leave-request placeholder taps now explain that the feature is not available yet instead of doing nothing.
- [x] Fixed CI-discovered invalid `const DojoPartnerTheme.*` references in Live Walk and Profile. Run 210 passed analysis and tests after adding the missing-booking-ID regression test; its APK build was still in progress at last check.
- [x] Earnings screen no longer displays sample balances or fake ledger entries.
- [x] Walk completion no longer displays a default ₹0 or an unverified payout amount; it clearly says earnings appear after verification in the Earnings screen.
- [x] Added a widget regression test to ensure walk completion shows pending verification and not `₹0.00` when no verified payout is supplied.
- [x] Working-schedule days default to off until the Partner explicitly selects availability.
- [x] Placeholder Partner/Walker ID removed from reviewed home/profile UI.
- [x] Live Walk neutral surfaces and Partner Profile borders use the shared theme tokens.
- [x] Pickup navigation prevents progress when the booking ID is missing, shows a support message, and has a regression widget test.
- [x] Walk Details now blocks pickup navigation when the booking ID is missing or the booking status update fails; the button shows an in-progress state while confirming. Added a widget regression test for the missing-ID case. The first two runs exposed a test-only off-screen ListView action issue; the test now scrolls before tapping. CI runs `40932226817` and `40932267505` completed successfully: Flutter analysis, widget tests, release APK build, and artifact upload all passed. Both runs uploaded `dojo-walk-partner-release-apk` (~43.5 MB; artifacts expire 2026-11-05).
- [x] Live Walk timer now starts only after the first valid GPS position is accepted, rather than counting time while GPS is still waiting for its first fix. This is a source-level safety improvement; verify the new head in CI and on a physical device before treating it as fully validated.
- [x] Return-location GPS validation now rejects non-finite coordinates, out-of-range latitude/longitude, non-finite or negative accuracy, and accuracy worse than 35 metres before comparing the return point. CI/device validation for the current head is still pending.
- [x] Walk-save retry no longer starts the elapsed-time timer if the walk never received its first valid GPS fix; an already-started walk resumes its timer while the Partner retries saving. This is source-level validation only; current-head CI and physical-device checks are still required.
- [x] When a booking ID exists, Live Walk now writes the completed walk record and booking completion status in one Firestore batch to avoid a partial success state if one write fails. Legacy/missing-booking-ID routes still preserve the walk record for handover safety; upstream navigation should prevent these routes. Current-head CI, Firestore rules, and device tests remain required.
- [x] Live Walk no longer invents `startedAt` using the completion time when no valid first GPS fix was ever received. It omits `startedAt` in that case and records `startTimeVerified` / `gpsTrackingStarted` flags so the saved record does not falsely imply GPS-confirmed timing. This is a source change only until current-head CI and backend consumers are checked.
- [x] Live Walk now trims the booking ID before customer-location lookup, OTP lookup, and persistence. Whitespace-only IDs are treated as missing rather than accidentally sent to OTP or written as a booking ID. This is source-level validation only; current-head CI and Firebase/backend integration checks remain required.
- [x] CI for Live Walk booking-ID normalization exposed a duplicate local `bookingId` declaration in `_endWalk` (`flutter analyze`: duplicate definition at line 777). Removed the redundant second declaration in commit `388b7c2c781e671d00551ecc972ee50aa443255e`. The fix is awaiting a fresh CI run; tests/APK build have not yet been confirmed for this head.
- [x] Reviewed duplicate Live Walk record risk: `_walkDocumentId` is random per screen instance, so the same booking can receive another walk document ID after screen recreation. Added proposed ADR-002 documenting the idempotency invariant, legacy-record safeguards, required failure/retry cases and release gates. This is a documented risk/decision direction only; duplicate prevention is not implemented or verified.
- [x] Pickup navigation map placeholder, action panel border, slider surface and slider border use shared theme tokens.
- [x] Walk Details information notice now uses shared orange-alpha and border tokens instead of one-off hex colors.
- [x] Walk Completed, Personal Details, Earnings, and Home review/setup prompt accent surfaces now use shared orange-alpha tokens instead of one-off warm hex colors.
- [x] Splash screen background, loading indicator and branding text use shared theme tokens.
- [x] Theme-token/widget tests passed on PR-head CI; later earnings and Walk Details changes were also validated by their completed workflows (see run evidence below).

### Not yet verified / remaining
- [ ] Inspect every authentication and onboarding screen for all visual states, accessibility, responsive layout and consistent spacing; remaining hard-coded semantic/status colors need review.
- [ ] Verify account status routing against approved POL-025 rules; do not infer verification/activation from UI alone.
- [ ] Review booking offers, walk start/complete, GPS permissions/freshness, incidents, notifications, profile and support.
- [x] GitHub Actions run 205 for commit `3d4da0ffb8e162f5b8c217d5ba620792dfa64620`: Flutter analysis, Flutter tests, release APK build, and APK artifact upload all completed successfully. Artifact: `dojo-walk-partner-release-apk` (about 43.5 MB; expires 2026-11-05). This verifies that earlier commit only, not the latest UI edits.
- [x] Run 213 (`40926210293`) for app-code commit `110bc7bf005f9b1fe43ed1e1ac60a2c00ae3d3a9` completed successfully: analysis, tests, release APK build and artifact upload passed. Artifact `dojo-walk-partner-release-apk` is about 43.5 MB and expires 2026-11-05.
- [x] Run `40927287906` for walk-completion UI commit `62bb8da51f1dbc3b51b95d7ac82892896e481f7c` completed successfully.
- [x] Run `40927504431` for regression-test commit `b7efa959ff5c8e20e8accd6ad23b721c975542a8` completed successfully: Flutter analysis, tests, release APK build and artifact upload passed.
- [x] Run `40928091894` for Walk Details theme commit `1a4519d0f6218b0f880350297bca46252088ee5b` completed successfully.
- [x] Checklist update commit `9113d57177b59440460832bf8b4f43dbc785c0ef` workflow run `40928117487` completed successfully, including release APK build and artifact upload.
- [x] Walk-completion accent-token commit `c23d996dece2fddd11154e0cf09e4e948ac0ac1b` workflow run `40929592398` and checklist/docs follow-up run `40929744136` completed successfully: Flutter analysis, tests, release APK build, and artifact upload passed. Both APK artifacts are about 43.5 MB and expire 2026-11-05.
- [x] Workflow runs `40932226817` (test-fix commit `c8ca905b77194c60c1a060e0b955ae6afe8f0407`) and `40932267505` completed successfully, including analysis, tests, release APK build and artifact upload. Documentation head `0132bdd4b9f657a287fad371c9c338df37b411cc` run `40932908587` also subsequently completed successfully, including APK upload. These runs predate the current Live Walk GPS timer/return-location validation changes; current-head CI remains to be checked.
- [ ] Integration tests and web/device visual QA remain outstanding.
- [x] Inspected failed CI run 188: `flutter analyze` found invalid `const DojoPartnerTheme.*` references in Live Walk and Profile. The references were corrected and the latest PR-head run 205 completed analysis, tests, APK build and artifact upload successfully.
- [ ] Capture device screenshots and compare against the Notion reference.
- [ ] Firebase integration/security remains a separate phase; no claim of backend validation is made.

Checklist marks mean source review/change only, not test pass or policy approval.


## Security review — Live Walk completion
- [x] Inspected repository Firestore rules against the current Live Walk completion batch. No `/walks/{walkId}` rule exists and the recursive default-deny rule blocks unmatched writes. The assigned-walker booking update allowlist also excludes `completedAt`, `dogReturned`, and `returnLocationVerified` written by the current batch. Documented as ADR-003 in commit `322b80917eb71d1c2f3afcfd27286a5ee76d168a`.
- [ ] Confirm which rules are deployed to Firebase; repository rules alone do not prove deployment state.
- [ ] Design and implement a trusted, authorized Live Walk completion transition; do not widen client rules broadly.
- [ ] Add Firestore Rules Unit Tests / Emulator tests for assigned vs wrong walker, unauthenticated access, missing/already-completed booking, duplicate completion and atomic write failure.
- [ ] Verify backend, rules and device integration before claiming Live Walk completion works in production.


## Firebase deployment configuration audit
- [x] Inspected root `firebase.json`: it declares Cloud Functions only and does not configure a Firestore rules file or indexes. The repository contains `firestore.rules`, but its deployment through this config is not established. Recorded in ADR-004 (commit `6f3cb32c582b2d221ff1e908ab99ac9e209a620c`).
- [ ] Confirm the actual Firebase project and deployed rules source/command; repository contents do not prove deployment state.
- [ ] Do not add the current rules to deployment config until the Live Walk authorization and write-schema blockers are fixed and Emulator tests pass.
- [ ] Implement and test a trusted Live Walk completion endpoint with authorization and idempotency before release.


## Backend pre-deployment release gate
- [x] Added `docs/testing/FIREBASE_BACKEND_PREDEPLOY_CHECKLIST.md` to centralize policy approval, deployed-rules provenance, trusted completion endpoint, Emulator tests, client integration and release evidence gates. This is a checklist only; it does not mean backend implementation or deployment is complete.
- [ ] Complete each gate with evidence before enabling production Live Walk completion.

## Live Walk backend contract
- [x] Defined proposed trusted completion endpoint contract: authenticated walker identity, assignment/status checks, atomic transaction, stable idempotency key, input validation, replay-safe response, and required failure/concurrency tests. Recorded in ADR-005 (commit `0765ef903d9c3eb537d1bc82decef771ac5311b5`).
- [ ] Validate allowed source booking status and field schema against approved Notion policy before implementation.
- [ ] Implement callable and replace client-side direct completion batch.
- [ ] Add emulator tests and verify rules/function deployment configuration; production behavior remains unverified.

- [x] Cross-checked the Live Walk backend contract against Notion POL-006, POL-007 and POL-026. All three source policies are still draft/unapproved, so exact source statuses, evidence schema and exception rules remain blocked pending Founder/CEO approval (ADR-005 update commit `8bf3b051c45216af29f5118a2ca5b2c4ef5e4bdc`).
