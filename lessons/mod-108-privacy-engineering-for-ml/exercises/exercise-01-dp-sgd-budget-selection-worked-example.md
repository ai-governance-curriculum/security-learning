# Exercise 01 — DP-SGD Budget Selection Worked Example

**Estimated effort:** ~3 hours
**Deliverable:** A committed budget-selection bundle for one
concrete training use case, consisting of (a) a filled-in
privacy-review-board decision packet following the chapter-01
template, (b) a short record-definition memo that argues why the
chosen technical unit matches the business claim, (c) a utility-
vs-privacy curve measured at three `ε` points in the tier's
permissible band, (d) a composition plan covering retraining
cadence and hyperparameter tuning, and (e) a plain-language
rationale paragraph the DPO / product owner can sign.
**Prerequisites:** Chapter 01 read end-to-end. mod-106 chapter
06 (DP-SGD with Opacus) and mod-106 exercise 05 at least
skimmed, so the Opacus configuration surface is familiar.
Access to one target model — a classifier, a recommender, or a
fine-tune — whose training data is on real personal data (or a
realistic analogue) and whose training loop can be run at least
three times at different noise multipliers.

---

## Objective

Chapter 01's claim is that an `(ε, δ)` on a model card without
a stated record, a tier-map placement, a measured utility
trade-off, and a composition plan is regulatory theatre. This
exercise is the exercise that turns the claim into a committed,
signed artefact for one real use case.

By the end of this exercise you have:

- A **record definition** — one sentence — that a non-engineer
  can read and understand what is being protected.
- A **tier placement** that cites the org's tier map (or a
  reasonable starter if the org does not have one yet).
- A **three-point utility curve** at `ε ∈ {ε_low, ε_mid, ε_high}`
  from the tier's permissible band, each with clean accuracy
  (or the equivalent production metric) measured on the same
  held-out set.
- A **chosen `(ε, δ)`** that lands inside the tier's band and
  is defended against both tighter and looser alternatives.
- A **composition plan** that is budget-feasible over a stated
  retraining horizon.
- A **privacy-review-board decision packet** that the DPO,
  product owner, and security lead can sign.

You are not shipping a DP-SGD training; you are shipping the
*decision* that precedes it. The run itself is mod-106
exercise 05. This exercise is what should happen before that
exercise ever gets scheduled.

---

## Problem statement

Pick one concrete training use case. Preferably one that is
real for the org you work with; failing that, a clearly-scoped
hypothetical with a plausible dataset shape. Candidates:

- A fine-tune of a classifier on customer-support tickets with
  free-text content.
- A fine-tune of a small LLM on internal product documentation
  that includes customer identifiers.
- A recommender trained on a logged-in user's clickstream.
- A risk-scoring model trained on financial-transaction records.
- A triage model trained on patient-reported symptoms (PHI; use
  only if a HIPAA / de-identified analogue is available).
- A face / voice embedding model trained on consented biometric
  samples.

Whatever you pick, by the end of this exercise you must be able
to state:

- What the training data contains, where it came from, and how
  many distinct data subjects it covers.
- The data classification per the org's catalogue (public /
  internal / personal-low / personal-moderate / personal-
  sensitive / special-category).
- The retraining cadence (one-off, quarterly, monthly, weekly).
- Who the subject-facing stakeholders are (customers, patients,
  tenant employees, regulated-industry counterparties).

If the use case cannot answer these cleanly, pick a different
one — a budget decision on an under-defined use case is a
decision you cannot defend.

---

## Requirements

### Deliverable A — record-definition memo (half a page)

A short memo that names:

1. **Technical unit.** Row / example / session / user /
   document / feature vector. Pick one.
2. **Business unit.** What one record *means* to a human
   reader — "one patient's clinic visit", "one user's complete
   browsing history", "one labelled ticket".
3. **Mapping argument.** The per-subject contribution
   distribution — if the technical unit is "row" and one user
   contributes 10,000 rows, state it and name the implied
   group-privacy cost. If the technical unit is "user" and
   you plan to microbatch all of a user's rows, state the
   microbatching recipe.
4. **Edge cases.** Users with no rows, users with one row,
   users who contribute across cohorts, synthetic / seeded
   rows. Each gets a one-line answer.

The memo lands as Section 2 of the decision packet below.

### Deliverable B — tier placement

A one-page section that:

- Cites the org's tier map (or the chapter-01 starter table if
  no org tier map yet exists — in which case flag that the
  starter is provisional).
- Argues the tier placement from the data classification —
  "patient-reported symptoms with linkable identifiers →
  personal-sensitive → `ε ≤ 1`".
