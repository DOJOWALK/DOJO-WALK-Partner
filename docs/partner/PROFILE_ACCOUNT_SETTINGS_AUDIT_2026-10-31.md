# DOJO WALK Partner — Profile & Account Settings Audit

**Audit date:** 2026-10-31  
**Repository:** `DOJO-WALK-Partner`  
**Branch:** `chore/notion-aligned-structure`  
**Scope:** Partner app source inspection only  
**Backend/Firebase changes:** None

## Executive summary

The Profile screen is partially implemented. It reads and displays Partner profile information, provides a read-only Personal Details sheet, links to a read-only KYC status screen, opens Partner Support, and supports Firebase Auth logout. General Settings, editable personal details, and account security management are not implemented.

## Findings

| Area | Current source behavior | Result |
|---|---|---|
| Profile data | Reads `walkers/{uid}` once using `.get()` | Read-only display; not live-updating |
| Name / phone | Shown in profile and Personal Details sheet | Read-only; no edit action |
| Partner ID / zone / service / rating | Read from profile document with fallbacks | Missing values show placeholders |
| Verification badge | Derived from `status`, `isApproved`, `isActive`, and `applicationSubmitted` | Better than a hard-coded Verified label; source-derived only |
| Documents & KYC | Opens `KycStatusScreen`, which reads the Partner document | Status-only, no document image/path exposure |
| General Settings | Settings icon opens Coming Soon dialog | Not implemented |
| Notification preferences | Opens Coming Soon dialog | Not implemented; see separate Notifications audit |
| Account security | No password reset, PIN, device/session management, or account recovery settings found in inspected Profile flow | Not implemented; login is phone OTP |
| Logout | Confirmation dialog then `FirebaseAuth.instance.signOut()` | Implemented |
| Account gate | `AccountCheckScreen` reads `walkers/{uid}` and routes only approved + active + approved-status accounts to Home | Client-side navigation gate; not a substitute for backend authorization |
| Application status | Submitted screen listens to the Partner document and displays status | Source has live status display for application flow |

## Important observations

1. **Personal Details is not an edit screen.** The Profile action opens a bottom sheet showing full name, mobile number, and Partner ID. The onboarding Personal Details form is separate; do not assume the Profile action lets an existing Partner edit their details.
2. **Profile data can become stale.** The Profile screen loads once with `.get()`; it does not subscribe to changes. A refresh/reload strategy should be considered when returning from detail screens or after an approved profile update.
3. **KYC status and profile badge are different views of similar account fields.** Keep status mapping consistent, and never infer that uploaded documents are verified merely because files exist.
4. **AccountCheck is a client-side gate.** Backend security and callable operations must independently validate current Partner eligibility. Do not rely on the Flutter route guard as an authorization boundary.
5. **Logout is present.** The source signs out the Firebase Auth user after confirmation. No additional local notification token cleanup/session-device revocation flow was found in this app audit; token lifecycle is part of the separate notifications/backend contract.
6. **No account deletion flow was found.** Do not add a self-service delete button until retention, legal, payout, incident, and identity-document obligations are defined by product/legal and backend owners.

## Recommended Partner UI scope

A future Profile & Settings implementation should be divided into:

- **Profile overview:** name, masked mobile, Partner ID, verification state, and work zone.
- **Personal details:** read-only by default; an edit request flow only after fields, approval rules, and backend ownership are agreed. Phone-number changes must require re-verification.
- **KYC & verification:** status and correction guidance; no public document URLs or raw storage paths.
- **Account security:** OTP-based sign-in explanation, verified phone change/recovery flow when supported, and session/device controls only when backend supports them.
- **Preferences:** notification preferences only after notification categories and delivery support are approved.
- **Support:** retain the existing DOJO Support entry point.
- **Logout:** keep confirmation and clear signed-out navigation.

## Dependencies / safety boundaries

- Do not write to `walkers/{uid}` from a new settings form without an approved field contract and authorization design.
- Do not let the client change `isApproved`, `isActive`, `status`, KYC review fields, Partner ID, payout details, or operational eligibility.
- Do not add account deletion or document deletion from the client without a retention and audit design.
- Do not modify Firebase Rules, Functions, backend repositories, production data, or deploy anything as part of this audit.

## Acceptance checklist for future UI work

- [ ] Product defines which profile fields Partners can edit directly versus request for review.
- [ ] Phone changes require fresh OTP verification and safe account re-association.
- [ ] Profile refreshes after returning from an approved edit/status flow.
- [ ] KYC labels are consistent across Profile, KYC Status, and application status screens.
- [ ] Security settings show only actions backed by real supported flows.
- [ ] Logout reliably clears the authenticated session and returns to login.
- [ ] Account eligibility is enforced by trusted backend operations, not only client navigation.
- [ ] No sensitive KYC or payment information appears in profile summaries or logs.

## Recommended next step

Keep the current read-only profile and KYC presentation. Do not add speculative edit/security writes. First obtain the product-approved editable-field and account-recovery rules, then implement the Partner UI against the separate team's approved contract.
