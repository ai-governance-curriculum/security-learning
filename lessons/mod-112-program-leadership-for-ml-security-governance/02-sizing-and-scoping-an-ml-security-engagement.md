# Chapter 02 — Sizing and Scoping a New ML-Security Engagement

> **Note on AI-assisted content.** The sizing shapes,
> cost-estimation examples, and release-gate control
> patterns in this chapter are structural; verify
> framework identifiers (NIST AI RMF sub-category IDs,
> ISO/IEC 42001 Annex A clauses, ATLAS technique IDs,
> SLSA levels) against the primary sources cited in
> [`resources.md`](./resources.md). The sizing numbers
> are illustrative, not benchmarks.

---

## Why this chapter exists

A new ML-security engagement arrives in one of four
shapes:

- **A new system.** A product team is standing up a new
  LLM-backed feature, a new classifier, or a new agent;
  security needs to be scoped before launch.
- **An acquired system.** The business just acquired a
  company whose AI stack now has to be onboarded.
- **A re-platform.** An existing system is being lifted
  onto the new ML platform (mod-103) and the security
  posture has to be re-established.
- **A regulatory trigger.** A new regulation applies to
  an existing system (EU AI Act high-risk designation,
  state law, sector regulation) and security scope has
  to be rebuilt against the new requirements.

In every case the programme-lead's job is the same:
turn the request into a bounded, evidenced engagement
with a cost estimate, a coverage statement, and a
release-gate hand-off. The failure mode is unbounded
engagement: the team spends weeks "doing security",
produces a long memo, nothing binds to the release
process, and the gate ships based on a stakeholder's
confidence that "we looked at it".

The failure mode this chapter is written against:

> A product team asks for a security review of a new
> customer-facing LLM assistant. The programme-lead
> books a kickoff, orders threat-modelling against
> ATLAS, commissions adversarial testing, and the
> engagement runs for 11 weeks. The deliverables are a
> threat model and a slide deck. The release ships
> four weeks later; the gate's "security approved"
> checkbox was ticked by someone who read the slide
> deck. Three months post-launch, an incident reveals
> a tool-call tiering gap that was in the threat model
> but never bound to a release-gate control. The
> coverage was *produced*; it was not *installed*.

A sized engagement is one whose shape, cost, and
coverage are known up front, whose output is a set of
installed controls rather than a memo, and whose exit
is auditable.

You leave this chapter able to:

- Build the asset inventory for an ML system in a shape
  that drives the rest of the engagement.
- Name the top-N threats against the system in a form
  that maps to the control library (chapter 01) and
  the mod-102 threat-model artefact.
- Produce the cost-and-coverage matrix that lets a
  sponsor pick a scope at a given spend level.
- Publish the release-gate requirements the engagement
  installs as its exit — the artefacts, the signatures,
  the policy-as-code binding.
- Avoid the common failure modes: unbounded scope,
  threat-model-as-deliverable, review-without-binding.

---

## Step 1 — Inventory the assets

The asset inventory is the engagement's spine. Every
later deliverable is a function of what is on the
inventory. The inventory has five classes of asset for
an ML system:

### Data assets

- **Training data.** Datasets used to build or
  fine-tune the models in scope. Each entry: dataset
  name, store (bucket URL), version, sensitivity
  classification (public, internal, confidential,
  restricted/PHI/PII), owner, licence terms, source
  of consent / lawful basis, record of lineage (mod-
  104). Datasets without a classified lineage record
  are a finding on their own.
- **Evaluation data.** Held-out eval sets, red-team
  payload sets, adversarial sample banks.
- **Runtime input/output data.** Inference requests,
  model outputs, trajectory logs, retrieval content
  passing through RAG. These are often where the
  sensitivity question is sharpest — "the training
  data is public but the production prompt stream is
  PHI".
- **Reference / retrieval corpora.** The content a RAG
  system retrieves from; often broader in sensitivity
  than the training set.

### Model assets

- **Base models.** Foundation models the system builds
  on: provider, version (digest if possible), hosting
  (self-hosted, managed, API-only), licence terms,
  known capability tier (chapter 06 mod-109).
- **Fine-tunes / adapters.** LoRA weights, full fine-
  tunes, prompt-tuning artefacts. Each with a lineage
  pointer to the base and to the training set.
- **Classical ML components.** Classifiers, retrieval
  rerankers, embedding models, guardrail models.
  Each is in scope and needs the same metadata.

