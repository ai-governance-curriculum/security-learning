# Chapter 04 — The ML-Security Metrics Package

> **Note on AI-assisted content.** Metric names from
> industry (MTTD, MTTR, SLSA levels, ATLAS coverage) are
> standard, but the thresholds, bands, and target values
> in this chapter are illustrative only. Verify SLSA
> level definitions, ATLAS technique set, and incident-
> metric methodology against the primary sources cited
> in [`resources.md`](./resources.md). Where this
> chapter uses example numbers (coverage percentages,
> MTTR targets), they are *for shape*, not benchmarks to
> inherit.

---

## Why this chapter exists

Metrics are how the ML-security programme reports up.
The head-of-governance (level 60) produces a board-
level AI report every quarter; the ML-security
programme-lead produces the security *section* of that
report. The section exists so the board can answer
three questions:

1. **Is ML-security getting better or worse?** (Trend.)
2. **Are the known risks being closed on a credible
   timeline?** (Burn-down.)
3. **Would we see it if it happened?** (Detection
   posture.)

The failure mode this chapter is written against:

> The quarterly board deck has an "AI security" slide
> with a green traffic-light and the words "Coverage
> improving across the portfolio". No underlying
> metric is defined; no cumulative chart exists; the
> traffic-light moves on vibes. Six months later an
> incident lands in a system that was "green". The
> board asks "what changed?" and the honest answer is
> "nothing — we never measured it".

The metrics package is a defined, versioned,
reproducible set of measurements that produces the
same number from the same inputs on the same date.
Four metric families cover the objective: vulnerability
burn-down, ATLAS TTP coverage, IR MTTD/MTTR for AI
incidents, and SLSA attainment across the model
portfolio. Each family has a definition, a source of
truth, a cadence, and a published trend.

You leave this chapter able to:

- Define each of the four metric families precisely
  enough that two different people run the same query
  and get the same number.
- Produce the metrics package in a shape that feeds
  the head-of-governance's quarterly board report.
- Avoid the standard failure modes: vanity metrics,
  moving-goalposts, metrics without a source of truth,
  metrics without a trend.

---

## Rules that apply to every metric

Before the four families, a shared discipline:

- **One source of truth per metric.** The number is
  pulled from one system (SIEM, control library,
  model registry, SBOM store). A second system that
  shows a different number is a reconciliation bug,
  not a secondary metric.
- **Definitions in a signed artefact.** Each metric
  has a signed definition document: the SQL / KQL /
  SPL / whatever query, the data sources, the
  denominator population, the inclusion criteria, the
  known caveats. The definition is versioned; a
  metric redefined mid-year is clearly flagged on the
  trend line.
- **Trend over snapshot.** A quarter's absolute number
  is only useful alongside the last several quarters.
  Every metric lands on the board report as a trend,
  not a single reading.
- **Denominator discipline.** "Coverage %" needs a
  denominator; "number of models" needs a definition
  of "model"; "vulnerabilities" need a severity
  threshold. A metric whose denominator can shift
  without acknowledgement is a lever for making the
  trend look good.
- **Reproducibility.** The metric's artefact is
  signed, dated, and reproducible. "The script was on
  the person's laptop" is a reproducibility failure.

---

## Family 1 — Vulnerability burn-down

### What it measures

The population of known security vulnerabilities and
findings against the ML portfolio, by severity, with
the age and remediation state of each. The question:
*are we closing findings on a credible timeline?*

### What counts as a vulnerability or finding

- **CVE-level vulnerabilities** in in-force model
  dependencies (SBOM / ML-BOM; mod-110) at severity
  critical / high.
- **ATLAS-mapped findings** from the engagement
  portfolio (chapter 02 top-N current-posture
  ratings of "uncovered" or "partial" against a
  threat the engagement accepted).
- **Audit findings** from internal audit or an
  external assessor against the AI-security control
  library.
- **Red-team findings** from mod-106 / mod-107
  chapter 04 that resulted in an actionable finding
  (not every red-team interesting result is a finding;
  a finding is one that an owner has accepted into
  the remediation queue).
- **Governance-exception findings** — a release-gate
  override granted with an expiry date (chapter 02);
  the expiry is the SLA for closure.

### Severity bands

A single severity scale across the sources, mapped
from each source's native scale:

- **Critical.** Exploitable without privilege; impact
  spans multiple tenants or data classes; or an EU AI
  Act Article 15 implication for a high-risk system.
- **High.** Exploitable with low privilege; impact
  within one system; detection in place but
  remediation incomplete.
