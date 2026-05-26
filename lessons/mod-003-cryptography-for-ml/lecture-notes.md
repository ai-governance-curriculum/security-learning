# Module 03 — Cryptography for ML Systems

> **Note on AI-assisted content.** Drafted with AI assistance and
> under human review. Cryptography is the part of security where
> casual claims are most dangerous; verify against primary sources
> (NIST publications, vendor docs, RFCs) before relying on any
> specific assertion. See [`resources.md`](./resources.md).

---

## 1. What this module *does not* cover

Cryptographic *primitives* — what makes AES secure, why ECDSA
works, how SHA-256 is constructed — are out of scope. This module
treats primitives as black boxes:

| Primitive | What you should treat it as | Reference |
|---|---|---|
| AES-256-GCM | The default for symmetric authenticated encryption | NIST SP 800-38D |
| ChaCha20-Poly1305 | Symmetric authenticated encryption, alternative to AES-GCM | RFC 8439 |
| RSA-2048+ | Asymmetric encryption / signatures, legacy-strong | NIST SP 800-56B |
| ECDSA P-256 / P-384 | Modern asymmetric signing | NIST FIPS 186 |
| Ed25519 | Modern signing, simpler than ECDSA | RFC 8032 |
| SHA-256 / SHA-3 | Cryptographic hashes | FIPS 180-4 / FIPS 202 |
| HMAC-SHA-256 | Message authentication | RFC 2104 |
| HKDF | Key derivation | RFC 5869 |

**The rule:** if you find yourself implementing one of these
primitives, stop. Use the vetted implementation in your language's
standard cryptography library (Python: `cryptography`; Go:
`crypto/...`; Rust: `ring` / `rustls`). If a vendor's library
isn't FIPS-validated and you need FIPS compliance, that's a
separate problem from primitive selection.

---

## 2. Encryption at rest

Encryption at rest means: a copy of the encrypted data, by itself,
is unreadable.

### 2.1 What encryption at rest doesn't protect against

If the *running system* can read the data, an attacker who gains
access to the *running system* can also read the data.
Encryption at rest protects against:

- Disk theft (someone walks off with a hard drive).
- Backup theft (someone exfiltrates a backup tape).
- Misrouted storage (someone gets access to an old S3 bucket).

It does **not** protect against:

- A compromised pod with mounted access to the decrypted volume.
- An attacker with valid API credentials querying the database.
- A logic bug exposing data over the API.

Encryption at rest is necessary, not sufficient.

### 2.2 Three approaches

| Approach | What it is | When it's right |
|---|---|---|
| **Storage-layer encryption** | The block / object store encrypts; you provide the key (CMK in AWS terminology) | Default. Covers disk theft, backup theft. |
| **Envelope encryption** | Data encrypted with a per-object data encryption key (DEK); DEK encrypted with a key encryption key (KEK) | When you have many objects and need granular key rotation |
| **Application-layer encryption** | App encrypts before storage; storage sees only ciphertext | When the threat model includes "the storage operator" or "the cloud provider" |

For ML workloads:

- **Training data warehouse**: storage-layer encryption is usually
  fine. The warehouse operator is part of your trust boundary.
- **Model artifacts**: envelope encryption is preferred — different
  artifacts may need different access controls.
- **Feature store with PII**: application-layer encryption for
  PII-bearing columns, on top of storage-layer encryption.

### 2.3 KMS as the substrate

A **Key Management Service** (AWS KMS, GCP Cloud KMS, Azure Key
Vault, HashiCorp Vault Transit) holds your KEKs. Properties:

- Keys never leave the KMS boundary; you call the KMS to
  encrypt / decrypt / sign.
- Access to keys is controlled by IAM, not by possession.
- Operations are logged.
- Keys can be rotated without re-encrypting all data (when
  envelope encryption is used).

**Mistake to avoid**: storing a KEK in a Kubernetes Secret. That
defeats the entire point of a KMS — the key now lives in
something the cluster operators can read. Use the KMS API
directly, with workload identity (from Module 02) for the IAM
permission.

### 2.4 ML-specific concerns

- **Model artifacts encryption**: a model artifact is large
  (hundreds of MB to tens of GB). Encrypting/decrypting at
  download time has a measurable cost. Plan for it.
- **Training data with PII**: encrypting at the column level for
  PII fields lets you query non-PII fields without decrypt
  overhead. The trade-off: schema complexity.
