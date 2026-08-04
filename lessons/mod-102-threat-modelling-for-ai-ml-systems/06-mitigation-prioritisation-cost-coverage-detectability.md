# Chapter 06 — Mitigation Prioritisation: Cost, Coverage, Detectability

> **Note on AI-assisted content.** Prioritisation is method, not
> truth. Numbers you assign to cost / coverage / detectability come
> from your organisation's real constraints, not from this chapter.
> The chapter installs the *shape* of a defensible ranking; the
> *values* are yours to justify.

---

## Why this chapter exists

Threat modelling that stops at "here are the threats" is not the
role's deliverable. The role owes a **defensible prioritised
roadmap** — one that a CISO can approve, a peer engineering leader
can plan against, an auditor can inspect, and a board can quote.

The temptation is to rank mitigations by "gut feel" or by whichever
row the loudest team escalated. Both fail on review. The chapter
installs a three-axis scoring shape that survives review because
each axis names a concrete quantity a reviewer can query.

The three axes:

- **Cost** — how much does the mitigation cost to build and run?
- **Coverage** — which STRIDE rows and which attack-tree paths does
  the mitigation cut?
- **Detectability** — does the mitigation leave an evidence trail
  when it triggers, so we can prove it worked and refine it over
  time?

The rule this chapter is trying to install:

> Every mitigation on the roadmap must have a defensible cost
> estimate, a defensible coverage claim traceable to specific
> STRIDE row IDs and attack-tree node IDs, and a defensible
> detectability answer. A mitigation you cannot rank on these
> three axes is not roadmap-ready.

---

## Where mitigations come from

The mitigation backlog is not invented in this chapter. It has
five sources, all built up in prior chapters and prior modules:

1. **Preventive controls from mod-101 chapter 01** — the
   preventive column of the OWASP ML / LLM Top 10 coverage matrix.
2. **Detective controls from mod-101 chapter 02** — the ATLAS-tagged
   Sigma / KQL / SPL detection content.
3. **Preventive / detective sketches from chapter 03** — attached to
   each STRIDE row.
4. **Candidate cuts from chapter 05 attack trees** — the specific
   node interdicts that break the least-cost path.
5. **Governance-derived controls from mod-101 chapter 04** — the
   EU AI Act Article 15 obligation resolves to a signed evaluation
   record; the ISO/IEC 42001 clauses resolve to management-system
   artifacts.

Every mitigation on the scorecard carries a **source ID** back to
one or more of the above. A mitigation without a source is a
mitigation nobody asked for.

---

## The scorecard row template

Every candidate mitigation acquires a row in the scorecard with:

| Field | Contents |
| --- | --- |
| **Mitigation ID** | Stable identifier, e.g. `MIT-LLM-TRUST-SEP-01`. |
| **Description** | One-sentence description of what the mitigation does. |
| **Source(s)** | Cross-reference to STRIDE row IDs, attack-tree node IDs, and framework obligations that motivate the mitigation. |
| **Class** | Preventive / detective / evidence (a mitigation can be more than one). |
| **Cost — engineering build** | Ordinal (S/M/L/XL) plus an eng-week point estimate. |
| **Cost — ongoing operational** | Ordinal (S/M/L/XL) plus a monthly-cost estimate. |
| **Cost — user-visible impact** | Latency added, capability removed, user friction introduced. |
| **Coverage — STRIDE rows** | Explicit list of STRIDE row IDs this mitigation addresses. |
| **Coverage — attack-tree cuts** | Explicit list of attack-tree node IDs from chapter 05 this mitigation cuts. |
| **Detectability** | Does the mitigation emit an evidence artifact when it triggers? (Preventive-only, preventive + detective, detective-only.) |
| **Independence** | Which other mitigations this one substitutes for, and which it stacks with. Two mitigations that cut the same set of paths are substitutes; two that cut disjoint sets stack. |
| **Score** | Composite score derived from the axes below. |
| **Priority tier** | P0 / P1 / P2 / P3, tied to the roadmap sequencing. |

The rest of the chapter defines each axis and shows how to
compose them into the score.

---

## Axis 1 — Cost

Cost breaks into three sub-axes; each ranks independently and is
scored ordinally (Small / Medium / Large / X-Large).

### Engineering-build cost

The person-weeks the owning team needs to build the mitigation to
production quality. Include:

- Detection-rule authoring + tuning + false-positive triage
  (detective mitigations).
- Preventive control design, implementation, and integration into
  the training / serving / ingest path (preventive mitigations).
- Documentation, on-call runbook, and evidence-artifact hook.
- Regression tests + release-gate policy update.

Skipping any of these produces underestimates.

Rules of thumb (illustrative; calibrate to your org):

