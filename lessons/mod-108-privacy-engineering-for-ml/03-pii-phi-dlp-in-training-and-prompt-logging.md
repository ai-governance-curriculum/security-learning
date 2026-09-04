# Chapter 03 — PII/PHI DLP in Training and Prompt Logging

> **Note on AI-assisted content.** Presidio's built-in
> recogniser catalogue and API surface change between releases;
> the recogniser names, confidence semantics, and NLP-model
> integrations quoted below are pointers to *look up*, not
> authoritative citations. Verify against the current Presidio
> documentation before pasting into a config. See
> [`resources.md`](./resources.md).

---

## Why this chapter exists

The training data and the prompt log are the two paths by which
personal data enters ML systems most silently. Neither is a
customer-facing surface; both are ingest paths. Both are
routinely instrumented for observability without anyone
noticing that the observability is now a personal-data
processing operation with its own regulatory obligations.

The specific failure mode this chapter is written to prevent:

> An LLM assistant is deployed. Six months later, the platform
> team enables prompt logging to debug quality regressions. The
> log stores full prompt / completion pairs, indexed by user id,
> retained for 90 days. Users have been copy-pasting emails,
> tickets, and medical notes into the assistant. The prompt log
> is now a de-facto PII/PHI database — one the DPO did not know
> about, the data-classification catalogue does not list, the
> retention policy does not describe, the DSAR system cannot
> query, and the access-control policy treats as "engineer
> debug data". Discovery is a customer complaint or a routine
> audit, whichever comes first.

The mirror-image failure on the training path:

> A team fine-tunes a customer-support model on the ticket
> corpus. The corpus contains customer names, phone numbers,
> policy numbers, and free-text notes with sensitive personal
> content. Nobody ran DLP on ingest; nobody redacted the
> corpus. The model memorises phrases; occasionally regurgitates
> a policy number under adversarial prompting; and the training
> dataset itself is stored unredacted in the object store for
> the retraining lifetime.

DLP — **data loss prevention** in the classical sense: detect
personal identifiers in text, then redact / mask / block — is
the mitigation. This chapter wires it into two pipelines: the
training-data path and the runtime prompt / trajectory logging
path.

You leave this chapter able to:

- Place DLP at the right seams in the training path (ingest,
  feature build, pre-batch, sample audit) and the runtime
  path (input scrub, prompt-log redaction, retrieval-store
  scrub, output DLP).
- Configure **Presidio** (or an equivalent) as the recogniser
  and anonymiser stack; tune per-entity recognisers to the
  org's domain (SSNs, MRNs, national IDs, tenant-specific
  identifiers).
- Measure DLP recall and precision on a labelled evaluation
  set; report per-entity F1 as a live metric.
- Choose between **irreversible** and **recoverable**
  redaction and document the choice in the mod-104 lineage
  record.
- Produce the **DLP-coverage evidence artefact** that names
  where DLP runs, what entities are covered, and what the
  per-entity recall and precision are.

Chapters 04 and 05 use this chapter's DLP as one of the
technical controls that discharge GDPR Art. 25 (data protection
by design) and the HIPAA Security Rule's technical safeguards.

---

## The three surfaces that need DLP

### Training data — before it becomes a model

The training path has four seams where DLP can sit; usually
several are used together:

- **Ingest.** DLP scans data as it lands from source systems
  (ticket store, log warehouse, CRM export, sensor feed). Runs
  once per record; produces a redacted / labelled version.
  Failure blocks ingest.
- **Feature build.** DLP runs at feature-store commit time.
  Catches personal data in fields that were not scanned at
  ingest (aggregation columns, free-text derived features).
  Fits the modern "batch feature pipeline" pattern.
- **Pre-batch.** DLP runs on the training batches immediately
  before the trainer consumes them. Rare (expensive) but
  useful as a defence-in-depth check when upstream trust is
  low.
- **Sample audit.** A statistical sample of training data is
  read by a human or a second DLP pipeline post-training as
  an evidence-generation step. Doesn't prevent leakage; proves
  the coverage.

