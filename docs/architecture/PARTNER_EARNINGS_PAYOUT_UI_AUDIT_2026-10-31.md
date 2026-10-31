# Partner Earnings & Payout UI Audit — 2026-10-31

## Scope
Read-only source audit of the Partner app earnings and walk-completion UI on branch `chore/notion-aligned-structure`, reconciled against the current Notion financial policy drafts. No application code, Firestore data, rules, payout provider, or deployment was changed.

## Evidence reviewed

### Partner app
- `lib/screens/home/earnings_screen.dart` — fetched from `chore/notion-aligned-structure`; blob SHA `480573efbd2057880709c0da4f4ca7e176c1841d`.
- `lib/screens/home/walk_completed_screen.dart` — fetched from `chore/notion-aligned-structure`; blob SHA `1d0acd39b4d3bf2a6e4f492c81929dbf1fa2d0e7`.

### Notion policy sources
- POL-013 — Walker Earnings & Payout Policy; last edited 2026-10-25; status DRAFT — NOT APPROVED, NOT IMPLEMENTED, NOT TESTED.
- POL-033 — Walker Earnings, Payouts, Adjustments & Financial Reconciliation Policy; last edited 2026-10-30; status DRAFT — NOT APPROVED, NOT IMPLEMENTED, NOT TESTED.
- POL-034 — Walker Performance, Ratings, Incentives & Disciplinary Management Policy; last edited 2026-10-30; status DRAFT — NOT APPROVED, NOT IMPLEMENTED, NOT TESTED.

## Findings

### 1. Earnings screen is a safe placeholder, not a working earnings ledger — P1
`EarningsScreen` is a `StatelessWidget` with hard-coded placeholder copy:
- “Awaiting verified records”
- “Amounts will appear when the trusted earnings ledger is connected”
- “No verified earnings to display”

The screen does not read Firestore, query a ledger, calculate totals, show completed Walk IDs, display adjustments/holds, or provide a statement period or dispute route. It does not fabricate a balance, which is correct for an unconnected ledger, but the earnings feature is not integrated.

### 2. Walk completion UI does not confirm or calculate earnings — P1
`WalkCompletedScreen` accepts an optional `earnings` double (default `0`), but the inspected UI does not display or use that value. It displays “Pending verification” and explains that the completion screen does not calculate or confirm payout. This is safer than showing a client-calculated amount, but the unused constructor field is misleading/dead API surface and should be reviewed when the backend contract is finalized. Do not wire it to a client-calculated amount.

### 3. No payout workflow or status evidence in these screens — P1
The inspected screens do not show a payout statement, batch/item reference, payout destination verification, queued/processing/paid/failed/held states, or payout dispute flow. This is a feature gap, not proof that no backend capability exists elsewhere.

### 4. Financial policy has unresolved and draft-only decisions — P0 release gate
Current Notion policy evidence:
- POL-013 says no earning rate, company commission, payout schedule, minimum payout, or payout method is approved in that draft.
- POL-033 adds a proposed base earning of ₹40 per verified successful completed Walk ID and proposed package-level bonus pools (Weekly ₹50, Half-Month ₹100, Monthly Lite ₹200, Monthly Pro ₹300), but explicitly labels these proposals NOT APPROVED / NOT IMPLEMENTED / NOT TESTED.
- POL-033 §19.5 explicitly says weekly/bi-weekly payout cycle, cutoff, minimum threshold, processing-time promise, and payout rail remain open and must not be displayed as a commitment.
- POL-034 §18 keeps base earnings and incentives separate and repeats that ₹40 and package bonus pools are proposed, not approved. Incentive eligibility, allocation, exclusions, evidence, review, appeal, and payment timing remain to be finalized.

Therefore, do not hard-code ₹40, any bonus amount, or Monday/weekly payout timing into Partner UI or backend as an approved entitlement. The remembered Monday payout concept conflicts with the latest POL-033 draft's explicit open-decision register; obtain a dated Founder/Finance decision and update policy before implementation.

### 5. Ledger integrity requirements must be backend-owned — P0 release gate
POL-013/POL-033 require trusted server-side calculations, one earning per eligible Walk ID, immutable original ledger records with compensating adjustments, idempotent retries, concurrency-safe payout batches, verified payout confirmation, maker-checker controls for applicable approvals, and reconciliation. Partner client must be read-only for amounts and payout state. Customer collection and walker payout are separate financial flows.

## Severity / recommended sequence

1. **P0 — Finance/Product decision:** approve effective-dated base rate card, duration/service variants, bonus model and allocation, payout frequency/cutoff/threshold/rail, adjustment rules, and dispute process. Resolve POL-013 vs POL-033 and POL-034 consistency. Record approver and effective date.
2. **P0 — Firebase Team contract:** define authoritative earning ledger, bonus ledger/component, payout batch/item records, exact IDs, statuses, idempotency keys, trusted completion/handover source, server-side authorization, indexes, audit events, and reconciliation ownership. Confirm deployed security rules.
3. **P1 — Partner UI:** replace placeholder only after the contract is approved. Display verified totals and walk-level breakdown from read-only trusted records; separate base earning, bonus, adjustment, hold and payout status. Add period statement and dispute entry point. Keep honest loading/empty/error/pending states.
4. **P1 — Completion screen:** remove or formally document the unused `earnings` constructor parameter; completion success must not imply earnings approved or payout confirmed.
5. **P0 — Tests before release:** duplicate completion, concurrent earning creation, invalid/missing rate card, client tampering, duplicate payout retry, unknown provider timeout, verified paid callback, failed payout recovery, hold/dispute, adjustment audit, and statement-to-ledger reconciliation.

## Verification status
- Source files were fetched and inspected through GitHub.
- Notion policy pages were fetched; their stated statuses are draft/unapproved.
- No Flutter analyze, unit/widget/integration test, emulator, Android build, Web build, live Firebase rules check, or payout-provider test was run in this environment.
- No test is marked PASS. No production readiness or payout integration is claimed.

## Decision required before coding
Confirm the current Founder/Finance decision for:
1. Is the proposed ₹40 per verified Walk ID approved, or is another base rate/model current?
2. Is the bonus per completed booking, or a package-level pool allocated across eligible walkers?
3. What payout frequency and cutoff are actually approved? (The latest POL-033 draft currently leaves this open.)
