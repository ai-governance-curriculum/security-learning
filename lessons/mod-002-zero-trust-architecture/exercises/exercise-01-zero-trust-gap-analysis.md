# Exercise 01 — Zero-Trust Gap Analysis

**Estimated time**: 2 hours
**Deliverable**: 2–3 page Markdown gap analysis
**Prerequisite**: Module 01 Exercise 01 (the SmartRecs threat model)

---

## The assignment

Take the SmartRecs system from Module 01 (or your own equivalent)
and produce a gap analysis against the **five NIST SP 800-207
zero-trust tenets** from lecture-notes §1.1.

For each tenet:

1. **State the tenet** in your own words (don't quote NIST verbatim).
2. **Assess SmartRecs** against the tenet:
   - **Compliant** — SmartRecs already satisfies this tenet.
   - **Partially compliant** — Some satisfaction, with named gaps.
   - **Non-compliant** — SmartRecs fundamentally violates the tenet.
3. **Cite the specific evidence** in the SmartRecs architecture
   that supports your assessment.
4. **For Partial / Non-compliant tenets**, name the **architectural
   change** that would close the gap. Be specific. Not "improve
   authentication" but "introduce SPIRE-issued workload identities
   for the 4 workload classes (training, serving, governance,
   notebook)."
5. **Rate the gap by effort × impact**:
   - Effort: small / medium / large (eng-weeks).
   - Impact: high / medium / low (what threats it mitigates).

## Format

Suggested structure:

```
# Zero-Trust Gap Analysis: SmartRecs

## Reference: Module 01 threat model
(link to your artifact)

## Tenet 1: <name>
- Statement
- Assessment: <compliant/partial/non-compliant>
- Evidence in SmartRecs
- Required architectural change
- Effort × Impact

## Tenet 2: ...
## Tenet 3: ...
## Tenet 4: ...
## Tenet 5: ...

## Summary table (one row per tenet)

## Top 3 gaps to address first, with justification

## What zero-trust doesn't help with at SmartRecs
(threats from Module 01 model that survive even full zero-trust
adoption)
```

## Quality criteria

A passing analysis:

- Treats each tenet **separately**. Cross-tenet hand-waving doesn't
  count.
- Identifies the gaps **concretely**, with named workloads, services,
  trust boundaries.
- Acknowledges the threats zero-trust **doesn't** help with —
  showing calibrated understanding.
- Produces a defensible top-3 prioritization.

A failing analysis:

- Treats "zero-trust" as a single yes/no — misses the per-tenet
  granularity.
- Recommends generic best-practices without naming the SmartRecs
  workloads they apply to.
- Claims zero-trust solves everything — overclaims.

## Reflection questions

1. Which tenet is hardest for SmartRecs to satisfy? Why?
2. Which tenet is easiest? Why is it usually the first to get
   declared "done" prematurely?
3. Which of your top-3 gaps will get the most pushback from the
   engineering team? Why? How would you justify the prioritization
   anyway?

## Save your artifact

You'll use this in Exercise 5 (the roadmap) and in Module 04
(network security deep dive).
