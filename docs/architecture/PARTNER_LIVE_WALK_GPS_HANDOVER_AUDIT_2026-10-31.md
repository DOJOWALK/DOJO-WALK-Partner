# Partner Live Walk GPS, Start/Complete & Safe Handover Audit — 2026-10-31

- Partner source: `DOJOWALK/DOJO-WALK-Partner`, branch `chore/notion-aligned-structure`.
- Cross-checks: Partner `firestore.rules`, Partner Live Walk ADRs 002/003/005, pickup GPS addendum, and Notion POL-007 / POL-006 status as recorded in the existing ADR.
- Audit type: read-only source audit. No app code, Firebase data, rules, or deployment changed.

## 1. Current implementation evidence

### GPS permission and tracking
- `LiveWalkScreen.initState()` calls `_startWalk()` immediately.
- `_checkLocationPermission()` accepts both `whileInUse` and `always`; it does not require background/always permission.
- `LocationPermissionService` requests foreground permission only and documents foreground permission as its purpose.
- GPS uses `Geolocator.getPositionStream()` with high accuracy and 3m distance filter.
- Client filters invalid coordinates and accuracy worse than 35m; ignores jumps >100m and movement <3m.
- First valid GPS fix starts the timer and sets the start location; the timer then increments locally each second.
- Route points are accumulated in the in-memory `_route` list and compacted to at most 500 points.
- No `WidgetsBindingObserver` / app lifecycle handler, background location service, periodic server heartbeat, or live `walk_locations` write is present in this screen. The route is saved to the `walks` document only at completion.
- A GPS stream error sets tracking false and shows Retry GPS. There is no visible stale-location threshold or server-visible tracking-loss event.

### Start authorization and pickup
- This screen receives a nullable `bookingId`; the widget does not require it.
- `_startWalk()` checks device location permission/service and loads pickup coordinates, but does not visibly re-read and validate booking assignment, allowed booking status, walker approval/activation, occurrence ID, or a server-authorized start token before starting the timer/route.
- Pickup coordinate parsing supports legacy top-level latitude/longitude, nested `pickupAddress` map, and legacy GeoPoint. The helper regression tests cover malformed/missing/out-of-range values.
- Missing pickup coordinates do not block the tracking stream. They only cause return-location verification to fail later and route the flow to OTP.

### Safe return / handover
- Return location is checked with a fresh high-accuracy device fix (20-second timeout), accuracy <=35m, and a hard-coded 75m distance threshold from the saved customer pickup coordinates.
- If GPS check fails, pickup coordinates are missing, or the current location is >75m away, the Partner UI asks for a four-digit Customer OTP.
- The OTP sheet reads the booking document directly and compares the entered value against the first non-empty one of `customerOtp`, `returnOtp`, or `otp`.
- OTP is therefore a client-side comparison against a booking field in the inspected code; no trusted verification callable, server-side attempt counter, expiry check, lockout, recipient identity validation, or one-time consume operation is visible.
- `_markDogReturned()` sets a local boolean after the return panel has been opened and a location check has completed. The final completion flow requires this boolean, then either accepts the <=75m GPS match or requests OTP.
- The UI does not visibly capture who physically received the dog, recipient relationship/authorization, handover photo/signature, or a safe exception/incident case.
- No emergency / dog missing / bite / injury / incident escalation action was found in this Live Walk screen.

### Completion persistence
- The screen generates a random `walks` document ID when its State object is initialized.
- On completion it writes the walk record and updates `bookings/{bookingId}` in one client Firestore batch when a booking ID is present. It writes fields including `status: completed`, `dogReturned: true`, `returnLocationVerified`, route, timestamps, duration and distance.
- If bookingId is absent, the code still writes a standalone completed `walks` document. The source comment says upstream should prevent this, but the widget API does not enforce it.
- A client batch is atomic for that one attempt, but a new screen instance can generate a new random walk ID for the same booking; it does not establish cross-session idempotency.
- If the batch fails, the UI resets `_isEnding` and permits retry. A retry in the same State uses the same random ID, but a restarted screen can create another ID.
- Existing ADR-003 records that the inspected Partner rules have no `/walks/{walkId}` match (default deny) and the booking update allowlist excludes fields this batch writes (`completedAt`, `dogReturned`, `returnLocationVerified`). Therefore this client batch is incompatible with those inspected rules. This is a source repository finding, not proof those exact rules are deployed.
- Existing ADR-005 says the trusted completion callable is proposed but not implemented. The inspected Firebase Functions main entry point exports service-location functions only; no live-walk completion callable was found there.

## 2. Findings and priority

### P0 — Completion path conflicts with inspected Firestore rules
The client writes `walks/{id}` where no match exists in the inspected Partner rules and updates booking fields not in the assigned-walker allowlist. Under those rules, the batch is denied atomically. Confirm deployed rules before any claim about production behavior; do not widen client writes to make it pass.

### P1 — Live GPS is not server-visible during the walk
The route remains in local memory until completion. There is no periodic location upload/heartbeat to the `walk_locations` source used by Admin Live Operations in the prior cross-app audit. App backgrounding, process termination, network loss and stale tracking cannot be reliably monitored by operations from this screen.

### P1 — Start is not visibly server-authorized
The screen begins tracking/timing based on device permission and GPS fix, without a visible trusted validation that this authenticated Walker owns the current assigned occurrence and that its booking is in an allowed start state. The nullable bookingId path permits a walk with no parent booking.

### P1 — Handover OTP is not trusted or one-time in the inspected client flow
The OTP is read from a booking document and compared locally. No rate limit, expiry, server-side verification, atomic consume, or replay prevention is visible. This cannot serve as a robust authorization boundary for safe handover.

