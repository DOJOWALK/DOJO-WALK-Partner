# Partner App Test Coverage & Build Validation Audit — 2026-10-31

## Scope and evidence
- Repository: `DOJOWALK/DOJO-WALK-Partner`
- Inspected source ref: `chore/notion-aligned-structure`
- Documentation destination: `audit/partner-flow-2026-10-31`
- This is a repository/configuration inspection. No Flutter command, Android build, Firebase Emulator, or physical-device test was run in this audit session.

## Existing automated tests
Two test files are tracked under `test/` in the previously inspected repository tree:
1. `test/widget_test.dart`
   - Brand theme token assertions (#FF7900, #FFFAF5, #252525).
   - Material 3 / theme background assertion.
   - Missing-booking-ID guard in NavigationScreen.
   - Missing-booking-ID guard in WalkDetailsScreen.
   - WalkCompletedScreen does not display unverified ₹0 earnings.
   - Basic app widget mount and exception check.
2. `test/features/live_walk/models/pickup_coordinates_test.dart`
   - Valid numeric and numeric-string coordinates.
   - Missing/partial/malformed/non-finite/out-of-range coordinate rejection.
   - Valid geographic boundary values.

## Coverage gaps (not evidence that code is broken)
The current test set is narrow relative to the app's feature surface. Add tests in risk order:
- P0: Live-walk start authorization and invalid/missing occurrence/booking IDs; completion idempotency across retries/recreated sessions; duplicate-tap/concurrent completion; safe handover and emergency/incident path; OTP expiry/rate-limit/one-time consume once a trusted backend contract exists.
- P1: Booking occurrence date/time parsing for immediate, one-time, selected-date, recurring daily, and multiple-walks-per-day cases; offer accept/decline/expiry and assignment race cases; approval/activation gating; availability conflict and schedule validation.
- P1: KYC submission validation, partial upload/retry, resume behavior, profile status mapping, and sensitive-data access boundaries (rules/emulator tests).
- P1: Earnings ledger read-only display, pending/verified/held/paid/failed states and adjustment visibility after POL-013/POL-033 decisions are approved.
- P1: Push token lifecycle, notification routing and persistent inbox once notification contract is implemented.
- P1: Support case lifecycle and incident creation/authorization/escalation.
- P2: loading/empty/error/offline/permission-denied/stale-GPS states, app background/resume, timezone and accessibility behavior.

## CI workflow inspection
File: `.github/workflows/flutter.yml`
- Triggers: pull requests targeting `main`, pushes to `main`, and manual `workflow_dispatch`.
- Uses `ubuntu-latest` and Flutter stable channel; Flutter SDK version is not pinned.
- Steps: Node syntax/config checks, `flutter pub get`, icon asset checks, launcher icon generation, `flutter analyze`, `flutter test`, `flutter build apk --release`, APK artifact upload.
- No Firebase Emulator startup/configuration or emulator integration test step is present in this workflow.
- A feature/audit branch push by itself does not trigger this workflow; a PR targeting `main` or manual dispatch is required.

## Existing CI evidence found in PR #5 description
PR #5 (`Align Partner UI and structure with Notion`) records workflow run `40976539899` as completed/success for app-code commit `b1f1e1bb544a340248126c751815e969a85664f5`. The PR description says the run included dependency install, asset validation, launcher icon generation, Flutter analysis, Flutter tests, Release APK build and artifact upload. This is historical evidence for that specific commit only; it does not certify the current audit branch or later commits.
The same PR description identifies latest PR head `4c80ad9053638d929093af178b7172ee342f9136` as documentation-only and explicitly says no workflow run was returned for that head at the time of the update. Current PR-head CI was not independently confirmed in this audit.

## Validation result
- Existing test inventory: inspected.
- CI workflow definition: inspected.
- Historical successful CI run: reported in PR #5 description for the specific app-code commit above.
- Current audit-branch Flutter analyze/test/APK build: NOT RUN.
- Current audit-branch workflow run: NOT VERIFIED.
- Firebase Emulator integration: NOT CONFIGURED/NOT RUN in this workflow.
- Physical Android device QA: NOT RUN.
- No PASS claim is made for unexecuted checks.

## Recommended next sequence
1. Establish a pinned Flutter stable version and keep CI/local toolchain aligned.
2. Ensure the release workflow is triggered for the intended PR branch and verify the exact head SHA's run.
3. Run `flutter analyze`, `flutter test`, and `flutter build apk --release` against the exact candidate commit; retain logs/artifact.
4. Add unit/widget tests for pure logic and screen state before introducing shared backend contracts.
5. Establish an isolated Firebase Emulator project/config plus canonical shared rules/functions before writing integration tests. Never point tests at production Firebase.
6. Add end-to-end fixtures for booking occurrence, assignment, live walk, handover, completion, incidents and payout only after the corresponding policies/contracts are approved.

## Change safety
This audit adds documentation only. No Dart source, tests, dependencies, Firebase rules/config, production data, or deployment settings were changed.
