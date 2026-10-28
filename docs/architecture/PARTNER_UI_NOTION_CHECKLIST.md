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

## Verification status
Theme tokens updated in the working branch. Schedule and earnings mock content removed from the reviewed screens. Remaining Partner screens still require a screen-by-screen code audit, device screenshots, Flutter analyze/tests and flow verification. Firebase integration/security remains a separate phase.
