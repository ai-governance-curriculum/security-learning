# Exercise 01 — ATLAS-Mapped Detection Content Authoring

**Estimated effort:** ~3 hours
**Deliverable:** A committed detection-content bundle for
one SIEM target (Elastic Security *or* Splunk Enterprise
Security *or* Microsoft Sentinel — pick one), consisting of
(a) a **portable Sigma rule set** covering the four module
focus areas (model-download anomaly, out-of-band agent tool
call, unusual training-data access, membership-inference
probe pattern) and *at least two* additional ATLAS
techniques of your choice, with each rule carrying the
ATLAS technique ID in its tags; (b) a **translated rule
set** compiled from Sigma into the target SIEM's native
dialect; (c) an **ingest-schema specification** per rule
listing the exact fields the rule depends on and the
upstream telemetry source each field comes from;
(d) a **baseline / tuning plan** describing the per-rule
baselining window, the enrichment inputs (per-identity
histogram, retrieval-provenance labels, near-duplicate
hashing), and the deployment path to production; (e) a
**coverage map** that enumerates each ATLAS technique the
pack covers, with the rule-id and severity for each, and
calls out the techniques explicitly *uncovered*; and (f)
a one-page **testing-and-promotion plan** describing how
each rule is validated against both synthetic red-team
payloads and sanitised production samples before being
enabled in paging mode.
**Prerequisites:** Chapter 01 read end-to-end. A chosen
SIEM target (Elastic / Splunk / Sentinel) with
documentation access. Familiarity with the MITRE ATLAS
matrix. Access to (or a credible model of) at least one
of: an LLM/API-gateway access log, a model-registry
access log, a cloud-storage access log for a training-
data bucket, an inference-gateway access log with
confidence-score enrichment.

---

## Objective

Chapter 01's claim is that an ML programme's detection
posture is defined by whether its SIEM has rules for
the ATLAS matrix and whether those rules are grounded
in signal the pipeline actually emits. This exercise is
where that claim is cashed in on *your* SIEM against
*your* telemetry (or a realistic model of it).

By the end of this exercise you have:

- A set of **portable Sigma rules** that cover the
  four module focus areas plus at least two additional
  ATLAS techniques you selected to broaden coverage.
- A **translated rule set** in the SIEM dialect your
  SOC runs, with the ATLAS technique IDs preserved so
  the coverage map renders correctly in the vendor
  dashboard.
- An **ingest-schema specification** that names each
  field the rules depend on and the pipeline that
  emits it — the artefact that lets a platform engineer
  know whether the rules are enforceable.
- A **baseline and tuning plan** that is honest about
  what each rule needs (per-identity histograms, LSH
  for near-duplicate detection, retrieval-provenance
  labels) and the sequence to get the rule into paging
  mode without flooding the queue.
- A **coverage map** that is a *governance artefact*,
  not just a rule inventory — covered techniques with
  rule IDs; explicitly-uncovered techniques listed with
  the reason (telemetry gap, policy decision, cost).
- A **testing-and-promotion plan** that includes both
  a synthetic red-team path and a replay path against
  real traffic samples.

You are **not** running a 90-day production rollout in
this exercise. You are producing the artefacts the
rollout will deploy.

---

## Problem statement

Pick one SIEM target up front and name it. Then pick
the signal sources you will author against. If you work
on an ML programme, pick the real sources. If you do
not, pick one of the realistic reference shapes:

- **LLM gateway access log** — trajectory records with
  prompt fragments, provenance labels, tool calls,
  model version, identity, token counts, latency.
- **Model-registry access log** — pull / push /
  signature-attach / approve events with identity,
  artefact digest, bytes transferred.
- **Cloud-storage access log for a training-data
  bucket** — object-read / object-write with identity,
  resource path, bytes, source IP.
- **Inference-gateway access log with enrichment** —
  per-request enrichment fields including a locality-
  sensitive-hash of the prompt / input, a counter of
  near-duplicate requests from the same identity in the
  last 15 minutes, a flag indicating whether the model
  exposes confidence scores.
- **Any other source** your programme instruments —
  Falco (chapter 02 feeds), K8s audit, SBOM feeds —
  name it specifically.

State before you start:

- SIEM target: Elastic / Splunk / Sentinel.
- Signal sources available (actual or modelled).
- Any enrichment pipeline you intend to assume (if you
  need a `near_duplicate_count_15m` field, say which
  pipeline computes it).
- Any field normalisation (ECS alignment, custom
  table in Sentinel, custom index + sourcetype in
  Splunk, custom data stream in Elastic).

If a signal source is hypothetical, mark it so and
include its proposed schema in deliverable C.

---

## Requirements

### Deliverable A — Sigma rule set (portable)

