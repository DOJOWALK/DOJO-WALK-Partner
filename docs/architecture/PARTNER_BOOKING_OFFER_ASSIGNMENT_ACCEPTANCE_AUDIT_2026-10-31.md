# Partner Booking Offer & Assignment Acceptance Audit — 2026-10-31

- Repository: `DOJOWALK/DOJO-WALK-Partner`
- App source branch inspected: `chore/notion-aligned-structure`
- Backend source branch inspected: `DOJOWALK/DOJO-WALK-Firebase` `main`
- Customer booking writer previously inspected: `DOJOWALK/DOJO-WALK-Customer` `main`
- Policy source: Notion POL-026, last fetched 2026-10-25; status **DRAFT — NOT APPROVED, NOT IMPLEMENTED, NOT TESTED**.
- Audit status: source-level review only. No app/backend code, Firestore data, rules, or deployment changed.

## 1. Evidence inspected

1. Partner `lib/screens/home/partner_home_screen.dart`:
   - Reads `bookings` where `walkerId == Firebase Auth UID`.
   - Today filter uses only `date`; active statuses are `assigned`, `accepted`, `picked_up`, `walking`.
   - No offer inbox, offer ID, response deadline, decline action, or candidate queue is visible in this screen.
2. Partner `lib/screens/home/walk_details_screen.dart`:
   - Loads a booking by ID and displays details.
   - Its only primary action is **Navigate to Pickup**.
   - Before navigation, it directly updates `bookings/{bookingId}.status = accepted` and `updatedAt`.
   - It does not visibly re-read/validate the booking's current status, assigned walker ID, offer ID, expiry, or the walker profile's active/approved state before making that write.
   - There is no explicit Accept / Decline offer UI in this flow.
3. Partner `functions/index.js` on the inspected branch exports only `checkBackend`; it is not a booking assignment or offer service.
4. Firebase `functions/src/index.ts` on `main` exports service-location callables only (boundary review, location activation/status, location save/name-index, import-run management). No booking offer/assignment/acceptance callable was found in that file.
5. Firebase `firestore.rules` on `main`:
   - `isApprovedWalker()` requires signed-in user with `walkers/{uid}.isActive == true` and `isApproved == true`.
   - Booking reads for a walker require `resource.data.walkerId == request.auth.uid` and `isApprovedWalker()`.
   - Admin may update booking assignment/status fields including `walkerId` and `assignedAt`.
   - An approved walker whose UID already matches `resource.data.walkerId` may update `status` and progress fields. The rule's changed-key allowlist does not itself validate a permitted status transition, offer expiry, or one-time acceptance.
   - `walk_requests/{requestId}` is explicitly read/write denied.
6. Admin `lib/features/walkers/services/walker_admin_service.dart` on `main` provides walker approval/rejection/suspension and booking reads; the inspected service does not provide a booking assignment transaction.

## 2. Findings

### P1 — Offer and acceptance workflow is not implemented in the inspected Partner UI
The app displays already-linked bookings and changes the booking to `accepted` when the walker taps Navigate to Pickup. This is not the POL-026 explicit offer → accept/decline → confirmed assignment flow. The app currently conflates accepting an assignment with beginning navigation.

### P1 — Assignment eligibility and state validation are not visible at the action boundary
The Partner action does not revalidate the booking's current state, current walker assignment, offer identity/expiry, or walker approval/activation. Firebase rules do require `isApprovedWalker()` for a walker's booking read/update, but deployed rules were not verified, and the Partner screen itself does not show the eligibility check. The rules allow the assigned approved walker to write the `status` field without constraining the transition value.

### P1 — No evidence of atomic single-walker assignment in the inspected backend
The inspected Firebase Functions entry point contains no booking assignment/acceptance callable. The rules permit an admin to update `walkerId`; they do not by themselves provide an atomic candidate-offer/acceptance transaction or prevent competing assignment writers. This is a scoped repository finding, not proof that no external or separately deployed service exists.

### P1 — No decline, expiry, no-response, or retry lifecycle found
The Partner flow has no visible decline action or offer deadline. Firebase's `walk_requests` collection is denied in the inspected rules. No offer collection/model/callable was found in the inspected Partner or Firebase source paths.

