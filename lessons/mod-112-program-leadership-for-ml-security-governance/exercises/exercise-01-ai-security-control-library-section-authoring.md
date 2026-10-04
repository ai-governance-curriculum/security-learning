# Exercise 01 — AI-Security Control-Library Section Authoring

**Estimated effort:** ~3 hours
**Deliverable:** A committed starter *section* of the
AI-security control library for one chosen cluster
(`AISEC-OPS`, `AISEC-SC`, `AISEC-LLM`, `AISEC-PRIV`,
`AISEC-ADV`, `AISEC-LIN`, `AISEC-TM`, `AISEC-SEC`,
`AISEC-PLAT`, or `AISEC-GOV`), consisting of
(a) a **library schema** (YAML or JSON) with the fields
required by chapter 01 (id, title, version, status,
effective_from, owner_role, scope, intent, observable,
evidence, mappings, dependencies, history); (b) **at
least five controls** fully populated against the chosen
cluster, including intent + observable + evidence
contract + framework mappings; (c) an **evidence-contract
specification** per control that names the artefact, its
producer, its signing identity, its storage location, and
its retention; (d) a **point-in-time-query specification**
describing how a reviewer answers "what controls were in
force on date X and what evidence demonstrates each"
using the library as authored; (e) a **lifecycle operations
plan** covering authorship cadence, review-board
engagement for MAJOR changes, deprecation / supersession,
and the hand-off interface to the senior AI governance
architect (level 50); (f) a **control-library audit case**
walking through one example audit question against the
section and showing how the library answers it end-to-end.
**Prerequisites:** Chapter 01 read end-to-end. A chosen
cluster. Familiarity with at least one upstream framework
whose mappings the controls will carry (NIST AI RMF, ISO/
IEC 42001 Annex A, SOC 2 TSC, EU AI Act, SR 11-7, HIPAA).
Access to the primary text of at least one of those
frameworks for mapping fidelity.

---

## Objective

Chapter 01's claim is that an AI-security programme runs
on a *library* of controls, not a policy document; and
that the library's point-in-time queryability is what
turns policy into audit evidence. This exercise is where
the claim is cashed in by authoring a real starter
section against a cluster you own.

By the end of this exercise you have:

- A **library schema** that fixes the shape of every
  future control in the section.
- A **starter set of controls** that is complete enough
  to be reviewed by the senior AI governance architect
  (level 50) and taken to the review board.
- An **evidence contract** per control that an
  engineering team can read and know what to produce.
- A **point-in-time query specification** that the
  audit team can validate against on a real date.
- A **lifecycle operations plan** that keeps the
  section healthy past its initial authoring.
- An **audit case walkthrough** showing the library
  working on a representative question.

You are **not** authoring the entire enterprise control
library in this exercise, and you are not writing the
deeper architectural pieces that belong to the level-50
architect (the handoff is explicitly in deliverable E).

---

## Problem statement

Pick one cluster up front, name it, and justify it. Good
starters:

- **AISEC-OPS** (operations) if you have mod-111 context
  — the detection-coverage, playbook-coverage, severity-
  ladder, and SOC-interface controls.
- **AISEC-SC** (supply chain) if you have mod-110
  context — SLSA attainment, model-signing, ML-BOM,
  malicious-model-file defence.
- **AISEC-LLM** (LLM / agent) if you have mod-107
  context — tool tiering, HITL, retrieval provenance,
  prompt-injection defence.
- **AISEC-PRIV** (privacy) if you have mod-108 context
  — DP posture, membership-inference defence, DLP for
  training data, DPIA artefact chain.
- **AISEC-TM** (threat modelling) if you have mod-102
  context — threat-model existence, review cadence,
  binding to deployed version.
- **AISEC-GOV** (governance) if your focus is the
  policy-as-code interface to mod-109 — control
  evaluation on release-gate, exception mechanism,
  mapping to the framework crosswalk.

State before you start:

- Cluster chosen and justified.
- Framework the mappings will be grounded in (one
  primary, at least one secondary).
- The repo path the section will live at
  (`controls/aisec-<cluster>/`).
- The storage choice for evidence artefacts (object
  store with retention lock, or a documented plan).

If you do not have access to an evidence-store
implementation, document the schema the store would
expose and the properties it would honour; the controls
still bind to that interface.

---