Author at least **six** rules in Sigma format
(`sigmahq` schema). The four module focus areas are
required:

- Model-download anomaly (`AML.T0044` or related).
- Out-of-band agent tool call (`AML.T0049` with
  `AML.T0053` as entry vector).
- Unusual training-data access (`AML.T0019` or
  related).
- Membership-inference probe pattern
  (`AML.T0024.001`).

Pick at least **two additional** techniques from the
ATLAS matrix. Candidates:

- Discovery against the model via API probing
  (`AML.T0003` or related).
- Prompt-injection detection on inbound requests
  (`AML.T0051` variants).
- Model-exfiltration via inference API
  (`AML.T0049`).
- LLM-generated-output DLP triggers for sensitive
  content.
- Any technique relevant to your product surface;
  justify the choice.

Each rule carries:

- `title` — concise, scanned at 3 a.m.
- `id` — a stable UUID.
- `description` — what fires it and why; a reader
  must know the intent without clicking through to
  ATLAS.
- `references` — the ATLAS technique page URL.
- `logsource` — product / service / category.
- `detection` — selection(s), condition, and any
  thresholds.
- `fields` — the enrichment to carry on the alert.
- `level` — low / medium / high / critical.
- `tags` — including `atlas.<technique-id>` and
  `atlas.tactic.<tactic-slug>`.
- `falsepositives` — enumerated, not dismissed.

Rules reference realistic field names (chapter 01 has
shapes you can adapt; align to your SIEM's ECS or
custom field names in deliverable C).

### Deliverable B — translated rule set (SIEM-native)

For each Sigma rule in A, produce the compiled form in
your SIEM's native dialect:

- **Elastic:** a Detections engine rule as JSON or the
  web-UI export, with threat framework / technique
  fields populated.
- **Splunk:** an ES correlation search with notable-
  event action, MITRE annotation fields.
- **Sentinel:** an analytics-rule YAML template with
  `tactics:` / `techniques:` populated.

Use `sigma-cli` / `pySigma` conversion where possible
and record the command line used; make manual edits
explicit (the ATLAS ID may not translate cleanly in
some converters and may require a manual tag).

### Deliverable C — ingest-schema specification

For every field referenced in deliverables A/B,
specify:

- The field name as it appears in the SIEM.
- The upstream source producing it (LLM gateway,
  model-registry access log, inference gateway,
  Falco, enrichment pipeline).
- The schema contract (type, cardinality, required /
  optional, parser).
- The enforcement — how the ingest pipeline rejects
  or quarantines malformed records that would silently
  break the rule.
- Any ECS mapping if available.

For hypothetical sources, provide the proposed schema
with the same fields.

### Deliverable D — baseline and tuning plan

For each rule, name:

- The baseline the rule depends on (per-identity
  histogram of pulls / near-duplicate rate / egress
  destinations) and how it is maintained.
- The tuning window — how long the rule runs in
  "notice" / log-only mode before promotion to paging.
- The exceptions mechanism — how legitimate exceptions
  (scheduled eval runs, approved backfills, authorised
  new destinations) are expressed. Exceptions live in
  code; wiki pages do not count.
- The ownership — who tunes this rule when its FP rate
  drifts.
- The retirement path — the condition under which the
  rule is deprecated (replaced by a better one,
  technique no longer relevant, telemetry source
  retired).

### Deliverable E — coverage map

A YAML (or Markdown table) document shaped like the
chapter 01 example:

```yaml
coverage:
  AML.T0019:
    rules: [{id: ..., severity: ..., source: ...}]
    status: covered
  AML.T0024.001:
    rules: [...]
    status: covered
  AML.T0044:
    rules: [...]
    status: covered
  AML.T0049:
    rules: [...]
    status: covered
  AML.T0053:
    rules: [...]
    status: covered
  AML.T0003:
    rules: []
    status: uncovered
    reason: "No inbound-API-probe telemetry today; see roadmap-04."
  # ... every ATLAS technique in your scope should appear.
```

Rules:

- **Explicit uncovered.** Techniques not covered must
  appear with a reason, not be omitted.
- **One source of truth.** The coverage map is the
  governance artefact mod-109 consumes; do not keep a
  second shadow version in a wiki.

### Deliverable F — testing-and-promotion plan

A one-page document per rule (or a shared template
instantiated per rule) covering:

- **Synthetic validation.** A hand-crafted event (or
  short sequence of events) that triggers the rule.
  Produce the JSON / log-line input and show the rule
  firing on it in your SIEM's test harness.
- **Replay validation.** The rule evaluated against a
  sanitised sample of production traffic over a
  defined window (24 h, one week — size-appropriate).
  Report true-positive and false-positive counts;
  show at least one true positive if the rule is
  intended to be enforcement-grade.