Choose seams based on the data flow's shape:

- **Data lands from many sources with weak upstream ownership.**
  Ingest DLP is mandatory; feature-build DLP is
  defence-in-depth.
- **Data is authored inside a curated feature store.**
  Feature-build DLP is primary; ingest may not exist as a
  separate stage.
- **Data flows continuously (streaming).** Ingest DLP runs
  per-record; sample-audit is the coverage metric.
- **Data is periodically snapshotted from source (batch
  ETL).** Ingest DLP runs per-batch on new records; sample-
  audit covers the whole batch.

Regardless of seam, three properties must hold:

- **The redacted form is what the trainer sees.** The raw
  form, if retained at all, is retained separately with
  stricter access controls and a different retention.
- **The redaction is logged.** Every redaction event
  (record, entity type, span) is written to a coverage log.
  Coverage % per entity type is the SLO.
- **A per-record hash lets the same record be linked across
  retrainings.** Different retrainings should see the same
  redaction result on the same record; if not, the coverage
  metric is unstable.

### Prompt / trajectory logging — the runtime surface

Inference-time logging captures inputs and outputs. Nearly
every LLM and agent system logs; the logs are usually where the
worst surprises hide.

Log types to think about:

- **Prompt log.** Full user input + model output pairs.
  Highest leakage risk.
- **Trajectory log.** For agents, the sequence of tool calls,
  retrieved documents, and intermediate reasoning steps
  (mod-107 chapter 05). Contains everything the prompt log
  does plus intermediate tool arguments (which are often more
  sensitive — e.g. an SQL query with a customer id).
- **Retrieval log.** Which documents were retrieved for which
  queries. Attributable to a user; combines two personal-data
  sets (query + document).
- **Debug log.** Free-text engineer log lines from the
  runtime. Historically the worst — random `logger.info`
  calls print prompt fragments to a shared file.
- **Metrics.** Per-request latency, token counts, tool-call
  identifiers. Usually low-PII but occasionally not (a "tool
  name" that includes a user id, a "reason" field that
  contains prompt text).

DLP placement in the runtime path:

- **Input scrub (before storage).** DLP runs on user input at
  ingest into the log; the log stores the redacted form. The
  original may be discarded (irreversible redaction) or
  retained separately with tighter controls (recoverable).
- **Retrieval-time scrub.** DLP runs on retrieved documents
  before they hit the prompt. If the retrieval store is
  itself DLPed on ingest (below), this may be a defence-in-
  depth check.
- **Output DLP (before storage and before return-to-user).**
  DLP runs on model output — flags or redacts SSN patterns,
  credit-card patterns, email formats. Return-to-user may
  block or warn; log storage stores the redacted form.
- **Trajectory redaction.** Tool arguments and results run
  through DLP before storage; the trajectory is stored
  redacted.

For the runtime, the design decision is: **who is allowed to
see the un-redacted form and under what governance?** A
prompt log with un-redacted prompts stored for on-call debug
is a governance decision — write it down. A prompt log with
un-redacted prompts stored *by default* is usually a mistake.

### Retrieval / RAG stores — the third leakage surface

If the retrieval store is populated from customer content —
tickets, documents, emails — the store itself is a personal-
data corpus. Every answer built from it inherits whatever
was in it.

DLP on the retrieval store:

- **Runs at ingest.** Every document / chunk is redacted /
  labelled at ingest time. The store keeps the redacted form
  as the retrievable text and keeps the labels (entity types,
  spans) as metadata.
- **Row-level ACLs.** Per chapter 02, retrieval hits are
  authorised per-caller. DLP is not a substitute for ACLs;
  they compose.
- **Purge on erasure.** DSAR / right-to-erasure requests hit
  the retrieval store too. The chunk index must support
  deletion by data-subject id.

The retrieval store's DLP coverage is a first-class metric
alongside the training-data coverage; both feed the DPIA
(chapter 04).

---

