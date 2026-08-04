# Chapter 06 — Immutable Audit Log Architecture: WORM, Object Lock, Tamper-Evident Trees

> **Note on AI-assisted content.** Cloud object-lock APIs
> (S3 Object Lock, GCS Bucket Lock, Azure Immutable Blob) and
> transparency-log implementations (Trillian, Rekor, Sigstore Log)
> evolve across releases. Verify current API surfaces, default
> retention semantics, and cross-account replication guarantees
> against the primary docs before deploying. See
> [`resources.md`](./resources.md).

---

## Why this chapter exists

Chapters 02–05 produced signed artifacts and evidence-linked
cards. The signatures give integrity of the *content*; this
chapter gives integrity of the *record* — the append-only,
tamper-evident audit trail of every training, evaluation,
admission, and inference event across the ML platform.

The specific failure mode this chapter is written to prevent:

> A model is compromised. The team knows *which* model — the
> admission decision from three months ago admitted a
> backdoored artifact. Reconstruction requires finding the
> admission-decision log, the training-run log, the dataset-
> ingest log, and every inference request the model served.
> Investigators pull CloudTrail. The relevant records are
> missing — not deleted, exactly, but the account admin
> credentials had been compromised the same week, and someone
> with `iam:PutBucketPolicy` had disabled versioning on the
> audit bucket. Nothing has cryptographic evidence of what was
> there before. The incident timeline cannot be reconstructed.
> The regulatory notification is late because the team cannot
> answer basic questions about what happened.

An audit log is only useful under adversary. Under
non-adversarial conditions any log works. Under adversary — the
condition that matters — an ordinary log with write access
retained by the account is worth roughly nothing.

The controls that give an audit log integrity under adversary:

1. **WORM storage** (Write-Once, Read-Many): once written, the
   object cannot be modified or deleted until a retention
   period elapses — enforced by the storage system, not by
   application policy.
2. **Off-account / cross-region replication** so a
   single-account compromise cannot delete the copy.
3. **Tamper-evident structure** (Merkle tree with signed tree
   heads) so any rewrite is detectable, not just resisted.
4. **Retention lock** so even the account owner cannot shorten
   the retention window mid-flight.
5. **Segregated write identity** so the source of writes is
   authenticated (SPIFFE / IAM role) and unexpected writers
   are visible.

You leave this chapter able to:

- Design a WORM audit-log architecture for the training,
  admission, inference, and governance event streams the ML
  platform produces.
- Configure S3 Object Lock / GCS Bucket Lock / Azure Immutable
  Blob with retention semantics that survive account
  compromise.
- Compose that storage with a tamper-evident log
  (Trillian, Rekor) so rewrites are detectable.
- Set retention floors driven by the three chapter-01 drivers
  and lay out the deletion / legal-hold workflow.
- Enumerate what belongs in the audit stream vs the metrics
  stream vs the debug-log stream, and why the audit stream is
  narrower.

---

## Three streams, three trust bars

A common mistake is treating "logs" as one substance. There are
at least three streams flowing off any ML platform, with
different volume, retention, and integrity requirements.

| Stream | Contents | Volume | Retention | Integrity requirement |
| --- | --- | --- | --- | --- |
| **Debug / trace logs** | Application `stderr`, request traces, GPU utilisation metrics, tokenizer decisions | Very high | Days to weeks | Low — mutable OK, sampling OK |
| **Metrics** | Aggregated request rates, latencies, model-quality drift metrics | High | Months | Medium — retention policy but not tamper-proof |
| **Audit events** | Every action with authorisation semantics: model signed, model attested, model admitted, model deployed, model deleted, dataset promoted, admission decision, inference-with-privileged-context | Low | Years | **High — WORM, retention-locked, tamper-evident** |

This chapter is about the *third* stream. The first two are
managed differently (SIEM ingestion, metric TSDBs, log-management
platforms) and are not the audit trail.

The **audit stream is deliberately narrow**. Every entry is:

- **Actionable at audit** — someone will ask about it.
- **Emitted at a security-relevant event boundary**.
- **Signed at emission** where practical (Rekor entry or DSSE
  envelope).
- **Written to a WORM store**.

Do not shove application `stderr` into the WORM store. Storage
cost is the least of the reasons; the real reason is that mixing
narrows the auditor's search surface and softens the "everything
here is audit-worthy" property.

---

## The event catalogue

The audit stream for an ML platform, per chapter 01's five
object classes, at minimum:

