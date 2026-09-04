# Exercise 05 — Immutable Audit Log Design Doc for an ML Platform

**Estimated effort:** ~3 hours
**Deliverable:** One Markdown design document containing (a) the
audit-event catalogue for the target ML platform, (b) the reference
architecture with authenticated event bus, WORM sink, and
tamper-evident log labelled, (c) the retention and legal-hold
matrix aligned to chapter 01's three drivers, (d) the concrete
cloud-provider configuration (S3 Object Lock / GCS Bucket Lock /
Azure Immutable Blob) with mode and retention decisions justified,
and (e) the monitor set and detection-independence write-up.
**Prerequisites:** Chapters 01 and 06 read end-to-end. Exercise 01
completed (the provenance architecture and retention schedule
provide the retention floors this design must honour). Mod-103
exercise 02 completed if you want a SPIFFE ID scheme to reference
for producer authentication.

---

## Objective

Author the **immutable audit-log design document** for the ML
platform: what events flow into it, how they are authenticated and
schema-validated on ingress, how they are stored under WORM with
tamper-evident structure, how they are replicated to survive
account compromise, how retention is set and legal holds are
applied, and who watches the log for rewrites.

By the end you should have a design document that an
implementation team could pick up and turn into
Terraform / Pulumi / cloud console clicks without further
requirements gathering, and that a governance auditor could read
end to end to confirm the platform can answer *"what happened
when, and can you prove nothing was rewritten"* under adversary.

## Problem statement

You are the AI/ML Security & Governance Engineer for the fintech
carried through mod-101 → mod-104. Current-state audit posture
(from exercise 01, section 4):

- **CloudTrail** on the AWS account holding the ML platform.
  Retention: 90 days in the S3 destination bucket.
- **Kubernetes audit logs** enabled on the GKE cluster; shipped
  to CloudWatch with 30-day retention.
- **MLflow tracking database** records training-run metadata,
  including dataset URI and metric values. Retention: unlimited
  by default; no cryptographic evidence of what was recorded.
- **No** event bus for ML-platform events (dataset promotion,
  training start / finish, admission decision, deployment
  applied). Those events exist only as application logs shipped
  to CloudWatch.
- **No** WORM storage anywhere. The S3 buckets are versioned
  but Object Lock is not enabled.
- **No** tamper-evident log. Rekor is used for public cosign
  signatures produced by CI, but no internal Trillian instance
  and no audit-event integration.
- **No** cross-account replication of any audit data. Everything
  lives in the same AWS account that runs the ML platform.

Regulatory context: the platform serves both EU and US
customers. Chapter 01's retention schedule (from your exercise 01
output) established regulator, incident-response, and monitoring-
window floors for each artifact class.

If you have a real ML platform to design against, substitute it
— the exercise structure is identical. State the substitutions
you made at the top of the document.

## Requirements

Produce a single Markdown design document with the following
sections.

### Section 1 — Audit event catalogue

A table listing every event that must flow into the audit stream.
Cover, at minimum, the classes in chapter 06's catalogue:

- `dataset.snapshot.created` / `dataset.snapshot.signed`
- `feature.materialisation.created` / `feature.materialisation.signed`
- `model.training.started` / `model.training.finished`
- `model.artifact.signed`
- `model.slsa.attested`
- `model.mlbom.attested`
- `model.eval.run`
- `model.admission.decision`
- `model.deployment.applied`
- `model.rollout.completed`
- `model.retirement`
- `key.signing.rotation`
- `governance.evidence.exported`
- `incident.declared` / `incident.closed`
- Elevated inference events under the three chapter-06 exceptions
  (privileged / sensitive context, tool-invoking agent action,
  audit-mode enabled during IR window).

Per event, columns:

| Event | Producer (SPIFFE ID or role) | Required fields | Emission point | Retention floor (from Ex. 01) | Detection consumer (mod-111) |

Rules:

- Every field listed for an event must be enough to reconstruct
  the *"who did what to what when, and outcome"* tuple without
  cross-referencing another system.
- Redaction rules for fields that must not appear in cleartext
  in the audit stream (raw prompts, PII in feature values) are
  called out.
- Elevated inference events name the criteria that promote them
  from metrics stream to audit stream.

Explicitly justify each item you *exclude* from the audit stream
(application `stderr`, GPU utilisation, request rate metrics) —
one line per exclusion is fine. The point is to prove you thought
about whether it belonged in the audit stream and decided no.

### Section 2 — Reference architecture

Diagram (Mermaid, PlantUML, ASCII, or image) of the audit-log
pipeline. Label:

- Every producer plane (training, admission, serving, governance,
  key-management, IR).
- The event bus (Kafka / Pub/Sub / EventBridge — pick one and
  justify).
- Schema registry and validation step at bus ingress.
- Fan-out destinations: SIEM (mod-111 consumer), WORM audit sink,
  tamper-evident log.
- Off-account and cross-region replication targets, showing
  ownership boundaries.
- The monitor plane and where it runs relative to the log server.

Immediately below the diagram, walk each numbered arrow with a
one-paragraph explanation of what flows across it, under what
identity, and what guarantee is being made at that point.

### Section 3 — Retention and legal-hold matrix

Table:

| Event class | Composed retention floor (from Ex. 01) | Cloud-provider retention mode | Legal-hold trigger events | Deletion approver | Deletion report recipient |

Rules:

- The composed retention floor is imported from your exercise 01
  output — this exercise does not re-derive it. If a floor is
  unknown at authoring time, cite the exercise-01 row that owns
  it, or insert a `<!-- needs-research: ... -->` marker.
- The retention mode is a concrete cloud-provider setting
  (`S3 Object Lock COMPLIANCE`, `GCS locked retention`,
  `Azure Immutable Blob time-based locked`). Explain the choice
  vs the alternative (e.g. why `COMPLIANCE`, not `GOVERNANCE`).
- Legal-hold trigger events must be phrased as events the
  platform can actually recognise (`incident.declared`, receipt
  of a preservation letter, opening of a regulator investigation).
- Deletion approver must be a role, never a named individual.
  Two-party approval is required for legal-hold clearance.
- Deletion reporter names the operational channel (email list,
  Slack channel, ticket queue) that receives the pending-deletion
  report before the automated deletion runs.

### Section 4 — Cloud-provider configuration

Provide the concrete configuration for the WORM sink on the
cloud provider carrying most of your workload. Match the
provider vocabulary chapter 06 uses.

#### Section 4a — WORM sink configuration

Include:

- Bucket name pattern and region layout.
- Object Lock / Bucket Lock / Immutable Blob mode and default
  retention.
- Encryption (KMS key ownership; is the KMS key in the same
  account as the bucket, or a different one — justify).
- Public-access block.
- Cross-region replication rule (filter, replica-region, KMS
  key on the replica side, delete-marker replication setting).
- Cross-account replication rule (destination account owner,
  destination account IAM policy summary, delete permissions on
  the destination).
- IAM policy statements (or their equivalent) that scope write
  access to only the ingest role and deny `Delete*` and `Put*`
  under any lifecycle transition.

Present as the config snippets you would hand to the platform
team, not as prose. `aws s3api put-object-lock-configuration ...`
is the shape.

#### Section 4b — Tamper-evident log choice

Pick one of the two chapter-06 composition patterns:

- **Pattern A**: hash-only entries appended to public Rekor as
  `hashedrekord`, with full events preserved separately in the
  WORM sink.
- **Pattern B**: private Trillian instance with DSSE-signed
  audit records.

Justify the choice against your platform's constraints
(regulator location, air-gap requirements, existing Sigstore
investment, ops budget for running Trillian). Then describe:

- Where the log server runs (managed service? self-hosted?
  which account? which cluster?).