- **Promotion gate.** The specific criteria for moving
  from log-only to paging: FP rate below $X / week,
  reach of the signal validated, downstream playbook
  ready (chapter 03).
- **Rollback path.** How to revert the rule to log-
  only if the production enablement reveals an issue.

---

## Starter guidance

- **Start from Sigma, not from the vendor dialect.**
  Rules in a vendor dialect are hard to port when the
  org changes SIEMs; Sigma is the lingua franca.
- **Confirm every field exists.** The most common
  failure is a rule that reads a field the pipeline
  does not emit. If the field is a planned enrichment,
  the rule depends on the enrichment landing.
- **Prefer per-identity baselines over global
  thresholds.** "500 requests per hour" is a global
  rule that catches no one; "> 10× the identity's own
  P95 over the last 7 days" catches the actual
  anomaly.
- **Write `description` for the on-call.** The
  description is the first thing a responder reads.
  "Agent tool call to unknown destination after
  external retrieval" is better than "AML.T0049
  trigger".
- **Keep ATLAS tags consistent.** `atlas.AML.T0049` is
  the convention this track uses; carry it in both
  `tags:` and vendor-specific threat-framework fields.
- **Pair each new rule with a chapter 03 playbook
  reference.** A rule without a playbook has no
  downstream response.
- **Separate detection from enrichment.** The rule
  should not compute an expensive derived field; it
  should read one that the ingest pipeline computes.
  LSH / near-duplicate counting / provenance labelling
  are enrichments.
- **Document assumed field names.** Even if your
  SIEM's current data stream has a different schema,
  specify what the rule *expects*; this is the
  pipeline-engineering contract.

---

## Acceptance criteria

A passing bundle:

- At least six Sigma rules covering the four required
  focus areas plus two additional ATLAS techniques,
  with ATLAS IDs on every rule.
- A translated rule set in the chosen SIEM's dialect,
  compiled from the Sigma originals (manual tweaks
  marked).
- An ingest-schema specification that names every
  field, source, type, and ECS mapping (or justified
  non-ECS alignment).
- A baseline-and-tuning plan per rule with named
  baseline, tuning window, exceptions mechanism, and
  ownership.
- A coverage map listing covered and uncovered
  techniques with reasons for the uncovered.
- A testing-and-promotion plan with synthetic
  validation, replay validation (even on a small
  sample), promotion-gate criteria, and rollback.

A failing bundle:

- Rules without ATLAS tags.
- Rules that reference fields no documented source
  emits.
- "Baseline: TBD" or "FP: unknown".
- A coverage map that omits uncovered techniques.
- A testing plan that only names synthetic tests.
- Rules authored only in the vendor dialect with no
  Sigma source.

---

## Stretch goals

- **End-to-end automation.** A CI pipeline that
  compiles Sigma to SIEM-native on PR merge, validates
  the SIEM schema, and runs the synthetic tests
  automatically.
- **Multi-SIEM translation.** Produce the compiled
  form in two SIEMs; show the differences and the
  schema-mapping decisions each required.
- **Enrichment pipeline.** Implement one of the
  required enrichments end-to-end (per-identity
  histogram, retrieval-provenance labels, near-
  duplicate count) and show it producing live values.
- **Governance evidence integration.** Wire the
  coverage map into mod-109 chapter 04's policy pack
  so the ATLAS coverage percentage is a published
  governance metric.
- **Threat-intel feed.** Add a rule whose selection
  consumes a threat-intel indicator list (open-source
  or vendor) and show how the list is refreshed.
- **ATT&CK-and-ATLAS joint rule.** Author a rule
  whose signal starts classical (ATT&CK `T1078` valid
  accounts) and escalates on an AI-specific follow-on
  (ATLAS technique). Tag both frameworks correctly.
- **Red-team integration.** Pair at least one rule
  with a mod-107 chapter 04 red-team payload sample
  such that the regression gate fires the rule on
  every CI run.

---

## Do not

- Do not claim an ATLAS technique is covered by a
  rule whose required field does not exist in your
  pipeline.
- Do not use `latest` / `main` / untagged image
  references in any rule that depends on image
  identity.
- Do not design a rule whose only validation is a
  synthetic log line. Rules unverified against real
  traffic (or a sanitised sample) do not promote.
- Do not file the coverage map in a wiki page outside
  version control.
- Do not treat chronic false-positive rules as
  "wait for the SOC to tune it later". A rule in
  paging mode with a bad FP rate burns the SOC's
  trust in the AI pack.
- Do not commit the solution bundle to this repo.
  Solutions live in the paired `-solutions` repo.
