# Partner / Walker UI — Notion Alignment Checklist

Canonical reference: [DOJO WALK — Unified UI/UX Design System](https://app.notion.com/p/405756abedb9819db5abcb5196a2f23d)

## Design direction
Modern Premium, minimal, action-first mobile UI. Live Walk is map-centric; keep the most important action obvious and safety controls clear.

## Shared tokens
- Orange: #FF7900
- Warm background: #FFFAF5
- Primary text: #252525
- White surfaces, subtle borders/shadows, readable typography, rounded cards and consistent icon style.
- Motion should be purposeful and should not block critical actions.

## Partner screen requirements
- Home: real next walk, current status, availability, next best action, no fabricated metrics.
- Schedule: today's assigned walks, clear confirmed/pending distinctions, availability management.
- Onboarding: applicant/review/verified status; do not allow work before required checks, training and authorized activation.
- Booking offers: clearly show offer vs accepted assignment; prevent duplicate/ambiguous actions.
- Live Walk: map/route, booking and pet instructions, GPS freshness, safe start/complete flow, return/handover confirmation and incident reporting.
- Earnings: verified records only; separate earnings from customer payment; show payout status from trusted data.
- Profile/support/incidents: clear status and permission-aware access, minimal customer data exposure.

## Required states
Loading, empty, error, permission denied, pending/review, disabled action with reason, and confirmed success. Do not show success until trusted operation confirms it. Do not substitute query failures with zero amounts or fake booking data.

## Policy dependencies
- POL-025 — Walker recruitment, verification, onboarding and training.
- POL-026 — Walker availability, booking assignment and replacement.
- POL-013 — Walker earnings and payout.
Draft policies remain draft; this document does not approve business rules.

## Screen-by-screen implementation audit

### Reviewed / changed in the working branch
- [x] Shared Material 3 theme tokens added for orange, warm background, primary/muted text and borders.
- [x] Mobile login and OTP screens use the shared warm background and shared neutral border/background tokens where applicable.
- [x] Account-check screen uses shared background/border tokens for reviewed neutral surfaces.
- [x] Work-location, KYC document, live-selfie, current-address, review-submit and application-submitted screens use shared background/border tokens for reviewed neutral surfaces; selected/accent surfaces in work-location, KYC documents and current-address now use shared orange-alpha tokens.
- [x] Schedule screen no longer fabricates booking cards; it explains that confirmed walks appear when available.
- [x] Home distinguishes booking-query failure from a genuinely empty day, shows a retry action, and avoids displaying zero walk/hour metrics while the query is unavailable.
- [x] Home no longer claims a fixed “Working” state; it reflects whether a schedule is configured and offers a Manage action.
- [x] Notification and leave-request placeholder taps now explain that the feature is not available yet instead of doing nothing.
- [x] Fixed CI-discovered invalid `const DojoPartnerTheme.*` references in Live Walk and Profile. Run 210 passed analysis and tests after adding the missing-booking-ID regression test; its APK build was still in progress at last check.
- [x] Earnings screen no longer displays sample balances or fake ledger entries.
- [x] Walk completion no longer displays a default ₹0 or an unverified payout amount; it clearly says earnings appear after verification in the Earnings screen.
- [x] Added a widget regression test to ensure walk completion shows pending verification and not `₹0.00` when no verified payout is supplied.
- [x] Working-schedule days default to off until the Partner explicitly selects availability.
- [x] Placeholder Partner/Walker ID removed from reviewed home/profile UI.
- [x] Live Walk neutral surfaces and Partner Profile borders use the shared theme tokens.
- [x] Pickup navigation prevents progress when the booking ID is missing, shows a support message, and has a regression widget test.
- [x] Pickup navigation map placeholder, action panel border, slider surface and slider border use shared theme tokens.
- [x] Walk Details information notice now uses shared orange-alpha and border tokens instead of one-off hex colors.
- [x] Splash screen background, loading indicator and branding text use shared theme tokens.
- [x] Theme-token/widget tests passed on PR-head CI; later earnings and Walk Details changes were also validated by their completed workflows (see run evidence below).

### Not yet verified / remaining
- [ ] Inspect every authentication and onboarding screen for all visual states, accessibility, responsive layout and consistent spacing; remaining hard-coded semantic/status colors need review.
- [ ] Verify account status routing against approved POL-025 rules; do not infer verification/activation from UI alone.
- [ ] Review booking offers, walk start/complete, GPS permissions/freshness, incidents, notifications, profile and support.
- [x] GitHub Actions run 205 for commit `3d4da0ffb8e162f5b8c217d5ba620792dfa64620`: Flutter analysis, Flutter tests, release APK build, and APK artifact upload all completed successfully. Artifact: `dojo-walk-partner-release-apk` (about 43.5 MB; expires 2026-11-05). This verifies that earlier commit only, not the latest UI edits.
- [x] Run 213 (`40926210293`) for app-code commit `110bc7bf005f9b1fe43ed1e1ac60a2c00ae3d3a9` completed successfully: analysis, tests, release APK build and artifact upload passed. Artifact `dojo-walk-partner-release-apk` is about 43.5 MB and expires 2026-11-05.
- [x] Run `40927287906` for walk-completion UI commit `62bb8da51f1dbc3b51b95d7ac82892896e481f7c` completed successfully.
- [x] Run `40927504431` for regression-test commit `b7efa959ff5c8e20e8accd6ad23b721c975542a8` completed successfully: Flutter analysis, tests, release APK build and artifact upload passed.
- [x] Run `40928091894` for Walk Details theme commit `1a4519d0f6218b0f880350297bca46252088ee5b` completed successfully.
- [ ] Latest checklist-only commit `9113d57177b59440460832bf8b4f43dbc785c0ef` has workflow run `40928117487` still in progress at last check; wait for its completion before claiming that docs-only commit has CI confirmation.
- [ ] Integration tests and web/device visual QA remain outstanding.
- [x] Inspected failed CI run 188: `flutter analyze` found invalid `const DojoPartnerTheme.*` references in Live Walk and Profile. The references were corrected and the latest PR-head run 205 completed analysis, tests, APK build and artifact upload successfully.
- [ ] Capture device screenshots and compare against the Notion reference.
- [ ] Firebase integration/security remains a separate phase; no claim of backend validation is made.

Checklist marks mean source review/change only, not test pass or policy approval.
