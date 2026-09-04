# Chapter 01 — Choosing the DP-SGD Budget

> **Note on AI-assisted content.** Regulator-facing privacy
> claims must be reviewed by counsel before external use. This
> chapter names concrete `(ε, δ)` ranges that show up in the
> literature and in industry practice; they are guidance, not
> compliance certifications. Verify against primary sources and
> the org's DPO / legal team before quoting a specific number
> to an auditor. See [`resources.md`](./resources.md).

---

## Why this chapter exists

mod-106 chapter 06 answered the *how* of DP-SGD: how to wrap a
training loop with Opacus, how to pick an accountant, how to
report the run on the model card. This chapter answers the
question that comes before that one and the question that comes
after:

- Before: *what `(ε, δ)` should this training run target, and
  why?*
- After: *once the run finishes, who signs off that the utility
  cost is acceptable, and how is the sign-off recorded?*

The specific failure mode this chapter is written to prevent:

> A team decides they should "add DP" to their model. They pick
> `ε = 8` because it appeared in a paper they read. Training
> completes; the model card lists `(ε = 8, δ = 1e-5)`. Six
> months later, a customer's counsel asks what "`ε = 8`" means
> for that customer's records. The team cannot answer, because
> nobody stated what a "record" is; nor can they explain why
> `ε = 8` rather than `1` or `4`; nor is there any record of a
> stakeholder — DPO, legal, product — signing off that the
> utility drop was acceptable. The number was picked; the claim
> is unfalsifiable and undefended.

The `(ε, δ)` on a model card is a policy claim. A policy claim
without a written justification, a named record definition, and
a named sign-off is regulatory theatre. This chapter is the
scaffolding that turns the number into a defensible decision.

You leave this chapter able to:

- Define the "record" the budget is denominated in — user,
  session, document, labelled example — and argue the choice.
- Place a proposed training run on a **tier map** from data
  classification to permissible `(ε, δ)` ranges, and defend the
  placement.
- Structure the **utility-vs-privacy** conversation with the
  product owner so the trade-off is negotiated once, in
  writing, rather than re-litigated per release.
- Own the **composition budget** — retraining cadence,
  fine-tuning cost, hyperparameter tuning cost — as a
  first-class part of the plan, not an afterthought.
- Produce the **privacy-review-board decision packet** that
  precedes the training run and is retained as evidence.

---

## What a DP-SGD budget actually claims

The `(ε, δ)`-differential-privacy guarantee (as instantiated by
DP-SGD; see mod-106 chapter 06 for the algorithm) is a bound on
the *influence one record can have on any observable outcome of
the training procedure*. In engineer-usable form:

> Adding, removing, or changing one record in the training set
> changes the probability of any downstream observation an
> attacker can make (a prediction, a confidence, a probability
> vector, an embedding lookup, a generated string) by a factor
> of at most `e^ε`, except with probability at most `δ`.

Three properties of this claim that drive the budget
conversation:

- **It is per-record.** Two records get two applications of the
  budget. A group of `k` records gets a roughly `(k·ε, k·δ)`
  bound (group privacy). If the "record" is a *user* and a user
  has 100 sessions, the budget for their session-level presence
  is much looser than the user-level budget suggests.
- **It bounds influence on the *procedure*, not on
  *inferences*.** DP-SGD says nothing about whether the model
  will learn a distributional fact about the population (male
  patients over 60 have higher heart-attack risk). It protects
  the individual record's *presence*, not distributional
  privacy. This is a common source of misunderstanding.
- **It composes.** Two DP-SGD runs on the same training data
  compose their budgets — a second run at `(ε_2, δ_2)` on the
  same records lands the composed system at (approximately)
  `(ε_1 + ε_2, δ_1 + δ_2)` under basic composition, or a tighter
  bound under advanced composition. Every retraining, fine-tune,
  and hyperparameter sweep touches the composed number.

The budget you choose is the budget you defend, with these three
properties, in the model card and in the DPIA (chapter 04). If
the record is not defined, the number does not mean anything;
if composition is not accounted for, the number decays silently.

---

## Defining the record

The *record* is the unit of protection. In DP-SGD terms, it is
the unit swapped in "adding or removing one record" of the
formal definition. In business terms, it is what the customer
believes is being protected.

Common record choices and their implications:

- **User.** One user's entire history counts as one record. The
  strongest guarantee to promise a person; the hardest to
  achieve because a user's data can be arbitrarily large. Often
  requires grouping all of a user's rows into a single "example"
  or "microbatch" before DP-SGD runs.
