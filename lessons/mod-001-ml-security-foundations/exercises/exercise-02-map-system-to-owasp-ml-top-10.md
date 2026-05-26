# Exercise 02 — Map a System to OWASP ML Top 10

**Estimated time**: 1–2 hours
**Deliverable**: A 1–2 page Markdown coverage matrix
**Prerequisite**: Exercise 01 completed

---

## The assignment

Take the SmartRecs system from Exercise 01 (or your own threat
model output) and produce a per-item coverage matrix against the
OWASP ML Security Top 10.

For each of the 10 items:

1. **Applicability**: Does this threat apply to SmartRecs?
   - **YES** — explain in one sentence why.
   - **NO** — explain in one sentence why not. (Be wary of false
     "no" answers; most items apply to most ML systems.)
2. **Current controls**: What does SmartRecs have today that
   reduces this threat? "Nothing" is a valid answer.
3. **Coverage assessment**: One of:
   - **Adequate** — the existing controls cover the realistic
     threat surface for this system.
   - **Partial** — controls exist but have known gaps.
   - **Inadequate** — controls are missing or token.
4. **Required additions**: If coverage is Partial or Inadequate,
   name the specific controls that would close the gap. Be
   concrete: not "improve input validation" but "add a
   distribution-monitor on feature `user_recency_days` that
   alerts when the production distribution diverges from the
   training distribution by KL > 0.1."
5. **Effort estimate**: Rough effort to add the missing controls.
   Use weeks (eng-weeks).

## Format

A table is the right format. Suggested:

| ID | Applies? | Why | Current controls | Coverage | Required additions | Effort |
|---|---|---|---|---|---|---|
| ML01 | YES | Adversarial queries can flip recommendation rankings | None | Inadequate | Distribution monitor + per-tenant rate limit | 2 wk |
| ML02 | YES | Feedback loop could be poisoned by colluding customers | Untrained-eligibility flag | Partial | Add outlier detection on retraining data | 1 wk |
| ... | ... | ... | ... | ... | ... | ... |

Below the table, a 3–4 paragraph **executive summary**:

- The **top three** gaps by impact.
- Why these three (defend against the alternative ranking).
- A proposed sequencing of mitigations.

## Quality criteria

A passing matrix:

- Every row is filled in. "I don't know" is not "N/A".
- The Applies? column is mostly YES with concrete reasoning. A
  matrix with multiple NOs for an ML system is usually wrong.
- The required additions are *engineering work*, not aspirations.
- The effort estimates are credible — not "1 day" for things
  that take quarters.

A failing matrix:

- Treats "we have an audit log" as sufficient for everything.
- Marks items NO with no defense.
- Recommends "implement security best practices" without
  specifics.

## Reflection questions

1. Which Top-10 item has the **largest** gap, and why is it
   easiest to overlook?
2. Are there threats your Exercise 01 model identified that *don't*
   map cleanly to a Top-10 item? Where do they belong?
3. Which Top-10 item is the team most likely to push back on
   prioritizing, and how would you defend its priority?

## Solution comparison

After writing your own, compare against the reference matrix in
[`ai-infra-security-solutions/modules/mod-001-ml-security-foundations/exercise-02/`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions/tree/main/modules/mod-001-ml-security-foundations) (when published).

The reference matrix is not the *only* correct matrix; defensible
matrices will differ in priority ordering and effort estimates.
What should be similar is which items are addressed and what kind
of controls fill the gaps.
