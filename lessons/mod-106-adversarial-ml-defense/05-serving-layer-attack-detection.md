# Chapter 05 — Serving-Layer Attack Detection

> **Note on AI-assisted content.** Vendor rate-limit APIs and
> anti-abuse dashboards change between releases; the reference
> implementations for extraction / inference detection (PRADA,
> ML-Doctor) evolve. Verify current APIs and papers before quoting
> externally. See [`resources.md`](./resources.md).

---

## Why this chapter exists

Chapters 02 and 03 hardened the model against evasion. Chapter 04
hardened the training pipeline against poisoning and backdoors. Two
inference-time families remain unaddressed: **model extraction** and
**membership / attribute inference**. Both operate through the
serving surface — query in, response out — and both live where the
model team is often looking least hard: at the request pattern
rather than the model internals.

The specific failure modes this chapter is written to prevent:

> A vision API charges per prediction. A customer with an unusual
> query pattern — mostly high-entropy grayscale patches submitted
> at 2 QPS around the clock — extracts a functionally-equivalent
> copy of the model over six weeks. The business finds out when a
> competitor's product ships something suspiciously similar. Rate
> limits based on QPS never fired because 2 QPS was within
> policy; the anti-abuse team was looking at fraud patterns, not at
> query similarity.
>
> An underwriting model returns per-record risk scores. A journalist
> discovers that querying "did this specific individual sign up
> during the training window?" and inspecting the confidence lets
> them determine training-set membership with 78% precision — a
> membership-inference attack that becomes a data-subject-rights
> story the day after publication. The team's response is to
> "clip the confidence output"; the underlying leakage remains.

Serving-layer defence has three moving parts:

1. **Query telemetry** rich enough to detect the attack shape.
2. **Detectors** for extraction and inference risk that operate on
   that telemetry.
3. **Response controls** — rate limits, output perturbation,
   confidence hiding, watermarking — that raise the cost of the
   attack when a detector fires.

You leave this chapter able to:

- Design serving-layer telemetry that captures the fields the
  detectors in this chapter need.
- Implement or configure a **query-similarity extraction detector**
  (PRADA-style — Juuti et al. 2019 — and cosine-similarity variants).
- Compute per-model **membership-inference risk** on a held-out set
  and expose it as a monitored metric.
- Choose between rate limiting, output perturbation, and confidence
  hiding as a response control, and understand the tradeoffs.
- Compose these controls with the identity, tenancy, and audit
  primitives from mod-103 (platform architecture) and mod-104
  (lineage).

---

## The telemetry you need to have

Every detector in this chapter runs on structured query events.
The event surface must be present *before* the detector; a
detector wired on top of unstructured proxy access logs is a
best-effort keyword search, not an attack detector.

Minimum per-request fields:

- `request_id`, `timestamp`, `model_id`, `model_version`.
- `identity` — the caller. This is a pointer, not a raw token: an
  API key ID, a workload-identity claim (mod-103), a tenant ID, an
  end-user ID where applicable.
- `input_fingerprint` — a size-bounded, non-reversible summary of
  the input suitable for similarity comparisons. For images:
  perceptual hash + pooled feature-vector. For text: a token
  n-gram signature or an embedding vector. For tabular: a
  quantised feature vector. **Never store the raw PII inputs**;
  the fingerprint is what the detector needs.
- `output_summary` — top-K predicted classes and their
  confidences (if exposed to the caller) or a redacted summary
  (if not).
- `latency_ms`, `error_code`.

Storage guidance:

- Fingerprints and outputs land in a query-audit store separate
  from PII stores. mod-103's tenancy and encryption gates apply.
- Retention: long enough for the slowest detector's window (a
  6-week extraction attack needs ≥ 6 weeks of fingerprints).
- Query rate: expect O(daily_query_volume × 200–500 bytes) —
  storage is manageable with fingerprints, not with raw payloads.

The rest of this chapter assumes this telemetry exists.

---

## Model-extraction detection

### The attack shape

An extraction attacker queries the model with inputs chosen to
maximise the information they extract per query. Two archetypes:

- **Random-query extraction.** Sample inputs from the natural
  distribution (or noise); train a surrogate on the returned
  labels. Cheap; requires many queries; produces a mediocre copy.