- **Session.** One session's data counts as one record. Weaker
  than user-level but easier to hit. Meaningful if a user's
  sessions are effectively independent (recommender for a
  logged-out user; anonymous search sessions).
- **Row / example.** One row in the training table counts as one
  record. The default DP-SGD assumes. Suitable when rows are
  natural units — one labelled image, one document, one
  transaction — and one person cannot easily contribute many
  rows.
- **Document.** One document counts as one record. Common in NLP
  fine-tuning; suitable when documents are drawn from a large
  corpus and single-authorship contribution is bounded.
- **Feature vector.** One assembled training example counts as
  one record. Weakest of the common choices; make sure the
  business claim maps to the technical unit.

The rule: **name the record; name what a user of the system
could contribute to the training data; convince yourself the
technical unit matches the business claim.** If the technical
unit is "row" and one user contributes 10,000 rows, the
user-level protection is `(10000·ε, 10000·δ)` — usually
vacuous. Rebuild the unit or acknowledge the mismatch.

The record definition lands on the model card:

```yaml
privacy:
  guarantee:
    epsilon: 3.0
    delta: 1e-5
    record_definition: "one user's complete session"
```

Every downstream reader (DPIA, model-card audit, DSAR response)
uses this string. Ambiguity here becomes ambiguity everywhere.

---

## The tier map — from data class to permissible budget

Budget selection is a policy conversation, not a per-run
optimisation. The org should have a written tier map from data
classification to permissible `(ε, δ)` ranges, and every
training run should place itself in a tier before Opacus is
touched.

A workable starting template (adapt to the org's data
classification and risk appetite):

| Data class | Example content | Target `ε` band | Notes |
| --- | --- | --- | --- |
| Public / non-sensitive | Wikipedia, open web | DP not required | Cite that DP is not the control for public data |
| Internal, non-personal | Product analytics with no user identifiers | `ε` open, DP optional | Choose based on membership-inference risk (chapter 02) |
| Personal, low-risk | Newsletter subscribers, product usage tied to account | `ε ∈ [4, 10]` | Weak-but-meaningful; require MI-AUC measurement |
| Personal, moderate | Financial transactions, location, behavioural profiles | `ε ∈ [1, 4]` | The common production band for regulated PII |
| Personal, sensitive | Health (PHI), biometric, sexual orientation, political affiliation, minors | `ε ≤ 1` | Strong protection; expect meaningful utility cost |
| Highly sensitive / special-category | HIV status, immigration status, mental-health treatment | `ε ≤ 0.5` or DP-not-sufficient — needs additional controls | Consider training on aggregates, synthetic data, or not training at all |
| Special: model output touches automated legal decisions | Credit, insurance, employment, benefits eligibility | Tier by underlying data class *and* GDPR Art. 22 constraint (chapter 04) | The right-to-explanation view (chapter 04) may drive additional constraints beyond DP |

`δ` in every row: at most `1/N` where `N` is the training-set
size (rule of thumb) and always well below. `δ = 1e-5` is a
common floor for `N` in the millions; `δ = 1e-6` for `N` in the
tens of millions.

The tier map is **org policy**, not a preference. It gets
approved by legal / DPO / security leadership once, versioned,
and referenced by every training-plan proposal. Chapter 04's
DP-by-design ADR captures the tier map. Chapter 05's HIPAA
controls tighten the PHI row of the tier map for covered
entities.

The map has three consumer-facing implications every product
should understand:

- **The band, not the number, is the policy.** A team saying
  "we ship at `ε = 3`" is choosing inside the moderate-PII
  band. A team saying "we ship at `ε = 12`" is asking for a
  policy exception — that requires named executive sign-off
  and a written rationale.
- **Below `ε = 1` is a research question, not a checkbox.**
  Strong DP-SGD on non-trivial models often requires
  architectural work — frozen backbones, transfer from public
  pre-training, careful head selection. Do not promise `ε = 1`
  in a plan before proving it feasible on the actual data.
- **`ε > 10` is not "weak DP" — it is *not DP* in the
  practically meaningful sense.** The bound is too loose to
  make a defensible claim to a regulator. If a team asks for
  `ε > 10`, either the tier is wrong, the record is wrong, or
  the technique is wrong (maybe DP is not what the situation
  needs).

---

## The utility-versus-privacy conversation

The trade-off is real. A DP-SGD run at `ε = 1` on non-trivial
data typically loses 5–20% accuracy against a non-private
baseline. `ε = 8` typically loses 1–5%. Whether either is
acceptable is a **product decision** informed by two engineering
inputs:

- The **non-private baseline** measured on the same evaluation
  set (mod-104 chapter 05).
- The **DP-SGD run** measured on the same evaluation set,
  configured per mod-106 chapter 06.

