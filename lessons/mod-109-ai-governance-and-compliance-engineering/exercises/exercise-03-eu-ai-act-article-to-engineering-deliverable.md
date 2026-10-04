# Exercise 03 — EU AI Act Article to Engineering Deliverable

**Estimated effort:** ~3 hours
**Deliverable:** A **high-risk-system compliance bundle** for
one classified system, consisting of (a) a signed
classification record (prohibited / high-risk / limited /
minimal / GPAI), (b) the seven core high-risk engineering
artefacts — Article 9 risk-management file, Article 10
data-governance dossier, Article 11/Annex IV technical
documentation, Article 12 logging specification, Article 14
human-oversight design record, Article 15
accuracy/robustness/cybersecurity report, Article 72
post-market monitoring plan — or the limited-risk Article 50
equivalents if the system is not high-risk, (c) an Article 27
Fundamental Rights Impact Assessment (FRIA) where applicable,
and (d) the Article 73 serious-incident reporting hook. All of
it wired back into the exercise-01/02 matrix as a new column.
**Prerequisites:** Exercise 01 and 02 complete; matrix has
`cross_refs.eu_ai_act` keys ready to populate. Chapter 03 read
end-to-end. Access to the target system's threat model (mod-102),
model card (mod-104), eval bundle (mod-104/mod-106), and the
mod-108 privacy artefacts.

---

## Objective

Chapter 03's claim is that **the EU AI Act Articles name
specific artefacts; a high-risk system either ships with them
or it does not ship into the EU**. This exercise is the
exercise that produces the artefact set, in the shape
engineering can own.

By the end of this exercise you have:

- A **classification record** that says, with Legal sign-off,
  whether the system is prohibited (Article 5), high-risk
  (Article 6(1)/(2) with Annex I/III citation), limited-risk
  (Article 50), minimal-risk, or GPAI (Articles 51–56).
- The **seven high-risk artefacts** (or the limited-risk
  equivalents) produced to the shape chapter 03 specifies,
  with real content from the exercise-01 system, not
  placeholders.
- A **FRIA** (Article 27) if the system is deployed by a
  public authority or private body providing high-risk AI
  services in enumerated categories, or a signed note that
  Article 27 does not apply and why.
- An **Article 73 serious-incident reporting hook** —
  runbook pointer plus admission-gate check — that the
  mod-111 incident-response practice can route to.
- An **updated matrix** with `cross_refs.eu_ai_act` populated
  for every row the Article walk touches.

You are **not** filing a conformity assessment, registering
the system in the EU database, or seeking a notified-body
assessment. You are shipping the engineering artefacts the
quality-management system (Article 17) and the conformity
assessment (Article 43) will later package.

---

## Problem statement

The target is the exercise-01 system. State before you start:

- The **deployer** role you are writing from. The EU AI Act
  distinguishes **providers** (make the system available on
  the EU market) and **deployers** (operate it within the
  EU). Many enterprise systems are both; the artefacts
  overlap but the duties differ.
- The **placement date / in-service date hypothesis.**
  Article application dates stage through to 2 August 2027;
  your artefacts may need to meet earlier obligations
  (Article 5 prohibitions from 2 February 2025; GPAI
  obligations from 2 August 2025; high-risk from 2 August
  2026 for Annex I; 2 August 2027 for Annex III). Pick a
  hypothesis.
- Whether the system has existing **Annex IV technical
  documentation** (common for CE-marked product companies)
  or needs it drafted from scratch.

If the exercise-01 system is clearly minimal-risk and
non-generative, consider picking a different system for this
exercise so the high-risk artefact walk has substance. Good
candidates — CV screener, credit-decision support, medical
triage, content-moderation tool, fraud scorer that affects
access to essential services. State clearly which system is
being used and why.

---

## Requirements

### Deliverable A — classification record (`governance/ai-act/<system>/classification.md`)

A one-page record stating:

1. **System ID, version, placement hypothesis.** What is
   being classified; when it is intended to go on the
   market or into service.
2. **Classification outcome.** Prohibited / high-risk via
   Article 6(1) (safety component of harmonised product) /
   high-risk via Article 6(2) + Annex III line / limited-
   risk under Article 50 / minimal-risk / GPAI model
   provider.
3. **Reasoning.** For high-risk Article 6(2), cite the
   Annex III line (e.g. "paragraph 4(a) — employment").
   For the Article 6(3) carve-out, state whether considered
   and why it does or does not apply.