- **Adaptive-query extraction.** Choose queries to maximise the
  decision-boundary information (active learning). Fewer queries;
  produces a better copy. Jagielski et al. 2020 characterise the
  regimes for deep networks; the LLM analogue is the
  prompt-based extraction line of work.

Both leave a signature. The signature is **not** query volume in
isolation — a low-QPS attacker over months is a real threat — but a
combination of query volume, **query distribution** unusual for
the identity, and **query-boundary-proximity** patterns.

### Detectors

Three practical detector shapes. Compose them; each catches a
different failure mode.

#### 1. Per-identity distribution drift

Build a baseline distribution of query fingerprints per identity
(or per identity segment: tenant, plan tier, geography). Alert
when an identity's recent distribution diverges from its baseline
by more than a threshold — measured with a distributional distance
(Wasserstein, MMD) over embedded fingerprints.

The failure mode this catches: an identity that historically sends
retail-image queries starts sending high-entropy synthetic
patches. Distribution drift is stark and shows up in days, not
weeks.

#### 2. Query-similarity clustering (PRADA-style)

**PRADA** (Juuti et al. 2019 — *PRADA: Protecting against DNN
Model Stealing Attacks*) formalises an observation: extraction
attackers, especially adaptive ones, tend to submit query batches
whose *pairwise distance distribution* looks unlike natural traffic.
Natural queries cluster; extraction queries fan out to cover the
input space (or, for boundary-probing attacks, cluster tightly
around known decision boundaries).

The detector computes, per identity, the sample distribution of
pairwise fingerprint distances within a rolling window and runs a
Shapiro-Wilk-style normality test (PRADA's original test) or a
distance-distribution KL-divergence against the population
baseline. Flag identities whose distance distribution is a
statistical outlier.

#### 3. Boundary-proximity flags

Compute a lightweight per-request "how close is this input to a
decision boundary" score — for a classifier, the margin between
the top-1 and top-2 predicted logits, or (if you can afford the
compute) the norm of the input-gradient. Aggregate per identity;
alert on identities whose recent traffic has an unusually low
mean margin (attacker probing the boundary) or unusually broad
margin distribution (attacker mapping the model's confidence
landscape).

Boundary-proximity is the strongest signal for adaptive-query
extraction; it also carries a false-positive risk against users
whose legitimate traffic is genuinely at the model's boundary
(edge-case fraud reviewers, adversarial-testing customers). Segment
by customer type before alerting.

### Response controls

When a detector fires, the response menu:

- **Rate-limit escalation.** Reduce the caller's rate limit and
  page a human. Rate-limit windows should be per-identity and
  per-endpoint, not global.
- **Output perturbation.** Return a top-K label list without
  confidences, add controlled noise to confidences, or round to a
  fixed number of significant digits. Reduces the extraction rate
  per query at a small utility cost. See Tramèr et al. 2016 for
  the tradeoff analysis.
- **Query-budget quota.** Cap monthly query volume by plan tier;
  hard-fail beyond the cap and require a human to unlock.
- **Watermarking.** Author outputs so that a downstream surrogate
  trained on them can be identified as a stolen copy. This is
  detection-after-the-fact, not prevention; useful as legal
  evidence, not as a defence.
- **Kill switch.** For a confirmed extraction incident, disable
  the caller's identity and revoke tokens (mod-105 chapter 05).

Do not silently degrade — every defensive action must be a
telemetry event the ops team can audit.

---

## Membership-inference risk monitoring

### The attack shape

Shokri et al. 2017 (*Membership Inference Attacks Against Machine
Learning Models*) established the concrete: a black-box attacker
who queries the target model with candidate inputs and observes
the confidence output can — for many models — decide whether each
input was in the training set with meaningfully-better-than-chance
accuracy. Yeom et al. 2018 sharpened the threat model and showed
that even simple confidence thresholding is a workable attack
against overfit models.

The failure mode is *quiet*: no obvious query pattern gives it
away, because the queries look like normal single predictions.
The signature is on the model itself — how much its confidence
diverges between members and non-members.

### The metric — membership-inference AUC

The industry-standard measurement is:

1. Assemble a held-out set of `N` "members" (in the training set)
   and `N` "non-members" (from the same distribution but held
   out).
2. Query the model on each and record the confidence of the true
   label.
3. Compute the AUC of a binary classifier that predicts
   membership from confidence.

An AUC ≥ 0.7 is a serious leak on a model whose training set
includes PII or protected attributes; AUC ≥ 0.6 is worth
investigating; AUC ≈ 0.5 (chance) means the model does not leak
detectable membership signal on this metric. Newer papers use
low-FPR AUC (`TPR @ 0.1% FPR`) as a more attack-relevant metric —
Carlini et al. 2022 — because attackers care about high-confidence
individual identifications.

### Wiring the metric into the platform

Membership-inference risk is not a one-shot number; it changes
every time the model is retrained. Wire it into the training
pipeline (mod-104):

- The training job produces a **members / non-members split** as
  an artefact.
- A post-training evaluation step computes the membership-
  inference AUC on the split and writes it to the model card.
- The mod-104 audit log records the value.
- Alerting: any retraining that increases MI-AUC above a
  threshold pauses the release for review.

### Response controls

- **DP-SGD at training (chapter 06).** The primary control. A
  correctly-configured DP training run bounds the per-example
  privacy loss and — measurably — reduces MI-AUC. The bound is
  not tight; empirical evaluation is still required.
- **Confidence hiding.** Return top-K labels without confidences.
  Reduces the attacker's signal for confidence-thresholding
  attacks; adaptive attackers still gain a signal from repeated
  queries and prediction stability.
- **Prediction perturbation.** Add controlled noise to
  confidences. A weaker mitigation than DP-SGD; measurable
  tradeoff with utility.
- **Model distillation.** A distilled student model on public
  data trained to match the target's outputs typically leaks
  less membership signal than the original. Not a rigorous
  guarantee; empirical mitigation only.

Do *not* deploy "confidence stripping" and call the leak fixed.
Confidence hiding raises the attacker cost; DP-SGD closes the
theoretical leak.

### Attribute inference and training-data extraction

Two adjacent threats. Attribute inference (Fredrikson et al.
2015) uses the model to reconstruct sensitive attributes of
training members. Training-data extraction (Carlini et al. 2021
for LLMs) recovers actual training strings. Both are outside the
scope of this chapter's monitoring detail — the mod-107 (LLM &
Agent Security) and mod-108 (Privacy Engineering) chapters cover
them — but the model-card row should record whether the model has
been evaluated for either.