| Event | Emitted by | Fields |
| --- | --- | --- |
| `dataset.snapshot.created` | Ingest pipeline | snapshot digest, upstream sources, row count, sensitivity class, region, ingest SPIFFE ID |
| `dataset.snapshot.signed` | Ingest pipeline | snapshot digest, Rekor UUID, signer identity |
| `feature.materialisation.created` | Feature pipeline | materialisation digest, upstream snapshot digest, feature view, timestamp |
| `feature.materialisation.signed` | Feature pipeline | materialisation digest, Rekor UUID, signer identity |
| `model.training.started` | Training orchestrator | run ID, source revision, dataset digest, base model digest, hyperparameters, trainer SPIFFE ID |
| `model.training.finished` | Training orchestrator | run ID, artifact digest, byproduct URIs, duration, exit status |
| `model.artifact.signed` | Signing step | artifact digest, Rekor UUID, signer identity |
| `model.slsa.attested` | Signing step | artifact digest, attestation Rekor UUID |
| `model.mlbom.attested` | Signing step | artifact digest, ML-BOM Rekor UUID, aggregate flag |
| `model.eval.run` | Evaluation pipeline | model digest, eval-set digest, result, Rekor UUID, evaluator SPIFFE ID |
| `model.admission.decision` | Admission controller | request namespace, request kind, artifact digest, decision (admit/deny), evidence consulted, policy version, requestor SPIFFE ID |
| `model.deployment.applied` | Deployment controller | Kubernetes resource kind + name + namespace, artifact digest, revision, applier SPIFFE ID |
| `model.rollout.completed` | Deployment controller | resource + revision, healthy replica count, timestamp |
| `model.retirement` | Ops workflow | resource, replaced-by digest (or none), retirement reason |
| `key.signing.rotation` | Key-management workflow | old key ID, new key ID, effective date, retention decision |
| `governance.evidence.exported` | Governance workflow (mod-109) | export bundle digest, requestor, purpose, timestamp |
| `incident.declared` / `incident.closed` | IR workflow (mod-111) | incident ID, severity, models involved, timeline |

Inference events are *usually* metrics-stream not audit-stream —
too high-volume, too little per-event value — with three
exceptions to elevate to audit:

- Any inference against a **privileged / sensitive** context
  (admin panel, internal-only surface, high-value transaction).
- Any inference that **invoked tools** or wrote external state
  (an LLM agent action — mod-107 walks this).
- Any inference under **incident-response evidence collection**
  (audit-mode enabled for a specific window after an incident
  is declared).

For every event, the fields are enough to reconstruct the
"who did what to what when, and what was the outcome" tuple.

---

## Reference architecture

```
        ┌───────────────────┐    ┌───────────────────┐    ┌───────────────────┐
        │ training pipeline │    │ admission gate    │    │ serving plane     │
        └────────┬──────────┘    └──────────┬────────┘    └──────────┬────────┘
                 │                          │                        │
                 ▼                          ▼                        ▼
        ┌────────────────────────────────────────────────────────────────────┐
        │  Event bus  (Kafka / Pub/Sub / EventBridge — durable, replayable)   │
        │  — every producer authenticated by SPIFFE ID                        │
        │  — schema-validated at ingress (JSON Schema / Protobuf)              │
        └────────────────────────────┬────────────────────────────────────────┘
                                     │
                     ┌───────────────┼───────────────────────┐
                     │               │                       │
                     ▼               ▼                       ▼
         ┌────────────────┐  ┌────────────────┐    ┌────────────────────┐
         │ SIEM ingest    │  │ WORM audit sink │    │ Tamper-evident log │
         │ (mod-111)      │  │ (Object Lock)   │    │ (Trillian / Rekor) │
         └────────────────┘  └────────┬────────┘    └────────────────────┘
                                      │
                          ┌───────────┼───────────┐
                          │                       │
                          ▼                       ▼
                ┌──────────────────┐    ┌──────────────────┐
                │ Cross-region     │    │ Off-account      │
                │ replication      │    │ replication      │
                │ (retention lock  │    │ (different       │
                │  preserved)      │    │  ownership)      │
                └──────────────────┘    └──────────────────┘
```

Every event is:

1. Published to the durable event bus by an SPIFFE-authenticated
   producer.
2. Schema-validated at bus ingress.
3. Fanned out to SIEM (for detection — mod-111), to the WORM
   audit sink (for retention), and to the tamper-evident log
   (for detectability of rewrites).