## Presidio as the reference recogniser stack

Presidio (Microsoft, open-source) is the reference PII
recogniser stack for this chapter. Alternatives include Google
Cloud DLP, AWS Comprehend, and hand-rolled regex+NLP stacks;
the design pattern is common.

Presidio has two main components:

- **Analyzer.** Runs a set of *recognisers* against text and
  emits a list of PII entities with type, span, and score.
- **Anonymizer.** Takes analyzer results and produces a
  redacted / masked / hashed / replaced text.

A recogniser is a rule + optional model:

- **Pattern recognisers.** Regex + validation (Luhn check for
  credit cards; ABA routing check; NHS number checksum).
  Reliable when the pattern is strict; false-positive prone
  when loose.
- **NLP recognisers.** Named-entity recognition (NER) via
  spaCy, transformers, or Stanza; used for open-vocabulary
  entities (PERSON, LOCATION, ORGANIZATION).
- **Custom recognisers.** Domain-specific — the org's
  employee-id format, the tenant-specific transaction id, an
  MRN pattern for a specific hospital.

Presidio ships with recognisers for common entities: SSN, credit
card, phone, email, IP address, date of birth, IBAN, ABA routing,
UK NHS number, US driver license, US ITIN, US passport, and
many others (verify the current list against the release
notes). It supports multiple languages via language-specific
NLP models.

The minimal wire-up (illustrative — verify against the current
Presidio API):

```python
from presidio_analyzer import AnalyzerEngine
from presidio_anonymizer import AnonymizerEngine

analyzer = AnalyzerEngine()
anonymizer = AnonymizerEngine()

text = "Call John Smith at 555-123-4567 about the account 1234567890."

# entities: None means "all supported"; usually pin the list.
results = analyzer.analyze(
    text=text,
    language="en",
    entities=["PERSON", "PHONE_NUMBER", "US_BANK_NUMBER"],
)

anonymized = anonymizer.anonymize(text=text, analyzer_results=results)
print(anonymized.text)
# → "Call <PERSON> at <PHONE_NUMBER> about the account <US_BANK_NUMBER>."
```

Three properties to configure explicitly:

- **`entities` is pinned.** Do not accept "all supported" as
  the entity set — the coverage metric depends on knowing
  what is being recognised. The tier map (chapter 01) implies
  which entities are in scope for the data class.
- **`score_threshold` is chosen per-entity.** Presidio
  recognisers return a confidence in `[0, 1]`. A single global
  threshold sacrifices either recall (too high) or precision
  (too low) for some entities. Tune per entity on labelled
  data.
- **The NLP model is pinned.** Presidio's default is a spaCy
  model; pinning to a specific model version is part of the
  reproducibility promise. Model upgrades change recognition
  behaviour.

### Adding a custom recogniser

Every org has entities Presidio's defaults do not cover — the
internal customer id, the internal case number, the tenant's
MRN format. A pattern recogniser (illustrative):

```python
from presidio_analyzer import PatternRecognizer, Pattern

case_number_pattern = Pattern(
    name="CASE_NUMBER",
    regex=r"\bCASE-[A-Z0-9]{8}\b",
    score=0.9,
)

case_number_recognizer = PatternRecognizer(
    supported_entity="CASE_NUMBER",
    patterns=[case_number_pattern],
    context=["case", "ticket", "reference"],
)

analyzer.registry.add_recognizer(case_number_recognizer)
```

Every custom recogniser gets:

- A **name** used in configs and logs.
- A **pattern or model** with an evaluation baseline (recall,
  precision) on a labelled evaluation set.
- A **`context` list** that raises the score when the pattern
  appears near contextual keywords (reduces false positives
  in unrelated text).
- A **release history** with a version pinned in the tier map.

Custom recognisers are code; they live in the ML-security
team's repository, are code-reviewed, tested, and versioned.

### Anonymisation operators

Presidio's Anonymizer supports several operators; pick per
entity type and per surface (training vs log):

