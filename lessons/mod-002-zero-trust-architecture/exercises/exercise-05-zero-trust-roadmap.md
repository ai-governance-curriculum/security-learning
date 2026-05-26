# Exercise 05 — Zero-Trust Roadmap

**Estimated time**: 2 hours
**Deliverable**: A 3–4 page Markdown roadmap document
**Prerequisite**: Exercises 01 and 02 of this module

---

## The assignment

You are SmartRecs' first security engineer. The CTO asks: "Where
do we start with zero-trust, and how long until we're done?"

Produce a written roadmap that:

1. **Defines "done."** Zero-trust adoption is never literally
   "done" — articulate a measurable end state that the team can
   actually reach.
2. **Sequences the work by reversibility**, not by enthusiasm.
   - **Phase 1**: cheap, easily reversed. Wrong decisions cost days.
   - **Phase 2**: moderate commitment. Wrong decisions cost weeks.
   - **Phase 3**: heavy commitment. Wrong decisions cost quarters.
3. **For each phase**:
   - Goal (1 sentence).
   - Concrete deliverables (3–7 items).
   - Success criterion to advance to the next phase.
   - Estimated calendar duration (be honest).
   - Estimated headcount (be honest).
4. **Names the risks** to the plan and the mitigations.
5. **Includes a rollback story.** Each phase must be reversible
   without an outage.

## Constraints to honor

- SmartRecs has 5 engineers total (3 ML, 1 backend, 1 ops). The
  security engineer (you) is the 6th. The team cannot dedicate
  full attention to security work.
- There are paying customers in production. The roadmap cannot
  produce an outage during rollout.
- The CFO will see this roadmap. Don't overpromise; don't
  underpromise to the point of looking unambitious.

## Format

```
# SmartRecs Zero-Trust Adoption Roadmap

## Author + date

## Executive summary
(3 sentences, readable in 20 seconds)

## "Done" definition
(What measurable end state does adoption reach?)

## Phase 1: Foundations (low-commitment, reversible)
- Goal:
- Deliverables (3–7 items):
- Success criterion:
- Duration:
- Headcount:
- Rollback plan:

## Phase 2: Microsegmentation (medium-commitment)
...

## Phase 3: Identity-first at scale (heavy-commitment)
...

## Phase N (if needed): ...

## Risks and mitigations
(Risk → likelihood → impact → mitigation)

## What this roadmap doesn't include
(Threats from your Module 01 threat model that survive even full
adoption.)

## CFO-friendly summary
(One paragraph at the top, defensible against a finance review.)
```

## Quality criteria

A passing roadmap:

- Defines "done" **concretely** — something a team can audit
  against.
- Sequences by reversibility, not by glamour. Foundation controls
  (identity issuance, audit log) come before glamorous ones
  (per-request policies).
- Honest about headcount and duration — zero-trust adoption at
  SmartRecs' size is usually a 12–24 month effort, not a
  quarter.
- Includes a rollback story.
- Acknowledges what zero-trust *doesn't* solve, with pointers to
  the modules that do.

A failing roadmap:

- "Phase 1: install Istio." → over-tooling early. Foundations
  are identity and audit; Istio comes later.
- A 6-week timeline. The work doesn't fit.
- No rollback story. A roadmap without rollback is a roadmap to
  an outage.
- No CFO-friendly summary — the CTO will refuse to take it to
  finance.

## Reflection questions

1. Which phase is the team most likely to skip? Why? How would
   you defend keeping it?
2. Which phase requires the most cross-team buy-in? How would
   you build it?
3. If forced to compress the roadmap by half (faster duration,
   same scope), which deliverables get cut, and why?
4. What single milestone, if achieved early, would most accelerate
   the rest of the adoption?

## Capstone connection

This roadmap is the document your replacement will inherit if you
leave SmartRecs. Write it as if for that audience.

## Solution comparison

After writing your own, compare against the reference roadmap in
[`ai-infra-security-solutions/modules/mod-002-zero-trust-architecture/exercise-05/`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions/tree/main/modules/mod-002-zero-trust-architecture) (when published).