- **Feature store rows**: hot-path reads are sensitive to decrypt
  latency. Don't application-encrypt features that are queried
  per-request unless the threat model demands it.

---

## 3. Encryption in transit

mTLS is the workhorse of zero-trust (Module 02). This section
covers what you actually need to know to configure it safely.

### 3.1 TLS version

**TLS 1.3 only.** TLS 1.2 is widely deployed and acceptable as a
fallback in mixed environments. TLS 1.0 and 1.1 are deprecated by
the IETF (RFC 8996); disable them. SSL is dead; if anyone says
"SSL" they mean TLS.

### 3.2 Cipher suites

For TLS 1.3, the cipher suites are mandated and short:

- `TLS_AES_128_GCM_SHA256`
- `TLS_AES_256_GCM_SHA384`
- `TLS_CHACHA20_POLY1305_SHA256`

For TLS 1.2 (if you must support it):

- ECDHE for key exchange (forward secrecy).
- AES-128-GCM or AES-256-GCM, or ChaCha20-Poly1305 for AEAD.
- No CBC, no RC4, no anything pre-AES.

Use Mozilla's [SSL configuration generator](https://ssl-config.mozilla.org/)
to produce server configs; the "intermediate" profile is the
right default.

### 3.3 mTLS specifically

mTLS adds **client** authentication via certificate. The
configuration concerns:

- Where do clients get their certs? (SPIRE, cert-manager, manual.)
- How are certs rotated? (Short-lived, automatic.)
- How is the trust chain managed? (Internal CA, externally signed.)
- How is client identity extracted from the cert? (SAN format,
  typically a SPIFFE ID.)

In Istio (Module 02), most of this is handled by the mesh. In
non-mesh deployments — internal gRPC services, model serving
without a mesh — you do it explicitly.

### 3.4 Certificate validation

Verifying a certificate means:

1. Trust chain validates to a CA you trust.
2. Not expired, not revoked.
3. Subject matches what you expected (SAN or principal).

**Common mistakes:**

- Accepting any cert signed by a trusted CA without checking the
  principal. (You trusted Let's Encrypt, but the cert is for
  `evil.example.com`.)
- Disabling cert validation in code for "testing" and forgetting
  to re-enable.
- Trusting CAs you don't actually trust (default trust stores
  often include hundreds of CAs).

For internal mTLS, use an internal CA with a single root, and
trust only that root.

### 3.5 SNI and routing

TLS handshake reveals the **Server Name Indication** (SNI) in
plaintext, which says which hostname is being requested. SNI is
not encrypted. If you need to hide which service is being talked
to (rare requirement), ESNI / ECH addresses this; otherwise it's
fine.

---

## 4. Encryption in use (confidential computing)

The third leg of the encryption story. Data is decrypted at rest;
data is decrypted in transit at the endpoint. But while the
*process* is using it, it's in plaintext in RAM.

Confidential computing protects RAM contents against:
- Privileged operators (sysadmins, cloud provider staff).
- DMA-style attacks.
- Cold-boot attacks (less relevant in cloud).

### 4.1 Technologies

- **Intel SGX**: hardware enclaves on Intel CPUs. Limited memory
  inside the enclave, requires app rewrite.
- **AMD SEV / SEV-SNP**: VM-level memory encryption on AMD.
  Easier to deploy than SGX (lift-and-shift VM workloads).
- **ARM CCA / Realm**: emerging.
- **AWS Nitro Enclaves**: AWS's confidential-computing primitive
  on Nitro hypervisor.
- **Google Confidential VMs / Azure Confidential VMs**: SEV-based
  on cloud-provider Linux VMs.

### 4.2 When confidential computing matters

The threat model has to include "the cloud provider's privileged
operators" or "a privileged sysadmin in the data center." For
most workloads, this isn't a credible threat — you're using a
trusted cloud provider, and your defense is the contract plus
the cloud provider's own controls.

When it does matter:

- **Healthcare ML with PHI**: confidential VMs add a layer that
  satisfies some interpretations of HIPAA + business associate
  agreements.
- **Financial ML with material non-public information**:
  similar regulatory shape.
- **Cross-tenant ML in a federated setting**: when two parties
  jointly train a model without exposing their data to each
  other.

### 4.3 The cost

Confidential computing is operationally expensive:

