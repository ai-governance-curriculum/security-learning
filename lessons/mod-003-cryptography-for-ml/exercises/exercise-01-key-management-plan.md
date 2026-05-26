# Exercise 01 — Key Management Plan

**Estimated time**: 2 hours
**Deliverable**: A 2–3 page Markdown plan + a KEK hierarchy diagram

---

## The assignment

Design a key-management plan for SmartRecs that satisfies the
five principles from lecture-notes §5.1.

The plan must cover:

1. **KEK hierarchy** (lecture-notes §5.4). Draw or describe the
   hierarchy of root → tenant → data keys.
2. **Per-purpose separation.** Identify at least 5 distinct
   purposes (e.g., training-data encryption, model-artifact
   encryption, audit-log signing, customer API auth, internal
   mTLS) and assign distinct keys to each.
3. **IAM model.** For each key, which workload identity
   (from Module 02 Exercise 02) is allowed to call
   `encrypt` / `decrypt` / `sign` / `verify` on it.
4. **Rotation cadence.** For each key, a rotation interval and a
   triggered-rotation event (e.g., "rotate on suspected
   compromise").
5. **Backend.** Which KMS holds each key — cloud-native KMS, Vault
   Transit, or HSM. Justify the choice.
6. **Migration story.** SmartRecs currently has *one* shared API
   key stored as a Kubernetes Secret. How do you get from there to
   the proposed plan, in phases, without an outage?

## Format

```
# SmartRecs Key Management Plan

## Reference
(links to Module 02 workload identity table)

## KEK hierarchy
(diagram, ASCII or Mermaid)

## Per-purpose keys (table)

| Purpose | Key class | Backend | Rotation | Triggered rotation | Workload(s) authorized |
|---|---|---|---|---|---|

## Operational ownership

(Who has the runbook for rotation? Who has the runbook for
compromise response?)

## Migration: from "one shared key" to this plan

### Phase 1: Foundations (reversible, <2 wk)
### Phase 2: Per-purpose keys (2-4 wk)
### Phase 3: Tenant-scoped envelope encryption (1-2 mo)
### Phase 4: Steady state

## Risks and mitigations

## What this plan deliberately does NOT cover
(e.g., post-quantum migration, FIPS 140-3, customer-managed keys)
```

## Quality criteria

A passing plan:

- Identifies **at least 5 distinct key purposes**.
- Each key has a **named backend** (AWS KMS in region X / Vault
  Transit / HSM model Y).
- Each key has an explicit **rotation interval** (e.g., 90 days
  for KEK, ephemeral for DEK).
- IAM is keyed on **workload identity**, not on IP, namespace, or
  shared API keys.
- The migration plan is realistic — small steps, each reversible.

A failing plan:

- "We'll use AWS KMS for everything" — undifferentiated.
- "Annual rotation" with no triggered-rotation event.
- IAM model is "the admin role can do everything."
- No migration plan, or a migration plan that requires a flag day.

## Reflection questions

1. Which key in your plan has the highest blast-radius if
   compromised? What additional control reduces that risk?
2. Which key is most likely to have its rotation skipped because
   "it would take too long"? How do you defend the cadence?
3. If SmartRecs hires a CISO who insists on FIPS 140-3 validation
   for one regulated customer, which keys would need to move
   into a FIPS-validated module, and what's the implementation
   cost?

## Save your artifact

This is the input to Module 05 (Secrets Management) and Module 07
(Compliance).
