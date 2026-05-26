# Exercise 03 — Secret Rotation Playbook

**Estimated time**: 2 hours
**Deliverable**: A 2–3 page playbook covering routine + emergency rotation

---

## The assignment

Write a rotation playbook for SmartRecs that covers:

1. **Routine rotation** — scheduled rotation of each secret class
   in your Exercise 01 inventory.
2. **Emergency rotation** — the procedure for a secret confirmed
   compromised.
3. **Rotation testing** — how do you verify rotation works
   *before* you need it?

## What the playbook must cover

For each major secret class in the SmartRecs inventory:

| Field | Content |
|---|---|
| **Secret class** | E.g., "Model artifact store IAM credentials" |
| **Routine cadence** | E.g., "Every 30 days, automated" |
| **Routine procedure** | Numbered steps, executable |
| **Pre-rotation checklist** | What must be true before starting |
| **Rotation window** | Maintenance window required? |
| **Verification** | How to confirm the rotation worked |
| **Rollback** | What to do if rotation breaks production |
| **Emergency procedure** | Same fields, but for "this secret leaked" |
| **Audit trail** | What gets logged where |
| **Owner** | Team responsible |

Cover at least these classes:

- Dynamic database credentials (Vault-issued).
- Static API keys (OpenAI key).
- TLS certificates (cert-manager-managed).
- Cosign signing identity.
- Customer-managed encryption keys.
- CI/CD OIDC trust configuration.

## Format

```
# SmartRecs Rotation Playbook

## Overview
- Schedule overview (calendar view)
- On-call rotation responsibilities

## Rotation: <secret class 1>
### Routine
1. Step
2. Step
...
### Pre-checks
### Verification
### Rollback
### Emergency procedure
### Audit trail

## Rotation: <secret class 2>
...

## Cross-cutting concerns
- How rotations show up in the audit chain
- How rotations are verified (drills)
- Drill cadence

## Annual rotation drill plan
(Quarterly tabletops; what gets tested when.)
```

## Quality criteria

A passing playbook:

- Each secret class has **concrete steps** — runbook-grade, not
  "rotate the secret."
- Each class has a **rollback** option.
- Each class has an **audit-trail** entry.
- The drill plan is on a real cadence.
- Emergency procedures are present even for routine secrets.

A failing playbook:

- Generic "rotate quarterly" with no specifics.
- No rollback steps.
- No mention of how rotations show up in the audit log.
- No drill plan.

## Reflection questions

1. Which rotation is most likely to break production if done
   wrong?
2. Which rotation is most likely to be **skipped** routinely?
   Why? What's the cultural / process fix?
3. If the on-call has 30 minutes during an incident, which
   emergency procedure must be the cleanest?

## Save your artifact

Reusable in Module 07 (Compliance — rotation as a regulatory
control) and Module 11 (Security Operations — detection of
overdue rotations).
