# Chapter 04 — Governance Frameworks as Security-Engineering Deliverables

> **Note on AI-assisted content.** Verify article numbers, clause
> identifiers, and RMF sub-category labels against primary sources
> before quoting. NIST AI RMF 1.0 lives at
> [nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-1.pdf](https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-1.pdf),
> ISO/IEC 42001:2023 at
> [iso.org/standard/81230.html](https://www.iso.org/standard/81230.html),
> and the EU AI Act at
> [eur-lex.europa.eu/eli/reg/2024/1689/oj](https://eur-lex.europa.eu/eli/reg/2024/1689/oj).

---

## Why this chapter exists

The three frameworks in this chapter — **NIST AI RMF 1.0**, **ISO/IEC
42001:2023**, and **EU AI Act Articles 9–15** — are, on paper,
governance frameworks. Read at face value they describe
*obligations*: risk management processes, an AI management system,
data governance requirements, accuracy and robustness obligations.

If a security-engineering team reads them as governance-only text,
the deliverables that come out are governance-only artifacts —
policies, procedures, meeting minutes — and the operative controls
never appear. That is the failure mode a level-35 AI/ML Security &
Governance Engineer is hired to prevent.

The differentiator against the peer `ai-evaluation-engineer` (level 35,
same family) is precisely this: `ai-evaluation-engineer` packages
release-assurance evidence for regulators; **this role produces the
security-engineering deliverables that populate the evidence
package**. If the evidence is empty because the controls are empty,
the peer has nothing to package.

The rule for every obligation in this chapter:

> An obligation is not "covered" by a policy that says it is covered.
> An obligation is covered when there is (a) a concrete platform
> control implementing it, (b) evidence the control ran, and (c) an
> admission-time or release-time gate that inspects the evidence
> before the model ships.

---

## NIST AI RMF 1.0 — the four functions and how each becomes a
deliverable

NIST AI RMF 1.0 organises its guidance into four **functions** —
GOVERN, MAP, MEASURE, MANAGE — each broken into categories and
sub-categories. The framework's [AI 600-1 Generative AI Profile](https://airc.nist.gov/AI_RMF_Knowledge_Base/AI_RMF/Uses/GenAI-Profile)
overlays the four functions with GenAI-specific sub-categories that
you should also work through where the system is generative.

### GOVERN — cultural, structural, and process foundations

Governance-oriented sub-categories are the ones most likely to be
absorbed as governance-only. Where a security-engineering deliverable
exists, name it:

| Sub-category theme (paraphrased — verify exact NIST label) | Security-engineering deliverable |
| --- | --- |
| Roles, responsibilities, and accountability structures for AI risk | The **role scope + deferral contract** (chapter 05 output) — signed off between this role, `ai-evaluation-engineer`, `ai-risk-engineer`, `agentic-safety-engineer`, and the CISO organisation. |
| Policies for AI-related legal and regulatory obligations | The **control-library section for AI security** (mod-112 deliverable) that names, per obligation, the platform control and the evidence artifact. |
| Third-party AI risk management (procurement, model-hub, plugin) | The **third-party AI onboarding checklist** — signed provenance, ML-BOM, ModelScan clean, contract-level obligations for retraining and incident notification. |
| Documentation of AI system information and inventory | The **AI system inventory** — a live registry of every production model, its owning team, its risk tier, and its evidence set. |

Two habits keep GOVERN from becoming paperwork:

1. **Every policy references a control.** No policy statement in the
   library ships without pointing to the platform artifact that
   makes the policy true.
2. **Every control references an evidence artifact.** No control in
   the library ships without naming the file, signature, log line,
   or SBOM entry the release gate inspects.

### MAP — context of AI system use

MAP sub-categories require you to describe the system, its purpose,
and its risks *before* controls are chosen. Deliverables:

| Sub-category theme | Security-engineering deliverable |
| --- | --- |
| Context, intended use, stakeholders identified | The **AI system card** first draft — the input to `ai-evaluation-engineer`'s release review. |
| Categorisation of AI system (risk tier, EU AI Act tier) | The **risk-tier assignment record** — which EU AI Act tier the system sits in, why, and which controls the tier requires. |
| Risks and benefits mapped | The **threat model** (mod-102 output) — STRIDE-adapted, ATLAS-mapped, top-N threats with mitigations. |

MAP is where chapters 01, 02, and 03 vocabulary lands: threat
categories from OWASP, TTPs from ATLAS, capability envelope from
NIST AI 100-2.

### MEASURE — quantify and assess

MEASURE is where security-engineering muscle shows. Every
sub-category requires evidence-generating machinery:

| Sub-category theme | Security-engineering deliverable |
| --- | --- |
| Metrics and characteristics selected | The **evaluation-metric selection** for security dimensions: attack success rate, membership-inference advantage, extraction cost, DP (ε, δ). |
| AI system performance assessed | The **adversarial-training report** (mod-106 output), the **red-team engagement report** (mod-107), the **DP training log** (mod-108). |
| AI risks tracked over time | The **coverage register** — one row per OWASP + ATLAS + NIST AI 100-2 threat, with the version-over-version metric history. |
| Feedback / post-market monitoring | The **detection content coverage register** (mod-111) and the **IR MTTD / MTTR metric package** (mod-112). |

The MEASURE deliverables are what the peer `ai-evaluation-engineer`
consumes into the release-gate evidence package. If the deliverables
are empty, the release gate is theatrical.

### MANAGE — prioritise, respond, communicate

MANAGE covers ongoing risk treatment. Deliverables:

| Sub-category theme | Security-engineering deliverable |
| --- | --- |
| Risks prioritised | The **prioritised mitigation queue** — top-N threats × mitigation cost/coverage trade-off (mod-102 output). |
| Risk treatment implemented | The **admission-time policy-as-code** (mod-109 output) — OPA/Rego policies that block deployment when evidence is missing. |
| Response to incidents | The **AI-incident IR playbooks** (mod-111 output) — one playbook per top-N AI-incident type. |
| Third-party communication and disclosure | The **notification path in the IR playbook**, including regulator, downstream consumer, and end-user paths. |

---

## ISO/IEC 42001:2023 — the AI Management System clauses

ISO/IEC 42001:2023 is the AI Management System (AIMS) standard,
built on the ISO management-system spine (context, leadership,
planning, support, operation, evaluation, improvement) with an
AI-specific Annex A of controls.

<!-- needs-research: refresh the Annex A control identifiers and titles against ISO/IEC 42001:2023 at
https://www.iso.org/standard/81230.html
before publishing. The clauses named below are the ISO 42001 clauses; the exact Annex A control ID
should be verified per audit engagement, as the numbering has been revised in the published
standard. -->

### The clause → deliverable map

| ISO 42001 clause theme (paraphrased) | Security-engineering deliverable |
| --- | --- |
| Clause 4 — Context of the organisation | The **AI system inventory** and the **risk-tier assignment record**, shared with GOVERN and MAP above. |
| Clause 5 — Leadership | The **role scope + deferral contract** (chapter 05) referenced up to the CISO organisation. |
| Clause 6 — Planning | The **objectives and risk-treatment plan** for the security-track slice of AI. |
| Clause 7 — Support (resources, competence, awareness, communication) | The **enablement collateral** — mod-112 output — for ML engineers, agent developers, and the SOC. |
| Clause 8 — Operation | The **admission-time policy-as-code**, the **detection content**, and the **IR playbooks**. |
| Clause 9 — Performance evaluation | The **metrics package** — vulnerability burn-down, ATLAS coverage, IR MTTD/MTTR. |
| Clause 10 — Improvement | The **quarterly review cadence** — diff ATLAS matrix, close new coverage gaps, refresh threat model. |
| Annex A controls | Each Annex A control maps to a specific engineering artifact — refer to the audit engagement's control-mapping worksheet. |

The takeaway: every ISO 42001 clause maps to a concrete engineering
deliverable this role either owns or contributes to. Where the clause
looks abstract, the deliverable is the disambiguator.

### Where the peer `ai-evaluation-engineer` shows up

`ai-evaluation-engineer` (level 35 peer) owns the release-assurance
methodology and the regulator-facing evidence package that ISO 42001
Clause 9 (Performance evaluation) requires. This role produces the
inputs to that package — the security-engineering evidence artifacts
named above.

### Where `senior-ai-governance-architect` shows up

`senior-ai-governance-architect` (level 50) owns the **architecture**
of the control library — the taxonomy, the shape of each control row,
the cross-jurisdiction reconciliation between ISO 42001, NIST AI RMF,
EU AI Act, SOC 2, and sector regs. This role authors the AI-security
section within the architecture; the architecture itself is deferred
up.

---

## EU AI Act Articles 9–15 — the security-engineering slice

The EU AI Act is a risk-based regulation. Its most operational
Articles for a security engineer are 9 through 15, addressing
high-risk AI systems. Where an obligation is *not* about security, it
is deferred to `ai-evaluation-engineer` (release-time),
`ai-risk-engineer` (harm modelling), or Legal (opinion). Where an
obligation *is* about security, it must translate to an engineering
artifact.

<!-- needs-research: verify Article numbering and content against the consolidated OJ text at
https://eur-lex.europa.eu/eli/reg/2024/1689/oj and the current guidance from the EU AI Office. The
Act was published in OJ 2024/1689 and applies in phases; some obligations become enforceable at
staged dates. Confirm current enforceability windows before quoting obligations as active. -->

### Article 9 — Risk management system

Requires a documented, iterative risk-management system across the AI
system lifecycle.

**Security-engineering deliverables:**

- The **threat model** (mod-102 output) — the iterative risk-model
  covering identification, estimation, and evaluation of risks
  arising from the use of the system.
- The **coverage register** — evidence that risks are addressed and
  reviewed.
- The **quarterly review cadence** — the record of iteration.

### Article 10 — Data and data governance

Requires training, validation, and testing datasets to meet quality
criteria and to have documented data-governance practices, including
management of biases.

**Security-engineering deliverables (security slice only):**

- The **data provenance graph** (mod-104 output) linking every
  training record to a signed ingest event.
- The **data-quarantine and outlier-detection log** — evidence of
  ingest-time integrity checks.
- The **PII / PHI DLP configuration** applied to training data (see
  mod-108).

Bias / fairness assessment sits with `ai-risk-engineer` (level 25);
this role hands the provenance graph as input to that assessment.

### Article 11 — Technical documentation

Requires technical documentation demonstrating conformity with the
Act's requirements.

**Security-engineering deliverables:**

- The **model card**, the **AI system card**, and the **ML-BOM**
  (mod-104 + mod-110).
- The **signed evidence bundle** attached to the release.

`ai-evaluation-engineer` (peer) owns the assembly of the technical
documentation for regulator submission; this role hands the security
artifacts into the assembly.

### Article 12 — Record-keeping (automatic logs)

Requires automatic recording of events during operation to trace risk
and post-market monitoring.

**Security-engineering deliverables:**

- The **immutable audit-log architecture** (mod-104) — WORM /
  append-only, covering training, inference, deployment, and
  admission events.
- The **retention configuration** aligned to the Act's obligations
  and to sector-reg requirements.

### Article 13 — Transparency to deployers

Requires accompanying instructions for use covering, among other
things, characteristics, limitations, and risks.

**Security-engineering deliverables:**

- The **model card + system card** contribution on security
  properties — attack success rate under specified attacks, DP
  budget, sensitive-data disclosure risk, tenant-isolation
  guarantees.

### Article 14 — Human oversight

Requires that the AI system be designed to be effectively overseen by
natural persons during use. For agent applications, this is the
operative article — human-in-the-loop is not optional at high-risk.

**Security-engineering deliverables:**

- The **agent-tool ACL configuration** with human-in-the-loop for
  irreversible actions above a threshold (mod-107).
- The **override-and-stop path** — how a human halts the system and
  the record of every halt.
- The **oversight-training material** for deployers.

### Article 15 — Accuracy, robustness, and cybersecurity

This is the article most explicitly directed at this role.

**Security-engineering deliverables:**

- **Accuracy.** The **release-time evaluation report** (owned by
  peer `ai-evaluation-engineer`; this role feeds the security
  dimensions).
- **Robustness.** The **adversarial-training report** (mod-106),
  with attack success rate at named perturbation budgets under
  named attacks (NIST AI 100-2 vocabulary — chapter 03).
- **Cybersecurity.** The **threat model**, the **coverage register**
  against OWASP + ATLAS, the **admission-time policy-as-code**, and
  the **IR playbook set** — the union of this role's mod-102 through
  mod-111 outputs.

Article 15 is where "cybersecurity of an AI system" is normalised as
a regulatory obligation. If your control library does not answer
"which artifact do you point to for Article 15?", the release gate is
not defensible under audit.

### The other Articles worth reading, briefly

- **Article 16** — obligations of providers of high-risk AI
  systems (signing, CE marking, technical documentation).
- **Article 43** — conformity assessment procedures.
- **Article 72** — post-market monitoring obligations. This role
  produces the security dimensions of the post-market monitoring
  package (detection content, incident metrics, coverage
  regressions).
- **Articles 50–52** — transparency obligations for GenAI providers
  and deployers, including AI-generated-content disclosure. See
  mod-111 for provenance / watermarking cross-references (C2PA,
  NIST AI 100-4).

---

## Sector regs — the same shape, one paragraph each

The pattern generalises. This role owns the security-engineering
translation of every applicable framework:

- **SOC 2 Trust Services Criteria.** The Security, Availability, and
  Confidentiality criteria map to the same platform controls
  (identity, network, secrets, audit, incident response) with
  AI-specific evidence.
- **SR 11-7 (Fed model risk management).** Requires effective
  challenge and validation of models. This role provides the
  security dimensions — adversarial robustness, extraction risk,
  poisoning risk — into the model validation record.
- **FDA Good Machine Learning Practice / PCCP.** Applies to
  regulated medical device software. The security-engineering
  deliverables (provenance, immutable audit, DP for training on
  patient data, IR playbooks) map onto FDA guidance.
- **HIPAA Security Rule.** Administrative, physical, and technical
  safeguards apply to any ML platform training on PHI. Encryption
  at rest and in transit, workforce training, access management,
  audit controls — all directly ownable by this role in the
  ML-platform slice.
- **EU Cyber Resilience Act (Regulation (EU) 2024/2847).** Applies
  cybersecurity requirements to products with digital elements,
  including AI-enabled products. The security-engineering
  deliverables — SBOM, ML-BOM, vulnerability handling, SDLC —
  translate directly.

Mod-109 covers each in depth; this chapter's job is only to install
the pattern.

---

## The frontier-lab safety frameworks — one paragraph each

Frontier labs publish safety-and-security frameworks that structure
deployment-tier gating: Anthropic's Responsible Scaling Policy, OpenAI's
Preparedness Framework, DeepMind's Frontier Safety Framework. Where an
enterprise deploys a frontier-lab model, or where the enterprise
operates its own frontier-scale training, these frameworks establish
the *deployment-tier* language your control library should mirror.
Understand each at the depth required to translate the tier structure
into enterprise gates; frontier red-team methodology depth is deferred
to `agentic-safety-engineer` (level 40).

- **Anthropic Responsible Scaling Policy (RSP)** —
  [anthropic.com/rsp](https://www.anthropic.com/rsp).
- **OpenAI Preparedness Framework** —
  [openai.com/index/updating-our-preparedness-framework](https://openai.com/index/updating-our-preparedness-framework/).
- **DeepMind Frontier Safety Framework (FSF)** —
  [deepmind.google/discover/blog/introducing-the-frontier-safety-framework](https://deepmind.google/discover/blog/introducing-the-frontier-safety-framework/).

---

## The deliverable pattern

Any conversation that starts "how do we cover Article 15?" or "how do
we cover ISO 42001 Clause 8?" resolves to the same three-column
answer:

| Column | Contents |
| --- | --- |
| **Obligation** | Framework + clause / article identifier, one-sentence paraphrase, source URL. |
| **Security-engineering artifact** | The specific artifact — file path, registry entry, dashboard, policy — that satisfies the obligation. |
| **Enforcement mechanism** | The admission-time policy, the release gate, or the runbook that makes the artifact non-optional. |

This is the shape of Exercise 04. If you leave this chapter able to
produce this row for any obligation on demand, the crosswalk work is
done.

---

## What this chapter is training you *not* to do

- Do not restate the framework's language as if that were the
  deliverable. Framework language is the input; the deliverable is
  the artifact that satisfies the framework language.
- Do not defer everything up to `senior-ai-governance-architect`.
  The architect owns the library's *architecture*; you own the
  security-engineering *content* of the library.
- Do not defer everything sideways to `ai-evaluation-engineer`. The
  evaluator packages the evidence; you produce the evidence.
- Do not defer everything down to `ai-governance-analyst`
  (level 15). Framework-crosswalk legwork is deferred down, but the
  engineering translation is yours.

---

## Summary

- NIST AI RMF 1.0 (GOVERN / MAP / MEASURE / MANAGE) — every
  sub-category has an engineering deliverable this role owns or
  contributes to.
- ISO/IEC 42001:2023 (AIMS) — every clause and every Annex A
  control maps to a specific artifact.
- EU AI Act Articles 9–15 — Article 15 is the operative security
  article; Articles 9, 10, 12, and 14 are the framework this role
  populates with engineering artifacts.
- Sector regs (SR 11-7, FDA GMLP/PCCP, HIPAA, EU CRA, SOC 2) —
  same shape, per-sector specificity. Mod-109 owns the depth.
- Frontier-lab frameworks (Anthropic RSP, OpenAI Preparedness,
  DeepMind FSF) — the *deployment-tier* language your enterprise
  gates should mirror; frontier red-team depth is deferred up to
  `agentic-safety-engineer`.
- Every obligation resolves to a three-column row: obligation →
  security-engineering artifact → enforcement mechanism.
- Chapter 05 nails down which role owns each artifact so the
  deliverables converge and do not leak into duplication or gaps.