- **S** — 1–2 eng-weeks. Typically a config change plus a rule.
- **M** — 3–8 eng-weeks. New service integration; new pipeline
  step; new detection with meaningful tuning.
- **L** — 9–20 eng-weeks. Cross-team platform work (DP-SGD
  integration into the training pipeline; adversarial-training
  hook into the standard training config).
- **XL** — 20+ eng-weeks. Multi-quarter work (rebuilding the
  training-eligible boundary; deploying SPIFFE across the platform;
  a full model-signing platform).

### Ongoing operational cost

The steady-state cost after ship:

- On-call load — how many false positives per week, how long each
  triage takes.
- Cloud / compute cost — extra compute for adversarial training,
  cost of an extra detection pipeline.
- Third-party spend — SaaS licence for a scanner, PII/PHI DLP
  vendor.
- Retraining cadence cost — DP-SGD trains slower and costs more
  per model version.

Rules of thumb:

- **S** — negligible ongoing cost.
- **M** — a few hours/week of on-call load or a few hundred dollars
  monthly.
- **L** — sustained ops load requiring a dedicated headcount slice
  or a substantive cloud line item.
- **XL** — headcount + significant infra cost that shows up on the
  BU budget.

### User-visible cost

The user-visible impact:

- Latency added — for real-time surfaces, milliseconds matter.
- Capability removed — score-truncation to top-1 changes the
  product's API contract.
- Friction introduced — HITL confirmation on a transfer adds a step.

Rules of thumb:

- **S** — imperceptible.
- **M** — a measurable degradation; requires a product-side
  conversation.
- **L** — a capability change; requires a product-side approval.
- **XL** — a product-strategy conversation.

The three sub-axes combine into a Cost tier by taking the *maximum*
— a mitigation with S engineering, S ops, but L user-visible cost
is a **L** cost overall, because the L axis dominates approval.

---

## Axis 2 — Coverage

Coverage is *paths cut* — not a count of threats "addressed". The
distinction matters:

- A mitigation that addresses one STRIDE row but cuts *all four
  paths* to a high-impact tree root is high coverage.
- A mitigation that addresses ten low-severity STRIDE rows but
  cuts *no path* to a high-impact tree root is low coverage.

Compute coverage against three inputs:

- **STRIDE rows covered.** Count of STRIDE row IDs on which this
  mitigation lands as preventive or detective. Weight each by the
  row's impact rank (from chapter 05's top-three selection or the
  fuller inventory rank).
- **Attack-tree cuts.** Count of attack-tree paths this mitigation
  removes for each of the top-three trees. A mitigation that cuts
  the root AND is 100% coverage of that tree; a mitigation that
  cuts one OR child of an AND is 0% coverage of the tree (the
  attacker takes another OR child).
- **Independence** — how much unique coverage does this mitigation
  add on top of already-planned mitigations? A mitigation that
  substitutes for a P0 mitigation adds nothing.

Score coverage ordinally:

- **High** — cuts ≥1 top-three attack-tree root AND ≥50% of the
  paths on that tree, OR addresses ≥5 high-impact STRIDE rows.
- **Medium** — cuts some paths but not root; addresses 2–4 STRIDE
  rows.
- **Low** — cuts individual leaf paths, addresses 1 row.
- **Zero** — no net coverage after subtracting already-planned
  mitigations.

Coverage is where the attack trees from chapter 05 earn their
keep. A mitigation ranking that cannot point to specific tree nodes
is a ranking that will lose on review.

---

## Axis 3 — Detectability

Detectability answers: *when this mitigation triggers, do we
get an evidence artifact?* Three grades:

- **Preventive + detective (P+D).** The mitigation is preventive
  and *also* fires a detectable event when a would-be attacker
  encounters it. Example: HITL confirmation on a transfer both
  prevents the transfer and generates a signed HITL-denial event.
  Best grade.
- **Preventive only (P).** The mitigation blocks the attack
  silently. Example: score-truncation to top-1 removes extraction
  richness but does not emit an event per attempted extraction
  query. Middle grade.
- **Detective only (D).** The mitigation notices the attack after
  the fact and produces a signal. Example: query-pattern
  extraction detector alerts on suspicious query streams.
  Lowest grade *if not paired with a preventive*, because a
  detective control with no preventive is a promise the SOC will
  respond in time.

Prefer preventive + detective. Where a mitigation is preventive
only, add a paired detective to catch bypass. Where a mitigation is
detective only, add a paired preventive or ensure the SOC's
response time is inside the attack's realisation window.

Detectability also decides evidence at admission time — a
preventive-only mitigation with no evidence artifact cannot be
enforced at scale by an admission policy (the release gate has
nothing to inspect).

