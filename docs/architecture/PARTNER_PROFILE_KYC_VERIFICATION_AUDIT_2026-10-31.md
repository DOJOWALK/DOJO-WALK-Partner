# Partner Profile, KYC & Verification Flow Audit — 2026-10-31

## Scope and method
Read-only source inspection on branch `chore/notion-aligned-structure`. Reviewed the Partner login/OTP/account gate, profile screen, onboarding screens (work location, personal details, selfie, document capture, address, review/submit), and application-status screen. Findings describe source behavior only. No app code, Firebase data, rules, Storage objects, or deployment was changed.

## Files reviewed
- `lib/screens/auth/mobile_login_screen.dart`
- `lib/screens/auth/otp_screen.dart`
- `lib/screens/auth/account_check_screen.dart`
- `lib/features/onboarding/screens/work_location_screen.dart`
- `lib/features/onboarding/screens/personal_details_screen.dart`
- `lib/features/onboarding/screens/live_selfie_screen.dart`
- `lib/features/onboarding/screens/kyc_documents_screen.dart`
- `lib/features/onboarding/screens/current_address_screen.dart`
- `lib/features/onboarding/screens/review_submit_screen.dart`
- `lib/features/onboarding/screens/application_submitted_screen.dart`
- `lib/screens/home/profile_screen.dart`
- `docs/architecture/PARTNER_APP_ARCHITECTURE.md`
- `docs/architecture/PARTNER_UI_NOTION_CHECKLIST.md`

## What is present

1. Phone OTP uses Firebase Phone Auth. OTP success routes to `AccountCheckScreen`.
2. New users without `walkers/{uid}` are routed into onboarding.
3. New walker draft creation sets `status: in_progress`, `isActive: false`, `isApproved: false`, `verificationStatus: pending`, and `applicationSubmitted: false`.
4. Onboarding captures work zone/travel mode, personal details (client-side minimum age 18), a live camera selfie, Aadhaar front/back, PAN, current address, and a review/consent step.
5. Selfie capture uses front camera plus ML Kit face detection, one-face framing, face-size/position/eye/head-angle checks across multiple frames, and basic image brightness/dimension checks. It uploads to a private Storage path and records a pending KYC status.
6. Document capture requires all three document images, uploads them to Firebase Storage, and records pending status/path metadata in `walkers/{uid}.kyc.documents`.
7. Final submission re-reads the walker document and validates identity, application state, required document/selfie paths, address and selected zone fields before setting `status: under_review`, `applicationSubmitted: true`, `submittedAt`, and `onboardingStep: submitted`.
8. `AccountCheckScreen` only routes to Partner Home when all three conditions are true: `isApproved == true`, `isActive == true`, and `status == approved`. Known non-active states are routed to the application-status screen; unknown states remain blocked.
9. Application status screen streams the walker document and tells users they cannot accept walks until approval and activation.

## Findings

### P0 — UI account gate is not a security boundary
The only visible Home gate in the inspected flow is a client-side Firestore read in `AccountCheckScreen`. The app itself cannot prove that deployed Firestore/Storage rules or trusted backend endpoints reject every operation from pending, rejected, suspended, left, or otherwise inactive walkers. A user can modify a client; therefore assignment acceptance, schedule/availability changes, walk start/complete, GPS writes, and payout access must each be authorized by trusted backend/rules using current server-side walker state. Deployed rules and backend enforcement were not available to verify in this audit.

### P1 — Profile displays a hard-coded “Verified” badge
`ProfileScreen._buildProfileHeader()` always renders a constant `_VerifiedBadge()`. The profile loader does not read `status`, `isApproved`, `isActive`, or `verificationStatus`. This can falsely label an applicant or inactive account as verified. The Documents & KYC action also opens a “Coming soon” dialog rather than the actual submitted document/status view.

### P1 — Application status labels collapse important states
`ApplicationSubmittedScreen` labels the account APPROVED when `isApproved && isActive`, without also requiring `status == approved`; this differs from the stricter AccountCheck gate. The screen maps every other non-rejected state to UNDER REVIEW, which hides `correction_required`, `suspended`, `left`, and unknown statuses. The screen should display the exact normalized state and clear next action, without implying approval on mismatched fields.

