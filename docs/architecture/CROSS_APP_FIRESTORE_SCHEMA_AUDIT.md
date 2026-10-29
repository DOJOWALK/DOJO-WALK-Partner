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