### P1 — Customer/Partner status contract is incomplete
The Customer booking writer previously inspected creates a parent booking with `status: pending` and `walkerId: null`, plus recurring/date schedule templates. The Partner Home screen only discovers bookings after `walkerId` is populated, then filters by a legacy `date` field. Its status filter includes `assigned` and `accepted`, but no offer state. The Partner detail action writes `accepted`. A booking-level status cannot safely represent every occurrence in multi-date or recurring bookings without an approved occurrence model.

### P1 — Double assignment and recurring occurrence safety remain unproven
No unique offer ID, occurrence ID, transaction-based claim, idempotency key, or concurrency test was found in the inspected Partner flow. POL-026 requires preventing concurrent acceptance by two walkers and evaluating each recurring occurrence independently. Current UI evidence does not demonstrate either control.

## 3. Required target contract (proposal for cross-team approval, not implementation)

- Parent customer booking remains the customer purchase/request record.
- Each independently assignable walk occurrence needs a stable `occurrenceId` and parent `bookingId`.
- Each offer needs a unique `offerId`, `occurrenceId`, `walkerId`, state (`pending/accepted/declined/expired/superseded`), server-created deadline, timestamps, and reason where applicable.
- A trusted backend transaction must re-read the booking occurrence, walker approval/activation/training/zone eligibility, availability version, leave/conflicts/capacity, payment authorization, and current offer state before accepting.
- The same transaction must atomically claim the occurrence for exactly one walker, close/supersede competing offers, and write an audit event. Retries and duplicate notifications must be idempotent.
- Partner UI must show a distinct offer card with Accept and Decline, service details, deadline, and limited customer information. An accepted assignment is then shown separately from an offer.
- **Navigate to Pickup** must not itself accept an offer. It should be enabled only for the currently confirmed assignment and must not mutate assignment ownership.
- Customer status should say confirmed only after backend assignment succeeds. Unassigned occurrences remain visibly pending/action-required; recurring occurrences show individual confirmed/unassigned states.
- Admin Operations should see offer attempts, accepted assignment, expired/declined offers, and escalation when eligible candidates are exhausted.

## 4. Required tests before release

1. Pending/unassigned booking is not visible as confirmed work to a walker.
2. Inactive, unapproved, unverified, untrained, out-of-zone, unavailable, on-leave, or conflicting walker cannot receive/accept an offer.
3. Correct walker accepts a valid, unexpired offer; assignment is atomically confirmed once.
4. Two walkers accept concurrently; exactly one succeeds and the other receives a safe conflict response.
5. A declined/expired offer cannot later be accepted; next eligible candidate is offered by server-side workflow.
6. Repeated taps, retries, duplicate push callbacks, and offline reconnect do not duplicate assignment or notifications.
7. Walker cannot change `walkerId`, assign themselves, accept another walker's offer, or move a booking to arbitrary status.
8. A suspended/deactivated walker cannot accept or progress a booking, even if an old offer is still present.
9. One-time, immediate, selected-date, recurring daily, and multiple-walks-per-day bookings create and display the correct occurrence records.
10. Customer, Partner, and Admin all show the same server-authoritative occurrence status and assigned walker.
11. Offer exhaustion creates a visible Central Operations action; replacement is not shown as confirmed until the replacement accepts.
12. Firestore Rules Emulator tests prove client cannot bypass backend state transitions.

## 5. Safe next steps

- Keep this as a P1 integration blocker; do not add a client-only Accept/Decline write or modify shared Firestore fields yet.
- Firebase Team: propose and review the canonical occurrence/offer schema and callable/transaction contract with Customer, Partner, and Admin teams.
- Founder/Policy owner: approve POL-026 decisions still open (ranking, deadline, attempt limit, scheduling buffers, escalation ownership, customer remedy) before those values are coded.
- Partner Team: after the contract is approved, replace the current Navigate-to-Pickup status mutation with explicit offer response and confirmed-assignment states.
- Add emulator fixtures for all booking types and concurrency cases; verify the exact deployed Firebase project/rules before release.

## 6. Verification boundary

- GitHub source files were fetched from the refs listed above.
- No Flutter analyze, unit/widget tests, Emulator tests, Android/Web build, or production Firebase inspection was run in this audit.
- No CI run is claimed.
- This audit does not prove the contents of deployed Firebase Functions or deployed Firestore Rules; verify deployment separately.
