# mod-108-privacy-engineering-for-ml: Privacy Engineering for ML — Differential Privacy, PETs, Inference-Attack Mitigation, PII/PHI Controls

**Estimated effort:** 14 hours

Privacy is where "the model is secure" and "we can defend the
model in front of a regulator" stop being the same statement.
A model that ships without a stated privacy posture is a model
someone else — the regulator, the customer's counsel, the local
supervisory authority — will characterise for you. This module
installs the vocabulary, the engineering artefacts, and the
platform integrations that let a security engineer answer, per
control, what privacy claim the org is making and how it is
proved.

The module is written against **GDPR** (Regulation (EU)
2016/679), the **HIPAA Security Rule** (45 CFR Part 164
Subpart C), the **NIST Privacy Framework**, and the primary
literature on **differential privacy** and **membership /
attribute inference**. It carries a running requirement to make
every privacy control a *platform* primitive — a DLP scanner on
the training-data ingest, a budget policy on the training
platform, a DPIA template in the design-review workflow — so the
claims survive real workloads, real audits, and real subject-
access requests.

Covers requirement theme **req-08**.

---

## Learning objectives

- Configure DP-SGD (Opacus) for a training run, choosing an
  appropriate `(ε, δ)` budget and justifying the trade-off
  against utility.
- Mitigate membership and attribute inference attacks in a
  deployed model — architectural controls (per-user rate
  limits, output aggregation), training-time controls (DP),
  and monitoring.
- Wire PII/PHI DLP into the training-data pipeline and into
  prompt logging (Presidio or equivalent).
- Translate GDPR Articles 22 (automated decisions), 25 (data
  protection by design and by default), and 35 (data protection
  impact assessment) into concrete engineering artifacts — a
  right-to-explanation view, a DP-by-design ADR, a DPIA
  template.
- Translate HIPAA Security Rule administrative / physical /
  technical safeguards into ML-platform-specific controls.

---

## Lecture chapters

1. [Chapter 01 — Choosing the DP-SGD Budget](./01-choosing-the-dp-sgd-budget.md).
   The `(ε, δ)` decision framework: what the record is, what
   the budget claims and does not claim, the org's tier map
   from data class to budget, the utility-negotiation
   conversation, the composition and hyperparameter costs, the
   review-board sign-off artefact. The complement to
   mod-106 chapter 06's Opacus wiring recipe — that chapter
   configures; this chapter *chooses*.
2. [Chapter 02 — Inference-Attack Mitigation for Deployed Models](./02-inference-attack-mitigation.md).
   The membership- and attribute-inference threat models under
   API and text-generation access; the three-layer defence —
   training-time (DP), architectural (rate limits, output
   aggregation, confidence hiding, per-caller identity), and
   monitoring (MI-AUC and TPR-at-low-FPR as continuous SLOs);
   the review checklist an ML deployment passes before it takes
   production traffic on regulated data.
3. [Chapter 03 — PII/PHI DLP in Training and Prompt Logging](./03-pii-phi-dlp-in-training-and-prompt-logging.md).
   Where DLP sits in the training-data path (ingest, feature
   store, pre-batch, sample audit) and in the runtime path
   (input scrub, prompt-log redaction, retrieval-store scrub);
   Presidio as the reference recogniser stack; recognition
   quality metrics (recall, precision, per-entity F1) and how
   to tune them without silently degrading either; irreversible
   vs recoverable redaction; the audit surface that proves the
   scrub happened.
4. [Chapter 04 — GDPR Articles 22, 25, and 35 as Engineering Artefacts](./04-gdpr-art-22-25-35-as-artefacts.md).
   Turning three legal articles into three engineering
   deliverables: a **right-to-explanation view** that satisfies
   Article 22's "meaningful information about the logic
   involved"; a **DP-by-design ADR** that discharges Article
   25's proactive-controls obligation; a **DPIA template**
   tailored to ML systems that Article 35 requires whenever
   the processing is likely to result in high risk. The
   chapter is not legal advice — it is the mapping from what
   the article says to what the platform has to ship for legal
   to sign it off.
5. [Chapter 05 — HIPAA Security Rule as ML Platform Controls](./05-hipaa-security-rule-as-ml-controls.md).
   The Security Rule (45 CFR §§ 164.302–318) is three
   safeguard families — administrative, physical, technical.
   This chapter maps each required and addressable standard to
   the concrete ML-platform control that satisfies it,
   distinguishes "PHI in training data" from "PHI at
   inference" from "PHI in prompt / trajectory logs", and
   names the artefacts a HIPAA covered-entity or business-
   associate ML programme owes an auditor.