The conversation is easier if it is structured. A pattern that
works:

1. **State the tier.** From the tier map, the acceptable band
   is `ε ∈ [1, 4]` (say).
2. **Show the utility for three points.** Run the DP-SGD
   experiment at `ε ∈ {1, 2, 4}` (or the appropriate band's
   endpoints and midpoint). Report clean-accuracy delta for
   each.
3. **Show the MI-AUC for three points** (chapter 02). The
   theoretical bound is loose; the empirical membership-
   inference AUC is often what a stakeholder actually cares
   about.
4. **Recommend one.** The person running the training makes a
   written recommendation with rationale.
5. **The product owner and DPO co-sign.** The sign-off names
   the specific `(ε, δ)`, the specific record definition, and
   the utility gap, and states that it is acceptable.

The output is a **decision, in writing, that lives with the
model card**. Retraining under a stable tier and stable data
class reuses the decision (does not re-litigate it); a change in
data class or data volume triggers a new conversation.

Failure mode this pattern prevents: engineers picking `ε` to
"make the utility not drop too much" and legal / product only
seeing the final number. Product should see the *curve*, so the
trade-off is a choice, not a fait accompli.

---

## Composition — the budget is not per-run, it is per-model

Every training run against a given training population spends
budget. The individual runs are budget-compliant; the
composition is often the surprise. A monthly retraining at
`(ε = 3, δ = 1e-5)` for a year is not "`ε = 3`" — under naive
sequential composition, it is `(ε = 36, δ = 1.2e-4)`. Under
tighter advanced-composition bounds (Kairouz et al.,
Renyi-DP-based accounting), the composed `ε` is smaller but
still much larger than the per-run value.

Choices for keeping the composed budget defensible:

- **Rotate the training data.** If each monthly retraining uses
  a *disjoint* slice (e.g. only new data since the last run),
  the runs do not compose over the same records. This is the
  simplest fix and the easiest to explain to an auditor. It
  requires the training population to actually be disjoint per
  run — verify.
- **Compose and re-target.** If the same underlying records
  are retrained on, budget the whole yearly programme and set
  the per-run budget so composition stays inside the yearly
  target. E.g. yearly target `ε = 5` over 12 retrainings →
  per-run `ε ≈ 0.4` under sequential composition (or a slightly
  looser per-run under advanced composition).
- **Freeze old checkpoints out of composition.** If old
  checkpoints are archived and no longer served, they still
  compose in the theoretical bound (an attacker could
  potentially query them). Operationally, if checkpoints are
  deleted and unrecoverable, the composed exposure is reduced;
  document the retention policy alongside the budget.
- **Split the guarantee by cohort.** Some techniques (per-user
  budgeting via user-level DP) let the org state
  "each user contributes to at most K retrainings" and bound
  the per-user composed budget explicitly. Advanced.

**Hyperparameter tuning composes too.** Every DP-SGD run for
hyperparameter search technically spends budget on the same
records. Common industry practice:

- **Tune on a proxy dataset** (public or synthetic) and run
  DP-SGD only for the final production model. State this on
  the model card.
- **Tune on a private held-out slice** that is not shared with
  the training slice. This is not free — the held-out slice's
  budget is spent — but it isolates the leakage.
- **Use a private selection method** (exponential mechanism
  over the hyperparameter grid) and account for the selection
  cost. Correct but rarely implemented.

The DPIA (chapter 04) and the model card both state the
composition plan. A plan that says "we retrain monthly and
compose naively" is a plan; a plan that says "we retrain
monthly with no accounting" is missing the plan.

---

## What DP-SGD does and does not cover

DP-SGD bounds record-level leakage from the *trained model*
weights. That is a real and important property. It is also
narrower than "the training data is private". The other privacy
surfaces:

- **Training-data storage.** Files at rest on disk, in object
  stores, in feature stores. Chapter 05 (HIPAA) and mod-105
  (secrets and key management) own storage encryption and
  access control.
- **Training-data transit.** In-flight between systems. mod-103
  chapter 03 (workload identity + mTLS) owns transport.
- **Training-time compromise.** The training environment
  itself — the GPU cluster, the training container — has
  access to raw data. DP-SGD bounds what leaks *into the model*
  from that environment; it does not defend the environment.
  mod-103 owns compute isolation.
- **Serving-side extraction.** A model can leak training data
  under text-based queries (LLM memorisation) or under
  membership-inference queries (chapter 02). DP-SGD raises the
  bar; it does not eliminate the risk.
- **Prompt / input logging.** Inputs to the deployed system are
  their own data — chapter 03 (PII/PHI DLP) covers.
