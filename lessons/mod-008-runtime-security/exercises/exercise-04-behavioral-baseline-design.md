# Exercise 04 — Behavioral Baseline Design

**Estimated time**: 2 hours
**Deliverable**: A baseline design + alerting strategy

---

## The assignment

Design a behavioral-baseline detection capability for the
SmartRecs `model-serving` workload. Rules (Exercise 03) catch
known patterns. This exercise builds the *anomaly* layer.

## What the design must specify

### 1. Dimensions to baseline

At minimum:

- **Outbound destinations** (hostnames + ports) per deployment.
- **Request rate** (RPS per pod).
- **CPU utilization** distribution.
- **Memory utilization** distribution.
- **GPU utilization** (if applicable).
- **Process tree depth** (number of children typical for the
  pod).
- **Syscall frequency profile** (high-level — too detailed
  produces noise).
- **Network connection patterns** (count of unique destination
  IPs per minute).

For each dimension:
- Why it matters for ML threats.
- How it's measured (source).
- The baseline computation method (median + IQR, percentile,
  EMA).

### 2. Learning windows

- **Initial learning**: how long is the baseline-building
  window when a new deployment starts? (1 week is a common
  starting point.)
- **Re-learning trigger**: when does the baseline get
  recomputed (deployment change, periodic refresh, on
  request)?
- **Drift handling**: how do you detect that a baseline has
  drifted enough to need re-learning?

### 3. Alert thresholds

For each dimension:
- **Threshold method**: percentile-based, σ-based, fixed
  multiple.
- **Concrete threshold**: e.g., "alert at 3σ above baseline
  median for 5 consecutive minutes."
- **Confidence interval**: alerting on a single outlier
  produces noise; alerting on sustained deviation reduces it.

### 4. Cold-start handling

A new deployment has no baseline. Options:

- Use a **default baseline** for the workload class.
- Disable alerts during learning window.
- Use a **conservative bound** (e.g., 5σ) until a real
  baseline is built.

Each has trade-offs.

### 5. Cross-dimension correlation

Single-dimension anomalies are noisy. Cross-dimension
correlation increases signal:

- CPU + outbound destination anomaly together = stronger
  signal.
- Request rate + memory anomaly together = stronger signal.

Design at least three cross-dimension alert rules.

## Format

```
# Behavioral Baseline Design: model-serving

## Dimensions

| Dimension | Source | Why it matters | Baseline method |
|---|---|---|---|

## Learning windows

### Initial learning
### Re-learning triggers
### Drift detection

## Alert thresholds

| Dimension | Threshold | Confidence |
|---|---|---|

## Cold-start handling

(Strategy + rationale.)

## Cross-dimension correlations

### Correlation 1: ...
### Correlation 2: ...
### Correlation 3: ...

## Operational concerns

- Where the baselines are stored
- Re-learning compute cost
- Per-deployment vs. per-pod
- Audit-chain integration

## Comparison: this layer + Falco rules
(What this catches that Exercise 03's rules don't, and vice
versa.)
```

## Quality criteria

A passing design:

- At least 6 dimensions with specific baseline methods.
- Real thresholds (numbers, not "we'll tune later").
- Cold-start strategy that doesn't either spam alerts or hide
  real threats.
- Cross-dimension correlations that have plausible signal.

A failing design:

- "We'll detect anomalies" without specifying how.
- Single-dimension alerts only.
- No re-learning strategy.

## Reflection questions

1. Which dimension is most likely to drift over time and need
   continuous re-learning?
2. Which dimension is hardest to baseline because workloads
   vary too much pod-to-pod?
3. The team uses a commercial behavioral-analytics product
   (Sysdig). Which dimensions in your design would you stop
   computing in favor of the product, and which would you
   keep?
