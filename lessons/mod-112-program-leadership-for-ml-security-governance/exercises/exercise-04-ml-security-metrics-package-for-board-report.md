# Exercise 04 — ML-Security Metrics Package for the Board Report

**Estimated effort:** ~3 hours
**Deliverable:** A committed, machine-readable
ML-security metrics package covering all four families
in chapter 04 for one representative quarter against a
plausible or real portfolio, consisting of
(a) **signed metric-definition artefacts** — one per
family — that specify data sources, denominators,
inclusion criteria, severity mappings, SLA definitions,
and reproducibility; (b) a **reproducible data pipeline
or query set** that produces the numbers from the
sources of truth (SQL, KQL, SPL, Python — your choice),
with the sample inputs that drive the quarter's
numbers; (c) the **quarter's rendered package**
— vulnerability burn-down, ATLAS TTP coverage, IR
MTTD/MTTR, SLSA attainment — in the chapter-04 shape,
with trend series pulled across at least four quarters
of plausible data; (d) a **three-page executive
summary** against the chapter-04 structure (one page
summary + one page per family highlights + decision
asks); (e) a **methodology appendix** that documents
every change in definition across the trend window;
and (f) a **failure-mode self-audit** that checks the
package against the chapter-04 failure modes and
reports any defects.
**Prerequisites:** Chapter 04 read end-to-end.
Familiarity with mod-110 (SLSA) and mod-111 (SIEM
coverage, incident response). Access to (or a credible
model of) a findings-tracking system, a SIEM coverage
map, an incident-management system, and an
attestation / SBOM store. Comfort with trend-chart
authoring in a tool you own (Jupyter, Grafana,
spreadsheet — any works).

---

## Objective

Chapter 04's claim is that the metrics package is a
reproducible, versioned, honest artefact — not a
monthly colour-grading exercise. This exercise is where
you build the package end-to-end for one quarter.

By the end of this exercise you have:

- Four **signed definition artefacts** that fix the
  metric semantics across time.
- A **reproducible pipeline** that produces every
  number in the package.
- A **rendered package** that is the shape the head
  of AI governance consumes to produce the board
  slide.
- An **executive summary** that is scannable in five
  minutes.
- A **methodology appendix** that preserves
  trustworthiness of the trend.
- A **self-audit** that would catch the chapter-04
  failure modes before they land on a board slide.

You are **not** running the real quarterly for your
organisation here; you are producing the full package
against a plausible or real portfolio, in the shape
the real package must take.

---

## Problem statement

Pick a portfolio to measure. If you have one, use it;
if not, construct a plausible one with:

- 10–50 in-scope ML systems.
- A SIEM content pack with an ATLAS coverage map at
  some meaningful fraction (not 0 %, not 100 %).
- A findings-tracking system with critical / high /
  medium / low severities and an SLA policy you
  can state.
- An incident-management history over at least four
  quarters with at least a handful of AI-touching
  incidents.
- An attestation store with SLSA levels across the
  model portfolio.

Document the portfolio at the start of the
deliverables.

---

## Requirements

### Deliverable A — four signed definition artefacts

One per family. Each defines:

- The source of truth (specific system; one, not
  two).
- The queried population (denominator).
- Inclusion / exclusion criteria.
- The severity (or coverage, or SLSA) scale and the
  mapping from the source's native scale.
