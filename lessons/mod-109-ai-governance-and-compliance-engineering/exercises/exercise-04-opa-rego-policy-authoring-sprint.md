# Exercise 04 — OPA/Rego Policy Authoring Sprint

**Estimated effort:** ~4 hours
**Deliverable:** A **versioned policy pack** that enforces the
exercise-01/02/03 control matrix at a real ML-platform
chokepoint, consisting of (a) ≥ 5 Rego policies — at minimum
model-card completeness, DP-budget-within-tier, eval-bundle-
current, approvals-present, and a sector-reg / tier-policy
policy sketched for exercise 05, (b) positive and negative
test cases per policy using `opa test`, (c) a composed
release-gate policy that returns a structured decision with
reasons and remediation hints, (d) a corpus of representative
deployment inputs (allowed, denied, exception) that the pack
is executed against with the decisions retained, and (e) a
decision-retention design describing where the decisions are
stored, under what retention, and how they are produced as
Clause 9.1 / Article 72 evidence.
**Prerequisites:** Exercise 01–03 complete; the unified matrix
in a machine-parseable form; chapter 04 read end-to-end;
chapter 03 `data-governance.yaml` and `logging-spec.yaml`
available for the dp-budget and logging policies. OPA
installed locally (via Docker image or binary). Familiarity
with Rego v1 syntax recommended; the official OPA tutorial is
sufficient preparation.

---

## Objective

Chapter 04's claim is that **a matrix without executable
gates is paper; a gate without reasons and remediation is
noise**. This exercise is the exercise that produces the
pack, runs it, retains the decisions, and tests the
policies hard enough that refactoring the pack later is
safe.

By the end of this exercise you have:

- A **policy pack** of ≥ 5 Rego policies, each one tied to a
  specific matrix row and encoding a specific obligation.
- **Tests per policy** that cover the positive path, the
  deny path with the specific violation surfaced, and the
  abstain path (the gate not applying to the input).
- A **composed release-gate** that aggregates per-control
  violations into a single decision document.
- A **representative-input corpus** with ≥ 10 inputs
  spanning allow, deny-single-violation, deny-multiple-
  violations, and exception-granted outcomes.
- A **decision-retention design** describing storage,
  retention, access, and how the stored decisions answer
  "prove your gate ran for release X" to a Clause 9.1
  auditor and an Article 72 post-market monitor.
- An **exception-path specification** stating what a
  policy exception looks like, who can sign one, how long
  it lives, and how it is itself audited.

You are **not** deploying the pack to a production chokepoint,
replacing the org's existing admission control, or
removing human reviewers from the release-gate meeting. You
are producing the pack and the evidence that it works.

---

## Problem statement

Pick one chokepoint — CI, training-job submission,
model-registry promotion, or runtime serving — and author
the pack for it. The chokepoint determines the input shape
and the useful policies. For most teams,
**model-registry promotion** is the right first chokepoint
because it binds to the matrix rows most densely; this
exercise defaults to that chokepoint unless you have reason
to pick another.

State before you start:

- The chokepoint and the system that submits the input (the
  registry service, the training scheduler, the CI runner).
- The input-schema version — a stable `input_schema.json`
  that the submitter emits and the policies consume. If
  the submitter is hypothetical, write the schema in this
  exercise.
- The data the policies load (`data.controls`,
  `data.tier_map`, `data.approved_signers`,
  `data.pack_meta`). State where it lives, how it is
  updated, who approves changes.

If the target chokepoint already has an admission policy in
some other engine (Kyverno, custom webhook), this exercise
is **shadow mode** — the OPA pack runs beside the existing
gate, decisions are logged but not acted on. State that
posture.

---

## Requirements

### Deliverable A — the five (or more) policies

Each policy is one `.rego` file plus one `.rego` test file
in a package named after the matrix row(s) it implements.
Minimum set:

1. **`model_card_completeness`** — required fields on the
   model card (chapter 04 example). Which fields are
   required is driven by the matrix row for GV-1.1, MP-1.1,
   MS-2.7, MP-5.1 as a baseline.
2. **`dp_budget_within_tier`** — the DP budget request on a
   training-job input lies inside the mod-108 chapter 01
   tier-map band. Exception path allowed with a signed,
   unexpired, scoped executive approval.
3. **`eval_bundle_current`** — the eval bundle referenced
   by the input is less than N days old; its measured
   metrics meet or exceed the production thresholds; the
   eval was run against the model version being promoted.