4. Replicated to a different account and a different region.

The fan-out is intentional. Losing any one destination breaks a
guarantee; having all three preserves guarantees under multiple
failure and adversary modes.

---

## WORM storage: cloud-provider APIs

The controls that make an object-storage bucket a legitimate
WORM store. Verify current API details against the provider
docs.

### AWS — S3 Object Lock

```
aws s3api create-bucket --bucket acme-audit-2026 --object-lock-enabled-for-bucket
aws s3api put-object-lock-configuration \
    --bucket acme-audit-2026 \
    --object-lock-configuration '{
      "ObjectLockEnabled": "Enabled",
      "Rule": {
        "DefaultRetention": {
          "Mode": "COMPLIANCE",
          "Years": 7
        }
      }
    }'
```

Two lock modes:

- **GOVERNANCE** — locks writes; can be bypassed by principals
  with the `s3:BypassGovernanceRetention` permission. Useful
  for internal policy that admins may need to override.
- **COMPLIANCE** — locks writes; *cannot* be bypassed by anyone
  in the account, including the root user, until the retention
  period elapses. This is the compliance-appropriate mode for
  audit logs.

Compliance-mode retention cannot be shortened after the fact.
That is the point.

Additional controls to layer on top:

- **Versioning enabled** — required for Object Lock.
- **Server-side encryption** with a KMS key.
- **Public-access block** at the account level.
- **Cross-Region Replication (CRR)** with `Filter { Prefix: "" }`
  and `DeleteMarkerReplication.Status: Disabled` — so replication
  cannot be used to hide the source.
- **Replicate to a different AWS account** using a role with
  minimal privileges. The destination account is owned by a
  different team, ideally by a governance team outside the
  ML org.

### GCP — GCS Bucket Lock

```
gcloud storage buckets update gs://acme-audit-2026 \
    --retention-period=7y
gcloud storage buckets update gs://acme-audit-2026 \
    --lock-retention-policy
```

`--lock-retention-policy` makes the retention permanent — the
retention period cannot be reduced after locking, only
extended. Analogous to S3 Compliance mode.

### Azure — Immutable Blob Storage

Blob storage supports **time-based retention** and **legal
holds**. Time-based retention with a locked policy is the WORM
equivalent; verify the current policy-locking API.

### Common configuration across providers

- **Retention period** aligned to the chapter 01 retention
  schedule.
- **Legal-hold** capability — for incident-response, individual
  objects can be placed on hold indefinitely, overriding the
  retention window's expiry (holds must be explicitly cleared).
- **Access log on the audit bucket itself** — who accessed the
  audit records is itself auditable.
- **Denial of `Delete*` and `Put*` permissions** on the retention
  bucket for all principals except the ingest role.

---

## Tamper-evident logs: Trillian, Rekor, Merkle trees

Object-lock is *prevention*. Tamper-evident logs are
*detection*: even if an attacker could rewrite the store, they
cannot rewrite it *undetectably*.

The primitive is a **Merkle tree** whose root hash is
periodically **signed and published**. Each entry is a leaf; the
tree root commits to every leaf; a signed root means "these are
exactly the leaves that existed at this tree size, at this
time". Any rewrite of an old leaf changes the root; an
attacker who rewrites without producing a matching signed root
is detectable at the next monitor check.

Implementations:

- **Trillian** — Google's Merkle-tree log server, the substrate
  under Rekor and Certificate Transparency.
- **Rekor** — Sigstore's transparency log for signing events;
  entries are DSSE envelopes and other signature bundles.
  Chapters 02–05 already write to Rekor.
- **Custom Trillian log** — for internal audit events that do
  not fit the Rekor entry types.

For the ML audit stream, two composition patterns:

### Pattern A — hash every audit event, append to Rekor as a `hashedrekord`

Every event is hashed (SHA-256 of the canonicalised JSON) and
the hash is appended to Rekor as a `hashedrekord` entry.
Verifiers can prove the event was appended at a specific tree
size (and therefore existed at that time) without exposing the
event content publicly (only the hash goes to Rekor).

Advantages: works with public-good Rekor (only hashes leave the
organisation), reuses chapter 02 infrastructure.

Trade-off: verification requires the raw event *and* the Rekor
inclusion proof; two things must be preserved.

### Pattern B — internal Trillian log, DSSE-signed audit records

