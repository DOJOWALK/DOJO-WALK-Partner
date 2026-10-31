# DOJO WALK Partner — Notifications Integration Audit

**Audit date:** 2026-10-31  
**Repository:** `DOJO-WALK-Partner`  
**Branch:** `chore/notion-aligned-structure`  
**Scope:** Partner app source inspection only  
**Backend/Firebase changes:** None

## Executive result

Notifications are **not implemented end-to-end** in the inspected Partner app source. The UI exposes notification entry points, but they are placeholders. Android declares the Android 13+ notification permission, but a permission declaration alone does not register a device, receive messages, display notifications, or provide an in-app inbox.

## Evidence inspected

- `pubspec.yaml`: no `firebase_messaging` or `flutter_local_notifications` dependency found.
- `lib/main.dart`: no notification initialization found.
- `lib/screens/home/partner_home_screen.dart`: notification bell invokes the generic “Notifications will be available in a future update” SnackBar.
- `lib/screens/home/profile_screen.dart`: Notifications preference action opens a Coming Soon message.
- `android/app/src/main/AndroidManifest.xml`: declares `POST_NOTIFICATIONS` for Android 13+, but source inspection did not find an associated runtime permission request or notification channel setup.
- Repository code search for messaging/token/notification handlers returned no matching implementation.

This is a checked-in source audit, not a verification of deployed Firebase configuration, provider delivery, or production device behavior.

## Feature status

| Capability | Source audit result |
|---|---|
| Notification center / inbox | Not found |
| Push messaging SDK dependency | Not found |
| FCM token registration and refresh | Not found |
| Runtime notification permission flow | Not found |
| Android notification channel setup | Not found |
| Foreground message handling | Not found |
| Background / terminated message handling | Not found |
| Tap routing / deep links | Not found |
| Read / unread state | Not found |
| Notification preferences | Coming Soon placeholder |
| Bell action | Coming Soon placeholder |

## Partner UI requirements

When a trusted notification contract is available, the Partner app should provide:

1. **Inbox:** newest first, pagination, loading/empty/error states, read/unread distinction.
2. **Notification detail:** title, concise message, created time, event reference, and safe navigation destination.
3. **Preferences:** only categories that operations actually support; clearly explain critical operational alerts that cannot be disabled, if policy requires.
4. **Permission UX:** request permission in context, explain why it is needed, handle denied/permanently denied states, and link to system settings when appropriate.
5. **Tap behavior:** validate the target and current Partner authorization before opening booking, walk, KYC, payout, or support details. Do not trust arbitrary payload routes.
6. **Token lifecycle:** handle token refresh and sign-out/account changes without exposing tokens in UI or logs.

Potential categories to consider after product approval: booking/assignment updates, walk reminders or operational changes, account/KYC status, payout status, support replies, and urgent safety/incident alerts. These are proposals, not currently available notification types.

## Backend dependencies — do not implement in this UI task

A separate Firebase/Backend team must define and own:
- Authoritative event generation and recipient authorization.
- FCM token storage, refresh, invalidation, and account/device association.
- Notification outbox/delivery retries and deduplication.
- In-app notification persistence, read state, and pagination.
- Safe payload schema and deep-link allowlist.
- Delivery/audit observability and sensitive-data redaction.

The Partner client must not create authoritative operational notifications, mark provider delivery as successful, or decide that an event is eligible for a push. Do not add Firestore collections, Rules, Functions, FCM triggers, token writes, or deployments in this Partner UI task.

## Acceptance checklist for a future implementation

- [ ] Product-approved notification categories and critical-alert policy exist.
- [ ] Backend contract and access rules are supplied by the Firebase/Backend team.
- [ ] Permission request is contextual and handles denied states.
- [ ] Token registration/refresh/sign-out lifecycle is tested.
- [ ] Foreground, background, and terminated delivery are tested on real Android devices.
- [ ] Notification tap routing validates authenticated user and authorized resource.
- [ ] Inbox handles pagination, read/unread, empty, loading, and errors.
- [ ] Duplicate/out-of-order events do not create confusing duplicate UI.
- [ ] Sensitive booking, customer, KYC, and payment data is not exposed in notification payloads or logs.
- [ ] Tests cover permission states, token lifecycle, payload validation, routing, and inbox state.

## Recommended next step

Keep both existing entry points honest as “Coming soon” until the backend team provides an approved notification contract. Once that contract exists, implement the Partner-side permission UX, inbox, and safe navigation as a separate scoped change. No notification SDK or operational write path should be added speculatively.
