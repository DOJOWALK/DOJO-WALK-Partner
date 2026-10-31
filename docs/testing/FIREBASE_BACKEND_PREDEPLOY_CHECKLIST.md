# Firebase Backend Pre-Deployment Checklist — DOJO WALK Partner

Status: **Blocked / not approved for deployment**. This checklist is a release gate, not proof that production Firebase is configured or working.

## 1. Founder / policy approval
- [ ] Confirm approved Notion versions and status of POL-006 (Customer Booking & Eligibility), POL-007 (Live Walk & Safe Handover), and POL-026 (Walker Availability, Assignment & Replacement).
- [ ] Approve the exact booking source status allowed to enter completion.
- [ ] Approve required handover evidence, authorized recipient evidence, GPS-unavailable handling, emergency/incident exception behavior, and completion response shown to the Partner.
- [ ] Confirm field names/types against the shared Customer/Admin/Partner Firestore schema. Do not derive the contract from the Partner UI alone.

## 2. Firebase project and deployment source
- [ ] Identify the actual Firebase project ID and environment used by Partner, Customer and Admin.
- [ ] Capture the deployed Firestore rules version/source and deployment command from the authorized project owner.
- [ ] Review the shared rules as a whole before adding or replacing a rules target. The current repository `firestore.rules` is not proven to be the deployed rules source.
- [ ] Verify Firebase Functions runtime, region, environment configuration, IAM and deployment identity.
- [ ] No production deploy or rules change until review and explicit release authorization.

## 3. Trusted completion endpoint
- [ ] Require Firebase Auth and derive walker UID only from verified auth context.
- [ ] Verify booking exists, assigned walker matches, and source status is policy-approved.
- [ ] Validate request ID, numeric bounds, timestamps, coordinates, route point limits and required evidence.
- [ ] Use a Firestore transaction / equivalent atomic backend operation to persist the walk and booking transition.
- [ ] Use a stable idempotency key/reference so retries and concurrent calls cannot create multiple walk records.
- [ ] Keep customer data private; use server timestamps and server-side audit events where the approved schema defines them.
- [ ] Return a stable result with walk ID, authoritative booking status and replay indication; do not report success before the trusted operation commits.

## 4. Emulator / automated tests required
- [ ] Unauthenticated caller rejected.
- [ ] Assigned walker with valid approved state succeeds.
- [ ] Wrong walker and unassigned booking rejected.
- [ ] Missing booking and unsupported source state rejected.
- [ ] Duplicate and concurrent requests create only one completion record.
- [ ] Retry after ambiguous network response returns the same walk ID.
- [ ] Invalid coordinates, route size, duration, counts and request ID rejected.
- [ ] GPS unavailable remains explicitly unverified; no fabricated start timestamp.
- [ ] Transaction failure leaves booking and walk state consistent.
- [ ] Firestore Rules tests cover customer privacy, walker isolation, admin access, and default-deny behavior.
- [ ] Run Functions unit tests and Firestore Emulator tests in CI; capture logs/results as release evidence.

## 5. Client integration and release verification
- [ ] Replace Partner direct completion writes only after the callable contract is approved and implemented.
- [ ] Confirm loading, failure, retry, duplicate response, GPS-permission and incident states on a physical Android device.
- [ ] Test against a non-production Firebase project using the actual shared schema.
- [ ] Verify rules/functions deployment revision and smoke-test results after authorized staging deployment.
- [ ] Confirm CI analysis, widget/unit tests, emulator tests, release APK build and artifact upload for the exact PR head.
- [ ] Keep PR draft until policy approvals, security review, emulator evidence and device QA are complete.

## Current known repository blockers (checked 2026-10-30)
- Root `firebase.json` declares Cloud Functions only; it does not configure Firestore rules.
- The checked-in `firestore.rules` has no `/walks/{walkId}` match and the default-deny rule denies unmatched paths.
- The checked-in assigned-walker booking update allowlist excludes some fields written by the current client completion batch.
- `functions/index.js` exports only `checkBackend`; trusted Live Walk completion is not implemented.
- These observations describe repository files only. They do **not** establish which rules are deployed to production.
- POL-006, POL-007 and POL-026 were observed as draft/unapproved; exact completion semantics must not be invented.

## Evidence links
- [ADR-002 — Live Walk idempotency](../decisions/ADR-002-live-walk-idempotency.md)
- [ADR-003 — Firestore Live Walk rules gate](../decisions/ADR-003-firestore-live-walk-rules-gate.md)
- [ADR-004 — Firebase deployment configuration audit](../decisions/ADR-004-firebase-deployment-config-audit.md)
- [ADR-005 — Live Walk completion backend contract](../decisions/ADR-005-live-walk-completion-backend-contract.md)