---

## Composing the score

A defensible composite score can take several shapes; two work
well in practice.

### Shape A — Weighted ordinal

Convert each axis to a numeric ordinal (S=1, M=2, L=3, XL=4;
Zero=0, Low=1, Medium=2, High=3; P+D=3, P=2, D=1). Weighted
composite:

```
Score = w_coverage * Coverage
      + w_detectability * Detectability
      - w_cost * CostTier
```

Reasonable starting weights for a security-engineering roadmap:

- `w_coverage = 3` — coverage dominates because a mitigation that
  cuts no path is worthless regardless of the other axes.
- `w_detectability = 1` — matters, but the coverage decision
  precedes it.
- `w_cost = 2` — cost matters because engineering capacity is
  finite; a P0 mitigation still has to fit the quarter.

Sort candidates by descending Score. Break ties by preferring
mitigations with existing evidence artifacts (fastest to enforce)
and mitigations with dependency-reducing effects (unblock
downstream work).

### Shape B — Two-axis quadrant + detectability annotation

Plot cost on one axis, coverage on the other, colour by
detectability. Mitigations in the top-left quadrant (high coverage
/ low cost) are P0. Bottom-right (low coverage / high cost) are
P3 or off-list.

The quadrant plot is often more persuasive in a design review
than a numeric score; a scored table underneath keeps the ranking
auditable.

Use both. The plot is for the conversation; the table is for the
record.

### Sanity checks before you defend the ranking

Before shipping the ranking, run three checks:

1. **Every P0 mitigation cuts ≥1 top-three attack-tree root.**
   If not, the ranking is not defending the top threats.
2. **Every P0 mitigation has a named owner and a fit in the
   quarter.** A P0 without an owner is a P0 nobody will do.
3. **No two P0 mitigations are substitutes for each other.**
   Substitutes waste capacity; move the weaker one to P1 with a
   note that it is a fallback.

If any check fails, re-rank before shipping.

---

## A worked scorecard — fintech reference system, first six rows

Illustrative — the numbers reflect the reference system in mod-101
exercise 01 and chapter 05; calibrate to your own before quoting.

| MIT ID | Description | Source | Class | Cost | Coverage | Detect. | Score | Tier |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| MIT-LLM-TRUST-SEP-01 | Separate trust levels of every context source in prompt composition | Chapter 03 THREAT-PT-T-1; Chapter 05 tree 1 A2a | Preventive | M (build) / S (ops) / S (user) | High — cuts tree 1 root, 6 STRIDE rows | P | 3*3 + 1*2 − 2*2 = 7 | P0 |
| MIT-LLM-TOOL-ACL-01 | Bind tool ACLs to authenticated user session, not agent service account | Chapter 03 THREAT-PT-S-2 / E-1; Chapter 05 tree 1 A4a | Preventive + Detective (ACL denial event) | M / S / S | High — cuts tree 1 root; 4 STRIDE rows | P+D | 3*3 + 1*3 − 2*2 = 8 | P0 |
| MIT-ML-SCORE-TRUNC-01 | Truncate fraud-v42 output to top-1 for score-access non-allow-listed tenants | Mod-101 Ch01 ML05; Chapter 03 THREAT-DS-I-1; Chapter 05 tree 2 B3a | Preventive | S / S / M (product contract change) | High — cuts tree 2 root; 3 STRIDE rows | P | 3*3 + 1*2 − 2*2 = 7 | P0 |
| MIT-ML-EXTRACT-DETECT-01 | Per-tenant query-embedding coverage detector, ATLAS-tagged Sigma rule | Mod-101 Ch02 Sigma stub; Chapter 03 THREAT-DS-I-1; Chapter 05 tree 2 B2a | Detective | M / M (FP tuning) / S | Medium — cuts tree 2 leaf paths, not root | D | 3*2 + 1*1 − 2*2 = 3 | P1 (pair with MIT-ML-SCORE-TRUNC-01) |
| MIT-ML-DP-SGD-01 | Retrain fraud-v42 with DP-SGD (Opacus), ε=8, δ=1e-5, published in model card | Mod-101 Ch01 ML03/ML04; Chapter 03 THREAT-TD-I-2/3 | Preventive | L / L (2× training cost) / M (accuracy delta) | Medium — cuts inversion + membership inference paths | P | 3*2 + 1*2 − 2*3 = 2 | P2 (defer until inversion detection shows real signal) |
| MIT-RAG-INGEST-ALLOWLIST-01 | Retrieval source allow-list restricting customer-support-emails corpus to signed sources | Chapter 03 THREAT-EI-T-1; Chapter 05 tree 1 A1a | Preventive + Detective | S / S / S | High — cuts tree 1 A1a leaf; 3 STRIDE rows | P+D | 3*3 + 1*3 − 2*1 = 10 | P0 |

