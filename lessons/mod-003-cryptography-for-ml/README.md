# Module 03 — Cryptography for ML Systems

**Duration**: ~20 hours (~1 week full-time, ~2 weeks part-time)
**Prerequisites**:
- Modules 01 and 02 completed.
- Working understanding of TLS, public-key cryptography, hash
  functions at the conceptual level.
- You should know what AES, RSA, ECDSA, SHA-256, and HMAC *are*;
  this module will not re-derive primitives.

## What this module is for

Modules 01 and 02 set up the *vocabulary* (threats) and the
*architecture* (zero-trust identity). This module covers the
*mechanisms* — the cryptographic primitives that make those
controls actually enforceable.

The goal is not to make you a cryptographer. It is to make you
**operationally fluent**: capable of choosing the right primitive,
configuring it safely, and recognizing the patterns where
cryptography is doing the wrong job.

You will learn:

1. **Encryption at rest** — for training data, model artifacts, and
   feature stores. KMS vs. envelope encryption vs. application-layer
   encryption.
2. **Encryption in transit** — TLS / mTLS configuration that
   survives audit and operations.
3. **Encryption in use** — what confidential computing buys (and
   doesn't).
4. **Key management** — HashiCorp Vault, cloud KMS, key rotation,
   key separation by use.
5. **Certificate management** — cert-manager, ACME, internal CAs,
   identity-bound certs.
6. **Signing** — model artifacts, container images, attestations.
   Cosign / Sigstore.
7. **Hash chains and tamper-evidence** — the foundation of the
   audit log work in Module 07.
8. **Homomorphic encryption** — what it is, what it's actually
   useful for in ML, and where it isn't.
9. **Common cryptographic mistakes** in ML systems specifically.

## How to work through this module

1. Read [`lecture-notes.md`](./lecture-notes.md).
2. Complete the five exercises in [`exercises/`](./exercises/).
3. Take the [quiz](./quiz.md).
4. Use [`resources.md`](./resources.md) for primary sources.

## Module deliverables

- A **key management plan** for SmartRecs (Exercise 01).
- A **TLS/mTLS configuration audit** of an existing deployment (Exercise 02).
- A **signed-artifact rollout plan** for model artifacts (Exercise 03).
- A **certificate management runbook** (Exercise 04).
- An **encryption-in-use decision document** for a regulated workload
  (Exercise 05).

## How this module connects to the rest of the track

| Where module 03 shows up later | What it provides |
|---|---|
| Module 04 Network Security | TLS / mTLS as the substrate for segmentation |
| Module 05 Secrets Management | Vault deep dive (this module is the cryptography primer) |
| Module 07 Compliance | Encryption controls that map to regulatory requirements |
| Module 10 Supply Chain | Cosign / Sigstore for image and model signing |
| Module 11 Security Operations | Hash chain audit log + signing-failure detections |

## Quick reference

- **Lecture notes**: [`lecture-notes.md`](./lecture-notes.md)
- **Exercises**: [`exercises/`](./exercises/)
- **Quiz**: [`quiz.md`](./quiz.md)
- **Resources**: [`resources.md`](./resources.md)
