# Exercise 05 — Mitigation Prioritisation Scorecard

**Estimated effort:** ~3 hours
**Deliverable:** A scored, tiered mitigation scorecard (Markdown or
CSV), a prioritised roadmap (Markdown), and a signed acceptance memo
(Markdown, one page).
**Prerequisites:** Exercises 01–04 complete. Chapter 06 read
end-to-end.

---

## Objective

Produce the module's culminating artifact: a **defensible
prioritised roadmap** of mitigations for the target system, ranked
on cost / coverage / detectability, tiered P0–P3, and closed with
an acceptance memo you would put in front of a CISO or peer
engineering leader for sign-off.

By the end of the exercise, the roadmap is in a shape mod-112
(program leadership) can maintain quarterly, and the module's
threat-model packet is complete.

## Problem statement

Same target system as exercises 01–04. Your inputs:

- The exercise-01 asset inventory (blast-radius data per asset).
- The exercise-02 STRIDE-per-element table (rows per threat).
- The exercise-03 IR-consumable inventory + coverage-vs-gap report
  (ATLAS + NIST tags per threat, status per axis).
- The exercise-04 attack trees + candidate-cuts lists (paths cut
  per candidate mitigation).

Your job is to consolidate these into a single scorecard, rank,
tier, sequence, and close with a memo.

## Requirements

### Artifact 1 — `mitigation-scorecard.md` (or `.csv`)

One row per candidate mitigation drawn from:

- Preventive controls from mod-101 chapter 01 coverage matrix (if
  you completed exercise 01 there — reuse it).
- Detective controls from mod-101 chapter 02.
- Preventive / detective sketches from exercise 02.
- Candidate cuts from exercise 04.
- Governance-obligation-derived controls from mod-101 chapter 04.

Each row uses the full row template from chapter 06:

| MIT ID | Description | Source(s) | Class | Cost — eng build (ordinal + eng-weeks) | Cost — ongoing ops (ordinal + $/mo) | Cost — user-visible | Coverage — STRIDE row IDs | Coverage — attack-tree cuts | Detectability | Independence (substitutes / stacks) | Score | Tier |

Rules:

- **Source column is mandatory.** Every mitigation traces back to a
  STRIDE row ID, an attack-tree node ID, and/or a framework
  obligation. No sources → no scorecard row.
- **Coverage column names IDs, not counts.** A mitigation covering
  "3 rows" is not the same as one covering "3 low-severity rows";
  the reviewer must be able to trace.
- **Cost column has both an ordinal and a rough estimate.** Ordinal
  for ranking; estimate for planning.
- **Independence column is populated.** Two mitigations that cut
  the same paths substitute for each other; two that cut disjoint
  paths stack. Chapter 06 requires this so the tiering doesn't ship
  two substitutes at P0.
- **Score uses a stated weighting.** Either the shape-A composite
  (weighted ordinals) or the shape-B quadrant with an
  accompanying tiebreak rule. The weighting is documented at the
  top of the file.

Include a top-of-file header naming:

- The date, the target system, the exercise version references.
- The scoring shape used (weighted ordinal / quadrant / other) and
  the axis weights.
- The three sanity checks from chapter 06 explicitly answered:
  - "Every P0 mitigation cuts ≥1 top-three attack-tree root."
  - "Every P0 mitigation has a named owner and a fit in the
    quarter."
  - "No two P0 mitigations are substitutes for each other."

### Artifact 2 — `roadmap.md`

The sequenced view of the tiered scorecard:

- **This quarter (P0)** — bullet per P0 mitigation with owner,
  eng-week estimate, and dependency notes. Total eng-weeks at the
  bottom; if that exceeds available capacity, name the
  down-tiered mitigation explicitly.
- **Next quarter (P1)** — same shape, one quarter out. Include any
  P1 items that pair with a P0 (detective for a preventive, or
  vice versa) and would degrade the P0 if omitted.
- **Backlog (P2)** — items to escalate on signal, with the signal
  condition named (e.g., "escalate DP-SGD to P1 if inversion
  detector fires signal on ≥ N tenants per month").
- **Not planned (P3 / off-list)** — with the rationale so future-
  you does not re-open the debate.

### Artifact 3 — `acceptance-memo.md`

A one-page memo, addressed to the CISO or the security-engineering
leader, that:

- Names the target system in one sentence.
- Names the top three threats from exercise 04 in one sentence
  each.
- Names the P0 mitigations from artifact 2 with expected coverage.
- Names the top three residual risks (threats where no mitigation
  is at P0 or P1) and the acceptance rationale.
- Requests sign-off, with a place for the signature date.

The memo is the artifact the roadmap actually ships on. Practice
the tone — this is not a policy document; it is a decision-
requesting memo.

## Starter guidance

- Draft the scorecard by walking exercise-04's candidate-cuts list
  and adding one row per cut. Then add rows for mitigations
  motivated by STRIDE rows outside the top-three trees but with
  strong obligation drivers (e.g., DP-SGD for the training-data
  inversion row driven by GDPR / GLBA).
- Score coverage against the attack trees first, STRIDE rows
  second. Coverage against the top-three trees is what makes a
  mitigation P0.
- The independence column is where reviewers catch waste. Do the
  substitution check yourself before submitting.
- The weighted-ordinal composite is not sacred. If the composite
  ranks a P0 as P1 and the reviewer's judgement disagrees, the
  disagreement is a prompt to fix the weights, not to override the
  score silently.
- Write the acceptance memo *last*. It is a summary; it should not
  drift from the scorecard.

## Acceptance criteria

A passing package:

- Scorecard has every row from the source columns (STRIDE +
  attack-tree cuts + obligation-derived controls) either included
  or explicitly excluded with rationale.
- Every scorecard row has every field populated.
- Roadmap tiers add up to a defensible eng-week total for the
  quarter.
- Acceptance memo fits on one page and has all four required
  bullets.
- The three sanity checks from chapter 06 are explicitly answered
  in the header.
- P0 tier passes all three sanity checks.

A failing package:

- Uses "impact × likelihood" as the sole ranking axis (ranks
  threats, not mitigations).
- Ships two P0 mitigations that substitute for each other.
- Names no owner on a P0.
- Skips the acceptance memo.
- Contains "future work" or "TBD" anywhere.

## Stretch goals

- Produce the quadrant plot (cost × coverage, coloured by
  detectability) as a Mermaid or Kroki-rendered diagram.
- Author a **quarterly re-score checklist** — the checklist a
  future you would run to keep the roadmap current: ATLAS matrix
  version diff, NIST edition diff, mitigation status refresh, new
  STRIDE row scan, new attack-tree candidate cuts. This feeds
  directly into mod-112.
- Sketch the **executive metrics package** the roadmap feeds —
  three-to-five slides that the CISO would take to the board. The
  slides quote the coverage-vs-gap numbers, the P0 completion
  progress, and the top-three residual risks. This is mod-112's
  eventual deliverable; you are drafting a preview.

## Do not

- Do not skip the memo. The unsigned roadmap is a wish list.
- Do not ship a scorecard whose P0s do not cut any top-three
  attack-tree root — the ranking is not defending the top threats.
- Do not ship a scorecard whose P0 total exceeds the quarter's
  capacity without an explicit degradation. That is a plan to
  miss.
- Do not commit a solution to any repository — solutions live in
  the paired solutions repo.
