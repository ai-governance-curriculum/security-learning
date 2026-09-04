# Chapter 02 — Inference-Attack Mitigation for Deployed Models

> **Note on AI-assisted content.** Attack-detector thresholds
> (MI-AUC bands, TPR-at-FPR floors) in this chapter reflect
> conventions in the literature and industry practice; they are
> not universal cutoffs. Verify against the ML-security team's
> current policy and against the most recent primary sources
> before publishing an SLO externally. See
> [`resources.md`](./resources.md).

---

## Why this chapter exists

A deployed model is a query oracle. Every prediction, every
confidence vector, every embedding lookup is one more sample
an attacker can use to draw inferences the deployment did not
intend. Two families of inference attacks matter for the privacy
posture:

- **Membership inference (MI).** Given a query, tell whether
  the query's record was in the training set. Formalised by
  Shokri et al. 2017 (*Membership Inference Attacks Against
  Machine Learning Models*); Yeom et al. 2018; Carlini et al.
  2022 (*Membership Inference Attacks From First Principles*)
  as the modern benchmark method.
- **Attribute inference (AI).** Given partial information
  about a record, predict a sensitive attribute of that record
  using the model as a signal. Related to the classical
  *inversion* attack (Fredrikson et al. 2015) and to
  reconstruction attacks in generative models.

The specific failure mode this chapter is written to prevent:

> A hospital fine-tunes a risk-scoring model on its patient
> cohort. The model is deployed as an internal REST endpoint
> for the clinical-decision-support team. Six months later, a
> researcher shows that querying the endpoint with a candidate
> patient's demographics returns a confidence pattern that
> reveals — with 78% AUC — whether that patient was in the
> fine-tuning cohort. Patients in the cohort had specific
> conditions the model was trained on; membership disclosure is
> attribute disclosure. The hospital shipped one control (mTLS
> to the endpoint) and treated the underlying model as private
> by architecture. No layer stopped the attack — because the
> attack is not a network attack, it is a **statistical**
> attack. The model was the surface.

You leave this chapter able to:

- State the membership- and attribute-inference threat models
  under the two dominant access modes — API/logits and
  text-generation.
- Design a **three-layer defence** — training-time (DP),
  architectural (rate limits, output aggregation, confidence
  hiding, per-caller identity), and monitoring (MI-AUC and
  TPR-at-low-FPR as continuous SLOs).
- Choose the right layer for the risk. DP-SGD is one lever;
  cheap architectural controls close many holes DP-SGD does
  not.
- Instrument the serving layer so a rising MI-AUC produces an
  alert *before* the incident is discovered externally.
- Own the **deployment-review sign-off** that a regulated-data
  model passes before it takes production traffic.

Chapter 01 chose the training-time privacy posture; this
chapter closes the loop at the serving layer.

---

## The threat models — access mode drives the attack

### Attack surface: API with confidence output

The classic scenario. The attacker has query access to the
model, sends candidate records, and reads back a probability
vector (or a distance / embedding). The attacker's goal:

- **MI:** decide whether `x` was in the training set.
- **AI:** decide the sensitive attribute of `x` (e.g. HIV
  status, income bracket, sexual orientation).

Signals the attacker exploits:

- **Confidence gap.** Models are often more confident on
  training examples than on unseen ones. `max(softmax(logits))`
  is higher on members. Yeom et al. 2018's canonical baseline.
- **Loss / logit distribution shape.** The distribution of
  per-example loss under different data augmentations differs
  between members and non-members. The Carlini et al. 2022
  LiRA attack uses this at very low false-positive rates —
  even a small TPR at FPR = 0.001 is a serious leak.
- **Nearest-neighbour effects.** For overparameterised
  regressors, the prediction on a member closely tracks the
  member's label, more so than a nearby non-member.
- **Embedding distance.** For representation models (face,
  voice, embedding-based recommenders), distance in embedding
  space to the query is a membership signal.

### Attack surface: text generation / LLM

The generative equivalent. The attacker prompts the model with
partial context and observes generated continuations. Two
dominant modes:

- **Extraction of memorised training data.** Given a common
  prefix or a strong hint, the model produces a training
  passage verbatim or near-verbatim. Carlini et al. 2021
  (*Extracting Training Data From Large Language Models*)
  demonstrated this at scale.
- **Membership inference on fine-tuning corpora.** For a
  fine-tuned LLM, the attacker probes whether a candidate
  document was in the fine-tuning set. Related to (and more
  practical than) the extraction attack.

