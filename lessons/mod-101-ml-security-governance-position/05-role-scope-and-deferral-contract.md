# Chapter 05 — Role Scope and Deferral Contract on the Level Ladder

> **Note on AI-assisted content.** The level ladder and adjacent-role
> ownership described here mirror the definitions in this repository's
> [`README.md`](../../README.md), [`CURRICULUM.md`](../../CURRICULUM.md),
> and [`JOB_REQUIREMENTS.md`](../../JOB_REQUIREMENTS.md). Confirm the
> `ownership_rule` and cross-repo references there before quoting the
> level structure externally.

---

## Why this chapter exists

Role identity is the last thing that gets clarified in security-and-
governance teams and the first thing that costs a program its
credibility when it goes wrong. Two failure modes are common:

1. **Scope creep.** This role absorbs work that belongs to
   `ai-risk-engineer` (harm modelling, level 25),
   `ai-evaluation-engineer` (release-assurance packaging, peer at
   level 35), or `senior-ai-governance-architect` (library
   architecture, level 50). The consequence: the security engineer
   burns out, the depth of the security-engineering craft
   deteriorates, and the peer roles atrophy.
2. **Scope collapse.** This role defers everything up or sideways
   and stops owning anything operationally. The consequence: the
   platform ships with no threat model, no admission gates, no
   detection content, and no IR playbooks, because the deferral
   partners were never supposed to own those artifacts.

The deliverable of this chapter is a **signed deferral contract** —
one written, cross-referenced document that names, for every
security-engineering artifact this role could plausibly own, who
actually owns it, who consumes it, and what handshake happens at the
boundary.

The deferral contract is not a nice-to-have. It is the artifact
Exercise 05 produces; it is a mod-112 deliverable in maintenance
mode; and it is the document you hand to a new peer, a new manager,
or a new CISO organisation on day one.

---

## The level ladder in one page

The AI Governance family — the ladder this role sits on — is
composed of the following roles and levels:

| Level | Role | Charter (one-line) |
| --- | --- | --- |
| 15 | `ai-governance-analyst` | Framework-crosswalk legwork, policy tracking, regulator-change monitoring. |
| 25 | `ai-risk-engineer` | Harm modelling, risk quantification, enterprise AI risk register, guardrail engineering. |
| 35 | **`ai-ml-security-governance-engineer`** (this role) | **Security-engineering ownership of ML/LLM systems, controls, evidence, detection, IR, and control-library content for the security section.** |
| 35 (peer) | `ai-evaluation-engineer` | Release-assurance methodology, regulator-facing evidence packaging, evaluation harnesses. |
| 40 | `agentic-safety-engineer` | Frontier-agent red-team methodology, dangerous-capability evaluation, novel red-team research. |
| 50 | `senior-ai-governance-architect` | Control-library architecture, taxonomy, cross-jurisdiction reconciliation. |
| 60 | `head-of-ai-governance` | Program leadership, board-level reporting, regulator engagement. |
| 70 | `chief-ai-officer` | Executive AI leadership. |

Adjacent-track roles that are not in the AI Governance family but
that this role deals with daily:

| Role | Track | Relationship |
| --- | --- | --- |
| `ai-infra-engineer` (level 25) | AI Infrastructure | Deferred-down for general infra hardening prerequisites. |
| `ai-infra-senior-engineer` (level 30) | AI Infrastructure | Deferred-down for senior infra hardening. |
| `ai-infra-mlops-learning` (level 25) | AI Infrastructure MLOps | Sideways-partner; this role wires security gates into MLOps pipelines. |
| `ai-infra-ml-platform-learning` (level 30) | AI Infrastructure ML Platform | Sideways-partner; this role's zero-trust and runtime-security slices plug into the platform. |
| `llm-application-developer-learning` (level 25) | AI Engineering | Sideways-partner; this role assesses LLM apps and requires their evidence. |
| `rag-engineer-learning` (level 25) | ML Engineering | Sideways-partner; this role assesses RAG systems and requires their evidence. |
| `ml-engineer-learning` (level 20) | ML Engineering | Deferred-down for classical ML fundamentals. |
| Enterprise SOC / DFIR | Security Operations | Consumer-partner; this role authors AI-specific detection and playbooks the SOC executes. |
| Legal counsel | Legal | Consumer-partner; this role supports without delivering legal opinion. |

---

## The role's charter in one paragraph

