# DOJO WALK Partner — Project File Structure

Status: **Structure proposal / audit baseline**. This document does not claim that every listed module already exists or is implemented.

## Principles
- Notion operating policies are the product source of truth; code must not silently invent undecided business rules.
- Keep existing, working features until references and tests have been checked.
- Keep Firebase integration separate from UI and feature presentation.
- Enforce authorization and sensitive state transitions on trusted backend services, not only in the client.
- Do not store secrets, OTPs, passwords, or unnecessary identity-document copies in source control.

## Target Flutter structure

```text
lib/
  main.dart
  app.dart
  theme.dart
  core/
    constants/
    errors/
    routing/
    utils/
    widgets/
  models/
  features/
    authentication/
    onboarding/
    dashboard/
    availability/
    schedule/
    bookings/
    live_walk/
    earnings/
    notifications/
    incidents/
    support/
    profile/
  services/
    interfaces/
  shared/
    components/
test/
  unit/
  widget/
  integration/
docs/
  architecture/
  data_dictionary/
  policies/
  testing/
  decisions/
```

## Migration rule
This is a target, not permission to mass-move files immediately. First map every existing file and import, identify duplicate/obsolete files, and establish a clean test baseline. Migrate one feature at a time and run analysis/tests after each batch. Keep a compatibility export only where it prevents a safe migration from breaking callers; remove it after all references are migrated and verified.

## Firebase sequencing
The repository currently has Firebase dependencies and calls `Firebase.initializeApp()` in `lib/main.dart`. Before changing initialization, inspect platform configuration and generated options. Firebase Auth, Firestore, Storage, rules, and trusted backend functions must be tested as a separate integration phase after structure/UI work.

## Policy dependencies
- POL-025: Walker recruitment, verification, onboarding and training.
- POL-026: Walker availability, booking assignment and replacement.
- POL-013: Walker earnings and payout.
- Incident/emergency policy: safe reporting, escalation and handover.
- Approved design system: DOJO WALK orange `#FF7900`, warm background `#FFFAF5`, primary text `#252525`.

## Acceptance checklist
- [ ] Existing file inventory and import graph reviewed.
- [ ] No source files deleted without reference checks.
- [ ] Feature moves are incremental and compile-tested.
- [ ] UI states cover loading, empty, error, permission-denied and success where relevant.
- [ ] Business rules marked draft in Notion are not represented as approved policy.
- [ ] Firebase integration is not reported complete until platform config, rules and integration tests pass.
