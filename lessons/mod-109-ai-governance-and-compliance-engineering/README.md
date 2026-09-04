# mod-109-ai-governance-and-compliance-engineering: AI Governance and Compliance Engineering — Frameworks to Enforceable Controls, Policy-as-Code, Evidence

**Estimated effort:** 16 hours

Governance-as-checklist is the failure mode this module is
written against. A stack of policies, a slide deck of
"frameworks adopted", and a spreadsheet of controls that
nobody enforces do not survive an EU AI Act audit, an ISO
42001 stage-2 audit, a SOC 2 Type II readiness review, an
SR 11-7 examination, an FDA pre-submission meeting, or a
HIPAA breach investigation. What survives is a **single
control library** with per-regime cross-references,
**executable admission gates** that produce evidence as a
by-product of normal engineering work, and **deployment-tier
gating** that steps up when a system's capability
materially changes.

This module builds that library. It walks the NIST AI RMF as
the vocabulary; the ISO/IEC 42001 AIMS as the certifiable
management-system shell; the EU AI Act's high-risk-system
Articles as engineering artefacts; policy-as-code (OPA/Rego)
as the enforcement layer; SOC 2, SR 11-7, FDA GMLP/PCCP, and
HIPAA as the sector-specific overlays; and the frontier-lab
Responsible Scaling / Preparedness / Frontier Safety patterns
as the enterprise deployment-tier discipline. Each chapter
produces a concrete artefact and a mapping row for the
unified control matrix.

Covers requirement theme **req-09**.

---

## Learning objectives

- Translate NIST AI RMF (GOVERN / MAP / MEASURE / MANAGE)
  sub-categories into concrete security-engineering controls
  and evidence artefacts.
- Map ISO/IEC 42001 AIMS clauses (Clauses 4–10 + Annex A)
  onto the security-engineering deliverables that satisfy
  each clause, and produce the Statement of Applicability.
- Translate EU AI Act Articles 9 (risk management), 10
  (data governance), 14 (human oversight), 15 (accuracy /
  robustness / cybersecurity), and 72 (post-market
  monitoring) — plus the neighbours Article 11/Annex IV,
  Article 12, Article 17, Article 27 FRIA, and Article 73
  serious-incident reporting — into engineering artefacts a
  high-risk system must ship with.
- Author policy-as-code (OPA/Rego) that encodes control
  obligations as enforceable admission gates at the four
  ML platform chokepoints (CI, training-job submission,
  model-registry promotion, runtime serving).
- Map SOC 2 Trust Services Criteria and sector regs (SR 11-7
  for banking model risk management, FDA GMLP / PCCP for
  medical device software, HIPAA for health) onto the same
  control library.
- Understand how frontier-lab deployment-tier gating
  (Anthropic RSP, OpenAI Preparedness Framework, DeepMind
  FSF) is adapted for enterprise deployment tiers — capability
  characterisation, tier-specific evaluations, safety cases.

---

## Lecture chapters

1. [Chapter 01 — NIST AI RMF Sub-Categories to Security
   Controls](./01-nist-ai-rmf-to-controls.md).
   The GOVERN / MAP / MEASURE / MANAGE functions and the
   Generative AI Profile (NIST AI 600-1) delta. Every sub-
   category as a triple: **outcome, control, evidence**. The
   unified control-mapping matrix schema that chapters 02–06
   extend. Adoption as a scaled claim (read → mapped →
   evidenced → enforced → audited), not a checkbox.
2. [Chapter 02 — ISO/IEC 42001 Clauses to Security-Engineering
   Deliverables](./02-iso-42001-clause-to-deliverable.md).
   Clauses 4–10 walked with the auditable deliverable per
   clause; Annex A structure; the **Statement of Applicability**
   template; certification path (stage 1, stage 2,
   surveillance, re-certification); integration with a
   parent 27001 AIMS.
3. [Chapter 03 — EU AI Act Articles 9, 10, 14, 15, and 72
   as Engineering Artefacts](./03-eu-ai-act-articles-to-artefacts.md).
   Classification first (prohibited / high-risk / limited /
   minimal / GPAI). The seven core high-risk artefacts —
   risk-management file, data-governance dossier, Annex IV
   technical documentation, logging spec, human-oversight
   design record, accuracy/robustness/cybersecurity report,
   post-market monitoring plan — plus Article 27 FRIA and
   Article 73 serious-incident-reporting hook. Timeline the
   artefacts have to survive.
4. [Chapter 04 — Policy-as-Code with OPA/Rego for ML
   Admission Gates](./04-policy-as-code-with-opa-rego.md).
   The four chokepoints (CI, training-job submission,
   model-registry promotion, runtime serving). Input
   contract; policy authoring; policy tests; policy packs;
   decisions as first-class evidence; exception paths;
   break-glass; policy hygiene (one control per file, data
   loaded not hard-coded, remediation on every rule).
5. [Chapter 05 — SOC 2 Trust Services Criteria and Sector
   Regulations (SR 11-7, FDA GMLP/PCCP, HIPAA)](./05-soc2-and-sector-regs.md).
   SOC 2 Common Criteria as they apply to ML platforms; SR
   11-7's three pillars translated into model-inventory,
   validation, and effective-challenge disciplines; FDA GMLP
   ten principles + PCCP as engineering deliverables;
   HIPAA Security Rule §§ 164.308–.312 mapped onto ML
   controls. All four regimes cross-referenced from the
   unified matrix.
