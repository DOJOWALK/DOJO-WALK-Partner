# DOJO WALK Partner

Flutter app for DOJO WALK walkers/partners.

## Project source of truth
Product behavior and operating requirements are governed by the DOJO WALK Notion policies. A policy marked draft is not an approved production rule. See:
- `docs/PROJECT_FILE_STRUCTURE.md`
- `docs/architecture/PARTNER_APP_ARCHITECTURE.md`
- `docs/decisions/ADR-001-notion-as-product-source-of-truth.md`

## Current technology
- Flutter / Dart
- Firebase packages are declared in `pubspec.yaml`
- Existing app entry point calls `Firebase.initializeApp()`; platform configuration and security must be verified before claiming a working environment.

## Local validation
Run these commands in a configured Flutter environment:

```sh
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

A successful local command is not evidence of deployed Firebase integration. Record actual command results and environment details.

## Planned Partner capabilities
Authentication, applicant onboarding and verification, availability, booking offers, live walk and safety handover, earnings statements, incident reporting, notifications, support and profile management. Feature status must be confirmed from code and tests; this list is not a claim that every capability is production-ready.

## Design tokens
- Primary orange: `#FF7900`
- Warm background: `#FFFAF5`
- Primary text: `#252525`

## Security principles
- Never commit credentials, API secrets, OTPs or passwords.
- Backend must enforce authorization, assignment uniqueness, trusted walk states and earnings/payout calculations.
- Use least-privilege Firebase rules and test them before production.
