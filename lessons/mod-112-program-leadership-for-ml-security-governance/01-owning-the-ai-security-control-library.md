# Chapter 01 — Owning the AI-Security Section of the Control Library

> **Note on AI-assisted content.** Control-library tooling
> (GRC platforms, control-catalogue versioning systems),
> standard identifiers (NIST SP 800-53 control IDs, ISO/IEC
> 27001 Annex A clauses, ISO/IEC 42001 Annex A, SOC 2 TSC
> point-of-focus numbers), and framework crosswalks all
> evolve. The structural examples in this chapter are shaped
> against the versions cited in [`resources.md`](./resources.md);
> verify every control ID and every clause against the
> primary source before publishing.

---

## Why this chapter exists

Every enterprise security programme reaches a point where
its controls are no longer a list in a wiki but a *library* —
a catalogued, versioned, referenceable corpus that drives
audit scoping, policy-as-code (mod-109 chapter 04), the
release-gate (chapter 02 of this module), and the metrics
package (chapter 04). For classical infrastructure the
library has been accreted over decades: SOC 2 TSC, ISO/IEC
27001 Annex A, NIST SP 800-53, CIS controls, PCI DSS,
sector regulation. For AI/ML there is no equivalent legacy;
the role of the ML-security programme-lead is to carve out
the AI-security *section* of the enterprise library and
own it with the same discipline the rest of the catalogue
is owned with.

The failure mode this chapter is written against:

> The AI governance programme publishes a glossy policy
> document with twenty "AI security controls" written in
> prose. The GRC team cannot cross-reference the controls
> against SOC 2, nothing in the policy-as-code pipeline
> binds to them, auditors ask for evidence against *their*
> framework and the answer is "we have a policy", and the
> next release ships because no release-gate control was
> actually wired up. Six months later the ML-security
> programme-lead cannot answer "what controls did we have
> on the model that failed?" because there is no versioned
> record of what was in force on that date.

A control library solves this by making the controls
*first-class artefacts*: each has an identifier, a scope,
an owner, a version history, evidence requirements, a
mapping to upstream frameworks, and a lifecycle (draft,
in force, deprecated). The AI-security section is a
subset of the library that cross-references the model
portfolio, the ML platform, and the ATLAS matrix.

You leave this chapter able to:

- Explain the role of the control library in a mature
  security programme and where the AI-security section
  sits inside it.
- Define a control at the right altitude — specific
  enough to audit, general enough not to break on every
  code change.
- Attach evidence to a control: what evidence is, where
  it lives, how it is signed, and how it is versioned.
- Operate the version-history discipline — point-in-time
  queries, deprecation, superseded relationships.
- Understand the handoff to the senior AI governance
  architect (level 50): where ownership of this chapter
  stops and where architectural authoring begins.

---

## What a control library actually is

A control library is a persistent, versioned record of
the controls the organisation claims to have in force,
with enough structure to answer three questions on any
given date:

1. **What controls were in force on date X?**
2. **What evidence demonstrates control C was operating
   on date X?**
3. **Which upstream framework requirements does control
   C satisfy?**

The library has a schema. In most mature programmes it
lives in a GRC platform (ServiceNow IRM, Hyperproof,
Drata, Vanta, OneTrust, Archer, or an in-house system).
The platform choice is secondary; what matters is that
the library expresses:

- **Identifier.** A stable ID (e.g. `AISEC-TM-001`) that
  does not change when the control's text is revised.
- **Title and description.** Human-readable, scanned by
  an auditor in a review.
- **Scope.** The population of systems the control
  applies to — "all models serving external customers",
  "models processing PHI", "fine-tuned LLMs in the
  managed-serving tenant". The scope is not "all AI";
  that is useless at audit.
- **Owner.** A named role, not a person. (People move;
  roles persist.)
- **Framework mapping.** The upstream requirements this
  control satisfies: NIST AI RMF sub-category, ISO/IEC
  42001 Annex A clause, SOC 2 TSC point-of-focus, SR
  11-7 element, EU AI Act article/annex, HIPAA § if
  applicable, sector regulation.
- **Evidence requirements.** What demonstrates the
  control is operating — a signed attestation, a policy-
  as-code decision log, an eval report, a Falco rule
  config.
- **Lifecycle state.** Draft, in-force, deprecated,
  superseded.
- **Version history.** Every change to any of the above
  with a date, an author, and an approving role.
- **Related controls.** Dependencies and supersessions.

A control that lacks any of these fields is not a
control; it is a wish.

---

## The AI-security section of the library