4. **`approvals_present`** — the input lists the approvals
   required for the target action and target stage, each
   approval is from an approved signer for the role, and
   no approver signed outside their quorum role.
5. **`deployment_tier_gate`** — the system's declared
   chapter-06 tier matches the required-evals bundle and
   the required-controls set; a mismatch denies with a
   remediation hint pointing to the correct tier
   definition.

Pick a sixth policy from one of the sector-reg or AI Act
obligations surfaced in exercises 03 and 05 — for example a
**`logging_sink_configured`** policy enforcing the Article
12 logging spec, or a **`fda_pccp_within_scope`** policy
enforcing the SaMD PCCP boundary. The sixth policy is the
hook for exercise 05's sector overlay.

Rules every policy follows (chapter 04 § hygiene):

- **One control per file.** No multi-control monoliths.
- **`gated_actions`** named explicitly; the policy
  **abstains** (allows) when the action is not in scope.
- **Data loaded, not hard-coded.** Field lists, tier maps,
  approver lists come from `data.*`, not from literals in
  the policy. Test with mock `data` in the test file.
- **Violation objects carry `rule`, cross-refs
  (`nist` / `iso` / `eu_ai_act` / `soc2` / `sector` / `tier`),
  and `remediation`.** No ruleless violations; no
  cross-ref-less violations; no "see docs" remediations.
- **`default allow := false`** at the top; `allow` is the
  conjunction of "applies" and "no violations" or "exception
  granted".

### Deliverable B — tests per policy

Each policy has a sibling `*_test.rego` with at least:

- `test_allow_when_everything_present` — baseline accept.
- `test_deny_when_<field>_missing` — one per required
  field or constraint.
- `test_abstain_for_<non_gated_action>` — baseline abstain.
- `test_allow_when_exception_granted` — if the policy has
  an exception path.
- `test_deny_when_exception_expired` / `_invalid_signer` /
  `_wrong_scope` — exception path edge cases.
- `test_remediation_hint_mentions_<field>` — a smoke test
  that violation objects include the remediation hint; this
  prevents refactors from silently stripping the hint.

Run as:

```bash
opa test -v policies/ tests/
```

Target coverage: **every rule evaluated by at least one
positive and one negative test**. Rego's branching makes
untested branches easy to miss; `opa test --coverage` is
available in recent versions and should be used.

### Deliverable C — composed release-gate

A composed policy — e.g. `aicg.gates.model_promotion` —
that imports the five / six per-control policies and
produces a single `decision` object:

```json
{
  "allow": false,
  "reasons": [
    {
      "rule": "impact_assessment_stale",
      "field": "impact_assessment_last_reviewed",
      "nist": "MP-3.1",
      "eu_ai_act": [27],
      "age_days": 402,
      "remediation": "Refresh impact assessment; re-run FRIA review; update the last_reviewed date."
    }
  ],
  "policy_version": "2026.10.04",
  "evaluated_at_ns": 1759572000000000000
}
```

The composed gate exports `data.aicg.gates.model_promotion.decision`.
Downstream consumers (the registry promotion handler, the CI
job, the review-board dashboard) read this one object.

Test the composed gate with its own `_test.rego` that
exercises the aggregation — e.g. two per-control
violations produce a decision with two reasons; a lone
abstention produces an abstention.

### Deliverable D — representative-input corpus

A folder of ≥ 10 input JSON files under
`corpus/` with a naming convention like
`001-allow-happy-path.json`, `002-deny-model-card-field-missing.json`,
`003-deny-dp-budget-exceeds-tier.json`,
`004-deny-eval-bundle-stale.json`,
`005-deny-approval-missing-pm.json`,
`006-deny-approval-expired-signer.json`,
`007-allow-exception-granted.json`,
`008-abstain-staging-promotion.json`,
`009-deny-multiple-violations.json`,
`010-allow-tier-0-passthrough.json`.

Each file is a complete `input` matching the input schema.
A `run.sh` (or `Makefile` target, or `pytest` harness) runs
every input through the composed gate using `opa eval` and
asserts the expected outcome:

```bash
opa eval --data policies/ --data tests/data \
         --input corpus/001-allow-happy-path.json \
         'data.aicg.gates.model_promotion.decision'
```

The script produces a short summary table (input →
expected / actual outcome; expected / actual reasons count).

