# Capstone Exercise 05 — SecOps Program

**Estimated time**: 5 hours
**Deliverable**: A 10-12 page SecOps program document

---

## The assignment

Produce NorthBridge's SecOps program — the operational layer
that runs continuously. Synthesizes Modules 08 + 11.

## Required sections

### Section A: Runtime security baseline (Module 08)

- **Pod Security Standards** rollout — per-namespace targets,
  enforcement schedule.
- **Seccomp + AppArmor** profiles — at least for the clinical
  serving pods.
- **Falco ruleset** — start with the default + 10-15
  NorthBridge-specific rules tied to your Module 08 work and
  the threats from Exercise 01.
- **Behavioral baseline** design for Triage-Risk and HAI-
  Predict serving pods.
- **Container-escape response runbook** (carry over from
  Module 08 Exercise 05).

### Section B: SIEM design

- **SIEM choice**: defend your pick for NorthBridge (budget
  ~$80k-$120k annual; already on Datadog for general
  observability).
- **Log sources** to ingest:
  - Kubernetes audit log.
  - Falco events.
  - Cilium Hubble flows.
  - Gateway access logs.
  - Audit chain entries.
  - CloudTrail.
  - GitHub Actions audit.
  - Rekor signature events.
  - Vault audit log.
- **Retention** matched to regulatory needs.
- **Integration with Datadog** — what stays in Datadog, what
  moves to SIEM.

### Section C: Detection ruleset

At least **20 Sigma rules** total. Combine:

- The ML-specific rules from Module 11 Exercise 02.
- Healthcare-specific rules — PHI access anomalies, unexpected
  bulk exports, EHR-integration-anomaly patterns.
- Insider-threat rules — privileged user access patterns.
- Supply-chain rules — unsigned admission attempts, unexpected
  Rekor entries.
- LLM-specific rules — prompt-injection clusters, output
  filtering trips, tool-call anomalies.

For each rule:

- Sigma YAML (or pseudo).
- MITRE ATLAS + ATT&CK tags.
- Severity.
- Expected FPR.
- Triage steps.
- Audit-chain integration.

### Section D: IR procedure + playbooks

- **IR procedure** (Module 11 Exercise 03 pattern).
- **At least 8 playbooks**:
  1. Suspected model extraction (Triage-Risk).
  2. Suspected data poisoning (HAI-Predict retraining).
  3. PHI exfiltration via ML pipeline.
  4. Prompt-injection harm in Ambient-Doc.
  5. Customer-impacting wellness-coach prompt injection.
  6. Container escape from training pod.
  7. Secret leak (e.g., OpenAI key in code).
  8. CI compromise.

For each playbook: detection sources, immediate containment,
investigation, eradication, recovery, communication, post-
incident.

### Section E: Tabletop schedule + scenarios

- **Quarterly tabletop cadence** for the next 12 months.
- **8 scenarios** drawing from the playbooks.
- **Facilitator guide** for the team.

### Section F: On-call structure

For an 8-engineer team growing to 25:

- **Today's on-call** — likely 4-person rotation, weekly.
- **At 15 engineers** — split into platform + ML-platform
  rotations.
- **At 25 engineers** — separate security on-call from
  general platform on-call?

For each phase:
- Rotation design.
- Tools.
- Compensation.
- Handoff process.

### Section G: Metrics dashboard

The metrics you'll review monthly:

- Detection coverage (% MITRE ATLAS tactics).
- Alert FPR per rule.
- MTTD / MTTR per severity tier.
- Postmortem follow-through (% action items closed on time).
- Drill cadence adherence.
- Detection-rule freshness.

A mockup of a leadership-facing metrics dashboard.

## Quality criteria

A passing program:

- Detection ruleset has **20+ rules** with MITRE mapping.
- IR procedure has **8+ playbooks** with concrete commands.
- Tabletop schedule covers a **12-month** plan.
- On-call scales from **8 to 25 engineers**.
- Metrics are **leading + lagging**, not just MTTR.

A failing program:

- < 15 detection rules.
- Generic IR procedure without playbook depth.
- "Quarterly tabletop" without scenarios.
- On-call designed only for today's team.
- MTTR as the only metric.

## Reflection questions

1. Which playbook is most likely to be needed first?
2. The detection ruleset will produce alert volume.
   What's the FPR you can sustain before alert fatigue?
3. The on-call rotation will burn the team out if
   misdesigned. What's the structural protection?

## Time budget

- Runtime security: 60 min.
- SIEM design: 45 min.
- Detection ruleset: 90 min.
- IR procedure + playbooks: 75 min.
- Tabletop schedule: 30 min.
- On-call: 30 min.
- Metrics: 30 min.