The AI-security section is the subset of the library
whose controls bind to AI-system assets. In practice
it clusters around the mod-102 through mod-111 topics:

- **AISEC-TM** (Threat modelling, mod-102). Controls that
  require a threat model exists, is reviewed, and binds
  to the deployed system version.
- **AISEC-PLAT** (Platform, mod-103). Controls on tenancy,
  workload identity, admission, and isolation of ML
  workloads.
- **AISEC-LIN** (Lineage, mod-104). Controls on dataset
  provenance, model cards, and content-addressed eval
  bundles.
- **AISEC-SEC** (Secrets, mod-105). Controls on KMS
  rotation, workload-identity federation, and model-
  registry signing-key custody.
- **AISEC-ADV** (Adversarial, mod-106). Controls on
  adversarial robustness evaluation and remediation.
- **AISEC-LLM** (LLM / agent, mod-107). Controls on
  prompt-injection defence, tool-call tiering, HITL
  gates, retrieval provenance.
- **AISEC-PRIV** (Privacy, mod-108). Controls on DP
  budget, DPIA, membership-inference defence, DLP for
  training data.
- **AISEC-GOV** (Governance, mod-109). Controls on
  policy-as-code enforcement and framework crosswalks.
- **AISEC-SC** (Supply chain, mod-110). Controls on
  SLSA attainment, model-signing, ML-BOM, and malicious-
  model-file defence.
- **AISEC-OPS** (Operations, mod-111). Controls on
  detection content, incident-response playbooks, and
  the SOC interface.

Each cluster has one or more controls. A reasonable
starting shape for a mid-maturity programme is 30-50
AI-security controls total, not 300 and not 10. Too few
and the audit coverage has holes; too many and the
library becomes unmaintainable and the control-to-
evidence binding degrades.

---

## Writing a control at the right altitude

The hardest discipline of control authoring is picking
the altitude. Three failure modes:

- **Too specific.** "The LLM gateway MUST emit a
  trajectory record using schema version 4.2 to the
  BigQuery dataset `prod_llm_telemetry` within 30
  seconds of request completion." This is an engineering
  spec, not a control. It breaks when the pipeline moves
  to Snowflake. It locks the control-library change
  cycle to the engineering change cycle.
- **Too vague.** "The organisation shall maintain
  appropriate monitoring of AI systems." This is
  unauditable; there is no observable that lets a
  reviewer say "the control is operating" or "it is not".
- **Too prescriptive about the technology.** "All models
  shall be served using KServe." This is an
  implementation choice disguised as a control.

The right altitude expresses the *control intent* —
what observable behaviour demonstrates the control is
operating — without binding to a particular tool or
schema. The engineering spec lives in the implementing
system's documentation; the control points to the spec
but is not the spec.

A worked example, control `AISEC-OPS-001`:

```yaml
id: AISEC-OPS-001
title: ATLAS-mapped detection coverage for in-scope models
version: 2.1.0
status: in_force
effective_from: 2025-04-01
owner_role: ml-security-programme-lead
scope:
  model_classes:
    - production_internal
    - production_external
  exclusions:
    - sandbox-tenant.*
    - research-only models (see AISEC-GOV-003)
intent: >
  For every in-scope model, the SIEM operates a detection
  rule for each ATLAS technique on the current coverage
  map (mod-111 chapter 01). Rules are authored in Sigma,
  carry the ATLAS technique ID, are backed by live
  telemetry, and have an owning on-call rotation.
observable:
  - Coverage map (YAML, versioned) exists and lists every
    required ATLAS technique.
  - Each covered technique has at least one rule in
    paging mode in the production SIEM.
  - Rule-to-telemetry binding is validated monthly by an
    automated job that confirms the rule's required
    fields exist in the pipeline.
  - Uncovered techniques are listed with a reason and a
    governance decision.
evidence:
  - artefact: coverage-map.yaml
    location: repo://ml-security/detection-content/coverage-map.yaml
    signed_by: ml-security-programme-lead
  - artefact: rule-telemetry-binding-report.json
    location: s3://audit-bucket/aisec-ops-001/{yyyy}/{mm}/
    retention: 7_years
    producer: automated
mappings:
  nist_ai_rmf:
    - MEASURE-2.6
    - MANAGE-4.1
  iso_iec_42001_annex_a:
    - A.6.2.4
    - A.9.2
  soc2_tsc:
    - CC7.2
    - CC7.3
  eu_ai_act:
    - article_15
    - article_72
  mitre_atlas: coverage_defined_in_artefact
dependencies:
  - AISEC-OPS-002  # rules have owning playbooks
  - AISEC-OPS-003  # severity-ladder alignment
history:
  - version: 2.1.0
    date: 2025-04-01
    author: ml-security-programme-lead
    change: added article_15 and article_72 mapping (AI Act in-force window)
  - version: 2.0.0
    date: 2024-10-15
    author: ml-security-programme-lead
    change: migrated to Sigma-primary rule authoring
  - version: 1.0.0
    date: 2024-02-01
    author: ml-security-programme-lead
    change: initial publication
```

