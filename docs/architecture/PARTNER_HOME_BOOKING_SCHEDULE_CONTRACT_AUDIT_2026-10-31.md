# Partner Home — Customer Booking Schedule Contract Audit

- Date: 2026-10-31
- Scope: Customer booking writer on `main` vs Partner Home reader on `chore/notion-aligned-structure`.
- Status: Source-level contract finding; no runtime or Emulator test claimed.
- Safety: No app source, Firestore data, rules, or production deployment changed.

## Evidence

### Customer booking writer
File: `DOJO-WALK-Customer/lib/features/booking/screens/booking_confirmation_screen.dart` on `main`.

The booking payload writes:
- `scheduledAt`: Firestore Timestamp for the first selected date (or current time for immediate booking).
- `preferredTime`: first walk's time (or ASAP).
- `walkSchedules`: first-day walk templates.
- For regular bookings: `frequency: daily`, `dailyWalkTemplate`, `walksPerDay`, and `planStatus`.
- For choose-dates bookings: `selectedDates` (date keys) and `dateSchedules` (each selected date with its walks).
- `status: pending` and `walkerId: null`.

The inspected writer does not write a top-level `date` or `startTime` field in this payload.

### Partner Home reader
File: `DOJO-WALK-Partner/lib/screens/home/partner_home_screen.dart` on `chore/notion-aligned-structure`.

The Home reader:
1. Queries `bookings` by `walkerId == current Firebase Auth UID`.
2. Filters each document using only `data['date']` for today's date.
3. Filters statuses to `assigned`, `accepted`, `picked_up`, or `walking`.
4. Sorts using `startTime`.

It does not read `scheduledAt`, `preferredTime`, `walkSchedules`, `dailyWalkTemplate`, or `dateSchedules` in the inspected today-booking selection path.

## Finding — P1 integration contract gap

The Customer writer's observed payload and Partner Home's observed reader do not share the same date/time fields. The Customer writer stores schedule data in `scheduledAt` and schedule structures, while Partner Home filters by `date` and sorts by `startTime`.

Consequently, a booking written exactly in the inspected Customer format may be omitted from Partner Home even after assignment, because the Partner Home date filter receives no `date` value. The current Customer writer also starts new bookings at `status: pending` and `walkerId: null`; assignment must be materialized by the approved assignment workflow before Partner should treat it as assigned work.

This is a source-level mismatch and a credible integration risk, not a claim that a live production booking has failed.

## Important recurring-booking detail

A quick fallback from `date` to `scheduledAt` is not a complete fix:
- One-time/immediate booking can use `scheduledAt` as its first occurrence.
- Choose-dates booking has multiple dates in `dateSchedules`; `scheduledAt` represents only the first selected date.
- Regular booking stores a daily template and frequency; a single `scheduledAt` does not enumerate each daily occurrence.
- Each occurrence can have multiple walks with separate times/durations.

Therefore the app teams must agree whether the backend creates one assigned booking-occurrence document per walk, or whether a canonical occurrence model is read by Partner. Do not invent a client-only recurrence expansion or change the shared schema without approval.

## Required resolution

1. Firebase/Backend owner: propose and document a canonical assigned occurrence contract, including occurrence ID, parent booking ID, assigned walker UID, local service date, start time, duration unit, pet snapshot, pickup address/coordinates, and authoritative status.
2. Customer owner: confirm booking intent fields and preserve parent booking/schedule templates; do not make Customer responsible for assignment.
3. Partner owner: Home and Schedule must read the same canonical assigned occurrences, not independently reinterpret booking-plan templates.
4. Admin/Operations owner: confirm assignment status and replacement semantics against the approved policy.
5. Add Emulator fixtures for one-time, immediate, multi-date, regular daily, and multiple-walk-per-day bookings. Verify that only assigned occurrences appear on the correct local date and sort by occurrence start time.
6. Add empty/loading/error states and ensure a failed query is never rendered as a valid empty schedule.

## Acceptance checks (not yet run)

- [ ] Assigned one-time occurrence appears on the correct local service date.
- [ ] Immediate booking is not shown as assigned work before assignment succeeds.
- [ ] Every selected date in a choose-dates booking produces the expected occurrence(s).
- [ ] Regular daily booking produces occurrences only for dates covered by its approved active period.
- [ ] Multiple walks on one date display independently and in time order.
- [ ] Unassigned/pending booking never appears as a confirmed Partner task.
- [ ] Partner cannot read another walker's occurrence.
- [ ] Server-side rules/functions enforce assignment and status transitions.
- [ ] Customer, Partner, Admin and Firebase Emulator integration tests pass.

## Explicit non-actions

- No `date` field was added to Customer payload.
- No Partner fallback to `scheduledAt` was implemented.
- No Firestore collection or status contract was renamed.
- No branch was merged and no production data was changed.
- Flutter Analyze, app tests, device QA and Emulator E2E have not been run for this audit note.
