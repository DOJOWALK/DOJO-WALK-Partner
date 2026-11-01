# Partner Live Selfie — Camera / Widget Test Seam Proposal

Date: 2026-11-01  
Scope: Proposal only; no production behavior or dependencies changed.

## 1. Objective

Make `LiveSelfieScreen` testable without opening a physical camera or writing to production Firebase, while preserving the current production camera, ML Kit, Storage, and Firestore behavior.

This proposal is deliberately separate from the responsive-preview change in PR #8.

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

### B. SelfieFaceAnalyzer

Responsibilities:
- accept a camera frame through a narrow frame input contract
- return the face observations needed by the existing checks: bounding box, eye-open probabilities, head Euler Y/Z
- close/dispose

Production adapter delegates to ML Kit. Widget/unit tests use a deterministic fake analyzer. Keep the current thresholds and capture decision logic unchanged in the first refactor.

### C. SelfieSubmissionRepository

Responsibilities:
- obtain the authenticated user identity (or receive a verified UID from a small auth abstraction)
- upload the JPEG to `walker_selfies/{uid}/selfie_{timestamp}.jpg`
- preserve metadata: `contentType: image/jpeg`, custom `userId`, `documentType: selfie`
- merge `walkers/{uid}.kyc.selfie` with `status: pending`, `storagePath`, and server `submittedAt`
- preserve `updatedAt` server timestamp

Production adapter uses Firebase Auth, Storage, and Firestore. Tests use a fake repository and assert the exact path/metadata/document contract without network access.

## 4. Injection approach

Add optional dependencies to `LiveSelfieScreen` constructor, defaulting to production adapters:
- `cameraFactory`
- `faceAnalyzerFactory`
- `submissionRepository`

Avoid global mutable test overrides. Keep the constructor defaults so existing navigation call sites remain source-compatible. Do not add a mocking package just for these seams; hand-written fakes are sufficient initially.

## 5. Test matrix

| Layer | Test | Expected evidence |
|---|---|---|
| Pure unit | preview height min / proportional / max | deterministic numeric assertions |
| Widget | camera initializing state | loading indicator and disabled retry |
| Widget | camera initialization failure | error copy and enabled retry |
| Widget | camera ready | fake preview visible; no platform channel |
| Widget | face-quality status | status copy responds to fake observations |
| Widget | capture success | review image + Retake + Continue visible |
| Widget | upload pending | Continue disabled and progress indicator visible |
| Repository unit | successful submission | exact Storage path, metadata, Firestore merge payload |
| Repository unit | upload/write error | surfaced error; no navigation |
| Device smoke | Android permission / front camera | real camera starts and frames arrive |
| Device smoke | capture / retake / continue | real JPEG review and expected next screen |
| Device smoke | pause / resume | camera released and safely reinitialized |

## 6. Required acceptance criteria

1. Existing onboarding route call sites compile without passing test dependencies.
2. Production adapters preserve the existing Storage path and Firestore field names/types.
3. Widget tests run with fakes and do not invoke camera, ML Kit, Auth, Storage, or Firestore platform channels.
4. Failure paths remain visible and retryable.
5. Existing responsive preview helper tests remain intact.
6. Android device/emulator smoke test is reported separately from CI unit/widget tests.

## 7. Explicit non-goals

- No KYC schema change.
- No Firebase Rules change.
- No Storage path or metadata change.
- No ML Kit threshold/face-quality policy change.
- No camera plugin or Firebase dependency upgrade.
- No claim that a widget test substitutes for a real camera smoke test.

## 8. Implementation sequence (after review)

1. Add the three contracts and production adapters without changing behavior.
2. Inject adapters into the screen with production defaults.
3. Add fake-based widget tests for loading, error/retry, preview, captured-photo, and upload states.
4. Add repository contract tests for Storage and Firestore payloads.
5. Run PR CI on the exact implementation commit.
6. Perform Android device/emulator camera smoke test and record device/API level plus results.

## 9. Current status

This document is a design proposal only. No Dart production code, dependencies, Firebase configuration, or rules were changed. No widget test, emulator test, or device camera test has been run by this proposal.