Run a private Trillian instance. Every audit event is wrapped
in a DSSE envelope signed by the emitter's SPIFFE identity and
appended. The full event content is in the log.

Advantages: everything in one log; richer queries.

Trade-off: operational burden of running Trillian at scale;
storage grows fast if the log doesn't shard.

Pick pattern A for organisations already invested in Sigstore;
pattern B for organisations wanting a self-contained audit trail
independent of Sigstore.

### Monitors

The log is useful only if someone watches it. Monitors:

- **Consistency monitor.** Periodically fetches the current
  signed tree head and verifies it is consistent with the last
  known tree head (`log(N₁) → log(N₂)` extension, not a
  divergence).
- **Inclusion monitor.** For a sample of audit events emitted,
  verifies the corresponding inclusion proof still holds.
- **Presence monitor.** For classes of events that must appear
  at regular intervals (heartbeat events, expected training
  cadences), alerts when they do not.

Monitors run in an environment that does not share admin
identity with the log server — a "detection independence"
requirement.

---

## Off-account / cross-org replication

The single most common audit-log-integrity failure mode is
"attacker compromised the same account the audit bucket is in
and deleted the bucket". Cross-region replication *within the
same account* does not fix this.

**Off-account replication** is what fixes it. The audit bucket
is written from the ML platform's account; a replication rule
copies each object to a bucket in a **different account** owned
by a **different team** (governance / security engineering /
IR). The destination account:

- Has no admin overlap with the ML platform account.
- Has Object Lock enabled with a locked retention policy.
- Has no `Delete*` API allowed on the audit prefix.
- Is monitored for unexpected writes and unexpected access.

The cost is a second S3 / GCS bill and a small amount of IAM
work. The value is that a full compromise of the ML platform
account still leaves a complete audit trail in the destination.

For very-high-sensitivity environments, replicate to a
**different cloud provider** or a **regulator-accessible
escrow**. This is the maximum-independence configuration and is
warranted for regulated ML systems (financial, medical,
government).

---

## Retention and legal hold

The retention schedule from chapter 01 governs the audit sink.
Restate here in operational terms:

- **Default retention** — configured at bucket level via
  Object Lock's default rule. Every object inherits it on write.
- **Per-object override** — objects that legitimately need
  longer retention (e.g., events related to a model still in
  production years later) get an explicit per-object
  `RetainUntilDate` extension.
- **Legal hold** — for objects related to an active incident,
  litigation, or regulatory request. Legal hold overrides
  retention expiry; the object cannot be deleted until the hold
  is cleared, regardless of retention window.
- **Legal-hold clearance workflow** — clearing a hold is a
  privileged action, itself audit-logged, requiring two-party
  approval.
- **Retention-expiry deletion** — automatic deletion after
  retention elapses, with a delayed grace period and a report
  of what was scheduled for deletion so a stakeholder can
  extend if needed.

Never build a system where deletion is a routine automated
step with no visibility. The value of retention is destroyed
the moment audit-log deletion becomes something no one watches.

---

## Producer authentication: don't trust the sender

Every producer of audit events authenticates via SPIFFE (mod-103
chapter 03) before writing to the event bus. The reasons:

- **Repudiation.** An unauthenticated audit stream is one where
  an attacker can inject false events to muddy investigation.
- **Attribution.** The `who` in "who did what" comes from the
  producer's authenticated identity, not from a self-reported
  field.
- **Detection.** Producers writing to the event bus under
  unexpected identities is itself a security signal (mod-111
  detection content).

Common producer identities:

- Training pipeline SPIFFE ID (writes `model.training.*`,
  `model.artifact.signed`, `model.slsa.attested`,
  `model.mlbom.attested`).
- Admission controller SPIFFE ID (writes
  `model.admission.decision`).
- Evaluation pipeline SPIFFE ID (writes `model.eval.run`).
- Serving-plane audit-mode collector (writes elevated
  inference events during IR windows).

The event bus enforces: `producer SPIFFE ID → allowed event
type patterns`. Any mismatch is rejected and itself logged as
an audit event (`audit.producer.rejected`).

---

## Schema and versioning

Audit events are structured. JSON Schema (draft 2020-12) or
Protobuf are the two acceptable choices:

- Declare a schema per event type.
- Version schemas explicitly (`event.version = "1"`; new fields
  bump the version; incompatible changes are new event types).
- Validate at event-bus ingress; reject invalid events, emit
  `audit.schema.rejected`.