---

## Exercises

Every exercise anchors on a specific chapter. Complete them in
order; each depends on the artefacts of the previous.

1. [Exercise 01 — DP-SGD budget selection worked example](./exercises/exercise-01-dp-sgd-budget-selection-worked-example.md).
   Choose the `(ε, δ)` for one concrete training use case;
   argue the choice against chapter 01's tier map; produce the
   privacy-review-board decision packet.
2. [Exercise 02 — Inference-attack mitigation plan](./exercises/exercise-02-inference-attack-mitigation-plan.md).
   Author the three-layer mitigation plan for one deployed
   model on regulated data; instrument the MI-AUC monitor;
   produce the deployment-review sign-off.
3. [Exercise 03 — PII/PHI DLP in the training pipeline](./exercises/exercise-03-pii-phi-dlp-in-training-pipeline.md).
   Wire Presidio (or equivalent) into a training-data ingest
   *and* a prompt-log pipeline; measure per-entity recall on
   a labelled evaluation set; produce the DLP-coverage
   evidence artefact.
4. [Exercise 04 — GDPR Art. 22/25/35 to engineering artefacts](./exercises/exercise-04-gdpr-art-22-25-35-to-engineering-artifacts.md).
   Produce the three artefacts — right-to-explanation view,
   DP-by-design ADR, DPIA — for one target product; walk them
   through a rehearsal review with legal.
5. [Exercise 05 — HIPAA Security Rule to ML controls](./exercises/exercise-05-hipaa-security-rule-to-ml-controls.md).
   Produce the HIPAA Security Rule control-mapping matrix for
   one PHI-using ML system; identify the gaps; produce the
   remediation plan.

---

## Directory layout

- `01-…md` … `05-…md` — lecture chapters (this module).
- `exercises/` — per-exercise prompts. Solutions live in the
  paired solutions repo.
- `labs/` — long-form hands-on labs (scaffolded).
- `quizzes/` — knowledge checks (scaffolded).
- `resources.md` — curated primary-source reading list;
  standards, papers, tools, and cross-references.

---

## Cross-references within this curriculum

- [mod-102](../mod-102-threat-modelling-for-ai-ml-systems/) —
  the threat-model scaffolding this module's privacy-focused
  attacker profiles plug into.
- [mod-103](../mod-103-secure-ml-platform-architecture/) —
  the workload identity, tenancy, and admission-gate
  primitives the chapter-02 per-caller controls and the
  chapter-05 HIPAA access controls depend on.
- [mod-104](../mod-104-data-and-model-lineage-security/) —
  the model / system card evidence surface every chapter
  writes to (privacy budget, DLP coverage, DPIA reference,
  HIPAA control map).
- [mod-105](../mod-105-secrets-and-key-management/) —
  the KMS behind PHI encryption (chapter 05) and the
  identity-revocation primitive incident response uses.
- [mod-106](../mod-106-adversarial-ml-defense/) — chapter 05
  (serving-layer detection) and chapter 06 (DP-SGD with
  Opacus) sit on the technical stack this module governs;
  mod-106 configures, mod-108 sets budget and reviews.
- [mod-107](../mod-107-llm-agent-security/) — the prompt-log
  pipeline chapter 03 writes to; the trajectory-preservation
  surface HIPAA logging obligations attach to; LLM-specific
  memorisation and training-data-extraction risk feeds
  chapter 02's threat model.
- [mod-109](../mod-109-ai-governance-and-compliance-engineering/) —
  the governance-evidence surface every artefact in this
  module (privacy budget, DPIA, HIPAA matrix, DLP coverage)
  lands in.
- [mod-110](../mod-110-supply-chain-security-for-ai/) —
  the imported-model and imported-dataset provenance whose
  privacy claims (or lack of) feed the DPIA and the tier map.
- [mod-111](../mod-111-security-operations-and-incident-response-for-ml/) —
  the privacy-incident response surface (breach clocks, DSAR
  handling, HIPAA breach notification) this module's controls
  feed.
- [mod-112](../mod-112-program-leadership-for-ml-security-governance/) —
  the programme-level ownership of the privacy budget policy,
  the DPIA cadence, and the HIPAA compliance posture.
