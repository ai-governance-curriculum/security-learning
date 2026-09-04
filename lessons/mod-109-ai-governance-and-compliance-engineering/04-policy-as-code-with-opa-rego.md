# Chapter 04 — Policy-as-Code with OPA/Rego for ML Admission Gates

> **Note on AI-assisted content.** OPA (Open Policy Agent) is
> a CNCF graduated project; Rego is its policy language. The
> policy snippets below use current Rego v1 syntax. OPA and
> its ecosystem (Conftest, Gatekeeper, Kyverno-Rego bridge)
> evolve; verify current syntax against the official docs
> (see [`resources.md`](./resources.md)) before shipping to
> production.

---

## Why this chapter exists

Chapters 01–03 produced a control matrix — every row a
triple of outcome, control, and evidence artefact. That
matrix is documentation. The failure mode of documentation-
only governance is straightforward:

> The team ships a model for the release-gate meeting.
> Legal asks whether the model card has the Article 15
> accuracy metric. Someone opens the model card. The field
> is empty. The team promises to add it and re-runs the
> meeting next week. Two releases later, another team
> ships a model without the Article 10 representativeness
> report. The pattern is clear: gates that live only in
> human review are gates humans forget.

Policy-as-code turns the control matrix into **executable
rules**. Every deployment attempt is evaluated against the
rules; missing or malformed evidence blocks the deployment
mechanically. The reviewer's role shifts from *catching*
misses to *interpreting hard cases* — exception rulings, edge
cases the policy did not anticipate, prioritisation of the
remaining gaps.

This chapter walks the OPA/Rego pattern for ML platform
admission gates: what the platform emits, what the policies
check, how the outputs feed back into the governance
dashboard, how the policies are tested, and how they are
versioned. The five exercises for this module culminate in
authoring a policy pack; this chapter is the reference for
the pack.

You leave this chapter able to:

- Design **admission-gate integrations** at the four
  chokepoints — code-commit CI, training-job submission,
  model-registry promotion, and runtime serving.
- Author **Rego policies** that encode individual control
  obligations from the chapter 01–03 matrix.
- Write **policy tests** (positive and negative) that
  survive Rego syntax changes and policy refactors.
- Wire policy decisions into **evidence** — the fact that a
  deployment passed the policy is itself an auditable
  record.
- Recognise the failure modes of policy-as-code
  (overreach, unmaintainable Rego, decisions without
  reasons) and design against them.

---

## Where policy-as-code fits in an ML platform

Four natural chokepoints. Each carries a policy pack scoped
to the decisions it can enforce.

- **CI on the code repo.** Every PR that touches a
  production ML service runs a lint over its
  configuration — model card schema, threat-model
  reference, risk-register reference, eval-plan reference.
  Missing fields, malformed values, or stale references
  fail the PR.
- **Training-job submission.** The training-platform
  scheduler (Argo Workflows, Kubeflow Pipelines, Ray, a
  bespoke controller) checks each submitted training job
  against a policy pack — is the training-plan approved,
  is the DP budget request within the tier map (mod-108
  chapter 01), is the training data lineage verified
  (mod-104), is the training image signed (mod-110).
- **Model-registry promotion.** Promoting a model from
  `staging` to `production` runs the release-gate policy
  pack — model card complete, eval bundle current and
  above thresholds, impact assessment current, risk
  register current, approvals recorded.
- **Runtime serving.** Kubernetes admission (via
  Gatekeeper or Kyverno) blocks serving workloads that
  don't reference a promoted model version, don't have
  the required labels for observability (mod-103), or
  bind to a KMS key they are not authorised for (mod-105).

The four packs share a data model. Each deployment attempt
carries a `context` object — the artefact under review, the
actor, the environment, the reason. Each policy pack
produces a `decision` — allow, deny, or exception-required
— plus a `reasons` array (per-rule outcome, evidence
pointers, remediation hint).

The pattern is CNCF's "policy engine as sidecar to every
control plane". OPA is not the only implementation
(Kyverno, Cerbos, Cedar), but OPA/Rego is the one this
chapter uses because Rego is expressive enough for the
matrix rows and OPA has the widest ecosystem for the
integration points listed above.

