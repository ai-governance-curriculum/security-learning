# Exercise 03 — PII/PHI DLP in the Training Pipeline (and Prompt Log)

**Estimated effort:** ~3 hours
**Deliverable:** A committed DLP bundle covering two surfaces —
one training-data path and one runtime prompt-log path —
consisting of (a) a labelled evaluation set with per-entity
ground truth, (b) one Presidio (or equivalent) DLP profile per
surface, with pinned recognisers, pinned NLP model, per-entity
thresholds, and per-entity anonymisation operators, (c) a
measured per-entity recall / precision / F1 report against the
eval set, (d) a wired placement in the pipeline — DLP as a
required step with fail-closed behaviour and a coverage log,
(e) the three-part DLP-coverage evidence artefact from chapter
03 (profile registry, per-profile eval reports, operational
coverage log sketch), and (f) a sample-audit plan with
reviewer, scope, and cadence.
**Prerequisites:** Chapter 03 read end-to-end. Access to one
training-data pipeline (or a realistic analogue) and one
prompt-log stream (or a stand-in). Python environment with
Presidio installed (`presidio-analyzer`, `presidio-anonymizer`)
or an equivalent DLP stack (Google Cloud DLP, AWS Comprehend
PII, a self-hosted NER pipeline). Access to a KMS reference
for any recoverable-redaction operator the profile uses
(mod-105).

---

## Objective

Chapter 03's thesis is that DLP without a labelled eval set is
not DLP — it is a regex that "looks like it works". The
exercise moves one pipeline from "we scrub PII" to a measured,
versioned, auditable control.

By the end of this exercise you have:

- A labelled eval set with per-entity ground truth for the
  entities actually present in your data.
- Two pinned DLP profiles — one for training, one for runtime
  prompt logging — each with its own recogniser set,
  threshold table, and anonymiser-operator table.
- Per-entity recall, precision, and F1 measured against the
  eval set, with per-entity SLOs set from the entity's leakage
  risk.
- A wired integration where DLP is a required step with fail-
  closed behaviour, a coverage log that writes counts (not
  values), and lineage integration with mod-104.
- A sample-audit plan that catches what the automated eval
  cannot.

You are producing a **compliance-grade** control — one that an
auditor can trace from the DPIA (chapter 04) through the
profile files and the eval report to the operational coverage
log.

---

## Problem statement

Pick two data surfaces to put under DLP:

1. **A training-data path.** Ingest → feature build → batch →
   trainer. Could be the pipeline for the exercise-01 model
   or a different one; needs to carry text content that can
   plausibly contain personal identifiers (support tickets,
   emails, chat transcripts, patient notes, free-form form
   fields).
2. **A runtime prompt-log path.** The log that captures user
   inputs and model outputs for one deployed assistant /
   agent / inference endpoint. If an agent is in play, the
   trajectory log (tool arguments, retrieved documents,
   intermediate reasoning) is the richer surface — pick it in
   preference to a plain prompt log.

Optionally also include a **retrieval / RAG store** as a third
surface — chapter 03 treats it as the third leakage surface,
and the exercise's artefacts extend naturally if you have one.

For each surface, before writing the profile, state:

- Data categories in the surface (e.g. "support-ticket free
  text with names, phone numbers, order IDs, UK NHS
  numbers").
- Expected scale (records / day; records / month at steady
  state).
- Downstream readers (trainer, log analyst, on-call engineer,
  external auditor via DSAR).
- Reversibility requirement (does any legitimate reader need
  the raw value back? under what governance?).

---

## Requirements

### Deliverable A — labelled evaluation set

For each surface:

1. **Source.** A sample of real-shape records (consented /
   de-identified where sensitive). Minimum ~500 records per
   surface for a meaningful F1 estimate; more for low-base-
   rate entities (SSN, MRN).
2. **Annotation.** Per-record, per-entity-type, per-span
   ground truth. The format is up to you (JSONL with offsets;
   BIO tags; CoNLL) but it must be loadable by the eval
   script.
3. **Adversarial / edge cases.** Explicitly include numbers-
   as-words, obfuscated formats ("s.s.n. 1 2 3 - 4 5 - 6 7 8
   9"), OCR errors, transliterations, embedded identifiers
   inside URLs or JSON blobs. Mark these records so the eval
   can report edge-case recall separately.
4. **Versioning.** The eval set has a version string and a
   content hash; changes are reviewed; the hash is referenced
   in every eval report.
5. **Access control.** The eval set may itself contain PII —
   store under the same ACL tier as training data; name the
   access policy.

A one-page README for the eval set names the source, the
annotation guide, the version, the content hash, and the per-
entity record count.

### Deliverable B — DLP profile per surface

For each surface, a YAML profile following the chapter-03
example:

```yaml
# dlp_profile_training.yaml  (example — adapt)
name: training_data_tickets_v1
description: "DLP for the ticket-corpus training pipeline."
version: "1.0.0"
nlp_model: en_core_web_lg==3.7.1   # pinned
entities:
  PERSON:
    recogniser: builtin
    threshold: 0.6
    action: replace
    placeholder: "<PERSON>"
  US_SSN:
    recogniser: builtin
    threshold: 0.85
    action: redact
  PHONE_NUMBER:
    recogniser: builtin
    threshold: 0.7
    action: replace
    placeholder: "<PHONE>"
  EMAIL_ADDRESS:
    recogniser: builtin
    threshold: 0.5
    action: replace
    placeholder: "<EMAIL>"
  ORDER_ID:
    recogniser: custom
    recogniser_ref: "configs/dlp/recognisers/order_id_v1.py"
    version: "1.0.0"
    threshold: 0.9
    action: hash
    salt_ref: "kms://alias/dlp-salt-2026-q1"
coverage_log:
  path: "s3://dlp-coverage/training/tickets/"
  retention_days: 2555           # ~7 years to cover HIPAA floor
  value_logging: false           # counts and types only
failure_mode: fail_closed
```

Every entity has: a recogniser (built-in or custom with code
reference and version), a confidence threshold, an action
(replace / redact / mask / hash / encrypt), and — where
recoverable — the KMS key reference. Every custom recogniser
is code, version-pinned, with its own eval row.

The runtime (prompt-log) profile differs on at least:

- Threshold choices (false-positive cost is lower in logs than
  in training data; thresholds often looser).
- Fail mode (fail-closed is still default; the chapter calls
  out explicit documented exceptions).
- Reversibility: the chapter's default is irreversible for
  aggregate quality monitoring; a break-glass encrypted path
  is possible if the governance exists.

### Deliverable C — per-entity eval report

Run the DLP profile against the labelled eval set and produce,
per profile:

| Entity | Recall | Precision | F1 | 95% CI | Edge-case recall | SLO target | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |
| US_SSN | | | | | | ≥ 0.99 recall | pass/fail |
| PERSON | | | | | | ≥ 0.90 recall | pass/fail |
| PHONE_NUMBER | | | | | | ≥ 0.95 recall | pass/fail |
| EMAIL_ADDRESS | | | | | | ≥ 0.95 recall | pass/fail |
| ORDER_ID | | | | | | ≥ 0.99 recall | pass/fail |

Rules:

- **Per-entity** reporting. Aggregate F1 is a red flag; include
  it only as a secondary number.
- **95% CI** reported. If the eval set is too small to produce
  a meaningful CI for a low-base-rate entity, state so.
- **Edge-case recall** reported alongside the overall recall.
  An eval that passes overall but fails on edge cases is a
  design flag.
- **SLO target** set per entity based on leakage risk (SSN
  and MRN high; PERSON lower; verify against the tier map).
- **Failing entity** — the profile does not promote. The report
  states the remediation (lower threshold, custom recogniser,
  context cue).

Include a short analysis of the top three false positives and
the top three false negatives — not just the numbers, but what
the recogniser got wrong and whether a rule change would fix
it.

### Deliverable D — wired placement

Show how DLP sits in the pipeline:

For training:

```
raw_ingest  →  dlp_scan(training_data_tickets_v1)
            →  feature_build  →  training_batch  →  trainer
```

Properties to confirm in the submission:

- DLP step's output is the only output the downstream step
  consumes.
- DLP step is idempotent per record (same record → same
  redaction across runs); provide a quick idempotence test
  (same input text, two runs, equal output).
- DLP failure is a pipeline failure. There is no "fallback to
  raw". If the pipeline has an existing fallback path, flag
  it as remediation.
- The DLP profile version is captured in the mod-104 lineage
  record for the resulting model; show the lineage field or a
  placeholder that would land there.

For the prompt log:

```
request  →  analyze_input  →  scrub_input (dlp_scan(prompt_log_default))
         →  model_call      →  analyze_output  →  scrub_output
         →  log_write(redacted_form)
```

Properties:

- Redacted form is what is stored; raw form is not duplicated
  to a "raw" log unless there is a documented business need
  and a matching ACL.
- Failure mode is a decision point — chapter 03's default is
  fail-closed; if fail-open is chosen for this surface, the
  compensating controls are named.
- Log ACL matches the sensitivity of the redacted form (even
  a well-redacted log is behavioural-pattern data).

For the retrieval store (optional third surface):

```
document_arrival  →  dlp_scan(retrieval_index_v1)
                  →  chunk  →  embed  →  index_write
```

### Deliverable E — the DLP-coverage evidence artefact

Three parts, following chapter 03:

1. **Profile registry.** A `dlp_profiles.yaml` or equivalent
   that lists every profile in use (training, runtime,
   retrieval if applicable), with its scope, surface, version,
   entities, reversibility, profile-file path, and eval-
   report path.
2. **Per-profile eval reports.** The Deliverable C tables,
   committed with the profile. A CI job runs the eval on
   profile change and emits a dated report. State the CI job
   command even if the CI itself is not wired yet.
3. **Operational coverage-log sketch.** Specify the log entry
   schema (timestamp, profile name + version, record hash,
   entity-type counts, operator-per-entity counts). State that
   no raw values are logged. Specify the daily / weekly
   aggregates (records scanned, records with ≥1 hit, total
   redactions per entity, p99 DLP latency). Specify the
   anomaly alert (e.g. "zero SSN detections on a training day
   when the running average is in the thousands").

### Deliverable F — sample-audit plan

A one-page plan:

- **Cadence.** Quarterly or per training-plan approval,
  whichever is sooner.
- **Sample size.** A statistically defensible sample — name
  the number and the base-rate assumption.
- **Reviewer(s).** The named role; if a second DLP pipeline is
  the auditor, name the pipeline and its separation from the
  primary.
- **Review protocol.** The reviewer reads the redacted output
  looking for missed entities and adversarial patterns;
  reviewer access is logged; the review itself is a
  personal-data processing activity (name it in the DPIA).
- **Output.** A dated report with missed entities per type,
  new adversarial patterns observed, and recommended profile
  changes. The report is version-controlled alongside the
  profile.

---

## Starter guidance

- **Build the eval set before touching Presidio.** Measuring
  before you know what "right" looks like produces numbers
  that cannot be interpreted.
- **Pin everything.** The NLP model (`en_core_web_lg` with
  version), the Presidio package versions, every custom
  recogniser's code version. Silent recall drift from model
  upgrades is a repeated failure in the chapter.
- **Tune per entity.** A single global `score_threshold` costs
  you either recall on high-stakes entities or precision on
  easy ones. Spend an afternoon tuning per entity on the
  labelled set.
- **Add custom recognisers for the org's identifiers.** Order
  IDs, case numbers, MRNs, policy numbers. Presidio's built-
  ins do not know your schema. A pattern recogniser with a
  `context` list and a validation function cuts both false
  positives and false negatives.
- **Log counts, not values.** The coverage log must not become
  its own PII store. Hash the record identifier; log the
  entity *types* and *counts*, not the entity *values*.
- **Fail-closed by default.** The exercise's one hardest-to-
  justify failure mode is a DLP outage that silently writes
  raw data. If you ship fail-open for any surface, write down
  the compensating control.
- **Trace to mod-104.** The DLP profile version lives in the
  model's lineage record — if an auditor asks "which DLP
  profile scrubbed the data this model was trained on", the
  lineage must answer.
- **Sample audit is the proof the automated eval cannot be.**
  Automated eval tests what you labelled; the audit tests what
  you did not know to label.

---

## Acceptance criteria

A passing bundle:

- Each surface has a labelled eval set with per-entity ground
  truth, including explicit adversarial / edge-case rows.
- Each surface has a pinned DLP profile — NLP model pinned,
  recognisers pinned, entities and thresholds enumerated.
- Per-entity recall, precision, F1 reported with 95% CI; per-
  entity SLO targets set from leakage risk; verdict row
  present per entity.
- Edge-case recall reported alongside overall recall.
- DLP is wired as a required pipeline step with fail-closed
  default; idempotence demonstrated for the training path.
- The runtime path writes only the redacted form to the log;
  the log schema stores counts and types, not values.
- The three-part evidence artefact (profile registry, eval
  reports, operational coverage log sketch) is committed.
- The sample-audit plan names cadence, sample size, reviewer,
  protocol, and output.
- The profile version is referenced in a mod-104 lineage
  field, or a placeholder is in place for it.

A failing bundle:

- A single global threshold is used; per-entity precision /
  recall is not reported.
- Aggregate F1 is the headline metric; per-entity numbers are
  missing.
- "Fallback to raw" or "best effort" is the failure mode of
  the DLP step on any surface.
- The coverage log stores raw entity values ("found SSN
  123-45-6789 in record X").
- Custom recognisers are not version-controlled or not
  reviewed.
- The eval set was drawn from the same source as the training
  data without separation, inflating recall.
- The runtime log retains un-redacted prompts "for debugging"
  without a documented governance.
- No sample-audit cadence is set.

---

## Stretch goals

- **Multilingual coverage.** If the data is multilingual, add
  a second NLP model (e.g. `xx_ent_wiki_sm` as a baseline;
  per-language transformers for the actual production
  languages) and report per-language recall. Common failure
  mode: English-only recognisers quietly missing names in
  other scripts.
- **Trajectory-log DLP for agents.** For an agent system,
  extend the runtime profile to tool-argument content and
  intermediate reasoning. Tool arguments are often more
  sensitive than prompts (SQL queries with customer IDs).
  Measure recall on tool-argument content separately.
- **Recoverable redaction with KMS gating.** Implement a hash
  or encrypt operator for one entity (e.g. `CUSTOMER_ID` with
  a per-tenant salt); gate decryption on a mod-105 KMS access
  check and a documented break-glass workflow. Measure the
  additional risk the recoverable surface introduces.
- **Drift monitor.** Compute the per-day redaction-rate baseline
  per entity type; alert when a day sits outside the historical
  distribution (zero SSN redactions when the baseline is in
  the thousands). Name the alert routing.
- **DSAR / erasure wiring.** Produce a procedure that an
  erasure request (chapter 04) uses to find the data subject's
  records in the training-data snapshot, feature store,
  retrieval index, and prompt log. The DLP coverage log
  (counts only) is the search index for the "did any of this
  subject's data cross DLP" question.
- **Sample-audit rehearsal.** Run one actual sample audit —
  pull a 100-record sample, hand-review for misses, write up
  the findings, feed one improvement back into the profile.
  Report the delta on the eval set.
- **Second-DLP cross-check.** Run a second DLP pipeline
  (different vendor or different NLP model) on the same eval
  set; report where the two disagree. Disagreements are a
  cheap source of profile improvements.

---

## Do not

- Do not accept Presidio's defaults as the production profile.
  The `entities=None` default scans "all supported" and
  silently changes the surface across releases.
- Do not conflate recall and precision. A recogniser with
  99% recall and 20% precision over-redacts the training
  signal; a recogniser with 99% precision and 60% recall
  leaks.
- Do not store un-redacted inputs in a "raw" shadow log
  unless the governance for the shadow is signed off and the
  retention is bounded.
- Do not treat custom recognisers as throwaway regex. They
  are code; code-review, version-pin, and eval-test them.
- Do not log raw entity values in the coverage log — the
  coverage log would recreate the PII problem.
- Do not promote a profile that fails any SLO entity without
  a dated remediation plan and a named owner.
- Do not commit the solution bundle to this repo; solutions
  belong in the paired `-solutions` repo.