- **Replace.** Substitute with a placeholder (`<PERSON>`).
  Irreversible; simplest; typical for training data.
- **Redact.** Delete the span. Even more irreversible; keeps
  no signal about the entity type.
- **Mask.** Partial redaction (`***-**-1234`). Retains some
  structure — useful for tenant-side debugging when the last
  four digits are meaningful — but is not a full redaction.
- **Hash.** Cryptographic hash. Deterministic for lookup /
  linking; leaks nothing about the value; but rainbow-table
  attacks against known-format values (SSN, credit card) are
  practical — salt with a per-tenant secret.
- **Encrypt.** Symmetric encryption. Reversible with the key;
  the key becomes a mod-105-managed secret; access to raw
  data becomes access to the key.
- **Custom.** Domain-specific — the org's tokenisation
  service, the format-preserving encryption library.

The choice per entity type is a policy decision that lands in
the DLP profile:

```yaml
# dlp_profile.yaml
name: training_data_v3
description: "Training-data DLP profile for the risk model."
version: "3.1.0"
nlp_model: spacy_en_core_web_lg==3.7.1
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
  US_BANK_NUMBER:
    recogniser: builtin
    threshold: 0.85
    action: mask
    mask_char: "*"
    chars_to_mask: 6
    from_end: false
  CASE_NUMBER:
    recogniser: custom
    version: "1.2.0"
    threshold: 0.9
    action: hash
    salt_ref: "kms://alias/dlp-salt-2026-q1"
  PHONE_NUMBER:
    recogniser: builtin
    threshold: 0.7
    action: replace
    placeholder: "<PHONE>"
```

Every entity has a threshold, an action, and where relevant a
key reference. The profile is version-controlled and pinned in
the training-plan config (chapter 01 packet Section 6).

---

## Irreversible vs recoverable redaction

The choice of operator (replace / redact vs. hash / encrypt)
is the choice between **irreversible** and **recoverable**
redaction. Both have use cases; the decision matters and
should be explicit.

**Irreversible** redaction (`replace`, `redact`):

- Once redacted, the original is gone (unless a separately-
  controlled raw copy is retained).
- Preferred for **training data** — the trainer should not
  need to see the raw value to learn the pattern.
- Preferred for **prompt logs used for aggregate quality
  monitoring** — the debugger does not need the raw prompt to
  see that quality dropped.
- Simplifies DSAR: the redacted form does not identify the
  data subject.

**Recoverable** redaction (`hash`, `encrypt`, format-preserving
encryption, tokenisation):

- The original is retrievable given a key.
- Necessary when downstream systems need to **join across
  records** on the personal identifier (a `hash` operator
  makes join possible without exposure).
- Necessary when a **specific-caller-authorised debug path**
  needs to see the raw value (a `decrypt` operator gated on
  KMS access).
- Recoverability makes DSAR harder: the redacted form may
  still be personal data because a key-holder can reverse it.
  Retention policy applies to the redacted form.

A common pattern in practice:

- **Training data:** irreversible replacement or redaction.
- **Feature-store join keys:** salted hash (irreversible on
  the training side but stable for join).
- **Prompt log for aggregate quality:** irreversible.
- **Prompt log for individual on-call debug:** either not
  retained, or retained with per-tenant encryption whose key
  is unlocked per request under a break-glass procedure.
- **Retrieval index:** irreversible replacement inside chunk
  text; per-document metadata (author, timestamp) retained
  with access control.

The choice per surface is captured in the mod-104 lineage
record. mod-105's KMS holds the keys for recoverable schemes.

---

## Recognition quality — recall, precision, per-entity F1

DLP that "looks like it works" but has 60% recall on SSNs is
worse than no DLP — it produces a false sense of coverage.
Every DLP profile requires a **labelled evaluation set** and a
per-entity F1 measurement.

The evaluation set:

- **Realistic distribution.** Text that looks like the
  production data. Synthetic-only evaluations underestimate
  false negatives caused by natural-language noise.