Note what the control *does not* do:

- It does not name the SIEM. Elastic, Splunk, Sentinel
  are implementation details.
- It does not list specific ATLAS technique IDs inline.
  The coverage map is the versioned artefact; the control
  references it.
- It does not define the detection logic. mod-111
  chapter 01 does that; the control audits the output.
- It does not say "appropriate" or "reasonable". Every
  word is cashed in an observable or an artefact.

---

## Evidence attachments: what, where, how

A control is only as credible as the evidence attached
to it. The evidence contract has four parts:

### What counts as evidence

- **Primary artefacts.** The thing the control produces
  as a side effect of operating — a signed attestation,
  a decision log, a coverage map, an eval report.
- **System-of-record screenshots.** Weak evidence; a
  screenshot is a point-in-time image a reviewer cannot
  reproduce. Prefer an API query against the system of
  record with a timestamp.
- **Signed attestations.** A role's cryptographic
  signature on an artefact that it was reviewed on a
  date. This is the strongest form.
- **Automated reports.** A scheduled job writes a
  machine-generated report to immutable storage.
  Reports are enriched with the source-of-truth query,
  the queried-at timestamp, and the job's own identity
  attestation.
- **Human attestations.** A named role signs a statement
  that they personally reviewed and confirmed something.
  Last-resort when automated collection is not feasible.

### Where evidence lives

A control-library-managed evidence store is immutable,
append-only, retention-controlled, and reachable by
auditor identity on request. In practice:

- An object store with versioning + object lock (S3
  Object Lock in compliance mode, GCS retention policies,
  Azure Blob immutable storage).
- A write-only ingest pipeline that signs each artefact
  on write.
- A reader API that returns an artefact at a date
  (`?effective_at=2025-07-14T00:00:00Z`).
- Classification: evidence inherits the classification
  of the system of record it was pulled from (PHI
  reports stay in the PHI zone; the control merely
  points to them).

### How evidence is signed

Every evidence artefact has a provenance record:

```json
{
  "artefact_id": "aisec-ops-001-coverage-map-2025-07-14",
  "artefact_sha256": "a3f...",
  "produced_by": "ml-security-programme-lead",
  "produced_at": "2025-07-14T14:22:11Z",
  "produced_from": {
    "repo": "ml-security/detection-content",
    "commit": "d41a...",
    "tool_chain_version": "coverage-map-cli:v2.3.0"
  },
  "signatures": [
    {
      "signer": "ml-security-programme-lead",
      "sig_alg": "ed25519",
      "sig": "..."
    }
  ]
}
```

The signing identity is a role, bound to a KMS key with
rotation (mod-105). An auditor validating the artefact
re-verifies the signature against the key's history.

### How evidence is versioned

Evidence is immutable per date. Updates do not mutate
the artefact; they produce a new artefact with a new
timestamp. The control's history record points to the
*latest* artefact; the full chain is retained for the
regulatory retention period (7 years is a common floor
for SOX / HIPAA / SR 11-7 contexts; verify your
jurisdiction).

---

## Version-history discipline

The question "what was in force on date X?" is the
reason the library exists. Three disciplines keep the
answer honest:

### Semantic versioning of controls

Controls follow MAJOR.MINOR.PATCH:

- **PATCH** — editorial change, no change in intent or
  observable. (Typo, clarifying wording, broken link.)
  Does not require re-approval; does require history
  entry.
- **MINOR** — change in evidence requirements, in
  mappings, or in scope that does not alter intent.
  Requires owner-role approval.
- **MAJOR** — change in intent or observable. Requires
  review-board approval (chapter 03). Supersedes the
  prior version with an explicit supersession pointer.

### Supersession, not deletion

A deprecated control is not deleted. It is marked
`deprecated`, its `superseded_by` field is set, and it
remains queryable so the point-in-time question still
works. A control from 2022 that applied to a model
retired in 2024 still has to be queryable in a 2026
audit of the 2023 operating year.

### Effective-from dates