- **Model-output data.** Confidence vectors, embeddings, and
  logits leak information about training data even from a
  DP-SGD model (weakly, but non-zero). Chapter 02's
  architectural controls (output aggregation, confidence
  hiding) close what DP-SGD leaves.
- **Downstream use.** A model trained with DP-SGD, then
  fine-tuned without DP on a non-private dataset, loses the
  guarantee entirely. State this on the model card and enforce
  at the platform level.

The tier map above should carry a note per row: *DP-SGD is one
control in the tier's control set; the row's full control set
includes storage encryption, access control, logging DLP, and
so on.* DP-SGD is not the privacy programme; the privacy
programme has DP-SGD in it.

---

## The privacy-review-board decision packet

Every training run against personal or regulated data should
land at a privacy-review board (or an equivalent function — the
DPO's approval flow, the compliance team's registration
process) before Opacus is called. The decision packet is the
input to that review.

A workable packet (Markdown; ~2 pages):

```markdown
# Privacy-review packet — <model name>, <version>

## 1. Data
- Data classification: <public | internal | personal-low |
  personal-moderate | personal-sensitive | special-category>.
- Population: <who the training records describe>.
- Volume: <number of records; number of distinct data subjects>.
- Provenance: <link to mod-104 lineage record>.

## 2. Record definition
- Technical unit: <row | session | user | document>.
- Business unit: <one person's <session | complete history>>.
- Mapping argument: <why the technical unit maps to the
  business claim; per-user row-count distribution>.

## 3. Budget tier and target
- Tier from map: <moderate-personal>.
- Target `(ε, δ)`: <ε = 3.0, δ = 1e-5>.
- Justification: <inside the tier's permissible band;
  utility at the band's tighter endpoints unacceptable
  per Deliverable 4>.

## 4. Utility experiment
- Baseline (non-private): <clean-accuracy on eval>.
- Runs at `ε ∈ {1, 2, 4}`: <table>.
- Chosen `ε`: <3.0 (midpoint; ~2% utility gap)>.
- MI-AUC at chosen `ε`: <value; delta vs baseline>.

## 5. Composition plan
- Retraining cadence: <monthly>.
- Training-data rotation policy: <fully rotated | overlap N>.
- Composed 12-month `(ε, δ)`: <computed value>.
- Fine-tuning plan: <none | further DP | no downstream non-
  private tune permitted per platform policy>.
- Hyperparameter tuning: <on proxy / held-out / private
  selection>.

## 6. Companion controls
- Storage: <mod-105 KMS + at-rest encryption>.
- Serving-side: <chapter 02 rate limits, output aggregation,
  MI-AUC monitor>.
- DLP on ingest: <chapter 03; per-entity coverage>.
- Access control: <mod-103 identities>.

## 7. Sign-off
- Recommending engineer: <name>, <date>.
- Product owner: <name>, <date>.
- DPO / privacy lead: <name>, <date>.
- Security lead (if applicable): <name>, <date>.

## 8. Evidence pointers
- Training-plan config: <path>.
- Utility measurement notebook: <path>.
- MI-AUC report: <path>.
- Model-card privacy section: <path>.
- DPIA reference: <path per chapter 04>.
```

The packet is version-controlled alongside the model. Changes
to the tier, the target, the composition plan, or the utility
gap require a new packet (or a diff review, depending on
severity). The packet is what a governance auditor (mod-109),
a regulator investigation, or a customer's counsel is handed.

---

## When DP-SGD is not the right control

Not every privacy problem is a DP-SGD problem. Recognise the
patterns:

- **The training population is small.** DP-SGD on tens of
  thousands of records rarely produces both a defensible `ε`
  and a usable model. Consider: training on aggregated
  statistics; using synthetic data; using a public pre-trained
  model with light fine-tuning; not training the model at all.
- **The population is very asymmetric.** If one user
  contributes 90% of the data, protecting "a record" is
  meaningless. Redefine the record or restructure the data.
- **The model is a lookup table.** Nearest-neighbour models,
  memorising retrievers, and small-corpus RAG systems do not
  benefit from DP-SGD; the leakage is at the retrieval / index
  layer, not the training layer. Use retrieval-side DLP and
  access controls instead.
- **The threat is not membership.** If the concern is
  "someone will guess Alice's cancer status from the model's
  output on an inference for Alice", the attack is *attribute
  inference*, not membership. DP-SGD helps but is not the
  primary control — chapter 02 discusses the layered defence.
- **The regulator requires *purpose limitation*, not
  *statistical privacy*.** If Article 5(1)(b) (GDPR purpose
  limitation) is what is being invoked, the answer is to not
  train the model on that data; DP-SGD does not solve a
  purpose-limitation violation.
