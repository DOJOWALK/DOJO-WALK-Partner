# Partner Live Selfie — Camera / Widget Test Seam Proposal

Date: 2026-11-01  
Scope: Proposal only; no production behavior or dependencies changed.

## 1. Objective

Make `LiveSelfieScreen` testable without opening a physical camera or writing to production Firebase, while preserving the current production camera, ML Kit, Storage, and Firestore behavior.

This proposal is deliberately separate from the responsive-preview change in PR #8. PR #8's responsive preview has passed the repository GitHub Actions checks on its exact current head; that CI result does not constitute camera/device integration coverage.

## 2. Current coupling observed

The current screen directly creates and controls:
- `CameraController` and `availableCameras()`
- ML Kit `FaceDetector`
- `FirebaseAuth.instance`
- `FirebaseStorage.instance`
- `FirebaseFirestore.instance`

The screen also owns capture state, image-stream processing, photo quality checks, upload metadata, and navigation. A widget test that pumps the current screen can therefore reach plugin/platform channels during `initState()`.

## 3. Recommended minimal seams

Introduce three small contracts behind the screen. Keep their production implementations backed by the same existing plugins.

### A. SelfieCameraSession

Responsibilities:
- initialize / dispose
- expose initialized and streaming state
- start / stop image stream
- take a photo
- provide a preview widget (production implementation returns `CameraPreview(controller)`)

The screen must not need to know whether the session is backed by a real `CameraController` or a fake. The fake preview can return a stable placeholder widget.

**Boundary requirement:** Keep `CameraController`, `CameraImage`, camera-plugin plane types, and platform-specific frame conversion inside the production camera adapter. The screen-facing contract must not expose camera-plugin types. Use either an immutable frame DTO (bytes, dimensions, pixel format, row stride, rotation and required plane metadata) or an analyzer-ready frame abstraction. The adapter must own conversion from plugin frames to this boundary.

**Lifecycle requirement:** initialize, start-stream, stop-stream, retry and dispose must be idempotent or explicitly serialized. Use a generation/cancellation token or equivalent so a late initialization or callback from an old camera session cannot start a stream or update UI after pause, retry, capture, resume replacement, or widget disposal. Dispose must release the camera exactly once and stale async results must be ignored.

### B. SelfieFaceAnalyzer

Responsibilities:
- accept a camera frame through the narrow frame input contract
- return the face observations needed by the existing checks: bounding box, eye-open probabilities, head Euler Y/Z
- close/dispose

Production adapter delegates to ML Kit. Widget/unit tests use a deterministic fake analyzer. Keep the current thresholds and capture decision logic unchanged in the first refactor.

**Analysis contract:** State whether frame analysis is asynchronous and enforce one frame at a time. Preserve the existing 180 ms throttle, single-frame guard, exactly-one-face rule, face-size and centering checks, eye/head-angle thresholds, and requirement for 8 consecutive good frames. After async ML Kit processing, discard results associated with a stopped or replaced camera session. Do not relax or broaden identity/face-quality policy as part of this testability refactor.

### C. SelfieSubmissionRepository

Responsibilities:
- obtain the authenticated user identity (or receive a verified UID from a small auth abstraction)
- upload the JPEG to `walker_selfies/{uid}/selfie_{timestamp}.jpg`
- preserve metadata: `contentType: image/jpeg`, custom `userId`, `documentType: selfie`
- merge `walkers/{uid}.kyc.selfie` with `status: pending`, `storagePath`, and server `submittedAt`
- preserve `updatedAt` server timestamp

Production adapter uses Firebase Auth, Storage, and Firestore. Tests use a fake repository and assert the exact path/metadata/document contract without network access.

**Submission contract:** Generate the submission timestamp once and reuse it in the Storage path for that submission. Preserve the existing document field names, nesting, merge behavior, and server timestamp sentinels; tests should assert the payload contract without comparing server-timestamp sentinels as ordinary DateTime values.

**Partial-write requirement:** Storage upload may succeed while the Firestore merge fails. Surface the Firestore error and keep the state retryable with a documented idempotency strategy. Do not silently delete the uploaded Storage object or introduce automatic rollback/cleanup unless a separate cleanup policy is explicitly approved. A retry must not accidentally create inconsistent metadata or silently report success.

## 4. Photo-quality validation

