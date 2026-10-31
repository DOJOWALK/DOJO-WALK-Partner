# DOJO WALK Partner App Architecture

Status: Initial architecture baseline; implementation and tests remain to be verified.

## Layers
1. **Presentation** — screens, reusable widgets, visual theme, navigation and form validation.
2. **Feature logic** — onboarding, availability, booking offers, live walk, earnings, incidents and profile workflows.
3. **Service interfaces** — explicit contracts for authentication, booking, location, uploads and earnings queries. UI should depend on interfaces rather than directly coordinating many Firebase calls.
4. **Firebase adapters (later phase)** — Auth, Firestore and Storage implementations, with error mapping and safe retry behavior.
5. **Trusted backend** — authorization, assignment concurrency, authoritative walk state, payout/earnings calculation, audit events and other sensitive transitions.
6. **Security and observability** — Firestore/Storage rules, least-privilege access, privacy-minimizing logs and test evidence.

## Policy boundaries
- An applicant remains pending until required verification, training and authorized activation are recorded (POL-025).
- Booking offers must be explicit; an offer is not an accepted assignment. Prevent double assignment using backend-controlled atomic state transitions (POL-026).
- Customer and walker payment records are separate. Earnings are calculated only from approved rate rules and trusted completion records (POL-013).
- Active-walk incidents prioritize safety and documented handover over completion metrics.
- Draft policies must remain visibly draft until approved.

## Current repository observations
- `lib/main.dart` calls `Firebase.initializeApp()` without explicit generated options in that file. Confirm platform configuration before modifying it.
- `pubspec.yaml` already declares Firebase Core, Auth, Firestore and Storage packages.
- Existing feature files use a mixture of `lib/features/... `, `lib/screens/...`, `lib/theme.dart` and direct Firebase SDK calls. Migrate only after mapping imports and responsibilities.
- Shared theme tokens have been aligned to the DOJO WALK palette (`#FF7900`, `#FFFAF5`, `#252525`). GitHub Actions run 205 for PR-head commit `3d4da0ffb8e162f5b8c217d5ba620792dfa64620` passed Flutter analysis, Flutter tests, release APK build, and artifact upload. This is CI evidence only; device visual QA, integration tests, and Firebase security/backend validation remain outstanding.

## Delivery sequence
1. Inventory and baseline.
2. Target structure documentation and safe theme/UI alignment.
3. Incremental feature migration.
4. Unit/widget tests and static analysis.
5. Firebase configuration and service-boundary implementation.
6. Security rules and backend authorization.
7. Emulator/integration tests and deployment readiness review.
