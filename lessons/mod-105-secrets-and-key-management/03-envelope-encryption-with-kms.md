# Chapter 03 — Envelope Encryption With Cloud KMS for ML Data and Artifacts

> **Note on AI-assisted content.** Verify cloud KMS API surfaces
> (AWS KMS, GCP Cloud KMS, Azure Key Vault) against the current
> provider docs before using in production. Key policies,
> resource-name formats, and IAM primitives change between
> versions. See [`resources.md`](./resources.md).

---

## Why this chapter exists

Chapter 02 protected credentials in flight. This chapter protects
data at rest — the raw training corpora, the feature-store
Parquet, the model-weight files, the evaluation records — using
**envelope encryption** anchored in a cloud KMS.

The specific failure mode this chapter is written to prevent:

> A regulated fintech encrypts its training data at rest using a
> single cloud KMS CMK named `data-lake`. The IAM policy grants
> `kms:Decrypt` on the CMK to a `DataLakeReader` role that every
> analytics service, every notebook, and every training pipeline
> assumes. An intern's notebook, running with the same role,
> accidentally exfiltrates a dataframe containing customer PII
> into an S3 bucket the intern controls (they meant to write to
> their scratch bucket; permissions were wide). During
> post-incident review the org realises: (a) every service that
> has ever read from the lake has had the ability to decrypt
> every dataset in the lake, including PHI datasets it never
> should have touched, (b) the CMK's audit log shows only that
> "DataLakeReader called Decrypt N times", with no way to tell
> *which service* or *which dataset*, (c) rotating the CMK to
> shrink blast radius would require re-encrypting the entire
> multi-petabyte lake.

The failure has three parts:

1. **One key protects everything.** A single compromised
   grant exposes the entire corpus.
2. **No key hierarchy.** There is no way to compartmentalise;
   the CMK is the leaf and the root at the same time.
3. **No per-object accountability.** The KMS audit log records
   key usage but not what was decrypted, and IAM records who
   assumed the role but not what data they read.

Envelope encryption with per-environment / per-tenant /
per-sensitivity keys — plus the hierarchy that supports it —
fixes all three.

You leave this chapter able to:

- Explain envelope encryption at the AEAD level (KEK, DEK,
  wrapped-DEK) and defend the choice of per-object DEKs.
- Design a key hierarchy that separates keys by environment,
  by tenant, and by sensitivity tier — and understand which
  axis you cannot skip.
- Configure cloud KMS resource policies and IAM grants so a
  compromised workload identity blast-radius is exactly one
  hierarchy leaf.
- Choose between provider-managed AEAD (S3 SSE-KMS, GCS
  CMEK, Azure customer-managed keys) and application-managed
  AEAD (Tink, libsodium) — and know when each is right.
- Author a **key-rotation** plan that rotates KEKs on a
  schedule without re-encrypting the underlying data.

---

## Envelope encryption, briefly

Envelope encryption separates the key that *does the crypto* from
the key that *protects the key that does the crypto*.

- The **DEK** (data-encryption key) is a symmetric key — usually
  AES-256 — that encrypts the actual data block or object using
  an AEAD mode (AES-GCM, AES-GCM-SIV, ChaCha20-Poly1305).
- The **KEK** (key-encryption key) is a key held inside a KMS
  or HSM that never leaves the boundary. The DEK is *wrapped*
  by the KEK — the KMS returns `Encrypt(KEK, DEK) → WrappedDEK`.
- The ciphertext stored on disk is the AEAD ciphertext of the
  plaintext under the DEK, plus the wrapped DEK, plus any
  associated data (AAD) bound to the record.

To read the data:

1. Fetch the ciphertext (which includes the wrapped DEK).
2. Call `KMS.Decrypt(WrappedDEK)` → get the DEK.
3. AEAD-decrypt the ciphertext with the DEK.
4. Zero the DEK from memory.

Why this beats "just encrypt with a KMS key directly":

- **Throughput.** KMS APIs charge per operation and have per-
  second quotas measured in low thousands. A training job
  reading a million objects cannot call KMS a million times;
  it calls KMS once per object (to unwrap the DEK) or, better,
  once per **object group** if the group shares a DEK.