---

## The input contract

OPA evaluates a **query** against **data** and **input**.
For ML admission gates, the useful pattern:

- `input` — the deployment attempt. Structured JSON.
- `data.controls` — the control matrix (loaded into OPA
  from `governance/controls/*.json`).
- `data.tier_map` — the DP tier map, deployment-tier
  gating rules (chapter 06), policy exceptions.
- `data.approved_signers` — RACI-driven list of who can
  approve what.

An input schema for a model-registry promotion:

```json
{
  "actor": {
    "id": "alice@example.com",
    "roles": ["ml-engineer", "team:recsys"]
  },
  "action": "model_registry.promote",
  "target": {
    "from_stage": "staging",
    "to_stage": "production",
    "model": "prod-recsys",
    "version": "3.4.2"
  },
  "artefact": {
    "model_card": {
      "path": "models/prod-recsys/3.4.2/card.yaml",
      "intended_use": "session-level session recommender...",
      "out_of_scope_use": "cross-tenant recommendations",
      "regulatory_scope": ["gdpr", "eu_ai_act_limited"],
      "privacy": {
        "guarantee": {
          "epsilon": 3.0,
          "delta": 1e-5,
          "record_definition": "one user's complete session"
        }
      },
      "eval_bundle_ref": "eval/prod-recsys/3.4.2/bundle.json",
      "risk_register_ref": "risk/prod-recsys/register.yaml",
      "impact_assessment_ref": "governance/impact-assessments/prod-recsys.md",
      "impact_assessment_last_reviewed": "2026-08-14"
    },
    "signed_by": ["alice@example.com"],
    "approvals": [
      {"role": "product_owner", "who": "pm@example.com", "when": "2026-09-02"}
    ]
  },
  "environment": {
    "cluster": "prod-eu-1",
    "tenant": "shared",
    "now": "2026-09-04T10:00:00Z"
  }
}
```

Every one of these fields is emitted by the platform, not
typed by the engineer. The model-card path is inferred from
the version tag; the eval bundle reference is inferred from
the eval-runner's output; approvals come from the release-
gate approval system. Engineers cannot lie to policy about
the artefact because the artefact is read from disk.

---

## A minimal policy: model card completeness

The simplest useful policy — every promotion carries a
model card with the required fields present.

```rego
package aicg.controls.model_card_completeness

import rego.v1

# Required fields on the model card. Each entry ties to a
# NIST AI RMF sub-category and (where relevant) an EU AI Act
# article.
required_fields := {
  "intended_use":                   {"nist": "MP-1.1", "eu_ai_act": [11]},
  "out_of_scope_use":               {"nist": "MP-1.1"},
  "regulatory_scope":               {"nist": "GV-1.1"},
  "risk_register_ref":              {"nist": "MP-5.1", "eu_ai_act": [9]},
  "eval_bundle_ref":                {"nist": "MS-2.7", "eu_ai_act": [15]},
  "impact_assessment_ref":          {"nist": "MP-3.1", "eu_ai_act": [27]},
  "impact_assessment_last_reviewed":{"nist": "MP-3.1", "eu_ai_act": [27]},
}

# Which promotion actions we gate.
gated_actions := {"model_registry.promote"}

# The gate applies only when the target stage is production.
applies if {
  input.action in gated_actions
  input.target.to_stage == "production"
}

# One violation per missing field.
violations contains v if {
  applies
  some field, meta in required_fields
  not has_value(input.artefact.model_card, field)
  v := {
    "rule": "model_card_field_missing",
    "field": field,
    "nist": meta.nist,
    "eu_ai_act": object.get(meta, "eu_ai_act", []),
    "remediation": sprintf(
      "Populate `%v` on the model card before promoting to production.", [field]),
  }
}

# Additional violation — impact assessment must be < 12 months old.
violations contains v if {
  applies
  reviewed := input.artefact.model_card.impact_assessment_last_reviewed
  reviewed
  age_days := time.now_ns() / 1e9 / 86400 -
              time.parse_rfc3339_ns(reviewed) / 1e9 / 86400
  age_days > 365
  v := {
    "rule": "impact_assessment_stale",
    "field": "impact_assessment_last_reviewed",
    "nist": "MP-3.1",
    "eu_ai_act": [27],
    "age_days": age_days,
    "remediation": "Refresh impact assessment; re-run FRIA review; update the last_reviewed date.",
  }
}

# Decision — allow only if there are no violations.
default allow := false
allow if {
  applies
  count(violations) == 0
}

allow if {
  not applies   # policy does not gate this action; abstain
}

has_value(obj, k) if {
  v := obj[k]
  v != null
  v != ""
  not empty_array(v)
}

empty_array(v) if {
  is_array(v)
  count(v) == 0
}
```

