# Exercise 04 — GDPR Articles 22, 25, 35 to Engineering Artefacts

**Estimated effort:** ~3 hours
**Deliverable:** A committed artefact bundle for one target
ML product, consisting of (a) a decision-record schema and a
subject-facing summary that discharge Article 22's right-to-
explanation obligation, (b) a DP-by-design ADR that discharges
Article 25's by-design-and-by-default obligation, (c) a DPIA
tailored to the system that satisfies Article 35's minimum
content, (d) a release-pipeline integration plan naming where
each artefact becomes a required gate, and (e) a rehearsal-
review record capturing a walkthrough with a stand-in for the
DPO / legal (notes, open questions, agreed changes).
**Prerequisites:** Chapter 04 read end-to-end. Exercise 01's
tier placement and `(ε, δ)` decision; exercise 02's threat
model and architectural controls; exercise 03's DLP profile
and coverage report — all three plug into these artefacts.
Access to the target product's data flow (which categories,
which subjects, which recipients, which retention). A named
rehearsal partner — the actual DPO is ideal; a security lead
or governance peer with GDPR context is an acceptable stand-
in.

---

## Objective

Chapter 04's thesis is that GDPR articles turn into engineering
deliverables, not into policy paragraphs. This exercise is the
exercise that makes that concrete for one target product.

By the end of this exercise you have:

- A **right-to-explanation view** — a per-decision record
  schema, a subject-facing summary template, and a named
  human-intervention and contest workflow.
- A **DP-by-design ADR** — a signed architecture decision
  record that lists proactive controls, alternatives
  rejected, and residual risks.
- A **DPIA** — a filled-in document following Article 35(7)'s
  minimum content, with risks, mitigations, and sign-off.
- A **release-pipeline integration plan** — which artefact
  gates which pipeline stage.
- A **rehearsal-review record** — the output of walking the
  three artefacts past a DPO stand-in, with the changes those
  conversations trigger.

You are producing **regulator-defendable** documentation. The
artefacts are what the supervisory authority is handed; the
rehearsal is the dry run that catches the gaps before the
real review.

> **Caveat.** This exercise does not provide legal advice.
> Final wording of subject-facing text and residual-risk
> determinations belongs to counsel / the DPO. The exercise
> trains the engineering muscle that produces the artefacts
> the DPO will edit, not approve-as-is.

---

## Problem statement

Pick one target product. In order of preference:

1. A real ML product in your org (or a product you have access
   to the data flow for) that processes personal data of EEA /
   UK residents.
2. A well-defined internal proof-of-concept with a plausible
   data flow and a decision class.
3. A hypothetical sketched in enough detail that the artefacts
   are specific — "a credit-scoring product that reads bureau
   data and self-reported application data, outputs an
   approve / decline / refer decision, serves ~10k decisions/
   month to UK applicants".

Whatever you pick, by the end of this exercise you must be
able to state:

- Lawful basis under Art. 6 (and Art. 9 if special-category
  data is in scope).
- Data categories processed (per Art. 4).
- Data subjects (who they are; approximate volume).
- Whether the processing produces Art. 22(1) solely-automated
  decisions with legal or similarly significant effects — if
  yes, the right-to-explanation view is required; if no,
  explain the human-in-the-loop design (chapter 04 is explicit
  that rubber-stamp humans do not escape the article).
- Whether a DPIA is required per Art. 35(3) or the lead
  supervisory authority's Art. 35(4) list.
- Cross-border transfers (Chapter V) if any.

If the product is a chat or RAG assistant without automated-
decision scope, the Article 22 artefact is a one-page "scope
not engaged — here is why" with the reasoning (rubber-stamp
test, no legal-effect test); the Article 25 ADR and Article 35
DPIA still apply.

---

## Requirements

### Deliverable A — right-to-explanation view (Article 22)

If the product produces Article 22(1) decisions, produce:

**A.1 Per-decision record schema.** A YAML / JSON schema that
every in-scope decision writes. Follow the chapter-04 example:

- `decision_id`, `subject_id` (hashed), timestamp.
- Model identity: name, version, model-card link.
- Inputs: features hash + a human-readable summary of top
  input values; data sources.
- Output: decision, raw score, threshold, explanation
  (method name + version, top positive factors, top
  negative factors, plain-language sentence), policy bounds.
- Human-review: available (yes/no), URL, SLA.
- Contest: available (yes/no), URL, SLA.
- Lineage: training-run ref (mod-104), DP budget `(ε, δ,
  record_def)` (from exercise 01), DPIA reference (from this
  exercise, Deliverable C).