- **Blast radius.** A stolen DEK exposes one object; a stolen
  KEK exposes every object wrapped with it (thousands to
  millions). The DEK stays in memory briefly; the KEK stays in
  the KMS forever. Compromising the KEK is dramatically harder
  than exfiltrating a DEK from memory.
- **Rotation.** Rotating the KEK re-wraps the wrapped DEKs (a
  cheap KMS call per object) but does not require decrypting
  and re-encrypting the underlying data. Data-level rotation
  is a heavier, separate operation.

Every cloud KMS implements envelope encryption natively:

- AWS: `GenerateDataKey`, `Encrypt`, `Decrypt` on a KMS CMK;
  the wrapped DEK is returned to the caller.
- GCP: `encrypt` / `decrypt` on a Cloud KMS CryptoKey; explicit
  envelope with Tink or the KMS SDK.
- Azure: Key Vault key operations `wrapKey` / `unwrapKey`.

Chapter 04 handles the workload-identity path that calls these
operations without a long-lived credential.

---

## The three axes of key separation

The default cloud template gives you one CMK per account (or per
project). The default is wrong for any ML platform touching
regulated data or serving multiple tenants. Separate the
hierarchy on three axes:

### Axis 1 — Environment (dev / staging / prod)

The non-negotiable axis. Never let a `dev` workload decrypt a
`prod` ciphertext. Enforced by:

- Separate cloud KMS keys per environment. Different key
  resource names, different key ARNs.
- Separate KMS grants / IAM. A `dev` workload's role has no
  IAM path that reaches `prod` keys.
- Ideally separate cloud accounts / projects / subscriptions
  per environment — the cross-account boundary makes the
  separation architectural, not just policy-driven.

Skipping this axis is the source of every "we accidentally
trained on production PII in the dev cluster" incident.

### Axis 2 — Sensitivity tier

Distinguish datasets by the harm class of a leak. A reference
scheme (adapt to your regulatory context):

| Tier | Contents | KMS key |
| --- | --- | --- |
| `public` | Public reference datasets (open ML benchmarks, published corpora) | Optional — encryption at rest is still standard practice; a shared low-sensitivity key is acceptable |
| `restricted` | Internal business data, non-PII | One key per business domain |
| `confidential` | Customer PII, non-health | One key, ideally split further by tenant (axis 3) |
| `PHI` / `PCI` | Health data, cardholder data | Separate key, separate audit stream, additional access controls per regime |

The sensitivity-tier key drives:

- Which KMS key is chosen at write time.
- Which principals have `Decrypt` on the key.
- Whether the KMS audit log is subject to the more-restrictive
  audit stream (mod-104 chapter 06 WORM sink with tighter
  retention).

Skipping this axis is the source of every "the entire
customer-PII dataset had the same protection as the
tokenised-brand-name corpus" incident.

### Axis 3 — Tenant

For multi-tenant ML platforms — a SaaS ML service, an internal
platform serving distinct business units with distinct
regulatory footprints — separate keys per tenant.

Two shapes work:

- **Per-tenant KEK, shared DEK per object group.** Each tenant
  has its own KEK; DEKs for that tenant's objects are wrapped
  under the tenant's KEK. Tenant offboarding is a KEK deletion
  (cryptographic erasure — see below). This is the pattern most
  platforms should use.