- Names any adjacent tiers the use case flirts with (e.g.
  "features include financial-transaction amounts bucketed at
  £5k resolution — not special-category but close") and
  explains why the chosen tier is correct.
- Names any `δ` floor derived from the training-set size
  (rule of thumb: `δ ≤ 1/N`, usually well below).

### Deliverable C — three-point utility curve

An actual measurement, not a projection. Run the DP-SGD training
three times at `ε ∈ {ε_low, ε_mid, ε_high}` corresponding to the
tier's permissible band endpoints and midpoint. For each run:

- Same training-data snapshot (hashed).
- Same model architecture.
- Same evaluation set (hashed, held out, consistent across
  runs and against any prior non-private baseline).
- Same accountant (named — PRV preferred where supported;
  otherwise RDP). State the Opacus version.
- Report: clean accuracy (or the production metric), class-
  balanced accuracy if imbalance matters, training wall-clock,
  and (if the model has a membership-inference monitor from
  mod-106 exercise 04 or chapter 02) the measured MI-AUC and
  TPR @ FPR = 10⁻³.

A rendered table:

| `ε` | `δ` | Noise multiplier | Clean accuracy | Δ vs non-private | MI-AUC | TPR@FPR=10⁻³ |
| --- | --- | --- | --- | --- | --- | --- |
| ε_low  | | | | | | |
| ε_mid  | | | | | | |
| ε_high | | | | | | |
| non-private baseline | n/a | n/a | | 0 | | |

If running three full trainings is infeasible for the target
model, run short-training variants (reduced epochs, consistent
across the three points) and label the table as a *short-run*
curve. A short-run curve is still a defensible decision input
if the ordering across `ε` is preserved; call this out so the
reviewer is not misled.

### Deliverable D — composition plan

A sub-section that answers, in order:

1. **Retraining cadence.** How often will this model retrain?
   What data is on the next training run — fully-fresh, fully-
   overlapping, partial?
2. **Composition over the horizon.** For `N` retrainings over
   the next 12 months, state the composed `(ε, δ)` under the
   accountant in use (sequential composition is the simple
   upper bound; advanced / RDP composition is tighter — pick
   one and name it). Show the arithmetic.
3. **Per-run cap.** If composition exceeds the tier's band,
   state the per-run cap that keeps the yearly composed `ε`
   inside the tier.
4. **Data-rotation policy.** If each retraining uses disjoint
   data, state the policy. Verify the "disjoint" claim with a
   proposed overlap-detection check.
5. **Hyperparameter / tuning cost.** How was `C`, batch size,
   and `σ` tuned, and did the tuning spend budget on the same
   records? Options and their costs:
   - Tuned on a public proxy (preferred; state it).
   - Tuned on a held-out slice (slice's budget is spent;
     document).
   - Tuned via private selection (correct but rare; cite the
     method).
6. **Fine-tune policy.** State that downstream non-DP fine-tune
   on the same records breaks the guarantee, and name the
   platform control (or policy) that prevents it.

### Deliverable E — the privacy-review-board decision packet

A rendered Markdown document following the chapter-01 template:

1. Data (classification, population, volume, provenance).
2. Record definition (from Deliverable A).
3. Budget tier and target (from Deliverable B; chosen point
   from the curve in Deliverable C).
4. Utility experiment (the curve table + a one-paragraph
   interpretation).
5. Composition plan (from Deliverable D).
6. Companion controls (storage encryption per mod-105; serving
   controls per chapter 02; DLP per chapter 03; access control
   per mod-103).
7. Sign-off block — recommending engineer, product owner, DPO,
   security lead. Signatures may be placeholders in the
   exercise submission, but the sign-off block exists and is
   routable.
8. Evidence pointers — training-plan config path, utility
   notebook path, MI-AUC report path, model-card privacy
   section path, DPIA reference (exercise 04 placeholder is
   fine).

### Deliverable F — plain-language rationale paragraph (~150 words)

One paragraph the DPO / product owner can sign without
unpacking the accountant choice. It states:

- What the chosen number means in business terms ("one
  patient's clinic visit is protected to within `e^1`-factor
  influence on any observation an attacker can make of the
  model").
- Why this number was chosen rather than tighter / looser.
- What utility was given up to earn it (a number from the
  table).
- What *is not* protected (training-data storage, prompt
  logs — companion controls apply).

The paragraph is the readable summary of the whole packet.

---

## Starter guidance

- **Define the record before you touch Opacus.** The record is
  the hardest-to-change decision in the packet; downstream
  configuration descends from it. If the per-subject
  contribution distribution looks awkward (a few users with
  thousands of rows), fix it before running experiments.
- **Pick three `ε` points at the tier band's endpoints and the
  middle.** Not three arbitrary numbers. If the tier says
  `ε ∈ [1, 4]`, pick `{1, 2, 4}`. The curve is more useful if
  the points span the policy range.
- **Reuse the exercise-04 (mod-106) MI-AUC canary set.** The
  utility-vs-privacy conversation is weakest when the only
  axis measured is accuracy. MI-AUC is the privacy axis; add
  it to the curve table.
- **Compose with the actual accountant.** Sequential composition
  of per-run `ε` is the easy upper bound and the easy slide
  deck; the production accounting uses the same accountant
  across runs. State which.
- **Argue against the easy answer.** A `ε = 8` run that gives
  2% utility delta looks appealing. Walk through why that is
  (or is not) the right choice for the tier. The decision
  packet is a defence against the easy-choice failure mode.
- **State what the budget does *not* cover.** The rationale
  paragraph that mentions companion controls is what prevents
  the "DP-SGD was our privacy programme" misreading.

---

## Acceptance criteria

A passing bundle:

- The record is defined, with a mapping argument and edge-case
  answers.
- The tier placement cites a tier map (org's, or chapter 01's
  starter) and defends the placement against adjacent tiers.
- The utility curve has three real measurements at tier-band
  endpoints + middle, on the same eval set, with the accountant
  and Opacus version named.
- The chosen `(ε, δ)` lands inside the tier's band and the
  decision packet argues against both the tighter and the
  looser alternatives from the curve.
- The composition plan states a cadence, computes the composed
  `(ε, δ)` over a stated horizon, and either fits inside the
  tier or specifies the per-run cap / data rotation that would
  make it fit.
- The companion-controls section names at least storage
  (mod-105), serving (chapter 02), DLP (chapter 03), and
  identity (mod-103).
- The sign-off block has routable owners (names of roles if the
  specific people are unknown).
- The plain-language rationale paragraph names the record,
  the chosen number, the utility given up, and what the budget
  does not cover.

A failing bundle:

- An `(ε, δ)` is proposed without a record definition.
- The tier map is not referenced (or the placement cites the
  tier map but is incompatible with the band — e.g. `ε = 6` on
  personal-sensitive data without an exception rationale).
- The utility curve is projected or borrowed from a paper
  rather than measured on this model and this data.
- Composition is treated as "we'll say `ε = 3` and retrain
  monthly" with no composed-horizon math.
- Hyperparameter-tuning cost is not addressed.
- The decision packet reads as the engineer alone signing off;
  the DPO / product-owner block is absent or unrouted.
- The rationale paragraph uses "differential privacy" without
  naming what *this* budget protects *which* record against.

---

## Stretch goals

- **Record-choice ablation.** Produce two decision packets for
  the same use case under two different record definitions
  (row-level vs. user-level), including the microbatching
  recipe and the implied noise multiplier for user-level DP.
  Compare the resulting `(ε, δ)` and utility; argue which is
  the correct policy choice.
- **Composition under advanced accounting.** Compute the
  composed `(ε, δ)` under both sequential and RDP-based
  advanced composition for the stated 12-month horizon.
  Report both; name the one on the packet.
- **Private hyperparameter selection.** Implement an
  exponential-mechanism selection over the `C` grid; account
  for the selection cost; argue whether it is a net gain over
  tuning on a public proxy for your use case.
- **Tier-map drafting.** If the org has no written tier map,
  draft a one-page starter tier map using chapter 01's table
  as the base and the use case's data class as the anchor.
  Walk it through a rehearsal with the DPO and record the
  changes.
- **DP-off vs DP-on business case.** Write a one-page
  stakeholder-facing memo that frames the utility delta as a
  product trade-off: "`ε = 3` costs us ~2% accuracy; the
  alternatives are not training on this data at all, or
  training without DP and taking the regulatory risk." The
  memo makes the decision reversible under new information.
- **Linkage to GDPR Art. 25.** Produce the ADR fragment
  (exercise 04) for *just* the DP-by-design row of this use
  case; make it concrete enough that exercise 04's full ADR
  can slot it in without rework.
- **Composition over imported-model boundaries.** If the use
  case fine-tunes an imported foundation model that was itself
  trained with DP, discuss the composed guarantee (or lack of
  one) and the mod-110 provenance implications.

---

## Do not

- Do not pick an `ε` because a paper used it. The paper's
  record definition and data class may be very different from
  yours.
- Do not report `(ε, δ)` without the accountant name. RDP, PRV,
  and GDP will disagree on the same run.
- Do not sign off on the packet alone. The DPO / product-owner
  block exists because the decision is theirs to make with
  your technical input, not yours to make with their silent
  acquiescence.
- Do not treat the composition section as a formality. The
  single most common post-ship surprise in DP programmes is
  the composed `ε` after a year of retrainings.
- Do not write "DP-SGD is our privacy programme" anywhere in
  the packet. DP-SGD is one row of the companion-controls
  section.
- Do not commit the solution bundle to this repo; solutions
  belong in the paired `-solutions` repo.
