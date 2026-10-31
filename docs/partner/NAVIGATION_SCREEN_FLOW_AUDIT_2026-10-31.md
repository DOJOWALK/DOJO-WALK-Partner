# DOJO WALK Partner — Navigation & Screen-Flow Audit

**Audit date:** 2026-10-31  
**Repository:** `DOJO-WALK-Partner`  
**Branch:** `chore/notion-aligned-structure`  
**Scope:** Checked-in Partner Flutter UI and navigation source  
**Backend/Firebase changes:** None

## Executive summary

The app has a recognizable flow from splash → phone OTP → account check → onboarding or approved Partner Home. The main work area exposes Home, Schedule, Earnings, and Profile. Several screens are reachable, but some are placeholders or informational-only. Navigation is implemented mainly with direct `MaterialPageRoute` calls rather than a central route registry.

This is a source-level route audit. It does not prove every flow works on a physical device or that backend-dependent operations succeed.

## Screen-flow map

### Authentication and onboarding

```text
main.dart
  → DojoPartnerApp
    → SplashScreen
      → MobileLoginScreen
        → OtpScreen
          → AccountCheckScreen
            ├─ no walkers/{uid} document → WorkLocationScreen
            │   → PersonalDetailsScreen
            │   → LiveSelfieScreen
            │   → KycDocumentsScreen
            │   → CurrentAddressScreen
            │   → ReviewSubmitScreen
            │   → ApplicationSubmittedScreen
            ├─ approved + active + status=approved → PartnerHomeScreen
            ├─ known non-active application status → ApplicationSubmittedScreen
            └─ unknown status / read failure → account-check message or retry
```

### Approved Partner work area

```text
PartnerHomeScreen
  ├─ Home / assigned work cards → WalkDetailsScreen
  │    → NavigationScreen
  │       → LiveWalkScreen
  │          → WalkSummaryScreen
  │             → PartnerHomeScreen
  ├─ ScheduleScreen
  │    → WorkingScheduleScreen
  ├─ EarningsScreen
  └─ ProfileScreen
       ├─ Personal Details → read-only bottom sheet
       ├─ Documents & KYC → KycStatusScreen
       ├─ Notifications → Coming Soon dialog
       ├─ DOJO Support → PartnerSupportScreen
       ├─ About DOJO Partner → About dialog
       └─ Logout → Firebase Auth sign-out → login screen
```

## Navigation and screen inventory

| Screen / area | Reachability | Current role | Audit result |
|---|---|---|---|
| Splash | App entry | Startup transition | Connected |
| Mobile Login | Splash | Phone OTP initiation | Connected |
| OTP | Login | Verify phone | Connected |
| Account Check | OTP | Route by account/application status | Connected; client-side gate only |
| Work Location | New application | Onboarding start | Connected |
| Personal Details | Work Location | Capture applicant details | Connected in onboarding; Profile shortcut is read-only |
| Live Selfie | Personal Details | Selfie capture/face detection | Connected |
| KYC Documents | Selfie | Aadhaar/PAN capture/upload | Connected |
| Current Address | KYC Documents | Address capture | Connected |
| Review & Submit | Address | Review and submit application | Connected |
| Application Submitted | Submit / non-active status | Application status/support | Connected |
| Partner Home | Approved account | Today's assigned work overview | Connected; booking feed contract mismatch remains separately audited |
| Walk Details | Home work card | Review/accept current booking and continue | Connected; backend authority limitations remain |
| Navigation | Walk Details | Route/map stage | Connected; map/navigation limitations documented separately |
| Live Walk | Navigation | Local walk tracking and completion flow | Connected; server-side tracking/verification limitations remain |
| Walk Summary | Live Walk | Partner-recorded summary | Connected; not an authoritative completion/payout receipt |
| Schedule | Home navigation | Assigned walk calendar | Reachable but honest not-connected empty state |
| Working Schedule | Schedule / Home shortcut | Availability preview | Reachable; saving intentionally unavailable |
| Earnings | Home navigation | Earnings placeholder | Reachable; no verified ledger data yet |
| Profile | Home navigation | Partner profile and account actions | Connected; several settings read-only/Coming Soon |
| KYC Status | Profile | Read-only KYC status | Connected |
| Partner Support | Profile | Support request/history UI | Connected; runtime permission/backend behavior not verified here |
| Walk Completed (legacy) | No production route found in navigation search | Older completion UI | Candidate legacy/unused screen; do not delete until full reference/deep-link/test check |

## Findings and risks

### P1 — Navigation architecture is decentralized

The inspected app uses direct `Navigator.push`, `pushReplacement`, and `pushAndRemoveUntil` calls across screens. No central named-route registry was found in the inspected app entry files. This makes route auditing, notification deep links, and future navigation changes harder to maintain.

**Recommendation:** Introduce a typed route layer only as a separate, tested refactor. Do not mass-rewrite navigation during this audit.

### P1 — Main work tabs and operational data are not fully functional

Schedule and Earnings are reachable, but they are not yet complete operational features. Schedule explicitly explains that the assigned walk calendar is not connected; Working Schedule is a preview and cannot save; Earnings waits for verified records. These are visible placeholders, not hidden features.

### P1 — Booking/live-walk screens have backend dependencies

Home → Walk Details → Navigation → Live Walk → Walk Summary is connected in the UI. However, the earlier Partner flow audit documented missing trusted offer/assignment semantics, server-side GPS ingestion, trusted OTP/handover validation, and authoritative completion. The presence of a route does not mean those operational guarantees exist.

### P2 — Profile shortcuts have mixed implementation depth

KYC status and Support are reachable screens. Personal Details is a read-only bottom sheet. General Settings and notification preferences are Coming Soon. These should be labelled accurately until supported flows are agreed.

### P2 — Legacy completion screen

`lib/screens/home/walk_completed_screen.dart` is present and has no production navigation reference in the route search, while the active live-walk flow routes to `WalkSummaryScreen`. A widget test imports the legacy screen. Treat it as a possible legacy duplicate, not safe-to-delete: check all imports, tests, generated references, and external deep links before removal.

### P2 — Account routing is client-side

AccountCheck routes approved/active accounts to Home and keeps other known statuses outside Home. This is useful UX, but every privileged backend operation must independently authorize the Partner. A Flutter navigation gate is not security enforcement.

## Recommended cleanup order

1. Keep the current screen map as the baseline; do not delete screens based on name similarity.
2. Add route-level widget tests for login → account check, onboarding completion, approved Home, logout, and Home tab navigation.
3. Decide whether Schedule, Earnings, and Settings should remain visible with honest empty states or be hidden until launch readiness.
4. Once product and backend contracts are approved, connect Schedule, Earnings, Notifications, and booking actions individually.
5. Only after reference/test/deep-link checks, decide whether the legacy WalkCompletedScreen can be removed.
6. Consider a typed route registry after the above behavior is covered by tests.

## Explicit scope boundary

This audit made no Firebase or backend repository changes, no Firestore writes, no Rules/Functions changes, no branch creation, and no deployment. It did not run Flutter build/tests or physical-device navigation tests. All findings are based on checked-in Partner source inspection.