- 5–30% throughput penalty depending on workload.
- Limited memory in some technologies (SGX in particular).
- App rewrites for technologies that aren't VM-level.
- Smaller hardware fleet — limited availability in some regions.

Use it where the threat model demands it; don't use it as
security theater.

---

## 5. Key management

Keys are the asset cryptography is supposed to protect. Bad key
management is the most common way deployed cryptography fails.

### 5.1 Principles

1. **One key, one purpose.** Don't reuse a key for both
   encryption and signing, for both training-data and model-
   artifact encryption. Compromise of one purpose shouldn't
   compromise the others.
2. **Short-lived where possible.** Long-lived root keys
   (decade-scale) only protect short-lived derived keys
   (hour-scale to month-scale).
3. **Rotation is a process, not a feature.** A key that has been
   "rotated" but the old data is still encrypted with the old
   key has *not* fully rotated.
4. **Access by identity, not by possession.** Use the KMS API
   with workload identity; don't ship the key as a Secret.
5. **Audit access.** Every encrypt / decrypt / sign operation
   should be logged with the requesting identity.

### 5.2 HashiCorp Vault

Vault is the de facto open-source secret management system. For
cryptography:

- **KV engine**: stores static secrets (not the focus here).
- **PKI engine**: issues short-lived certificates for internal CAs.
- **Transit engine**: a "crypto as a service" surface — Vault
  holds keys, callers ask Vault to encrypt / decrypt / sign,
  keys never leave Vault.
- **Database engine**: issues dynamic database credentials.

For ML workloads, the relevant ones are:
- **Transit** for application-layer encryption (the keys for
  encrypted feature columns).
- **PKI** for internal mTLS certs.

### 5.3 Cloud KMS comparison

| Cloud | Service | Notes |
|---|---|---|
| AWS | KMS | Standard. Keys are tied to a region. |
| GCP | Cloud KMS | Comparable to AWS KMS. |
| Azure | Key Vault | KMS + secret manager combined. |

For multi-cloud deployments, an external KMS (Vault, or a
dedicated HSM) decouples key management from cloud lock-in. The
cost is the operational complexity of running an external KMS.

### 5.4 Key separation patterns for ML

A defensible setup separates keys by:

- **Tenant** (per-tenant DEK, KEK shared).
- **Use** (different keys for training-data encryption, model-
  artifact encryption, audit-log signing).
- **Environment** (dev / staging / prod keys are distinct).
- **Region** (per-region keys for data-residency reasons).

A KEK hierarchy:

```
Root KMS key (region-scoped, KMS-resident, audit-logged)
  └─ Tenant KEKs (1 per tenant, KMS-resident, rotated annually)
       └─ Data DEKs (per object, envelope-encrypted, ephemeral)
```

### 5.5 Key rotation operationally

For envelope encryption, rotation is cheap: rotate the KEK,
re-encrypt the DEK. The data itself doesn't move.

For app-layer encryption without envelope: rotation requires
re-encrypting all data. Plan it as a migration, not a routine.

For mTLS certs: SPIRE / cert-manager rotates automatically.
That's the recommended path.

---

## 6. Certificate management

### 6.1 Internal CA architecture

Most production ML platforms run an **internal CA** for service-
to-service mTLS. Architecture:

```
Root CA (offline, in HSM, signs intermediate CAs annually)
  └─ Intermediate CA (online, signs end-entity certs)
       └─ End-entity certs (1h–24h TTL, per workload)
```

The root is offline to limit its exposure. Compromise of the
intermediate CA is recoverable (revoke + reissue from root);
compromise of the root is a multi-week incident.

### 6.2 cert-manager

