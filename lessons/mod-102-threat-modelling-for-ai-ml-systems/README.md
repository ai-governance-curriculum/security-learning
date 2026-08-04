# mod-102 — Threat Modelling for AI/ML Systems: Assets, TTPs, Attack Trees, Mitigation Priorities

**Estimated effort:** 14 hours
**Track:** AI/ML Security & Governance Engineer (`security`, level 35)
**Family:** AI Governance
**Requirement themes covered:** req-02 (produce STRIDE-shaped threat
models for ML/LLM systems that name the ML-specific asset classes,
map to MITRE ATLAS TTPs and NIST AI 100-2 attack families, trace top
threats as attack trees, and defend a prioritised mitigation
roadmap).

---

## What this module is for

Mod-101 installed the vocabulary — OWASP ML and LLM Top 10, MITRE
ATLAS TTPs, NIST AI 100-2 attack families, the governance overlay,
and the deferral contract for your role. Mod-102 installs the
**working method** that vocabulary supports: threat modelling of an
AI/ML system, end to end, producing artifacts that a design review,
an incident-response function, and a release gate all consume.

You leave this module able to:

- Produce an **ML asset inventory** that names the five ML-specific
  asset classes as first-class citizens on the data-flow diagram:
  training data, model artifact, decision surface, prompt/tool
  graph, embedding index.
- Author an **ML-adapted STRIDE** table — STRIDE-per-element applied
  to each ML asset, extended with the ML-native threats classical
  STRIDE has no letter for.
- Map every identified threat to **MITRE ATLAS techniques** and to
  **NIST AI 100-2 attack families**, producing an **IR-consumable
  inventory** the mod-111 SecOps slice reads as detection input.
- Draw an **attack tree** for the top three threats — from initial
  access through the kill chain to impact — with cost-to-attacker
  and detection-interdict points annotated.
- Produce a **mitigation prioritisation scorecard** ranking each
  candidate mitigation by cost, coverage of attack-tree paths, and
  detectability, resolving to a defensible sequenced roadmap.

By the end of the module, when a product team hands you an ML system
diagram, you should be able to walk out — in a fixed time budget —
with a threat model, a TTP-tagged threat inventory, three attack
trees, and a mitigation roadmap that stands up to review.

## How to work through this module

1. Read the six lecture chapters in order — each builds on the prior
   one's artifact.
2. Complete the five exercises in [`exercises/`](./exercises/) in
   order. The output of exercise 01 (the asset inventory) is the
   input to exercise 02 (STRIDE), whose output is the input to
   exercise 03 (ATLAS + NIST mapping), and so on. You are building
   one complete threat model.
3. Use [`resources.md`](./resources.md) as the primary-source
   reference list. Every framework, standard, and methodology cited
   in the chapters is linked there.
4. Move to `mod-103-secure-ml-platform-architecture` when you can
   produce the module's four deliverables (asset inventory,
   STRIDE-per-element table, TTP-mapped threat inventory, attack
   trees, mitigation scorecard) from a blank page in under an
   engineering week for a system you have never seen before.

## Lecture chapters

- [01 — Why threat modelling for ML needs new assets](./01-why-threat-modelling-for-ml-needs-new-assets.md)
- [02 — The ML asset inventory: five first-class asset classes](./02-ml-asset-inventory-five-first-class-asset-classes.md)
- [03 — ML-adapted STRIDE: STRIDE-per-element for ML assets](./03-ml-adapted-stride-per-element.md)
- [04 — Mapping threats to ATLAS TTPs and NIST AI 100-2](./04-mapping-threats-to-atlas-ttps-and-nist-ai-100-2.md)
- [05 — Attack trees for the top three threats](./05-attack-trees-for-top-three-threats.md)
- [06 — Mitigation prioritisation: cost, coverage, detectability](./06-mitigation-prioritisation-cost-coverage-detectability.md)

## Exercises

- [Exercise 01 — ML asset inventory and classification](./exercises/exercise-01-ml-asset-inventory-and-classification.md)
- [Exercise 02 — STRIDE for ML worked example](./exercises/exercise-02-stride-for-ml-worked-example.md)
- [Exercise 03 — ATLAS TTP mapping for one system](./exercises/exercise-03-atlas-ttp-mapping-for-one-system.md)
- [Exercise 04 — Attack tree for top three threats](./exercises/exercise-04-attack-tree-for-top-three-threats.md)
- [Exercise 05 — Mitigation prioritisation scorecard](./exercises/exercise-05-mitigation-prioritisation-scorecard.md)

## Module deliverables

The artifacts you leave the module with — every one carried forward
into later modules:

- The **ML asset inventory and classification** (Ex. 01), used by
  mod-103 (zero-trust architecture), mod-104 (data + model lineage),
  mod-108 (privacy engineering).
- The **STRIDE-per-element table** (Ex. 02), used by mod-103 for the
  authorisation surface and by mod-107 for the LLM-specific threats.
- The **ATLAS + NIST-mapped threat inventory** (Ex. 03), consumed
  directly by mod-111 (SecOps + IR) as the detection-content backlog.
- The **attack trees for top three threats** (Ex. 04), reused by
  mod-106 (adversarial defence) and mod-111 (tabletop drills).
- The **mitigation prioritisation scorecard** (Ex. 05), fed into the
  program-leadership roadmap that mod-112 maintains.

## Where this module sits in the track

| Module | Where mod-102 shows up |
| --- | --- |
| mod-103 Secure ML Platform Architecture | The STRIDE table + asset inventory become the authorisation surface and the zero-trust boundaries. |
| mod-104 Data and Model Lineage Security | Training-data and model-artifact rows drive the lineage graph requirements. |
| mod-105 Secrets and Key Management | Model-signing / dataset-signing / decision-signing keys are named from the asset inventory. |
| mod-106 Adversarial ML Defence | The evasion and poisoning threats in the STRIDE table become the training-pipeline hardening backlog. |
| mod-107 LLM and Agent Security | The prompt/tool-graph asset and the LLM-specific STRIDE rows become the module content. |
| mod-108 Privacy Engineering for ML | Training-data threats drive the DP-SGD / DLP / redaction requirements. |
| mod-110 Supply Chain Security for AI | ML06 / LLM03 threats in the STRIDE table set the SBOM + provenance backlog. |
| mod-111 SecOps and IR for ML | The ATLAS-tagged threat inventory (Ex. 03) becomes the detection backlog. |
| mod-112 Program Leadership | The mitigation scorecard (Ex. 05) becomes the board-visible roadmap. |

## Notes on primary sources

Every framework identifier, technique ID, article number, and
methodology name in these chapters must be verified against the
primary source before being quoted externally. Where a claim cannot
be verified in the current authoring session, the chapter contains a
`<!-- needs-research: ... -->` marker rather than a guess. Do not
publish this module content externally until every marker has been
resolved to a primary-source citation or removed with an explicit
note.