- Signing key custody for the log's signed tree heads (mod-105
  reference).
- Verifier client shipped to consumers so external readers can
  independently prove inclusion.

### Section 5 — Producer authentication and schema

Two sub-sections.

- **Producer authentication.** Map each event producer to its
  SPIFFE ID (or role identity if SPIFFE is not yet in place —
  mark with a mod-103 dependency marker in that case). State
  the bus-side enforcement (`producer SPIFFE ID → allowed
  event type patterns`) and what happens on mismatch
  (`audit.producer.rejected` event, alert to whom).
- **Schema and versioning.** Pick JSON Schema (draft 2020-12) or
  Protobuf, and justify. Show the schema for one event as a
  worked example (`model.admission.decision` is a good choice
  because it is the highest-frequency, highest-value audit
  event). Describe the versioning rule (backward-compatible
  additions bump `event.version` minor; incompatible changes
  become a new event type). Name the schema registry.

### Section 6 — Monitors and detection independence

For each of the three monitor classes from chapter 06:

| Monitor | Cadence | Signal on failure | Owning team | Runs where |

- **Consistency monitor** — signed tree head must extend the
  last known tree head.
- **Inclusion monitor** — sample of events must remain provable
  against the current tree head.
- **Presence monitor** — heartbeat / expected-cadence events
  must appear.

Rules:

- The owning team must not be the same team that operates the
  log server. Call out how you achieve that (a governance /
  security-engineering team runs monitors; a platform team runs
  the log server). If your organisation cannot separate the
  two teams, state that as a residual risk in section 8.
- "Runs where" must be a substrate that does not share admin
  identity with the log server. Different cloud account, at
  minimum.
- Signals must include a specific paging / ticketing target
  (`page IR-on-call`, `open a P1 in <queue>`), not just "alert".

### Section 7 — Governance export workflow

Describe the two-party workflow chapter 06 sketches:

1. Requester (mod-109 governance operator) opens an
   evidence-export request with a stated purpose and scope
   (event types, time range, models).
2. Approval — who, how many, on what SLA.
3. Export tool runs against WORM sink + tamper-evident log,
   producing a bundle with (a) raw events, (b) inclusion proofs,
   (c) tree head at export time.
4. Bundle is signed by an evidence-export identity distinct from
   the requester's.
5. Bundle digest is emitted to the audit stream as
   `governance.evidence.exported`.
6. Delivery mechanism (secure download portal, S3 pre-signed URL
   with narrow expiry, physical media for regulator).

Include a template for the request form (name the fields).

### Section 8 — Residual risk register

At least five entries. For each, columns:

| Residual risk | Why it cannot be fully mitigated at this layer | Compensating control | Owning team | Acceptance approver |

Examples that must appear (add more as the platform requires):

- A privileged operator in the destination replication account
  colluding to delete replicas before retention expiry.
- Schema drift between producer version and validator version
  during a rolling upgrade of the event bus.
- Monitor plane compromise producing false-negative consistency
  checks.
- Regulator jurisdiction change requiring retention extension
  past the current retention lock.
- Failure of the tamper-evident log service (Rekor outage or
  Trillian data-loss event).

## Starter guidance

- Read chapter 06 with exercise 01's retention schedule
  alongside. Section 3 of this exercise is *your own exercise-01
  section-3 table*, filtered to just the events section-1 of
  this exercise defined, with the cloud-provider mode column
  added.
- Do not design SIEM detection rules here. Detection lives in
  mod-111. Section 1's "Detection consumer" column names the
  destination team, not the rule.
- Do not solve KMS key custody for the log's signed tree heads.
  That is a mod-105 concern; reference it and move on.
- Do not design the schema for every event exhaustively. One
  worked example (section 5) plus a promise of the same shape
  for the rest is enough.
- If a section forces a choice between competing standards or
  cloud-provider features, pick one, justify against the
  chapter-06 mistakes list, and note the alternative in the
  residual-risk register.
