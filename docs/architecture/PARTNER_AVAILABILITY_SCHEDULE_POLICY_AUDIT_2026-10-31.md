# Partner Availability Schedule — Policy & Backend Contract Audit

- Date: 2026-10-31
- Scope: Partner `ScheduleScreen` and `WorkingScheduleScreen` on `chore/notion-aligned-structure`.
- Status: Source-level audit only. No Flutter/device/Emulator test claimed.
- No app source, Firebase data, rules, or production deployment changed.

## Confirmed implementation

### Schedule tab
File: `lib/screens/home/schedule_screen.dart`

- Displays today's date and a static empty-state message.
- Does not query assigned bookings or walk occurrences.
- Links to Working Schedule.
- Correctly distinguishes availability from confirmed assignment in its explanatory text.

### Working Schedule editor
File: `lib/screens/home/working_schedule_screen.dart`

- Reads `walkers/{currentAuthUid}.workingSchedule`.
- Supports all seven weekdays with enabled/disabled flags and start/end times.
- Defaults each day to 7:00 AM–7:00 PM when no saved value exists.
- Saves `workingSchedule.status = active`, `workingSchedule.days`, and `updatedAt` directly to the walker document using merge.
- Validates that at least one day is selected and each enabled day's end time is later than its start time.
- Does not visibly check partner approval/activation state before saving.
- Does not visibly enforce weekly schedule-change limits, effective dates, pending review, or conflicts with already assigned walks.

## Findings

### P1 — Schedule tab is not an assigned-work calendar

The tab is a static placeholder and does not show confirmed assignments. This is not inherently unsafe, because it explicitly says assignments should only appear after real booking data is available. However, it remains a functional gap: Partner users cannot review their upcoming confirmed workload in this tab.

Resolution depends on the canonical assigned-occurrence contract. Do not connect this screen to raw Customer parent bookings or independently expand recurrence templates.

### P1 — Availability is written directly by the client

The editor writes the full `workingSchedule` map directly to `walkers/{uid}`. The inspected UI does not verify the partner's approved/active work state before saving. Firestore Rules may enforce this, but deployed rules and server enforcement were not verified.

Backend must define whether an applicant, rejected, suspended, inactive, or not-yet-trained partner may edit availability. Availability changes must never grant booking eligibility by themselves.

### P1 — No conflict protection or change governance is visible

The editor validates only start/end ordering. It does not check whether a proposed availability change overlaps existing confirmed assignments, and it does not show an effective date or weekly change allowance.

The product policy previously discussed includes time-based working hours and limits on schedule changes. Exact final limit and approval behavior must be confirmed from the current policy source before enforcement. Do not invent a limit in code.

### P2 — Time model is ambiguous

The UI stores formatted strings such as `7:00 AM` and `7:00 PM`. This is human-readable but fragile as an API contract. The backend contract should define a canonical local-time representation, timezone/service-zone interpretation, and validation for daylight-saving/timezone edge cases where applicable.

The current validation rejects overnight shifts because end must be later than start on the same day. Confirm whether overnight availability is intentionally unsupported.

### P2 — Save feedback can overstate persistence guarantees

The UI shows “Working schedule saved successfully” after a Firestore client write. That confirms the client write returned successfully, but does not by itself prove that assignment services consume the same fields or that the partner became eligible for assignments. Copy should clearly say “Availability saved” and avoid implying confirmed work.

## Required contract decisions

1. Firebase Team: define the authoritative availability schema and who may write it.
2. Operations/Product: confirm weekly schedule-change policy, effective time, and whether edits require approval.
3. Assignment service: confirm it reads the exact `walkers/{uid}.workingSchedule` path and excludes unapproved/inactive partners.
4. Assignment service: define conflict handling when a partner edits availability around already assigned walks. Existing assignments must not be silently cancelled or invalidated.
5. Partner UI: after the occurrence contract is approved, render confirmed upcoming assignments separately from availability.
6. Security: verify Firestore Rules or callable backend commands prevent unauthorized status/eligibility changes.

## Acceptance checks (not run)

- [ ] Applicant/rejected/suspended partner cannot become assignable by editing availability.
- [ ] Active partner can save valid weekly availability.
- [ ] Invalid ranges and empty availability are rejected consistently by client and backend.
- [ ] Schedule changes obey the confirmed policy and weekly limit.
- [ ] Changes do not erase or silently conflict with confirmed assignments.
- [ ] Assignment engine reads the same canonical availability contract.
- [ ] Schedule tab shows assigned occurrences only, with pending offers clearly separated if policy allows them.
- [ ] Timezone and local service-day behavior are consistent across Customer, Partner, Admin and backend.
- [ ] Emulator security and integration tests pass.

## Explicit non-actions

- No schedule schema changed.
- No assumed weekly edit limit was added.
- No Firestore Rules or Functions were changed.
- No Partner Schedule UI was connected to raw booking documents.
- No PR was opened or merged.