- **Medium.** Exploitable with existing partial
  mitigation; needs closure but not within the next
  release.
- **Low.** Hardening finding; closed on normal cadence.

The mapping from each source's scale (CVSS, red-team
scale, auditor's scale) is in the metric's definition
document; it is not re-decided each quarter.

### The burn-down

For each severity, three series:

- **Open at start of period.**
- **Opened during period.**
- **Closed during period.**

Open at end-of-period = open at start + opened −
closed. A visible divergence (opened >> closed over
multiple quarters) is the real signal; a flat total
can hide "we are opening and closing at the same rate
without reducing debt".

Age bands on the open population:

- `0-30d`, `31-90d`, `91-180d`, `181-365d`, `>365d`.

Each severity has an SLA (critical close < 7 d, high
close < 30 d, medium close < 90 d, low close < 180 d
is one shape; your org's SLA may differ). The metric
reports **SLA-breach count** per severity: open items
over age — the critical that is 45 days old is a
louder number than the 70 medium items.

### Example shape

```yaml
metric: vulnerability_burn_down
period: 2025-Q3
source_of_truth:
  - findings_db
  - sbom_store
  - release_gate_overrides
definition_version: v2.1
by_severity:
  critical:
    open_start: 3
    opened: 5
    closed: 7
    open_end: 1
    sla_breaches:
      "7-14d": 0
      ">14d": 0
    close_time_p50_days: 4
    close_time_p90_days: 6
  high:
    open_start: 18
    opened: 22
    closed: 20
    open_end: 20
    sla_breaches:
      "31-60d": 3
      ">60d": 1
    close_time_p50_days: 21
    close_time_p90_days: 42
  # ...
notes:
  - "Includes release-gate overrides as open findings until expiry."
```

### Common failure modes

- Reclassification quietly reduces the critical count.
  Any severity reclassification lands as a signed
  record and is called out on the trend.
- Findings "closed" by being folded into a larger
  tracking item without actual remediation.
- A denominator that grows (more models in scope) but
  the trend chart still shows absolute numbers; split
  into absolute and per-model-in-scope.

---

## Family 2 — Coverage of ATLAS TTPs

### What it measures

For each ATLAS tactic and technique in the matrix,
whether the organisation has detection, prevention, or
documented acceptance against it, across the portfolio
of in-scope ML systems. The question: *would we see it
if it happened?*

### The coverage map

The coverage artefact (mod-111 chapter 01) is the
source of truth. For each technique:

- **Covered** — at least one in-force detection rule
  or preventive control, in paging mode (or policy-
  as-code hard-block), binding to a telemetry stream
  that is live.
- **Partial** — rule exists in log-only mode, or
  preventive control exists but not on all in-scope
  systems, or the required telemetry is partial.
- **Uncovered — accepted** — explicit governance
  decision not to cover (chapter 03 decision record
  with expiry).
- **Uncovered — not accepted** — gap; must appear in
  the burn-down.

Coverage % is computed per *tactic* (not just one
overall number). A programme at 90 % Collection
coverage and 10 % Resource-Development coverage is a
very different programme from one at 50/50; a single
"coverage %" would hide that.

### Portfolio dimension

A technique is "covered" at the portfolio level only
if the rule applies to every in-scope system it is
relevant to. "Covered for the ops-assistant but not
for the recommender" is a partial.

Per-system coverage is a secondary breakdown. The
board sees portfolio; the quarterly working session
sees per-system.

### Example shape

```yaml
metric: atlas_coverage
period: 2025-Q3
source_of_truth: siem_coverage_map
definition_version: v1.4
portfolio:
  in_scope_systems: 14
  in_scope_models: 32
by_tactic:
  Reconnaissance:
    techniques_total: 6
    covered: 4
    partial: 1
    uncovered_accepted: 1
    uncovered_not_accepted: 0
    coverage_pct: 66.7
  Collection:
    techniques_total: 7
    covered: 6
    partial: 1
    uncovered_accepted: 0
    uncovered_not_accepted: 0
    coverage_pct: 85.7
  # ...
trend:
  - period: 2024-Q4; portfolio_coverage_pct: 42.1
  - period: 2025-Q1; portfolio_coverage_pct: 55.8
  - period: 2025-Q2; portfolio_coverage_pct: 61.0
  - period: 2025-Q3; portfolio_coverage_pct: 68.4
```

### Common failure modes

- A "covered" count that includes rules in log-only
  mode (not covered; partial).
- A "covered" count that includes rules against
  telemetry that does not exist in production.
- Portfolio coverage reported as the average of per-
  system coverage, which hides the system in which
  nothing is covered.
- Matrix evolution not reconciled. New ATLAS
  techniques appear; the denominator grew; the trend
  looks like a drop. Call out matrix-version in the
  definition and show the "same-denominator" trend
  for comparison.

---

## Family 3 — IR MTTD / MTTR for AI incidents

### What it measures

For incidents that touched an AI/ML system, the time
from the earliest objective signal to detection, and
from detection to remediation. The question: *when
something happened, how long did we take?*

### Definitions

- **AI incident.** An incident on the mod-111 chapter
  04 severity ladder whose root cause involves an
  ML/AI asset — model, training data, inference
  endpoint, agent tool, retrieval store, model
  registry. Incidents that merely occurred inside the
  ML namespace but have classical root cause (K8s
  misconfiguration, VPN compromise) are excluded;
  mod-111 chapter 04 defines the boundary.
- **MTTD (Mean Time To Detect).** From the earliest
  objective signal in telemetry (not the earliest
  retrospectively-identified signal; the earliest
  signal that *could have been detected* under the
  then-current detection content) to the paging
  event. In practice both are reported — the
  then-current MTTD and the retrospective MTTD —
  because the gap between them is the improvement
  signal for detection content.
- **MTTR (Mean Time To Remediate / Respond).** From
  paging to the end of the primary remediation
  action (not the end of all follow-up). The
  definition's cutoff is important: "contained",
  "eradicated", "recovered" each have different
  stopwatches and the metric names which.
- **Severity scoping.** Report MTTD/MTTR by severity
  band from the ladder, not as one blended number.
  Mixing a Sev-1 MTTR of hours with a Sev-4 MTTR of
  weeks is meaningless.

### Reporting shape

```yaml
metric: ai_incident_response_times
period: 2025-Q3
source_of_truth: incident_management_system
definition_version: v3.0
incidents_count:
  sev1: 1
  sev2: 3
  sev3: 7
mttd:
  sev1: 42_minutes
  sev2_median: 2.8_hours
  sev2_p90: 11_hours
  sev3_median: 1.2_days
retrospective_mttd_gap:
  sev1: 0_minutes       # the earliest objective signal and the pager fired together
  sev2_median: 3.1_hours
  # the gap between "the signal existed in telemetry"
  # and "the detection rule caught it" — our detection improvement signal
mttr:
  stage_definition:
    contained: pager_to_blast_radius_bounded
    eradicated: contained_to_root_cause_removed
    recovered: eradicated_to_normal_operation
  sev1_contained: 1.4_hours
  sev1_eradicated: 9.2_hours
  sev1_recovered: 2.3_days
  sev2_median_contained: 4.6_hours
  sev2_median_eradicated: 1.1_days
trend:
  mttd_sev2_median:
    - 2024-Q4: 6.4_hours
    - 2025-Q1: 4.8_hours
    - 2025-Q2: 3.3_hours
    - 2025-Q3: 2.8_hours
```

### Low-count-period discipline

Many AI programmes have one or two Sev-1s a year.
Reporting an "MTTD improved from 2 h to 90 min"
based on an N of 1 is noise. For low-count severity
bands:

- Report the raw list of incidents with their
  individual times, not a mean.
- Report the trend only when N ≥ a defined floor
  (3 is a reasonable floor for medians, more for
  means).
- Narrate the one Sev-1 with an incident retrospective
  reference; the board wants the story, not a
  spuriously-precise mean.

### Common failure modes

- The MTTR clock stopping at "incident closed" when
  "closed" is a workflow-system state untethered
  from any technical fact.
- The MTTD clock starting at the pager (missing the
  "signal existed earlier" story).
- Mixing severities. A Sev-4 MTTR of 2 weeks and a
  Sev-1 MTTR of 2 hours blended into a mean MTTR of
  1 week is nonsense.
- The *retrospective* MTTD not reported, which hides
  the detection-content improvement opportunity.

---

## Family 4 — SLSA attainment across the model portfolio

### What it measures

For each in-scope model, the SLSA (Supply-chain Levels
for Software Artefacts, as adapted for models in
mod-110 chapter 01) level attained for its *build*,
its *source*, and its *dependencies*. The question:
*could we trust the provenance of what we are
serving?*

### Levels (abbreviated, verify against mod-110)

- **SLSA L0** — no attestation.
- **SLSA L1** — build attestation exists.
- **SLSA L2** — build attestation signed by a trusted
  builder; source identified.
- **SLSA L3** — builder isolated; attestation
  non-forgeable; provenance includes complete inputs.
- **SLSA L4** — hermetic, reproducible build; two-
  party review. (Rare for model artefacts today; may
  not apply.)

Each level definition is verified against the current
SLSA specification; the metric definition pins the
spec version.

### Portfolio distribution

```yaml
metric: slsa_attainment
period: 2025-Q3
source_of_truth: attestation_store
definition_version: v1.3
spec_version: slsa_v1.0
in_scope_models: 32
distribution:
  L0: 2
  L1: 6
  L2: 18
  L3: 6
  L4: 0
weighted_portfolio:
  # weighted by production exposure — a model serving
  # 10m req/day counts more than a research model.
  production_exposure_L2_or_above_pct: 94
excluded:
  # third-party-hosted (API-only) models where the
  # organisation cannot attain SLSA on the model build
  # itself; attainment is on the client wrapper only.
  count: 4
  reason: vendor_hosted_api_only
trend:
  l2_or_above_pct:
    - 2024-Q4: 48
    - 2025-Q1: 61
    - 2025-Q2: 74
    - 2025-Q3: 81
```

### Target-setting discipline

A target of "100 % L3" is almost always a vanity
target that no reasonable programme hits. A target
of "100 % L2 or above for production-exposed models;
50 % L3 for the top-decile-exposure models by end of
year" is a target an engineering plan can bind to.

### Common failure modes

- Counting SLSA-L2 for a model whose attestation is
  valid but whose signing key is custodied by a
  single person's laptop (fails the "non-forgeable"
  spirit of the level).