**AI/ML Security & Governance Engineer** — a hands-on level-35
specialist who owns the *engineering craft* of AI/ML security and
governance end-to-end for the AI security section of the enterprise
control library. Owns the threat model, the platform hardening
(zero-trust, workload identity, secrets, network segmentation,
admission-time gates), the adversarial-ML and LLM-attack defences at
platform scale, the ML supply-chain controls, the privacy-engineering
craft for ML, the detection content, the AI-specific IR playbooks,
and the security-engineering content that populates NIST AI RMF, ISO
42001, EU AI Act, SOC 2, and sector-reg obligations. Defers up to
level 40 for frontier red-team method research, to level 50 for
control-library *architecture*, to level 60 for program leadership.
Defers sideways to `ai-evaluation-engineer` (peer, level 35) for
release-assurance packaging and to `ai-risk-engineer` (level 25) for
harm modelling. Deliverables are engineering artifacts, not
policies-that-cite-policies.

---

## Adjacent-role scope tables

The tables below are the operational core of the deferral contract.
For each adjacent role, the columns are:

- **Artifact.** The concrete deliverable.
- **This role.** Whether this role owns, contributes to, consumes,
  or is out of scope for the artifact.
- **Adjacent role.** Whether the adjacent role owns, contributes,
  consumes, or is out of scope.
- **Handshake.** The document, ticket type, review meeting, or
  policy interface that transfers the artifact across the boundary.

### 5.1 vs. `ai-risk-engineer` (level 25)

`ai-risk-engineer` owns harm modelling — who is affected by an AI
system, what is the societal / population-level risk, how is the
enterprise AI risk register populated. This role owns the *technical*
threat model — attacker capability, exploit chain, mitigations.

| Artifact | This role | `ai-risk-engineer` | Handshake |
| --- | --- | --- | --- |
| Harm model (affected populations, societal risk) | Consumes | **Owns** | Harm model attached to threat model as `harm-model.md`. |
| Enterprise AI risk register | Consumes (for prioritisation) | **Owns** | Register consulted at mod-112 quarterly review. |
| Guardrail engineering (content-safety, prompt guardrails) | Consumes (for LLM security integration) | **Owns** | Guardrail contract attached to mod-107 threat model. |
| Threat model (STRIDE, ATLAS, top-N threats with mitigations) | **Owns** | Contributes (harm inputs) | Threat model reviewed jointly at mod-102 sign-off. |
| ATLAS-mapped detection content | **Owns** | Out of scope | Detection content owned by this role, deployed to SOC. |
| IR playbooks for AI incidents | **Owns** | Contributes (harm classification) | Playbook harm-classification cross-referenced from harm model. |
| DP-SGD training runs (privacy engineering) | **Owns** | Contributes (privacy-risk assessment) | Assessment attached as prerequisite; this role executes DP-SGD. |

The one-line rule: **`ai-risk-engineer` names who gets hurt; this
role names how the attack happens and stops it.**

### 5.2 vs. `ai-evaluation-engineer` (peer, level 35, same family)

The peer packet is the most subtle boundary because the levels
match. The differentiator is *release-assurance methodology* vs.
*security-engineering craft*.

| Artifact | This role | `ai-evaluation-engineer` | Handshake |
| --- | --- | --- | --- |
| Release-gate methodology | Contributes (security dimensions) | **Owns** | Release-gate methodology consumes this role's security evidence. |
| Regulator-facing evidence package | Contributes (security dimensions) | **Owns** | Evidence bundle assembled at release; this role's artifacts required. |
| Evaluation harness (Inspect or equivalent) | Uses (for red-team engagement) | **Owns** | Red-team runs use the peer's harness for reproducibility. |
| Adversarial-training report (mod-106) | **Owns** | Consumes (for release-gate) | Report signed and attached to model registry entry. |
| Red-team engagement report (mod-107) | **Owns** | Consumes (for release-gate) | Report attached to release evidence bundle. |
| DP training log (mod-108) | **Owns** | Consumes (for release-gate) | Log signed and attached; peer packages for regulator. |
| ML-BOM / signed provenance (mod-104 + mod-110) | **Owns** | Consumes (for release-gate) | Bundle attached to release. |
| ATLAS-mapped detection content | **Owns** | Out of scope (peer packages metrics only) | SOC deploys; peer references coverage in evidence. |
| Model card + system card | Contributes (security section) | **Owns** | Peer assembles final card; this role authors security section. |
| EU AI Act Article 11 technical documentation | Contributes (security section) | **Owns** | Peer assembles; this role authors security artifacts. |
| Adversarial-ML methodology depth | **Owns** | Consumes | Peer requires the method be published; this role authors it. |
| Regulator-facing summary language | Reviews for accuracy | **Owns** | Peer writes; this role reviews the security claim wording. |