If any input's actual outcome diverges from the expected,
the exercise flags the policy pack as not yet shippable.

### Deliverable E — decision-retention design

A short document (`decision-retention.md`) with:

- **Where decisions are stored.** Append-only object
  storage keyed by `release_id` + `evaluated_at_ns`; or an
  internal evidence database; or a dedicated audit log. Name
  the storage and the access path.
- **What is stored.** The full input (with any secrets
  elided per org policy); the full decision; the policy
  pack version used; the actor that triggered the
  evaluation. Chapter 04's point: *the decision is a
  document, not a bit*.
- **Retention.** Length tied to the regimes the system is
  under. Baseline: EU AI Act Article 12 asks six months
  minimum unless law provides otherwise; SOC 2 looks for
  one year; SR 11-7 model files are retained for the
  model's useful life + N; HIPAA § 164.316(b)(2)(i) asks
  for six years. State the retention and the authority for
  it.
- **Integrity.** Append-only; cryptographic chaining or
  object-storage write-once semantics; signing key
  reference (mod-105).
- **Access.** Who can read the decisions and under what
  controls; access is itself logged.
- **Use.** How the stored decisions are consumed —
  compliance dashboards; auditor "give me the release
  decisions for the last 90 days" query; post-market
  monitoring (Article 72) feedback loops; incident
  investigation.
- **Deletion / tombstoning.** For personal-data
  considerations (log entries that may include subject
  identifiers via caller IDs), the deletion / retention
  schedule aligned with the mod-108 chapter 03 DLP work.

### Deliverable F — exception-path specification

A short document (`exceptions.md`) with:

- **What an exception looks like.** Shape of the exception
  record (`type`, `signer`, `expires_at`, `matches`,
  `reason`, `created_at`). Example matches the chapter 04
  example.
- **Who can sign.** The `data.approved_signers.<type>` list
  per exception type and the authority behind it (ML
  Governance Lead; Executive Sponsor; Review Board).
- **How long exceptions live.** Default (90 days); maximum
  (12 months); the review that must happen before renewal.
- **How exceptions are audited.** Every exception grant is
  itself a decision in the retention store; an exception
  used past expiry fails the policy as if the exception
  did not exist; the quarterly exception review is a
  Clause 9.3 management-review input and a chapter 06
  review-board input.
- **Break-glass.** When an exception is granted mid-
  incident to allow a hotfix to ship outside the normal
  gate, the exception has stricter TTL (24–72 hours), the
  on-call executive signs, and a post-mortem is required.
  Describe the mechanism and the approval policy; do not
  pretend break-glass is a routine path.

### Deliverable G — matrix wire-up

Walk the matrix. For every row the pack enforces, add a
field `enforcement.policy: aicg.controls.<name>` pointing
to the specific Rego policy. Rows that are not yet
enforced by policy keep `enforcement.policy: null` and
remain `partial` / `planned` for Clause 9.2 and chapter 05
reporting.

### Deliverable H — integration note

A one-page README for the policy pack folder stating:

- Where this pack ships (CI job, registry hook, runtime
  admission controller) — even if shadow-mode.
- How to run the tests and the corpus locally.
- How the pack is versioned (semver; monotonically-
  increasing `data.pack_meta.version`).
- How a new policy is added — the author's checklist
  mirroring chapter 04's hygiene rules.

---

## Starter guidance

- **Start from the chapter 04 `model_card_completeness`
  policy.** It is directly reusable with small adjustments
  to the required-fields map.
- **Write the schema before the policy.** The input schema
  is the contract; the policies are the enforcement. Changing
  the schema after writing five policies is expensive.
- **Use `data.*` even where it feels like overkill.** The
  three-line policy becomes a ten-line policy with
  `data`-driven lists, and the test harness becomes trivial
  because mock data is set in the test file.
- **Keep `opa test` passing on every commit.** A single
  broken test blocks the pack; broken tests under commits
  are a signal to split the policy, not to disable the
  test.
- **Treat the corpus as part of the pack.** Shipped
  policies are only as trustworthy as their input corpus.
  Add corpus entries whenever you fix a bug or add a rule.
- **Use `--coverage` once you have five policies.** It
  surfaces the branches the tests do not touch; those
  branches are where production breakage comes from.
