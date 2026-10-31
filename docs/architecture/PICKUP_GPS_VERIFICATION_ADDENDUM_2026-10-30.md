# Cross-App Pickup GPS Verification Addendum — 2026-10-30

This addendum supersedes earlier statements in the audit that CI was still unverified. It does not supersede the outstanding Firebase Emulator/device integration requirements.

## Verified Customer CI

- Repository: `DOJOWALK/DOJO-WALK-Customer`
- PR: #30, `fix/pickup-coordinate-contract` (still Draft, open, not merged).
- Head commit: `2bcbc08887e2611369140f923bd4a7d8583e8352`.
- Workflow run: `40954050747`, **completed / success**.
- Confirmed successful steps: dependency install, launcher icon generation, Flutter tests, Flutter analysis, Release APK build, APK validation and artifact upload.
- Artifact: `Dojo-Walk`, about 27.9 MB, expires 2026-11-05.
- The new `pickup_address_snapshot_test.dart` covers coordinates present, legacy address with no coordinates, and a partial-coordinate record. These tests passed in this workflow run.

## Verified Partner CI

- Repository: `DOJOWALK/DOJO-WALK-Partner`
- PR: #5, `chore/notion-aligned-structure` (still Draft, open, not merged).
- PR head at check: `38a6744cf026a4fd5d17645502a19c8b7617acea`.
- Workflow run: `40952443568`, **completed / success**.
- Confirmed successful steps: backend/config syntax checks, dependency install, image validation, launcher icon generation, Flutter analysis, Flutter tests, Release APK build and artifact upload.
- This establishes CI for that specific commit, not device QA or live Firebase integration.

## Pickup coordinate contract now present in code

- Customer helper `buildPickupAddressSnapshot(SavedAddress)` includes `latitude` and `longitude` only when each value is present, preserving legacy address compatibility.
- Partner `LiveWalkScreen._loadCustomerLocation()` checks nested `pickupAddress.latitude/longitude` after legacy top-level coordinate fields and before legacy top-level GeoPoint.
- Partner retains coordinate validation; missing coordinates are not invented.

## Still outstanding — do not mark complete

- [ ] Firebase Emulator end-to-end: saved address → booking document → Partner reads pickup coordinates.
- [ ] Explicit Partner regression tests for nested valid coordinates, absent values, malformed types and out-of-range coordinates.
- [ ] Confirm expected UI/handover behavior when pickup coordinates are absent; client GPS lookup is not proof of zone eligibility or authorization.
- [ ] Validate approved booking/live-walk status transitions, authorization rules, duplicate completion protection and Admin live tracking data contract.
- [ ] Device-level walkthrough and review of privacy/permission behavior.

## Safety boundary

No PR was merged. No Firebase deployment, production data change, or Firestore rules change was made. Notion policy approval and shared schema decisions remain prerequisites for changing authoritative booking/status behavior.


## Partner nested-coordinate regression coverage added — 2026-10-30

- [x] Extracted nested `pickupAddress` parsing into pure helper `lib/features/live_walk/models/pickup_coordinates.dart`.
- [x] Live Walk now uses the helper for nested pickup coordinates while preserving legacy top-level and GeoPoint fallback paths.
- [x] Added `test/features/live_walk/models/pickup_coordinates_test.dart` for valid numeric values, numeric strings, missing coordinates, partial pairs, malformed values, NaN/infinity, out-of-range values, and valid geographic boundaries.
- Latest test commit: `6354db8586f65286a38449481f94d73bda793617`.
- [ ] GitHub Actions run for this latest commit has not yet been returned by the PR-run lookup. Do not mark these new tests as passed until a workflow result confirms it.
- [ ] Firebase Emulator end-to-end and device GPS/handover verification remain outstanding.
