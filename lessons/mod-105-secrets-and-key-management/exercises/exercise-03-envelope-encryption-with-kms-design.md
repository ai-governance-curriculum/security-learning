# Exercise 03 — Envelope Encryption With KMS Design

**Estimated effort:** ~2 hours
**Deliverable:** A design document consisting of (a) the
key-hierarchy diagram naming every KEK across the environment
/ sensitivity / tenant axes, (b) per-dataset placement
decisions (which KEK wraps which data, provider-managed vs
application-managed AEAD), (c) sample KMS resource policies
and IAM grants for at least three keys, (d) the KEK rotation
plan and the KEK-deletion runbook.
**Prerequisites:** Exercise 01 (the sensitivity /
environment / tenant classifications drive this design).
Chapter 03 read end-to-end. Familiarity with one cloud KMS
(AWS KMS, GCP Cloud KMS, Azure Key Vault). Familiarity with
the target platform's data-classification scheme (from
mod-108 if in place; from chapter 01 fallback if not).

---

## Objective

Design the key hierarchy that protects the ML platform's
data at rest. The design must:

- Cover every dataset, feature-store table, model artifact,
  and evaluation record with an envelope-encryption plan.
- Separate keys on the three mandatory axes: environment,
  sensitivity, tenant.
- Give every key a naming schema that encodes the axes.
- Enforce IAM + resource-policy dual-principal custody
  (admin in security account, ops in workload account).
- Support KEK rotation without data-level re-encryption.
- Support cryptographic erasure for tenant offboarding and
  right-to-be-forgotten requests.

By the end you should have a document a platform SRE and a
data-protection lead can jointly execute.

---

## Problem statement

Take the platform from exercise 01. Datasets and artifacts in
scope for encryption at rest:

- **Training corpus.** Snowflake tables (transactions,
  behaviour features) — restricted, some PII columns; a
  smaller PHI subset from a healthcare-partner integration.
- **Feature-store online.** Redis (per-user features served
  to the online inference path).
- **Feature-store offline.** Parquet in S3
  (`s3://acme-features/…`).
- **Model artifacts.** OCI-packaged safetensors + tokenizer
  + config, in an OCI registry backed by S3.
- **Evaluation records.** JSON reports (input, model output,
  judge output, score) in S3
  (`s3://acme-evaluations/…`).
- **Audit logs.** WORM sink from mod-104 chapter 06 in
  `s3://acme-audit/…`.

Tenants: the platform serves three distinct business units
(`retail`, `wholesale`, `wealth`); the healthcare partner
data is a per-partner PHI compartment
(`healthcare-partner-a`). The org runs on AWS; assume AWS
KMS as the reference (adapt if the target platform is GCP or
Azure).

---

## Requirements

### Section 1 — Key hierarchy diagram

A diagram showing every KEK, with the naming schema from
chapter 03:

```
kek-<env>-<tier>-<tenant>-<purpose>
```

The diagram groups keys by:

- **Environment axis.** `dev` / `staging` / `prod` in
  separate columns.
- **Sensitivity axis.** `public` / `restricted` /
  `confidential` / `phi` in separate rows.
- **Tenant axis.** Per-tenant sub-groups where applicable.

For each key, note:

- The cloud account it lives in (security-owned vs
  workload-owned).
- The rotation schedule.
- The workload identities allowed to `GenerateDataKey` /
  `Decrypt`.
- The `EncryptionContext` conditions the key policy
  enforces.

### Section 2 — Dataset placement table

For every dataset / artifact class from the problem
statement, one row:

| Dataset / artifact | AEAD implementation (provider-managed vs application-managed) | KEK (from section 1) | AAD contents | Access pattern (batch, streaming, interactive) | KMS quota estimate | DEK caching strategy |

Rules:

- **AEAD implementation:** provider-managed (SSE-KMS,
  CMEK, CMK) is the default for object-storage-scale data;
  application-managed (Tink, cloud SDK envelope) is required
  for field-level encryption and cross-workload trust
  boundaries.
- **AAD:** every application-managed AEAD row has an AAD
  design that binds the ciphertext to the semantic identity
  of the record (tenant + record-ID + schema version at
  minimum).
- **KMS quota estimate:** an order-of-magnitude calculation
  of the calls/sec the workload will make, so section 3's
  key-policy design can be sized (`GenerateDataKey` +
  `Decrypt` combined).
- **DEK caching strategy:** where does the DEK live in
  memory, for how long, and when is it zeroised? For
  training jobs, "cached per object group for the job's
  lifetime, zeroised on job exit" is the reference.

### Section 3 — Sample KMS resource policies

For at least three keys (one per environment × sensitivity
combination), author the full resource-side key policy in
AWS KMS JSON (or the equivalent for GCP / Azure). Each
policy must include:

- **Admin principal in the security account** with
  `PutKeyPolicy`, `ScheduleKeyDeletion`,
  `CancelKeyDeletion`, `EnableKey`, `DisableKey`.
- **Ops principal in the workload account** with
  `GenerateDataKey` and `Decrypt`.
- **Encryption-context condition** on the ops principal
  binding decrypt to the tenant / purpose identifier.
- **Explicit deny for `NotPrincipal`** to catch accidental
  future grants.
- **Alias binding** (`alias/kek-<schema>`) so applications
  reference the alias, not the underlying key ID.

Cross-account trust: the workload account's IAM role must
also carry an inline policy naming the KEK ARN with the
same actions and the same encryption-context condition
(both sides must permit).

### Section 4 — KEK rotation plan

For each key in the hierarchy:

- **Rotation trigger.** Scheduled (cadence in days) +
  on-demand (chapter 05 compromise trigger).
- **Rotation mechanism.** Provider automatic rotation
  (AWS annual, GCP configurable) vs manual re-key + alias
  re-point.