- **Per-entity ground truth.** Every span of every entity type
  is annotated; both entity type and span extent are
  evaluated. Off-by-one or wrong-type mistakes are common
  failure modes.
- **Adversarial / edge cases.** Numbers-as-words ("five five
  five one two three"), obfuscated formats ("s.s.n.: 1 2 3
  4 5 6 7 8 9"), OCR errors, transliterations. Adversaries
  and users both produce these.
- **Version-controlled.** The eval set is pinned; changes to
  the eval set are reviewed.

Per-entity metrics to report:

| Entity | Recall | Precision | F1 | 95% CI | Coverage SLO |
| --- | --- | --- | --- | --- | --- |
| US_SSN | 0.98 | 0.99 | 0.985 | ±0.003 | ≥ 0.99 recall |
| PERSON | 0.91 | 0.87 | 0.89 | ±0.01 | ≥ 0.90 recall |
| PHONE_NUMBER | 0.94 | 0.95 | 0.945 | ±0.01 | ≥ 0.95 recall |
| CASE_NUMBER | 0.99 | 1.00 | 0.995 | ±0.001 | ≥ 0.99 recall |
| MRN | 0.86 | 0.92 | 0.89 | ±0.02 | ≥ 0.95 recall — **below SLO, remediation open** |

The SLO band per entity should reflect the entity's leakage
risk. SSN and MRN carry high leakage risk; the SLO is tight.
PERSON has different economics — a `<PERSON>` mask that keeps
92% of names is enough for most training uses.

The measurement runs at profile-change time and on a nightly
schedule against the pinned eval set. Regressions block promo­
tion of the profile.

Common failure modes in recognition quality:

- **Recall reported without precision.** A recogniser with 100%
  recall and 20% precision destroys the training signal by
  over-redacting; it also cries wolf on the coverage report.
- **F1 reported without per-entity breakdown.** An aggregate
  F1 hides the low-recall entity that is the actual risk.
- **Eval set drawn from the same source as training data.**
  If the eval set is a leaked subset of the production data,
  recall on the eval set may not reflect production. Draw the
  eval set from a separate source or a synthetic distribution.
- **Model version drift.** The NER model gets upgraded; recall
  changes silently. Pin the model.

---

## The DLP-coverage evidence artefact

The evidence artefact is what the DPIA (chapter 04) references
and what a governance audit (mod-109) reads. It has three
parts:

### Part 1 — Profile registry

```yaml
# dlp_profiles.yaml
profiles:
  - name: training_data_v3
    scope: [training_pipeline_risk_model]
    surface: training
    version: "3.1.0"
    entities: [PERSON, US_SSN, US_BANK_NUMBER, CASE_NUMBER, PHONE_NUMBER]
    reversibility: irreversible
    profile_file: "configs/dlp/training_data_v3.yaml"
    eval_report: "reports/dlp/training_data_v3_2026-09-01.md"
  - name: prompt_log_default
    scope: [assistant_prompt_log]
    surface: runtime
    version: "1.4.0"
    entities: [PERSON, US_SSN, PHONE_NUMBER, EMAIL_ADDRESS, CREDIT_CARD]
    reversibility: irreversible
    profile_file: "configs/dlp/prompt_log_default.yaml"
    eval_report: "reports/dlp/prompt_log_default_2026-09-01.md"
  - name: retrieval_index_v2
    scope: [rag_ticket_index]
    surface: retrieval
    version: "2.0.1"
    entities: [PERSON, US_SSN, CASE_NUMBER, PHONE_NUMBER, EMAIL_ADDRESS]
    reversibility: irreversible
    profile_file: "configs/dlp/retrieval_index_v2.yaml"
    eval_report: "reports/dlp/retrieval_index_v2_2026-09-01.md"
```

Every profile has a scope (which data flow it applies to), a
surface (training / runtime / retrieval), a reversibility
posture, and pointers to the profile file and the latest eval
report.

### Part 2 — Coverage metrics per profile

The per-entity F1 table above, rendered per profile and per
release, is committed alongside the profile. A CI job runs
against the eval set on profile changes and on schedule; the
report is committed.

### Part 3 — Operational coverage log

At runtime, every DLP invocation writes a coverage log entry:

- Timestamp.
- Profile name + version.
- Record identifier (hash if the record itself has PII).
- Entity types found + counts.
- Redaction operator applied per entity.
- No raw text; no raw entity values.

Aggregated per profile per day:

- Records scanned.
- Records with at least one hit.
- Total redactions per entity type.
- Percentile latency of DLP invocation.

The aggregated metrics feed the platform observability dashboard.
Anomalies — a training day with zero SSN detections when the
running average is thousands — are alerts.

---

## Wire-level integration

### Training pipeline

The training pipeline calls DLP as a step in the DAG:

```
raw_ingest → dlp_scan(training_data_v3) → feature_build → training_batch → trainer
```

Properties:

- The DLP step's output is the *only* output the downstream
  step consumes. Raw ingest is retained (or not) under a
  separate ACL and retention.
- The DLP step is idempotent per record — the same record
  produces the same redaction across runs.
- The DLP step's failure is a pipeline failure. There is no
  "fallback to raw" mode.
- The DLP step's profile version is captured in the mod-104
  lineage record for the resulting model.

### Runtime prompt / trajectory log

The runtime writes to the log through a DLP wrapper:

```
request → analyze_input → scrub_input (dlp_scan(prompt_log_default))
        → model_call → analyze_output → scrub_output → log_write(redacted_form)
```

Properties:

- The redacted form is what the log stores. The un-redacted
  form is *not* also written to a "raw" log unless there is
  a documented business need and a matching ACL.
- The DLP step's failure is a **decision point**: block the
  log write (fail closed — safer) or write with a
  "dlp_failed" tag (fail open — worse). Pick fail-closed as
  default; fail-open only for explicitly-documented log
  streams with compensating controls.
- The prompt log's ACL matches the sensitivity of the
  redacted form. Even a well-redacted prompt log is
  personal-data-adjacent (behavioural pattern data).

### Retrieval store

The retrieval store applies DLP at ingest and at update:

```
document_arrival → dlp_scan(retrieval_index_v2) → chunk → embed → index_write
```

Properties:

- The index stores the redacted chunk text. If similarity
  search returns the chunk to the caller, the caller sees
  the redacted form.
- If the retrieval-store metadata retains an "original" copy
  for compliance reasons, that copy is stored separately with
  tighter controls.
- Erasure requests hit the index — chapter 04 walks the DSAR
  wiring.

---

## Sample audit — the "prove the coverage" step

Automated DLP is fallible. A **sample audit** provides evidence
that the coverage claim is real:

- **Frequency.** Quarterly or per training-plan approval,
  whichever is sooner.
- **Sample size.** A statistically defensible sample from the
  redacted output — usually a few thousand records.
- **Reviewers.** A human reviewer (or a second, independent DLP
  pipeline) reads the redacted records and looks for missed
  entities.
- **Report.** Missed entities, per-type; new adversarial
  patterns; recommended profile changes. The report is
  version-controlled alongside the profile.

Sample audits are the evidence the DPIA cites when claiming
"DLP coverage is >99% recall for high-risk entities". Without
a periodic audit, the coverage claim is only as fresh as the
last automated eval.

For prompt logs, the sample audit is often the *only* time
anyone reads the log content. The audit process is a
personal-data processing activity itself — access is logged;
reviewers are named; the review is limited to redacted output.

---

## Standard failure modes

- **DLP configured but not measured.** A profile ships with no
  eval report; coverage is asserted, not proven. Fix: eval
  report is a release-gate artefact.
- **DLP thresholds copied from the default.** Per-entity
  tuning skipped; recall is unknown on the org's data. Fix:
  per-entity thresholds set on the labelled eval set.
- **"Fallback to raw" on DLP failure.** A DLP outage becomes a
  silent bypass. Fix: fail-closed; DLP failure is a pipeline
  incident.
- **Prompt log "temporarily" enabled without DLP.** The most
  common source of a prompt-log incident. Fix: prompt logging
  is a first-class product feature; the DLP profile is a
  ship-blocker for enabling it.
- **Custom recogniser without versioning.** The regex changes;
  historical redactions are inconsistent. Fix: custom
  recognisers are code; they get a version and a release
  history.
- **NLP model unpinned.** Silent recall drift when the model
  updates. Fix: pin the model version in the profile.
- **Recoverable redaction without KMS access controls.** Any
  engineer can decrypt. Fix: mod-105 KMS access controls
  gate reversibility; decryption is a break-glass procedure.
- **Retrieval index not scanned.** RAG store contains raw
  personal data; DLP was scoped to training only. Fix: every
  data flow gets a profile.
- **Coverage log stores raw entity values.** The coverage log
  becomes its own PII store. Fix: coverage log stores counts
  and types, not values.
- **DSAR requests don't reach the retrieval index or the
  prompt log.** DLP redacted the primary identifier, but the
  data subject is still identifiable in other stores. Fix:
  DSAR wiring (chapter 04) reaches every store, not just the
  primary database.
- **Sample audit not performed.** Coverage claim is only as
  fresh as the last automated eval; adversarial patterns
  discovered externally. Fix: quarterly sample audit is on
  the DPO calendar.

---

## The mistakes this chapter is trying to prevent

- **Prompt logging as an afterthought.** The log is
  personal-data processing. Design it as such.
- **DLP framed as "add regex".** Real DLP is a per-entity
  precision-recall trade-off with a labelled eval set and a
  measurable SLO.
- **Trust in the recogniser catalogue.** Presidio's built-ins
  are a starting point; the org's actual data has custom
  entities and custom edge cases the built-ins do not know
  about.
- **Reversibility as a default.** "Encrypt the PII" sounds
  safe until an engineer with the key runs a report against
  the encrypted store. Reversibility is a specific choice
  with specific access controls.
- **Coverage metrics that hide the tail.** Aggregate F1 looks
  fine; the SSN recall is 60%. Per-entity metrics or nothing.
- **DLP without lineage integration.** The training-data
  redaction is not attached to the model card; the audit
  cannot trace which model was trained on which redaction
  profile. mod-104 owns the lineage; this chapter feeds it.

---

## Summary

- Training data, prompt / trajectory logs, and retrieval
  stores are the three surfaces where PII / PHI enters ML
  systems most silently. Each needs DLP; each has different
  placement seams.
- **Presidio** is the reference recogniser stack: analyzer +
  anonymiser, built-in pattern and NLP recognisers, custom
  recognisers for domain entities.
- Every DLP profile has a **pinned recogniser set**, a
  **per-entity threshold**, a **per-entity action**
  (replace / redact / mask / hash / encrypt), and a **pinned
  NLP model version**.
- Choose **irreversible vs recoverable** redaction per surface
  and document the choice. Training data → irreversible;
  join keys → hashed; on-call debug (if it exists) →
  encrypted under break-glass KMS access.
- Recognition quality is measured on a **labelled evaluation
  set** with **per-entity recall, precision, and F1**.
  Regressions block profile promotion. Sample audits close
  the loop the automated eval cannot.
- The **DLP-coverage evidence artefact** — profile registry,
  per-profile eval reports, aggregated operational coverage
  log — is what the DPIA (chapter 04) cites and what a
  governance auditor is handed.
- DLP fails **closed**. A DLP outage is a pipeline incident;
  a "fallback to raw" mode is a silent-bypass bug waiting to
  happen.
- The DLP pipeline is **not** the DP guarantee. Chapter 01's
  budget and chapter 02's inference-attack controls are
  separate; DLP prevents PII from *entering* the model /
  log, DP prevents leakage from what did enter, and inference
  controls limit what the deployed surface reveals. All
  three ship together for regulated data.