Reading the scorecard:

- Four **P0** mitigations. Each cuts a top-three tree root or is a
  necessary complement.
- The extraction detector (MIT-ML-EXTRACT-DETECT-01) is P1 because
  its role is to *catch bypass* of the P0 score-truncation, not to
  stand alone. Pairing lifts detectability of the preventive.
- DP-SGD (MIT-ML-DP-SGD-01) is P2 because at fintech tier the
  inversion threat is currently gap-status but the cost is
  substantial; the sequencing plan escalates it if the detection
  content in P1 fires signal.
- No two P0 mitigations substitute for each other. Coverage stacks.

That is a defensible ranking. Every row can be defended against a
specific STRIDE ID and attack-tree node, and the composite score is
reproducible.

---

## Producing the roadmap

The scorecard sorts into P0/P1/P2/P3 tiers. The roadmap adds
sequencing:

- **This quarter (P0)** — every P0, with named owner and eng-week
  estimate. Add up the totals; if they exceed capacity, degrade
  the weakest to P1 with an explicit note.
- **Next quarter (P1)** — the pairings and secondary mitigations.
- **Backlog (P2)** — items to escalate on signal (e.g., DP-SGD if
  inversion detector fires).
- **Not planned (P3 / off-list)** — with the rationale so future-you
  does not re-open the debate.

Every quarter, re-score. Threats move, framework versions update
(ATLAS revises, OWASP LLM has annual releases), and the coverage
math shifts. Chapter 04's coverage-vs-gap report is the input to
the re-score.

---

## Guardrails against common failures

- **Do not rank on "risk score = likelihood × impact" alone.** That
  ranks *threats*, not *mitigations*. A high-risk threat with no
  affordable mitigation still parks on the accepted-risk register;
  a low-risk threat with a cheap high-coverage mitigation ships now.
- **Do not skip the substitution check.** Two mitigations that cut
  the same set of paths are substitutes; picking both wastes
  capacity.
- **Do not accept "we already have some of this" without a
  measurement.** If you cannot point to the STRIDE rows currently
  covered and the paths currently cut, "some of" is unquantified.
- **Do not mistake detectability for coverage.** A detector adds
  detectability, not coverage; the coverage is the interdicted path
  count, not the alert.
- **Do not defer signing the roadmap.** The roadmap that ships to
  the CISO / peer engineering leader / product owner and is
  countersigned by them is the roadmap that actually happens. An
  unsigned roadmap is a wish list.

---

## The output artifact this chapter produces

By the end of this chapter and exercise 05, for the target system:

- The **mitigation scorecard** — one row per candidate mitigation
  with all row-template fields filled, sorted by composite score.
- The **prioritised roadmap** — P0/P1/P2/P3 tiers with owner,
  eng-week estimate, and quarter placement.
- The **acceptance memo** — one page, addressed to the CISO or
  security-engineering leader, that names the top three threats
  from chapter 05, names the P0 mitigations, defends the
  sequencing, and requests sign-off.

The acceptance memo is the artifact that closes the module. Once
signed, the roadmap enters the program-leadership workstream
mod-112 maintains.

---

## The mistakes this chapter is trying to prevent

- **Ranking by intuition without an axis.** Every rank must be
  defensible against cost, coverage, and detectability.
- **Skipping the attack-tree traceback.** Coverage claims that
  cannot be traced to specific tree node IDs are not defensible.
- **Weighing all axes equally.** Coverage dominates; cost gates
  capacity; detectability differentiates. The weights encode that.
- **Producing a scorecard nobody signs.** The roadmap that gets
  countersigned by the owning engineering leader is the roadmap
  that ships.
- **Filing the roadmap and never re-scoring.** The frameworks
  evolve, the threats evolve, and the coverage math shifts. Re-
  score quarterly.

---

## Summary

- Rank mitigations on three axes: cost (engineering build + ongoing
  ops + user-visible impact), coverage (STRIDE rows + attack-tree
  cuts, with substitution accounted for), and detectability
  (preventive + detective is best; detective-only requires a paired
  preventive).
- Compose the axes into a composite score, or plot as a cost /
  coverage quadrant coloured by detectability. Use both — the plot
  for the conversation, the table for the record.
- P0 mitigations each cut a top-three attack-tree root; no two P0s
  are substitutes; each has an owner and a quarter fit.
- Close the module with a signed acceptance memo — the
  countersigned roadmap enters mod-112's program-leadership
  workstream.
- Re-score quarterly. ATLAS, NIST AI 100-2, and the threat surface
  all move; the roadmap must move with them.
