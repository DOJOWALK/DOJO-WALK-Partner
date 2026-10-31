# Partner App Duplicate Code, Unused File & Architecture Audit — 2026-10-31

## Scope and safety
Repository: DOJOWALK/DOJO-WALK-Partner. Source branch: chore/notion-aligned-structure. This is a source-tree/import/reference audit, not a local Flutter build. No app files were deleted, moved or rewritten. No Firebase rules/data/deployment changed.

## Repository inventory
- Recursive Git tree inspected on the source branch: 117 tracked files total.
- Dart source: 28 files under lib/.
- Automated Dart tests: 2 files under test/.
- App bootstrap is small and clear: main.dart initializes Firebase then runs DojoPartnerApp; app.dart sets MaterialApp/theme and SplashScreen as home.
- Existing docs/PROJECT_FILE_STRUCTURE.md explicitly marks its target layout as a proposal and prohibits mass moves before import/reference mapping and a clean test baseline.

## Findings: duplicate / unused candidates

### 1. WalkCompletedScreen — probable unused production screen (P1 cleanup candidate)
- File exists at lib/screens/home/walk_completed_screen.dart.
- Search of the inspected source branch found no production navigation/reference to WalkCompletedScreen. LiveWalkScreen currently navigates to WalkSummaryScreen after saving.
- test/widget_test.dart imports and tests WalkCompletedScreen, so it is not wholly unreferenced in the repository.
- Do NOT delete yet. First confirm no deep-link, route-name, external caller or intended replacement requirement; then either remove the screen and its dedicated test together or restore it as the single approved completion screen. Avoid maintaining two competing completion experiences.

### 2. WalkSummaryScreen vs WalkCompletedScreen — overlapping responsibility (P1)
- WalkSummaryScreen is the production route used by LiveWalkScreen after completion.
- WalkCompletedScreen is separately implemented and tested but not found in production route references.
- Decide one canonical post-walk result screen. Preserve all required summary fields and pending-verification messaging; do not merge blindly because the two screens have different constructor/data contracts.

### 3. PickupCoordinates model and test — keep (not duplicate)
- lib/features/live_walk/models/pickup_coordinates.dart is used by LiveWalkScreen to parse the Customer pickupAddress map.
- test/features/live_walk/models/pickup_coordinates_test.dart exercises numeric values, numeric strings, malformed/partial values and geographic bounds.
- This is a useful shared parser and regression test; do not remove as “unused”.

### 4. ReviewBottomSheet — keep (not duplicate)
- lib/screens/home/review_bottom_sheet.dart is called from PartnerHomeScreen and returns a ReviewResult.
- No duplicate review sheet implementation was identified in this pass.
- Separate question remains whether the returned review is persisted to a trusted backend; this audit does not establish that.

### 5. LocationPermissionService — keep pending deeper service consolidation
- The service file is imported by LiveWalkScreen. It is not an orphan.
- Its current permission behavior was covered in the earlier live-walk audit; do not create a second permission service while fixing background tracking.

## Dependency audit (source references)
- Firebase Core/Auth/Firestore/Storage: required by bootstrap and app features.
- camera: used by live selfie capture.
- google_mlkit_face_detection: used by selfie framing/face detection.
- image: used by selfie image quality processing.
- image_picker: used by KYC document selection/capture.
- geolocator: used by live-walk location stream and checks.
- google_maps_flutter: imported in LiveWalkScreen; not classified as unused.
- cupertino_icons: retained as standard Flutter icon dependency; remove only after checking asset/icon usage and generated lockfile/build.
- flutter_test and flutter_lints: test/lint dependencies.
- flutter_launcher_icons: configuration exists in pubspec for Android launcher asset generation.

No package is marked safe to remove from this source-only pass. Verify with dart pub deps, analyzer, and build after obtaining a local checkout; do not edit pubspec based only on textual search.

## Architecture observations
1. Current lib/ layout is mixed legacy + feature-first: onboarding/live_walk under features/, while auth/home/splash remain under screens/. This is transitional, not inherently a defect.
2. Firebase calls are embedded directly in screens (booking status writes, profile/onboarding reads/writes, live walk persistence). This increases UI/backend coupling and complicates contract tests. Introduce feature repositories/services behind interfaces incrementally, not a wholesale rewrite.
3. Navigation uses direct MaterialPageRoute pushes and bottom-navigation switching. No centralized route registry/router was found in app.dart. A typed route map can be introduced after route inventory and deep-link requirements are settled.
4. main.dart calls Firebase.initializeApp() without an explicit generated firebase_options.dart in the inspected tree. Platform native configuration exists, but multi-platform initialization/build must be verified before changing bootstrap.
5. Tests currently consist of widget_test.dart and pickup_coordinates_test.dart. Existing widget tests cover brand tokens, missing booking-ID guardrails, pending earnings messaging and app widget mounting. This is a small baseline relative to 28 Dart source files; do not interpret it as broad feature coverage.
6. No proof of full Flutter analyze/test/build was obtained in this audit. Search results and file references are source evidence only.

## Cleanup classification

| Item | Classification | Action now |
|---|---|---|
| WalkCompletedScreen | Probable unused production screen; test-only reference | Keep until canonical completion screen decision and route/test check |
| WalkSummaryScreen | Active production completion route | Keep |
| PickupCoordinates + test | Active shared parser + regression coverage | Keep |
| ReviewBottomSheet | Active Home component | Keep |
| LocationPermissionService | Active Live Walk dependency | Keep; extend only after agreed permission design |
| pubspec dependencies | All checked packages have a source/config reference or standard role | No deletion in this pass |
| legacy screens/ + features/ split | Transitional structure | Incremental migration only |
| repeated Firebase access in widgets | Architecture coupling, not duplicate file evidence | Extract repositories feature-by-feature |

## Recommended next implementation sequence
1. Confirm the single canonical completion screen (WalkSummaryScreen vs WalkCompletedScreen) against product requirements and tests.
2. Build a complete route and import/reference graph locally; include Android/iOS/web entry points and generated files.
3. Establish a real baseline: flutter pub get, dart format --output=none --set-exit-if-changed, flutter analyze, flutter test, and supported platform build. Record exact commands, commit SHA and outputs.
4. Extract one feature repository at a time, starting with booking read/occurrence contract and assignment, then Live Walk trusted operations. Do not move UI folders as a prerequisite.
5. After each extraction, update tests, run analysis/tests, compare the diff and only then remove obsolete compatibility code.
6. Review assets and native configuration separately; never delete google-services.json, launcher assets, manifests or generated platform files without a dedicated Firebase/platform check.

## Evidence / verification boundary
- Tree and Dart source inventory read from chore/notion-aligned-structure.
- Target structure guidance read from docs/PROJECT_FILE_STRUCTURE.md.
- Main/app/pubspec and the two tracked test files inspected.
- GitHub code search used to trace key screen/service/dependency references. GitHub code search is not a substitute for a complete local compiler/import graph.
- No Flutter SDK command, analyzer, test runner, emulator, device or build was run here. No CI PASS is claimed.
- No files were deleted, renamed, moved or modified in application source. This report is documentation-only.
