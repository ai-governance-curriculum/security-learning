# Chapter 04 — GDPR Articles 22, 25, and 35 as Engineering Artefacts

> **Note on AI-assisted content.** This chapter is not legal
> advice. Article text, recital numbers, and supervisory-
> authority guidance evolve; verify every citation against the
> primary source ([EUR-Lex](https://eur-lex.europa.eu/eli/reg/2016/679/oj))
> and the org's DPO / counsel before publishing an artefact
> externally. Where a claim is normative (should / must), the
> intended reader is the engineer producing the artefact; the
> DPO owns the final wording. See [`resources.md`](./resources.md).

---

## Why this chapter exists

Regulation and code do not speak the same language. A DPO reads
Article 22 and sees a right that the controller must respect; an
engineer reads it and wants to know what code change discharges
the obligation. Between the two sits a translation exercise
that most orgs perform badly:

- The engineer builds something reasonable but does not know
  which article the something discharges — so it cannot be
  cited in the DPIA and it cannot be defended in an
  investigation.
- The DPO writes a policy that says "the controller shall
  provide meaningful information" — accurate but
  unactionable — so nothing gets built and the policy stays
  aspirational.

This chapter is the translation table for three articles that
matter most for ML systems, each mapped to a concrete
engineering deliverable:

- **Article 22** — restrictions on solely-automated decisions
  producing legal or similarly significant effects, and the
  right to obtain human intervention and to contest.
  → **Right-to-explanation view**.
- **Article 25** — data protection by design and by default;
  proactive controls integrated into processing.
  → **DP-by-design ADR (architecture decision record)**.
- **Article 35** — Data Protection Impact Assessment; required
  where processing is likely to result in high risk to
  natural persons.
  → **DPIA template tailored for ML systems**.

The specific failure mode this chapter is written to prevent:

> A product ships a machine-learning-driven credit decisioning
> feature. The engineering team is aware of GDPR at the level
> of "we have a privacy policy". No DPIA is produced. When a
> data subject requests information about a decision made about
> them, the team's response is a form-letter from support that
> mentions "our proprietary model". The supervisory authority
> notes the response is not "meaningful information about the
> logic involved" per Article 22(3) / Article 15(1)(h). The
> product also lacks a documented Article 25 by-design record
> — the choice to use ML on this data was never assessed. The
> outcome is an enforcement action against the *processing
> practice*, not the technology; the tech was legal, the
> practice around it was not.

You leave this chapter able to:

- Read the three articles well enough to know what they are
  asking for and where their scope ends.
- Produce a right-to-explanation view that satisfies Article
  22 in engineering terms — a per-decision record, a
  human-review path, and a subject-facing surface.
- Produce a DP-by-design ADR that discharges Article 25 —
  proactive controls listed, tier-map placement recorded,
  rejected alternatives named.
- Produce a DPIA that a DPO can review and sign — scope,
  necessity, risk, mitigation, residual risk, sign-off.
- Wire these three artefacts into the release pipeline so
  each one is a required deliverable at the appropriate gate.

Chapter 05 does the same translation for the HIPAA Security
Rule (US healthcare). The two chapters are complementary — an
ML product touching EEA / UK residents and US PHI needs both.

---

## Article 22 — solely-automated decisions and the right-to-explanation view

### What Article 22 says (as an engineer should read it)

Article 22(1): data subjects have the right not to be subject
to a decision based **solely** on automated processing —
including profiling — which produces legal or similarly
significant effects.

Article 22(2) names three exceptions: contract-necessary,
authorised by EU/member-state law, or based on explicit consent.

Article 22(3): where the decision is based on 22(2)(a) contract
or 22(2)(c) consent, the controller shall implement suitable
measures to safeguard the data subject's rights — at minimum,
the right to obtain human intervention, to express their point
of view, and to contest the decision.

Article 22(4): special-category data (Art. 9) is generally
prohibited from being the basis of a 22(1) decision unless
tighter exceptions apply.

Recitals 71 and 72 elaborate. Article 15(1)(h) (right of access)
requires providing "meaningful information about the logic
involved, as well as the significance and the envisaged
consequences" of automated decision-making including profiling.

Engineering reading:

- If the ML system is used to make a decision *solely* — no
  human in the loop, no meaningful human review — with a
  significant effect (credit, insurance, employment, benefits,
  housing, education), Article 22 constrains the system.
- The system must offer: **human intervention**, the ability
  for the data subject to **express their point of view**, and
  the ability to **contest** the decision.
- The subject has a right to **meaningful information about
  the logic**.

What "sole" means is legally contested; a rubber-stamp human
who never reviews is probably still "sole" per WP29 / EDPB
guidance. Do not treat "we have a human somewhere in the
process" as an automatic escape. mod-107 chapter 03's HITL
patterns are relevant here — a HITL gate designed to be
meaningful is closer to the safe side.

### The right-to-explanation view (engineering artefact)

The artefact is a per-decision **record** the system produces
for every in-scope decision, plus a **subject-facing view** and
a **human-intervention workflow**.

Per-decision record — captured at inference time:

```yaml
# decision_record.yaml
decision_id: dec_2026_09_04_78a3
subject_id: "hashed:sha256:..."           # per data classification
timestamp: "2026-09-04T14:22:37Z"
model:
  name: risk_scoring_v4
  version: "4.2.1"
  card: "https://.../model-cards/risk_scoring_v4"
inputs:
  features_hash: "sha256:..."
  features_summary:                        # human-readable
    - "credit_utilisation: 0.72"
    - "recent_late_payments: 1"
    - "employment_years: 3"
    - "requested_amount_bucket: 'medium'"
  data_sources:
    - "internal_credit_history"
    - "self_reported_application_data"
output:
  decision: "declined"
  score: 0.34
  threshold: 0.45
  explanation:
    method: "shap_v0.44"
    top_positive_factors:                  # increased risk
      - {feature: "recent_late_payments", contribution: 0.18}
      - {feature: "credit_utilisation", contribution: 0.12}
    top_negative_factors:                  # decreased risk
      - {feature: "employment_years", contribution: -0.05}
    plain_language: >
      "Your recent late payments and current credit
       utilisation were the main factors that reduced
       your score below the approval threshold."
  policy_bounds:
    "score < threshold implies decline; explanation
     always cites top factors."
human_review:
  available: true
  path: "https://.../review/dec_2026_09_04_78a3"
  sla: "10 business days"
contest:
  available: true
  path: "https://.../contest/dec_2026_09_04_78a3"
  sla: "20 business days"
lineage:
  training_run: "mod-104-lineage://runs/risk_scoring_v4.2.1"
  dp_budget: "eps=3.0, delta=1e-5, record=user"
  dpia_ref: "mod-108/dpia/risk_scoring_v4"
```

Every field earns its place:

- **`decision_id`** and **`subject_id`** — support DSAR /
  right-of-access lookup.
- **`features_summary`** — human-readable; the "meaningful
  information about the logic" the subject sees.
- **`explanation`** — the local explanation. SHAP / LIME /
  integrated gradients / counterfactual — pick one and pin
  it. Do not ship "we use a proprietary method"; name the
  method with a version.
- **`plain_language`** — the version the customer support rep
  and the subject read. Generated by a template that maps top
  factors into sentences; reviewed by legal for the phrasing.
- **`policy_bounds`** — the deterministic rule from score to
  decision. "The model output crossed the threshold" is the
  legally-load-bearing part; the explanation motivates it.
- **`human_review`** and **`contest`** — the URLs and SLAs
  Article 22(3) requires. Both exist; both are named on the
  subject-facing surface.
- **`lineage`** — mod-104's audit trail; the model version,
  the DP budget, the DPIA. When the supervisory authority
  asks "how did you come to this decision", the answer chains
  through here.

Subject-facing surface:

- The subject, upon requesting information about a decision,
  is shown the **`plain_language`** explanation, the top
  factors, the **`human_review`** and **`contest`** paths,
  and the **`model` name + version**. Not the raw SHAP
  values; not the internal thresholds. The data controller's
  UX / support tooling renders this from the decision record.
- The subject's request for the record is fulfilled inside
  Article 12 timelines (one month; extendable by two under
  Art. 12(3) for complex cases).

Human-intervention workflow:

- **A named human reviewer** (or a rota) receives review
  requests via the `human_review` URL. The reviewer sees the
  full decision record and the subject's point of view; makes
  a decision; records the outcome. The workflow's SLA is what
  is exposed to the subject.
- **Rubber-stamping is a design failure.** The reviewer's
  workflow should include the ability to override the model
  decision with reasons; the outcome of overrides feeds the
  model-monitoring surface (systematic overrides suggest
  model error).
- **Reviewer identity** and reviewer decisions are audited.
  The audit is retained per legal.

### What the subject sees vs what the record contains

The record is comprehensive; the subject-facing view is a
curated subset. The curation:

- **Include** the plain-language explanation, top factors
  (weighted, named), the decision, the review + contest
  paths, and the model version.
- **Exclude** raw SHAP values, internal thresholds when
  disclosure creates gaming risk, and lineage identifiers
  the subject has no use for.
- **Design for accessibility.** The explanation is
  understandable by a non-expert. Legal reviews the wording
  for the specific jurisdiction.

There is a genuine tension between "meaningful information
about the logic" (as much as the subject can act on) and
"trade secret / model gaming" (as little as the org can get
away with). The right-to-explanation view is the org's
position on the tension, in writing.

### When the model output does not drive the decision

The `sole` in Article 22(1) matters. If the model produces a
score but a human underwriter makes the final call using the
score as one input among many, Article 22 is less directly
engaged — but the exemption is narrower than teams often think.
Guidance (EDPB Guidelines on automated individual
decision-making and profiling): the human review must be
"meaningful"; the reviewer must have the authority and
competence to change the outcome.

A workable rule of thumb: **if the human review is a rubber
stamp — no override authority, no time to consider, no
alternative outcome ever chosen — treat the decision as
solely automated for artefact purposes**.

---

## Article 25 — data protection by design and by default: the DP-by-design ADR

### What Article 25 says

Article 25(1): the controller shall, both at the time of
determining the means of processing and at the time of
processing itself, implement appropriate technical and
organisational measures — including pseudonymisation — designed
to implement data-protection principles effectively and to
integrate necessary safeguards into the processing.

Article 25(2): implement measures to ensure that, by default,
only personal data necessary for each specific purpose of the
processing are processed. Data minimisation applies to the
amount collected, the extent of processing, retention, and
accessibility.

Engineering reading:

- Article 25 is a **process obligation** — the org shows that
  privacy was considered at design time, not as a bolt-on.
- The org needs a record of *what was considered* and *what
  was chosen*.
- The evidence is the design artefact — an ADR (architecture
  decision record) or equivalent that names the alternatives
  considered, the principle applied, and the resulting choice.

### The DP-by-design ADR template

An ADR that discharges Article 25 for an ML system:

```markdown
# ADR — Data protection by design for <system>

## Status
Accepted (date). Reviewed by: <DPO>, <security lead>,
<engineering lead>.

## Context
### System scope
- Purpose: <one-sentence purpose; specific>.
- Data subjects: <who>.
- Data categories: <per Art. 4; e.g. "identification data,
  contact data, behavioural data, financial data">.
- Special-category data (Art. 9): <yes / no; if yes,
  which categories and under which Art. 9(2) lawful basis>.
- Lawful basis: <Art. 6(1) legal basis; if Art. 6(1)(f),
  reference the legitimate-interest assessment>.

### Data flow overview
<Short prose or diagram — where data enters, how it is
processed, where it is stored, how long it is retained.>

## Data protection principles — how each is honoured

### Lawfulness, fairness, transparency (Art. 5(1)(a))
<How consent / contract / legitimate interest was
established; how transparency is delivered (privacy notice,
in-product disclosure).>

### Purpose limitation (Art. 5(1)(b))
<Purpose statement; scope-limiting controls (feature-store
access ACLs, use-case labels, downstream-use tracking).>

### Data minimisation (Art. 5(1)(c))
<Feature selection rationale; fields excluded and why;
aggregation choices.>

### Accuracy (Art. 5(1)(d))
<How data is verified at ingest; how erroneous data is
corrected or purged; rectification workflow.>

### Storage limitation (Art. 5(1)(e))
<Retention per data type; auto-purge mechanism; retention
of training-time snapshot vs. serving-time state.>

### Integrity and confidentiality (Art. 5(1)(f))
<Storage encryption (mod-105); transport (mod-103);
access controls (mod-103); audit logging (mod-104).>

### Accountability (Art. 5(2))
<How the above is evidenced — the mod-104 lineage record,
the mod-109 governance evidence, the DPIA reference below.>

## By-design controls (Art. 25(1))
<Numbered list of proactive controls integrated into the
system, with pointers to where each is implemented.>

1. Differential-privacy training (chapter 01) —
   target `(ε, δ)` = <value>; profile <ref>.
2. PII/PHI DLP on training data (chapter 03) —
   profile <name>, coverage report <ref>.
3. Inference-attack architectural controls (chapter 02) —
   per-identity rate limit, output aggregation, MI-AUC
   monitor.
4. Feature minimisation — <specific features excluded from
   training with rationale>.
5. Pseudonymisation of subject id at ingest (Art. 4(5)) —
   <method; key management ref>.
6. Right-to-explanation view (Art. 22 artefact above) —
   pointer to decision-record schema and subject UI.
7. DSAR / erasure wiring — how requests reach training data,
   feature store, model, retrieval store, prompt log.
8. Data-subject rectification workflow — how the human
   review from Art. 22 feeds back into corrections.

## By-default controls (Art. 25(2))
<How the defaults minimise data — closed by default,
opt-in for additional collection, minimal retention by
default, limited access by default.>

## Alternatives considered
### <Alternative 1>
- Description.
- Why not chosen (usually: does not honour minimisation /
  purpose-limitation as well; residual risk too high).

### <Alternative 2>
- Description.
- Why not chosen.

### Do nothing / do not build
- Considered. Why the processing is nonetheless justified
  (necessity, legitimate interest, contract).

## Residual risk
<Named risks the by-design controls do not fully close;
who owns them; the DPIA (below) covers them in detail.>

## References
- DPIA: <ref>.
- mod-104 lineage: <ref>.
- Right-to-explanation view: <ref>.
- Model card: <ref>.
- Tier map (chapter 01 policy): <ref>.
- HIPAA control map (if PHI in scope; chapter 05): <ref>.
```

An ADR that reads as "we hired a good team and they used best
practices" is not an Article 25 discharge. An ADR that lists
specific controls, specific alternatives rejected, and specific
residual risks is.

### Data-protection principles as a design checklist

The GDPR data-protection principles (Art. 5) are the checklist
Article 25 asks about. For ML systems, the principles map to
concrete design choices:

- **Purpose limitation.** The training data is scoped to the
  named purpose; use-case labels on features prevent scope
  creep; a retraining that would expand the purpose triggers
  a new DPIA.
- **Data minimisation.** Feature engineering explicitly excludes
  fields whose predictive value does not justify their
  privacy cost. The exclusion is written down. The engineering
  bias should be "which of these do we really need", not
  "throw everything at the model and see".
- **Storage limitation.** Training snapshots are retained per
  a stated policy; serving-time state is minimised.
  Retention limits apply to the mod-104 audit log too, subject
  to any longer retention required by other regimes (HIPAA
  six-year retention, financial-sector retentions).
- **Accuracy.** Data-correction workflows feed both the
  training data and the deployed model. If Alice's record was
  wrong, correcting it in the source system without also
  updating the training data or the model's serving state is
  a compliance gap.

Each principle in the ADR earns a concrete answer, not a
paraphrase of the principle.

### Pseudonymisation vs. anonymisation

Article 25(1) explicitly names pseudonymisation. Article 4(5)
defines it: processing such that data can no longer be attributed
to a specific data subject without additional information kept
separately.

- **Pseudonymised data is still personal data** under GDPR (the
  key exists somewhere).
- **Anonymised data** is not personal data (the key does not
  exist; re-identification is not practically possible).

Chapter 03's hashed identifiers are pseudonymisation, not
anonymisation. The ADR should be precise about which is
claimed. Claiming anonymisation for pseudonymised data is a
common and material misstatement.

---

## Article 35 — Data Protection Impact Assessment

### What Article 35 says

Article 35(1): where processing is likely to result in a high
risk to the rights and freedoms of natural persons — using
new technologies and taking into account the nature, scope,
context, and purposes of the processing — the controller shall,
prior to the processing, carry out a DPIA.

Article 35(3) names three cases where DPIA is always required:

- Systematic and extensive evaluation based on automated
  processing including profiling, on which decisions producing
  legal or similarly significant effects are based.
- Processing on a large scale of special-category data (Art.
  9) or of personal data relating to criminal convictions
  (Art. 10).
- Systematic monitoring of a publicly accessible area on a
  large scale.

Individual supervisory authorities publish additional lists
(the Article 35(4) "must-do" list; the Article 35(5) "may not
require" list). Check the org's lead supervisory authority.

Article 35(7) sets the DPIA's minimum content:

- A systematic description of the envisaged processing and its
  purposes.
- An assessment of necessity and proportionality.
- An assessment of the risks to rights and freedoms.
- The measures envisaged to address the risks — including
  safeguards, security measures, and mechanisms to ensure the
  protection of personal data and demonstrate compliance.

Article 35(9): where appropriate, seek views of data subjects
or their representatives.

Article 36 requires **prior consultation** with the supervisory
authority when the DPIA indicates high residual risk in the
absence of measures the controller has taken.

Engineering reading:

- Nearly every ML system processing personal data at scale
  probably requires a DPIA. Automated decisions with
  significant effects definitely do.
- The DPIA is a **structured risk assessment** with a required
  content list. It is signed by the DPO, retained, and
  reviewed when the processing changes.
- The DPIA is not a one-off. Changes to the processing
  (a new data source, a new purpose, a new model architecture,
  a new decision surface) trigger a DPIA update.

### The ML-DPIA template

The DPIA template below is scoped to ML systems and cross-refers
to the artefacts this module produces. Use it as the starting
point; the DPO adapts to the org's DPIA process.

```markdown
# DPIA — <system>, version <n>

## Metadata
- DPIA ID: <unique id>.
- Version: <n>. Prior version: <ref>.
- Prepared by: <name, role>.
- Reviewed by: DPO <name>, security lead <name>,
  engineering lead <name>.
- Approval date: <date>.
- Next review: <date>; or on material change (see §7).

---

## 1. Systematic description of the processing (Art. 35(7)(a))

### 1.1 Purpose
- Specific purpose the processing serves.
- Business need; why ML is required (vs. deterministic
  alternatives).

### 1.2 Nature
- Data collected: <categories per Art. 4>.
- Special-category data (Art. 9): <yes/no; which; Art. 9(2)
  basis if yes>.
- Data sources: <internal / external; provenance ref
  mod-104 / mod-110>.
- Data subjects: <who; approximate volume>.
- Data recipients: <internal teams; third parties;
  cross-border transfers per Art. 46>.

### 1.3 Scope
- Geographic scope: <EEA / UK / other>.
- Volume: <records; subjects; queries/day for serving>.
- Duration: <how long processing continues>.
- Retention: <per data category; per artefact — training
  data, model, logs, decision records>.

### 1.4 Context
- Relationship with data subjects (customer,
  employee, general public).
- Data-subject expectations (would they expect this
  processing given the collection context?).
- Vulnerabilities of the data subjects (minors, patients,
  low-power groups).

### 1.5 Automated decisions
- Does the processing produce Art. 22 automated
  individual decisions? <yes/no>.
- If yes: pointer to the Art. 22 right-to-explanation
  view above.
- If yes: legal basis (contract / consent / EU or
  member-state law).

## 2. Necessity and proportionality (Art. 35(7)(b))

### 2.1 Necessity
- Why the processing is necessary for the specified
  purpose.
- Alternatives considered (aggregate statistics only;
  smaller feature set; different technique; not doing
  the processing).

### 2.2 Proportionality
- Balance between data-subject interests and the
  processing purpose.
- Data-minimisation controls (which fields excluded
  and why; chapter 03 DLP profiles).
- Retention limits.
- Access controls (mod-103 identity primitives).

### 2.3 Lawfulness (Art. 6)
- Basis: <contract / consent / legitimate interest /
  legal obligation / vital interest / public task>.
- If legitimate interest (Art. 6(1)(f)): reference the
  Legitimate Interest Assessment.
- If special-category (Art. 9): the Art. 9(2) basis
  and any supplementary conditions from Art. 9(2)(g)
  onwards.

### 2.4 Data-subject rights delivery
- How Art. 12–22 rights are delivered:
  - Right of access (Art. 15): <DSAR wiring>.
  - Right to rectification (Art. 16): <workflow>.
  - Right to erasure (Art. 17): <workflow; how it reaches
    training data, model, retrieval store, prompt log>.
  - Right to restriction of processing (Art. 18): <how>.
  - Right to data portability (Art. 20): <if applicable>.
  - Right to object (Art. 21): <how>.
  - Rights re: automated decision-making (Art. 22):
    <pointer to §1.5 and to the right-to-explanation view>.

## 3. Risk assessment (Art. 35(7)(c))

For each risk, state: likelihood, severity, impact on data
subjects, and the risk score before mitigation.

### 3.1 Confidentiality risks
- Training-data leakage via model outputs (membership /
  attribute inference, LLM training-data extraction).
  - Chapter 02 mitigations apply.
- Training-data leakage via storage compromise.
  - mod-105 encryption; mod-103 access controls.
- Prompt-log or trajectory-log leakage.
  - Chapter 03 DLP; access controls.

### 3.2 Integrity risks
- Model poisoning altering decision outcomes for
  vulnerable subjects.
  - mod-106 chapter 04 detection; mod-104 provenance.
- Data-poisoning altering the training distribution.
  - mod-106 chapter 04; mod-104.

### 3.3 Availability risks
- Model / feature-pipeline outage causing decision
  delays impacting rights.
  - mod-111 SRE / incident processes.

### 3.4 Discrimination / bias risks
- Systematic bias in decisions correlating with
  protected characteristics.
  - Bias evaluation on model-card; mitigations; monitoring.
  - Note: bias risk is a data-protection risk under GDPR
    (Art. 5(1)(a) fairness; Recital 71) as well as an
    equality-law issue.

### 3.5 Automated-decision risks
- Rubber-stamp human review resulting in de-facto solely
  automated decisions.
  - HITL design per §1.5; reviewer competence + authority.
- Explanation quality insufficient for subject to
  meaningfully contest.
  - Explanation-method choice; plain-language quality
    review.

### 3.6 Function creep
- Purpose expanding beyond original scope; feature set
  repurposed.
  - Use-case labels on features; DPIA-on-change trigger.

## 4. Mitigations (Art. 35(7)(d))

Cross-reference the artefacts in this module:

- Training-time controls: chapter 01 tier-map placement,
  DP-SGD `(ε, δ)`.
- Inference-time controls: chapter 02 three-layer defence
  (architectural + monitoring).
- DLP: chapter 03 profiles + coverage evidence.
- Article 22 delivery: right-to-explanation view above.
- Article 25 delivery: DP-by-design ADR above.
- Storage / transport: mod-105 KMS, mod-103 identity.
- Provenance / lineage: mod-104.
- Supply chain: mod-110 (imported models, datasets).
- Governance: mod-109 (evidence surface).
- Incident response: mod-111 (breach clocks per Art. 33,
  34).

## 5. Residual risk

Named risks that the mitigations do not fully close; the
DPO's assessment of whether the residual risk is
acceptable.

If residual risk is high, Art. 36 prior consultation with
the supervisory authority is required before processing
begins.

## 6. Data-subject / representative consultation
(Art. 35(9))

- Was consultation performed? Method used (survey,
  representative body, none)?
- Findings; how findings shaped the design.
- If not performed: reason (Art. 35(9) allows "where
  appropriate").

## 7. Review triggers

The DPIA is reviewed on:
- Annual cadence (default).
- Material change to the processing:
  - New data source or data category.
  - New purpose (or expansion of scope).
  - New data recipient.
  - New model architecture materially changing decision
    behaviour.
  - Change to automated-decision surface (new decision
    class, changed threshold, changed lawful basis).
  - Change to retention or cross-border transfer.
  - Change to the DP tier (chapter 01) — e.g. moving from
    personal-moderate to personal-sensitive.
- Incident affecting the processing (Art. 33 breach; a
  systemic bias finding; a rights-request escalation).

## 8. Sign-off
- Preparer: <name>, <date>.
- DPO: <name>, <date>.
- Product owner: <name>, <date>.
- Engineering lead: <name>, <date>.
- Legal (as applicable): <name>, <date>.
```

The DPIA is version-controlled. The current version is the
one linked from the model card (mod-104) and the governance
evidence surface (mod-109). Prior versions are retained.

### When a DPIA is or is not required

The safest posture: if unsure, produce the DPIA. The cost of
a DPIA that turns out not to be strictly required is low; the
cost of the missing DPIA for processing that required one is
high.

Common patterns where a DPIA is clearly required for an ML
system:

- Automated decisions with significant effects on individuals
  (credit, insurance, employment, benefits, housing) — even
  if a human reviews.
- ML systems trained on health data, biometrics, or other
  special-category data.
- ML systems processing children's data.
- Large-scale profiling systems (recommenders, ad targeting,
  behaviour scoring).
- ML systems using data collected in a context different from
  the current use (context change; purpose change).
- Systems using novel technologies (generative AI, agentic
  systems) on personal data at scale.

Patterns where DPIA may not be required (verify with DPO):

- Aggregate-only analytics on already-anonymised data.
- Small-scale internal test on synthetic data.
- Processing purely for statistical purposes with appropriate
  safeguards (recital 162; Art. 89).

The `Article 35(4)` list from the org's lead supervisory
authority (the ICO in the UK; the CNIL in France; the DSK in
Germany; and so on across the EEA) resolves close calls.

---

## Wiring the three artefacts into the release pipeline

Each artefact is a required deliverable at a specific gate:

- **Design gate** (before implementation starts) —
  DP-by-design ADR (Art. 25).
- **Pre-processing gate** (before personal data is processed
  at production scale) — DPIA (Art. 35).
- **Deployment gate** (before serving to users) — right-to-
  explanation view (Art. 22), if solely-automated decisions
  with significant effects are in scope.

Pipeline integration:

- The design-gate check verifies the ADR exists, is signed,
  and references the current tier map (chapter 01).
- The pre-processing-gate check verifies the DPIA exists, is
  signed by the DPO, and references the ADR + the chapter-02
  deployment-review packet + the chapter-03 DLP profile.
- The deployment-gate check verifies (for in-scope systems)
  that the decision-record schema is implemented, that the
  human-intervention workflow is live, and that the subject-
  facing surface renders the right-to-explanation view.

If the pipeline runs without these artefacts, the pipeline
config is misconfigured — the check should fail.

Retraining under the same processing context does not require
new artefacts (a version-bump on the model card that references
the existing DPIA + ADR is enough). Material change to the
processing (new data category, new purpose, new decision
surface, new tier) triggers artefact updates before the
retraining ships.

---

## Standard failure modes

- **DPIA written after processing has started.** Article 35(1)
  says "prior to the processing". A retroactive DPIA is
  better than none — flag it as remediation.
- **Right-to-explanation view is a paragraph in the privacy
  policy.** Article 22(3) requires the *right to contest* and
  *human intervention*, not a URL to "how our model works".
  The engineering artefact must exist.
- **DP-by-design ADR that lists "we use ML best practices".**
  Not an Article 25 discharge. Named controls, named
  alternatives, named residual risks.
- **DPIA that copy-pastes template text.** A DPIA that could
  belong to any system is not a DPIA for this system. Every
  section is specific.
- **The DPO is asked to sign at the last minute.** The DPIA
  and ADR go through the DPO early — Article 39(1)(c) says
  the DPO shall provide advice regarding the DPIA and
  monitor its performance. Late DPO involvement is a process
  failure.
- **Automated decisions treated as "not solely automated"
  because a human clicks approve.** If the human does not
  actually consider, the decision is solely automated in
  spirit. Design HITL to be meaningful (mod-107 chapter 03).
- **Explanations that "explain" the model rather than the
  decision.** Subjects need to know why *their* decision
  went the way it did, in language they can act on.
- **DSAR / erasure workflow that only touches the primary
  database.** The training data, the model, the retrieval
  store, the prompt log, and the decision-record store all
  need to be reachable.
- **DPIA never re-reviewed.** Processing evolved; the DPIA
  did not. Fix: named review triggers; annual cadence at
  minimum.
- **Article 22 view is fully generated by the model.** The
  model explaining itself is not the same as the controller
  providing meaningful information about the logic; legal
  reviews the wording.
- **Cross-border data transfer not addressed.** Even if the
  processing is EEA-lawful, the transfer to a non-adequate
  jurisdiction (Chapter V of GDPR) needs its own basis —
  Standard Contractual Clauses, BCRs, adequacy decision.
  The DPIA covers this.

---

## The mistakes this chapter is trying to prevent

- **Legal-in-a-vacuum.** Policy is written that engineers do
  not know how to implement; the policy sits unenforced.
- **Engineering-in-a-vacuum.** Controls are shipped that
  legal cannot cite; the controls are invisible in an
  investigation.
- **Confusing "we do the right thing" with "we can show we
  did the right thing".** Regulators care about the
  documented process — the ADR, the DPIA, the sign-off — as
  much as the underlying reality. Undocumented compliance is
  compliance-in-your-head.
- **DPIA-as-a-form.** The form gets filled; the risks are
  not actually considered. A DPIA whose §3 is boilerplate is
  not risk assessment; it is theatre.

---

## Summary

- **Article 22** — solely-automated decisions producing legal
  or significant effects — is engineered as a **right-to-
  explanation view**: a per-decision record, a subject-facing
  summary, a human-review workflow, a contest path. Rubber-
  stamp humans do not escape the article; the reviewer must
  have authority and competence.
- **Article 25** — data protection by design and by default
  — is engineered as a **DP-by-design ADR**: a design record
  that names proactive controls, alternatives considered,
  and residual risks. An ADR that reads as "we follow best
  practices" is not a discharge.
- **Article 35** — Data Protection Impact Assessment — is
  engineered as a **structured DPIA template**: description,
  necessity, risk, mitigation, residual risk, sign-off. A
  DPIA that could belong to any system is not the DPIA for
  this one.
- The three artefacts are **release-pipeline gates**: ADR
  at design, DPIA before processing, right-to-explanation
  view at deployment for in-scope systems.
- Each artefact **cross-references** the technical controls
  in this module (chapter 01 tier map, chapter 02 defences,
  chapter 03 DLP) and the sibling modules (mod-103 identity,
  mod-104 lineage, mod-105 KMS, mod-107 HITL, mod-109
  governance). The privacy programme is these artefacts,
  not the sum of the individual controls.
- **The DPO is a partner, not a rubber stamp.** Early
  involvement, review of the DPIA / ADR / decision-record
  schema, is what turns paperwork into compliance.
- **Not legal advice.** This chapter names the shape of the
  artefacts; the actual legal wording belongs to counsel.
