# Module 07 — Compliance and Governance for ML Systems

**Duration**: ~35 hours (~1.5 weeks full-time, ~3 weeks part-time)
**Prerequisites**:
- Modules 01–06 completed. Module 03's hash-chain audit log,
  Module 02's identity controls, and Module 06's DP-SGD all
  reappear here as compliance controls.
- Comfort reading regulatory text — this module deals with
  GDPR, HIPAA, SOC 2, EU AI Act. You don't need a JD, but you
  need to read carefully.

## What this module is for

The other modules ask "is this secure?" This module asks "can
we prove it to an auditor, regulator, or customer?"

The framing shift is important: a system designed *only* for
auditors will pass audits and fail real threats; a system
designed *only* for threats will defend against attacks and
fail audits. The right design satisfies both — but the
compliance work is its own discipline.

You will learn:

1. **The compliance landscape for ML** — which frameworks
   matter, when, and why.
2. **GDPR** for ML — subject rights, lawful basis,
   automated-decision controls, cross-border transfer.
3. **HIPAA** for ML — the technical safeguards, business
   associate agreements, ML-specific concerns.
4. **SOC 2** — the Trust Services Criteria, what an audit
   actually looks like, how to be ready.
5. **EU AI Act** — risk classifications, obligations, timelines.
6. **ISO 27001 / ISO 42001** — the international management-
   system standards.
7. **NIST AI RMF** — the risk-management framework that
   underpins much of the rest.
8. **Audit-chain integration** — turning Module 03's hash chain
   into a compliance artifact.
9. **Compliance automation** — moving from "audit panic week"
   to "evidence is continuous."
10. **Vendor risk** — your supply chain matters for compliance.

## How to work through this module

1. Read [`lecture-notes.md`](./lecture-notes.md). It's long
   because the regulatory surface is broad; skim the sections
   for regulations that don't apply to your context.
2. Complete the five exercises in [`exercises/`](./exercises/).
3. Take the [quiz](./quiz.md).
4. Use [`resources.md`](./resources.md) for primary sources —
   for compliance work, citing the regulation directly is
   table stakes.

## Module deliverables

- A **regulatory-applicability matrix** for SmartRecs (Exercise 01).
- A **GDPR controls implementation plan** (Exercise 02).
- A **SOC 2 readiness assessment** (Exercise 03).
- A **continuous compliance design** integrating with the audit
  chain (Exercise 04).
- A **vendor-risk review process** (Exercise 05).

## How this module connects to the rest of the track

| Where module 07 shows up later | What it provides |
|---|---|
| Module 08 Runtime Security | Detections that satisfy regulatory monitoring requirements |
| Module 09 Policy as Code | Policies that encode compliance controls |
| Module 10 Supply Chain | Vendor risk + supply-chain attestation |
| Module 11 Security Operations | Incident response timelines (GDPR 72h, etc.) |

## Quick reference

- **Lecture notes**: [`lecture-notes.md`](./lecture-notes.md)
- **Exercises**: [`exercises/`](./exercises/)
- **Quiz**: [`quiz.md`](./quiz.md)
- **Resources**: [`resources.md`](./resources.md)
- **Paired project**: [`projects/project-2-compliance/`](../../projects/project-2-compliance/)
- **Paired solution**: [`ai-infra-security-solutions/projects/project-2-compliance/SOLUTION.md`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions/blob/main/projects/project-2-compliance/SOLUTION.md)
