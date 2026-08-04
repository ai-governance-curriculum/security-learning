# mod-105-secrets-and-key-management: Secrets and Key Management for ML — Vault, KMS, Keyless CI, Ephemeral Credentials

**Estimated effort:** 12 hours
**Track:** AI/ML Security & Governance Engineer (`security`, level 35)
**Requirement theme covered:** req-04

---

## What this module installs

Every control in mod-102 → mod-104 is underwritten by secret
material: dynamic credentials for shared data stores, KMS keys
that wrap training data at rest, signing keys that back
cosign/SLSA attestations, cloud tokens that CI uses to deploy.
This module names that material, custody-manages it, and
rehearses what happens when it leaks.

It answers four operational questions:

1. What secrets does an ML platform actually hold — and who
   owns each?
2. How do we issue credentials to workloads without static
   long-lived tokens?
3. How do we encrypt training data and model artifacts at rest
   so a compromised access grant does not compromise the
   corpus?
4. How do we sign artifacts and deploy from CI without a
   long-lived credential sitting in the CI system?
5. When something leaks anyway, what do we do — in what
   order, on what SLA?

Chapter 01 produces the inventory; chapters 02–04 install the
lifecycle for the three main classes of material; chapter 05
authors the runbook for the day it fails.

---

## Learning objectives

- Inventory the secrets an ML platform actually holds — training
  data-store creds, feature-store creds, model-registry creds,
  external-API keys, model artifact signing keys, judge-model
  creds, PII/PHI decryption keys.
- Deploy Vault with dynamic secrets for time-limited access to
  shared data stores.
- Configure envelope encryption with cloud KMS for at-rest
  datasets and model artifacts, and separate keys per
  environment / tenant / sensitivity tier.
- Wire keyless CI (OIDC → short-lived cloud tokens, keyless
  cosign signing) so no long-lived credentials sit in the CI
  system.
- Author a secret-leak response runbook — detect, contain,
  rotate, notify — with concrete SLA numbers.
- Cover requirement theme req-04.

---

## Chapters

1. [Chapter 01 — What Secrets an ML Platform Actually Holds](./01-ml-secrets-inventory.md)
   — the eleven secret classes, secrets vs keys, sensitivity /
   environment / tenant classification, and the inventory table
   that drives the rest of the module.
2. [Chapter 02 — Vault and Dynamic Secrets for Shared Data Stores](./02-vault-dynamic-secrets.md)
   — Vault topology, Kubernetes auth, dynamic database and
   cloud-IAM engines, KV for external-provider tokens, audit
   detections.
3. [Chapter 03 — Envelope Encryption With Cloud KMS for ML Data and Artifacts](./03-envelope-encryption-with-kms.md)
   — envelope encryption (KEK/DEK/wrapped-DEK), key hierarchy
   by environment / sensitivity / tenant, cryptographic
   erasure, KMS policy shape, key-rotation without data
   re-encryption.
4. [Chapter 04 — Keyless CI: OIDC to Cloud, Keyless Cosign Signing](./04-keyless-ci-with-oidc-and-cosign.md)
   — CI OIDC federation to AWS/GCP/Azure IAM, keyless cosign
   signing via Fulcio, strict trust-policy conditions,
   phased rollout.
5. [Chapter 05 — The Secret-Leak Response Runbook](./05-secret-leak-response-runbook.md)
   — detect / contain / rotate / notify with concrete SLA
   numbers, per-class variants for the seven ML-specific
   secret classes, rehearsal cadence.

---

## Structure

- `01-…md` … `05-…md`: lecture chapters (above).
- [`exercises/`](./exercises/): five prompts — inventory, Vault
  dynamic-secrets plan, envelope-encryption design, keyless-CI
  wiring, secret-leak runbook.
- `labs/`: long-form hands-on labs (scaffolded — populated in a
  later cycle).
- `quizzes/`: knowledge checks (scaffolded).
- [`resources.md`](./resources.md): external references and
  primary sources.

---

## Prerequisites

- Mod-101 (position and scope of the ML security function).
- Mod-102 (threat modelling — you should be able to enumerate
  which threats a secret-management gap enables).
- Mod-103 (zero-trust primitives — chapters 02 and 04 build
  on the SPIFFE workload identity from mod-103 chapter 03).
- Mod-104 (signed provenance — chapter 04 depends on the
  cosign / Sigstore mental model from mod-104 chapter 02).

Working knowledge of one cloud IAM system (AWS IAM, GCP IAM,
or Azure AD) and one CI system (GitHub Actions, GitLab CI, or
similar).
