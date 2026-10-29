# Cross-App Firestore Schema Audit — DOJO WALK Partner / Customer / Admin

- Checked: 2026-10-30
- Status: Evidence-based initial audit; **not an approved shared schema**.
- Scope: booking document creation, Partner Live Walk completion, and Admin Live Operations reads.
- Safety boundary: do not change production rules, deploy functions, or silently migrate shared fields from this audit. Confirm the canonical schema and policy requirements first.

## Sources inspected
- Customer: `DOJO-WALK-Customer/lib/features/booking/screens/booking_confirmation_screen.dart` on `main`, source commit `94d45b12c7873fc2d289e164df965c735c0c63cb`.
- Admin: `DOJO-WALK-Admin/lib/features/walkers/services/walker_admin_service.dart` on `main`, source commit `d87d248ff8cc7f1b265c0db0c8f5abd52b6a3eb5`.
- Admin: `DOJO-WALK-Admin/lib/screens/live/live_operations_screen.dart` on `main`, source commit `15bf852258b273f753a45d9b107528dc027829e5`.
- Partner: `lib/features/live_walk/screens/live_walk_screen.dart` on `chore/notion-aligned-structure`, blob `e551856f752c6b11df1e718e50eb3a4d9d53677b`.

## Confirmed observations

### 1. Customer booking creation
The Customer app creates `bookings/{bookingId}` with fields including:
- `bookingId` (same value as document ID), `customerId`, `walkType: scheduled`, `bookingPlan`, `serviceType`, `serviceName`
- `petName`, `dogId`, `petDetails`
- `pickupAddressId`, `pickupAddress` (a map copied from the selected address)
- `scheduledAt` (Timestamp), `duration` (string such as “30 minutes”), `preferredTime`, `walkCount`, `walkSchedules`
- `status: pending`, `walkerId: null`, `cancelRequest: null`, `createdAt`
- Some booking types add `frequency`, `walksPerWeek`, `walksPerDay`, `planStatus`, `dailyWalkTemplate`, `selectedDates`, and `dateSchedules`.

### 2. Partner Live Walk reads location differently
Partner `_loadCustomerLocation()` reads top-level booking `latitude`, `longitude`, or `location` as a Firestore GeoPoint. The inspected Customer booking writer instead stores selected pickup data under `pickupAddress` and `pickupAddressId`; the inspected write does not set those top-level coordinate fields.
- Potential effect: Partner may fail to load the customer's return location and require OTP even when the saved pickup address contains coordinates.
- This is a source-level mismatch risk, not proof of a production failure. Confirm the exact `pickupAddress` coordinate keys and approved OTP/handover fallback before changing either app.

### 3. Partner completion write
Partner currently creates a random-ID `walks/{walkId}` document with `walkerId`, optional `bookingId`, `dogName`, `walkType: Regular Walk`, `scheduledTime`, `duration` (integer seconds), `distance` (kilometres), `location` (display string), `peeCount`, `poopCount`, `endedAt`, `status: completed`, `dogReturned`, `returnLocationVerified`, timestamps, route points, and optional start/end GeoPoints.
- For a non-empty booking ID, the client batch also changes `bookings/{bookingId}.status` to `completed` and writes `completedAt`, `dogReturned`, `returnLocationVerified`, and `updatedAt`.
- Client-side random walk IDs do not enforce one walk per booking across screen recreation or concurrent sessions.

### 4. Admin reads
- Admin's WalkerAdminService queries the shared `bookings` collection, including a `walkerId == walkerId` query; it describes status and assignment validation as a UI responsibility, with security rules required to enforce authorization independently.
- Admin Live Operations reads `walkers` with `isOnline == true` and reads route points from a separate `walk_locations` collection with `walkerId`, `latitude`, `longitude`, and `timestamp`.
- Partner completion route is embedded in the `walks` document. This audit did not establish that `walks.route` and `walk_locations` are intended to be the same live-tracking data source.

## Risks / questions to resolve
1. **Pickup coordinate contract:** What are the canonical latitude/longitude keys inside `pickupAddress`? Should Partner read that map, or should a trusted backend materialize a canonical location field?
2. **Status state machine:** Customer writes `pending`; Partner currently writes `completed`. The exact allowed intermediate statuses and completion preconditions must come from approved POL-006/POL-007/POL-026 and the shared Admin workflow.
3. **Duration units:** Customer `duration` is a display string; Partner `walks.duration` is integer seconds. Do not reuse the same field semantics across documents without a documented schema.
4. **Pet naming:** Customer uses `petName` / `petDetails.name`; Partner's walk record uses `dogName`. Decide whether this is intentional denormalization and document it.
5. **Live tracking:** Clarify whether Admin's `walk_locations` is the canonical live route feed and how it is created/secured; the inspected Partner Live Walk currently persists route points to `walks.route`.
6. **Rules/deployment:** The Partner repository's root `firebase.json` only configures Functions; the actual deployed Firestore rules source remains unverified. Do not assume the Partner rules file governs the shared Firebase project.

