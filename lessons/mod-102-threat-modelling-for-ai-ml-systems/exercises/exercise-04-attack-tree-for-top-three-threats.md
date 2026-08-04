# Exercise 04 — Attack Tree for the Top Three Threats

**Estimated effort:** ~3 hours
**Deliverable:** Three attack trees in a version-controllable text
format (Markdown outline, Mermaid, or attacktree DSL), each with
per-node ATLAS tag, NIST vocabulary, cost, probability,
detectability annotations; plus a candidate-cuts list per tree.
**Prerequisites:** Exercises 01, 02, and 03 complete. Chapter 05
read end-to-end.

---

## Objective

Select the **top three threats** from the exercise-03 IR-consumable
inventory by impact × likelihood, and author a full attack tree per
threat. Each tree traces the attacker's kill chain from initial
access through discovery / staging / execution to impact, in ATLAS-
tactic language, with cost / probability / detectability annotations
per node.

By the end of the exercise, you have the input chapter 06 needs to
rank mitigations by coverage of attack-tree paths.

## Problem statement

Same target system as exercises 01–03. You have the IR-consumable
inventory from exercise 03. You now:

1. Rank threats in that inventory by impact × likelihood.
2. Select the top three.
3. Author a full attack tree per selection.

## Requirements

### Section 1 — Top-three selection memo

A one-page justification of the top-three selection:

- The two axes (impact, likelihood) each ordinally scored 1–5,
  with the scoring rubric named. Impact should reference the
  asset's blast radius from exercise 01. Likelihood should
  reference the status block from exercise 03 (gap-status raises
  likelihood; live-preventive lowers it), the public-attack
  maturity (well-known → higher; academic-only → lower), and the
  external attack surface.
- The top ~8 candidates ranked, with brief rationale per row.
- The final top-three with a two-sentence justification per
  selection.
- **Ties**: break by preferring threats whose tree teaches the most
  (unfamiliar kill chains > well-understood ones), per chapter 05.

### Section 2 — Attack tree per top-three threat

Three trees. For each:

- **Root** — the top-level attacker goal, in one sentence.
- **Node structure** — AND / OR operators explicit. Get the
  operator right; see chapter 05 §"Choosing AND vs OR".
- **Node annotations** — every node carries the following fields:
  - `atlas_tactic` and `atlas_technique` — verify IDs at
    atlas.mitre.org (may be empty for design-flaw nodes and for
    nodes outside the ATLAS matrix; note that).
  - `nist_ai_100_2_capability_required` — the attacker capability
    the node presumes.
  - `cost_to_attacker` — ordinal (low / medium / high /
    infeasible-at-scale) with a one-line justification.
  - `probability` — ordinal (unlikely / plausible / likely /
    near-certain) given the *current* defensive posture.
  - `detectable` — yes / no / partial, with the required telemetry
    named if partial or yes.
- **Least-cost-path highlight** — mark the cheapest path from root
  to leaves. This is where the attacker actually goes; it is the
  path chapter 06 will most want to cut.
- **Format** — Markdown outline is fine; Mermaid is fine; whatever
  the *source* form, it must be diffable in git. Slide-only
  formats are unacceptable.

### Section 3 — Candidate-cuts list per tree

For each tree, list the candidate defensive cuts:

- **Node interdicted** — which node in the tree does the cut land
  on?
- **Cut type** — preventive (removes the node), detective (fires
  when the node is exercised), or both.
- **Paths cut** — how many root-to-impact paths does this cut
  remove? For AND-rooted trees, cutting any child of the root cuts
  all paths (100%); for OR-rooted sub-trees, cuts on a single
  child cut only that child's paths.
- **Source cross-reference** — the mitigation ID this cut
  corresponds to (or a proposed new mitigation ID), the STRIDE
  row IDs it addresses, and the OWASP / NIST / ATLAS obligations
  it discharges.

The candidate-cuts list is the **direct input to exercise 05**
(the mitigation prioritisation scorecard). Every cut you list here
becomes a row on the scorecard.

## Starter guidance

- The chapter-05 worked trees (tree 1 for LLM prompt-injection →
  excessive-agency and tree 2 for fraud model extraction) are your
  templates. Copy their shape.
- Author top-tree-first; do not fill in one tree completely before
  starting the second. The three trees have overlapping cuts
  (trust-level separation appears in multiple trees), and drafting
  in parallel surfaces the overlaps early.
- Do not spare the AND/OR operators. Get them right or the
  candidate-cuts list is wrong.
- The tree does not have to be exhaustive. It has to cover the
  **cheap paths the attacker will actually take** and the
  **paths detection can catch**. A tree that enumerates every
  theoretical path is a tree that will not fit on a slide and will
  not be maintained. Prefer depth on the cheap paths.
- Cross-reference across trees when a cut interdicts more than one
  tree — that lifts the cut's coverage score in exercise 05.

## Acceptance criteria

A passing set of three trees:

- Every tree traces from initial access (or the attacker's starting
  position) through the ATLAS-tactic chain to impact.
- Every internal node has an explicit AND / OR operator.
- Every node carries the full annotation set (ATLAS tag or
  explicit-none justification; NIST capability; cost; probability;
  detectability).
- Every tree has a highlighted least-cost path.
- Every tree has a candidate-cuts list of at least four cuts, each
  with paths-cut count and source cross-reference.
- The top-three selection memo defends the ranking against the
  alternatives, not just against nothing.

A failing set:

- Uses AND everywhere (or OR everywhere) without differentiation.
- Contains nodes with no annotations.
- Contains trees that stop at "obtain query access" and never trace
  to impact.
- Lacks the candidate-cuts list.
- Selects the top three by "gut feel" without a scoring rubric.

## Stretch goals

- Author a fourth tree for a threat that scored below the top three
  but shares many candidate cuts with the top three. Note how the
  overlap changes the exercise-05 ranking.
- Add cost-to-attacker in a quantitative unit (dollars, hours,
  queries) rather than an ordinal, for at least the top-three
  tree's least-cost path. This is what a formal quantitative-risk-
  analysis review will demand.
- Overlay a Kroki-renderable or Mermaid diagram of one of the
  trees, colouring detectable nodes green and undetectable nodes
  red — useful for the mod-112 board slide.

## Do not

- Do not skip the top-three selection memo. Chapter 06 depends on
  a defensible top-three ranking.
- Do not stop tree-authoring at a slide. The source form must be
  diffable.
- Do not commit a solution to any repository — solutions live in
  the paired solutions repo.