- **The record definition cannot be nailed down.** If reviewers
  cannot agree what a record is, DP is not the right tool
  yet. Fix the data model before adding noise.

The tier map should carry an escape hatch row for cases where
DP is not the answer: *this tier requires additional or
alternative controls (see chapter 02 / 03 / 05)*.

---

## Standard failure modes

- **`(ε, δ)` on the model card with no record definition.** The
  most common failure mode. Fix: record definition is a
  required field on every model card that claims DP.
- **`ε > 10` labelled "differentially private".** The
  guarantee is close to vacuous; the label is misleading. Fix:
  the tier map's `ε > 10` row is "not DP" or "DP with caveat";
  the model card either states the caveat prominently or does
  not label as DP.
- **Composition ignored.** Monthly retrainings under the same
  per-run `ε` are treated as if the model is `ε`-DP; the
  composed system is not. Fix: composition plan is a required
  field.
- **Utility gap discovered at the last minute.** DP-SGD run for
  the first time at release-gate; the team scrambles.
  Fix: DP-SGD experiment happens at training-plan approval,
  not at release.
- **DPO signs off without seeing the record definition.** The
  sign-off is a signature on a claim that is not what the DPO
  understood. Fix: the decision packet's Section 2 is required
  reading for sign-off.
- **Hyperparameter tuning eats the budget silently.** The
  reported `(ε, δ)` is per-run, but the search that produced
  the hyperparameters consumed additional budget.
  Fix: state the tuning approach; use proxy / held-out /
  private selection.
- **Fine-tune-without-DP after DP-SGD pretrain.** The DP
  guarantee is lost the moment a non-private fine-tune runs on
  the same records. Fix: the platform blocks non-DP fine-tuning
  on a DP-trained model; the model card states the
  restriction.
- **Group privacy ignored.** The claim is per-record but the
  business claim is per-family / per-household / per-tenant.
  Fix: state the group size and the group-level budget in the
  packet.
- **Non-private baseline missing.** No utility comparison
  possible; the utility gap is unknowable. Fix: non-private
  baseline is a required deliverable of the training-plan
  approval.
- **Tier map is not written down.** Every training team invents
  its own budget. Fix: the tier map is org policy, versioned,
  and pointed at from every training-plan template.

---

## The mistakes this chapter is trying to prevent

- **The "we added noise" pattern.** Configuring Opacus is not
  the same as running a defensible privacy programme. The
  configuration is one line in a longer story.
- **The unowned budget.** No named human owns the choice; the
  training pipeline defaults it; nobody can defend it.
- **Tier drift.** Personal-sensitive data trained at a
  moderate-tier budget because "we always used `ε = 4`".
- **Reflexive tightening.** Every year the target `ε` gets
  smaller because someone read a paper; the utility falls
  monotonically until the model is unshippable. The tier map
  is the discipline against ratchet.
- **Composition denial.** "We retrain monthly but we always
  say `ε = 3`". Regulators noticed this pattern years ago; it
  is not a defence.
- **DPO as a rubber stamp.** The sign-off is meaningful only if
  it is informed. The decision packet is what makes it
  informable.

---

## Summary

- The **`(ε, δ)`** on the model card is a claim about a
  **specific record** being protected against **specific
  observations**. Missing the record definition makes the
  number meaningless.
- The org owns a **tier map** from data classification to
  permissible `(ε, δ)` bands. Each training run places itself
  in a tier and defends the placement.
- The **utility-vs-privacy trade-off** is a product decision
  informed by measured curves — non-private baseline, DP-SGD
  at three points, MI-AUC per point — and co-signed by the
  product owner and the DPO. The decision is written down and
  reused.
- **Composition** is a first-class concern. Retraining
  cadence, hyperparameter tuning, and fine-tuning all consume
  the composed budget. The plan states which. Rotate the
  training data, tighten the per-run budget, or account
  explicitly.
- **DP-SGD is one control, not the privacy programme.** The
  storage layer, the serving layer (chapter 02), the DLP layer
  (chapter 03), the compliance layer (chapters 04, 05) all
  ship together.
- The **privacy-review-board decision packet** — data class,
  record definition, budget, utility experiment, composition
  plan, companion controls, sign-off — is the artefact this
  chapter produces. It is what a regulator, a customer, or a
  new team lead is handed to understand the decision.
- Not every problem is a DP-SGD problem. Small populations,
  asymmetric contributions, attribute-inference threats, and
  purpose-limitation violations need different controls; the
  tier map has an escape hatch for them.