Every version has `effective_from`. The library's
point-in-time query is: "controls in force on date X"
means `status in {in_force, deprecated_but_in_force_on_X}
AND effective_from <= X AND (deprecated_from IS NULL OR
deprecated_from > X)`. If the library cannot answer
this query it is not a library; it is a document.

---

## The handoff to the senior AI governance architect (level 50)

The learning objective calls out explicitly: hand deeper
architectural authoring to senior-ai-governance-architect.
This is a scope boundary worth being deliberate about.

The programme-lead (this role, level 35) owns:

- The AI-security *section* of the control library — its
  structure, its scope, its version history.
- The evidence contract — what evidence is required for
  each control, where it is stored, how it is signed.
- The release-gate controls that enforce the section
  (chapter 02).
- The metrics that report on the section (chapter 04).
- The regulator-support evidence pack that references
  the section (chapter 05).

The senior AI governance architect (level 50) owns:

- The architectural shape of individual controls when
  the control is novel or spans multiple sections —
  e.g. "how should DP-SGD budget expiry interact with
  model-signing attestation when the model is re-trained
  on a shrinking budget". This is design work on the
  control itself.
- Framework crosswalks that require interpretation of
  the upstream framework — "does ISO/IEC 42001 A.10
  apply to our managed-LLM vendor, and if so under what
  Clause 4 scope".
- Cross-section coherence — AISEC-ADV depends on
  AISEC-LIN depends on AISEC-SC in subtle ways; the
  architect maintains the dependency graph.

The practical interface: the programme-lead files the
*need* ("we need a new control for X because of Y"),
the architect writes the control's intent/observable/
mapping, the programme-lead takes it from draft to
in-force through the review board, and both share
authorship on the history entry.

Mis-cases to avoid:

- Programme-lead authors a complex novel control alone,
  the architect finds a cross-section conflict in month
  two, the control is reworked, and the library has two
  near-duplicate historical versions. Involve the
  architect early.
- Architect writes a beautiful control that no evidence
  pipeline can satisfy. The programme-lead has to catch
  this at the evidence-contract review.
- Both roles sign off, but nobody owns getting the
  control into policy-as-code (mod-109 chapter 04). The
  control is live in the library and dead on the
  release-gate. The programme-lead owns the hand-off to
  mod-109.

---

## Standard failure modes

- **Policy as prose.** A policy document that no
  system binds to is theatre. If a control cannot be
  queried, mapped, or evidenced, it does not exist.
- **Framework-only, no evidence.** A control that lists
  ten NIST sub-category mappings but no evidence
  artefact is unauditable; the mappings are decoration.
- **Living in one GRC vendor's proprietary schema.**
  The library should be exportable to a portable format
  (YAML / JSON) so a vendor change does not require
  rebuilding the library.
- **Scope "all AI".** Scope that cannot be enumerated
  cannot be audited. Every control's scope must resolve
  to a finite set of systems at any given date.
- **No point-in-time query.** If "what was in force on
  2024-11-03?" cannot be answered automatically, the
  library is a wiki with a schema, not a library.
- **Change-log fatigue.** Every typo generates a
  review-board agenda item. Reserve the review board for
  MINOR+ changes; PATCH changes land through a lightweight
  owner-approval path.
- **Evidence that lives on the author's laptop.** An
  attestation signed on a laptop and emailed around is
  not evidence. If the artefact is not in the
  retention-controlled store, it does not count.
- **One-shot section authoring.** The section is
  written in a sprint, published, and then abandoned.
  Without a quarterly review and a feedback loop from
  the release-gate (chapter 02) and the metrics
  (chapter 04), the section decays.

---

## Summary

- The AI-security *section* of the enterprise control
  library is a first-class, versioned corpus of controls
  that bind to the ML portfolio, the ML platform, and
  the ATLAS matrix.
- Each control has an ID, title, intent, observable,
  scope, owner, framework mappings, evidence contract,
  lifecycle state, and version history.
- Controls are authored at the *intent* altitude: an
  observable behaviour, not an engineering spec, not a
  piece of prose, not a tool choice.
- Evidence is immutable, signed, retention-controlled,
  and queryable at a date. If evidence lives on a
  laptop, the control does not exist.
- Semantic versioning plus effective-from dates plus
  supersession makes the point-in-time query real.
- The programme-lead (level 35) owns the section's
  structure, evidence contract, and operational
  lifecycle; the senior AI governance architect (level
  50) owns deeper architectural authoring of individual
  controls and cross-section coherence.
- The failure modes are policy-as-prose, framework-only
  controls, evidence that lives on a laptop, and
  one-shot section authoring without a quarterly review
  cadence.