The one-line rule: **`ai-evaluation-engineer` assembles the release
evidence; this role produces the security artifacts inside the
evidence bundle.**

### 5.3 vs. `agentic-safety-engineer` (level 40)

`agentic-safety-engineer` sits above this role. The differentiator is
frontier-agent red-team methodology depth.

| Artifact | This role | `agentic-safety-engineer` | Handshake |
| --- | --- | --- | --- |
| Enterprise agent security engineering (mod-107) | **Owns** | Consumes (as input to frontier methodology) | Enterprise threat model shared upstream. |
| Frontier-agent red-team method research | Consumes (published methods) | **Owns** | Methods published and adopted at this role's scale. |
| Dangerous-capability evaluations | Out of scope | **Owns** | Handled at frontier-lab / regulator scale. |
| Novel jailbreak research | Consumes (published patterns) | **Owns** | Patterns published; this role wires detection content. |
| Agent-tool ACL patterns at enterprise scale | **Owns** | Contributes (methodology) | ACL patterns published upstream. |
| Frontier deployment-tier gating | Contributes (enterprise translation) | **Owns** | Frontier tier structure translated to enterprise gates. |
| IR playbook for enterprise agent misuse | **Owns** | Consumes | Playbook shared upstream where frontier-relevant. |

The one-line rule: **`agentic-safety-engineer` researches the frontier
methodology; this role deploys the methodology at enterprise scale.**

### 5.4 vs. `senior-ai-governance-architect` (level 50)

`senior-ai-governance-architect` owns the *architecture* of the
control library. This role owns the *content* of the AI-security
section of the library.

| Artifact | This role | `senior-ai-governance-architect` | Handshake |
| --- | --- | --- | --- |
| Control-library architecture (taxonomy, row shape, cross-jurisdiction reconciliation) | Consumes | **Owns** | Architecture defined; this role's rows conform. |
| AI-security section of control library | **Owns** | Reviews | Section maintained by this role; architect reviews on cadence. |
| Cross-jurisdiction control reconciliation (EU AI Act ↔ NIST AI RMF ↔ ISO 42001 ↔ sector regs) | Contributes (security dimension) | **Owns** | Reconciliation shared to informed the security section. |
| New-framework onboarding (adding a new obligation set to the library) | Contributes (security artifacts) | **Owns** | Architect leads onboarding; this role fills the security cells. |
| Policy-taxonomy authoring | Consumes | **Owns** | Taxonomy defines category IDs used in this role's rows. |
| Admission-time OPA/Rego policies | **Owns** | Reviews (for library conformance) | Policies conform to the architecture's control-ID schema. |

The one-line rule: **the architect builds the shelves; this role
fills the security shelves with the right books.**

### 5.5 vs. `head-of-ai-governance` (level 60)

`head-of-ai-governance` runs the program. This role runs the
security slice of the program.

| Artifact | This role | `head-of-ai-governance` | Handshake |
| --- | --- | --- | --- |
| Program strategy | Contributes (security dimension) | **Owns** | Strategy briefed to this role; security slice contributed. |
| Board-level reporting | Contributes (metrics) | **Owns** | Metrics package (mod-112) feeds board slide. |
| Regulator engagement | Supports (security artifacts) | **Owns** | Regulator requests routed through head; this role produces artifacts. |
| Program metrics package (vulnerability burn-down, ATLAS coverage, IR MTTD/MTTR) | **Owns** | Consumes | Metrics package produced by this role for board. |
| Program budget for the security slice | Justifies | **Owns** | Justification produced by this role, decision by head. |
| Cross-CISO organisation interface | Runs the working-level | **Owns** the executive-level | Quarterly working session run by this role; escalation to head. |

The one-line rule: **the head reports up; this role produces the
security-slice numbers the head reports.**

### 5.6 vs. enterprise Security Operations / DFIR

This role authors the AI-specific detection content and IR playbooks.
The SOC executes them.

| Artifact | This role | Enterprise SOC / DFIR | Handshake |
| --- | --- | --- | --- |
| SIEM detection content (Sigma / KQL / SPL) | **Owns** the authoring | **Owns** the deployment and tuning | Content merged into SOC's SIEM repo; on-call tuning by SOC. |
| Runtime detection (Falco / eBPF) | **Owns** the AI-specific rules | Owns the enterprise-generic rules | Rules deployed via same runtime-security pipeline. |
| IR playbook — AI-specific incident types | **Owns** the AI-specific steps | Owns the enterprise IR framework | Playbook slots into enterprise IR playbook set. |
| SOC on-call for AI incidents | Contributes (subject-matter escalation) | **Owns** the 24/7 rotation | Escalation path documented in playbook; this role paged on-call. |
| Post-incident review | Contributes (technical analysis) | **Owns** the PIR ceremony | This role co-authors the AI-specific PIR sections. |

