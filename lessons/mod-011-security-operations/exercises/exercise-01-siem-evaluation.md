# Exercise 01 — SIEM Evaluation

**Estimated time**: 2 hours
**Deliverable**: A 2–3 page decision document

---

## The assignment

Evaluate SIEM options for SmartRecs and recommend one.

## SmartRecs context

- 6 engineers; security engineer is the 6th (you).
- Single-cloud AWS today; may add a region in 12 months.
- ~30 GB/day of security-relevant log volume (audit chain,
  Falco, Hubble, k8s audit, CloudTrail, application audit).
- Annual budget for SIEM + tooling: ~$80k.
- Pursuing SOC 2 Type 2 — SIEM with retention is part of
  evidence.
- The team is already on Datadog for general observability.
- No 24/7 SOC; embedded on-call.
- Compliance: GDPR (EU customers), HIPAA (healthcare
  customer), potential SOC 2 in 90 days.

## What the evaluation must cover

1. **Selection criteria** with weights.
2. **Candidates** to evaluate (at least 4 — Elastic, Datadog
   Cloud SIEM, Sentinel, Wazuh; optionally Splunk for
   reference).
3. **Side-by-side comparison** on each criterion.
4. **Recommendation** with reasoning.
5. **Trade-offs accepted**.
6. **Migration considerations** if SmartRecs is currently
   doing security with ad-hoc tooling.
7. **Re-evaluation triggers**.

## Specific criteria to evaluate

- Cost (predictable, fits the budget).
- Time-to-value (setup effort, default rule library quality).
- Integration with the existing stack (Datadog, AWS,
  Kubernetes audit, Falco, Cilium).
- Sigma rule support (or equivalent format).
- Retention compatible with regulatory expectations.
- Operational cost (running it day-to-day).
- Compliance evidence quality (what the SIEM exports for
  auditors).
- Future-proofing (multi-cloud, scale).

## Format

```
# SIEM Evaluation: SmartRecs

## Audience (engineering + security leadership)

## TL;DR

## Selection criteria

| Criterion | Weight | Why |
|---|---|---|

## Candidates

### Elastic Security
- Pros
- Cons
- Cost estimate
- Integration effort

### Datadog Cloud SIEM
...

### Microsoft Sentinel
...

### Wazuh
...

(Optionally: Splunk for reference; usually rejected on cost.)

## Side-by-side

| Criterion | Elastic | Datadog | Sentinel | Wazuh |
|---|---|---|---|---|

## Recommendation

## Trade-offs accepted

## Migration plan
(High-level only.)

## Re-evaluation triggers
```

## Quality criteria

A passing evaluation:

- Picks **one SIEM** explicitly.
- Defends the choice against the obvious alternative.
- Acknowledges what's worse about the pick.
- Sequences the migration realistically (not "deploy in week
  1").
- Stays within the $80k budget.

A failing evaluation:

- "Splunk is best" without considering cost.
- "Open source is free" ignoring operational cost.
- No criteria weights — just pros / cons.
- Misses the existing Datadog ecosystem implication.

## Reflection questions

1. The team objects: "Why not just put everything in Datadog?"
   Defend or concede.
2. The CISO objects: "Wazuh is free; pick that." Defend or
   concede.
3. What would change if SmartRecs hit 100 engineers in 18
   months?
