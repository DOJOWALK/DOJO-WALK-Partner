# Partner Onboarding Form Source Review — 2026-11-01

**Scope:** Source-only follow-up for Personal Details and Current Address. No Flutter test, emulator, device, or backend run is claimed.

## Personal Details — source observations

File: `lib/features/onboarding/screens/personal_details_screen.dart`

- The screen loads the signed-in user's `walkers/{uid}` profile and prefills full name, email, phone, gender, and date of birth when available.
- The phone field is displayed as non-editable and uses the Firebase Auth phone number when present, otherwise the saved profile phone.
- Date of birth selection is capped at the date 18 years before the current date; the picker lower bound is 1940.
- Name validation trims whitespace and enforces 3–80 characters.
- Email is optional; a basic email-pattern check is applied when non-empty.
- The form has explicit loading and saving states and reports unauthenticated / Firestore errors in the UI.
- Existing code also passes work-location selections into this screen through constructor arguments. Do not change their Firestore representation until Team 01's canonical onboarding contract is approved.

## Current Address — source observations

File: `lib/features/onboarding/screens/current_address_screen.dart`

- Loads `walkers/{uid}.currentAddress` and prefills `houseNumber`, `street`, `landmark`, `city`, `state`, and `pinCode`.
- Required fields: house/flat number, street/locality, city, state, and PIN code. Landmark is optional.
- PIN code validation requires exactly six digits after trimming.
- Save is blocked until the user checks the current-residential-address confirmation.
- Save uses a merge write for the nested `currentAddress` map and an `updatedAt` server timestamp.
- Missing auth, missing profile, permission-denied, network failure, and generic load/save failures have user-facing handling in source.

## Testability / risks

1. Both screens call `FirebaseAuth.instance` and `FirebaseFirestore.instance` directly. The repository currently has no declared `fake_cloud_firestore` or Firebase mocking package in `pubspec.yaml`; isolated widget tests need a deliberate Firebase test seam or emulator-backed setup.
2. Do not add dependencies or refactor Firebase access as part of a UI-only test change without review. Prefer agreeing a test seam first.
3. Current Address accepts city and state as free-text fields. This review records existing behavior only; it does not approve any new location schema or replace the canonical service-zone catalogue.
4. PIN format validation is client-side only; server-side validation and Firestore authorization must remain enforced independently.

## Recommended next tests (not run)

- Personal Details: unauthenticated state; loading completion; empty/short/long name; invalid optional email; date-picker maximum date; keyboard and large-text scrolling.
- Current Address: unauthenticated and missing-profile states; required-field errors; malformed PIN values; confirmation gate; saving disabled state; permission/network errors; keyboard insets and short-height scrolling.
- Integration: verify exact Firestore reads/writes only against the approved Team 01 contract and Firebase Emulator rules. Do not infer backend acceptance from widget tests.

## Evidence boundary

This document is a source review and test plan only. No test execution, CI PASS, Firebase Emulator result, camera test, or production readiness is claimed.