6. [Chapter 06 — Frontier-Lab Deployment-Tier Gating for
   Enterprise Systems](./06-frontier-rsp-to-enterprise-tiers.md).
   Anthropic RSP, OpenAI Preparedness Framework, DeepMind
   FSF summarised and mined for the shared shape (capability
   categories, tier thresholds, per-tier mitigations,
   review body, if-then commitment). Enterprise Tier 0–5
   taxonomy; per-tier evaluation bundle; safety-case
   pattern; policy-as-code enforcement of tier transitions
   and TTLs.

---

## Exercises

Complete in order; each depends on artefacts from the
previous exercise and from the chapters they cite.

1. [Exercise 01 — NIST AI RMF sub-category to control map](./exercises/exercise-01-nist-ai-rmf-sub-category-to-control-map.md).
   Build the unified matrix v0.1: at least twenty sub-
   categories mapped to outcome/control/evidence triples,
   one system in scope, cross-refs stubbed.
2. [Exercise 02 — ISO/IEC 42001 clause-to-artefact map + SoA](./exercises/exercise-02-iso-42001-clause-to-artifact-map.md).
   Extend the matrix with ISO 42001 columns; produce the
   scope statement, applicability statement, and internal-
   audit-programme skeleton.
3. [Exercise 03 — EU AI Act Article to engineering
   deliverable](./exercises/exercise-03-eu-ai-act-article-to-engineering-deliverable.md).
   Classify one target system; produce the seven high-risk
   artefacts (or the limited-risk equivalents); wire them
   to the matrix.
4. [Exercise 04 — OPA/Rego policy authoring sprint](./exercises/exercise-04-opa-rego-policy-authoring-sprint.md).
   Author a policy pack of ≥ 5 controls with tests; run it
   against a corpus of representative deployment inputs;
   produce a decision-retention design.
5. [Exercise 05 — Sector-reg and RSP adaptation map](./exercises/exercise-05-sector-reg-and-rsp-adaptation-map.md).
   Extend the matrix with SOC 2 + one sector regime (SR
   11-7, FDA GMLP/PCCP, or HIPAA) + enterprise deployment
   tiers adapted from the frontier-lab frameworks.

---

## Directory layout

- `01-…md` … `06-…md` — lecture chapters (this module).
- `exercises/` — per-exercise prompts. Solutions live in
  the paired solutions repo.
- `labs/` — long-form hands-on labs (scaffolded).
- `quizzes/` — knowledge checks (scaffolded).
- `resources.md` — curated primary-source reading list;
  standards, papers, tools, and cross-references.

---

## Cross-references within this curriculum

- [mod-101](../mod-101-ml-security-governance-position/) —
  the ML-security governance function this module operates
  under; role definitions and RACI feed chapter 01's GOVERN
  and chapter 02's Clause 5.
- [mod-102](../mod-102-threat-modelling-for-ai-ml-systems/) —
  the per-system threat models chapter 03's Article 9 risk-
  management file references.
- [mod-103](../mod-103-secure-ml-platform-architecture/) —
  the admission-gate chokepoints (workload identity, mTLS,
  tenant isolation) chapter 04's policies bind to.
- [mod-104](../mod-104-data-and-model-lineage-security/) —
  the model card, dataset provenance, and eval-bundle
  content-addressing that every chapter's evidence artefact
  depends on.
- [mod-105](../mod-105-secrets-and-key-management/) — the
  KMS underpinning HIPAA § 164.312 encryption controls and
  the audit-log integrity chapter 03 Article 12 requires.
- [mod-106](../mod-106-adversarial-ml-defense/) — the
  adversarial-ML controls chapter 03 Article 15 cites and
  chapter 06's tier evaluations rely on.
- [mod-107](../mod-107-llm-agent-security/) — the LLM /
  agent controls chapter 06's Tier 3/4/5 gate on (tool
  ACLs, HITL, indirect-prompt-injection defence).
- [mod-108](../mod-108-privacy-engineering-for-ml/) — the
  privacy artefacts (DP budget, DPIA, HIPAA control map,
  DLP coverage) that flow into chapter 03's Article 10
  data-governance dossier and chapter 05's HIPAA overlay.
- [mod-110](../mod-110-supply-chain-security-for-ai/) — the
  supplier register and per-supplier assessment that
  chapter 01 GV-6.1, chapter 02 Annex A.10, chapter 03
  Article 25, chapter 05 SOC 2 CC9.2, and chapter 06
  supplier-imported-capability all consume.
- [mod-111](../mod-111-security-operations-and-incident-response-for-ml/) —
  the incident-response runbooks chapter 03 Article 73 and
  chapter 05's HIPAA / SOC 2 / SR 11-7 incident branches
  hook into.
- [mod-112](../mod-112-program-leadership-for-ml-security-governance/) —
  the programme-level ownership of the unified matrix, the
  audit calendar, the review boards, and the deployment-
  tier policy.
