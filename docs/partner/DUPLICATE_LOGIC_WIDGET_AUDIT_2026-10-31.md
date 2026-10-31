# Partner Duplicate Logic & Widget Audit — 2026-10-31

## Scope
- Repository: `DOJOWALK/DOJO-WALK-Partner`
- Branch: `chore/notion-aligned-structure`
- Audit base: `a16a4c65facf9b99246707f1e23c04e7e6bc230d` (source-reference audit commit)
- Reviewed onboarding, support, auth/account-state, profile/KYC, home and live-walk source references.
- No code was changed. No source file/widget was deleted or merged.
- Firebase/Backend repository, branches, Rules, Functions, data and deployments were not accessed or modified.

## Findings

### P1 — Support request submission logic is duplicated in two user journeys
**Files**
- `lib/features/onboarding/screens/application_submitted_screen.dart` — `_openHelpSupport()`
- `lib/screens/home/partner_support_screen.dart` — `_submitRequest()`

**Shared behavior confirmed**
Both directly create a document in `support_requests` with:
- `userId` and `walkerId` set to current UID
- `category`, `message`
- `status: open`
- `createdAt` and `updatedAt` server timestamps

**Important behavior differences**
- Onboarding dialog categories: Application Status, KYC Documents, Personal Details, Other.
- Approved Partner Support page categories: Application Status, KYC Documents, Booking & Walk, Payment & Earnings, Profile & Account, App Technical Issue, Other.
- Partner Support requires at least 10 characters; onboarding dialog only rejects an empty message.
- Partner Support warns not to submit Aadhaar/PAN/OTP/payment credentials; onboarding dialog does not show the same warning.
- Partner Support shows request history; onboarding dialog only submits a request.
- Error/success messaging and loading state are implemented separately.

**Risk**
The same support collection contract can drift. A later policy or validation change may be applied to one journey but not the other. The onboarding path currently accepts shorter descriptions and lacks the sensitive-information warning.

**Recommendation**
Do not merge the two screens or force one UI. In a future Partner-only refactor, extract a small shared support-submission helper/service and shared category/validation constants while keeping the two different presentations. Before that refactor, agree whether both journeys should use the same category list and 10-character/privacy validation. This helper must remain a Partner UI/client helper only; do not alter backend schema or permissions.

### P1 — Partner account/verification status mapping is repeated and inconsistent
**Files**
- `lib/screens/auth/account_check_screen.dart` — decides whether the Partner can enter Home.
- `lib/screens/home/profile_screen.dart` — `_verificationLabelFor(Map<String, dynamic>)`.
- `lib/features/onboarding/screens/kyc_status_screen.dart` — `_accountStatus()`.
- `lib/features/onboarding/screens/application_submitted_screen.dart` — derives application status label/message inline.

**Differences found**
- AccountCheck routes `correction_required`, `rejected`, `suspended`, and `left` to the submitted/status screen; only `approved && active && status == approved` enters Home.
- KYC status explicitly labels `correction_required`, `left`, `suspended`, `in_progress`, and unknown/empty states.
- Profile badge handles approved-active, suspended/disabled/inactive, rejected, and under-review/submitted, but does not explicitly label `correction_required`, `left`, or `in_progress`.
- ApplicationSubmitted screen derives a smaller display state: approved-active, rejected, otherwise under review. A suspended, left, correction-required, or in-progress account can therefore be presented with generic wording on that screen.

**Risk**
Different screens may tell the same Partner different things about the same account state. The AccountCheck route guard and server authorization are separate concerns: a shared UI mapper must not be treated as a security boundary.

**Recommendation**
Create one pure Dart account-status presentation mapper with explicit exhaustive cases and unit tests. Keep the actual AccountCheck access decision separately explicit and conservative; do not let a display label authorize access. Confirm the authoritative status vocabulary with the owning backend team before changing any cases. No backend work is included here.

### P2 — Logout flows repeat similar UI/auth behavior
**Files**
- `lib/features/onboarding/screens/application_submitted_screen.dart` — confirmation dialog, signOut, pop to first route.
- `lib/screens/auth/account_check_screen.dart` — signOut, pop to first route.
- `lib/screens/home/profile_screen.dart` — confirmation dialog, signOut, replace stack with MobileLoginScreen.

**Difference**
The confirmation and error-handling patterns vary. The destinations also differ because these screens sit at different points in the app flow.

**Recommendation**
Do not consolidate navigation destinations blindly. If desired later, share only a small confirmation presentation/helper while keeping each flow's correct post-logout navigation. Add widget tests before changing behavior.

### P2 — Repeated date/time/status formatting is not yet a proven cross-screen duplicate
- Partner Home has local date/time parsing and booking status helpers.
- Support screen has its own timestamp/status label helpers.
- KYC screen has document/account status formatting.
These operate on different data domains. Do not merge them into a generic formatter merely because helper names or switch structures look similar.

### P3 — Similar visual components are not enough to prove duplication
- Profile's private `_ProfileItem`, `_ActionItem`, `_DetailRow` and other screens' cards/rows have similar Material styling, but distinct data/layout behavior.
- Onboarding progress/document cards and KYC status tiles have different semantics.
- No shared widget deletion or visual-component consolidation is justified by this audit alone.

## Recommended safe refactor order

1. **Status mapper tests first:** write pure Dart test cases for approved-active, approved-inactive, under_review, correction_required, rejected, suspended, left, in_progress, pending, empty and unknown values. Agree expected display labels with product/backend owners.
2. **Support validation decision:** confirm one common minimum message length, sensitive-data warning and category policy for both pre-approval and approved Partner journeys.
3. **Support helper extraction:** only after step 2, extract a Partner-only submission helper/constants. Preserve separate UIs and existing collection fields.
4. **Logout helper (optional):** only share confirmation UI if it does not change route-stack destinations.
5. Run analyzer, unit/widget tests and CI on each isolated change. No package, screen, or source deletion is part of this plan.

## Decision register

| Finding | Confidence | User-facing risk | Action now |
|---|---:|---:|---|
| Support request logic duplicated | High | Validation/category drift | Document; no code changes |
| Account status mapping inconsistent | High | Conflicting status labels | Document; require status vocabulary agreement |
| Logout pattern repeated | High | Navigation inconsistency if over-refactored | Leave separate |
| Date/time/status helpers similar | Medium | False-positive abstraction risk | Do not consolidate |
| Similar-looking cards/rows | Low as duplication evidence | Accidental UI regression | Retain |

## Verification limits
- This is a source-level comparison of checked-in Dart files, not a runtime behavior test.
- No Flutter analyzer, test, emulator, APK build or device run was performed for this audit.
- No claim is made that any CI checks pass on the audit head.
- No Firebase/Backend source, rules, functions, data, branches or deployments were touched.
