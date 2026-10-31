# Partner Notifications UI Blueprint — 2026-10-31

## Status and scope
- Status: UI/product blueprint only; not implemented.
- Repository: `DOJOWALK/DOJO-WALK-Partner`
- Target branch: `chore/notion-aligned-structure`
- This document does not authorize Firebase/backend changes.
- No FCM SDK, local-notification SDK, Firestore schema, security rules, Functions, token writes, or deployment changes are included.
- The Partner app must not display fabricated operational notifications or claim delivery/read receipts without an authoritative source.

## Current source audit
- Partner Profile's Notifications row currently opens a placeholder dialog.
- `pubspec.yaml` has no visible Firebase Messaging or local notifications dependency.
- Android manifest declares `POST_NOTIFICATIONS`; a manifest permission alone does not implement runtime permission handling or push delivery.
- The existing Firebase/backend team owns delivery, token registration, event creation, inbox persistence, read state, and security.
- Findings are source-level only; no production device or deployed backend behavior was verified.

## Proposed Partner UI

### 1. Notification Inbox
Entry point: Profile > Notifications; a home badge may be added only when a trusted unread count is available.

Screen states:
1. Loading — neutral skeleton rows.
2. Populated — newest first, grouped by Today / Earlier.
3. Empty — “You're all caught up” with a quiet illustration/icon.
4. Error — plain-language message and Retry.
5. Offline/stale — show last successfully loaded data with a “May be out of date” note, if cache support is later provided.
6. Unsupported/not connected — explain that notifications are not available yet; do not fabricate sample events.

Each notification row may display:
- Title and concise message.
- Event timestamp, formatted in device locale.
- Category icon and optional non-sensitive reference label.
- Unread visual treatment only when server-provided read state exists.

Interactions:
- Open a notification only when its destination and entity are authorized and validated.
- Mark-as-read must be a trusted, idempotent operation; UI must not optimistically claim success if the request fails.
- “Mark all as read” should appear only after backend contract and confirmation behavior are defined.
- No arbitrary external URLs or unvalidated document paths from notification payloads.

### 2. Notification Preferences
Proposed categories (final list requires product/backend agreement):
- Booking and walk updates.
- Schedule or availability updates.
- Earnings and payout updates.
- Account and KYC updates.
- Support request updates.
- Important service announcements.

Preference behavior:
- Display saved server preference values when available.
- Until a read/write contract exists, show settings as unavailable/read-only; do not make toggles appear saved.
- Distinguish essential account/security notices from optional categories. Do not offer a global mute that suppresses essential safety/account notices unless policy explicitly allows it.
- Explain that device-level notification permission is separate from in-app category preferences.
- Request OS permission contextually, only after the delivery implementation exists and the user understands the benefit. Respect denial and provide an OS-settings explanation without repeatedly prompting.

### 3. Navigation and privacy
- Booking notification → validated booking/occurrence detail.
- Walk lifecycle notification → validated assigned walk detail.
- Earnings/payout notification → earnings screen.
- KYC/account notification → KYC status or account status screen.
- Support notification → relevant support request, if a secure detail route exists.
- If target is missing, stale, unauthorized, or unsupported, open the inbox item and show a safe fallback message.
- Never include Aadhaar/PAN numbers, OTPs, precise live location, private document URLs, or payment credentials in notification title/body/preview.
- Notification previews must be safe on a locked screen.

## Backend-owned contract dependencies (not implementation instructions)
Before wiring the UI, the backend team should publish and own:
- Stable notification ID and event type.
- Recipient identity and authorization model.
- Server-created timestamp and immutable event identity.
- Read/unread state and idempotent mark-read operation.
- Cursor-based pagination and ordering.
- Category preference read/update contract, validation, and defaults.
- Device-token registration, rotation, invalid-token cleanup, and logout handling.
- Delivery failure/retry policy and in-app inbox persistence.
- Deep-link target type and target ID validation.
- Retention/deletion policy and audit expectations.

The Partner client should consume the approved contract; it must not invent or write notification records directly.

## Acceptance checklist for a future UI implementation
- [ ] Profile Notifications row opens the real inbox screen.
- [ ] Loading, populated, empty, error, and unavailable states are covered.
- [ ] Unread count is sourced from an authorized server response.
- [ ] Pagination does not duplicate or skip items.
- [ ] Read state reflects server confirmation and is retryable.
- [ ] Deep links validate target type, ID, and current user access.
- [ ] Preferences clearly distinguish saved, unavailable, and unsaved states.
- [ ] OS permission denial does not block app use or cause repeated prompts.
- [ ] Sensitive data is excluded from notification content and lock-screen previews.
- [ ] Widget tests cover all states and navigation fallbacks.
- [ ] No Firebase/backend source or configuration is changed in the Partner repository.

## Explicit non-goals
- No backend schema or callable function implementation.
- No Firestore rules or Firebase deployment.
- No FCM/local notification package installation yet.
- No token registration or direct client writes.
- No fake inbox content presented as real user activity.
