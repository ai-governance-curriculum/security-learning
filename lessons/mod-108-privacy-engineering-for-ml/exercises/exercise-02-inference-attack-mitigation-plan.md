# Exercise 02 — Inference-Attack Mitigation Plan

**Estimated effort:** ~3 hours
**Deliverable:** A committed inference-attack mitigation bundle
for one deployed model on personal or regulated data,
consisting of (a) a threat-model section naming access mode,
attacker profile, and assets at risk, (b) the chapter-02 three-
layer defence filled in — training-time, architectural,
monitoring — with specific values for every control, (c) an
MI-AUC canary set and a measurement script wired to the
release pipeline, (d) a runtime-detector sketch (per-identity
rate limit, per-identity entropy, input-drift), (e) a filled-in
deployment-review packet following the chapter-02 template, and
(f) a short "what DP-SGD left behind" annex that names the
specific residual risks the architectural + monitoring layers
are closing.
**Prerequisites:** Chapter 02 read end-to-end. Exercise 01 (or
an equivalent DP-SGD decision) completed for the target model
— or an explicit acknowledgement that the training-time layer
is "no DP" with the reason. Access to the deployed model's
serving configuration and the auth / identity layer in front
of it. Access to the training data (for constructing the
canary set) or a documented procedure for building the canary
without re-exposing members.

---

## Objective

A single-layer privacy posture — training with DP-SGD *or*
rate-limiting *or* hiding confidences — leaves the attack
surface open to the attacks the other layers were supposed to
close. Chapter 02's thesis is that the defence is three-
layered, each layer sized to the threat, and the monitor is a
continuous SLO.

This exercise moves one deployed model from "we assume we are
fine" to a signed, measured posture. By the end you have:

- A written threat model that names the attacker, their access
  mode, and the asset.
- A specific per-identity rate limit, output-aggregation
  policy, confidence-hiding choice, per-caller identity
  binding, and query-audit scheme.
- An MI-AUC canary set with known members / non-members,
  measured against the deployed checkpoint under the current
  state-of-the-art attack (LiRA or equivalent).
- Both AUC and `TPR @ FPR = 10⁻³` reported, with per-tier SLO
  targets named.
- A sign-off packet that would survive a governance audit.

You are producing an operational artefact — the on-call
engineer and the DPO both read it to understand what the model
protects and what the monitor should scream about.

---

## Problem statement

Pick one deployed model (or a close-to-deployed one) on
personal or regulated data. Candidates:

- A deployed classifier on customer data with a REST / gRPC
  endpoint.
- A LLM assistant fine-tuned on tenant data, serving via a
  managed endpoint or a self-hosted inference server.
- A retrieval-augmented chatbot whose RAG index is populated
  from customer content.
- An embedding service exposing per-document embeddings or
  nearest-neighbour queries.

If the exercise-01 target model is deployed, continue with it;
otherwise pick one with a documented serving surface and a
known or constructible training-data membership record.

By the end of this exercise you must be able to state:

- Access mode (API with logits / argmax-only / text-generation
  / embedding / retrieval top-K).
- Attacker profile (external anonymous / authenticated tenant
  user / insider tenant admin / joint attacker / public
  internet).
- The caller identity primitive in production (mod-103) — if
  there is none, the deployment is not ready for regulated
  data and the exercise's first finding is to escalate.
- Whether the training-time layer is DP-SGD, DP-off, or
  something else (e.g. output-perturbation, aggregated-only
  training).

---

## Requirements

### Deliverable A — threat-model section

A one-page section that answers:

1. **Access mode.** One of {API/logits, API/argmax, API/top-K,
   text-generation, embedding, retrieval}. If the deployment
   exposes multiple modes, enumerate.
2. **Attacker profile.** External anonymous, authenticated
   tenant user, insider tenant admin, joint attacker,
   researcher-with-public-access. Pick one or more.
3. **Assets at risk.** For each of {membership, attribute,
   verbatim training data, index contents, embedding
   content}, state whether it is in-scope for this model and
   why.
4. **Why this attacker.** Argue the realism from the access
   mode and the data classification — "the model is reachable
   by authenticated tenant users of other tenants under the
   current ACL; cross-tenant MI is in-scope".
5. **LLM-specific extensions (if applicable).** Memorised
   training-data extraction, prompt-based extraction attempts,
   prefix-continuation attacks. Named explicitly where
   relevant.

### Deliverable B — architectural controls

For every architectural lever in chapter 02, state the specific
value for this model, or state (with reason) that it is not
used. The expected shape:

```yaml
architectural:
  rate_limits:
    per_identity:
      limit: 500  # requests/day
      window: 1d
      burst: 100/hr
    per_tenant:
      limit: 20000
      window: 1d
    unauthenticated_pool:  # if public tier exists
      limit: 50/hr
      note: "unauth pool treated as one identity"
  output:
    mode: top_k           # argmax | top_k | full_vector | threshold
    k: 3
    confidence:
      format: rounded_2dp # none | rounded_Nd | argmax_only | noise
      noise_sigma: null
    temperature: 1.5      # calibration-aware output smoothing
  caller_identity:
    primitive: workload_identity_x509  # mod-103 primitive
    requirement: required_for_all_paths
    public_tier: false
  query_audit:
    enabled: true
    fingerprint: sha256_of_input
    retention_days: 90
    pii_in_log: redacted_via_chapter_03_profile
```

