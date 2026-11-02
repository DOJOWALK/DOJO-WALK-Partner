# DOJO WALK Partner App — AI Contributor Instructions

## Project scope
This is the DOJO WALK Walker/Partner Flutter app. The root `pubspec.yaml` includes Firebase Auth, Firestore, Storage, camera, ML Kit face detection, image processing, image picker, geolocation, and Google Maps. Firebase Functions are configured from the `functions` directory.

## Required workflow
1. Inspect the relevant screen, services, models, permissions, and tests before changing code. Follow existing patterns and preserve current app contracts.
2. Use the repository's Flutter/Dart configuration. Run `flutter pub get`, `flutter analyze`, and relevant `flutter test` tests where available.
3. For Firebase Functions changes, inspect the Functions package scripts and tests, then run the repository's existing checks.
4. Add tests for new state transitions, permission decisions, and failure paths. Report commands and actual results; do not claim unrun checks passed.

## Product and operational constraints
- Treat walker identity, KYC, selfie, GPS, booking, and walk-session data as sensitive.
- Enforce authorization in trusted backend rules/functions; never rely only on client-side checks.
- Preserve the distinction between booking ID and walk ID.
- A live walk must retain its safety lifecycle: GPS/check-in, active tracking, completion/stop events, and safe handover for emergencies. Do not silently cancel or stop a running walk.
- Do not invent KYC approval, availability, assignment, payout, or GPS success states.
- Do not weaken location, camera, photo, or identity protections to bypass a test.

## Security and release boundaries
Never commit real KYC images, selfies, customer data, tokens, API keys, or service-account files. Do not deploy Functions or change production Firebase settings/secrets without explicit owner approval.

## Pull requests
Work on a feature branch, never directly on `main`. Include affected flows, privacy/security impact, device permission behavior, tests, and rollback notes. Production deployment and merge require owner approval.


## Mandatory DOJO WALK engineering operating rules (Notion-aligned)

The Notion AI Engineering Control Center and Four Team AI Coding Instructions are the operating source of truth. Central Task Register: https://app.notion.com/p/2f476768c6f14aec9e70bf04afd83df8

Before editing:
- Read the assigned task, linked spec/policy and relevant team page; inspect this repository's current source, root instructions, working tree, active branch, recent commits and open PRs.
- Record the task ID, repository, exact active branch, current commit SHA, scope, acceptance criteria, dependencies and test plan.
- Continue the exact active branch recorded for the task. Do not create a replacement branch merely because a chat/session changed. Check for duplicate or overlapping work first.
- If a required product decision, backend contract or approval is missing, stop and report BLOCKED with the precise question. Do not guess.

During and after implementation:
- Make the smallest safe change within the assigned task. Do not silently change product policy, API/data contracts, schema, permissions, security rules or payment behavior.
- Coordinate shared contract changes with the owning team before parallel client work. Team 01 owns shared backend contracts; consuming teams must use approved versioned contracts.
- Never force-push, delete branches, close historical PRs or overwrite unmerged work without explicit approval.
- Run relevant checks and record exact commands/workflows, timestamps, results and the exact commit SHA tested. Use PASS only for checks that actually passed; use FAIL for failures and NOT RUN for checks not executed.
- PR/handoff notes must include task ID, scope, risk, affected repositories, branch, PR, exact SHA, contract/schema version where relevant, test evidence, blockers and rollback notes.
- Obtain independent review for security, permissions, payments, KYC, GPS/location and data-migration changes. Merge and production deployment require the required human approval.
- A green CI result applies only to the checks run on that exact SHA; it is not blanket production-readiness approval.

Do not mark work complete until acceptance criteria, required test evidence, review/approval, PR/release state and receiving-team handoff are accurately recorded.


## Existing work preservation
The Notion team instructions record `chore/notion-aligned-structure` and open PR #5 as existing Partner work. Verify their live GitHub state and the Central Task Register before choosing a branch. Preserve PR #5 and all audit/feature branches unless a fresh evidence-based review and explicit authorized decision permit a change.