4. **GPAI provider angle.** If the system imports a GPAI
   model, name the model and the provider; note which
   Article 53/55 provider duties the enterprise relies on
   via supplier attestation (chapter 06 analogue).
5. **Sign-off.** Legal counsel; ML Governance Lead; date.

The classification outcome drives the artefact set. The rest
of the exercise assumes **high-risk** unless the record says
otherwise; if the record says limited-risk, substitute the
Deliverable I limited-risk track for Deliverables B–H.

### Deliverable B — Article 9 risk-management file

Follow the chapter 03 template. For the target system:

- Enumerate ≥ 10 risks across health, safety, and
  fundamental rights. If you cannot name ten, the risk
  identification is incomplete.
- For each risk, state: intended-use vs foreseeable-misuse
  trigger; inherent risk (likelihood × severity); the
  control(s) applied with matrix-row cross-refs; residual
  risk; accepting authority; next review date.
- Include at least one risk per category: **health/safety**
  (if applicable to the system), **fundamental rights**
  (discrimination; privacy; dignity; access to redress),
  **cybersecurity** (model extraction, poisoning,
  adversarial inputs — bridges to Article 15), and **misuse**
  (how a determined adversary could re-purpose the system).
- Add a **vulnerable-group** section: specific attention to
  children, elderly, people with disabilities, people in
  precarious situations where the system might affect them.
- Add a **testing** sub-section stating how risk-management
  measures are tested (which eval, which cadence).

Commit as YAML or Markdown with embedded YAML, in the
`governance/ai-act/<system>/` folder.

### Deliverable C — Article 10 data-governance dossier

Follow the chapter 03 template. For each of training,
validation, and testing datasets:

- Provenance and consent / lawful basis.
- Volume (count, hashed identifier, snapshot date).
- Population scope — geography, language, demographic
  dimensions where recorded.
- **Representativeness assessment** — a report that compares
  dataset distribution to the target deployment population
  on at least two dimensions. Methodology stated; gaps
  identified; remediation planned.
- Error-and-completeness assessment — known data-quality
  issues and their impact.
- Intended-use alignment — does the geography / language
  scope match the deployment hypothesis.

If the training set contains **special categories of
personal data** (GDPR Article 9(1)) used under Article 10(5)
AI Act for bias detection and correction, add the Article
10(5) sub-section: purpose, categories, pseudonymisation
applied, non-transmission commitment, deletion schedule,
records-of-processing pointer. Cross-reference mod-108
exercise 03 (PII/PHI DLP) and mod-108 exercise 04 (GDPR
Article 25 ADR).

### Deliverable D — Article 11 / Annex IV technical documentation

Annex IV lists the technical documentation a provider must
compile *before* the system is placed on the market and keep
updated. Draft at minimum the top-level structure with the
sections populated for the target system:

1. General description — intended purpose, developer, date,
   version, hardware the system runs on, operating-system
   requirements.
2. Detailed description — development methods, system
   architecture, pretrained models used (supplier, licence,
   version), third-party components, training datasets
   (reference Deliverable C), computational resources.
3. Monitoring, functioning, and control — intended
   trade-offs, metrics of accuracy, robustness, accuracy
   validation.
4. Risk-management description — reference Deliverable B.
5. Changes made to the system through its lifecycle.
6. Harmonised standards applied — ISO/IEC 42001, 23894,
   24028, etc.
7. EU declaration of conformity (template, not signed).
8. Post-market monitoring plan — reference Deliverable H.

Full Annex IV is a book; this deliverable is the **table of
contents with the sections wired to the real artefacts** so
subsequent iteration can backfill. Note any section where
the content is "to be drafted" with an owner and target date.

### Deliverable E — Article 12 logging specification

Article 12 requires high-risk systems to automatically log
events over their lifetime, enabling identification of
situations that may result in risk under Article 79 or
substantial modification, facilitating post-market
monitoring (Article 72), and monitoring operation
(Article 26). Produce `governance/ai-act/<system>/logging-spec.yaml`:

- **Events logged** — inference request (with model version,
  timestamp, caller identity), inference response (with
  confidence / abstention), human-oversight interventions
  (approval, override, abstention), model update deployed,
  tier change (chapter 06).
- **Fields per event** — the minimum set to support Article
  26 oversight: timestamp, system version, model version,
  input hash (not raw input unless policy allows),
  prediction class or output type, confidence, oversight
  decision if any.