- **Bring-your-own-key (BYOK) / customer-managed KMS.** The
  tenant's KEK lives in the tenant's own KMS (or in your KMS
  under the tenant's IAM control). The tenant can revoke your
  access; you cannot decrypt the tenant's data without them.
  This is the strongest tenant-isolation model but adds
  operational complexity — the tenant is now on the on-call
  path for their own key availability.

Skipping this axis on a multi-tenant platform means every
tenant's ciphertexts are protected by the same key — a
single-tenant compromise compromises all tenants.

---

## Cryptographic erasure — the reason all this matters

If per-tenant KEKs are in place, deleting the KEK renders every
ciphertext wrapped under it permanently undecryptable.

This is not a curiosity — it is the mechanism by which most
"right to be forgotten" requests are actually satisfiable at
scale. Physically deleting individual rows from a data lake and
every downstream copy is infeasible. Deleting the tenant's KEK
(after archiving nothing wrapped by it that the org has any
retention obligation for) is a single KMS operation and is
mathematically final.

Design the hierarchy such that any deletion boundary the
business will care about — per-tenant, per-region, per-purpose
— aligns with a KEK boundary. If the deletion boundary you
care about crosses a key, you cannot cryptographically erase
without cross-tenant collateral.

Chapter 05 walks the key-deletion runbook (deleting a KEK is
irreversible; a fat-fingered deletion is an incident).

---

## Where the envelope encryption actually happens

Two implementation shapes; pick per data class.

### Provider-managed AEAD — S3 SSE-KMS, GCS CMEK, Azure CMK

The cloud object store performs the AEAD encryption on the
client's behalf. You configure the bucket / container to use
a specific CMK; the provider calls `GenerateDataKey` per
object, encrypts the object under the DEK, stores the object
with the wrapped DEK in metadata, and calls `Decrypt` on read.

Use this for:

- Raw training-data snapshots landing in a data lake.
- Model artifacts written to an OCI registry backed by an
  object store.
- Evaluation-report outputs.

Pros:

- Zero application code changes.
- Provider-side caching amortises KMS calls across many object
  operations from the same session.
- Integrates cleanly with the storage lifecycle policies.

Cons:

- The AEAD boundary is the storage service, not the workload.
  A workload with `s3:GetObject` and `kms:Decrypt` sees
  plaintext.
- No cryptographic binding of the ciphertext to a specific
  business record — the AAD is set by the provider (often
  including the bucket / key name), not chosen by your app.

### Application-managed AEAD — Tink, libsodium, cloud KMS envelope APIs

The application encrypts the record itself, calling KMS for
the wrapped DEK. Google's [Tink](https://developers.google.com/tink)
is the reference library — it handles key management, AEAD
selection, key rotation, and cloud-KMS integration in a way
that discourages misuse.

Use this for:

- Field-level encryption of PII columns in a training dataset
  (some columns encrypted, others plaintext).
- Per-record encryption where the record's key material
  should be scoped by a business identifier (tenant, patient,
  case).
- Any data path where the storage substrate cannot be trusted
  (e.g. writing to a shared feature store where readers must
  be authorised at a finer grain than storage IAM).

Example (Python, using Tink with AWS KMS):

```python
import tink
from tink import aead
from tink.integration import awskms

aead.register()
awskms.AwsKmsClient.register_client(
    "aws-kms://arn:aws:kms:us-east-1:111111111111:key/kek-ml-prod-conf-tenant42",
    None,  # use default AWS credentials chain (workload identity, chapter 04)
)

# Load a key template that uses envelope encryption:
kms_aead = awskms.AwsKmsClient().get_aead(
    "aws-kms://arn:aws:kms:us-east-1:111111111111:key/kek-ml-prod-conf-tenant42"
)
env_aead = aead.KmsEnvelopeAead(aead.aead_key_templates.AES256_GCM, kms_aead)

plaintext = b"customer PII record ..."
associated_data = b"tenant42|record-id-9876|schema-v3"
ciphertext = env_aead.encrypt(plaintext, associated_data)

# ciphertext contains: len(wrapped_dek) || wrapped_dek || aes_gcm_ciphertext
# associated_data is not stored in the ciphertext but MUST match on decrypt
```

Key points:

- The **associated data (AAD)** binds the ciphertext to a
  business context — a tenant, a record ID, a schema version.
  If an attacker moves the ciphertext to a different tenant's
  record, decryption fails because the AAD mismatches. Always
  set an AAD that captures the semantic identity of the
  record.
- The DEK never appears in the application beyond the AEAD
  operation; Tink handles the zeroisation.
- The KEK ARN encodes the environment, tier, and tenant in the
  key name (see below) so a mis-configured application cannot
  accidentally reach for a wrong-tenant key.

---

## Naming the keys

The key hierarchy is only enforceable if the key names encode
the axes. A reference schema (adjust punctuation per provider):

```
kek-<env>-<tier>-<tenant>-<purpose>

Examples:
kek-prod-confidential-tenant42-training
kek-prod-confidential-tenant42-features
kek-prod-restricted-shared-training
kek-prod-phi-shared-training
kek-staging-restricted-shared-training
```

Cloud-specific notes:

- **AWS KMS.** Set the naming schema in the key **alias**
  (`alias/kek-prod-confidential-tenant42-training`) so
  applications reference the alias, not the underlying key ID
  (the underlying key ID rotates on schedule; the alias is
  stable).
- **GCP Cloud KMS.** Keys live in a KeyRing; use the key ID
  as the schema and the KeyRing as a coarser boundary
  (`projects/acme-ml-prod/locations/us/keyRings/confidential-tenant42/cryptoKeys/training`).
- **Azure Key Vault.** Key names within a vault; use a
  vault-per-environment pattern
  (`https://acme-ml-prod-conf.vault.azure.net/keys/tenant42-training`).

The naming schema is enforced at three layers:

1. Terraform / cloud-config module rejects a key that does
   not fit the pattern.
2. Application code references keys via aliases, not raw IDs.
3. A periodic audit script lists every KMS key in the account
   and flags any name that does not match the pattern.

---

## The IAM / key-policy shape

Every KMS key has both an IAM grant *and* a resource-side key
policy. Both must permit the operation. This dual layer is a
gift — it lets you enforce cross-account key custody.

Reference AWS pattern for a per-tenant confidential KEK:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowKeyAdminByPlatformSecurity",
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::999999999999:role/PlatformSecurityKeyAdmin" },
      "Action": ["kms:Describe*", "kms:List*", "kms:PutKeyPolicy", "kms:ScheduleKeyDeletion", "kms:CancelKeyDeletion"],
      "Resource": "*"
    },
    {
      "Sid": "AllowEnvelopeOpsFromMLTrainingWorkloadIdentity",
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::111111111111:role/ml-training-tenant42" },
      "Action": ["kms:GenerateDataKey", "kms:Decrypt"],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "kms:EncryptionContext:tenant": "tenant42"
        }
      }
    },
    {
      "Sid": "DenyEverythingElseForBlastRadius",
      "Effect": "Deny",
      "NotPrincipal": {
        "AWS": [
          "arn:aws:iam::999999999999:role/PlatformSecurityKeyAdmin",
          "arn:aws:iam::111111111111:role/ml-training-tenant42"
        ]
      },
      "Action": "*",
      "Resource": "*"
    }
  ]
}
```

The three critical properties:

1. **Key admin lives in a different account** (a security-team
   account) from the workload account. A compromise of the ML
   account cannot delete the key.
2. **Encryption-context condition** — every `Decrypt` call must
   present `tenant=tenant42` in the encryption context or it
   is denied. Any bug that would otherwise let the training
   workload decrypt some other tenant's ciphertext is caught by
   the KMS itself, not by application-side checks.
3. **Explicit deny** — belt-and-braces against a future
   accidental policy grant.

The equivalent shape exists in GCP (Cloud KMS IAM +
`encryptionContext` bindings via CMEK conditions) and Azure
(Key Vault access policies + resource IDs); reference the
respective docs. The pattern (custody in a different security
principal + workload principal for ops + condition on business
context) is the invariant.

---

## Rotating a KEK

Rotate KEKs on a schedule; keep the schedule short enough that
a leaked key was only usable for a short window.

- **Cloud-provider automatic rotation.** AWS KMS supports
  annual automatic rotation of symmetric CMKs (the key material
  changes; the alias stays; wrapped DEKs are re-wrapped on next
  use). GCP Cloud KMS supports scheduled rotation (period
  configurable; default 90 days). Azure Key Vault supports
  policy-driven rotation.
- **On-demand rotation.** Any suspected compromise triggers an
  immediate rotation (chapter 05). The new key material is
  used for all new wraps; old wrapped DEKs remain unwrappable
  by the old material until re-wrap.
- **Data-level re-encryption** is separate — the plaintext data
  need not be re-encrypted when the KEK rotates. Re-encrypt
  only when moving data across a hierarchy boundary (e.g.
  reclassifying data into a lower-sensitivity tier).
- **Deprecating a key** — old key material is disabled but
  retained for a defined window so old ciphertexts can still be
  read while re-wrap proceeds. Only after every ciphertext has
  been re-wrapped do you schedule the old material for deletion
  (irreversible — chapter 05 approval required).

**Do not rotate on a schedule you cannot meet.** A stated
90-day rotation that actually happens every 400 days is worse
than an honest 365-day rotation, because the compliance
statement is a lie.

---

## KMS quotas — the operational reality

Cloud KMS has per-second quotas that ML workloads bump into.

- AWS KMS `Decrypt` / `GenerateDataKey` — default quotas are
  in the low thousands per second per region per account;
  raise via support ticket. Batch operations, cache DEKs
  aggressively (per object group, not per row), and use client-
  side caching libraries (Tink's key handles, AWS Encryption
  SDK's caching CMM).
- GCP Cloud KMS — similar order of magnitude; check current
  quotas.
- Azure Key Vault — historically much lower throughput than
  AWS/GCP; use Managed HSM for high-throughput scenarios.
  <!-- needs-research: pull current quota numbers for AWS,
  GCP, Azure KMS/HSM before quoting in a design; they change. -->

The pattern: **one DEK per object group, cached in-process
for the training job's lifetime, KMS called once per group to
unwrap on start, DEK zeroised on completion**. Do not call
KMS once per row.

---

## The mistakes this chapter is trying to prevent

- **One CMK for everything.** Common on greenfield builds; the
  first regulator audit or the first PII incident reveals the
  gap. Design the hierarchy on day one; retrofitting is
  expensive.
- **Sensitivity tier ignored.** PHI and public benchmarks in
  the same key is a compliance finding waiting to be written.
  Tier at the KMS level, not just at the storage-bucket level.
- **Tenant axis ignored on a multi-tenant platform.** Every
  tenant sharing a CMK means a single tenant's compromise
  compromises all tenants. Per-tenant KEKs make cryptographic
  erasure a real operation.
- **No encryption-context condition on decrypt.** Without a
  KMS-enforced condition on the business context, an
  application bug can decrypt the wrong record with the right
  role. Set the condition on the key policy, not in the
  application.
- **DEKs cached across trust boundaries.** A DEK cached beyond
  the workload's lifetime is a plaintext-key credential; treat
  it like one.
- **KEK deletion without a rehearsal.** KEK deletion is
  irreversible and can destroy access to petabytes of archived
  data. The chapter-05 runbook has an M-of-N approval process
  and a rehearsal cadence.
- **KMS costs dominating the ML compute cost.** A design that
  calls KMS per-row instead of per-object-group will show up
  in the KMS invoice. Fix by caching DEKs at the object-group
  layer; do not fix by widening the KEK.

---

## Summary

- Envelope encryption separates the key that does the crypto
  (DEK, per object or per object group) from the key that
  protects the DEK (KEK, in KMS, never extracted).
- Separate keys on three axes: environment (mandatory),
  sensitivity tier (mandatory for regulated data), tenant
  (mandatory for multi-tenant platforms). Skipping any axis
  creates a blast-radius class the chapter-05 runbook cannot
  contain.
- Cryptographic erasure — deleting the KEK — is the mechanism
  that makes "right to be forgotten" and tenant-offboarding
  tractable at scale. Design the hierarchy so any deletion
  boundary aligns with a KEK boundary.
- Prefer provider-managed AEAD (SSE-KMS, CMEK, CMK) for
  object-storage-scale data; use application-managed AEAD
  (Tink, cloud SDK envelope APIs) for field-level encryption
  and cross-workload trust boundaries.
- Name keys so the environment, tier, tenant, and purpose are
  encoded in the alias; enforce the schema at IaC, application,
  and audit-script layers.
- Key policies enforce dual-principal custody (admin in a
  security account; ops in the workload account) and
  encryption-context conditions on business identifiers.
- Rotate KEKs on the shortest cadence you can actually meet;
  re-wrap wrapped DEKs; re-encrypt data only when crossing
  hierarchy boundaries; KMS quotas force caching DEKs at the
  object-group layer.