The attack surface bleeds into mod-107's OWASP LLM Top 10
(LLM02 — sensitive information disclosure); the mitigation for
memorisation-driven leakage overlaps this chapter's controls.

### Attack surface: embedding / retrieval

Retrievers and embedding services expose top-K neighbours or
raw embeddings. The attacker can:

- **Enumerate the index** — query enough embeddings to
  reconstruct the index content statistically.
- **Reconstruct a member's raw content** from its embedding
  (embedding-inversion attacks; Song and Raghunathan 2020;
  Morris et al. 2023 *Text Embeddings Reveal Almost as Much
  as Text*).
- **Confirm membership** — a query hitting an index entry with
  distance well below the baseline is likely a member.

Retrieval systems ship their own inference-attack surface.
Treat the retrieval store as if it were a small model with its
own MI risk.

---

## The three-layer defence

No single control is sufficient. The layered defence:

- **Training-time (DP).** Chapter 01 sets the budget; mod-106
  chapter 06 configures Opacus. DP-SGD *raises the floor* on
  MI-AUC and reduces memorisation.
- **Architectural.** Serving-side controls that reduce the
  attacker's signal per query and cap the attacker's query
  budget.
- **Monitoring.** Continuous MI-AUC and TPR-at-low-FPR
  measurements against a canary set; alerts when the
  measurements regress; drills on the response runbook.

Each layer closes some attacks and leaves others. The right
combination is chosen from the threat model, not by preference.

---

## Architectural controls — cheap wins DP-SGD does not replace

### Per-user rate limits

The single most effective inference-attack control that does
not require model changes. The dominant attacks require
thousands to hundreds of thousands of queries per victim
record; a per-identity rate limit at the low-hundreds-per-day
range prevents the attack from finishing in a reasonable time,
regardless of how memorising the underlying model is.

Design notes:

- **Rate limit is per-*identity*, not per-*IP*.** Anonymous
  attackers cycle IPs cheaply. The limit is tied to the
  authenticated caller (mod-103 chapter 03 identities). For
  services with a public unauthenticated tier, treat the
  unauthenticated pool as one identity and rate-limit
  aggressively.
- **The limit's shape matters.** A hard daily cap prevents
  extraction over a day; a token-bucket at N/hour with M/day
  burst prevents both burst extraction and slow-drip
  attacks. Choose per data class.
- **Cross-tenant limits are separate from per-user limits.**
  A tenant-wide limit prevents a compromised or malicious
  tenant admin from farming out queries.
- **Retrieval systems get their own limits.** Embedding
  endpoints and top-K endpoints are queryable oracles;
  rate-limit them like inference endpoints.

Rate limits alone do not stop the attack; they slow it. The
combination with monitoring is what makes them a control — the
attack that would have taken 100k queries and finished in an
hour now takes 100 days and rings the MI-AUC monitor on the
way.

### Output aggregation

The attacker's per-query signal often lives in the *precise*
value of the confidence, the loss, or the embedding. Rounding,
bucketing, or top-K restriction reduces that signal.

Common patterns:

- **Argmax only.** Return the top class label; do not return
  the probability vector. Effective; kills a lot of the MI
  literature's attacks. Sometimes unacceptable — clinicians,
  underwriters, and calibration-dependent downstream systems
  need probabilities.
- **Rounded confidence.** Return probability rounded to a
  fixed number of digits (e.g. two decimal places). Cheap;
  reduces but does not eliminate the signal.
- **Top-K only.** Return only the top-K labels with
  probabilities; drop the tail. Effective for large label
  sets.
- **Aggregated over K nearest queries.** For continuous /
  streaming systems, return only aggregates over K recent
  queries — a rolling average, a quantile — not per-query
  outputs. Rare but very effective; requires product buy-in.
- **Coarse binning of embeddings.** For embedding APIs, return
  a hash / quantised embedding rather than the raw vector.
  Retrieval quality degrades — a design decision.

The trade-off is real. Bucketing calibrations makes
downstream calibration-critical consumers unhappy. The choice
is a product decision informed by the threat model.

### Confidence hiding and calibration masking

Even without full aggregation, several targeted controls close
specific attacks:

- **Temperature scaling on output.** A calibrated softmax
  (temperature > 1) flattens the confidence peak; the member /
  non-member confidence gap narrows. Cheap; combines well with
  argmax + confidence output.
- **Random noise on confidence.** Add small Gaussian noise to
  the returned confidences (post-softmax). Not the same as
  DP-SGD; it is output perturbation. Modest effectiveness
  against high-precision attacks; low cost.