- **Impact on wrapped DEKs.** Wrapped DEKs remain
  decryptable under the old material until re-wrap; state
  the re-wrap policy (proactive background job, or
  lazy on-next-read).
- **Impact on plaintext data.** None — the plaintext is
  not re-encrypted unless crossing a hierarchy boundary
  (state the exception).
- **Retirement of old material.** Old material is
  retained (disabled) for a defined window, then scheduled
  for deletion (irreversible). Name the window.

### Section 5 — KEK-deletion runbook

Deleting a KEK is a compliance-relevant, irreversible act
that can render petabytes of archived data permanently
undecryptable. The runbook:

- **Trigger cases.** Tenant offboarding, right-to-be-
  forgotten cryptographic erasure, planned key
  decommission after re-key window.
- **Preconditions.** All ciphertexts under the KEK have
  been (a) re-wrapped under a successor key AND retained,
  or (b) intentionally rendered unrecoverable per a
  documented decision. Every ciphertext accounted for.
- **Approvals.** M-of-N approval process — at least two
  named humans, one from security, one from data-
  protection.
- **Execution.**
  `aws kms schedule-key-deletion --key-id … --pending-window-in-days 30`
  (the pending window is legally-mandatory-minimum
  configurable; use it for a cooling-off period).
- **Verification.** During the pending window, the key
  is disabled but recoverable; on completion, it is
  gone.
- **Cancellation.** `cancel-key-deletion` during the
  pending window; escalation path if a cancellation is
  attempted.
- **Post-deletion audit.** Record the deletion in the
  WORM audit sink with the approval trail and the
  attestation of ciphertext accounting.

### Section 6 — Cost / quota sanity check

Rough numbers:

- Estimated KMS calls per hour under peak training + peak
  inference load.
- Cost estimate at current KMS pricing (per-call + monthly
  key charge).
- Whether the estimate is within default AWS/GCP/Azure
  quotas or requires a quota-raise ticket.
- Whether the DEK-caching strategy from section 2 is
  sufficient to stay within quota; if not, what changes.

## Starter guidance

- Do the environment × sensitivity matrix first; the
  tenant axis is a multiplier on the leaves that already
  need to exist.
- The naming schema is the enforcement layer. Get the
  pattern right; make it Terraform-checkable; propose the
  audit script that lists non-conforming keys.
- Provider-managed AEAD is fine for object-scale data;
  reach for application-managed only when you need
  field-level control or cross-workload boundaries.
- Cryptographic erasure is a feature, not a curiosity —
  design so any deletion boundary the business will need
  aligns with a KEK.
- KMS quotas will bite before storage costs will. Size
  the DEK caching strategy for the peak, not the
  average.
- Do not let the "one KEK per record" temptation win —
  per-object-group is usually right; per-row is a
  throughput hazard.

## Acceptance criteria

A passing document:

- Hierarchy covers all three axes for every dataset in the
  problem statement.
- Naming schema is defined and every key in the hierarchy
  conforms.
- Placement table has one row per dataset with all columns
  populated.
- At least three fully-authored key policies with the four
  invariants (dual-principal, encryption-context condition,
  explicit deny, alias binding).
- KEK rotation plan states the mechanism, cadence, and
  re-wrap policy per key.
- KEK-deletion runbook has M-of-N approval, ciphertext-
  accounting precondition, pending-window, and audit-log
  entry.
- Cost / quota check has actual numbers, not "should be
  fine".

A failing document:

- Uses a single CMK for multiple sensitivity tiers.
- Skips the tenant axis on a multi-tenant platform.
- Names keys without a schema (`ml-data-key`, `prod-key`).
- Has a key policy without an encryption-context condition
  on the ops principal.
- Puts the KEK admin in the same account as the workload
  ops principal.
- Includes a plan to "delete keys as needed" without an
  M-of-N approval process.
- Ignores KMS quotas / caching.

## Stretch goals

- **BYOK design.** For the healthcare-partner tenant, add
  a bring-your-own-key section — the partner holds the
  KEK, the platform holds only the wrapped DEK, the
  platform cannot decrypt without the partner. Discuss
  operational trade-offs (partner is now on the on-call
  path for their key availability).
- **Multi-region KMS strategy.** If the platform runs in
  two prod regions, discuss KMS multi-region keys (AWS)
  vs replicated keys (GCP) vs geo-replicated Key Vault
  (Azure). Trade-offs: latency, blast radius, data-
  residency compliance.
- **HSM boundary.** Identify which KEKs (if any) warrant
  HSM-backed key material (FIPS 140-3 Level 3) — usually
  the signing keys and the top-tier PHI KEKs. Reference
  cloud-provider offerings (AWS CloudHSM, GCP Cloud HSM,
  Azure Managed HSM).
- **Envelope-encryption library choice.** Compare Tink,
  the AWS Encryption SDK, and rolling-your-own (do not
  roll your own — but articulate why not, with reference
  to specific misuse-resistance features).
- **Regulatory-mapping annex.** Map each KEK's audit
  requirements to the specific clauses in HIPAA, PCI DSS,
  and EU AI Act (mod-109 evidence input).

## Do not

- Do not commit real KMS ARNs / real cloud account IDs —
  placeholders only.
- Do not design the CI signing-key path (that's exercise
  04).
- Do not author the leak-response runbook (that's
  exercise 05, though this exercise's KEK-deletion
  runbook feeds into it).
- Do not attempt data-level re-encryption in the plan
  unless the re-classification / boundary-crossing case
  demands it; that operation is separate, expensive, and
  scheduled.
- Do not commit a solution here — solutions live in the
  paired solutions repo.
- Do not invent regulatory citations — annotate with
  `<!-- needs-research: ... -->` where a claim cannot be
  verified.