### P1 — Completion is not idempotent across screen/process recreation
A random walk document ID is generated per screen State. Existing ADR-002 documents the duplicate-record risk. The client batch does not enforce one walk per occurrence under concurrent sessions or retries after an ambiguous network response.

### P1 — “Dog returned” evidence is only a local boolean
The walker can mark the dog returned after opening the return panel and completing a location check, even when the location check failed or differed (OTP is then required at final confirmation). No server-validated recipient/handover evidence is recorded.

### P1 — Emergency and exception workflow is missing from this screen
No visible incident action or trusted exception state exists for dog missing/escape, bite/injury, customer unavailable, unsafe recipient, GPS outage, or inability to complete normal handover. Do not force a normal completion in those scenarios.

### P2 — GPS distance/time metrics are client-derived and vulnerable to gaps
Distance is summed from accepted client points; timer increments locally. GPS outages, app suspension, device clock changes, mock location/spoofing, and gaps are not reconciled with a server timeline. Client accuracy/jump filters improve quality but do not establish authenticity.

### P2 — Fixed 75m rule and fallback behavior need policy approval
The 75m return threshold and OTP fallback are hard-coded in UI. POL-007 is Draft and requires Founder approval; do not treat this threshold or exception behavior as approved policy.

## 3. Proposed safe target architecture (not implemented)

1. **Start callable:** require non-empty stable occurrenceId/bookingId; derive walker UID from Firebase Auth; transactionally verify assigned walker, approved + active + eligible state, booking/occurrence status, zone and start prerequisites. Return a stable walkId and server start time. Repeated start requests return the same active walk.
2. **Live location:** use a platform-supported background location design only if the approved product/privacy policy requires it and the platform permission/foreground-service requirements are met. Upload bounded, timestamped points/heartbeats to a canonical server-visible collection such as `walk_locations`; record accuracy, permission state, sequence number and client timestamp. Backend validates ownership, freshness, coordinate bounds and sequence/idempotency. Do not store only an unbounded embedded route.
3. **GPS outage:** surface tracking stale/offline state to Partner and Operations; retain a bounded local retry queue with monotonic sequence IDs; never fabricate points. Define operational escalation and customer messaging in approved policy.
4. **Handover verification:** backend-generated short-lived OTP or other approved recipient proof; store verifier securely (prefer hash), rate-limit attempts, expire it, consume atomically once, bind to the correct occurrence and authorized recipient. Do not expose OTP in a readable booking field to the Partner client.
5. **Safe completion callable:** require stable completionRequestId; transactionally revalidate assignment and active state, required return/handover evidence, incident status and route metrics; create/update one stable walk record and mark occurrence complete exactly once. Return the same result for safe retries.
6. **Emergency flow:** allow Partner to create an incident event immediately with category, severity, location/time and notes; do not require normal completion or handover before raising an emergency. Backend alerts the configured operations owner and preserves evidence. Emergency contacts and response timings must come from approved POL-016/POL-007.
7. **Admin Operations:** read the same canonical live location source and show last update time, accuracy, stale/lost GPS, walk state, handover pending/verified, and incident alerts. Avoid exposing more customer address data than necessary.

## 4. Required release tests

- Start rejected for unauthenticated, unapproved, inactive, suspended, wrong walker, unassigned booking, wrong occurrence, already-started/completed/cancelled booking.
- Start retries and concurrent sessions return one stable walkId.
- Foreground/background transitions, screen lock, app switch, process death, permission revoked, GPS disabled, low accuracy, network offline/reconnect.
- Live points are visible to authorized Admin only, with freshness and stale alerts; unauthorized users cannot read/write another walker's stream.
- Route sequence duplicates/out-of-order points and replayed requests are rejected or safely deduplicated.
- Missing/malformed pickup coordinates never produce a false GPS match.
- GPS match at 74m/75m/76m, inaccurate/stale fix, missing pickup, and OTP fallback behavior are covered after policy approves the threshold.
- OTP wrong, expired, replayed, brute-force, wrong booking, concurrent verify, already consumed, and successful authorized recipient cases.
- Dog returned without authorized recipient, customer unavailable, unsafe handover, missing dog, bite/injury, and GPS outage can raise incidents without false completion.
- Duplicate completion, screen recreation, process restart, concurrent completion, ambiguous network response and batch/transaction failure leave exactly one authoritative walk record.
- Firestore Rules Emulator and Functions Emulator prove clients cannot bypass start, location, handover, incident, or completion transitions.
- Controlled device QA confirms privacy notices, permission prompts, background tracking, battery impact, notification visibility, and customer/admin experience.

## 5. Approval and implementation gates

- POL-007 (Live Walk & Safe Handover), POL-006 (Customer Booking & Eligibility), and POL-026 (Assignment) are drafts in the checked Notion evidence; founder approval and exact state vocabulary/exception rules are prerequisites.
- Confirm whether background GPS is a product requirement and obtain privacy/consent and platform permission review before implementation.
- Firebase Team owns canonical schema, callable transactions, security rules and emulator tests. Partner Team owns UI, permission UX and safe retry states. Admin Team owns operations visibility.
- Confirm deployed Firestore rules and Functions version/project before release.
- Do not implement client-only OTP verification, client-only completion, or broad Firestore write permissions as a workaround.

## 6. Verification boundary

- Source files and ADRs were fetched from GitHub refs stated above.
- No Flutter analyze/tests/build, Firebase Emulator test, device QA, production data inspection, or deployed rules/functions verification was run as part of this audit.
- No CI status is claimed.
- No source code, rules, production data or deployment was modified.
