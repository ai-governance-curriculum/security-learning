# Exercise 03 — MITRE ATLAS Walkthrough

**Estimated time**: 1–2 hours
**Deliverable**: A 2–3 page Markdown narrative
**Prerequisite**: Exercise 01 completed

---

## The assignment

Pick **one** threat from your Exercise 01 threat model and walk it
through the MITRE ATLAS tactic chain (lecture notes §3.1).

If you don't have a strong candidate, use this default:

> **Default scenario.** A competitor of SmartRecs wants to
> replicate SmartRecs' recommendation quality without paying for
> the underlying data and training compute. They have a budget
> of ~$50k and 6 months. They have technical staff capable of
> training models. They have a paid SmartRecs subscription.

For your chosen scenario, produce a written narrative that:

1. **Names the adversary, the goal, and the constraints.** One
   paragraph.
2. **Walks each ATLAS tactic** that applies. Skip tactics that
   don't apply (with a one-line note saying why). For each
   applicable tactic, write 2–4 sentences:
   - **What the adversary does.** Concrete actions.
   - **What signal it produces.** Logs, metrics, side effects.
   - **What detection (if any) would fire.**
3. **Identifies the *first* detection that could catch this**
   end-to-end. Argue why detections earlier than that one would
   either fail or be evaded.
4. **Identifies the *latest* detection that's still useful.**
   Even if early detection fails, what's the last chance to
   catch the adversary before Impact?
5. **Names the **gap** — the stage of the chain where SmartRecs
   has no realistic detection capability.

## Format

Suggested structure:

```
# ATLAS Walkthrough: <scenario name>

## Adversary
## Goal and constraints
## Tactic chain walkthrough
  ### Reconnaissance
  ### Resource Development
  ### Initial Access
  ### ML Model Access
  ### Discovery
  ### Collection
  ### ML Attack Staging
  ### Exfiltration
  ### Impact
## First realistic detection point
## Last realistic detection point
## Detection gaps
## Recommended detection additions
```

## Quality criteria

A passing walkthrough:

- Treats the adversary as a **realistic** actor — not omniscient,
  not omnipotent, not stupid.
- Names the **signal** each tactic produces — what would actually
  appear in logs, metrics, or behavior.
- Defends the detection-point choices against the obvious
  alternatives (why not earlier? why not later?).
- Names a **realistic** gap, not the worst-case "no detection
  anywhere" gap.

A failing walkthrough:

- Skips tactics without justification.
- Treats every step as inherently detectable.
- Recommends "improve monitoring" without specifying which signal
  on which surface.

## Mini-exercises (15 min each)

If you finish the main exercise quickly:

### A. Counter-scenario

Rerun the walkthrough with the same adversary but **half the
budget and half the time**. Which tactics fall out of reach?
Which stays the same?

### B. Insider variant

Rerun with an **insider** (a SmartRecs employee with read access
to the model artifact). Which ATLAS tactics become trivial? Which
detections fire on insiders that don't fire on outsiders?

### C. Detection authoring

Write a Sigma rule (or pseudo-Sigma) for the **first detection
point** you identified. It doesn't have to be syntactically
perfect, but it should be specific enough that an engineer could
implement it.

## Solution comparison

After writing your own, compare against the reference walkthrough
in [`ai-infra-security-solutions/modules/mod-001-ml-security-foundations/exercise-03/`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions/tree/main/modules/mod-001-ml-security-foundations) (when published).