Every value is defended in a one-sentence comment or a brief
callout — "`k = 3` because the downstream calibration consumer
needs the top three options; argmax-only was rejected because
<reason>." A value with no defence does not pass.

For LLMs, add:

```yaml
llm_memorisation_controls:
  training_data_deduplication: {done: true, method: minhash_near_duplicate}
  perplexity_output_filter: {threshold: 1.5, action: flag_and_log}
  prefix_continuation_detector: {enabled: true, action: block}
  output_dlp:
    profile_ref: chapter_03_output_profile
  watermarking: {enabled: false, reason: "no attribution use case yet"}
```

For retrieval / RAG:

```yaml
retrieval_controls:
  row_level_acl: {enforced_at: retrieval_gateway, model: per_tenant_scope}
  distance_in_response: {returned: false}
  ingest_dlp: {profile_ref: chapter_03_retrieval_profile}
```

### Deliverable C — MI-AUC canary set and measurement

A canary set built from training-time data:

1. **Members set.** A fixed sample of records (e.g. 1k–10k)
   known to have been in the training data. Hashed; pinned.
2. **Non-members set.** A fixed sample drawn from the same
   source distribution but not in the training data. Hashed;
   pinned.
3. **Membership record.** The record of which records are
   members is a sensitive artefact — store it under tight
   ACLs (same tier as the training data).
4. **Measurement script.** Runs the LiRA attack (or Yeom
   baseline where LiRA is infeasible — if the attack is
   downgraded, state why) against the deployed checkpoint,
   emits:
   - AUC with 95% confidence interval.
   - TPR at FPR = 10⁻² and 10⁻³ (and 10⁻⁴ if feasible).
   - Per-cohort breakdowns if cohorts are available (e.g.
     per-tenant, per-geography).
5. **Scheduling.** The measurement runs on release (gating)
   and on a weekly (or similar) cadence against the live
   checkpoint. Regressions page the on-call.

Attribute-inference canary (where sensitive-attribute data is
in training): same construction, with a held-out set of known
sensitive-attribute labels; the attack trains a small inferer
on model outputs and reports accuracy on the held-out set.

Report the current measurements against the chapter-02 SLO
table or against the tier-adjusted SLO you commit to:

| Metric | SLO target (tier) | Measured | 95% CI | Gate action |
| --- | --- | --- | --- | --- |
| MI-AUC | ≤ 0.55 | | | block / warn / log |
| TPR @ FPR=10⁻³ | ≤ 0.01 | | | block / warn / log |
| TPR @ FPR=10⁻² | ≤ 0.05 | | | block / warn / log |
| Attribute inference accuracy (if applicable) | | | | |

### Deliverable D — runtime detectors

A sketch (not full implementation) of two detectors wired to
the live serving traffic:

1. **Per-identity query volume + entropy.** Log aggregated
   per-identity request rate and per-identity input-space
   entropy; alert when either sits in a tail of the historical
   distribution. Name the alert threshold (e.g. z-score > 3
   over a 7-day baseline) and the routing (ML platform
   on-call).
2. **Input-distribution drift.** Compare the current window's
   request distribution against a stable baseline;
   PSI / KL / embedding-centroid-shift — pick a metric and name
   the threshold.

Each detector has: input (what log source), state (what
baseline it compares to), action (alert / block / rate-reduce),
owner (on-call role), SLA (seconds / minutes to acknowledge).

For a LLM, add a **prompt-shape detector** that flags prefix-
continuation prompts likely to be extraction attempts (per
chapter 02).

### Deliverable E — the deployment-review packet

A rendered Markdown document following the chapter-02 template:

1. Model identity (data class, `(ε, δ)` or "not DP" with
   reason, model-card link).
2. Threat model (from Deliverable A).
3. Architectural controls (from Deliverable B).
4. Monitoring (from Deliverable C and D).
5. LLM-specific (if applicable) — from Deliverable B's LLM
   section + perplexity / extraction detectors.
6. Retrieval-specific (if applicable).
7. Companion controls (storage encryption per mod-105;
   transport per mod-103; access control per mod-103; DLP per
   chapter 03).
8. Sign-off — ML platform on-call rep, product owner, DPO,
   security lead; HIPAA Security Officer if the model is on
   PHI (chapter 05).

### Deliverable F — "what DP-SGD left behind" annex

A half-page annex that lists, for the specific model:

- Which residual risks the training-time layer did not close
  — retrieval leakage, prompt-log exposure, population-level
  attribute inference, overfit on non-DP fine-tune, memorised
  LLM extraction.
- For each, which architectural / monitoring control in the
  packet closes it, and the remaining residual.

If the training-time layer is "no DP", the annex instead lists
*everything* the architectural + monitoring layers are
expected to close, and flags the gaps that only training-time
controls would close.

---

## Starter guidance