Test cases for this policy:

```rego
package aicg.controls.model_card_completeness_test

import rego.v1
import data.aicg.controls.model_card_completeness

test_allow_when_all_fields_present if {
  model_card_completeness.allow with input as {
    "action": "model_registry.promote",
    "target": {"to_stage": "production"},
    "artefact": {"model_card": {
      "intended_use": "x",
      "out_of_scope_use": "y",
      "regulatory_scope": ["gdpr"],
      "risk_register_ref": "r.yaml",
      "eval_bundle_ref": "e.json",
      "impact_assessment_ref": "ia.md",
      "impact_assessment_last_reviewed": "2026-08-14",
    }},
  }
}

test_deny_when_intended_use_missing if {
  not model_card_completeness.allow with input as {
    "action": "model_registry.promote",
    "target": {"to_stage": "production"},
    "artefact": {"model_card": {
      "out_of_scope_use": "y",
      "regulatory_scope": ["gdpr"],
      "risk_register_ref": "r.yaml",
      "eval_bundle_ref": "e.json",
      "impact_assessment_ref": "ia.md",
      "impact_assessment_last_reviewed": "2026-08-14",
    }},
  }
  violations := model_card_completeness.violations with input as {
    "action": "model_registry.promote",
    "target": {"to_stage": "production"},
    "artefact": {"model_card": {
      "out_of_scope_use": "y",
      "regulatory_scope": ["gdpr"],
      "risk_register_ref": "r.yaml",
      "eval_bundle_ref": "e.json",
      "impact_assessment_ref": "ia.md",
      "impact_assessment_last_reviewed": "2026-08-14",
    }},
  }
  some v in violations
  v.rule == "model_card_field_missing"
  v.field == "intended_use"
}

test_abstain_for_staging_promotion if {
  model_card_completeness.allow with input as {
    "action": "model_registry.promote",
    "target": {"to_stage": "staging"},
    "artefact": {},
  }
}
```

The tests run in CI on every change to the policy pack:

```bash
opa test -v policies/ tests/
```

Rule: **no policy ships without positive and negative tests
for every branch**. Untested Rego is a liability.

---

## A tier-map policy: DP budget within the sanctioned band

Chapter 08's DP tier map (mod-108 chapter 01) constrains the
`(ε, δ)` a training job can target based on the data class.
Encoding it as policy:

```rego
package aicg.controls.dp_budget_tier

import rego.v1

# Loaded from data.tier_map.
# tier_map.bands[<data_class>] = {epsilon_max, delta_max, requires_approval_from}

gated_actions := {"training_job.submit"}

applies if input.action in gated_actions

# Look up the tier band for the job's declared data class.
band := data.tier_map.bands[input.artefact.data_class]

violations contains v if {
  applies
  input.artefact.privacy_target.epsilon > band.epsilon_max
  v := {
    "rule": "dp_epsilon_exceeds_tier_max",
    "requested_epsilon": input.artefact.privacy_target.epsilon,
    "band_max": band.epsilon_max,
    "band": input.artefact.data_class,
    "nist": "GV-1.2",
    "eu_ai_act": [10],
    "remediation": sprintf(
      "Requested ε=%v exceeds sanctioned band %v (max %v). Either tighten ε, re-classify the data with justification, or request an executive exception documented per policy exception process.",
      [input.artefact.privacy_target.epsilon,
       input.artefact.data_class,
       band.epsilon_max]),
  }
}

violations contains v if {
  applies
  input.artefact.privacy_target.delta > band.delta_max
  v := {
    "rule": "dp_delta_exceeds_tier_max",
    ...
  }
}

# Exception path — an executive can approve out-of-tier, but
# the approval must be recorded, unexpired, and from an
# approved signer.
allow if {
  applies
  count(violations) == 0
}

allow if {
  applies
  some ex in input.artefact.exceptions
  ex.type == "dp_budget_out_of_tier"
  ex.signer in data.approved_signers.dp_exception
  time.parse_rfc3339_ns(ex.expires_at) > time.now_ns()
  ex.matches.data_class == input.artefact.data_class
}
```