- Portfolio counts dominated by low-exposure research
  models; add the production-exposure-weighted view.
- Vendor-hosted models silently excluded without
  acknowledgement, giving a flattering "portfolio
  coverage" number. Report excluded count and reason.

---

## The quarterly metrics package

What the ML-security programme-lead delivers each
quarter to the head of AI governance:

- **Executive summary** (one page). The four family-
  level readings, each with a one-sentence
  interpretation and a direction arrow against last
  quarter.
- **Per-family section** (one page each). The
  structured artefact above, trend chart, top
  movements, interpretations.
- **Decision requests** (one page). Any decision the
  programme-lead is asking the head of AI governance
  (or the board, via the head of AI governance) to
  make — budget asks, portfolio-level acceptance of
  risk, scope changes.
- **Methodology appendix** (as needed). Pointers to
  the signed definition documents for each metric.
  The board does not read this; the auditor does.

The package itself is a signed artefact in the
evidence store with the usual provenance record
(chapter 01). The head of AI governance produces the
board-level report *from* this package; the package
is not the board report.

---

## Standard failure modes

- **Vanity metrics.** "Number of trainings
  conducted", "number of policies published", counts
  of activity rather than counts of coverage or
  outcome. These do not belong on the board report.
- **Metrics without a denominator.** "20 findings
  closed" is meaningless without "out of how many
  open at start".