## Requirements

### Deliverable A — library schema

A machine-readable schema (JSON Schema, YAML schema,
Pydantic model, or Rego-friendly structure) that every
control in the section conforms to. The schema expresses:

- Required fields: `id`, `title`, `version`,
  `status in {draft, in_force, deprecated,
  superseded}`, `effective_from`,
  `owner_role`, `scope`, `intent`, `observable`,
  `evidence`, `mappings`, `history`.
- Optional fields: `dependencies`, `superseded_by`,
  `deprecated_from`, `notes`.
- Constraints:
  - `id` matches `AISEC-[A-Z]+-[0-9]{3,}`.
  - `version` is semver-compatible (`MAJOR.MINOR.
    PATCH`).
  - `effective_from` is ISO-8601 date.
  - `history` is a non-empty ordered list with
    `version`, `date`, `author`, `change` on each
    entry.
  - `evidence` is a non-empty list with required
    sub-fields (`artefact`, `location`, `signed_by`,
    `retention` or `retention_lifecycle`).
  - `mappings` is at least one framework-mapping block.
- A validator (Python / Rego / `ajv`-based JS /
  equivalent) that returns pass/fail against a sample
  control.

Document the schema in the repo so an authoring
engineer can author a new control from the schema alone.

### Deliverable B — five fully-authored controls

At least five controls in the chosen cluster, fully
populated against the schema. Each control includes:

- The complete frontmatter.
- An `intent` paragraph in plain prose explaining what
  the control is for; a reviewer reads this at an
  audit without needing more context.
- An `observable` block enumerating observable facts
  that demonstrate the control is operating.
- An `evidence` block with concrete artefact
  descriptions.
- A `mappings` block with at least one upstream
  framework reference per control, verified against
  the primary text (not a secondary summary).
- A `history` block with at least an initial
  publication entry.

The controls together **cover the chosen cluster
meaningfully**: no two controls restate the same intent;
the set is a credible starter against the cluster.

### Deliverable C — evidence-contract specification

For every evidence artefact across the five controls,
specify:

- The artefact's producer (role or automated system).
- The artefact's shape (schema or JSON/YAML sample).
- The signing identity and KMS binding (mod-105
  reference acceptable).
- The storage location (object-store path with the
  classification zone).
- The retention term (with the regulatory basis if
  known — SOX 7 years, HIPAA 6 years, GDPR
  jurisdiction-dependent).
- The query interface — how a reviewer retrieves the
  artefact at a date.

If any artefact's pipeline does not yet exist,
mark it so, and describe what has to be built; a
control that depends on a non-existent pipeline is
not in `in_force` status until the pipeline exists.

### Deliverable D — point-in-time query specification

Describe (SQL, pseudo-code, or a prose spec) how to
answer:

- "What controls were in force on 2025-07-14?"
- "What evidence demonstrates `AISEC-<cluster>-001` was
  operating on 2025-07-14?"
- "What are all controls in the section as of today
  whose MAJOR version has changed since
  2024-01-01?"

Include the actual query against the schema in
deliverable A; if your store is a Git repo of YAML
files, the query is a Git log over the files; if it is
a database, the query is SQL. If the point-in-time
query is "we eyeball the Git history and manually
reconstruct", that is not a passing deliverable.

### Deliverable E — lifecycle operations plan

A short document (1-2 pages) covering:

- **Authorship cadence.** When is a new control
  authored (triggered by what — a mod-102 threat
  model, a mod-109 framework change, a mod-111
  incident retrospective)?
- **Review-board engagement.** MAJOR changes go to
  the review board; what is the board composition
  (chapter 03), what is the submission artefact, what
  is the quorum, what is the audit trail?
- **Deprecation / supersession.** When is a control
  deprecated vs. superseded; what is the artefact
  trail; how is the point-in-time query preserved?
- **Handoff with the senior AI governance architect
  (level 50).** Which authorship situations do you
  escalate to the architect (novel multi-cluster
  control, cross-framework-interpretation question,
  dependency-graph conflict); what is your draft
  responsibility vs. the architect's; what is the
  joint signature on history entries?
- **PATCH / MINOR / MAJOR classification.** Who
  decides which band a change falls in; what is the
  tie-break.

### Deliverable F — audit-case walkthrough