Two properties this policy demonstrates:

- **Exceptions are first-class**, not backdoors. The
  exception has a shape (signer, expiry, scope). It is
  audit-visible. The pattern generalises to every "the
  policy says no but we need to ship" situation.
- **Data (tier map) is loaded**, not hard-coded. The tier
  map is a governance artefact edited via a separate review
  workflow; the policy only knows how to consume it. When
  the policy team and the tier-map team are different
  people, decoupling matters.

---

## Composing a policy pack

Individual policies are noise unless they compose into a
release-gate decision that answers a single question:
**should this deployment proceed?** The pattern:

```rego
package aicg.gates.model_promotion

import rego.v1

# Sub-policies that contribute to this gate.
import data.aicg.controls.model_card_completeness
import data.aicg.controls.eval_bundle_current
import data.aicg.controls.risk_register_signed_off
import data.aicg.controls.approvals_present
import data.aicg.controls.dp_budget_tier
import data.aicg.controls.attestation_of_supply_chain

all_violations contains v if {
  some v in model_card_completeness.violations
}
all_violations contains v if {
  some v in eval_bundle_current.violations
}
all_violations contains v if {
  some v in risk_register_signed_off.violations
}
all_violations contains v if {
  some v in approvals_present.violations
}
all_violations contains v if {
  some v in dp_budget_tier.violations
}
all_violations contains v if {
  some v in attestation_of_supply_chain.violations
}

default decision := {"allow": false, "reasons": []}

decision := {
  "allow": count(all_violations) == 0,
  "reasons": all_violations,
  "policy_version": data.pack_meta.version,
  "evaluated_at_ns": time.now_ns(),
}
```

The consumer of the gate receives a decision like:

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
  "policy_version": "2026.09.04",
  "evaluated_at_ns": 1757152800000000000
}
```

Two properties that matter:

- **The decision is a document, not a bit.** `allow=false`
  without `reasons` is useless. Every violation carries a
  rule ID (so the runbook can be looked up), a control
  cross-reference (so the reviewer can trace to the
  matrix), and a **remediation hint** (so the engineer
  knows what to do). The remediation is the difference
  between a helpful gate and a hated gate.
- **The evaluated decision is retained.** The platform
  writes the decision to append-only storage alongside the
  deployment attempt. Both allows and denies. The audit
  question "prove your gate ran for release X" is answered
  by producing the retained decision, keyed by the release
  ID.

---

## Wiring into a control plane

The four wiring patterns:

### 1. CI check (GitHub Actions / equivalent)

```yaml
# .github/workflows/policy-lint.yml
name: policy-lint
on: [pull_request]

jobs:
  conftest:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - name: Install Conftest
        run: |
          curl -sSfL https://github.com/open-policy-agent/conftest/releases/download/v0.62.0/conftest_0.62.0_Linux_x86_64.tar.gz | tar xz
          sudo mv conftest /usr/local/bin/
      - name: Assemble deployment inputs
        run: |
          scripts/assemble-inputs.py --pr-only > /tmp/inputs.json
      - name: Evaluate policy
        run: |
          conftest test /tmp/inputs.json \
            --policy policies/ \
            --data governance/ \
            --namespace aicg.gates.model_promotion \
            --output json > /tmp/decision.json
      - name: Publish decision as PR comment
        uses: marocchino/sticky-pull-request-comment@v2
        with:
          path: /tmp/decision.json