- **Metrics without a definition artefact.** Two
  quarters later nobody remembers how the number was
  computed; a redefinition masquerades as improvement.
- **One number per family.** Each family needs a
  multi-dimensional view (by severity, by tactic, by
  severity-band, by level). Compressing to one
  number loses the signal.
- **Metrics that cannot be audited.** A number whose
  source cannot be reconstructed in an audit is
  dead on arrival.
- **Trend charts that quietly change scale.** The
  y-axis zero and the methodology are fixed; a
  shifted axis to make a trend look better is
  dishonest.
- **The level 60 report rewrites the numbers.** The
  head of AI governance translates and summarises;
  they do not change the number. If the package's
  number disagrees with the board slide, the package
  wins and the slide is corrected.

---

## Summary

- The ML-security metrics package feeds the head-of-
  governance's board-level AI report with four
  defined, versioned, reproducible families:
  vulnerability burn-down, ATLAS TTP coverage, IR
  MTTD/MTTR for AI incidents, SLSA attainment across
  the model portfolio.
- Every metric has one source of truth, a signed
  definition artefact, a denominator, a reported
  trend, and reproducibility.
- Each family has a shape — burn-down by severity
  with age bands; coverage by tactic with portfolio
  dimension; MTTD/MTTR by severity with retrospective
  MTTD gap; SLSA distribution with production-
  exposure weighting.
- The package is a signed artefact in the evidence
  store; the head of AI governance produces the
  board slide *from* it, without rewriting the
  numbers.
- The failure modes are vanity metrics, missing
  denominators, undefined computations, blended-
  severity means, dishonest axes, and compressing
  multidimensional posture into one green light.
