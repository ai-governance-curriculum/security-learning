# Module 05 — Secrets Management for ML Systems

**Duration**: ~20 hours (~1 week full-time, ~2 weeks part-time)
**Prerequisites**:
- Modules 01–04 completed.
- Module 02's workload identity material is the foundation; this
  module assumes you understand SPIFFE-style identity already.
- Module 03's KMS material is the foundation; you should know what
  a KMS is and what envelope encryption is.

## What this module is for

A secret is anything whose disclosure to an unintended party is a
security event: API keys, database passwords, model-store
credentials, signing keys, cloud IAM credentials, customer
PII-encryption keys.

Most production incidents trace back to either a secret that was
**embedded in code** (or an image, or a config), or a secret that
was **long-lived and broadly shared.** This module fixes both.

You will learn:

1. **HashiCorp Vault** at the depth needed to run it (KV, PKI,
   Transit, dynamic database engines).
2. **External Secrets Operator (ESO)** — bringing external secret
   stores into Kubernetes safely.
3. **Cloud-native secret managers** — AWS Secrets Manager, GCP
   Secret Manager, Azure Key Vault.
4. **Dynamic secrets** — credentials created on demand, valid for
   minutes, never stored.
5. **Secret rotation** — both routine and emergency.
6. **CI/CD secrets** — how to give a CI pipeline access without
   creating a long-lived attack surface.
7. **ML-specific secret patterns** — model store credentials,
   training-data credentials, customer-managed keys.
8. **Secret detection** — finding secrets that have already
   leaked (in code, logs, images, model artifacts).
9. **Break-glass procedures** — what to do when a secret is
   confirmed exposed.

## How to work through this module

1. Read [`lecture-notes.md`](./lecture-notes.md).
2. Complete the five exercises in [`exercises/`](./exercises/).
3. Take the [quiz](./quiz.md).
4. Use [`resources.md`](./resources.md) for primary sources.

## Module deliverables

- A **secrets inventory** of SmartRecs (Exercise 01).
- A **Vault deployment plan** including PKI, KV, and Transit
  (Exercise 02).
- A **secret-rotation playbook** for routine and emergency cases
  (Exercise 03).
- A **CI/CD secret design** that avoids long-lived credentials
  (Exercise 04).
- A **secret-leak incident response runbook** (Exercise 05).

## How this module connects to the rest of the track

| Where module 05 shows up later | What it provides |
|---|---|
| Module 07 Compliance | Secret rotation as a regulatory control |
| Module 08 Runtime Security | Detecting secret access from unauthorized processes |
| Module 09 Policy as Code | Policies that mandate dynamic secrets, ban hardcoded ones |
| Module 10 Supply Chain | Signing keys (a special class of secret) |
| Module 11 Security Operations | Detection rules for secret access anomalies |

## Quick reference

- **Lecture notes**: [`lecture-notes.md`](./lecture-notes.md)
- **Exercises**: [`exercises/`](./exercises/)
- **Quiz**: [`quiz.md`](./quiz.md)
- **Resources**: [`resources.md`](./resources.md)