Pick one plausible audit question against the section
and walk through how the library answers it. The
walkthrough shows:

- The question (verbatim, as a reviewer might phrase
  it).
- The library query the programme-lead runs.
- The controls returned.
- The evidence artefacts the controls point to.
- The signatures and dates on each.
- The gaps, if any, and how they would be addressed.

Example question shapes:

- "Show me how your programme covered ATLAS
  `AML.T0024.001` for in-scope production models on
  2025-04-01."
- "What control required the model-signing
  attestation that is on model `model-xyz:v3.4`?"
- "Which controls deprecated between 2024-01-01 and
  2025-01-01 superseded what?"

---

## Starter guidance

- **Pick a cluster where you can anchor to a real
  mod-10x chapter.** The exercise is much easier if
  your cluster has existing module content you can
  reference and ground against.
- **Mappings must be verified.** Each framework
  mapping is checked against the primary text (not a
  blog, not a vendor summary). Mark any uncertain
  mapping with `<!-- needs-research: ... -->` so
  reviewers see it.
- **Author the schema before any control.** A control
  authored before the schema is almost always
  misshapen.
- **Intent is prose; observable is a list.** Keep
  the altitude discipline from chapter 01. Observable
  items are what a reviewer could tick off; intent is
  what explains the ticks.
- **Evidence artefacts must be real or planned.** A
  control whose evidence is "to be designed" is not
  in-force; put it in draft and name the engineering
  blocker.
- **The handoff with the architect is a documented
  interface, not a sentence.** Deliverable E is where
  this lives.
- **Reference, do not duplicate.** The control
  references the detection-rule file, the policy-as-
  code rule, the SBOM producer — it does not
  reproduce them.

---

## Acceptance criteria

A passing section:

- A validatable schema, a validator script, and a
  sample control that passes validation.
- Five controls, each with full intent + observable +
  evidence + mappings + history, mapped to at least
  one primary-framework requirement each.
- An evidence contract per artefact with producer,
  shape, signing identity, store, retention, query
  interface.
- A point-in-time query that works today against the
  authored section.
- A lifecycle operations plan with authorship
  cadence, review-board process, deprecation /
  supersession, level-50 handoff, and
  PATCH/MINOR/MAJOR classification.
- An audit-case walkthrough that is end-to-end
  (question → query → controls → evidence →
  signatures → interpretation).

A failing section:

- Controls without `observable`.
- Mappings cited to secondary sources without the
  primary citation.
- Evidence artefacts whose producer or signing identity
  is undefined.
- A point-in-time query answered "manually from Git".
- A lifecycle plan that does not address the level-50
  handoff.
- An audit-case walkthrough that reads as "we would
  tell the auditor…" rather than "we query the
  library and return X".

---

## Stretch goals

- **Policy-as-code binding.** For one control, author
  the Rego rule in mod-109 chapter 04 that evaluates
  the control on a release-gate; show the control-id
  attached to the rule's decision log.
- **Automated evidence collection.** For one control,
  implement the automated evidence-collection job
  that writes a signed artefact to the store on a
  schedule.
- **Multi-cluster dependency graph.** Add a
  dependency from a control in your cluster to a
  control in another cluster; show the dependency
  graph and how the point-in-time query honours
  dependencies.
- **Supersession pathway.** Author a MAJOR change to
  one of the five controls, showing the superseded
  version remains queryable and the supersession
  record is complete.
- **Framework-crosswalk coverage report.** Produce the
  framework-crosswalk coverage report for the chosen
  cluster — for each sub-requirement of each mapped
  framework, which control(s) satisfy it.
- **GRC-platform export.** Export the YAML section to
  one GRC vendor's import format (ServiceNow IRM,
  Hyperproof, Drata, Vanta) and show the round-trip
  preserving the schema fields.

---

## Do not

- Do not claim a framework mapping you have not
  verified against the primary text.
- Do not author a control whose evidence lives on a
  developer's laptop.
- Do not use "all AI" as a scope. Scope must resolve
  to a finite set.
- Do not deliver a Word document instead of a
  schema-conforming YAML file. The point of the
  exercise is a machine-readable section.
- Do not duplicate controls across clusters. If a
  control belongs in two clusters it belongs in one,
  and the other cluster references it.
- Do not commit the solution bundle to this repo.
  Solutions live in the paired `-solutions` repo.