**A.2 Subject-facing summary template.** A Markdown / HTML
template that renders a subject-safe curated subset of the
record — plain-language explanation, top factors (named,
weighted), decision, review path, contest path, model name +
version. Raw SHAP values, internal thresholds, and lineage
identifiers are excluded unless disclosure is specifically
justified.

**A.3 Human-intervention workflow.** A one-page process
description:

- Who the reviewers are (role; rota; competence check).
- The reviewer's view (full decision record + the subject's
  stated point of view).
- Override authority (named — the reviewer *can* change the
  outcome; the chapter is explicit that a rubber stamp is
  not a defence).
- SLA (as exposed to the subject; Article 12's one-month
  timeline is the ceiling, extendable per Art. 12(3)).
- Audit (reviewer identity, decision, rationale retained;
  override patterns feed the model-monitoring surface).

**A.4 Contest path.** Where the subject can contest a
decision; what happens when they do; separate from the
human-intervention workflow if the contest process is
different (often it is — contest can produce a different
outcome through a different route).

**A.5 Scope-not-engaged variant (if applicable).** A one-page
memo arguing that the product is not in Article 22 scope,
addressing: solely-automated test (is there meaningful human
review?), legal-or-similarly-significant-effects test (does
the decision carry a significant effect?). Both tests must
be addressed, not just one; a decision that is advisory but
materially affects the subject's rights can still engage
Article 22 depending on jurisdiction.

### Deliverable B — DP-by-design ADR (Article 25)

A rendered ADR following the chapter-04 template:

- **Status.** Accepted (date). Reviewers.
- **Context.** System scope — purpose, data subjects, data
  categories, Art. 9 flag + basis if applicable, Art. 6
  basis. Data-flow overview — where data enters, how it
  is processed, where it is stored, retention.
- **Data-protection principles.** Each Art. 5 principle
  (lawfulness/fairness/transparency; purpose limitation;
  data minimisation; accuracy; storage limitation; integrity
  and confidentiality; accountability) answered concretely
  — the principle name is the heading; the answer is the
  specific choice the system makes.
- **By-design controls.** A numbered list of proactive
  controls with pointers:
  1. DP training per exercise 01 — `(ε, δ)`, record
     definition, composition plan.
  2. DLP on training data per exercise 03 — profile name,
     coverage SLO.
  3. Inference-attack controls per exercise 02 — rate
     limits, aggregation, MI-AUC monitor.
  4. Feature minimisation — specific features excluded,
     with rationale.
  5. Pseudonymisation of subject identifiers at ingest —
     method, KMS key reference (mod-105).
  6. Right-to-explanation view (Deliverable A) if in scope.
  7. DSAR / erasure wiring — how a subject-access or
     erasure request reaches training data, feature store,
     model, retrieval store, prompt log, decision records.
  8. Rectification workflow — how human-review overrides
     feed back into data corrections.
- **By-default controls.** How defaults minimise data — opt-
  in for additional collection, minimum retention,
  minimum access.
