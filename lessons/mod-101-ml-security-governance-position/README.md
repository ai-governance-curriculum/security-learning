# mod-101 — AI/ML Security & Governance Engineer: Frameworks, Position on the Ladder, and Working Vocabulary

**Estimated effort:** 12 hours
**Track:** AI/ML Security & Governance Engineer (`security`, level 35)
**Family:** AI Governance
**Requirement themes covered:** req-01 (fluent working command of the
four operative ML/LLM security taxonomies) and req-12 (cross-functional
leadership of the ML security & governance slice — baseline framing).

---

## What this module is for

This is the ladder-position and working-vocabulary module for the
AI/ML Security & Governance Engineer. It installs the reflex-fast
fluency the rest of the track builds on:

- OWASP ML Top 10 and OWASP LLM Top 10 v2025 read *as an engineer* —
  each risk mapped to a preventive control, a detective control, an
  evidence artifact, and an owner.
- MITRE ATLAS read as the *TTP catalogue* your SIEM detection content
  and IR playbooks map to.
- NIST AI 100-2 read as the *working vocabulary* for attacker goals,
  capabilities, and knowledge — so threat models, red-team reports,
  and control specifications say the same thing.
- NIST AI RMF, ISO/IEC 42001, and EU AI Act Articles 9–15 read as
  *engineering deliverables* — every obligation resolves to an
  artifact and an enforcement mechanism, not a policy quotation.
- Your exact scope on the level ladder, expressed as a signed
  **deferral contract** against `ai-risk-engineer` (level 25),
  `ai-evaluation-engineer` (peer, level 35), `agentic-safety-engineer`
  (level 40), `senior-ai-governance-architect` (level 50), and
  `head-of-ai-governance` (level 60).

By the end of the module you should be able to walk into any ML/LLM
design review or release gate at your organisation with the mental
map required to say *precisely* what you own, what you defer, what
you produce, and what artifacts an auditor should be handed.

## How to work through this module

1. Read the five lecture chapters in order — each is focused and
   short.
2. Complete the five exercises in [`exercises/`](./exercises/) in
   order. Exercise 01 seeds a coverage matrix that Exercises 02–04
   extend, and Exercise 05 formalises the boundary work the whole
   track will maintain.
3. Use [`resources.md`](./resources.md) as your primary-source
   reference list. Every framework and standard cited in the
   chapters is linked there.
4. Move to `mod-102-threat-modelling-for-ai-ml-systems` when you
   can produce the module's deliverables on demand from a blank
   page.

## Lecture chapters

- [01 — OWASP ML Top 10 and OWASP LLM Top 10 v2025 for engineers](./01-owasp-ml-and-llm-top-10-for-engineers.md)
- [02 — MITRE ATLAS as the living TTP catalogue](./02-mitre-atlas-ttp-catalogue.md)
- [03 — NIST AI 100-2 as the working adversarial-ML vocabulary](./03-nist-ai-100-2-adversarial-ml-taxonomy.md)
- [04 — Governance frameworks as security-engineering deliverables](./04-governance-frameworks-to-security-engineering-deliverables.md)
- [05 — Role scope and deferral contract on the level ladder](./05-role-scope-and-deferral-contract.md)

## Exercises

- [Exercise 01 — OWASP ML and LLM Top 10 to control map](./exercises/exercise-01-owasp-ml-and-llm-top-10-to-control-map.md)
- [Exercise 02 — MITRE ATLAS TTP tour and detection map](./exercises/exercise-02-mitre-atlas-ttp-tour-and-detection-map.md)
- [Exercise 03 — NIST AI 100-2 attack taxonomy as working vocabulary](./exercises/exercise-03-nist-ai-100-2-attack-taxonomy-to-vocabulary.md)
- [Exercise 04 — Governance obligation to security-engineering deliverable](./exercises/exercise-04-governance-obligation-to-security-engineering-deliverable.md)
- [Exercise 05 — Role scope and deferral contract](./exercises/exercise-05-role-scope-and-deferral-contract.md)

## Module deliverables

The artifacts you leave the module with — each carried forward into
later modules:

- The **coverage matrix** across OWASP ML + LLM v2025 for the fintech
  reference system (Ex. 01), extended in mod-102 threat modelling.
- The **ATLAS technique coverage register** and detection-content
  stubs (Ex. 02), extended in mod-111 SecOps and IR.
- Five **NIST-vocabulary threat-model rows** and the unified control
  specification (Ex. 03), extended in mod-102 and mod-106.
- The **governance-to-engineering crosswalk** and enforcement stubs
  (Ex. 04), extended in mod-109 and mod-112.
- The **signed deferral contract** (Ex. 05), maintained by mod-112.

## Where this module sits in the track

| Module | Where mod-101 shows up |
| --- | --- |
| mod-102 Threat Modelling | The coverage matrix and NIST-vocabulary rows are the input; the module produces the STRIDE + ATLAS threat model. |
| mod-103 Secure ML Platform Architecture | The Article 15 cybersecurity obligation lands as concrete zero-trust primitives. |
| mod-104 Data and Model Lineage Security | The Article 12 record-keeping obligation lands as the immutable audit-log architecture. |
| mod-105 Secrets and Key Management | The ML05 / ML09 controls and Article 15 cybersecurity artifacts wire into Vault, KMS, keyless CI. |
| mod-106 Adversarial ML Defence | ML01, ML02, ML03, ML04 and NIST 100-2 evasion / poisoning / privacy families become the pipeline. |
| mod-107 LLM and Agent Security | LLM01–LLM10:2025 become the module content; ATLAS detection content drops in. |
| mod-108 Privacy Engineering for ML | ML03 / ML04, GDPR / HIPAA translations become DP-SGD, PII/PHI DLP. |
| mod-109 AI Governance and Compliance | The chapter-04 crosswalk becomes the module. |
| mod-110 AI Supply Chain Security | ML06 / LLM03 controls become SLSA, cosign, ML-BOM, ModelScan. |
| mod-111 SecOps and IR for ML | The ATLAS register (Ex. 02) becomes the detection library. |
| mod-112 Program Leadership | The deferral contract (Ex. 05) becomes the maintenance artifact; the metrics package feeds board reporting. |

## Notes on primary sources

Every framework identifier, version, article number, and clause label
in these chapters must be verified against the primary source before
being quoted externally. Where a claim cannot be verified in the
current authoring session, the chapter contains a
`<!-- needs-research: ... -->` marker rather than a guess. Do not
publish this module content externally until every marker has been
either resolved to a primary-source citation or removed with an
explicit note.
