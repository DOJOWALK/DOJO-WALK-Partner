# Partner Notifications & Push Delivery Audit — 2026-10-31

- Partner source: `DOJOWALK/DOJO-WALK-Partner`, branch `chore/notion-aligned-structure`.
- Cross-check: Partner `pubspec.yaml`, Home, Profile, AndroidManifest and checked-in Firestore Rules; Firebase Functions `main` entry point previously inspected during this audit series.
- Audit type: read-only source review. No app source, Firebase data, rules, or deployment changed.

## 1. Evidence inspected

1. `pubspec.yaml` includes Firebase Core/Auth/Firestore/Storage, camera, ML Kit, image picker, Geolocator and Google Maps. It does **not** include `firebase_messaging` or a local-notifications package.
2. `lib/screens/home/partner_home_screen.dart`:
   - AppBar notification bell has `onPressed: () {}`; it performs no navigation or action.
   - No message stream, notification badge, unread count, notification inbox, or notification tap routing is implemented in the inspected Home screen.
3. `lib/screens/home/profile_screen.dart`:
   - Profile menu exposes “Notifications / Manage notification preferences”.
   - Tapping it opens a “Coming soon” message; preferences are not implemented.
4. `android/app/src/main/AndroidManifest.xml` declares Android `POST_NOTIFICATIONS` permission and location/background/foreground service permissions. A manifest permission alone does not request runtime permission, obtain/register FCM tokens, receive messages, display notifications, or handle taps.
5. Partner Firestore Rules allow the walker to update selected profile fields including `fcmToken` and `deviceTokens`; the private `walkers/{uid}/notifications` subcollection allows owner create/update and read. No Partner source code was found that writes device tokens or consumes a notification collection.
6. `functions/src/index.ts` in Firebase repository `main` was previously inspected and exports service-location functions only. No booking notification, FCM send, token cleanup, scheduled expiry, or notification trigger was found in that entry point.
7. The Partner search for `FirebaseMessaging`, `firebase_messaging`, `onMessageOpenedApp`, and `getInitialMessage` returned no source matches in the inspected repository branch.

## 2. Findings

### P1 — Push notification client integration is absent in inspected source
No FCM SDK dependency, token registration, foreground/background message handler, notification display, or notification-open routing was found. Android notification permission declaration is present but is not a working push pipeline.

### P1 — Home notification bell is a no-op
The visible bell has an empty callback. Walker cannot open an inbox or see pending/urgent alerts from this entry point.

### P1 — Notification preferences are placeholder UI
The Profile screen advertises preference management but only displays “Coming soon”. There is no saved preference model or opt-in/out behavior.

### P1 — No evidence of backend event-to-push delivery
The inspected Firebase Functions entry point has no notification send/trigger logic. The rules permit token-related fields but do not deliver messages. This scoped finding does not rule out an external provider or separately deployed service that is not present in the checked repository.

### P1 — Critical workflow events have no verified delivery path
No end-to-end push path was found for booking offer, accepted/declined/expired offer, assignment/replacement, cancellation, schedule change, walk start/completion, payout status, or incident/emergency alert. These events must not rely on push alone; the app also needs an authoritative inbox/state sync.

### P2 — Token lifecycle and privacy controls are undefined in app code
No evidence of per-device token registration, token refresh, logout cleanup, invalid-token removal, multi-device handling, notification permission state, or sensitive-content redaction on lock screen was found.

## 3. Recommended target design (proposal, not implemented)

- Add Firebase Messaging only after Firebase Team approves the shared notification contract and platform setup.
- Register one token record per device under a secure, user-owned path, with platform, app version, created/updated timestamps, permission state and last-seen time. Avoid treating a single mutable token field as the entire device registry.
- Derive recipient UID and event eligibility server-side. Never let a client send arbitrary FCM to another user.
- Backend event handlers send push after the authoritative Firestore transaction commits. Use an outbox/idempotency key so retries do not duplicate business events or notifications.
- Maintain a persistent in-app notification inbox with stable notification ID, event type, title/body, related booking/occurrence/walk/incident ID, createdAt, readAt, delivery state and safe deep-link route. Inbox state remains authoritative if push is delayed or denied.
- Push payload should contain minimal non-sensitive data; fetch protected details after authentication and authorization. Avoid exposing customer address, phone, OTP, KYC or financial details in lock-screen text.
- Handle foreground, background, terminated-app launch, notification taps, duplicate delivery and expired/deleted target records.
- On logout, unlink that device token from the signed-in account; on token refresh, update registration; on invalid-token response, remove stale registration.
- Notification preferences should be explicit, granular where appropriate, and must not suppress mandatory safety/security/incident notices. Exact categories and defaults require policy approval.
- Admin/Central needs delivery observability and failed-notification fallback; push must never be the sole proof that a Walker received or accepted an offer.

## 4. Required release tests

1. Android 13+ runtime notification permission granted, denied, later enabled, and permanently denied.
2. Token generated, persisted to correct authenticated walker, refreshed, rotated and removed on logout.
3. Same user on multiple devices; one device logout does not remove other device registrations.
4. Foreground, background, terminated app, notification tap, duplicate push and stale deep-link handling.
5. Booking offer push opens the exact offer; it does not auto-accept or mutate assignment.
6. Decline/expiry/replacement/cancellation pushes reflect server-authoritative state, even when delivered late or out of order.
7. Incident/emergency alerts bypass optional marketing preferences and do not reveal sensitive customer data on lock screen.
8. In-app inbox remains correct when push permission is denied, device is offline, FCM is delayed, or delivery fails.
9. Backend retries/outbox idempotency do not create duplicate inbox events or duplicate business transitions.
10. Invalid FCM tokens are cleaned up; unauthorized user cannot read another walker's inbox or register tokens for another UID.
11. Customer address, phone, OTP, KYC and bank/payout details are absent from push payloads.
12. Emulator/integration tests cover booking, walk, payout and incident events end-to-end.

## 5. Implementation gates

- Firebase Team owns event taxonomy, trusted triggers/outbox, token security, delivery retries and backend observability.
- Partner Team owns permission UX, token lifecycle integration, inbox UI, read state and deep-link handling.
- Admin Team owns operational notification visibility and fallback/escalation.
- Customer Team should share event naming and parent booking/occurrence identifiers; do not invent a Partner-only event schema.
- Approve notification categories, mandatory alerts, preferences, retention and lock-screen privacy before release.
- Do not add direct client-to-FCM sending or widen Firestore rules as a shortcut.

## 6. Verification boundary

- Checked source refs and files are identified above; repository search returned no FCM client implementation matches.
- No Flutter analyze/tests/build, Firebase Emulator test, device push test, provider-console inspection, or production deployment inspection was run.
- No CI status is claimed.
- No source code, Firestore rules/data, or deployment was modified.