```

The `assemble-inputs.py` script (org-local) walks the PR
diff and produces the JSON deployment attempt from the
files being changed. `conftest` invokes OPA under the hood.

### 2. Training-job submission (Argo Workflows / Kubeflow)

An admission webhook on the training-job CRD calls into an
OPA sidecar with the job spec. Denied jobs are rejected at
API-server time with the reasons attached to the response.

### 3. Model-registry promotion (MLflow / bespoke)

A pre-promotion hook in the registry POSTs the deployment-
attempt JSON to OPA's HTTP API and blocks promotion on
`allow=false`.

### 4. Runtime admission (Kubernetes)

For serving workloads, use OPA Gatekeeper (or Kyverno with
Rego support via CEL bridge). A `ConstraintTemplate` per
policy; a `Constraint` binds the template to the target
resources. Denied deployments fail `kubectl apply` with the
reasons.

Two operational rules across all four wirings:

- **Dry-run first.** Every new policy ships in `warn` mode
  for a burn-in period; the platform logs would-be
  violations but does not block. Once the false-positive
  rate is understood, flip to `enforce`. Skipping the burn-
  in is how "we shipped the policy and broke every team".
- **Bypass path is explicit.** For platform outages that
  wedge the policy engine, a break-glass — signed by two
  senior engineers, logged verbosely, alerts fired — allows
  a deployment to proceed. `oc policy exception dry-run
  --break-glass` and equivalents. Break-glass usage is
  itself an audit-visible event.

---

## Turning policy decisions into evidence

The decisions the gate emits are audit evidence. To be
useful, they need to:

- **Be retained** with the deployment they gated. Append-
  only object store; content-addressed. Retention aligns
  with the longest of the applicable regime clocks
  (Article 12: ≥ 6 months for high-risk systems; sector
  regs may be longer).
- **Be queryable by control ID.** "Show me every deployment
  where the eval_bundle_stale rule fired in the last
  quarter" is a chapter-01-MEASURE-2.7 audit answer. A
  simple approach: index the decisions in the same
  observability store as other admission events; a Grafana
  panel per rule.
- **Feed the governance dashboard.** Chapter 01's matrix
  has an `evidence.verification` per row. When the
  verification method is "policy X gates action Y",
  dashboard tiles show pass-rate and rule-hit-rate per
  policy. Auditor asks "show me evidence GV-1.1 is
  operating"; the tile is the answer.

---

## Policy structure and hygiene

### File layout

```
policies/
├── aicg/
│   ├── controls/
│   │   ├── model_card_completeness.rego
│   │   ├── model_card_completeness_test.rego
│   │   ├── eval_bundle_current.rego
│   │   ├── eval_bundle_current_test.rego
│   │   ├── dp_budget_tier.rego
│   │   ├── dp_budget_tier_test.rego
│   │   ├── attestation_of_supply_chain.rego
│   │   ├── risk_register_signed_off.rego
│   │   └── approvals_present.rego
│   └── gates/
│       ├── model_promotion.rego
│       ├── training_job_submission.rego
│       └── runtime_admission.rego
governance/
├── controls/           # matrix data
├── tier_map.json
├── approved_signers.json
└── pack_meta.json      # version, changelog
```

### Rules

- **One control per file.** Complex controls (multiple
  fields, multiple thresholds) get sub-rules, still in one
  file.
- **Every control file has a matching `_test.rego`.**
- **Policy pack is versioned.** `pack_meta.json` carries the
  version; every emitted decision embeds it. A policy that
  changed the definition of "high-risk" between v1.2 and
  v1.3 is a different policy — the pack version records
  which one was in force.
- **Rules explain themselves.** Every violation carries
  `rule`, control cross-refs, and a `remediation` string.
  A helpful gate is one you can act on without asking
  someone.
- **No `deny := true` walls without reasons.** Never emit a
  decision the caller can't unpack.
- **Data is data, not code.** Tier maps, signer lists, and
  regulatory-scope registers are JSON/YAML files loaded via
  `data.*`. Never hard-code them in Rego.
- **Prefer positive rules.** `allow if all_conditions_met`
  is easier to read than `deny if any_condition_missing`.
  Rego composes both, but a hybrid style produces
  surprising abstain semantics.

### Refactoring

Policies get old. Refactors need:

- A **behavioural test snapshot** — before refactor, record
  the decision for a corpus of representative inputs; after
  refactor, confirm decisions match. If they don't, the
  refactor changed behaviour and needs explicit review.
- A **deprecation path** — when a control is retired,
  mark it `deprecated: true` in `pack_meta.json` and remove
  from the gate composition; keep the file for two
  versions before deleting so old decisions can still be
  traced to their rule.

---

## Standard failure modes

- **Gate that doesn't block.** Policy ships in `warn` mode
  and stays there because the team can't handle the
  volume. Fix: quantify the false-positive rate; if the
  rate is legitimately high, the policy is too strict —
  loosen it; if the rate is low, flip to enforce with
  break-glass available.
- **Violation without remediation.** The engineer sees
  `allow=false, reason=eval_bundle_stale` and has no idea
  what to do. Fix: every rule carries a `remediation`
  string; PR-comment format includes it prominently.
- **Policy that requires context the engineer can't
  produce.** The gate demands `impact_assessment_ref` but
  the platform can't find it because it lives in a wiki.
  Fix: the input contract only asks for fields the
  platform actually produces; move the artefact under
  version control or write a fetcher.
- **Untested policy.** Rego typo goes to production; every
  deployment is silently allowed. Fix: `opa test` in CI on
  every change; policy pack version tracks test-pass status.
- **Data drift.** Tier map changed but nobody updated the
  test fixtures; policy references undefined bands. Fix:
  test fixtures are generated from the data at test time;
  changes to data trigger the test suite.
- **Exception used as bypass.** Executives sign exceptions
  routinely, defeating the policy. Fix: exception rate is
  a metric on the governance dashboard; > N exceptions per
  quarter triggers policy review — the tier is wrong or
  the policy is wrong.
- **Break-glass overused.** Same pattern; two senior
  signatures become a rubber stamp. Fix: break-glass alerts
  fire to a channel everyone reads; usage is retro-
  reviewed monthly.
- **Policy pack drift across environments.** Prod and
  staging run different pack versions. Fix: pack version
  is a required field on the platform's system inventory;
  drift alerts fire.
- **Rego overreach.** A policy that reads the model weights
  and computes fairness metrics is not a policy — it is an
  application. Fix: policy makes decisions on evidence
  *already emitted*; the eval-runner computes fairness,
  the policy checks the number is below threshold.
- **One gigantic policy file.** Refactoring is impossible;
  the changelog is unreadable. Fix: one control per file;
  gate files compose imports.
- **Missing "we abstain" semantic.** Rules that don't apply
  to the action still contribute an implicit `deny`, so
  the gate returns `allow=false` for out-of-scope calls.
  Fix: gates have an explicit `applies` predicate; when
  none apply, `default allow := true` at the gate level
  (the platform decides which gate to invoke for which
  action; policy shouldn't second-guess).

---

## Summary

- Policy-as-code turns the chapter 01–03 control matrix into
  **executable admission gates**. The reviewer's job shifts
  from catching misses to interpreting hard cases.
- Four natural chokepoints: **CI**, **training-job
  submission**, **model-registry promotion**, and
  **runtime serving**. Each carries a scoped policy pack.
- Every deployment attempt is a **structured input**; every
  decision is a **document** with rule IDs, control cross-
  references, and remediation hints.
- **Data is data.** Tier maps, signer lists, and regulatory
  scope live outside the Rego and are loaded via `data.*`
  so the policy team and the governance team can evolve
  independently.
- **Every policy has tests.** Positive and negative branches;
  `opa test` in CI; snapshot tests for refactors.
- **Decisions are retained** and become auditor evidence.
  Chapter 01's `evidence.verification` field points at the
  policy that gated the action; the decision store answers
  the audit question.
- Failure modes to design against: warn-mode-forever;
  violation-without-remediation; exceptions-as-bypass;
  policy pack drift; Rego overreach. Every one of them is a
  process failure, not a Rego failure — the language is
  fine; the discipline is what carries the gate.