- **Start from the access mode.** The architectural controls
  descend from it. An argmax-only API has a very different
  attack surface from a logits-returning API, and the right
  rate limit for one is wrong for the other.
- **Rate limit per authenticated identity, not per IP.** This
  is the single-cheapest fix most teams miss. If the
  deployment has no authenticated identity on every path, the
  exercise's first output is to escalate — the deployment is
  not ready for regulated data.
- **Report AUC *and* TPR @ low FPR.** The chapter is explicit
  that `AUC = 0.55` can co-exist with high-confidence MI on a
  tail subset. The release-gate SLO is both.
- **Match the LiRA attack to your model.** If LiRA is
  infeasible (compute, shadow-model cost), run the Yeom et
  al. baseline and state the trade-off. A baseline attack is
  still an attack; do not report "no measurement" as the
  answer.
- **Treat the retrieval index as its own model.** If RAG is in
  use, Deliverable C has a retrieval MI-AUC too (nearest-
  neighbour distance distribution for known-indexed vs
  known-not-indexed documents).
- **Fingerprint the queries in the audit log.** The query
  audit is a privacy artefact — storing full prompts recreates
  the PII problem the chapter-03 DLP is for. Hash or feature-
  bin.
- **Argue the aggregation choice from the product.** Full-
  confidence vectors are returned "for calibration"; most of
  the time no downstream consumer actually needs them. Walk
  through the consumers before accepting the full-vector mode.

---

## Acceptance criteria

A passing bundle:

- Threat model names access mode, attacker profile, and
  assets at risk, with a one-line realism argument.
- Every architectural lever is set to a specific value with a
  one-sentence defence.
- Rate limits are per authenticated identity, with a separate
  per-tenant limit; the unauthenticated pool (if present) is
  treated as one identity.
- MI-AUC canary set exists, is pinned, and the measurement
  script runs against the live checkpoint with reported
  AUC + TPR @ FPR = 10⁻³ and 10⁻².
- SLO targets are named per tier; the measured values are
  compared against the targets and a gate action is stated per
  row.
- At least two runtime detectors are wired, with inputs,
  thresholds, actions, owners, and SLAs.
- LLM / retrieval sections are filled where applicable; if not
  applicable, the packet states so and why.
- The sign-off packet is complete and routable, and the DP-SGD-
  leftover annex names residual risks and the controls that
  close them.

A failing bundle:

- Rate limit per IP only, or no rate limit at all.
- Full probability vector returned without a named consumer.
- AUC reported without TPR at low FPR; the tail is hidden.
- No canary set; MI-AUC is a projection, not a measurement.
- Attribute-inference risk flagged but not measured.
- Audit log stores full prompts without DLP; the log is itself
  a PII store.
- Alerts are configured but route to an unwatched channel.
- The packet's sign-off block is a one-line "security
  reviewed" with no DPO or product-owner routing.

---

## Stretch goals

- **Membership-attack cross-check.** Run two attacks (LiRA
  and a shadow-model attack, or LiRA and a loss-threshold
  baseline) and compare their verdicts; report the attack
  that produces the higher TPR at low FPR, not an average.
- **Attribute-inference canary.** Build the canary and run
  the attack; compare the inference accuracy against a
  population-prior baseline (what an attacker could infer
  without the model). The *delta* is the privacy signal.
- **Embedding-inversion canary.** For embedding / retrieval
  services, run an embedding-inversion attack (e.g. Morris et
  al. 2023 recipe) on known-indexed embeddings and report the
  BLEU / exact-match recovery rate.
- **Rate-limit shaping study.** Simulate three attacker query
  budgets (1k / 10k / 100k) under the chosen limits; compute
  the attacker's time-to-finish for each. Argue the limit's
  shape from the attacker's time-cost, not from product
  intuition.
- **Alert rehearsal.** Trigger a synthetic MI-AUC regression
  (e.g. by swapping the checkpoint for a known-leaky stand-
  in) and verify the alert reaches on-call within the stated
  SLA; capture the runbook execution.
- **Cross-tenant isolation audit.** For a multi-tenant model,
  construct members from tenant A and non-members from tenant
  B's cohort; measure MI-AUC across the tenant boundary.
  Report whether the isolation holds.
- **Composition with chapter-04 DPIA.** Produce the
  chapter-02 input the chapter-04 DPIA's §3 risk section
  needs — likelihood / severity scores for membership and
  attribute inference under the chosen controls.

---

## Do not

- Do not report "MI-AUC looks fine" without the attack name
  and the TPR-at-low-FPR number. The chapter is explicit that
  AUC alone hides the tail.
- Do not store the canary membership label in the main audit
  log. The canary's ground truth is itself leakable; ACL it
  like the training data.
- Do not accept "full probability vector returned because
  calibration" without naming the downstream consumer. Most
  cases have no real consumer.
- Do not route alerts to a Slack channel nobody watches. The
  packet names the receiver and the SLA.
- Do not treat architectural controls as a substitute for
  training-time DP on sensitive data. The three layers
  compose; none replaces the others.
- Do not commit the solution bundle to this repo; solutions
  belong in the paired `-solutions` repo.