- **Retention** — "at least six months unless provided
  otherwise by applicable law" (Article 12(3)); align with
  mod-108 chapter 03 PII handling.
- **Integrity** — append-only; cryptographic chaining /
  signing; cross-reference mod-105 (KMS) for the signing key.
- **Access** — who can read logs (ML Security Lead, auditor,
  DPO for personal-data access); how access is itself
  logged.
- **Admission-gate check** — the Deliverable E of exercise
  04 (OPA policy) that blocks deployment of a serving
  binary that does not emit the required events to the
  configured sink.

### Deliverable F — Article 14 human-oversight design record

Article 14 requires that high-risk systems be designed to be
effectively overseen by natural persons during use. The
deliverable:

- **Oversight model.** State which of Article 14(4)'s
  measures apply — e.g. (a) understanding system capacities;
  (b) remaining aware of automation bias; (c) correctly
  interpreting outputs; (d) decision not to use the output;
  (e) intervention or interruption; (f) stopping via the
  "stop" button.
- **Operational design.** For each applicable measure,
  describe the UI / UX / API feature that implements it.
  Example: for a CV screener, the recruiter sees the
  shortlist and the per-candidate rationale; the "override"
  action is a first-class UI element; the system does not
  make the hiring decision — it informs it.
- **Operator competencies.** The required training,
  qualifications, and ongoing review for the humans in
  the oversight loop; reference GOVERN 3.2 (chapter 01)
  and Clause 7.2 (chapter 02).
- **Monitoring of the oversight loop.** How is "the human
  really is reviewing the output" verified — override rate
  monitored; rubber-stamp detection; time-on-screen metrics
  (where ethically appropriate).
- **Biometric categorisation / remote biometric
  identification** add-on — Article 14(5) requires at
  least two natural persons for post-remote biometric
  identification; include this only if applicable.

Cross-reference mod-107 chapter 03 (HITL patterns) for the
agentic / LLM-specific design patterns.

### Deliverable G — Article 15 accuracy / robustness / cybersecurity report

Article 15 requires high-risk systems to be designed and
developed to achieve, in light of their intended purpose, an
appropriate level of accuracy, robustness, and cybersecurity
and to perform consistently throughout their lifecycle.

Produce `reports/ai-act/<system>/article-15.md` with:

- **Accuracy.** The metrics the system reports (overall;
  per sub-population from the Deliverable C
  representativeness dimensions); the eval dataset (hashed);
  the production threshold; the baseline comparator (prior
  version, non-AI alternative). Declaration of metrics to
  appear in the Article 13 user instructions.
- **Robustness.** Resilience to inputs outside the training
  distribution; resilience to adversarial perturbations
  (mod-106 overlap); feedback-loop controls (self-training
  risks). Report measurement; name eval; name threshold.
- **Cybersecurity.** Resilience to data poisoning, model
  poisoning, model evasion, model-confidentiality attacks
  (extraction / inversion). Reference mod-106 chapters
  02 / 03 / 05 for the specific evals; name the metric and
  the production threshold; name the detection or
  mitigation in place.
- **Consistency over lifecycle.** The regression suite
  that confirms the metrics have not drifted since the
  last release; the production monitoring that would
  alert on in-flight drift.

Every claim links to a specific measurement artefact and a
specific eval version. Numbers without a reproduction recipe
are claims, not reports.

### Deliverable H — Article 72 post-market monitoring plan

Article 72 requires providers of high-risk systems to
establish and document a post-market monitoring system
proportionate to the nature of the technologies and the
risks of the system. Produce
`governance/ai-act/<system>/post-market-monitoring-plan.md`:

- **Objective.** Collect and analyse relevant data on
  performance throughout lifetime; detect substantial
  modifications.
- **Data collected.** The telemetry fed back — accuracy
  monitors; fairness drift; abstention rate; override
  rate; incident / near-miss reports; user feedback
  channels.
- **Analysis cadence.** Who looks at what, when; the
  review-board schedule; the engineering escalation path.
- **Trigger conditions.** When monitoring findings trigger
  a corrective action, a retraining, a tier re-assessment,
  or an Article 73 serious-incident filing.
- **Linkage to Article 73.** Explicit cross-reference to
  the serious-incident reporting hook (Deliverable J).
- **Reference to GPAI model.** If the system uses an
  imported GPAI model, how post-market data flows back to
  the model provider.

