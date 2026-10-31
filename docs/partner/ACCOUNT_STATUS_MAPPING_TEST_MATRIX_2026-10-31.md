# Partner Account Status Mapping — Test Matrix (2026-10-31)

## Scope and safety boundary

This is a Partner-repository-only presentation and behavior review. It does not change Firebase, Firestore, Functions, security rules, backend repositories, or deployed data. The current status fields are read-only inputs to the Partner UI.

**Important separation:** a display label is not authorization. The presentation mapping must never grant access to Partner Home. The existing Account Check remains conservative: Home is entered only when all three conditions are true: `isApproved == true`, `isActive == true`, and normalized `status == approved`. This is client-side routing behavior, not a substitute for server-side authorization.

## Source observations

Reviewed on branch `chore/notion-aligned-structure`:

- `lib/screens/auth/account_check_screen.dart` — routes to Home only for the strict three-field combination; known non-active states route to Application Submitted; unknown status remains blocked with a support message.
- `lib/screens/home/profile_screen.dart` — badge currently handles approved+active, suspended/disabled/inactive, rejected and under_review/submitted; other states fall back to “Verification pending”.
- `lib/features/onboarding/screens/kyc_status_screen.dart` — handles approved+active, correction_required, rejected, suspended/left/inactive, under_review/submitted and in_progress; unknown values are displayed as normalized raw text.
- `lib/features/onboarding/screens/application_submitted_screen.dart` — currently treats any approved+active flags as APPROVED regardless of status; only rejected gets a separate label; remaining states display UNDER REVIEW.

These differences confirm that one shared presentation mapper is justified, but the canonical backend vocabulary and contradictory-field semantics are not yet confirmed.

## Proposed presentation test matrix

The expected labels below are a **UI proposal**, not a claim that the backend contract has approved every state.

| # | status | isApproved | isActive | Proposed presentation | Access expectation |
|---|---|---:|---:|---|---|
| 1 | approved | true | true | Verified Partner / Approved & active | Eligible for existing strict client gate only |
| 2 | approved | true | false | Account inactive | Block |
| 3 | approved | false | false | Approval state conflict — contact support | Block; confirm backend meaning |
| 4 | approved | false | true | Account state conflict — contact support | Block; confirm backend meaning |
| 5 | under_review | false | false | Verification in review | Block |
| 6 | correction_required | false | false | Action required — correction needed | Block |
| 7 | rejected | false | false | Application not approved | Block |
| 8 | suspended | true/false | true/false | Account suspended | Block |
| 9 | left | true/false | true/false | Account closed / marked as left | Block |
| 10 | in_progress | false | false | Application in progress | Block |
| 11 | pending | false | false | Verification pending | Block |
| 12 | missing / empty | false | false | Status unavailable — contact support (unless an explicit not-submitted state is separately confirmed) | Block |
| 13 | unknown non-empty value | any | any | Status needs review — contact support; do not expose arbitrary raw backend text as a final user-facing label | Block |
| 14 | under_review | true | true | Conflicting account status — contact support | Block |
| 15 | rejected | true | true | Conflicting account status — contact support | Block |
| 16 | suspended | true | true | Account suspended | Block |
| 17 | correction_required | true | true | Conflicting account status — contact support | Block |
| 18 | left | true | true | Account closed / marked as left | Block |

## Normalization cases to test

- Trim leading/trailing whitespace and compare status case-insensitively.
- Treat non-string/missing status as empty, not as an exception.
- Treat only boolean `true` as true; strings such as `"true"` must not grant access.
- Unknown values must fail closed for access and produce a safe support-oriented label.
- Contradictory flags must never produce an “active/verified” presentation or Home access.
- `applicationSubmitted == true` must not silently override explicit states such as rejected, suspended, left, or correction_required.

## Decisions requiring product/backend confirmation

1. Is `disabled` an official status, or should it be treated as a legacy alias for `suspended`?
2. Does `left` mean permanently closed, voluntarily inactive, or another lifecycle state?
3. Are `pending` and `in_progress` both valid canonical statuses, and what exact user-facing next step applies to each?
4. What is the authoritative behavior when status and flags contradict each other?
5. Does `applicationSubmitted == true` have any meaning when status is missing or contradictory?
6. Is there a distinct `not_submitted` / onboarding state, or is the absence of a walker document the only pre-application signal?

Until these are confirmed, keep the existing Account Check gate unchanged and do not infer new authorization behavior from the UI matrix.

## Next implementation sequence

1. Obtain product/backend confirmation for the open semantics above.
2. Add a pure Dart presentation mapper in the Partner repository only.
3. Add unit tests for every matrix row plus normalization and malformed values.
4. Update Profile, KYC Status and Application Submitted to consume the mapper; keep Account Check's authorization/routing decision separate and unchanged unless explicitly approved.
5. Run formatter, analyzer and tests in CI for the exact commit. Report results only from that run.

## Verification status

- Source review: completed for the four named Partner UI files.
- Matrix: drafted; canonical contract questions remain open.
- Dart implementation: not started.
- Flutter tests/analyzer/build: not run.
- Firebase/backend: not accessed or modified.
- No source files deleted and no branch created.