### Interface assets

- **Inference endpoints.** Public API, internal API,
  partner-facing API, batch job. Each with its
  identity model, auth, rate-limiting, and gateway.
- **Tool integrations.** For agent systems (mod-107),
  the tool registry: tier, destination, side-effect
  profile.
- **Retrieval sources.** Internal document stores,
  external search providers, user-provided URLs,
  external APIs.
- **Admin interfaces.** Model registry, training-
  pipeline control plane, evaluation harness,
  deployment dashboard.

### Infrastructure assets

- **Compute.** Training clusters, serving clusters,
  node pools, GPUs, inference accelerators (mod-103).
- **Secrets / keys.** Signing keys, model-encryption
  keys, API keys to external providers (mod-105).
- **Pipelines.** Training pipeline, eval pipeline,
  deployment pipeline, data-ingest pipeline.
- **Platform services.** Model registry, feature
  store, vector store, experiment tracker.

### Identity assets

- **Human identities** that touch the system — ML
  researchers, platform engineers, approvers, legal
  reviewers, oncall.
- **Workload identities** — service accounts, OIDC
  subjects, workload-identity federations.
- **External identities** — vendor accounts, customer
  tenants, partners.

### Shape of the inventory

The inventory is a machine-readable artefact. One
shape:

```yaml
engagement_id: ENG-2025-034
system: internal-ops-assistant
owner_team: ops-platform
asset_inventory:
  data:
    - id: DATA-01
      name: ops-ticket-corpus
      store: s3://internal-ops/tickets/
      version: ds-v4.1.0
      sensitivity: restricted  # tickets contain customer PII
      lineage: lineage://datasets/ops-ticket-corpus/ds-v4.1.0
      owner_role: ops-data-lead
    - id: DATA-02
      name: public-faq
      store: gs://public-faqs/
      sensitivity: public
      lineage: lineage://datasets/public-faq/v2.0
  models:
    - id: MODEL-01
      base: vendor-llm/foundation-v3@sha256:abc...
      finetune: internal/ops-assistant-ft:v1.2
      sensitivity: inherits from DATA-01
      lineage: lineage://models/ops-assistant/v1.2
  interfaces:
    - id: IFACE-01
      type: inference_endpoint
      auth: oidc_internal
      tools:
        - id: TOOL-01
          name: zendesk.get_ticket
          tier: 1
          destination_class: internal_api
        - id: TOOL-02
          name: email.send
          tier: 3
          destination_class: external_email
  infrastructure:
    - id: INFRA-01
      type: serving_cluster
      cluster: ml-serving-prod-eu-west-1
      namespace: ops-assistant
  identities:
    - id: ID-01
      role: ops-platform-eng
      type: human
      scope: deploy_ops_assistant
    - id: ID-02
      role: ops-assistant-serving-sa
      type: workload
      scope: inference_runtime
```

The inventory is signed by the system owner and
re-signed on each engagement update. An inventory that
is "mostly right" is unusable; a signed, dated,
versioned inventory is the engagement's foundation.

---

## Step 2 — Name the top-N threats

The threat model lives in mod-102. The programme-
lead's job here is to *scope* the model to the system
by naming the top-N threats the engagement will size
against. "Top-N" is a bounded number — 10, 15, 20 —
chosen so the engagement has a tractable surface and
the deliverables are enumerable.

Threats are drawn from several sources and merged:

- **MITRE ATLAS matrix.** For each tactic, the
  techniques that apply given the asset inventory. A
  system with no self-hosted model does not need
  `AML.T0044` (Full ML Model Access) against it; a
  system with public inference does.
- **OWASP LLM Top 10 and OWASP ML Top 10.** Common
  LLM / ML risks that often appear in auditor
  checklists; using these in the enumeration keeps
  the output translatable.
- **Sector-specific threat sources.** FS-ISAC AI
  threat reporting for financial-services, H-ISAC for
  healthcare, authority bulletins (NCSC, CISA, ENISA)
  for critical infrastructure.
- **Internal threat intelligence.** The organisation's
  own incidents (mod-111) and near-misses.
- **Red-team findings** from mod-107 chapter 04 and
  mod-106.

Each threat is written as a one-line statement with
an identifier, an ATLAS / OWASP mapping, affected
assets, and a current-posture rating:

```yaml
threats:
  - id: THR-01
    statement: >
      Indirect prompt injection via retrieved ticket content
      causes the agent to call email.send with attacker-
      controlled destination.
    atlas: [AML.T0053, AML.T0049]
    owasp_llm: LLM01
    affected_assets: [IFACE-01, TOOL-02]
    current_posture: partial  # retrieval-provenance labelling in place,
                              # HITL for TOOL-02 not yet enforced
  - id: THR-02
    statement: >
      PII in training ticket corpus (DATA-01) recoverable
      from model via membership inference.
    atlas: [AML.T0024.001]
    owasp_ml: ML05
    affected_assets: [MODEL-01, DATA-01]
    current_posture: uncovered
  - id: THR-03
    statement: >
      Supply-chain compromise of vendor-llm/foundation-v3
      undetected because the model is pulled on each pod
      start without signature verification.
    atlas: [AML.T0010]
    affected_assets: [MODEL-01]
    current_posture: uncovered
  # ... up to top-N
```

**Posture ratings.** Three states keep the matrix
honest:

- **Covered** — a control in the library applies and
  evidence demonstrates it is operating.
- **Partial** — a control exists but is incomplete
  (e.g. detection in log-only mode, policy drafted
  but not enforced).
- **Uncovered** — no control, or control exists but
  does not apply to this system.

A threat without a posture rating is a threat the
engagement has not actually looked at.

**Prioritisation.** The top-N is not the N highest-
scoring threats; it is the N threats where the
engagement's cost is justified. A top-N that includes
only exotic model-theft threats and misses the two
mundane retrieval-provenance gaps is miscalibrated.
Pair likelihood and impact against *the cost to close*;
closing a mundane gap often has the best coverage
return per hour.

---

## Step 3 — Produce the cost-and-coverage matrix

The sponsor's job is to pick a scope at a cost. The
programme-lead's job is to let them pick on evidence
rather than guesswork. The cost-and-coverage matrix is
the artefact that makes the choice legible.

A matrix row per threat, columns for the cost of each
level of coverage:

| Threat   | Current  | Minimum control (cost) | Full control (cost) | Beyond full (cost) |
|----------|----------|------------------------|---------------------|--------------------|
| THR-01   | Partial  | HITL for TOOL-02 destinations outside known-list; 2 eng-weeks | Retrieval-provenance + tool-tier + HITL + detection rule in paging mode (mod-111 ch 01); 4 eng-weeks | Dynamic ACL per retrieval source + replay fuzz suite in CI (mod-107 ch 04); 10 eng-weeks |
| THR-02   | Uncovered | Document DP posture; disable confidence-score endpoint; 1 eng-week | DP-SGD training re-run with budget ε≤8 and signed budget record (mod-108 ch 01); 6 eng-weeks + compute | Full DP + membership-inference eval + detection rule for probe pattern; 10 eng-weeks |
| THR-03   | Uncovered | Attach cosign verification to pod start (mod-110 ch 02); 1 eng-week | Verification + ML-BOM + SLSA Level 2 for the model-build pipeline (mod-110 ch 01); 4 eng-weeks | SLSA Level 3 + Rekor-logged attestations + verification gate in release-gate; 8 eng-weeks |
| ...      | ...      | ...                    | ...                 | ...                |

**Three levels, not seven.** The matrix is a decision
tool. Minimum / Full / Beyond-Full keeps the choice
tractable. More levels mean the sponsor cannot see the
trade-off; fewer mean the choice is "yes or no".

**Costs are honest.** An engineer-week is an engineer-
week; a compute cost is a compute cost. If a control
needs 20 TB of GPU-hours for an eval, say so. If a
control needs 10 % of a legal reviewer's quarter, say
so. The matrix fails if it hides the real cost in
"we'll figure it out".

**Coverage is cumulative.** Full coverage includes
minimum; Beyond-Full includes Full. The sponsor is
picking a level, not a basket.

**Dependencies.** Some threats share controls (THR-01
and THR-02 both need the detection pack; the pack is
costed once). Call this out so the sponsor is not
double-charged.

**Default recommendation.** The programme-lead
recommends a level per threat, with a rationale.
Sponsors frequently defer to the recommendation; the
rationale is what makes the deferral informed.

---

## Step 4 — Publish the release-gate requirements