## Recommended safe next steps
- [ ] Inspect the actual selected address document/model and record its coordinate field names.
- [ ] Compare the Admin booking status filters and assignment writer against the approved Notion policy.
- [ ] Confirm whether Partner live location must write `walk_locations`, `walks.route`, or both, with retention/privacy constraints.
- [ ] Get Founder/CEO approval for POL-006, POL-007 and POL-026 before implementing completion/status transitions.
- [ ] Agree a shared versioned Firestore data dictionary across Customer/Admin/Partner repositories.
- [ ] Add Emulator tests for pickup-coordinate lookup, booking status transitions, authorization, duplicate completion, and customer data privacy.
- [ ] Implement changes only after schema and policy approval; validate CI and device integration before release.

## Policy references
- POL-006 — Customer Booking & Eligibility Policy (Notion; Draft at last check).
- POL-007 — Live Walk & Safe Handover Policy (Notion; Draft at last check).
- POL-026 — Walker Availability, Booking Assignment & Replacement Policy (Notion; Draft at last check).


## Follow-up verification — Partner pickup-location reader (2026-10-30)
- [x] Re-read Partner `lib/features/live_walk/screens/live_walk_screen.dart` at branch `chore/notion-aligned-structure`, source blob `e551856f752c6b11df1e718e50eb3a4d9d53677b`.
- [x] Confirmed `_loadCustomerLocation()` reads only top-level `bookings.latitude`, `bookings.longitude`, or top-level `bookings.location` when it is a Firestore `GeoPoint`.
- [ ] The selected Customer booking writer passes `pickupAddress` as a map and also stores `pickupAddressId`; canonical coordinate keys inside that map have not yet been proven from the inspected source excerpt. Do not guess map keys.
- [ ] Next verification: trace the Customer address model/save path and determine the actual coordinate key names, then agree a versioned shared location contract before changing either app.
- [ ] Do not use this client-side reader as an authorization or service-zone eligibility check. Server-side booking/zone validation is required by the approved backend contract.


## Confirmed Customer pickup-coordinate omission (2026-10-30)
- [x] Inspected Customer `SavedAddress` model: saved address documents support numeric `latitude` and `longitude`; `toBookingSnapshot()` includes them, and `fromMap()` reads them.
- [x] Inspected Customer `pickup_address_selection_screen.dart`: the `addressMap` passed into booking confirmation currently copies address text and instructions but omits `latitude` and `longitude`.
- [x] Inspected Customer `booking_confirmation_screen.dart`: booking writer stores this map as `pickupAddress` and does not write top-level `latitude`, `longitude`, or `location` in the observed booking payload.
- [x] Inspected Partner `LiveWalkScreen._loadCustomerLocation()`: it reads top-level `latitude`, `longitude`, or top-level `location` GeoPoint only; it does not inspect `pickupAddress.latitude/longitude`.
- **Finding:** this is a confirmed writer/reader contract gap in the inspected code. Even if the saved address has coordinates, the booking snapshot builder omits them; Partner then does not read nested pickup coordinates. For some bookings this can leave customer pickup coordinates unavailable to the live-walk screen.
- [ ] Safe fix proposal (not implemented): include `latitude` and `longitude` from `SavedAddress` in the selected `addressMap`; add a validated fallback in Partner to read `pickupAddress.latitude/longitude` while retaining legacy top-level fields; add Customer/Partner tests for valid, missing, malformed and out-of-range coordinates.
- [ ] Confirm behavior when saved address coordinates are null: do not silently treat missing coordinates as a verified pickup point; define approved booking eligibility / UI handling.
- [ ] After code change, run both Customer and Partner CI/tests and verify an end-to-end booking in Firebase Emulator before release. No production deployment or data migration performed.


## Pickup coordinate fix status (2026-10-30)
- [x] Customer branch `fix/pickup-coordinate-contract`: `pickup_address_selection_screen.dart` now includes saved `latitude` and `longitude` in the selected booking address map when non-null. Commit: `5e2b32b6a95fbc28e34331c1b2275fb701d57050`.
- [x] Partner branch `chore/notion-aligned-structure`: `LiveWalkScreen._loadCustomerLocation()` now checks validated nested `pickupAddress.latitude/longitude` after legacy top-level coordinates and before legacy top-level GeoPoint. Commit: `cdf9a016359c5583381aa017bea05908d9505197`.
- [x] Both changed source files fetched back from GitHub to verify the edits.
- [ ] Automated workflow runs were not returned for either commit by the current PR-run lookup. This is **not** evidence that CI passed; verify via GitHub Actions or create/open PRs that trigger the configured workflows.
- [ ] Regression tests and Firebase Emulator end-to-end test remain required. Null/malformed/out-of-range coordinates are rejected by the Partner validator; no coordinate is invented when missing.
- [ ] Customer change is on a dedicated branch and must be reviewed through a PR. Partner PR #5 remains Draft; do not merge/deploy until tests and policy alignment are confirmed.