### Deliverable I — Article 50 (limited-risk) overlay if applicable

If the classification record (Deliverable A) says the system
is **limited-risk** instead of high-risk, replace B–H with
the Article 50 transparency obligations:

- **AI-interaction notification.** If the system interacts
  with humans, the design ensures humans are informed they
  are interacting with AI.
- **Deepfake / synthetic-content labelling.** If the system
  generates image, audio, or video content constituting a
  deepfake, the output is labelled as AI-generated in a
  machine-readable format where feasible.
- **Emotion / biometric categorisation notice.** If
  applicable, operators inform the natural persons
  exposed.
- **Documentation.** A one-page record documenting the
  transparency design choices and the test confirming
  users see the notice.

The limited-risk overlay is dramatically lighter than the
high-risk set and is deliberately so.

### Deliverable J — Article 73 serious-incident reporting hook

Article 73 requires providers of high-risk systems to report
serious incidents to the market surveillance authority of
the Member State where the incident occurred. Produce:

- A **runbook pointer** that routes an "AI serious incident"
  category from the mod-111 incident-response playbook to
  the EU AI Act reporting flow. Includes decision tree:
  does the incident count as "serious" under Article 3(49)?
- A **data-collection template** so the triage captures the
  facts the Article 73(1) notification needs (identification
  of the system; description of the incident; preliminary
  causal analysis; corrective measures).
- A **timeline awareness** marker: Article 73(2) reporting
  deadlines (immediately upon the provider establishing
  causal link; and no later than 15 days after awareness for
  non-fatal; shorter for serious infrastructure or death
  cases).
- An **admission-gate linkage** — the chapter 04 /
  exercise 04 OPA policy that blocks a release if the
  system's incident runbook does not reference the
  Article 73 hook.

### Deliverable K — Article 27 FRIA (if applicable)

Article 27 requires a Fundamental Rights Impact Assessment
before deployment by a public body, by a private deployer
providing public services, and in specified Annex III
categories (credit-scoring; insurance; employment-related).
Produce `governance/ai-act/<system>/fria.md` with:

- A description of the deployer's processes using the
  system.
- The period of time and frequency of use.
- Categories of natural persons likely to be affected.
- Specific risks of harm to those categories.
- Measures of human oversight (reference Deliverable F).
- Measures to be taken if risks materialise (reference
  Deliverable B R-mitigations).
- Governance arrangements (reference RACI).

If Article 27 does not apply, produce a one-paragraph note
with the reasoning and the Legal sign-off. The note is the
record.

### Deliverable L — matrix extension

Walk the exercise-01/02 matrix and populate
`cross_refs.eu_ai_act` on every row the Article walk
touched. Add new rows where an EU AI Act obligation does not
map to an existing AI RMF or ISO 42001 row (e.g. Article
50 transparency label, if the system is limited-risk; the
EU-database-registration admin task for high-risk systems).

### Deliverable M — placement timeline alignment

A short note stating:

- The in-service / placement date hypothesis from
  Deliverable A.
- The Article application dates relevant to the system.
- Which artefacts in B–L must be in place by which date.
- Which of them are currently `implemented`, `partial`,
  `planned`, or `gap` — the regulatory burn-down.

This is the artefact the engineering leader uses to decide
whether the project ships to the EU on the proposed
timeline.

---

## Starter guidance

- **Classify first; everything downstream depends on it.**
  Legal sign-off on classification before you spend time on
  the Annex IV table of contents.
- **Reuse exercise-01 and -02 artefacts.** The risk-register
  rows become the Article 9 risk-management file lines; the
  Clause 8.3 impact-assessment template (if the exercise-02
  stretch goal was taken) becomes the FRIA shell.
- **For Deliverable C representativeness, do not promise
  what you cannot measure.** If the dataset has no gender
  label (deliberately — GDPR Article 9), say so and
  describe the proxy you can measure (prediction-rate
  parity against a proxy source).
- **For Deliverable G, cross-link to mod-106 evals.** The
  adversarial-robustness and model-confidentiality metrics
  live there; Article 15 is where they get a legally-
  recognised home.
- **For Deliverable K, do not conflate FRIA with GDPR DPIA.**
  They share surface area but their legal bases, triggering
  conditions, and audience differ. Cross-reference, do not
  substitute.
- **For Deliverable J, test the runbook pointer.** A
  reporting hook that nobody has walked through in a
  tabletop is not a hook; it is a wish.

---

## Acceptance criteria