The engagement's exit is not a slide deck. It is a set
of release-gate requirements installed in the enterprise
release-gate pipeline, backed by controls in the
library (chapter 01) and policy-as-code (mod-109
chapter 04).

A release-gate requirement has:

- **The control-library ID** it enforces.
- **The policy-as-code rule** that evaluates it on each
  release.
- **The evidence artefact** that must be attached to
  pass.
- **The failure mode** — hard block, soft warning,
  advisory, each with a documented approver for
  override.
- **The owner** who maintains the rule when it drifts.

A worked example for THR-01 at Full coverage:

```yaml
release_gate_requirements:
  - id: RGR-ENG-2025-034-01
    system: internal-ops-assistant
    control: AISEC-LLM-004  # tool-tier + HITL enforcement
    policy_rule:
      path: policy/aisec-llm-004.rego
      package: aisec.llm.hitl
    required_evidence:
      - model_card.yaml with tool-tier declarations
      - hitl_config.yaml bound to the deployment manifest
      - detection_rule_coverage: AML.T0049, AML.T0053
    failure_mode: hard_block
    override_role: ml-security-programme-lead
    override_requires:
      - documented reason
      - time-bounded (max 14 days)
      - review-board awareness (chapter 03)
    owner_role: ml-security-programme-lead
```

The release-gate requirement is the artefact that
makes the engagement real. A threat model that does
not install a release-gate requirement is a document;
a release-gate requirement that does not bind to a
control-library control is a wart; a control-library
control without a release-gate requirement is
unenforced policy.

### The engagement exit checklist

The engagement exits when every item on the following
list is signed:

- [ ] Asset inventory signed by system owner, versioned.
- [ ] Threat enumeration signed by programme-lead,
      covering top-N with current-posture ratings.
- [ ] Cost-and-coverage matrix signed by sponsor at a
      chosen level per threat.
- [ ] Release-gate requirements installed in policy-as-
      code, binding to control-library controls.
- [ ] Evidence pipeline for each requirement is live
      (not planned).
- [ ] Owning on-call rotation named for every detection
      rule installed.
- [ ] Mod-104 lineage records bound for every in-scope
      model.
- [ ] Mod-110 attestations bound for every in-scope
      model where applicable.
- [ ] Follow-up schedule published for anything deferred
      (deferred items are tracked, not forgotten).

---

## Standard failure modes

- **Unbounded scope.** "We will secure the AI assistant"
  is not a scope. The asset inventory is the scope.
- **Top-N without a prioritisation argument.** A top-N
  that is five famous attacks and no mundane control
  gaps is wrong-shaped. Prioritise by cost-to-close
  against risk, not by novelty.
- **Threat-model-as-deliverable.** The threat model is
  an input to the engagement, not the output. The
  output is a set of installed release-gate
  requirements.
- **Costs without compute lines.** An engagement that
  silently assumes "the ML platform team has spare GPU
  budget" will be rejected at execution time. Include
  all honest costs.
- **One level per threat.** Showing a sponsor "this is
  what you need to do" without showing the minimum and
  the beyond-full options denies them the choice their
  budget may require.
- **Review without binding.** Reviews that do not install
  controls do not count. Every finding is either a
  release-gate requirement or an explicit "accepted
  risk" with a named approver.
- **Signatures on PDFs instead of signed artefacts.**
  The inventory, threat enumeration, matrix, and
  requirements all live as versioned artefacts in the
  evidence store (chapter 01), not as PDF attachments
  in a shared drive.
- **Engagement duration drift.** A one-week engagement
  that becomes a twelve-week engagement without a
  re-scope conversation is a budget surprise waiting
  for the next steering review.

---

## Summary

- Every ML-security engagement starts with a signed,
  versioned **asset inventory** across data, models,
  interfaces, infrastructure, and identities.
- A bounded **top-N threat enumeration** is drawn from
  ATLAS, OWASP LLM / ML, sector intel, and internal
  incidents, with a current-posture rating per threat.
- The **cost-and-coverage matrix** gives the sponsor
  three-level choices (minimum / full / beyond-full)
  per threat with honest costs and a programme-lead
  recommendation.
- The engagement's **exit is installed release-gate
  requirements**, each binding to a control-library
  control and a policy-as-code rule, with evidence
  pipelines live and owners named.
- The failure modes are unbounded scope, threat-model-
  as-deliverable, cost estimates that hide the compute
  bill, and reviews that do not bind controls to the
  release-gate.