The one-line rule: **this role writes the detection and the playbook;
the SOC pages the responder and executes the runbook.**

### 5.7 vs. Legal counsel

| Artifact | This role | Legal | Handshake |
| --- | --- | --- | --- |
| Legal opinion (jurisdiction, applicability, litigation risk) | Out of scope | **Owns** | Opinion consulted; not authored by this role. |
| Regulator communication drafting | Contributes technical clarity | **Owns** the legal wording | Draft reviewed by Legal before send. |
| Contract terms with vendors (SLA on retraining notification, incident notification) | Contributes technical requirements | **Owns** the contract wording | Requirements handed to Legal; Legal drafts terms. |

The one-line rule: **this role produces the technical facts; Legal
produces the legal wording.**

---

## The signed deferral contract — the artifact

A working deferral contract has these sections:

1. **Preamble.** The role's charter in one paragraph (§ "The role's
   charter in one paragraph" above).
2. **Adjacent-role scope tables** for every relationship the role
   has — every table in the previous section, plus any organisation-
   specific ones (e.g., a Product Security team, a Trust & Safety
   team, a data-privacy officer).
3. **Escalation path.** Who this role escalates to and for what.
4. **Escalation trigger set.** Explicit criteria for escalation
   (e.g., "an incident where the SOC MTTR crosses SLO," "a threat
   model that names a novel attack class published in the last
   quarter," "a control-library gap that blocks a release").
5. **Review cadence.** Quarterly review with each adjacent role;
   annual re-sign with all.
6. **Signature block.** This role, each adjacent role, the head of
   AI governance, and the CISO organisation representative.

This is Exercise 05's deliverable and mod-112's maintenance artifact.

---

## The two anti-patterns to name explicitly

### Anti-pattern 1 — "The security team owns AI safety"

Untrue. AI safety, in the sense of harmful-content prevention,
fairness, and downstream harm, is owned by `ai-risk-engineer` (level
25) and — at the frontier level — by `agentic-safety-engineer` (level
40). This role owns the *security* of the AI system: threat model,
adversarial defence, supply chain, secrets, detection, IR.

The distinction matters because when a fairness regression is filed
as a security incident, the wrong on-call is paged and the wrong
control library is consulted.

### Anti-pattern 2 — "The security team owns compliance"

Untrue. Compliance in the sense of *audit response* and *regulator
communication* is owned by the head-of-governance (level 60) and by
Legal. This role owns the *engineering artifacts* the audit consumes.

The distinction matters because when an auditor asks "who owns
Article 15?" the answer is "the head-of-governance's team owns the
audit response; this role produces the engineering evidence Article
15 references."

---

## The role's day-to-day in practice

Ordered roughly by proportion of week:

- Design reviews on new ML/LLM systems, producing threat models and
  admission-time control specifications.
- Authoring and reviewing policy-as-code (OPA / Rego) for admission
  gates.
- Authoring and tuning detection content and IR playbooks.
- Cross-team enablement — bringing ML engineers, agent developers,
  and product teams up the security curve.
- Vendor risk assessment for ML tooling, model hubs, and managed
  services.
- Incident response for AI-specific events.
- Program-slice work — control-library maintenance, quarterly
  reviews with adjacent roles, metrics package to head-of-governance.
- Supporting `ai-evaluation-engineer` peer and the head-of-governance
  on regulator-adjacent requests.

You are *not* primarily writing CUDA kernels. You are *not*
primarily training models. You *are* writing prose, policy, and glue
code, and the prose matters more than the code.

---

## Summary

- The role is a level-35 hands-on engineering specialist in the AI
  Governance family, sitting between `ai-risk-engineer` (level 25)
  and `agentic-safety-engineer` (level 40), with `ai-evaluation-
  engineer` as the level-35 peer.
- The role owns the security-engineering craft end-to-end — threat
  model, platform hardening, adversarial defence, supply chain,
  privacy engineering, detection, IR, control-library security
  section.
- The role defers up (level 40 red-team research, level 50 library
  architecture, level 60 program leadership), sideways (peer
  release-assurance, level 25 harm modelling), and down (level 15
  crosswalk legwork, general infra prerequisites) — with a written
  contract for every boundary.
- The signed deferral contract is Exercise 05's deliverable and the
  mod-112 maintenance artifact.
