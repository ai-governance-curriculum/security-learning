# Module 12 — Capstone

**Duration**: ~30 hours (~1 week full-time, ~2 weeks part-time)
**Prerequisites**: Modules 01–11 completed. This module is the
**synthesis** of the entire track; you should have working
artifacts from all eleven prior modules before starting here.

## What this module is for

The first 11 modules taught **components**: threat models,
zero-trust, cryptography, network controls, secrets, adversarial
ML, compliance, runtime, policy, supply chain, SecOps.

This module is **integration**. You take a single, more
realistic system and produce the **complete security program**
for it — design, controls, detections, IR, compliance,
documentation. The capstone is the deliverable an interviewer or
hiring manager would use to assess "is this person ready to
operate as an AI infrastructure security engineer?"

The shift is in three dimensions:

1. **Scenario complexity**: the capstone scenario is more
   realistic than SmartRecs — multi-tenant, regulated, with
   adversarial threats and real compliance obligations.
2. **Output integration**: every artifact builds on every other.
   The threat model informs the architecture; the architecture
   informs the controls; the controls produce signals; the
   signals drive detections; the detections trigger IR; IR
   produces postmortems; postmortems update controls. The
   capstone makes the loop concrete.
3. **Audience awareness**: artifacts are written for specific
   audiences (CISO, CFO, customer's security review, regulator,
   on-call engineer). Each audience needs different framing.

## How to work through this module

Unlike the prior modules, this one has:

- **No new lecture content** — only synthesis guidance
  ([`lecture-notes.md`](./lecture-notes.md) covers how to
  approach synthesis work, not new concepts).
- **No quiz** — instead, a self-assessment readiness checklist
  appears in [`readiness-checklist.md`](./readiness-checklist.md).
- **More exercises**: six, building progressively to a complete
  program.
- **A grading rubric**: usable by an instructor, a peer
  reviewer, or for self-evaluation.

Plan for **2–4 weeks of part-time work** or 1 intensive week.
The artifacts are substantial; don't rush.

## The scenario

The capstone scenario is **NorthBridge Health**, a healthcare ML
company. Read the full brief in
[`scenario-brief.md`](./scenario-brief.md) before starting any
exercise. The scenario is deliberately richer than SmartRecs — it
includes:

- US healthcare customers (PHI under HIPAA).
- EU customers (PII under GDPR; high-risk AI under the EU AI Act).
- An LLM-based clinical decision support feature.
- Pursuing SOC 2 Type 2.
- A planned multi-cloud expansion in 12 months.
- A team that's growing from 8 to 25 engineers over the next year.
- Real adversarial threats: data extraction, prompt injection,
  insider threat, supply chain.

## The deliverable

By the end of this module, you produce a **portfolio**:

| # | Artifact | Audience |
|---|---|---|
| 1 | Threat model + applicability matrix | Engineering + security leadership |
| 2 | Architecture (zero-trust + crypto + network + secrets) | Engineering leadership |
| 3 | ML-specific controls (adversarial defenses + provenance) | ML platform team |
| 4 | Compliance + policy program | CFO + auditor + customer CISO |
| 5 | SecOps program (detection + IR + on-call) | Security team + leadership |
| 6 | Stakeholder communication portfolio | Various — CFO, customers, regulators |

Each builds on the previous. The collection is the deliverable.

## Quick reference

- **Scenario brief**: [`scenario-brief.md`](./scenario-brief.md)
- **Synthesis guidance**: [`lecture-notes.md`](./lecture-notes.md)
- **Readiness checklist**: [`readiness-checklist.md`](./readiness-checklist.md)
- **Exercises**: [`exercises/`](./exercises/)
- **Grading rubric**: [`grading-rubric.md`](./grading-rubric.md)
- **Resources**: cross-references back to Modules 01-11.

## What this module deliberately doesn't cover

- New technical material. The track teaches; the capstone
  synthesizes.
- A solved-example "model answer." Defensible capstones
  differ; there's no single right answer.
- Code implementation. The capstone produces design and
  operational artifacts, not running code.

## A note on time

A 30-hour budget across 6 exercises is ~5 hours per exercise.
That's the **minimum**. A serious capstone may take 60+ hours.
Treat the time budget as a floor; quality compounds.