- **Threshold-only decisions.** For binary decisions, return
  only "positive / negative / uncertain" rather than a
  probability. Kills a lot of MI signal; sometimes
  unacceptable to downstream users.

### Per-caller identity and query auditing

Every inference-attack detector requires knowing who queried
what, when. Without identity, the detector is per-IP, which is
weak.

Requirements:

- Every inference call has a **caller identity** (mod-103) and
  a **request identity** (uuid).
- Every inference call logs the identity, the timestamp, a
  content fingerprint (hash of input, or a lower-entropy
  representation like binned features), and the returned
  aggregate.
- The audit log is queryable per identity — "show all queries
  from identity X in the last hour" — as the MI-monitor's
  input.

The audit log carries privacy implications of its own —
raw queries may contain PII; the log itself is subject to
retention limits (chapter 05). Store fingerprints, not full
prompts, where possible; encrypt the log at rest.

### For LLMs: memorisation controls

Text-generation surface controls specific to LLM leakage:

- **Deduplication of training data.** Duplicate documents are
  much more likely to be memorised. Aggressive
  deduplication (byte-level and near-duplicate) reduces
  memorisation without touching the model.
- **Perplexity-based output filtering.** Very-high-perplexity
  outputs (i.e., outputs the model is unusually confident of)
  correlate with memorised training text. A serving-side
  filter that flags or blocks very-low-loss generations
  catches many extraction attempts.
- **Prompt-based extraction detection.** Prompts of the form
  "continue the following text: <first 30 tokens of a known
  document>" have a recognisable shape; input-side detectors
  can flag them.
- **Output DLP.** Regex or ML-based detectors that flag PII
  patterns in outputs (SSN, credit card, email format).
  Presidio (chapter 03) or equivalent.
- **Watermarking.** Cryptographic watermarking of generated
  text (Kirchenbauer et al. 2023) does not prevent
  extraction but supports attribution and downstream
  detection.

### Retrieval-store controls

For RAG systems:

- **Row-level access control on retrieval.** Every retrieval
  hit passes a per-caller ACL check before returning; queries
  from user A never return documents scoped to user B.
  Reduces attribute-inference by enforcing that only records
  the caller may see are ever returned.
- **Retrieval-time confidence hiding.** Return only the
  retrieved *content*, not the raw distance / similarity
  score. Distance is a strong MI signal.
- **Retrieval-index hygiene.** DLP the retrieval store on
  ingest (chapter 03). PII in the index is PII in every
  answer the retrieval powers.

---

## Monitoring — MI-AUC and TPR-at-low-FPR as continuous SLOs

