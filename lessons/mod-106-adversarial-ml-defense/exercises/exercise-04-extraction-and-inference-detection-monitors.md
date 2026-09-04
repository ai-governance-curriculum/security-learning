# Exercise 04 — Extraction and Inference Detection Monitors

**Estimated effort:** ~4 hours
**Deliverable:** A serving-layer monitoring bundle consisting of
(a) a query-telemetry schema plus a working emitter integrated
against a mock or real serving path, (b) a query-similarity
extraction detector (per-identity distribution drift + a PRADA-
style detector) that runs on the telemetry, (c) a membership-
inference risk evaluator that computes MI-AUC (and low-FPR TPR)
on a members / non-members split, (d) an alert-and-response
routing table that names detector → alert payload → channel →
owner → action, and (e) a written interpretation memo tying the
numbers to the chapter-01 threat model and the next-step
follow-ups (rate limits, output perturbation, DP-SGD).
**Prerequisites:** Chapters 05 read end-to-end; chapter 06 read
for the DP-SGD response-control context. Exercise 01 completed
for the baseline threat-model artefact. A target model behind a
callable interface (a Flask / FastAPI wrapper is fine; a real
serving stack is better). Python with `torch`, `scikit-learn`,
`numpy`, and (for optional identity work) an auth library
appropriate to the target.

---

## Objective

Serving-layer defence is where every threat-model conversation
about extraction and membership inference lands. This exercise
gets you to the point where you can *measure* both.

By the end of this exercise you have:

- A structured query-telemetry stream with identity + non-
  reversible fingerprint + output summary per request.
- Two extraction detectors running on that telemetry with
  documented alerting thresholds.
- A membership-inference AUC (and low-FPR TPR) reported on the
  target model against a members / non-members split.
- A routing table that turns detector output into an on-call
  action.
- A written recommendation on whether the model can ship as-is,
  needs DP-SGD (exercise 05), or needs output-perturbation
  serving-layer controls before shipping.

You are proving that the monitors work on this model and this
telemetry — you are not trying to catch a specific attacker.

---

## Problem statement

Continue with the target model. Its serving surface today is
whatever the org has — an API endpoint, a batch scoring job, or
a scratch FastAPI wrapper you built for exercise 01.

Current state:

- No structured per-request telemetry beyond nginx / cloud access
  logs.
- API keys exist but are shared per tenant.
- No extraction detection.
- Membership-inference risk has never been measured.

Your job is to add the smallest telemetry surface that supports
the detectors from chapter 05, run the detectors, and put the
numbers on the model card.

---

## Requirements

### Deliverable A — telemetry schema + emitter

A JSON-schema (or equivalent typed record) for the per-request
event with, at minimum:

```json
{
  "request_id": "uuid",
  "ts": "2026-09-04T14:22:31Z",
  "model_id": "fraud-v3",
  "model_version": "sha256:...",
  "identity": {
    "kind": "api_key | workload | end_user",
    "id_hash": "sha256:...",
    "tenant_id": "tenant-retail"
  },
  "input_fingerprint": {
    "algorithm": "phash | tokenized_ngram | quantised_features",
    "value": "..."
  },
  "output_summary": {
    "top_k": [{"label": "not_fraud", "confidence": 0.83}, ...],
    "abstain": false
  },
  "latency_ms": 12,
  "error_code": null
}
```

Constraints:

- The identity `id_hash` is a hash of the token / key, never the
  raw token. Correlation is by hash, per chapter 05 and mod-105
  chapter 05.
- The `input_fingerprint` must be non-reversible or size-bounded
  enough that it cannot reconstruct the input. Perceptual hashes,
  pooled embeddings, quantised feature vectors all qualify. A
  raw base64 of the input does not.
- The `output_summary` may exclude confidence values if the
  serving surface hides them from callers, but the detector
  section must still function.
- Emit the events to any sink — stdout for local runs; a
  Kafka/Kinesis/Pub-Sub topic for production; a flat file for
  the exercise. The routing table (Deliverable D) names the sink.

Wire the emitter into the target serving path (or a mock that
mimics it). A short traffic-replay script that submits a
scripted mix of legitimate and synthetic-attack queries produces
the telemetry the detectors will chew on.

### Deliverable B — extraction detectors

Two detectors on the telemetry:

