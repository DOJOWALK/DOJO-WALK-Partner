# ADR-004: Firebase Deployment Configuration Audit

- Status: Confirmed repository configuration gap; deployment state is unknown.
- Scope: Firestore rules and Cloud Functions deployment configuration for the Partner app.
- Evidence on branch `chore/notion-aligned-structure`:
  - Root `firebase.json` configures only Cloud Functions (`source: functions`, runtime `nodejs22`).
  - It does not declare a Firestore rules path or Firestore indexes path.
  - `firestore.rules` exists in the repository, but the inspected Firebase CLI configuration does not associate it with a Firestore deployment target.
  - `functions/index.js` exports only `checkBackend`; no trusted Live Walk completion callable exists.
- Implication: A normal `firebase deploy` using this root configuration would not deploy the repository's `firestore.rules` as a Firestore rules target. This does not establish what is currently deployed in the Firebase project; rules may be deployed separately or from another repository/configuration.
- Decision: Do not wire the current rules file into deployment configuration yet, because the inspected rules deny `walks` writes and exclude fields used by the current completion batch. First design and test the intended secure completion flow and rules.
- Required next steps:
  1. Confirm the actual Firebase project, deploy command, CI workflow, and source of currently deployed rules.
  2. Reconcile the Partner rules with the shared production rules/source of truth; do not replace a shared production ruleset with this repository's rules without a reviewed merge plan.
  3. Implement a trusted, authenticated, idempotent completion transition and narrowly scoped authorization checks.
  4. Add Emulator Suite tests and CI checks for the rules/functions before adding deploy targets.
  5. Add explicit `firestore.rules` (and indexes if needed) configuration only after the rules are safe and verified; use preview/review before production deployment.
- Release gate: No production deployment or security-completion claim until deployed rules are identified and verified.
