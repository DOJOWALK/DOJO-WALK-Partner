# Partner ↔ Customer ↔ Firebase Integration Contract Audit — 2026-10-31

## Scope
Inspected:
- Customer `main`: `lib/features/booking/screens/booking_confirmation_screen.dart`
- Partner `chore/notion-aligned-structure`: `lib/screens/home/partner_home_screen.dart`, `firestore.rules`, `firebase.json`
- Firebase `main`: `firestore.rules`, `functions/src/index.ts`, `firebase.json`, `.firebaserc`

This is source/configuration inspection only. It does not establish which rules/functions are currently deployed in the Firebase console or which app build is installed in production.

## 1. Customer booking writer — observed contract
Customer writes a parent document to `bookings/{generatedBookingId}` using `bookingRef.set(bookingData)`.
Observed common fields:
- `bookingId`, `customerId`, `walkType: scheduled`
- `bookingPlan`: `one_time`, `regular`, or `customize`
- `serviceType`: `temporary_walk`, `regular_walk`, or `custom_walk`
- `serviceName`, `petName`, `dogId`, `petDetails`
- `pickupAddressId`, nested `pickupAddress`
- `scheduledAt` (Timestamp), `duration` (string such as “30 minutes”), `preferredTime`
- `walkCount`, `walkSchedules`, `status: pending`, `walkerId: null`, `cancelRequest: null`, `createdAt`.

Additional plan-specific fields:
- Regular: `frequency: daily`, `walksPerWeek: 7`, `walksPerDay`, `planStatus: pending_confirmation`, `dailyWalkTemplate`.
- Choose Dates: `walksPerDay`, `selectedDates`, `dateSchedules` with date Timestamp and nested walks.
- The writer does not create per-walk occurrence documents in the inspected method.

## 2. P1 — Customer booking ↔ Partner Home schema mismatch
Partner Home queries `bookings` where `walkerId == current Auth UID`, then selects today's work using only `data['date']`. It filters statuses `assigned`, `accepted`, `picked_up`, `walking` and sorts by `startTime`.
The inspected Customer writer does not write top-level `date` or `startTime`; it writes `scheduledAt`, `preferredTime`, `walkSchedules`, `dailyWalkTemplate`, and/or `dateSchedules`.
Result: a booking assigned by setting `walkerId` may still be omitted from Partner Home because the reader expects a different date/time shape. A fallback to `scheduledAt` alone would still fail to represent multi-date bookings and multiple walks per day.
Required resolution: approve one canonical assigned-walk occurrence contract. Each occurrence needs stable `occurrenceId`, parent `bookingId`, `walkerId`, service-local date/time/timezone, duration, pet snapshot, pickup snapshot/coordinates, and authoritative state. Partner Home/Schedule should read assigned occurrences, not independently reinterpret Customer templates.

## 3. Firebase booking rules — partial alignment plus validation gaps
Firebase repository `main/firestore.rules` has a `/bookings/{bookingId}` create rule validating the common fields, pending status, null walker, 20–60 minute duration, 1–3 walk templates, and the three plan types.
The Customer writer's observed top-level field names and plan field names broadly align with that allowlist.
However:
- Custom booking validation checks `selectedDates` and `dateSchedules` are lists of equal non-zero length, but does not validate each date entry, nested walks, selected-date uniqueness/order, or date-key consistency.
- The regular/custom/one-time rules do not establish a canonical per-walk occurrence or assignment lifecycle.
- The client writer calculates/sets booking price summary in UI, but the inspected payload shown here does not include a trusted payment/price authorization contract. Server-side pricing/payment validation remains necessary before payment/confirmation.
- Rules permit an approved assigned walker to update a set of booking progress fields directly. The allowlist constrains field names but does not, by itself, enforce a complete state-transition graph, single-use acceptance, offer expiry, trusted pickup verification, or exactly-once completion.

## 4. P0/P1 — completion document/rules incompatibility and missing canonical live data
The inspected Firebase rules contain a booking match but no explicit `/walks/{walkId}` or `/walk_locations/{...}` match in the relevant rules tree. Default deny therefore applies to client writes to those collections unless a separately deployed rule/service exists.
Earlier Live Walk source audit documented that Partner client completion writes a `walks` document and updates booking completion fields, while the checked-in Firebase booking walker allowlist does not include all fields used by that completion batch (including handover/return verification fields). This remains a high-priority contract conflict to resolve with trusted backend completion, not by broadly opening client writes.
Admin Live Operations and Partner Live Walk have previously been observed to use different tracking shapes: Admin expects `walk_locations` records while Partner retains route points in `walks.route`. No canonical live location write contract was found in the inspected sources.

## 5. Rules/configuration source mismatch — deployment safety blocker
- Firebase repo `.firebaserc` default project is `dojo-platform-b68a3`.
- Firebase repo `firebase.json` maps Firestore rules to `firestore.rules` and Functions source to `functions`.
- Partner repo `firebase.json` configures Functions only; it does not declare a Firestore rules path.
- Partner repo checked-in `firestore.rules` explicitly denies booking creation and differs from Firebase repo's Customer booking creation contract.
- Customer repository did not expose a root `firestore.rules` or `firebase.json` at the inspected paths.
These files are repository sources, not proof of the currently deployed Firebase rules. Do not deploy Partner repo rules as the shared production rules source. Treat Firebase repo as the current candidate shared rules source until deployment metadata is independently verified.

## 6. Backend Functions surface
The inspected Firebase `functions/src/index.ts` exports five callable functions, all service-location related:
- `reviewServiceLocationBoundary`
- `activateServiceLocation`
- `setServiceLocationStatus`
- `saveServiceLocationWithNameIndex`
- `manageServiceLocationImportRun`
No booking occurrence generation, assignment/offer, accept/decline, live-walk start, location ingestion, OTP verification, completion, incident, notification, or payout callable/trigger was found in this entrypoint. This finding is limited to the inspected Functions entrypoint and does not exclude external services.

## 7. Duplicate collections / data ownership
No evidence in this pass of a second Customer booking collection: the inspected Customer writer and Partner Home both use `bookings`.
The main duplication risk is semantic, not simply duplicate collection names:
- Parent booking contains templates and selected dates.
- Partner Home expects a legacy top-level `date`/`startTime`.
- Live Walk writes a separate `walks` record.
- Admin live operations has expected `walk_locations` records, but Partner live tracking does not currently publish that canonical stream.
Do not create more parallel collections until the shared contract is approved. Prefer parent booking + stable occurrence records + trusted walk record + canonical live-location stream, with explicit ownership and references.

## 8. Required decisions / implementation order
1. Freeze and document canonical Firestore schema with field types, required/optional fields, timezone rules, ownership and retention.
2. Define stable walk occurrence IDs for one-time, immediate, selected-date and regular daily/multiple-walk bookings.
3. Implement backend-only assignment/offer and acceptance transaction; Partner UI reads occurrence/offer state.
4. Implement trusted start, GPS ingestion/heartbeat, handover/OTP, idempotent completion and incident flows.
5. Align Admin Live Operations with the same canonical live-location stream.
6. Add emulator tests for Customer create → assignment → Partner read → start → tracking → handover → completion, plus rules denial tests and concurrency/idempotency cases.
7. Verify deployed project/rules/functions versions before any deployment; never deploy a partial Partner rules file over shared rules.

## Evidence limitations
- No Firebase console deployment metadata, live production rules export, or production data was inspected.
- No Emulator test, Flutter test, build, or device test was run in this audit.
- No source code, Firestore rules, Functions, production data, or deployment configuration was changed.
