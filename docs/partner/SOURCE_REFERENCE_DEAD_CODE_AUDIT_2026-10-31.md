# Partner Source Reference & Dead-Code Audit — 2026-10-31

## Scope and method
- Repository: `DOJOWALK/DOJO-WALK-Partner`
- Branch inspected: `chore/notion-aligned-structure`
- Inspected head: `d216a6b2a5ffc9c1667855179cec4739a455a881`
- Method: recursive Git tree inventory, direct source-file reads, Dart import/navigation/reference checks, test-import checks, and dependency declaration review.
- This is a checked-in source audit only. No local Flutter analyzer/build/test was run in this audit. No emulator or production Firebase state was inspected.
- No Firebase/Backend repository, branch, Rules, Functions, or deployment was touched.

## Inventory snapshot
The recursive tree returned `truncated=false`. It contains the Flutter app, Android/iOS platform scaffolding, assets, documentation, lockfile, and tests. App source is transitional: `lib/screens/` and `lib/features/` coexist. That is a maintainability observation, not evidence that either tree is disposable.

## Findings

### 1. Legacy completion screen — high-confidence cleanup candidate, NOT approved for deletion
- File: `lib/screens/home/walk_completed_screen.dart`
- The current production walk flow routes from `LiveWalkScreen` to `WalkSummaryScreen` (imported directly by `lib/features/live_walk/screens/live_walk_screen.dart`).
- No production navigation/import reference to `WalkCompletedScreen` was found in the inspected app source.
- It is still imported and exercised by `test/widget_test.dart`; the test asserts the legacy screen's pending-verification earnings messaging.
- Classification: **orphaned from the current production navigation path, but still test-referenced**.
- Recommendation: retain for now. First decide whether the legacy screen is intentionally retained for a future route or whether its test should be migrated to the canonical WalkSummaryScreen. Only then consider deletion in a separate reviewed cleanup.

### 2. Current walk summary — active canonical screen
- File: `lib/screens/home/walk_summary_screen.dart`
- Imported by `lib/features/live_walk/screens/live_walk_screen.dart`.
- Covered by `test/screens/home/walk_summary_screen_test.dart`.
- Not a duplicate to remove. It is the active completion-summary path.

### 3. Shared UI/helper files — referenced, retain
- `lib/screens/home/review_bottom_sheet.dart` is imported by `partner_home_screen.dart` and used for the post-walk review prompt.
- `lib/screens/home/customer_otp_sheet.dart` is imported by `live_walk_screen.dart`.
- `lib/features/live_walk/models/pickup_coordinates.dart` is imported by `live_walk_screen.dart` and has a dedicated model test.
- `lib/features/live_walk/services/location_permission_service.dart` is imported by `live_walk_screen.dart`.
- These are not dead code based on the reference graph.

### 4. Navigation is decentralized, not duplicated
- `lib/app.dart` sets `SplashScreen` as the app home.
- Screens navigate using direct `Navigator.push`, `pushReplacement`, and `pushAndRemoveUntil`; there is no central named-route registry.
- The flow is distributed across Splash/Auth/AccountCheck, onboarding screens, PartnerHome, and the walk flow.
- Recommendation: do not mass-move or delete screens. A route registry/feature-folder migration should be a separate, incremental architecture task after route/deep-link inventory and tests exist.

### 5. Dependencies — declared packages are not proven unused
- `pubspec.yaml` declares Firebase Core/Auth/Firestore/Storage, camera, ML Kit face detection, image processing, image_picker, geolocator, Google Maps, Cupertino icons, Flutter lints, and launcher icons.
- Directly inspected usage confirms camera, ML Kit, image processing, Firebase Storage, Firestore, Auth, geolocator, and Google Maps imports exist in the codebase. Google Maps is imported in Live Walk, although the current Navigation screen explicitly renders a map-unavailable placeholder.
- `image_picker` and `cupertino_icons` are **review candidates only** from this pass; no package should be removed until a repository-wide import and transitive/config usage check is completed.
- `flutter_launcher_icons` is used by the `flutter_launcher_icons` configuration in pubspec and must not be removed merely because no Dart import exists.

### 6. Platform and configuration files — preserve
- Android/iOS manifests, launch resources, launcher icon variants, Gradle files, and Firebase service configuration are platform/build inputs, not Dart dead code.
- Do not remove `google-services.json`, platform folders, or icon resources based on Dart reference checks alone.
- The Partner repository contains a `.github/workflows/deploy-functions.yml` workflow. This audit does not run, edit, or approve it; keep it outside any cleanup unless its ownership and deployment target are separately verified. Do not use it to deploy backend changes.

### 7. Test coverage and baseline
- Tracked test files include `test/widget_test.dart`, `test/features/live_walk/models/pickup_coordinates_test.dart`, and `test/screens/home/walk_summary_screen_test.dart`.
- `test/widget_test.dart` still imports the legacy completion screen; this is why its apparent lack of production references is not a safe delete.
- No analyzer, unit test, widget test, APK build, or device test was executed as part of this audit. Existing CI from earlier commits is not evidence for this inspected head.

## Cleanup decision register

| Candidate | Evidence | Confidence | Decision |
|---|---|---:|---|
| `walk_completed_screen.dart` | No production route reference found; imported by widget test | High for production orphan status; low for safe deletion | Retain pending canonical-screen decision and test migration |
| `image_picker` dependency | Declared in pubspec; no confirmed usage established in this pass | Low | Keep; complete whole-repo usage scan first |
| `cupertino_icons` dependency | Declared in pubspec; no confirmed usage established in this pass | Low | Keep; check icon references and lockfile impact |
| `lib/screens/` vs `lib/features/` | Mixed transitional organization | Not a dead-code finding | No bulk move/delete |
| Platform assets/config | Build/runtime references may be outside Dart imports | Not a dead-code finding | Preserve |

## Safe next sequence
1. Obtain an exact repository-wide Dart import/reference report (including generated files, tests, platform configuration, and asset declarations).
2. Decide whether `WalkCompletedScreen` is retired; if yes, update its test to assert the canonical `WalkSummaryScreen` behavior before deleting the old screen in a separate change.
3. Verify suspected package removals with analyzer/build CI on the exact candidate commit.
4. Review duplicate-looking widgets by behavior and call sites, not by similar names or visual appearance.
5. Delete nothing until the replacement, tests, and CI prove the same user-facing behavior remains.

## Explicit non-actions
- No source files, widgets, assets, dependencies, routes, or branches were deleted or modified.
- No Firebase/Backend repo, branch, Rules, Functions, Firestore data, or deployment was touched.
- No claim is made that Flutter tests/build pass on this head.
