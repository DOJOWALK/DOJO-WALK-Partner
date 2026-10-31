# Account Status Presentation Integration Audit — 2026-10-31

## Scope
Partner app source-only audit. No Firebase/backend repository, rules, functions, production data, or deployment were touched.

## Existing shared mapper
`lib/features/account/account_status_presentation.dart` exists and is pure presentation logic. It:
- Accepts a status string normalized with trim/lowercase.
- Accepts only literal boolean `isApproved` and `isActive`.
- Separates labels from access/navigation decisions.
- Returns a support-review label for unknown or contradictory states.
- Has a dedicated unit test file with cases for canonical and contradictory combinations.

The mapper is not currently imported by the four account-status surfaces reviewed.

## Current inconsistencies

| Source surface | Current behavior | Gap |
|---|---|---|
| AccountCheck | Home only when `status == approved`, `isApproved == true`, and `isActive == true`; known non-active states go to ApplicationSubmitted; unknown blocks | Access gate is deliberately conservative and must remain separate |
| Profile badge | Handles approved-active, suspended/disabled/inactive, rejected, under_review/applicationSubmitted; otherwise pending | Does not distinguish correction_required, left, in_progress, unknown, or contradictory flags consistently |
| KYC Status | Has its own label mapping; left is grouped with inactive; under_review/applicationSubmitted shown as Under review; handles correction_required and in_progress | Wording differs from shared mapper; applicationSubmitted can override missing status |
| Application Submitted | Shows APPROVED when both flags are true, regardless of contradictory status; REJECTED only for raw rejected; otherwise UNDER REVIEW | Can show APPROVED while status says suspended, under_review, correction_required, or another conflicting state |

## Safe integration boundary
1. Keep AccountCheck's existing access decision unchanged and fail-closed.
2. Use one presentation mapper only for display labels in Profile, KYC Status, and Application Submitted.
3. Do not let a presentation label determine authorization, route access, booking eligibility, or payout.
4. Do not infer a canonical status from `applicationSubmitted` when the status field is absent.
5. Unknown/contradictory values must not be presented as verified/active.

## Product/backend decisions still required
These values cannot safely be normalized by UI guesswork:
- Is `disabled` a canonical status or a legacy alias for `suspended`?
- Does `left` mean permanently closed, voluntarily inactive, or another state?
- Are `pending` and `in_progress` both canonical? What user action follows each?
- What is the authoritative precedence when status and boolean flags contradict?
- Can `applicationSubmitted == true` ever substitute for a missing status?
- Is there a distinct not-submitted/onboarding status?

## Recommendation
Do not yet wire the shared mapper into all screens or change displayed terminology. First confirm the canonical status vocabulary and precedence with the product/backend owner. Once confirmed, update the pure mapper and tests, then integrate one UI surface at a time while preserving AccountCheck's access gate.

## Verification status
- Source files inspected from `chore/notion-aligned-structure`.
- Existing mapper and unit-test source confirmed present.
- No Flutter analyzer/test/build was run as part of this audit.
- No source code changed in this audit.
