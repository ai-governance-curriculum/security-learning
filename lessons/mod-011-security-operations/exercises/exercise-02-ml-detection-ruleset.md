# Exercise 02 — ML-Specific Detection Ruleset

**Estimated time**: 3 hours
**Deliverable**: 10+ Sigma rules with MITRE ATLAS mapping

---

## The assignment

Build SmartRecs' ML-specific detection ruleset. These are
detections that exist *because* the platform runs ML. Standard
infrastructure detections (failed logins, lateral movement) are
covered elsewhere; this exercise focuses on ML-specific.

## Required detections (minimum 10)

Author Sigma rules for at least these threats:

1. **Per-tenant query rate spike** — extraction probe candidate.
2. **Per-tenant cost spike (LLM)** — cost-amplification attack.
3. **Prompt-injection pattern detection** — direct attempts.
4. **Indirect prompt-injection signal** — high entropy text in
   retrieved RAG chunks.
5. **Model file integrity violation** — unauthorized write to
   model directory (Falco source).
6. **Suspected membership-inference probe** — high-confidence-
   disclosing queries against narrow records.
7. **Training-data distribution shift on retraining** — input
   for poisoning detection.
8. **Per-model accuracy regression in production** — possible
   poisoning indicator.
9. **Per-tenant feature-access pattern anomaly** — multi-tenant
   isolation probe.
10. **Notebook outbound to non-allowlisted destination** —
    notebook abuse / exfiltration.

Optional further detections:

11. Cosign signature verification failure at admission.
12. Rekor entries from unexpected workflows.
13. Hugging Face model load with unsafe deserialization format.
14. Sustained GPU utilization on supposedly-idle pod.

## For each rule

Provide:

- The Sigma YAML.
- **MITRE ATLAS** and/or **ATT&CK** tags.
- **Severity** (`low` / `medium` / `high` / `critical`).
- **False-positive scenarios** (real ones).
- **Triage steps** (3-5 specific actions).
- **Tuning levers** (how to reduce FPR over time).

## Format

```
# SmartRecs ML Detection Ruleset

## Rule index

| ID | Title | Severity | ATLAS / ATT&CK tags |
|---|---|---|---|

## Detections

### ML-DET-001: Per-tenant query rate spike

```yaml
title: Per-tenant query rate spike (possible extraction probe)
id: ...
status: experimental
description: ...
author: ...
date: ...
tags:
    - atlas.ml.t0024  # Discover ML Model Family
    - atlas.ml.t0044  # ML Attack Staging
logsource:
    product: smartrecs
    service: ml-gateway
detection:
    selection:
        request.tenant_id|exists: true
        query_rate_per_minute|gt: # 5x baseline
    timeframe: 10m
    condition: selection
falsepositives:
    - Tenant ran a planned batch operation (annotated in
      tenant metadata).
    - New product launch announcement that drove traffic.
level: high
```

- False-positive scenarios: ...
- Triage steps: ...
- Tuning levers: ...

### ML-DET-002: Per-tenant LLM cost spike
...

(Continue through 10+ rules.)

## Coverage analysis

| MITRE ATLAS tactic | Rules covering it |
|---|---|
| Reconnaissance | ... |
| Resource Development | ... |
| Initial Access | ... |
| ...

## Coverage gaps

(Tactics with no detection. Honest list.)

## Integration with the SIEM

(How rules deploy, where alerts go, audit-chain integration.)

## Tuning plan

(Per-rule: monthly review of FPR, expected baseline alert
volume, when to retire or refactor.)
```

## Quality criteria

A passing ruleset:

- **10+ real Sigma rules** (not pseudo).
- Each maps to **MITRE ATLAS or ATT&CK**.
- Each has **false-positive scenarios** and **triage steps**.
- The coverage analysis is honest — gaps named, not glossed
  over.
- Tuning plan acknowledges that rules degrade in production.

A failing ruleset:

- < 10 rules.
- No ATLAS / ATT&CK mapping.
- Generic "investigate the alert" triage.
- No coverage analysis.

## Reflection questions

1. Which rule has the **highest expected FPR**? What's the
   mitigation?
2. Which rule has the **most surprising signal-to-noise
   ratio** — i.e., catches more real attacks than expected?
3. The team objects: "Most of these rules will rarely fire.
   Why bother?" Defend.
