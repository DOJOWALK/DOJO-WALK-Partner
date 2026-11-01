# DOJO WALK Partner App — AI Contributor Instructions

## Project scope
This is the DOJO WALK Walker/Partner Flutter app. The root `pubspec.yaml` includes Firebase Auth, Firestore, Storage, camera, ML Kit face detection, image processing, image picker, geolocation, and Google Maps. Firebase Functions are configured from the `functions` directory.

## Required workflow
1. Inspect the relevant screen, services, models, permissions, and tests before changing code. Follow existing patterns and preserve current app contracts.
2. Use the repository's Flutter/Dart configuration. Run `flutter pub get`, `flutter analyze`, and relevant `flutter test` tests where available.
3. For Firebase Functions changes, inspect the Functions package scripts and tests, then run the repository's existing checks.
4. Add tests for new state transitions, permission decisions, and failure paths. Report commands and actual results; do not claim unrun checks passed.

## Product and operational constraints
- Treat walker identity, KYC, selfie, GPS, booking, and walk-session data as sensitive.
- Enforce authorization in trusted backend rules/functions; never rely only on client-side checks.
- Preserve the distinction between booking ID and walk ID.
- A live walk must retain its safety lifecycle: GPS/check-in, active tracking, completion/stop events, and safe handover for emergencies. Do not silently cancel or stop a running walk.
- Do not invent KYC approval, availability, assignment, payout, or GPS success states.
- Do not weaken location, camera, photo, or identity protections to bypass a test.

## Security and release boundaries
Never commit real KYC images, selfies, customer data, tokens, API keys, or service-account files. Do not deploy Functions or change production Firebase settings/secrets without explicit owner approval.

## Pull requests
Work on a feature branch, never directly on `main`. Include affected flows, privacy/security impact, device permission behavior, tests, and rollback notes. Production deployment and merge require owner approval.