A passing bundle:

- Classification record signed by Legal, cites the specific
  Annex III line (or the Article 6(1) harmonised product
  listing), and names the GPAI dependency if applicable.
- Risk-management file enumerates ≥ 10 risks across the
  categories required; names residual-risk accepting
  authority per risk.
- Data-governance dossier covers training, validation, and
  testing, with representativeness assessed on ≥ 2
  dimensions.
- Annex IV table of contents is present with every section
  pointing to the artefact (or marked "to be drafted" with
  owner and date).
- Logging spec names events, fields, retention, integrity,
  and access control with cross-refs to mod-105 and
  mod-108.
- Human-oversight design record names which Article 14(4)
  measures apply and how they are implemented in the UX /
  API.
- Article 15 report has numbers, named evals, and reproduction
  recipes for accuracy, robustness, and cybersecurity.
- Post-market monitoring plan names the data, the cadence,
  the trigger conditions, and the Article 73 linkage.
- Article 73 serious-incident runbook exists and is linked
  from the mod-111 incident playbook.
- Article 27 FRIA produced if applicable, or a signed
  non-applicability note if not.
- Matrix `cross_refs.eu_ai_act` populated for every row the
  Article walk touched.
- Placement timeline note names what must be ready by when.

A failing bundle:

- Classification without Legal sign-off, or with a
  classification outcome at odds with Annex III.
- Risk-management file that lists only cybersecurity risks
  (no fundamental-rights risks).
- Representativeness assessment that reduces to "the
  training data is big".
- Article 15 "report" with no numbers — "the system is
  robust" is not a report.
- Post-market monitoring plan with no trigger conditions —
  the monitor exists but has no connection to action.
- Article 73 runbook reference that points to a nonexistent
  runbook ID.
- FRIA that is a copy-paste of the DPIA with "GDPR"
  replaced by "AI Act".

---

## Stretch goals

- **CE declaration-of-conformity draft.** The template at
  the end of Annex V, filled with the system's actual
  values. The declaration is what the EU database
  registration (Article 71) references.
- **Harmonised standards walk.** For each ISO or CEN
  harmonised standard that gives presumption of conformity
  with an Article 15 (or Article 9, 10, 13) obligation,
  state whether the organisation adopts it and the
  compliance delta.
- **GPAI supplier-attestation checklist.** If the system
  uses an imported GPAI model, draft the per-provider
  checklist of the Article 53/55 duties the enterprise
  relies on the provider to meet, and the attestation shape
  the enterprise accepts (model card, usage policy,
  copyright policy, training-data summary).
- **Codes-of-conduct linkage.** Article 95 encourages
  voluntary codes for non-high-risk systems. Draft the
  one-page code the org would commit to for its
  limited-risk and minimal-risk portfolio.
- **Member-State divergence note.** Member States can impose
  additional requirements. If the deployment target is a
  specific country, note that country's known divergences
  (e.g. France's CNIL guidance, Germany's BSI advisories).
- **Database-registration dry run.** Walk the Article 71
  EU database registration flow for the system; identify
  what information you would submit, which fields require
  translation, and the designated person responsible for
  the submission.
- **Regulator-engagement log.** Produce the one-page
  template the org uses to track interactions with the AI
  Office or national competent authorities. Zero
  interactions is a reasonable state; zero template is a
  gap.

---

## Do not

- Do not treat this as the compliance bundle for *all*
  jurisdictions. The AI Act is the EU. The UK AI framework,
  the US sectoral regime, and emerging state laws
  (California AB-2273, Colorado AI Act) land in exercise 05
  or in a successor module; do not conflate.
- Do not invent Annex III placements. If the system does
  not fall into Annex III, do not force it there. Many
  systems are minimal-risk; the Act accepts that.
- Do not sign off on classification yourself. Legal signs;
  engineering witnesses.
- Do not take the Article 10(5) special-category permission
  as a general licence. The strict conditions must all be
  satisfied; the records-of-processing obligation is non-
  negotiable.
- Do not treat FRIA as a one-off. Article 27 FRIA has to be
  updated when deployment conditions change materially; the
  deliverable's `review_due` field matters.
- Do not quote Article wording as the engineering spec.
  Translate it. "Appropriate level of accuracy" means a
  measured threshold specific to the system; shipping
  that phrase as the spec is not a spec.
- Do not commit the solution bundle to this repo. Solutions
  live in the paired `-solutions` repo.