The captured JPEG quality check may remain a pure helper or be extracted into a small independently testable pure function. In either case, preserve the existing contract exactly:
- decoded JPEG must be at least 480 × 480 pixels
- sampled average brightness must remain within the existing inclusive bounds 35–235
- decode failure is rejected

Add deterministic tests for decode failure, dimensions below each minimum, lower brightness boundary, upper brightness boundary, and a valid passing image. Do not add blur, identity, or new face-quality checks in this refactor.

## 5. Injection approach

Add optional dependencies to `LiveSelfieScreen` constructor, defaulting to production adapters:
- `cameraFactory`
- `faceAnalyzerFactory`
- `submissionRepository`

Avoid global mutable test overrides. Keep the constructor defaults so existing navigation call sites remain source-compatible. Do not add a mocking package just for these seams; hand-written fakes are sufficient initially.

## 6. Test matrix

| Layer | Test | Expected evidence |
|---|---|---|
| Pure unit | preview height min / proportional / max | deterministic numeric assertions |
| Pure unit | JPEG decode failure / minimum dimensions | invalid images rejected |
| Pure unit | brightness at 35 and 235; values outside bounds | exact existing inclusive boundary behavior |
| Pure unit | valid JPEG | accepted without changing quality policy |
| Widget | camera initializing state | loading indicator and disabled retry |
| Widget | camera initialization failure | error copy and enabled retry |
| Widget | camera ready | fake preview visible; no platform channel |
| Widget | face-quality status | status copy responds to fake observations |
| Widget | stale frame result after stop/retry | old session result ignored |
| Widget | capture success | review image + Retake + Continue visible |
| Widget | upload pending | Continue disabled and progress indicator visible |
| Repository unit | successful submission | exact Storage path, metadata, Firestore merge payload |
| Repository unit | upload failure | surfaced error; no navigation |
| Repository unit | Storage success then Firestore failure | surfaced partial failure; safe retry; no implicit object deletion |
| Lifecycle unit/widget | pause during initialization; resume; dispose | no stale stream start, duplicate init or late UI update |
| Device smoke | Android permission / front camera | real camera starts and frames arrive |
| Device smoke | capture / retake / continue | real JPEG review and expected next screen |
| Device smoke | pause / resume | camera released and safely reinitialized |

## 7. Required acceptance criteria

1. Existing onboarding route call sites compile without passing test dependencies.
2. Production adapters preserve the existing Storage path and Firestore field names/types.
3. Widget tests run with fakes and do not invoke camera, ML Kit, Auth, Storage, or Firestore platform channels.
4. Failure paths remain visible and retryable; Storage/Firestore partial-write behavior is explicit.
5. Camera plugin frame types do not leak through the screen-facing camera interface.
6. Lifecycle cancellation prevents stale initialization, stream callbacks, and analyzer results from affecting a newer/disposed session.
7. Existing preview helper tests and all current camera/face thresholds remain intact.
8. Photo-quality tests cover the existing 480×480 and brightness 35–235 contract.
9. Android device/emulator smoke test is reported separately from CI unit/widget tests with device/API details.
10. No new dependencies, schema, Rules, Storage path, metadata, or face-quality policy changes are included without separate review.

## 8. Explicit non-goals

- No KYC schema change.
- No Firebase Rules change.
- No Storage path or metadata change.
- No ML Kit threshold/face-quality policy change.
- No camera plugin or Firebase dependency upgrade.
- No automatic Storage cleanup/rollback policy.
- No claim that a widget test or CI run substitutes for a real camera smoke test.

## 9. Implementation sequence (after review)

1. Add the three contracts and production adapters without changing behavior.
2. Inject adapters into the screen with production defaults.
3. Add fake-based widget tests for loading, error/retry, preview, captured-photo, and upload states.
4. Extract or expose the pure JPEG quality validator and add deterministic boundary tests.
5. Add repository contract tests for Storage and Firestore payloads, including partial-write failure.
6. Add lifecycle and stale-frame cancellation tests.
7. Run PR CI on the exact implementation commit.
8. Perform Android device/emulator camera smoke test and record device/API level plus results.

## 10. Current status

This document is a design proposal only. No Dart production code, dependencies, Firebase configuration, or rules were changed by this proposal. No widget test, emulator test, or device camera test has been run by this proposal. The separate PR #8 CI success validates Flutter analyze and the repository test suite on that PR head only; it does not validate physical camera behavior.
