# Firebase Emulator Integration Readiness — DOJO WALK

- Checked: 2026-10-30
- Status: **Planning / blocked on shared Firebase test configuration**
- Scope: Customer saved pickup address → booking document → Partner Live Walk pickup-coordinate reader.
- This document is a test plan and readiness record. It does not claim that Emulator tests have run.

## Repository evidence

### Partner repository
- `firebase.json` currently configures only Cloud Functions (`functions` source: `functions`, runtime: Node.js 22).
- The repository contains a root `firestore.rules` file, but the current `firebase.json` does not declare a Firestore rules path or Firestore/Auth Emulator ports.
- `functions/package.json` has only a syntax-check lint script; no Emulator test script or Emulator dependencies were found in the inspected file.
- The Flutter PR workflow validates backend JavaScript syntax and Firebase JSON syntax, then runs Flutter analysis/tests and builds the APK. It does not start Firebase Emulators.

### Customer repository
- The inspected Customer repository has no root `firebase.json` or root `firestore.rules` at the checked default branch.
- Its current GitHub workflow runs Flutter dependency install, analysis and APK build; it does not start Firebase Emulators.

### Consequence
The current repository configuration is insufficient to safely run a shared Firestore/Auth Emulator integration test. The Partner `firestore.rules` file must not be assumed to be the deployed/shared project's authoritative rules merely because it exists in this repository. Do not wire it into a new emulator config until the project owner confirms the canonical rules source and test project configuration.

## Proposed integration test flow

1. Seed a test customer and a saved-address fixture with valid numeric `latitude` and `longitude`.
2. Build the same pickup-address snapshot shape used by Customer booking selection.
3. Create a test `bookings/{bookingId}` document with `pickupAddress.latitude` and `pickupAddress.longitude`.
4. Read the booking as the test Partner identity and pass the document map through the Partner pickup-coordinate parser.
5. Assert the returned coordinates exactly match the saved address values.
6. Verify negative cases: no coordinate keys, only one coordinate, numeric strings (if intentionally supported), malformed values, NaN/infinity, and out-of-range latitude/longitude.
7. Verify authorization separately: unauthenticated read denied; unrelated user denied; authorized test identities allowed only according to the approved shared rules.
8. Clean up test documents after each test; use an isolated Emulator project ID and never production credentials.

## Required decisions / prerequisites

- [ ] Confirm the authoritative Firebase project and an isolated Emulator project ID.
- [ ] Confirm the canonical Firestore rules source and whether Customer, Partner and Admin must share one rules file.
- [ ] Confirm whether Firebase Auth Emulator is required and define test identities/claims.
- [ ] Confirm the approved booking read authorization model for Customer and Partner.
- [ ] Confirm whether missing pickup coordinates should block booking, block walk start, or use an approved manual handover path.
- [ ] Add Emulator config and CI service startup only after the above decisions are recorded.
- [ ] Run the integration suite in CI and preserve logs/artifacts as evidence.

## Current verified code-level coverage

- Customer unit tests cover pickup snapshot coordinates present, legacy address without coordinates, and partial-coordinate data (verified in Customer CI run `40954050747` on commit `2bcbc08887e2611369140f923bd4a7d8583e8352`).
- Partner pure-helper regression tests cover valid numeric values, numeric strings, missing/partial values, malformed values, NaN/infinity, out-of-range values, and valid geographic boundaries. Their current-head CI run was still in progress at the time of this note; do not describe the Partner tests as CI-verified until that run completes.
- These are unit tests, not Firestore Emulator integration tests.

## Safety boundary

No production Firebase configuration, Firestore rules, data, or deployment was changed. No Emulator configuration was added because the authoritative shared rules/project setup is not yet established.
