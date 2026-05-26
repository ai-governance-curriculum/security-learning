# Module 11 Quiz — Security Operations

> Closed-book first.

---

## Conceptual (10 questions)

### Q1
Name the five activities of security operations (§1). For each,
give one example of how a team without that activity ends up
worse off.

### Q2
Compare the **dedicated SOC** and **embedded** staffing models
(§1.2). Which fits SmartRecs? Defend.

### Q3
A SIEM's cost is dominated by ingest volume. For each log
source below, decide if it goes in your SIEM, in your generic
observability stack (Datadog, Grafana, Honeycomb), or both:
- (a) Kubernetes audit log.
- (b) Application request logs at full fidelity.
- (c) Falco runtime events.
- (d) Cilium Hubble flow logs.
- (e) Stripe webhook events.

### Q4
Explain why **Sigma format** matters even if you're committed
to one SIEM. Why not just write KQL or SPL directly?

### Q5
The lecture lists "good rule" and "bad rule" characteristics
(§3.4). Name three of each, and explain in one sentence why
each matters.

### Q6
For each MITRE ATLAS tactic below, name the **detection
source** that's most likely to fire on it:
- Reconnaissance.
- Initial Access (via supply chain).
- ML Model Access.
- Discovery.
- Collection.
- Exfiltration.

### Q7
Define **alert fatigue** in your own words. Name three
operational consequences. Name three structural mitigations.

### Q8
Compare a **tabletop** and a **game day** (§9). When is each
appropriate? Which would you run first at SmartRecs?

### Q9
The lecture argues for **blameless postmortems** (§10.1).
Defend the principle. What's the failure mode of a blame-based
postmortem culture, and how does it harm future incident
response?

### Q10
The lecture warns against using MTTR as a single-number metric
(§6.4). Explain three ways MTTR can lie. What's the better way
to use it?

---

## Applied (5 questions)

### Q11
Author a Sigma rule that detects **model-extraction probing**:
- Trigger: a single tenant's query rate exceeds 5× their
  trailing-30-day baseline.
- Duration: sustained for 10+ minutes.
- Severity: high.
- Logsource: ML gateway access log.

Include MITRE ATLAS tags + false-positive scenarios + triage
steps.

### Q12
Design the **alert routing** for SmartRecs:
- (a) Critical → page.
- (b) High → page or Slack?
- (c) Medium → ?
- (d) Low → ?

For each tier, name the routing destination, the expected
response SLA, and the on-call's expectation. Justify any
deviations from the lecture defaults.

### Q13
Walk through the **first 30 minutes** of incident response
when this alert fires:

> **Critical**: An audit-chain query shows that a
> non-administrative IAM identity has accessed the entire
> customer-PII column in the feature store within the past
> hour. The access pattern looks like a database dump.

Specifically: triage, confirm, contain, escalate, communicate.

### Q14
Design a **tabletop scenario** for "suspected LLM prompt
injection harm." Include:
- Setup.
- Inject events at +10, +30, +60 minutes.
- Decision points.
- Expected outcomes.
- Common mistakes.
- Grading rubric.

### Q15
Write the **postmortem** for the incident in Q13. Use the
structure from §10.2:
- Summary.
- Timeline (fabricate the details consistent with Q13).
- Root cause analysis.
- What went well + what went poorly.
- Action items (at least 5).
- Lessons learned.

Make it blameless. Action items must be systemic, not
personal.

---

## Self-assessment rubric

Same as previous modules. Passing: average ≥ 2.0, no question
scored 0.