- Registry of schemas lives alongside the event bus (Confluent
  Schema Registry, Buf Schema Registry).

An unstructured audit log is a log a future auditor cannot
query. Enforce structure at write time.

---

## Query, replay, and evidence export

Two consumer patterns:

- **SIEM / detection.** Real-time consumers subscribed to the
  event bus, running Sigma / KQL / SPL rules for anomalies
  (mod-111).
- **Governance / audit export.** Point-in-time query against
  the WORM sink: "give me every `model.admission.decision` for
  the `serving` namespace between 2026-01-01 and 2026-03-31".

The governance-export workflow:

1. Requester (mod-109) opens an evidence-export request.
2. Two-party approval.
3. Export tool queries WORM sink and Trillian log; produces a
   bundle containing (a) the raw events, (b) their inclusion
   proofs, (c) the tree head at export time.
4. Bundle is signed by an evidence-export identity; digest is
   recorded to the audit stream as
   `governance.evidence.exported`.
5. Bundle is delivered to the requester.

The recipient can verify the export is authentic and
tamper-evident against the tree head. If the tree head
changes between export and delivery, the export can be
re-verified.

---

## What this chapter does not cover

- **SIEM / detection rule authoring.** Mod-111 SecOps and IR
  authors the detection rules against the audit stream. This
  chapter authors the stream; that module authors what to
  watch it *for*.
- **KMS / HSM key management.** The signing keys for DSSE
  envelopes, the KMS keys encrypting the WORM sink, and the
  root of trust for SPIFFE all live in mod-105.
- **Legal / regulatory retention specifics per jurisdiction.**
  Mod-109 governance owns per-regime retention floors and
  legal-hold workflows.
- **Log-management platforms (Splunk, Datadog, Elastic).**
  Those are consumers of the event bus, not the audit sink
  itself. Their retention is application-driven, not
  compliance-driven.

---

## The mistakes this chapter is trying to prevent

- **Mixing audit events with debug logs.** Narrows the search
  surface; dilutes the "everything here is audit-worthy"
  property; explodes storage cost for the WORM sink.
- **Object Lock in GOVERNANCE mode where COMPLIANCE was
  needed.** Governance mode is bypassable by the account
  admin; that is exactly the adversary the WORM control is
  meant to survive.
- **Cross-region replication within the same account, called
  "cross-account backup".** Not the same thing. If the account
  is compromised, the replica is too.
- **Unauthenticated event producers.** Any process on the
  network can then inject false events. Every producer must
  present a SPIFFE identity.
- **No tamper-evident log at all.** Object Lock is prevention;
  detection of any rewrite requires a Merkle-tree log with
  signed heads and monitors.
- **Monitors run by the same team that runs the log.** A
  detection-independence violation; the monitor and the log
  server should not share admin identity.
- **Automated retention-expiry deletion with no report.** The
  deletion becomes the only thing anyone knows about the
  retention policy; retention becomes a routine no one
  supervises.
- **Schemaless audit events.** A query at audit time is
  impossible; the auditor gets a pile of JSON.

---

## Summary

- The audit stream is narrower than the log stream: only
  security-relevant, action-authorising events, at years-long
  retention, with high integrity requirements.
- The event catalogue for an ML platform covers dataset
  ingest, feature materialisation, training, signing,
  attestation, ML-BOM production, evaluation, admission
  decision, deployment, retirement, key rotation, governance
  export, and incidents.
- The reference architecture: authenticated event bus →
  fan-out to SIEM + WORM sink + tamper-evident log →
  off-account, cross-region replication.
- WORM storage: S3 Object Lock in COMPLIANCE mode, GCS Bucket
  Lock with locked retention, Azure Immutable Blob with locked
  time-based retention. Retention aligned to chapter 01's
  three-driver schedule.
- Tamper-evident logs: Rekor (`hashedrekord` for privacy-
  preserving audit) or a private Trillian instance; monitors
  running under separate admin identity check consistency,
  inclusion, and presence.
- Producers authenticate by SPIFFE identity; events are
  schema-validated at bus ingress; retention deletion is a
  supervised, reportable workflow, not silent automation.
- Governance export is a two-party workflow that emits a
  signed bundle a recipient can verify against the tree head.
- This chapter completes the module: chapters 02–05 produced
  signed evidence; this chapter guarantees the record *about*
  that evidence survives under adversary and remains
  answerable at audit — closing the "prove what happened"
  loop the module opened.
