# Exercise 05 — Container-Escape Response Runbook

**Estimated time**: 2 hours
**Deliverable**: A runbook + a tabletop scenario

---

## The assignment

Write the on-call runbook for a confirmed (or strongly
suspected) container-escape incident at SmartRecs. Container
escape is the worst-case runtime-security scenario; the runbook
must be **rehearsable** and **time-bounded**.

## What the runbook must cover

### 1. Detection sources

- Falco alert (specific rule).
- Tetragon enforcement event (if used).
- Audit-chain anomaly.
- Host-level alert (process-tree change, unexpected `setns`
  call).
- External report (someone tells you).

For each source, describe the **first 5 minutes** of triage —
what data to collect *before* taking destructive action.

### 2. Immediate containment (within 15 minutes)

- Identify the affected pod.
- Identify the affected node.
- Quarantine the node: cordon + drain (with caveats — drain
  may give the attacker time to do more damage).
- Network isolation: per-namespace deny-all override.
- Preserve forensic evidence: pod memory snapshot, node
  process list, network connection list.

### 3. Investigation (within 4 hours)

- Process lineage: what spawned the escape attempt?
- Filesystem changes since pod started.
- Network connections during the incident window.
- Audit-chain queries: what else happened around the time?
- Correlation with other systems (CI activity, deployment
  events, access changes).

### 4. Eradication

- Determine the root cause:
  - Vulnerability in container runtime?
  - Vulnerable application code?
  - Compromised dependency?
  - Insider action?
- Patch / mitigate before returning the node to service.

### 5. Recovery

- Bring the node back online (or replace it entirely).
- Re-deploy affected workloads on a verified node.
- Validate the fix held (replay attack pattern, confirm
  blocked).

### 6. Communication

- Internal: who learns about the incident, when, with what
  level of detail.
- External: customer notification (timing depends on the
  incident class — GDPR's 72 hours is the worst case).
- Regulatory: depends on data touched.
- Post-mortem: who runs it, when, who's invited.

### 7. Post-incident actions

- Update runtime-security rules to catch the specific pattern.
- Update incident-response procedures based on what went well /
  poorly.
- Update detection coverage for related patterns.

## The tabletop scenario

Write a 1-page tabletop that simulates an escape:

- **Setup**: what alert fires, what evidence is on the table.
- **Inject events**: at +10 min, +30 min, +60 min.
- **Decision points**: containment timing, communication
  timing, escalation timing.
- **Expected outcomes**: what a well-run drill achieves.
- **Common mistakes**.

## Format

```
# Container-Escape Response Runbook

## Last updated / owner

## Severity classification

## Detection sources

### Source 1: Falco "container escape attempt"
- Specific alert text
- First 5 minutes: what to collect

### Source 2: Tetragon enforcement event
- ...

## Immediate containment

### Step 1: Identify affected pod and node
- Command: ...
- Expected output: ...

### Step 2: Network isolation
- Command: ...
- Expected output: ...

### Step 3: Preserve evidence
- Memory snapshot: ...
- Process list: ...
- Network state: ...

## Investigation

### Process lineage
### Filesystem changes
### Audit-chain queries
### Correlation with CI / deploy events

## Eradication

### Root-cause analysis
### Patch / mitigation

## Recovery

### Node return-to-service
### Workload re-deployment
### Validation

## Communication

| Audience | When | What | Owner |
|---|---|---|---|

## Post-incident

### Runtime-security rule updates
### Procedure updates
### Detection-coverage updates
### Customer-facing post-mortem

---

# Tabletop Scenario: Suspected escape in production

## Setup
(0 min): Falco alert fires...

## Inject events

(+10 min): ...

(+30 min): ...

(+60 min): ...

## Decision points

1. Containment vs. observation: ...
2. Communication: ...
3. Escalation: ...

## Expected outcomes

(What a correctly-run drill achieves.)

## Common mistakes

- Drain the node before snapshot (lose evidence).
- ...
```

## Quality criteria

A passing runbook:

- Each step has **specific commands** (or named tools), not
  "investigate."
- Containment is **time-bounded** with concrete actions.
- Evidence-preservation steps come **before** containment
  actions that destroy evidence.
- The tabletop is realistic and runnable.

A failing runbook:

- "Investigate, then contain" without specifics.
- Drains the node before snapshots (destroys evidence).
- No customer-communication plan.
- No tabletop or one that's not actionable.

## Reflection questions

1. Which step in the runbook is most likely to go wrong under
   real incident pressure?
2. The team objects: "Container escape never happens; this
   runbook is over-investment." Defend the runbook.
3. The first time you run the tabletop, what gaps will appear
   in your runbook?

## Save your artifact

Cross-reference with Module 11 (Security Operations) for the
SIEM and broader IR integration.