---

## Rate limiting, quotas, and identity — the platform primitives

Extraction and inference detectors rely on per-identity
aggregation. That aggregation only works when identities are
strong. Two rules:

- **API keys must be per-caller.** Shared API keys across an
  organisation defeat per-identity detection. mod-105 chapter 02
  covers per-caller keys with Vault dynamic secrets; the serving
  layer must actually validate identity, not just presence of a
  key.
- **Workload identity end-to-end.** Internal callers use
  SPIFFE / OIDC identity (mod-103 chapter 03). This gives you a
  workload-attested identity per request rather than a shared
  service account.

Rate-limit primitive design:

- **Per-identity, per-endpoint, sliding-window.** Global rate
  limits protect the service against abuse but do nothing about
  a distributed extraction attack across many small identities.
- **Quotas at multiple granularities.** Per-tenant, per-user,
  per-plan-tier — because attackers pool identities across a
  tenant when they can.
- **Elastic response.** When a detector fires, tighten the rate
  limit rather than blocking outright — an outright block
  informs the attacker and pauses legitimate traffic. Log the
  tightening as an incident event.

---

## Watermarking — a note on scope

Model output watermarking (imperceptible marks on generated
content or on confidence outputs that a downstream trained
surrogate would inherit) is a legitimate defence, but it is
detection-of-theft, not prevention. Two watermarking families:

- **Output watermarking** — for generative models, statistical
  patterns in the sampled tokens that identify the source model
  (Kirchenbauer et al. 2023 for LLMs).
- **Model-weight watermarking** — embedding an owner signature
  in the model weights that survives fine-tuning to a bounded
  degree.