- **Alternatives considered.** At least two technical
  alternatives (e.g. "aggregate-only analytics", "smaller
  feature set", "different model class") and a "do nothing /
  do not build" option, each with the reason it was not
  chosen.
- **Residual risk.** The risks the by-design controls do not
  fully close; who owns them; a pointer to the DPIA for the
  detailed treatment.
- **References.** DPIA, mod-104 lineage, right-to-explanation
  view, model card, tier map (exercise 01 / chapter 01
  starter), HIPAA control map if applicable (exercise 05).

Chapter 04 is explicit that "we follow best practices" is not
an Article 25 discharge. Every bullet in by-design controls is
a specific choice; every alternative is a specific
alternative.

### Deliverable C — DPIA (Article 35)

A rendered DPIA following the chapter-04 template:

- **Metadata.** DPIA ID, version, preparer, reviewers,
  approval date, next review.
- **§1 Systematic description** — purpose, nature,
  (special-category flag + basis), scope, context (data-
  subject relationship, vulnerabilities), automated decisions
  flag + pointer to Deliverable A.
- **§2 Necessity and proportionality** — why the processing
  is necessary; alternatives considered; proportionality
  argument; Art. 6 (and 9 if applicable) lawful basis; data-
  subject rights delivery (how each of Art. 12–22 is
  implemented).
- **§3 Risk assessment** — per risk category, likelihood,
  severity, impact, pre-mitigation score. Categories: con­
  fidentiality (training-data leakage via model, via storage,
  via logs); integrity (poisoning); availability (outage
  impacting rights); discrimination / bias; automated-
  decision risks; function creep.
- **§4 Mitigations** — cross-references to:
  - Exercise 01 tier placement + DP budget.
  - Exercise 02 three-layer defence.
  - Exercise 03 DLP profiles.
  - Deliverable A right-to-explanation view.
  - Deliverable B ADR.
  - mod-103 identity / mTLS; mod-104 lineage; mod-105 KMS.
  - mod-110 supply-chain provenance for imported models /
    datasets.
  - mod-109 governance evidence; mod-111 incident response
    (Art. 33 / 34 breach clocks).
- **§5 Residual risk.** The named risks the mitigations do not
  fully close; the DPO's assessment of acceptability. If any
  residual risk sits in "high", Article 36 prior-consultation
  with the supervisory authority is required — flag it.
- **§6 Data-subject or representative consultation (Art.
  35(9)).** Was it done; by what method; findings; or why
  not.
- **§7 Review triggers.** Annual cadence; material-change
  triggers (new data source, new purpose, new recipient, new
  model architecture materially changing decision behaviour,
  change to automated-decision surface, change to retention
  or cross-border transfer, change to DP tier, incident).
- **§8 Sign-off.** Preparer, DPO, product owner, engineering
  lead, legal.

The DPIA that could belong to any product is not the DPIA for
this one. Every section is specific — the risks name the
particular dataset and the particular decision class; the
mitigations name the particular exercise outputs.

### Deliverable D — release-pipeline integration plan

A short section (half a page) that names, for the target
product:

- **Design gate.** The ADR (Deliverable B) exists, is signed,
  and references the current tier map. The gate check that
  verifies this.
- **Pre-processing gate.** The DPIA (Deliverable C) exists, is
  signed by the DPO, and references the ADR + the chapter-02
  deployment-review packet + the chapter-03 DLP profile. The
  gate check.
- **Deployment gate (for Art. 22 systems).** The decision-
  record schema is implemented; the human-intervention
  workflow is live; the subject-facing surface renders the
  summary template. The gate check.
- **Retraining pathway.** Retrainings under the same
  processing context do not require fresh artefacts (a
  version-bump on the model card referencing the existing
  DPIA + ADR is enough); material changes trigger artefact
  updates. State what counts as material for *this* product.

### Deliverable E — rehearsal-review record

Walk the three artefacts past a DPO stand-in (named rehearsal
partner). Record:

- Date, participants, duration.
- Open questions the partner raised, with proposed answers or
  owner + due date.
- Agreed changes to each artefact (a diff list; the actual
  edits land in Deliverables A–C).
- Any residual-risk reassessment that the conversation
  triggered.
- A list of items the real DPO will need to re-review before
  the artefacts are signed externally.

The rehearsal is not a rubber stamp — if the walkthrough
produces zero open questions, either the artefacts are too
abstract to find issues in or the partner was not pushed.
Flag that in the record.

---

## Starter guidance

- **Decide Article 22 scope first.** The right-to-explanation
  view is the heaviest Deliverable; knowing whether it is in
  scope changes the shape of the DPIA (§1.5) and the ADR (the
  by-design controls list). The chapter is clear that
  "rubber-stamp human review" does not escape scope — be
  honest about the real HITL design.
- **Reuse exercises 01, 02, 03.** The three technical
  exercises produce the artefacts the ADR and DPIA cross-
  reference. If any of those are not yet done, do the pieces
  needed and note the dependency.
- **Specific residual-risk statements.** "Residual risk is
  low" is not an Article 35 compliant finding. "Residual
  risk: membership inference under a very large (1M+ query)
  attacker, mitigated by MI-AUC monitoring at 0.55 and the
  per-tenant rate limit; incident response path in mod-111"
  is.
- **Walk the DSAR / erasure path end-to-end.** Chapter 04 is
  explicit that erasure must reach every store — training
  data, model (what the model memorised), retrieval index,
  prompt log, decision records. Trace a hypothetical erasure
  request through each store; the trace is what
  Deliverable B's bullet 7 says it is.
- **Pseudonymisation ≠ anonymisation.** Hashed identifiers
  are pseudonymised; the data is still personal under GDPR.
  Be careful in the ADR about which is claimed.
- **Cross-border transfers.** If the product serves EEA
  residents from infra in a non-adequate jurisdiction (US
  cloud regions, etc.), §1.2 of the DPIA names the Chapter V
  transfer basis (SCCs, BCRs, adequacy decision) and the
  Transfer Impact Assessment.
- **The rehearsal is the dry run.** The point is to find the
  gaps that the real DPO conversation would otherwise find
  live. Push the stand-in to interrogate the DPIA like a
  supervisory authority would.

---

## Acceptance criteria

A passing bundle:

- Article 22 scope is explicitly decided; the right-to-
  explanation view is produced if in scope, or a defensible
  scope-not-engaged memo is produced with both tests
  addressed.
- The decision-record schema has every field earning its
  place; the subject-facing summary is readable to a non-
  expert; the human-intervention workflow names a reviewer
  with real override authority.
- The ADR lists specific proactive controls (not best-
  practices paraphrases), specific alternatives rejected
  (not "we considered alternatives"), and specific residual
  risks (not "residual risk is low").
- The DPIA covers every section of Art. 35(7); the risk
  assessment is specific; the mitigations cite the technical
  exercises; the residual-risk block names risks and the
  DPO's acceptability assessment.
- The release-pipeline integration plan names three gates
  (design, pre-processing, deployment-for-Art.-22) with
  verifiable gate checks and a defined retraining pathway.
- The rehearsal record captures real questions and agreed
  changes.
- DSAR / erasure wiring reaches every PHI/PII surface — the
  trace is present.

A failing bundle:

- "Our model is proprietary" or similar as the right-to-
  explanation content.
- An ADR that reads as a GDPR paraphrase rather than system-
  specific choices.
- A DPIA whose §3 risk assessment is boilerplate.
- Automated decisions treated as "not solely automated"
  because a human clicks approve, with no rubber-stamp test.
- Erasure wiring that only touches the primary database;
  training data, model, retrieval, logs ignored.
- Cross-border transfer not addressed when applicable.
- A rehearsal record with zero open questions and zero
  changes.

---

## Stretch goals

- **Real DPO walkthrough.** Walk the artefacts past the
  actual DPO (not just a stand-in) and capture the review as
  a formal pre-sign step. Flag the differences between the
  rehearsal and the real review as a learning note.
- **Multi-jurisdictional overlay.** For a product serving both
  UK and EEA residents (post-Brexit) or EU + Swiss residents,
  write a one-page overlay that names the FDPA / UK GDPR
  deltas. Material deltas: UK ICO guidance on automated
  decisions, Swiss revFADP's own DPIA regime.
- **Supervisory-authority exercise.** Pick the lead
  supervisory authority for the product (ICO, CNIL, DSK, DPC,
  etc.) and verify the DPIA matches its published
  expectations; adjust accordingly.
- **Explanation-method ablation.** For the Deliverable A
  schema, produce two explanation methods (SHAP + counter­
  factual) and compare the subject-facing summaries they
  produce. Argue which the product should ship.
- **Decision-record UX mockup.** Produce an actual mockup
  (even a static one) of what the subject sees when they
  request information about a decision. Walk a non-technical
  person through it and record whether they can act on it.
- **DPIA-on-change simulation.** Pick a plausible material
  change (new data source, new decision class) and run the
  DPIA through the review-trigger process. Produce the
  version diff; show how the ADR / right-to-explanation
  artefacts update in lockstep.
- **Linkage to chapter 05 HIPAA.** If the product also
  touches PHI, produce the §1 (systematic description) and
  §4 (mitigations) sections referencing exercise 05's HIPAA
  control-mapping matrix. The two regimes compose; the DPIA
  states where.

---

## Do not

- Do not treat the DPIA as a form to fill. Boilerplate §3 is
  worse than no DPIA — it signals the risks were not
  considered.
- Do not sign the ADR without the DPO's review. Article
  39(1)(c) names the DPO's advisory role for the DPIA; the
  same partnership applies to the ADR.
- Do not treat "we trained the staff" as a right-to-
  explanation discharge. Training is Article 25-adjacent;
  the Article 22 artefact is the subject-facing record.
- Do not conflate pseudonymised and anonymised. Claiming
  anonymisation on hashed identifiers is a material
  misstatement.
- Do not promise a right-to-explanation that the system
  cannot deliver. If SHAP is not computed per decision, the
  schema cannot promise top-factor explanations.
- Do not forget the erasure path. "Our main database supports
  deletion" is not an Article 17 defence if the model
  memorised the data and the retrieval index still has it.
- Do not commit the solution bundle to this repo; solutions
  belong in the paired `-solutions` repo.
