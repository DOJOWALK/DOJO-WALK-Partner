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
- [x] Work-location, KYC document, live-selfie, current-address, review-submit and application-submitted screens use shared background/border tokens for reviewed neutral surfaces.
- [x] Schedule screen no longer fabricates booking cards; it explains that confirmed walks appear when available.
- [x] Home distinguishes booking-query failure from a genuinely empty day, shows a retry action, and avoids displaying zero walk/hour metrics while the query is unavailable.
- [x] Earnings screen no longer displays sample balances or fake ledger entries.
- [x] Working-schedule days default to off until the Partner explicitly selects availability.
- [x] Placeholder Partner/Walker ID removed from reviewed home/profile UI.
- [x] Live Walk neutral surfaces and Partner Profile borders use the shared theme tokens.
- [x] Splash screen background, loading indicator and branding text use shared theme tokens.
- [x] Theme-token/widget tests were updated in source, but have not yet been executed.

### Not yet verified / remaining
- [ ] Inspect every authentication and onboarding screen for all visual states, accessibility, responsive layout and consistent spacing; remaining hard-coded semantic/status colors need review.
- [ ] Verify account status routing against approved POL-025 rules; do not infer verification/activation from UI alone.
- [ ] Review booking offers, walk start/complete, GPS permissions/freshness, incidents, notifications, profile and support.
- [ ] Latest Flutter analyze, widget tests, integration tests and web/device build must be re-run after the recent commits.
- [x] Inspected the prior failed CI log: `flutter analyze` stopped on an unused theme import in the splash screen; the import is now used by the splash UI. This fix is not yet confirmed by a fresh successful run.
- [ ] Capture device screenshots and compare against the Notion reference.
- [ ] Firebase integration/security remains a separate phase; no claim of backend validation is made.

Checklist marks mean source review/change only, not test pass or policy approval.