**Detector 1 — per-identity distribution drift.**

- Build a per-identity baseline distribution over
  `input_fingerprint` (e.g. a KDE on quantised feature vectors,
  or a cluster-count vector over a KMeans clustering of
  fingerprints).
- Every N minutes (or on a fixed cadence), compute the
  distribution over the last M minutes' fingerprints per
  identity and compare with the baseline via a distance
  metric (Wasserstein, MMD, KL-divergence — argue the choice).
- Emit an alert when the distance exceeds a stated threshold.

**Detector 2 — PRADA-style query-similarity detector.**

- Per identity, over a rolling window, compute the empirical
  distribution of pairwise fingerprint distances.
- Compare against a natural-traffic baseline (either a global
  aggregate or per-identity-segment aggregate) using the PRADA
  Shapiro-Wilk-style test (Juuti et al. 2019) or a KL-divergence
  on binned distances.
- Emit an alert when the p-value falls below or the divergence
  exceeds a stated threshold.

Constraints:

- Both detectors have explicit thresholds stated in a config
  file (not hard-coded), with a written justification for each
  chosen value.
- Both detectors emit alerts as structured records, not string
  log lines. The alert payload includes identity id_hash,
  detector name, score, threshold, window definition, and the
  request_ids that contributed.
- The detectors do not read the raw input; they only read the
  fingerprint field. Verify this in code.

### Deliverable C — membership-inference risk evaluator

A script that:

1. Loads the target model at the pinned version from exercise
   01.
2. Loads a **members** set (the training set, or a random
   subset of ≥ 5000) and a **non-members** set (samples from
   the same distribution but demonstrably held out — from a
   held-out portion of the same source or from a public dataset
   with the same schema).
3. Queries the model on each and records the confidence of the
   true label.
4. Computes:
   - MI-AUC (Shokri-style — Shokri et al. 2017).
   - Low-FPR TPR (Carlini et al. 2022 — TPR at FPR = 0.1%). If
     the sample size does not support a stable estimate at
     0.1%, report at 1% and say so.
5. Writes a report:

```json
{
  "model": "fraud-v3",
  "model_version": "sha256:...",
  "members_count": 5000,
  "non_members_count": 5000,
  "mi_auc": 0.71,
  "tpr_at_fpr_0.001": 0.09,
  "tpr_at_fpr_0.01": 0.28,
  "notes": "..."
}
```

The report lands in the model card's privacy section.
Constraints:

- Do not use PII in the report. The members / non-members
  identity information is what the risk measures — do not
  expose it.
- The members / non-members split is auditable: the script
  records the split's file hash or the query that constructed
  it.

### Deliverable D — alert-and-response routing table

For each detector, one row:

| Detector | Trigger condition | Alert payload fields | Destination channel + paging rotation | Owner | First response | Escalation |
| --- | --- | --- | --- | --- | --- | --- |

At minimum:

- Both extraction detectors from Deliverable B.
- Membership-inference risk regression (fires when MI-AUC on a
  scheduled recomputation increases by more than a stated
  threshold vs. the baseline in the model card).

Routing rules:

- Every row has a paging rotation (not a person's name) as the
  destination.
- Every row's first response is a concrete action: "tighten the
  identity's per-endpoint rate limit by 50% for 60 minutes,
  page on-call for review" — not "investigate".
- Escalation names when the incident becomes an on-call
  wake-up: confirmed extraction, MI-AUC regression above a
  threshold, or any detector firing on an identity in the
  designated high-tier plan.
- No row is empty. A detector without a destination is a
  detector that does not exist.

### Deliverable E — interpretation memo

~2 pages of Markdown. Answer:

1. **What did the detectors see?** During the traffic replay,
   which detectors fired on which identities and at what
   scores? False positives and false negatives against the
   synthetic-attack labels?
2. **What is the model's MI-AUC?** Report the value in context —
   if it exceeds 0.7, the memo names the recommended action
   (DP-SGD via exercise 05, output perturbation, or hold the
   release).
3. **How does this update the exercise-01 threat-model artefact?**
   The extraction row and the membership-inference row now have
   baseline numbers. Update the artefact and cite the file.
4. **What is the next step?** Point at exercise 05 (DP-SGD) if
   MI-AUC is a concern; at a rate-limit change proposal if
   extraction risk is a concern; at mod-105 chapter 05 if the
   identity model is too weak to run per-identity detection
   correctly.

Cite:

- The PRADA paper (Juuti et al. 2019).
- The Shokri paper (Shokri et al. 2017) and the Carlini et al.
  2022 low-FPR paper.
- The library versions.

---

## Starter guidance

- **Instrument first.** The detectors depend on the telemetry;
  do not write the detectors against imaginary events.
- **Use a mock serving path if the real one is not available.**
  A FastAPI wrapper + a traffic-replay script gives you every
  input the detectors need, plus you can construct extraction-
  like synthetic traffic to test the detectors' true positives.
- **Do not over-engineer the fingerprint.** For images, a 64-bit
  perceptual hash + a 32-dim pooled feature vector is enough
  for a first-pass detector. For tabular, quantised feature
  vectors work. Get the pipeline running, then improve.
- **Pick MI-AUC thresholds and drift thresholds ex ante.** The
  memo argues the choice; do not tune to fire or not fire on a
  specific test.
- **Use a public dataset with a genuine held-out split for the
  non-members set.** If you construct the non-members set by
  perturbing the members set, the AUC measures the perturbation,
  not membership.
- **Cross-check the identity model.** If the platform's tokens
  are shared across many callers, the detectors will produce
  garbage. If that is the case, name the identity fix as a
  prerequisite in the memo — do not silently paper over it.

---

## Acceptance criteria

A passing bundle:

- Telemetry schema documented, emitter integrated, and events
  produced end-to-end from a traffic replay.
- Both extraction detectors run against the emitted events and
  produce structured alerts with configured thresholds and
  justifications.
- MI-AUC and low-FPR TPR reported with a documented members /
  non-members split.
- Routing table has one row per detector, all cells populated,
  paging rotations named.
- Memo interprets the numbers, updates the exercise-01
  threat-model artefact, and names the specific follow-up
  actions.

A failing bundle:

- Telemetry schema that includes reversible fingerprints or raw
  API keys / tokens.
- Detectors with thresholds tuned to specific test cases (the
  exercise measures detection, not overfit).
- MI-AUC reported without stating members / non-members counts
  and how the split was constructed.
- Routing table with empty cells or destinations that are
  individual names rather than rotations.
- Memo that says "the model looks fine" without pointing at the
  specific numbers.

## Stretch goals

- **Boundary-proximity detector.** Add the third detector from
  chapter 05 — per-identity mean margin (top-1 minus top-2
  logit) with an alert threshold. Compare its hit rate against
  the other two on the synthetic-extraction traffic.
- **Shadow-model membership-inference.** Implement the Shokri
  shadow-model attack rather than confidence-threshold MI, and
  compare the AUC numbers. The shadow-model AUC is often higher
  and is the more realistic threat.
- **Real serving integration.** Land the emitter in the org's
  actual serving path (behind a feature flag). Every request
  emits telemetry; the detectors run in a scheduled cron; the
  routing table wires into the org's on-call.
- **Watermark evaluation.** If the org has adopted output
  watermarking, evaluate whether the watermark survives a
  short extraction against a distilled surrogate. Document the
  survival rate; discuss its role as legal evidence.
- **STRIP integration.** Add a chapter-04 STRIP detector at
  serving time on suspect requests. Overlap analysis with the
  extraction detectors — they answer different questions but
  overlapping alerts may point at coordinated attacks.
- **Rate-limit A/B.** Deploy the "tighten rate limit on alert"
  first response as a feature flag on a small percentage of
  traffic; measure whether legitimate traffic is impacted
  before rolling wider.

## Do not

- Do not log raw inputs. The fingerprint is what the detectors
  need; logging inputs is a privacy incident waiting to happen
  (mod-104 chapter 04 and mod-108 both flag this).
- Do not report an MI-AUC without stating the split. The
  number is meaningless without it.
- Do not report a "we blocked X extractions" number without
  false-positive analysis. Blocking legitimate traffic is a
  worse failure than missing an extraction, and the memo must
  reason about both.
- Do not use per-tenant shared API keys as the identity
  substrate without flagging the fix as a prerequisite. The
  detector precision collapses on shared identities.
- Do not commit a solution here — solutions live in the paired
  solutions repo.
