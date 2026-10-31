# Partner Onboarding UI-Only Audit — 2026-11-01

**Scope:** Team 03 / Partner App. Source inspection only; no runtime, emulator, device, or viewport test is claimed by this document.

## Guardrails

- This audit is limited to Flutter UI structure, navigation, accessibility review, and test planning.
- Do not change Firestore/Storage paths or fields, introduce `zoneId`, rename `areaId`, add callable/API integrations, or alter Firebase Rules.
- Do not treat existing mock/proposal contracts as approved backend DTOs.
- Keep PR #5 Draft/Open. No merge or deployment.

## Six-screen source audit

| Screen | Source | Source-level observation | Responsive / accessibility evidence | Status |
|---|---|---|---|---|
| Work Location | `lib/features/onboarding/screens/work_location_screen.dart` | Reads active documents from the `zones` collection and derives city/area options from current document fields. This is legacy UI behavior, not an approved Zone catalogue contract. | Must test narrow portrait, landscape, large text, keyboard, loading, empty and stream-error states. Semantics/keyboard traversal require widget inspection. | **FAIL — integration boundary**; **NOT TESTED — viewport/a11y** |
| Personal Details | `lib/features/onboarding/screens/personal_details_screen.dart` | Loads the signed-in walker's existing profile and presents a form; loading and unauthenticated paths are present in source. | Must test keyboard insets, validation errors, large text and short-height scrolling. No viewport test evidence recorded. | **NOT TESTED** |
| Live Selfie | `lib/features/onboarding/screens/live_selfie_screen.dart` | Camera preview is placed in a fixed `height: 370` container inside a scrollable list. Camera permission/initialization failure and retry messaging are present. | Fixed height is not adaptive to short-height/landscape constraints. Need layout adaptation and tests. Large-text and semantics checks remain open. | **FAIL — responsive preview**; **NOT TESTED — other states** |
| KYC Documents | `lib/features/onboarding/screens/kyc_documents_screen.dart` | Uses image picker camera capture for Aadhaar front/back and PAN; upload progress state exists in source. | Must test camera denial/cancel, missing/empty files, upload failure/retry, short-height, landscape, large text and semantics. | **NOT TESTED** |
| Current Address | `lib/features/onboarding/screens/current_address_screen.dart` | Loads existing walker address and exposes a form with loading/saving/confirmation state. | Must test keyboard resize/insets, validation, load failure, large text, short-height and landscape. | **NOT TESTED** |
| Review & Submit | `lib/features/onboarding/screens/review_submit_screen.dart` | Loads walker data for review and has loading/submitting/agreement state. Source-level review does not establish an approved server-side submission contract. | Must test long review content, large text, short-height scrolling, load/submit errors, disabled submit and semantics. | **NOT TESTED** |

## Confirmed blockers / boundaries

1. Work Location's direct `zones` query and `city`/`area` field assumptions must remain unchanged until Team 01 publishes and Team 03 jointly approves the canonical Zone Lifecycle + Partner Onboarding Contract v0.4.
2. The fixed 370 logical-pixel Live Selfie preview is a concrete responsive-layout defect to address in a UI-only change.
3. Onboarding save/resume/correction and KYC intent/finalize contracts remain pending. This audit does not authorize new backend writes or API wiring.
4. Existing tests are not evidence of real device camera behavior or backend contract acceptance.

## Test matrix to execute on the exact implementation head

| Viewport / state | Work Location | Personal Details | Live Selfie | KYC Documents | Current Address | Review & Submit |
|---|---|---|---|---|---|---|
| Small-height portrait | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |
| Landscape | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |
| Large text scaling | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |
| Keyboard visible / insets | NOT RUN | NOT RUN | N/A | N/A | NOT RUN | N/A |
| Loading / empty / error | NOT RUN | PARTIAL SOURCE ONLY | PARTIAL SOURCE ONLY | PARTIAL SOURCE ONLY | PARTIAL SOURCE ONLY | PARTIAL SOURCE ONLY |
| Permission denied / retry | N/A | N/A | PARTIAL SOURCE ONLY | NOT RUN | N/A | N/A |
| Semantics / keyboard traversal | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |

## Next implementation step

Make a UI-only Live Selfie preview sizing change that responds to available screen height/orientation without changing camera, upload, Firestore, Storage, or navigation behavior. Add focused widget coverage for the preview layout at short-height portrait, landscape, and large text. Then continue the remaining five screen-specific widget checks.

## Evidence limitations

- Source refs were inspected on the PR #5 head branch `chore/notion-aligned-structure` (head SHA `71c94d4d3f879161c3934494f9aed6a5c5c4c85e`) at the time of this audit. The six inspected source files were: Work Location `56baeb49c91908116ea99a284f1e3e4883b39d80`; Personal Details `fa1f1b60df2fbe92df227f29f42fc02d7a356bdc`; Live Selfie `a4a6f1dc272845bcecac4b92e28718561af2212b`; KYC Documents `9028c4ff84ada3e525e8def978112429fcee71d7`; Current Address `a4caef0ca8394e07c2354449928650d7dc441742`; Review & Submit `83610b86907e3ffcb9d4f7550609a1a8a7fe5802`.
- This document is a source audit and test plan, not a Flutter test report.
- No emulator, physical-device, permission-dialog, camera, Firebase Emulator, or backend integration test was run.
- Record Flutter analyze, widget-test, and APK results only after running them on the exact PR head SHA.
