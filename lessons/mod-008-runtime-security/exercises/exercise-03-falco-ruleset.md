# Exercise 03 — Falco Ruleset

**Estimated time**: 2–3 hours
**Deliverable**: 8+ ML-specific Falco rules + a tuning plan

---

## The assignment

Author a Falco ruleset for SmartRecs that catches
ML-platform-specific threats. The default Falco ruleset is the
baseline; this exercise focuses on the rules **specific to ML
operations**.

## Required rules (minimum 8)

Cover, at minimum:

1. **Model file tampering** — write to model directory by a
   process not in the loader allowlist.
2. **Training-job egress anomaly** — connection from a
   training pod to a destination not in the allow-list.
3. **Reverse shell in production** — shell process
   (`bash`, `sh`, `python -i`) in a production serving
   container.
4. **Privileged container in production namespace** — a
   privileged container admitted that should have been
   blocked.
5. **Cloud metadata access** — outbound to
   `169.254.169.254` from any non-system pod.
6. **`kubectl exec` into production serving** — interactive
   exec on a production pod.
7. **GPU misuse pattern** — sustained 100% GPU utilization on
   a pod whose schedule doesn't expect it (e.g., during
   non-training windows).
8. **Notebook outbound to non-allowlisted destination** —
   egress beyond the internal mirror + sample-data buckets.

Optionally:

9. **Container escape attempts** — `setns`, `unshare`,
   `nsenter`, mount-namespace manipulation.
10. **Sensitive file access** — reads of `/etc/shadow`,
    `/proc/.../environ` of other processes, etc.

## For each rule

Provide:

- The rule YAML (or pseudo-YAML).
- The condition predicates.
- The output template.
- Priority.
- Tags (including MITRE ATLAS or ATT&CK tag where
  applicable).
- Expected false-positive scenarios.
- Triage steps.

## Tuning plan

For each rule, propose:

- The expected baseline alert volume (per day).
- Tuning levers (excluded image patterns, time windows,
  allowed processes).
- The action-vs-noise calibration: at what alert frequency does
  this become noise?

## Format

```
# SmartRecs Falco Ruleset

## Rule index

| ID | Rule | Priority | Tags |
|---|---|---|---|

## Rules

### R001: Model file tampering
```yaml
- rule: unauthorized_model_write
  desc: ...
  condition: ...
  output: ...
  priority: CRITICAL
  tags: [ml, model_integrity, mitre_t1565]
```
- Expected FPR: ...
- Triage: ...
- Tuning levers: ...

### R002: Training-job egress anomaly
...

### R003: Reverse shell in production
...

### R004-R008: ...

## Cross-references with the audit chain
(How Falco events become audit-chain entries.)

## Integration with Falcosidekick
(Routing: Critical → PagerDuty, High → Slack, Medium/Low → SIEM.)

## Quarterly review process
(How rules are re-evaluated, tuned, retired.)
```

## Quality criteria

A passing ruleset:

- At least 8 rules with **specific** conditions (not generic
  "anomaly detected").
- Each rule has a priority calibrated to actual response cost.
- Expected false-positive scenarios are real (e.g., "kubectl
  exec during planned debug sessions").
- The tuning plan is realistic — rules without tuning drown
  the on-call in noise.

A failing ruleset:

- Generic placeholders.
- All rules at CRITICAL priority.
- No tuning plan.
- Missing the ML-specific rules in favor of generic Linux
  security rules.

## Reflection questions

1. Which rule has the highest signal-to-noise ratio? Why?
2. Which rule will produce the most false positives initially?
3. The team objects: "Falco alerts are noise." How do you
   keep the team engaged with alert review long-term?
