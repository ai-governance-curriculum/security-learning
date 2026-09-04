# mod-106-adversarial-ml-defense: Adversarial ML Defence at Platform Scale — Evasion, Poisoning, Extraction, Inference, Backdoors

**Estimated effort:** 18 hours

Adversarial ML is the point where "the service is secure" and "the
model is secure" stop being the same statement. This module installs
the vocabulary, the defences, and the platform integrations that let
a security engineer answer *which* adversarial-ML attack family a
proposed control covers, *and* the ones it does not.

The module is written against the taxonomy in **NIST AI 100-2** and
the **OWASP Machine Learning Security Top 10**. It carries a running
requirement to build every defence as a platform service — a config
on the standard training or serving job, not a bespoke research
notebook — so that the controls survive real workload volume, real
retraining cadences, and real on-call rotations.

Covers requirement theme **req-06**.

---

## Learning objectives

- Working command of the adversarial-ML attack families in NIST AI
  100-2 and OWASP ML Top 10: evasion, data poisoning, model
  extraction, membership / attribute inference, backdoor / trojan
  attacks.
- Design an adversarial-training pipeline (PGD, TRADES) that runs as
  part of the standard training platform, not as a bespoke research
  exercise.
- Configure certified defences (randomised smoothing) for classifiers
  where robustness certificates are required.
- Wire in-serving attack-detection monitors — high query-similarity
  extraction detection, membership-inference risk monitoring,
  poisoning-during-continual-learning canaries.
- Configure DP-SGD end to end using Opacus for a training run that
  must ship with a differential-privacy budget.

---

## Lecture chapters

1. [Chapter 01 — The Adversarial-ML Attack Landscape](./01-adversarial-ml-attack-landscape.md).
   Installs the taxonomy (NIST AI 100-2 + OWASP ML Top 10), the
   five attack families, the training-time / inference-time seam,
   and the white-box / grey-box / black-box access model.
2. [Chapter 02 — Adversarial Training as a Platform Service](./02-adversarial-training-pipeline.md).
   PGD-AT and TRADES on the standard training job; robust-accuracy
   evaluation under AutoAttack; cost budgeting; the failure modes
   that trip up first-time deployments.
3. [Chapter 03 — Certified Robustness with Randomised Smoothing](./03-certified-robustness-randomised-smoothing.md).
   Empirical vs certified robustness; the Cohen et al. construction;
   Train / Predict / Certify; the accuracy-vs-radius curve as the
   reportable artefact.
4. [Chapter 04 — Poisoning and Backdoor Detection](./04-poisoning-and-backdoor-detection.md).
   Spectral-signature detection, activation clustering, Neural
   Cleanse, STRIP, and canaries for continual-learning pipelines.
   Layered composition with mod-104 provenance and mod-110 supply-
   chain gates.
5. [Chapter 05 — Serving-Layer Attack Detection](./05-serving-layer-attack-detection.md).
   Telemetry surface; extraction detectors (per-identity drift,
   PRADA, boundary-proximity); membership-inference risk metric;
   rate limits, output perturbation, and watermarking as response
   controls.
6. [Chapter 06 — DP-SGD End to End with Opacus](./06-dp-sgd-with-opacus.md).
   The `(ε, δ)` guarantee, Opacus wiring, accountant choice,
   hyperparameter sizing, model-card reporting, and the compatibility
   gotchas (`BatchNorm`, DDP, per-sample gradients).

---

## Exercises

Every exercise anchors on a specific chapter. Complete them in order;
each depends on the artefacts of the previous.

1. [Exercise 01 — Robustness baseline assessment with ART](./exercises/exercise-01-robustness-baseline-assessment-with-art.md).
   Ship an ART-based robustness baseline for one target model:
   AutoAttack + selected auxiliaries, threat-model artefact from
   chapter 01, robust-accuracy scorecard.
2. [Exercise 02 — Adversarial training pipeline plan](./exercises/exercise-02-adversarial-training-pipeline-plan.md).
   Design memo + config schema for wiring PGD/TRADES into the target
   training platform, with cost budget and evaluation harness.
3. [Exercise 03 — Poisoning detection with spectral signatures](./exercises/exercise-03-poisoning-detection-with-spectral-signatures.md).
   Implement spectral-signature + activation-clustering detection on
   a deliberately-poisoned training set; produce the flagged-index
   report and the retraining delta.
4. [Exercise 04 — Extraction and inference detection monitors](./exercises/exercise-04-extraction-and-inference-detection-monitors.md).
   Instrument the serving layer with fingerprints and identity;
   implement a PRADA-style extraction detector and a membership-
   inference risk metric.
5. [Exercise 05 — DP-SGD configuration with Opacus](./exercises/exercise-05-dp-sgd-configuration-with-opacus.md).
   Configure Opacus for a bounded `(ε, δ)` training run;
   produce the model-card privacy section with a utility-gap
   analysis.

---

## Directory layout

- `01-…md` … `06-…md` — lecture chapters (this module).
- `exercises/` — per-exercise prompts. Solutions live in the paired
  solutions repo.
- `labs/` — long-form hands-on labs (scaffolded).
- `quizzes/` — knowledge checks (scaffolded).
- `resources.md` — curated primary-source reading list; standards,
  papers, tools, and cross-references.

---

## Cross-references within this curriculum

- [mod-102](../mod-102-threat-modelling-for-ai-ml-systems/) — the
  threat-model scaffolding this module's attack-family artefact
  plugs into.
- [mod-103](../mod-103-secure-ml-platform-architecture/) — the
  identity, tenancy, admission-gate, and mesh primitives that the
  serving-layer detectors in chapter 05 depend on.
- [mod-104](../mod-104-data-and-model-lineage-security/) —
  provenance and signed lineage that the poisoning-defence
  composition in chapter 04 relies on; the model-card evidence
  surface every chapter here writes to.
- [mod-105](../mod-105-secrets-and-key-management/) — per-caller
  API-key management and the incident runbook that a confirmed
  extraction incident triggers.
- [mod-107](../mod-107-llm-agent-security/) — LLM prompt-injection,
  jailbreak, and prompt-based training-data-extraction attacks;
  a superset of the evasion family for generative models.
- [mod-108](../mod-108-privacy-engineering-for-ml/) — the broader
  privacy programme this module's DP-SGD chapter connects into.
- [mod-109](../mod-109-ai-governance-and-compliance-engineering/) —
  consumes the model-card evidence (robustness numbers, privacy
  budget, MI-AUC) written by every exercise here.
- [mod-110](../mod-110-supply-chain-security-for-ai/) — base-model
  provenance and imported-artefact scanning that closes the
  backdoored-base-model surface chapter 04 names.
- [mod-111](../mod-111-security-operations-and-incident-response-for-ml/) —
  the event bus that consumes canary alerts, extraction alerts,
  and MI-AUC regressions and drives the on-call response.