The training-time bound (DP-SGD's `ε`) is loose in practice.
Empirical MI-AUC is often lower — sometimes much lower — than
the theoretical bound predicts. The number that matters for
operations is the *measured* one; measure it continuously.

### The MI-AUC canary set

- **Fix a canary set.** A held-out set constructed at training
  time: a members set (records that were in the training data)
  and a non-members set (records that were not, drawn from the
  same distribution). Both sets have known ground truth.
- **Measure MI-AUC per release.** Run the current attack
  benchmark (LiRA is the modern default) against the deployed
  model on the canary set. Report the AUC.
- **Measure TPR at low FPR.** AUC alone hides the tail — a
  model with `AUC = 0.55` can still allow high-confidence
  membership determination for a specific subset (Carlini et
  al. 2022 shows this). Report `TPR @ FPR = 10^-3` and
  `TPR @ FPR = 10^-2` as separate SLOs.
- **Alert on regression.** MI-AUC increases (worsens) between
  releases, or `TPR @ low FPR` increases, are alerts. Route
  to the ML platform on-call.

Suggested SLO bands (adjust to the data-class tier):

| Tier | Target MI-AUC | Target TPR @ FPR=10^-3 | Escalation |
| --- | --- | --- | --- |
| Public / internal | Advisory only | Advisory only | Log only |
| Personal-low | ≤ 0.60 | ≤ 0.02 | Alert on regression |
| Personal-moderate | ≤ 0.55 | ≤ 0.01 | Alert on regression; block release if breached |
| Personal-sensitive | ≤ 0.52 | ≤ 0.005 | Block release; escalate to DPO |
| Special-category | ≤ 0.51 | ≤ 0.002 | Do not ship without additional review |

These are starting points, not compliance thresholds. Tighten
per the org's tier map. The exact numbers should be pinned in
the tier map (chapter 01) alongside the training-time `ε`
band.

### Attribute-inference monitoring

Membership monitoring is well-established; attribute-inference
monitoring is less so but should exist for models on
sensitive-attribute data:

- **Sensitive-attribute reconstruction canary.** A held-out set
  of records with a known sensitive attribute. Run an
  attribute-inference attack (train a small model on the
  target model's outputs; measure its accuracy on the canary
  set for the sensitive attribute). Report the accuracy.
- **Alert on regression.** As above.

Note that a *high* attribute-inference score is not always
attributable to the model — the population-level correlation
may be recoverable from any similar model, DP or not. The
metric that matters is the *difference* between what an
attacker can infer with model access and what they can infer
without it. Design the canary so the delta is measurable.

### Runtime detectors

For live serving traffic (not just the canary), two detectors
are worth wiring:

- **Per-identity query volume + entropy.** An identity issuing
  many queries in a narrow region of the input space is a
  suspicious pattern (extraction, MI, or attribute-inference
  farming). PRADA (Juuti et al. 2019) is a reference pattern;
  simple entropy-based detectors catch many cases.
- **Distributional drift on inputs.** If an identity's input
  distribution suddenly narrows or moves far from historical
  baseline, flag. Not privacy-specific, but a useful cross-
  cutting signal.

Detector output routes into the incident-severity ladder
(mod-107 chapter 05 for LLM systems, mod-111 more generally).

---

## Deployment-review sign-off — what a regulated-data model passes

The deployment review is the analogue to chapter 01's
training-plan review. Before a model on personal or regulated
data takes production traffic, it passes this review. The
sign-off packet:

```markdown
# Deployment-review packet — <model>, <version>

## 1. Model identity
- Data class trained on: <from chapter 01 packet>.
- `(ε, δ)`: <or "not DP" with reason>.
- Model-card link: <path>.

## 2. Threat model
- Access mode: <API/logits | text-generation | retrieval>.
- Attacker profile: <external anonymous | authenticated
  tenant user | insider tenant admin | joint attacker>.
- Assets at risk: <membership | attribute | verbatim training
  data | index contents>.

## 3. Architectural controls (this chapter)
- Rate limit: <per-identity value; per-tenant value>.
- Output aggregation: <argmax | top-K | rounded | full
  vector>. Rationale for the choice.
- Confidence hiding: <temperature | noise | none>. Rationale.
- Per-caller identity: <mod-103 identity primitive>.
- Query audit: <log location; retention; fingerprint scheme>.

## 4. Monitoring (this chapter)
- MI-AUC canary set: <path; sizes>.
- MI-AUC target and current value: <e.g. ≤ 0.55; measured
  0.53>.
- TPR @ FPR=10^-3 target and current value: <e.g. ≤ 0.01;
  measured 0.007>.
- Attribute-inference canary (if applicable): <path; metric;
  current value>.
- Runtime detectors: <per-identity entropy; input-drift>.
- Alert routing: <destination>.

## 5. LLM-specific (if applicable)
- Training-data deduplication: <run; hash-based; retain
  fraction>.
- Output DLP: <Presidio profile; per-entity coverage>.
- Extraction detector: <perplexity-based; input-shape-based>.
- Watermarking: <yes / no / experiment>.

## 6. Retrieval-specific (if applicable)
- Row-level ACL: <yes / no; enforcement point>.
- Distance / score returned: <yes / no; rationale>.
- Ingest DLP: <chapter 03 profile>.

## 7. Companion controls
- Storage encryption: <mod-105 KMS>.
- Transport: <mod-103 mTLS + workload identity>.
- Access control: <mod-103>.

## 8. Sign-off
- ML platform on-call representative: <name>, <date>.
- Product owner: <name>, <date>.
- DPO / privacy lead: <name>, <date>.
- Security lead: <name>, <date>.
- (For HIPAA data:) Security Officer per §164.308(a)(2):
  <name>, <date>.
```

The packet is version-controlled. Retraining under the same
architectural posture reuses the packet (re-measures MI-AUC
against the new checkpoint); a change in access mode, aggregation
policy, or attacker profile triggers a fresh review.

---

## What DP-SGD alone leaves behind

DP-SGD reduces MI risk from the *trained model*. It does not
address:

- **Retrieval-index leakage.** The RAG store is a separate
  privacy surface; DP-SGD does nothing for it.
- **Prompt / trajectory logging.** Chapter 03 owns.
- **Overfitting on a public / non-DP fine-tune of a DP-trained
  base.** The DP guarantee is lost.
- **Attribute inference driven by *population-level*
  correlation.** The model learned a real association between
  demographic and outcome; a query on a member's demographic
  will produce the outcome regardless of DP. Attribute
  inference requires re-examining whether the model *should
  have been trained on that data at all*.
- **The confidence signal that survived the noise.** DP-SGD
  reduces the gap; architectural aggregation kills what
  remains.
- **Slow-drip extraction from an LLM.** DP-SGD reduces
  memorisation; deduplication, perplexity filtering, and
  output DLP address the specific extraction attempts.

The pattern that fails: shipping DP-SGD as the *only* privacy
control. The pattern that works: DP-SGD reduces the training-
time floor; architectural controls block the cheap attacks;
monitoring catches the ones that still land.

---

## Standard failure modes

- **Rate limit per-IP only.** Attackers cycle IPs; the limit
  does nothing. Fix: rate limit per authenticated identity.
- **Full probability vector returned "for calibration".** The
  MI signal is in the vector. Fix: publish the calibration
  policy; return rounded or top-K by default; expose the full
  vector only to explicitly-authorised internal callers.
- **No canary set.** MI-AUC unmeasured; the SLO cannot be
  enforced. Fix: canary is a required artefact at
  release-gate.
- **AUC-only reporting.** `AUC = 0.55` looks fine; the tail is
  hidden. Fix: TPR @ FPR = 10^-3 reported alongside.
- **Attribute-inference not measured.** MI is measured; the
  attack the users are actually worried about is not.
  Fix: attribute-inference canary for sensitive-attribute
  models.
- **Retrieval store treated as passive storage.** RAG index
  MI-risk is separate; nobody measures it. Fix: retrieval
  systems get canaries too.
- **Monitor alerts land in an unwatched channel.** MI-AUC
  regressed; nobody responded. Fix: alerts route to the ML
  platform on-call; response SLA is written.
- **LLM extraction detector "we'll add later".** Training-data
  extraction has landed as an actual incident at multiple
  orgs; "later" is too late. Fix: perplexity filter and
  input-shape detector are ship-blockers for LLMs on
  regulated fine-tuning data.
- **Query audit disabled for privacy reasons.** No audit → no
  detection. Fix: fingerprint the query, not the full input;
  encrypt the log; retain per policy; log the *existence* of
  every query.
- **Sign-off packet becomes a wiki page nobody reads.**
  Fix: the packet is a pull-request artefact; the review is a
  named approval step in the release pipeline.

---

## The mistakes this chapter is trying to prevent

- **Confusing "the model was trained with DP" with "the model
  is inference-attack-safe".** Two different claims; both
  matter; only one is common. This chapter is the second.
- **Waiting for a demonstrated attack before shipping the
  monitor.** Inference attacks are not exotic; the tools are
  freely available (opacus, TensorFlow Privacy, Meta Private
  ML, ML Privacy Meter). Adversaries will run them; measure
  first.
- **Treating attribute inference as "not our problem".** The
  attribute the model exposes is often the one the deployment
  is *for* — the risk score, the eligibility flag, the
  category. Its exposure to inference is the point of
  paranoia.
- **Cost-cutting on the query audit.** No audit → no
  detection → no incident evidence → no defence in a
  regulator conversation. The audit is not optional.
- **Assuming rate limits do enough.** Rate limits + argmax +
  MI monitor is a system; any single control on its own is
  weaker than an attacker.

---

## Summary

- Deployed models are query oracles. Two attack families —
  **membership inference** and **attribute inference** — are
  the privacy attacks the serving layer must resist. LLM
  systems add **training-data extraction** as a third.
- The defence is **three-layered**: training-time (DP-SGD
  from chapter 01), architectural (rate limits, output
  aggregation, confidence hiding, per-caller identity), and
  monitoring (MI-AUC and TPR-at-low-FPR as continuous SLOs).
- Cheap architectural controls — per-identity rate limits,
  argmax-only responses, confidence rounding, top-K
  restriction — close many attacks DP-SGD does not. Choose
  the aggregation policy from the threat model, not from
  convenience.
- The monitor is the SLO. A canary set of known members and
  non-members runs the current attack benchmark (LiRA) per
  release; MI-AUC and TPR-at-low-FPR both feed the release
  gate.
- LLMs need memorisation-specific controls: training-data
  deduplication, perplexity-based output filtering, input-
  shape detectors, output DLP, watermarking where useful.
- Retrieval systems have their own MI surface (embedding
  inversion, index enumeration) and their own controls
  (row-level ACL, distance hiding, ingest DLP).
- The **deployment-review packet** — threat model,
  architectural controls, monitoring configuration, sign-off
  — is the artefact a governance auditor is handed for a
  regulated-data model. Retrainings reuse it; access-mode
  changes require a fresh review.
