# Exercise 01 — Provenance Architecture For One Training Pipeline

**Estimated effort:** ~2 hours
**Deliverable:** One Markdown document containing (a) the pipeline
diagram of a target training pipeline with signing / logging /
retention annotated per artifact class, (b) the retention schedule
table driven by regulatory, incident-response, and monitoring
horizons, and (c) a gap list of signed-vs-logged decisions the
current-state pipeline is missing.
**Prerequisites:** Chapter 01 read end-to-end. The mod-102 asset
inventory and the mod-103 zero-trust gap assessment for the same
target platform.

---

## Objective

For a target ML training pipeline, produce the **end-to-end
provenance architecture**: enumerate every artifact the pipeline
touches or produces (chapter 01's five object classes), name for
each *what is signed*, *what is logged*, and *what is retained
for how long*, and identify the gap between the current-state
pipeline and the reference architecture.

By the end you should be able to point at any object on the
pipeline diagram and answer: is it signed, by whom, into which
store; is it logged, into which stream, with what retention; and
which regulator / IR driver sets that retention.

## Problem statement

You are the AI/ML Security & Governance Engineer for the
fintech carried through mod-101 → mod-103. The current-state
training pipeline for the `fraud` model:

- **Data lake.** Raw training data lands in an S3 bucket
  `s3://acme-data-lake/fraud/`; the bucket is versioned but
  has no Object Lock. Snapshots are pointers to point-in-time
  prefixes referenced by `latest`.
- **Feature store.** Feast, backed by Redis (online) and
  Parquet in S3 (offline). Feature-view materialisations write
  to `s3://acme-features/fraud/`.
- **Training.** Kubeflow pipeline running on GKE. Pipeline
  step containers are built in GitHub Actions. Training
  containers pull PyTorch and `transformers` from PyPI at
  runtime (no vendored dependencies).
- **Model artifact.** Weights written to
  `s3://acme-models/fraud/<run-id>/weights.safetensors`.
  MLflow tracks the run URI and dataset URI as metadata.
- **Registration.** An MLflow model version is registered;
  the version is promoted through `staging` → `production`
  aliases manually by an ML engineer.
- **Signing.** None. There is a JIRA ticket to "add cosign"
  from last quarter, unassigned.
- **Audit logging.** CloudTrail on the AWS account;
  Kubernetes audit logs enabled but shipped to CloudWatch
  with 30-day retention.
- **Retention.** Ad-hoc — an S3 lifecycle rule moves objects
  under `s3://acme-models/` to Glacier after 90 days and
  deletes after 365. No exception for models still in
  production past 365 days.

If you have a real training pipeline in front of you (an
internal ML platform, a research pipeline you have permission
to model), substitute it — the exercise structure is
identical.

## Requirements

Produce a single Markdown document with the following sections.

### Section 1 — Pipeline diagram (max 1 page)

Draw the pipeline (Mermaid, PlantUML, ASCII, image — any
format that is version-controllable). Label:

- Every artifact produced or consumed, per chapter 01's five
  object classes: training data snapshot, feature set, model
  artifact, evaluation run, deployment / serving revision.
- Every workload / pipeline component that produces each
  artifact.
- Every store the artifact lands in (S3 prefix, MLflow, OCI
  registry, transparency log).
- Every external entity (CI, IdP, KMS, admission gate).

Legend included; boundaries labelled.

### Section 2 — Per-artifact signing / logging / retention table

One row per artifact from the diagram. Use the template:

| Artifact class | Instance | Producer | Signed? (by whom, into which log) | Logged? (event, stream) | Retention floor | Retention driver | Storage tier |

Rules:

- Every artifact class from chapter 01 has at least one row,
  even if the current-state pipeline does not produce it (in
  which case the row is a red flag for section 4).
- "Signed?" is either `NO`, or `YES: <signer identity> → <log
  destination>` (e.g. `YES: spiffe://acme.internal/plane/ci/…
  → rekor.acme.internal`).
- "Retention floor" is a duration or explicit date-based
  policy; write `NONE` if there is no floor.
- "Retention driver" is one or more of `regulatory
  (<regime>)`, `IR-window`, `model-monitoring`, or `NONE`.

### Section 3 — Retention schedule with the three drivers

Table form:

| Artifact class | Regulatory floor (with regime cite) | IR-window floor | Monitoring-window floor | Composed floor (max) | Storage tier | Deletion / legal-hold workflow |

Rules:

- Every regulatory citation must be traceable to a primary
  source (EU AI Act article, HIPAA section, ISO/IEC 42001
  clause, SR 11-7 section, jurisdiction-specific data-
  retention regime). If a claim cannot be verified in the
  session, insert a `<!-- needs-research: ... -->` marker
  rather than guessing.
- The composed floor is the maximum of the three drivers,
  never the minimum.
- The deletion workflow must name (a) who initiates deletion,
  (b) who approves, (c) how a legal hold blocks it.

### Section 4 — Gap list against the reference architecture

Turn chapter 01's reference architecture (arrows 1–7) into a
checklist. For each arrow, one row:

| Reference-architecture control | Current-state behaviour | Gap | Chapter that closes the gap | Effort estimate (person-weeks) |

The "chapter that closes the gap" column names the mod-104
chapter (02, 03, 04, 05, 06) or the paired module (mod-105
secrets, mod-110 supply chain, mod-111 SecOps) that owns the
remediation.

### Section 5 — Sequenced remediation roadmap

Turn the gap list into a sequenced roadmap. Order by:

1. **Blocking dependencies.** Signing (chapter 02) is a
   prerequisite for ML-BOM attestation (chapter 04) and card
   evidence linking (chapter 05). Order accordingly.
2. **Blast radius.** A gap that closes the "no immutable
   audit at all" bar outranks a gap that improves an
   already-signed artifact's metadata.
3. **Cost.** Cheaper controls first among equals.

Present as a numbered sequence with owners and target dates
(placeholders if you don't own the platform).

## Starter guidance

- Walk the diagram with chapter 01's reference architecture
  open alongside. Every arrow in the reference model must
  have a corresponding row in your table — including "NONE"
  rows, which are the interesting ones for section 4.
- The most common failure mode is treating MLflow's dataset
  URI or CloudTrail as evidence for the "logged" column. They
  are lineage / mutable log, not signed provenance nor WORM
  audit. Say so plainly rather than pretending.
- For the retention driver column, list *every* driver that
  applies. Do not pick the one that gives the shortest
  answer.
- Do not attempt to design the signing infrastructure or the
  admission gate — that is exercises 02 and (via mod-103
  exercise 05) already done. This exercise is the gap-and-
  roadmap; the depth on each gap comes from the paired
  chapters.

## Acceptance criteria

A passing document:

- Contains a diagram with all five object classes present
  (even if some are marked "not produced by current pipeline").
- Table in section 2 has one row per artifact and no cell left
  blank.
- Regulatory citations in section 3 either resolve to a
  primary source or carry a `needs-research` marker.
- Composed retention is always the max, never the min, of the
  three drivers.
- Gap list in section 4 maps every reference-architecture
  arrow to either "present" or a specific remediation ticket
  with an effort estimate.
- Remediation roadmap is ordered by dependency, not
  alphabetically.

A failing document:

- Cites regulatory retention floors without a primary source
  and without a `needs-research` marker.
- Uses "we ship CloudTrail" or "we track in MLflow" as
  evidence of a "signed" or "WORM audit" property.
- Claims composed retention equal to the minimum of the
  drivers.
- Skips any of the five object classes.
- Presents remediations as a wishlist rather than a sequenced
  plan with dependencies called out.

## Stretch goals

- Add an **evidence-link mapping** column to section 2 naming
  which downstream governance clause (ISO/IEC 42001, EU AI
  Act, NIST AI RMF, NIST SP 800-53 AU-family, SR 11-7) each
  artifact is evidence for. This turns the artifact table into
  mod-109 evidence input directly.
- Produce the same architecture for a **greenfield version**
  of the pipeline (as if you were designing it from scratch)
  and compare — which controls are cheaper to install day-one
  vs which are dramatically more expensive to retrofit.
- Extend section 3 with a **legal-hold rehearsal** — describe
  the concrete steps to put every audit object related to a
  hypothetical incident on legal hold within one hour of the
  incident declaration.
- Add a **cross-provider retention comparison** column: for
  the composed retention, note the specific API surface
  (Object Lock COMPLIANCE, GCS locked retention, Azure
  Immutable Blob) required for the storage tier chosen.

## Do not

- Do not build the signing infrastructure in this exercise
  (that's exercise 02).
- Do not author the ML-BOM (that's exercise 03).
- Do not author the model card (that's exercise 04).
- Do not commit a solution to this repository — solutions
  live in the paired solutions repo.
- Do not invent regulatory citations or retention floors —
  cite from primary sources, and where a claim cannot be
  verified, insert a `<!-- needs-research: ... -->` marker
  rather than guessing.