Neither prevents extraction; both provide evidence in a legal
follow-up. Use them when the business is willing to litigate
model theft and understands the limitations. mod-107 owns the
LLM-specific watermarking story.

---

## Standard failure modes

- **Serving-layer telemetry that is missing the identity or the
  fingerprint.** No detector recovers from bad telemetry. Fix
  telemetry first.
- **Fingerprints that leak PII.** A "fingerprint" that
  reconstructs the input is not a fingerprint; it is the input.
  Use perceptual hashes / pooled embeddings / one-way sketches
  with the reversibility explicitly evaluated.
- **Global rate limits and no per-identity quota.** The most
  common configuration; the least effective against extraction.
  Every extraction incident post-mortem asks why per-identity
  quotas were not set; every extraction incident answers "we
  never got around to it".
- **Detector without an alert path.** A distribution-drift
  metric on a Grafana chart nobody reads is not a detector.
- **MI-AUC never measured.** Almost every production classifier
  has a measurable membership-inference AUC and almost none
  measure it. Absence of measurement is not absence of leak.
- **Confidence hiding sold as an MI defence.** It is a
  mitigation, not a fix. Members and non-members still show
  measurable divergence in prediction stability, response
  latency (side channels), and top-K distribution.
- **Ignoring the shared-tenant case.** Multiple end-users behind
  one tenant's API key look like one identity. Extraction
  attackers exploit this. Per-tenant quotas plus in-tenant
  attribution (where the tenant can provide it) close the gap.
- **Enforcing at layer 7 only.** L7 rate limits protect one
  service. A serving mesh (mod-103 chapter 03) enforces the
  policy at the identity level across services; enforce at both
  layers, prefer the mesh for the identity-attributed decisions.

---

## The mistakes this chapter is trying to prevent

- **Treating extraction as an anti-abuse problem.** Anti-abuse
  teams look for fraud, credential stuffing, and DDoS. Model
  extraction is a *content* attack; the signal is in the query
  distribution, not in the QPS. If the anti-abuse dashboard is
  the only defence, extraction goes undetected.
- **Treating membership inference as a compliance-only topic.**
  It is a technical attack against a technical artefact. The
  metric belongs in the model card and the monitoring dashboard
  alongside accuracy and latency — not solely in a privacy
  policy PDF.
- **Confusing rate limits with detection.** Rate limits are a
  *control*, not a detector. Detection tells you an attack is
  happening; the control decides what to do next.
- **Assuming closed-weight serving prevents extraction.** The
  point of extraction is that black-box query access is enough
  for a functional copy. Closed-weight serving raises the query
  budget the attacker needs; it does not remove the threat.
- **Publishing "we watermark outputs" as if it were a prevention
  control.** Watermarking gives you a story to tell after the
  copy is discovered. It does not prevent the copy.
- **Not writing the MI-AUC on the model card.** A model card
  without an MI-AUC row is a model card that has not been
  privacy-evaluated. Regulators and downstream governance
  (mod-109) will notice.
- **Leaving the identity model weak.** If the platform cannot
  attribute a request to a single caller, none of the detectors
  in this chapter run correctly. Fix identity before rolling out
  extraction detection.

---

## Summary

- Serving-layer telemetry — identity, non-reversible input
  fingerprint, output summary — is the substrate every detector
  in this chapter needs. Instrument first; detect after.
- Extraction detectors combine per-identity distribution drift,
  PRADA-style query-similarity clustering, and boundary-
  proximity flags. Each catches a different attack shape;
  compose them.
- Response controls escalate: rate-limit tightening, output
  perturbation, quota enforcement, watermarking, and — as a
  last resort — kill-switch on the identity.
- Membership-inference risk is a *measurable* per-model metric
  (MI-AUC and low-FPR TPR). Wire it into the training pipeline;
  put it on the model card; alert on retraining regressions.
  DP-SGD (chapter 06) is the primary control.
- Identity strength is a prerequisite — shared API keys defeat
  per-identity detection. mod-103 and mod-105 own the identity
  and secret-management primitives this chapter builds on.
- Watermarking is post-hoc evidence, not prevention. Use it when
  the business will litigate; do not lead with it as a defence.