- **Keep the decision shape stable.** Downstream consumers
  (dashboards, Slack bots, release-gate UIs) bind to
  `allow`, `reasons`, `policy_version`. Breaking that shape
  requires a pack major-version bump.

---

## Acceptance criteria

A passing policy pack:

- Five or more policies, each with cross-refs to the
  matrix, data loaded (not hard-coded), remediation hints
  on every violation.
- `opa test` passes with ≥ 90% rule coverage (or a documented
  gap list for the uncovered rules).
- Composed release-gate aggregates per-control violations
  into a single structured decision with `policy_version`
  and `evaluated_at_ns`.
- Representative-input corpus has ≥ 10 inputs covering allow,
  deny-single, deny-multi, exception-granted, and abstain
  outcomes; the harness confirms expected = actual for each.
- Decision-retention design names storage, retention,
  integrity, access, use, and deletion; retention length is
  justified against at least one regime.
- Exception-path specification states signer, expiry,
  audit, and break-glass; the exception rego path is
  tested with positive and negative tests.
- Matrix `enforcement.policy` populated for the enforced
  rows.
- Integration note states shipping mode (enforce / shadow)
  and run-locally instructions.

A failing policy pack:

- Policies that hard-code field lists / tier maps / signer
  lists.
- Violations that lack `rule`, cross-refs, or `remediation`.
- Tests covering only the happy path.
- Composed gate that returns `allow=false` with an empty
  `reasons` array.
- Corpus that is only happy-path or lacks the exception /
  abstain cases.
- Decision retention stated as "we log it" with no retention
  length, no integrity property, no access control.
- Exception path that any signer can grant and that never
  expires.

---

## Stretch goals

- **CI integration.** Wire the policy pack into a GitHub
  Actions / GitLab CI pipeline job that runs on every PR
  touching the policy repo. Produces a PR status check
  that fails on new rule-coverage gaps.
- **Conftest harness.** Package the pack as a Conftest
  bundle so Kubernetes manifests (runtime admission) can
  be evaluated with the same policies as the registry
  promotion.
- **Gatekeeper constraint templates.** For the runtime-
  serving chokepoint, convert the composed gate into a
  Gatekeeper `ConstraintTemplate` so Kubernetes admission
  blocks non-compliant Deployments.
- **Decision streaming to Loki / Elastic.** A side-car that
  forwards each decision to the org's SIEM so an auditor
  can query decisions by matrix row, by rule, by actor.
- **Rule-coverage dashboard.** A simple report that
  tracks, over time, the number of matrix rows with
  `enforcement.policy` set vs the number without. A
  burn-down chart for governance.
- **Policy-pack version-bump automation.** A pre-merge hook
  that bumps `data.pack_meta.version` on any change to the
  `policies/` folder and fails if the bump is missing.
- **Pre-commit lint.** `opa fmt` + `opa check --strict` as
  a pre-commit hook so Rego formatting and shadowing bugs
  are caught before CI.
- **Chapter 06 tier TTL enforcement.** Extend the deployment-
  tier policy to deny promotion of a Tier 4 system whose
  last tier review is older than the tier's TTL. Produces
  the operational enforcement of the six-month Tier 4
  review cadence.
- **Exception quarterly report.** A query over the retained
  decisions that lists all granted exceptions in the
  reporting period, grouped by type. Produces the
  management-review (Clause 9.3) and review-board
  (chapter 06) feedback item.

---

## Do not

- Do not ship the pack in enforce mode to production
  without a shadow-mode run and a dry-run review. Enforce-
  without-shadow is how a legitimate release gets blocked
  by a bug in a policy that nobody caught.
- Do not grant the policy repo write access to the
  engineers whose deployments the policies gate. Separation
  of duties is the only reason the gate is a gate.
- Do not store secrets in the input or in `data.*`. If a
  policy needs a secret to evaluate, the secret is in the
  signer's attestation, not in the policy data.
- Do not treat `opa` version drift as a problem to solve
  later. Rego v1 and v0 are not interchangeable; pin the
  version in CI and in local tooling.
- Do not write policies that only deny. Rules that abstain
  (because the action is not in scope) must `allow` so the
  pack composes correctly.
- Do not use the composed gate to replace human review on
  tier 3 / 4 / 5 systems. The policy pack enforces the
  mechanical gates; the review board judges the hard
  cases.
- Do not commit the solution pack to this repo. Solutions
  live in the paired `-solutions` repo.
