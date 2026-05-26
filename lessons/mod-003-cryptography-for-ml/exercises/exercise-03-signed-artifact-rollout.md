# Exercise 03 — Signed-Artifact Rollout Plan

**Estimated time**: 2 hours
**Deliverable**: A 2–3 page phased rollout plan

---

## The assignment

SmartRecs currently ships 24 model artifacts to production. None
are signed. Promotion is `kubectl apply` by a platform engineer.

Design a phased rollout that introduces Cosign signing **and**
admission verification, with **zero production outages**.

## Constraints

- **No production outages.** Each phase must be safely revertible
  on its own. No flag day.
- **Phased, not big-bang.** Three to five phases.
- **Cosign keyless** (OIDC + Fulcio + Rekor) is the chosen
  signing approach.
- **Kyverno** is the chosen admission controller.
- The CI runs in GitHub Actions; that's the signing identity.
- A model artifact lives in S3 at `s3://smartrecs-models/<name>/<version>/`.

## Each phase must specify

1. **Goal** of the phase.
2. **Deliverables** — concrete actions / artifacts.
3. **What's running in production at the end of the phase** (the
   intermediate state).
4. **Rollback plan** — if this phase breaks production, how does
   the team revert?
5. **Success criterion** to advance.
6. **Duration estimate** (calendar weeks).
7. **Failure mode** — what does it look like if this phase is
   skipped or executed poorly?

## Specific design questions to address

- How does signing get retrofitted for the **existing 24 artifacts**?
  (Re-sign in CI? Re-sign manually? Allowlist legacy artifacts
  during transition?)
- What does the admission policy say in the **early phases** when
  some artifacts are signed and others aren't?
  - Hint: most policy engines support a "warn" mode that logs but
    doesn't block. That's where you start.
- How does the team **roll back** if a critical artifact suddenly
  fails admission due to a bad signature?

## Format

```
# Signed-Artifact Rollout Plan: SmartRecs

## Goal
(End state: every artifact admitted to production has a valid
Cosign signature from the expected CI identity, recorded in
Rekor.)

## Phase 1: Foundations (instrument-only)
- Goal:
- Deliverables:
- End-of-phase state:
- Rollback:
- Success criterion:
- Duration:
- Failure mode:

## Phase 2: New artifacts signed (no enforcement)
...

## Phase 3: Existing artifacts re-signed
...

## Phase 4: Admission warning mode
...

## Phase 5: Admission enforcement
...

## Cross-cutting concerns

### Existing artifacts handling
### Emergency override (break-glass)
### Audit-log integration

## Roles and responsibilities

## Risks

## Open questions
```

## Quality criteria

A passing plan:

- Has **at least 4 phases** with credible duration estimates.
- Each phase ends in a **deployable state** — half-done states
  that require completion of the next phase to function are
  unsafe.
- Names a **break-glass override** — there must be a documented
  way to deploy unsigned in an emergency, and that override must
  itself be audited.
- Addresses the **legacy 24 artifacts** explicitly.
- The "warning mode" phase is explicit and precedes enforcement.

A failing plan:

- "Phase 1: turn on enforcement" → outage.
- No rollback plans on any phase.
- Treats the existing 24 artifacts as someone else's problem.

## Reflection questions

1. Which phase is most likely to **stall** if the team gets
   distracted by other work? How do you reduce that risk?
2. The break-glass override is a security weakness. How do you
   protect it from abuse?
3. If the CI's OIDC identity changes (e.g., GitHub Actions runner
   migration), what breaks, and how do you mitigate?

## Save your artifact

Reusable in Module 10 (Supply Chain Security).