- Where a regulatory retention floor is uncertain, insert a
  `<!-- needs-research: ... -->` marker rather than guessing.
  A design doc that fabricates a retention floor is worse than
  one that flags an open question.

## Acceptance criteria

Passing work:

- Every event class in chapter 06's catalogue appears in section
  1, or is explicitly justified as out-of-scope for the target
  platform.
- The reference architecture in section 2 shows the SPIFFE-
  authenticated ingress, the fan-out, and the off-account
  replication — no missing hop.
- Retention in section 3 is imported from exercise 01, not
  re-derived, with visible cross-references. Every retention row
  names a concrete cloud-provider retention mode.
- Section 4 contains real configuration snippets, not prose
  describing what a configuration would look like.
- Section 4b names one of the two chapter-06 patterns and
  justifies the choice against the specific platform.
- Section 5 shows one full event schema; the versioning rule is
  concrete; the schema registry is named.
- Section 6 monitors are owned by a team separate from the log
  operator, or the failure to separate them is captured in
  section 8.
- Section 7 governance export is a two-party workflow with a
  distinct export-signer identity.
- Section 8 residual-risk register has ≥5 entries, each with a
  compensating control and an acceptance approver role.

Failing work:

- Uses `GOVERNANCE` mode where `COMPLIANCE` was appropriate,
  with no justification.
- Treats CloudTrail as the audit stream (it is the AWS control-
  plane audit, not the ML-platform audit — call the difference
  out).
- Puts audit events and application `stderr` in the same store.
- Runs monitors under the same admin identity as the log server
  with no note in the residual-risk register.
- Cross-region replication *within the same account*, described
  as "cross-account backup".
- Retention floors cited without exercise-01 provenance and
  without a `needs-research` marker.
- Governance-export workflow with no signing step or no audit
  emission on export.

## Stretch goals

- **Air-gap variant.** Design a variant of section 2 for an
  environment where the ML platform runs in an air-gapped
  region (no outbound network to public Rekor). Which chapter-
  06 pattern is forced by the constraint? Which controls become
  more expensive?
- **Regulator-accessible escrow.** Design the replication rule
  and access-control model for a regulator-accessible read-only
  replica of the audit stream. Which events are included, which
  are redacted, who controls the escrow, how a regulator
  authenticates.
- **Post-incident replay.** Describe the operational procedure
  for reconstructing the timeline of a compromised model from
  the audit stream: which events to pull, in what order, and
  how you would prove the timeline is complete (no missing
  entries) using tamper-evident log properties. This is the
  chapter-06 opening scenario, resolved.
- **Cost model.** Estimate the storage-plus-replication cost of
  the WORM sink at 7-year retention against the event volumes
  in your section 1. Which event classes dominate the bill?
  Which retention floors could be renegotiated at governance if
  the bill is prohibitive, and against which regime cites?
- **Cross-cloud replication.** Extend section 4 to replicate
  from the primary WORM sink to a different cloud provider.
  Name the replication mechanism, the reconciliation
  guarantees, and the trust model between the two providers'
  IAM systems.

## Do not

- Do not build the audit-log implementation in this exercise —
  the design document is the deliverable. Provisioning the
  bucket, wiring the event bus, and standing up Trillian
  belong to a follow-on implementation ticket, not this
  exercise.
- Do not author SIEM detection rules against the audit stream.
  That work belongs to mod-111 and would over-scope this
  exercise.
- Do not commit a solution to this repository — solutions live
  in the paired solutions repo.
- Do not invent regulatory retention floors. Cite from primary
  sources, and where a claim cannot be verified in the session,
  insert a `<!-- needs-research: ... -->` marker.
- Do not name specific vendor SIEM / log-management products as
  required components. The design should be portable across
  Splunk, Elastic, Datadog, Chronicle, etc. — those are
  consumers of the event bus, not the audit sink itself.
