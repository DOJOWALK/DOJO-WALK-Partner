# DOJO WALK Partner — Earnings & Payout UI Blueprint

**Status:** UI proposal only  
**Repository:** `DOJO-WALK-Partner`  
**Branch:** `chore/notion-aligned-structure`  
**Backend/Firebase changes:** None. This document does not authorize or implement backend work.

## 1. Product principles

- Earnings shown to a Partner must come only from a trusted, verified earnings ledger.
- Customer payment amount is not the Partner's earning amount.
- A Partner-recorded Walk Summary, local GPS sample, or client-side completion event is not proof of payout eligibility.
- The Partner app is read-only for ledger entries and payout records. It must not calculate, create, edit, or mark earnings as paid.
- Do not hard-code rates, incentive amounts, payout day, cutoff, minimum payout, processing time, or payment rail while the relevant Notion policies remain draft/unapproved.
- Missing data must be labelled as unavailable/not connected, never represented as ₹0 or as a paid/failed transaction.

## 2. Earnings screen information architecture

### A. Summary
Show separate values only when supplied by the trusted ledger:
- **Verified earnings** — total of ledger entries eligible for display under the approved policy.
- **Pending verification** — completed walk records awaiting authoritative verification; must not be included in verified earnings.
- **Adjustments** — separately itemised credits/debits with reason and reference.
- **Already paid** — only confirmed payout transactions, not payout requests or initiated transfers.

If any value is not available from the service, show “Not available yet” with a short explanation. Do not show a fabricated ₹0.

### B. Walk-wise statement
Each row should be based on a stable server-issued Walk ID and show:
- Walk date/time in service timezone
- Dog or masked service label, as permitted
- Walk ID/reference
- Ledger status: pending verification / verified / adjusted / excluded / disputed
- Earning amount only when ledger-authoritative
- Adjustment reason and linked reference, if applicable

A completed walk with no ledger entry must not be assigned an estimated earning by the app.

### C. Payout history
Each payout record may show:
- Payout reference / batch ID
- Covered earning period (only if supplied)
- Amount
- Status: pending / processing / paid / failed / reversed
- Initiated and confirmed timestamps, when present
- Masked destination/payment method, only if the backend explicitly provides safe display data
- Failure/reversal explanation and support reference

“Paid” must require an authoritative confirmed transaction state. A client button tap or initiated transfer is not confirmation.

### D. Support and dispute
Provide a read-only detail view and a Support entry point for:
- Missing walk entry
- Incorrect earning/adjustment
- Payout delayed or failed
- Duplicate payout concern

The app must submit only a support request through an approved existing support flow; it must not edit ledger or payout data.

## 3. Screen states

- **Loading:** skeleton or progress indicator; avoid temporary ₹0.
- **Connected with records:** show verified totals and ledger-backed rows.
- **Connected, no records:** “No verified earnings yet.”
- **Not connected / unavailable:** explain that verified earnings records are not connected; do not imply the Partner has earned nothing.
- **Error:** concise message and retry; retain no stale value as current unless visibly marked last updated.
- **Partial data:** label each unavailable section; never infer missing fields.
- **Empty payout history:** “No confirmed payouts to display yet,” not “No payout due.”

## 4. Suggested navigation

Earnings tab
1. Earnings Overview
2. Walk Statement
3. Payout History
4. Payout Detail
5. Help with an earning or payout

Keep the current Earnings screen as a safe placeholder until the trusted read API and approved policy are available. No fake charts, estimated amounts, payout countdowns, or editable payout controls.

## 5. Data ownership and UI contract (proposal)

The backend team owns:
- Ledger entry creation and immutable source references
- Verification and eligibility decisions
- Incentive/adjustment calculations
- Payout batch creation and idempotency
- Payment provider status reconciliation
- Confirmed paid/failed/reversed states
- Audit trail and dispute resolution

The Partner app consumes read-only, access-controlled data. A future contract should provide stable IDs, currency, decimal-safe amount representation, status enums, timestamps, period metadata, and pagination. The exact collection/API names and fields must be agreed by the Firebase/Backend team; this blueprint does not prescribe or modify them.

## 6. Policy dependencies — unresolved

Before displaying actual amounts or payout schedules, product/operations must approve:
- Base earning rules and per-walk rates
- Incentive eligibility and amounts
- Treatment of cancellations, partial walks, incidents, and adjustments
- Verification criteria and dispute window
- Payout cycle, cutoff, minimum threshold, and processing SLA
- Payment method/provider and failed-transfer handling

Until then, UI must remain neutral and avoid publishing draft policy figures.

## 7. Acceptance checklist

- [ ] No hard-coded earning rate, incentive, payout date, or minimum threshold.
- [ ] No ₹0 placeholder presented as a real balance.
- [ ] Pending verification is separate from verified earnings.
- [ ] Walk Summary does not itself create an earning or imply payout eligibility.
- [ ] Only server-confirmed payout status can display “Paid.”
- [ ] Partner client has no ledger/payout write controls.
- [ ] Missing/partial/error states are explicit and retryable.
- [ ] All amounts and dates are sourced from trusted records and formatted safely.
- [ ] Support flow does not expose Aadhaar, PAN, OTP, or payment credentials.
- [ ] UI tests cover empty, loading, error, pending, verified, failed, and paid states once a read contract exists.

## 8. Current implementation assessment

The current `lib/screens/home/earnings_screen.dart` is a placeholder that says verified records are awaited and does not show sample balances. This is safer than inventing figures, but it is not yet an earnings ledger, statement, or payout history. Keep it in this state until policy and read-only data contracts are approved.