### P1 — KYC upload completion is not KYC verification
Selfie and document uploads write client-supplied `status: pending` plus Storage paths. Face detection and image-quality checks are client-side capture guidance, not identity proof, document authenticity validation, biometric match, or liveness/anti-spoof verification. The review-submit step checks that paths exist in Firestore; it does not itself validate the stored objects or verify the identity. Only an authorized reviewer/trusted verification workflow should change verification results.

### P1 — Sensitive KYC files require strict Storage and access controls
Aadhaar/PAN images and selfie data are highly sensitive. Source uses Storage paths rather than public download URLs, which is preferable, but no deployed Storage rule, access audit, retention/deletion policy, encryption/access logging configuration, or reviewer role authorization was verified. The app's ability to download a photo for review must be constrained to the applicant and specifically authorized reviewers. Never expose document paths or files to customers, other walkers, or broad manager roles by default.

### P1 — Client writes application and KYC state directly
The app writes `walkers/{uid}` fields and nested KYC metadata from the client. The code contains comments describing intended Firestore rule restrictions, but those comments are not proof that the deployed rules enforce field allowlists, immutable approval fields, ownership, status transitions, file path ownership, size/type constraints, or reviewer-only decisions. Confirm deployed rules and trusted backend before production.

### P2 — KYC progress can lose local upload state
The document screen's selected images and its in-memory `_storagePaths` map are local to that screen instance. The reviewed code does not hydrate previously uploaded documents into the capture UI on re-entry. If the app is closed or the user returns later, they may need to recapture/re-upload even when Storage files and Firestore metadata already exist. Add persisted draft-aware document status and safe retry/resume behavior after the canonical KYC contract is approved.

### P2 — Partial upload cleanup/retry needs a defined strategy
Document uploads are sequential; Firestore metadata is written after the three uploads finish. If a later upload fails, earlier Storage objects may remain without a matching Firestore record. Session-local paths can help retry only while the screen remains alive. Define idempotent per-document paths, orphan cleanup, upload checksum/size/type validation and retry semantics on the backend/storage contract.

### P2 — Profile read errors silently fall back to defaults
Profile loading catches all errors and only clears the loading flag. It can render generic profile values without a visible error/retry state, which may look like valid missing data. Distinguish not-found, permission-denied and network failure, and offer retry.

## Required follow-up before release

1. **Firebase Team (P0):** verify deployed Firestore and Storage rules; only server-authorized roles can approve/reject/activate/suspend; walker cannot self-write approval, active, verification, payout or privileged fields; restrict KYC reads; enforce object ownership, content type/size and retention; authorize every operational write against current account state.
2. **Backend contract (P0):** define one canonical application state machine and reviewer decision record, including pending, under_review, correction_required, approved, rejected, suspended and left; approval and activation must be explicit, auditable, and effective-dated. Ensure client UI and backend use identical transitions.
3. **Partner UI (P1):** replace hard-coded Verified badge with real state from canonical account record; connect Documents & KYC to a safe read-only status/details view; show correction request/re-upload, rejection/support, suspension and activation states clearly.
4. **KYC UX (P2):** persist document upload progress/status, support safe resume/retry, and avoid unnecessary repeated collection of Aadhaar/PAN.
5. **QA (P0):** test fresh applicant, partially saved draft, pending review, correction required, approved-but-inactive, active-but-not-approved, fully approved+active, rejected, suspended, left, unknown state, Firestore permission denied, Storage permission denied, partial upload, offline/retry, and direct invocation of protected operations while inactive.

## Verification status
- Source files were fetched from GitHub and inspected.
- The current branch source was not executed in Flutter in this environment.
- No Flutter analyze, unit/widget/integration tests, emulator, Android/Web build, physical-device camera/liveness test, Firebase rules test, Storage rules test, or production authorization test was run.
- No test is marked PASS. No claim is made that production security is correct or incorrect; the deployed rules/backend must be checked.

## Recommended next task
Audit Partner booking offers and assignment acceptance, especially the boundary between an offered booking, an accepted assignment, and an authorized active walk. Reconcile it with the canonical assigned-walk occurrence contract already documented in the schedule audit.