[cert-manager](https://cert-manager.io/) is the Kubernetes-native
tool for certificate management. It supports:

- ACME-based external certs (Let's Encrypt, ZeroSSL).
- Internal CAs (provided by Vault PKI, AWS Private CA, or a
  self-signed root).
- Automatic renewal (no human in the loop for typical 90-day
  rotation).

For ML platforms, the common pattern:

- External certs (for the customer-facing API) via cert-manager
  + Let's Encrypt.
- Internal certs (for service-to-service mTLS) via cert-manager
  + Vault PKI, or via SPIRE.

### 6.3 SPIFFE certs vs. cert-manager

SPIRE issues SVIDs that are X.509 certs. cert-manager issues
X.509 certs. The differences:

- **SPIRE**: identity-bound certs, very short TTL (~hour),
  attestation-based issuance.
- **cert-manager + Vault PKI**: more general-purpose, can issue
  longer-TTL certs, broader use cases.

For zero-trust workload identity, **SPIRE** is the right tool.
For one-off internal services that need a cert, cert-manager is
fine.

### 6.4 Revocation

Certificate revocation in TLS is operationally hard:

- **CRL** (Certificate Revocation List): a list the verifier has
  to download and consult. Often stale.
- **OCSP**: query the CA to check revocation. Adds latency,
  privacy concerns (CA sees who's connecting to whom).
- **OCSP stapling**: server includes a recent OCSP response in
  the handshake. The right answer for public-facing TLS.
- **Short-lived certs**: if the cert lifetime is 1h, revocation
  is "wait at most 1h." Often simpler than implementing CRL/OCSP.

For internal mTLS with SPIRE-issued 1h SVIDs, **short-lived
certs is the revocation strategy**. No OCSP / CRL infrastructure
needed.

---

## 7. Signing

Signing answers: "did the legitimate producer create this
artifact?"

### 7.1 What needs signing in an ML system

- **Container images** — covered by Cosign / Sigstore.
- **Model artifacts** — same tools; sign the model file as you
  would a container.
- **Attestations** — in-toto attestations record build provenance
  and are themselves signed.
- **Audit log entries** — each entry signed (or HMAC'd) by the
  producing workload's identity.
- **Promotion approvals** — when a human signs off on a model
  promotion, that signature is part of the audit trail.

### 7.2 Cosign / Sigstore

[Cosign](https://github.com/sigstore/cosign) is the de facto
signing tool for container images, with extensions for arbitrary
blobs (including model artifacts).

The interesting feature is **keyless signing**:

1. The signer authenticates via OIDC (typically a CI identity).
2. A short-lived signing certificate is issued by **Fulcio**, the
   Sigstore CA, bound to the OIDC identity.
3. The signature is recorded in **Rekor**, the Sigstore
   transparency log.
4. Verifiers check the signature, the Fulcio cert, and the Rekor
   entry.

No long-lived private keys to manage. The trade-off is
*availability dependence* on Sigstore's public services (or
your own internal Sigstore deployment).

### 7.3 Verifying signatures at admission

The admission controller (Kyverno, OPA Gatekeeper) must verify:

- The image has a valid signature.
- The signing identity matches the expected OIDC subject (e.g.,
  the CI workflow that's allowed to sign).
- The Rekor entry exists.

If any check fails, admission is rejected. Module 10 covers this
pipeline in detail.

### 7.4 Model artifact signing specifics

A model artifact differs from a container image in two ways:

1. It's a single blob, not a layered image.
2. It's loaded by the serving runtime, not by the container
   engine.

Cosign supports blob signing (`cosign sign-blob`). The verifier
runs in the serving startup path — it pulls the model, verifies
the signature, then loads the model into memory.

A model whose signature does not verify must not be loaded. The
serving pod fails to start; the deploy fails. This is the
critical control.

---

## 8. Hash chains and tamper-evidence

### 8.1 The problem

Audit logs in a regulated environment must be **tamper-evident**:
a privileged insider who tampers with the log must leave
detectable traces.

Database integrity controls (foreign keys, constraints) don't
help — a sysadmin with DB access can edit anything. WORM storage
helps but is operationally expensive. Hash chains give you
tamper-evidence cheaply.

### 8.2 The construction

Each log entry contains:

- The payload (the audit event).
- The hash of the *previous* entry.
- The current entry's hash (computed over payload + previous-hash).

```
Entry 0: hash = H(payload_0)
Entry 1: hash = H(payload_1 || hash_0)
Entry 2: hash = H(payload_2 || hash_1)
...
Entry N: hash = H(payload_N || hash_{N-1})
```

If anyone tampers with entry K, the recomputed hash differs from
the stored hash, and every subsequent entry's chain breaks. A
`verify()` function walks the chain and returns the first break.

### 8.3 Anchoring

A hash chain alone proves *internal* consistency. To prove
*external* freshness — that the chain wasn't replaced wholesale —
you periodically **anchor** by publishing the latest hash to an
external timestamp service:

- RFC 3161 timestamp authorities.
- OpenTimestamps (uses Bitcoin's blockchain as the timestamp
  service).
- An external trusted party (auditor) signs the daily anchor.

The anchor is the difference between "we have integrity" and "we
have integrity provable to a third party."

### 8.4 Reference implementation

The hash-chain audit log lives at
`ai-infra-mlops-learning/projects/project-4-governance/src/audit/log.py`.
Read it; it's small and concrete.

---

## 9. Homomorphic encryption (a cautious primer)

**Homomorphic encryption** (HE) lets you compute on encrypted
data without decrypting it. Fully homomorphic encryption (FHE)
supports arbitrary computations; partially homomorphic schemes
support a fixed set.

### 9.1 What HE is actually useful for in ML

**Inference on encrypted data**: a client sends encrypted input,
the server runs inference, the server returns an encrypted
output, the client decrypts. The server never sees plaintext.

Real production deployments are extremely rare. Reasons:

- HE inference is 1000–10,000× slower than plaintext inference
  for non-trivial models.
- The supported ops are limited; nonlinear activations need
  polynomial approximations.
- Key management is hard (one key per client session).

### 9.2 When to take HE seriously

- **Cross-org collaborations** where neither party will share
  data: HE can be part of a privacy-preserving solution.
- **Regulated inference** where even cloud-provider operators
  must not see plaintext, and the latency budget is generous.

### 9.3 When *not* to take HE seriously

- A pitch from a vendor that HE makes everything "secure by
  default."
- A consumer-facing serving stack where latency matters.
- Anything where confidential computing (Section 4) is a
  reasonable alternative.

For most production ML, **don't use HE**. Build the controls in
this module and Module 02; that addresses the threat model
without HE's complexity.

---

## 10. Common cryptographic mistakes in ML systems

A catalogue of mistakes the field repeats:

### 10.1 Embedded long-lived secrets

A `Secret` resource in Kubernetes containing a 5-year API key,
mounted as an env var. Compromise of the cluster = compromise of
the API. Fix: workload identity + dynamic credentials (Module 05).

### 10.2 Unsigned model artifacts

A serving pod pulls a model from S3 without signature
verification. Anyone who can write to the S3 bucket can poison
the model. Fix: sign the model on registration; verify at load.

### 10.3 Self-signed certs in production

A self-signed cert means there's no trust chain. The serving
client either accepts any cert (no security) or pins this exact
cert (operationally brittle). Fix: an internal CA with proper
issuance.

### 10.4 Mixing dev and prod keys

The training pipeline encrypts artifacts with key K. The serving
pipeline uses the same key K to decrypt. Compromise of either
side compromises both. Fix: separate keys, separate IAM scopes.

### 10.5 Trusting the default trust store

A Python client connecting to internal services trusts every CA
in the system's default trust store — including 200+ public
CAs. Fix: pin to your internal CA's root in the verification
config.

### 10.6 No key rotation plan

The KEK was issued 4 years ago and has never been rotated. Fix:
rotation cadence as part of platform ops; document the runbook.

### 10.7 Encrypting fields with deterministic encryption

Deterministic encryption (same plaintext → same ciphertext) lets
attackers do frequency analysis. Useful for searchable encryption
in narrow cases; misused elsewhere. Fix: use AEAD modes (AES-GCM)
unless determinism is specifically required.

### 10.8 Storing audit-log signing keys with the auditor

If the audit log is signed by a key the auditor controls, the
auditor can rewrite history. Fix: the audit log is signed by
each workload's own identity; verification is done by an
independent verifier.

---

## 11. ML-specific signing scenarios

### 11.1 Model lineage attestation

A model artifact carries an attestation:

- The Git SHA of the training code.
- The hash of the input dataset(s).
- The training pipeline run ID.
- The validation evidence (quality metrics, fairness metrics).
- The signature of the training pipeline's workload identity.

This attestation is signed (in-toto attestation format) and
verified at admission. A model that wasn't trained by the
expected pipeline on the expected data won't be admitted.

### 11.2 Promotion sign-off

A human approving a model's promotion to production produces a
signed approval. The signature is keyed to the human's identity
(short-lived OIDC-derived cert), the approval is recorded in the
audit chain, and the deployment proceeds only with a valid
approval signature.

### 11.3 Decision signatures (high-stakes)

For high-stakes individual decisions (loan approvals, medical
diagnoses), the *output* of the model can be signed by the
serving pod, including the model version and the inputs used.
This creates non-repudiation: months later, the decision can be
verified against the model that produced it.

This is operationally expensive and is reserved for genuinely
high-stakes decisions, not for every recommender call.

---

## 12. What you should be able to do after this module

- [ ] Explain the difference between storage-layer, envelope, and
      application-layer encryption — and when each applies.
- [ ] Configure a Kubernetes deployment to use a KMS-backed key
      for application-layer encryption of a PII field.
- [ ] Set up cert-manager + Vault PKI for internal mTLS.
- [ ] Configure Cosign keyless signing in a CI pipeline.
- [ ] Verify a Cosign signature at admission via Kyverno or
      Gatekeeper.
- [ ] Implement a hash-chain audit log given a database backend.
- [ ] Identify three signing failures in a proposed deployment
      and recommend fixes.
- [ ] Recognize when a vendor pitch ("our HE solution gives
      privacy by default") is overpromising.

---

## 13. What this module deliberately doesn't cover

- **Primitive cryptanalysis.** If you need to evaluate whether
  AES-128 is "enough," you're either solving a niche problem
  (use AES-256) or you should consult a cryptographer.
- **FIPS-validated operation procedures.** FIPS is operational
  and audit-focused; consult the cryptographic-module validation
  program for your specific deployment.
- **Post-quantum cryptography.** The migration is real but not
  yet acute for ML-platform-scale systems. Watch the NIST
  PQC project; act when your data has a 10+ year confidentiality
  requirement.
- **HE / MPC research depth.** Mentioned for awareness; not
  practical for typical ML production deployments today.

---

## 14. Suggested reading order outside this module

After this:

1. Skim [NIST SP 800-57 Part 1](https://csrc.nist.gov/pubs/sp/800/57/pt1/r5/final) for the formal key-management framework.
2. Read the [Cosign documentation](https://docs.sigstore.dev/cosign/overview/) — short and concrete.
3. Read the [cert-manager docs](https://cert-manager.io/docs/) on the [Vault issuer](https://cert-manager.io/docs/configuration/vault/).
4. Move to **Module 04: Network Security**.

---

## Appendix A — Glossary

- **AEAD**: Authenticated Encryption with Associated Data. Modes
  like AES-GCM that provide both confidentiality and integrity.
- **CA**: Certificate Authority. Signs certs that other parties
  trust.
- **CRL / OCSP**: Certificate revocation mechanisms.
- **DEK / KEK**: Data Encryption Key / Key Encryption Key
  (envelope encryption).
- **Envelope encryption**: Encrypting data with a DEK, encrypting
  the DEK with a KEK.
- **FIPS 140-3**: NIST's cryptographic module validation program.
- **Fulcio**: Sigstore's keyless-signing CA.
- **HE / FHE**: Homomorphic Encryption / Fully Homomorphic
  Encryption.
- **HMAC**: Keyed message authentication code.
- **HSM**: Hardware Security Module. Tamper-resistant box that
  holds keys.
- **KMS**: Key Management Service.
- **mTLS**: Mutual TLS — both sides authenticate with certs.
- **PKI**: Public Key Infrastructure.
- **Rekor**: Sigstore's transparency log.
- **SNI**: Server Name Indication, the TLS extension that signals
  which hostname is being requested.
- **SVID**: SPIFFE Verifiable Identity Document.
- **TLS**: Transport Layer Security.
- **WORM**: Write-Once-Read-Many storage. Provides
  tamper-evidence via storage primitive.

---

## Appendix B — Common misconceptions

| Misconception | Reality |
|---|---|
| "AES-256 is more secure than AES-128 in practice." | For symmetric attackers, AES-128 is still safe. Choose AES-256 for the security margin and post-quantum hedge, not because AES-128 is broken. |
| "Self-signed certs are fine internally." | They work; they don't compose. Pin the trust chain, or run an internal CA. |
| "Long keys = long-lived keys." | Key length and key lifetime are orthogonal. Rotate keys regardless of length. |
| "If we use TLS, MITM is impossible." | MITM is impossible *if cert verification is implemented correctly*. The qualifier is doing most of the work. |
| "Confidential computing makes the cloud safe." | Confidential computing addresses a specific threat (privileged operators). Most threats survive it. |
| "Homomorphic encryption gives us privacy." | HE gives you compute-on-ciphertext. Privacy is a property of the entire system; HE is a tool. |
| "Our auditor approved this; therefore it's secure." | Auditors check the controls you described. They don't validate the cryptography. Compliance ≠ security. |

---

*Continue to the [exercises](./exercises/) when you're ready to
apply this material to real systems.*