- The time boundary (period definition, "incident
  in Q3" meaning).
- Known caveats and biases.
- The signing identity and the version.
- The expected error bars or uncertainty acknowledged.

Each artefact is signed and dated. If a definition is
revised across quarters, the revision is a MAJOR
version bump and is reflected on the trend chart.

### Deliverable B — reproducible pipeline

The actual query / code / pipeline that produces the
numbers from the sources of truth. Deliverable
expectations:

- Each metric's query is in the repo.
- The pipeline runs end-to-end to produce the
  rendered package from the input data.
- Sample inputs are included so a reviewer re-runs
  and gets the same numbers.
- The pipeline writes a signed artefact (the
  rendered package) to a plausible evidence-store
  location.

If you have no real data, construct synthetic data
with properties that produce an interesting-shaped
package (not all green, not all red; a vulnerability-
closure trend worth narrating; a coverage trend worth
narrating; low-count MTTR for a severity worth
narrating; an SLSA distribution worth narrating).
Document the synthetic-data generator so a reviewer
can regenerate.

### Deliverable C — rendered package

The quarter's package in the chapter-04 shape:

- **Vulnerability burn-down**: by severity, with
  open-at-start / opened / closed / open-at-end,
  age bands, SLA-breach counts, close-time
  percentiles; trend over at least four quarters.
- **ATLAS TTP coverage**: by tactic, with totals /
  covered / partial / uncovered-accepted / uncovered-
  not-accepted; portfolio dimension; trend over at
  least four quarters.
- **IR MTTD / MTTR for AI incidents**: counts by
  severity, MTTD (then-current and retrospective
  with the gap), MTTR with the stage definitions
  (contained / eradicated / recovered); low-count-
  period discipline applied where N is small; trend
  on the N-sufficient series.
- **SLSA attainment**: distribution across the
  portfolio, exposure-weighted production coverage
  at L2 or above, excluded count and reason; trend.

Format: machine-readable YAML / JSON for the
numbers plus rendered PNG / SVG trend charts for
the executive summary.

### Deliverable D — executive summary (three pages)

- **Page 1** — four family readings, each a one-
  sentence interpretation + direction arrow +
  anomalies-this-quarter.
- **Page 2** — vulnerability burn-down + ATLAS
  coverage, each with their trend chart and 3-4
  bullets.
- **Page 3** — MTTD/MTTR + SLSA, each with their
  trend chart and 3-4 bullets; followed by a
  "decision asks" section (budget, portfolio
  priority, scope-change, acceptance of risk, etc.).

The summary is scannable in five minutes, defensible
against questions, and does not reduce the four
families to one green light.

### Deliverable E — methodology appendix

For each metric family, document every definition
change across the trend window:

- Date of change.
- What changed (criterion revised, scale remapped,
  denominator shifted).
- Why (reason for the change).
- Impact on the trend (if the change makes earlier
  quarters incomparable, show both the old-definition
  and new-definition reading for the overlap period).

If no definitions have changed, say so explicitly;
"no changes" is a positive statement, not an absence.

### Deliverable F — failure-mode self-audit

Walk through each chapter-04 failure mode and
answer, for your package: does it occur, and if so,
what did you do about it? The failure modes to
check:

- Vanity metrics on the executive summary (activity
  counts in place of coverage/outcome).
- Metrics without a denominator.
- Metrics without a signed definition artefact.
- One number per family on the summary.
- Metrics that cannot be audited (source cannot be
  reconstructed).
- Trend charts with scale manipulation.
- Low-N series reported as a mean rather than raw
  points.

Each answer is a specific pointer to the artefact
that mitigates it, or an explicit acknowledgement of
a residual defect.

---

## Starter guidance

- **Build the definition artefacts first.** The
  numbers follow from the definitions, not the
  other way round.
- **Choose one source of truth per metric and
  commit.** If you discover a reconciliation gap
  between two systems, treat it as a finding, not
  a chance to pick the number you prefer.
- **Trend windows need plausible histories.** A
  trend of "Q3 only" is not a trend. If you have
  no historical data, generate plausible
  synthetic history and document the generator.
- **Low-count MTTD/MTTR series are the honest
  case.** Many programmes have 1-2 Sev-1s a year;
  reporting a mean on an N of 1 is dishonest. The
  package shows the raw list and narrates.
- **The executive summary is the only part the
  board reads.** Three pages, scannable in five
  minutes. Everything else is the appendix the
  auditor will pull.
- **Methodology changes are visible, not hidden.**
  A metric redefinition that improved the number
  is called out explicitly.
- **Self-audit is self-honest.** The failure-mode
  check is for your benefit, not performative.

---

## Acceptance criteria

A passing package:

- Four signed definition artefacts, each with
  source-of-truth, denominator, scale, time
  boundary, caveats, signer.
- Reproducible pipeline that regenerates the
  numbers from the input data.
- Rendered package covering all four families with
  trend series ≥ four quarters, properly structured
  (not one number per family).
- Three-page executive summary with decision asks.
- Methodology appendix covering every definition
  change (or stating none).
- Failure-mode self-audit with specific pointers
  per failure mode.

A failing package:

- Metrics without a signed definition artefact.
- One-number-per-family executive summary.
- Low-N MTTR reported as a mean without the raw
  points.
- Trend chart with manipulated axes.
- No reproducibility pipeline (numbers from a
  spreadsheet with no source trail).
- Methodology appendix absent.

---

## Stretch goals

- **Automated pipeline.** The pipeline runs on a
  schedule, writes the signed artefact to a
  retention-controlled store, and notifies the
  head of AI governance's delegate when a new
  package is ready.
- **Per-system drill-down.** For each metric
  family, add a per-system view that the
  quarterly working session consumes (the board
  summary is portfolio; the working session is
  per-system).
- **Scenario sensitivity.** Pick one metric and
  show how the number moves under three
  alternative definitions. The result argues
  explicitly why you picked the one in the signed
  definition artefact.
- **Head-of-governance's downstream slide.**
  Produce the board slide the head of AI
  governance would publish from your package, and
  confirm the numbers are identical. Any
  discrepancy is an interface defect to fix.
- **Historical consistency check.** For a trend
  window that spans a methodology change, show
  both the restated and the as-published numbers,
  with a note.
- **Cost of coverage.** Append a cost series
  (engineer-weeks + compute) to the coverage %
  trend. Shows the board the cost shape of further
  coverage.

---

## Do not

- Do not use a vanity metric on the executive
  summary (training-counts, policy-counts, etc.).
- Do not blend severities in an MTTR mean.
- Do not report "trend improving" without the trend
  series.
- Do not shift a trend axis to make the trend look
  better.
- Do not deliver numbers whose source cannot be
  reconstructed.
- Do not commit the solution bundle to this repo.
  Solutions live in the paired `-solutions` repo.
