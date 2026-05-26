# Module 11 — Security Operations for ML Systems

> **Note on AI-assisted content.** Drafted with AI assistance and
> under human review. Specific SIEM products, Sigma syntax, and
> threat-intel sources evolve; verify with upstream docs.
> See [`resources.md`](./resources.md).

---

## 1. What security operations actually is

The first 10 modules produced controls (what stops attacks) and
signals (what tells you an attack happened). Security
operations is the **discipline** that turns signals into
action.

Five activities:

1. **Detection** — turning raw signals into actionable alerts.
2. **Triage** — deciding what's a real incident vs. a false
   positive vs. an info-only event.
3. **Investigation** — what actually happened, when, by whom,
   what was affected.
4. **Response** — containing, eradicating, recovering.
5. **Learning** — turning incidents into systemic
   improvements.

A team without security operations has controls that produce
events that nobody reads. The events are wasted; the controls
are theatrical.

### 1.1 What it isn't

- **Building controls** — that's Modules 02-10.
- **Compliance auditing** — Module 07.
- **Threat modeling** — Module 01.

SecOps is the operational layer that **assumes** the controls
exist and **operates them in production**.

### 1.2 The SOC vs. embedded model

Two staffing patterns:

| Pattern | Description | Fit |
|---|---|---|
| **Dedicated SOC** | 24/7 analysts watch alerts; tier-1 triage; escalate to engineering | Enterprise scale, regulated industries |
| **Embedded** | Engineering teams are the SOC; on-call rotations | Smaller teams; SmartRecs scale |
| **Hybrid** | Tier-1 outsourced (MSSP); tier-2 internal | Mid-market |

For SmartRecs (~6 engineers, no dedicated SOC), the embedded
model is the realistic posture. The lecture notes calibrate to
that scale; an enterprise SOC has a different operational
shape.

---

## 2. SIEM fundamentals

A SIEM (Security Information and Event Management system)
collects, queries, and alerts on security-relevant events.

### 2.1 What a SIEM actually does

- **Ingest** logs from many sources (Kubernetes audit, Falco,
  Cilium Hubble, application logs, AWS CloudTrail, etc.).
- **Normalize** — different sources use different schemas;
  normalize to a common one.
- **Index** for query performance.
- **Store** with retention appropriate to compliance + IR
  needs.
- **Query** against current and historical data.
- **Alert** based on rules (real-time matches or scheduled
  queries).
- **Dashboards** for situational awareness.

### 2.2 SIEM choices

| Product | Type | Fit |
|---|---|---|
| **Splunk** | Commercial, expensive, comprehensive | Enterprise |
| **Elastic Security** (formerly SIEM in Elastic Stack) | Self-host or Elastic Cloud | Flexible |
| **Microsoft Sentinel** | SaaS on Azure | Microsoft-heavy environments |
| **Google Chronicle** | SaaS on GCP | Google-heavy environments |
| **Sumo Logic** | SaaS | Mid-market |
| **Datadog Cloud SIEM** | SaaS, observability-adjacent | Teams already on Datadog |
| **Open-source: Wazuh / OSSEC / Graylog** | Self-host | Budget-constrained, technical teams |

For SmartRecs scale, the realistic options are:

- **Elastic Security** (self-hosted ELK or Elastic Cloud).
- **Datadog Cloud SIEM** (if the team is already on Datadog).
- **Wazuh** (free; significant operational cost).

### 2.3 Costs

SIEMs are expensive. The cost model is usually:

- **Per-GB ingest** (Splunk, Sumo Logic): a 50GB/day log volume
  can run $10k-$50k/month.
- **Per-event** (Sentinel, Chronicle): pay per event analyzed.
- **Per-host** (Datadog): pay per monitored host.

For a 6-engineer ML platform processing tens of GB/day of
logs, expect to spend tens of thousands of dollars annually on
SIEM. The cost is usually justified — but only when the SIEM
is actually queried and alerts on it acted upon.

### 2.4 What goes into the SIEM

For an ML platform, the high-value sources:

- **Kubernetes audit log** — every API call against the
  cluster.
- **Falco / Tetragon events** — runtime security alerts.
- **Cilium Hubble flow logs** — L3/L4/L7 network flows.
- **Application audit logs** — gateway requests, API access,
  authn events.
- **Audit chain entries** — compliance events.
- **CloudTrail / cloud-provider audit** — IAM, infrastructure
  changes.
- **CI/CD events** — workflow runs, secret access, signature
  events.
- **Rekor events** (Module 10) — signature monitoring.

Each is one log source to configure. Each has its own format
to parse.

### 2.5 What doesn't (usually) go into the SIEM

- High-volume application telemetry (request logs at full
  fidelity).
- Debug logs from development environments.
- Anything with PII / PHI that the SIEM isn't licensed to
  process.

The boundary: SIEM is for **security-relevant** events.
General observability (Datadog, Grafana, Honeycomb) is for
application telemetry. Some events cross over (Hubble flows
for both); the design decision is *which is the source of
truth* for a given query.

---

## 3. Detection-rule authoring

A rule is a query that fires when matched. The work is
authoring rules that catch real threats while not drowning the
on-call in noise.

### 3.1 The Sigma format

Sigma is a generic detection-rule format. The advantage:
write once, convert to any SIEM's native query language.

A sample Sigma rule:

```yaml
title: Suspicious kubectl exec into production pod
id: 7c3d4e5f-6a7b-8c9d-0e1f-2a3b4c5d6e7f
status: experimental
description: Detects interactive kubectl exec into a production
             namespace. Production pods should not require
             interactive debugging in normal operation.
author: security@smartrecs
date: 2026-01-15
tags:
    - attack.execution
    - attack.t1609   # Container Administration Command
    - atlas.ml.t0044 # Initial Access
references:
    - https://attack.mitre.org/techniques/T1609/
logsource:
    product: kubernetes
    service: audit
detection:
    selection:
        verb: 'create'
        objectRef.subresource: 'exec'
        objectRef.namespace|startswith: 'prod-'
    condition: selection
falsepositives:
    - Planned debugging sessions (annotated with approval)
    - Break-glass access during incidents
level: high
```

Components:

- **title** + **description** + **id** — human-readable + UUID.
- **status** — `experimental` → `test` → `stable`.
- **tags** — MITRE ATT&CK / ATLAS for mapping.
- **references** — links to background.
- **logsource** — which log source the rule applies to.
- **detection** — the matching logic.
- **falsepositives** — known FP scenarios.
- **level** — `low` / `medium` / `high` / `critical`.

### 3.2 Converting Sigma to your SIEM

Tools:

- `sigma-cli` (official) — converts to many backends.
- `uncoder.io` — web-based converter.
- SIEM-vendor-specific converters.

The conversion isn't always lossless. Complex Sigma rules may
need manual adjustment per SIEM.

### 3.3 Detection categories for ML platforms

Group rules by what they catch. A defensible coverage:

#### Identity / authentication

- Multiple failed auth attempts from same source.
- Unusual access patterns (geography, time-of-day).
- Privilege escalation.

#### Network

- Egress to unauthorized destinations (paired with Cilium
  policy denials).
- Cloud-metadata endpoint access.
- DNS anomalies (suspicious queries, long subdomains).

#### Workload

- Pod admission rejections.
- Shell processes in production containers (from Falco).
- Container escape attempts.

#### Supply chain

- Signature verification failures.
- Rekor entries from unexpected workflows.
- Unsigned artifacts attempting admission.

#### ML-specific

- Per-tenant query rate spikes (extraction probe).
- Per-tenant cost spikes (LLM cost abuse).
- Drift alerts on production models.
- Feature-distribution anomalies on production inference.
- LLM prompt-injection-pattern matches.

### 3.4 Writing good rules

A good rule:

- **Has a low false-positive rate** in production.
- **Has actionable triage steps** — what does the on-call
  do?
- **Maps to MITRE ATLAS / ATT&CK** for situational awareness.
- **Has a known-bad test** — can be verified to fire on a
  positive case.
- **Has a known-good test** — can be verified not to fire on
  routine activity.

A bad rule:

- Triggers on every operational event.
- Has "investigate the alert" as the only triage step.
- Doesn't map to any tactic.
- Has never been tested against a positive case.

### 3.5 ML-specific detection signals

The detections that exist *because* SmartRecs is an ML
platform:

#### Model extraction (ML05)

```
rule: per_tenant_query_rate_spike

if (
    per_minute_query_rate(tenant_id) > baseline(tenant_id) * 5
    and duration > 10 minutes
) -> alert
```

A tenant whose query rate has gone from 100/min to 500/min for
10+ minutes is a candidate extraction attack.

#### Per-tenant cost amplification

```
rule: tenant_cost_spike_llm

if (
    hourly_cost(tenant_id) > expected_hourly_cost(tenant_id) * 3
) -> alert
```

For LLM APIs, sudden cost increases per tenant.

#### Prompt-injection pattern match

```
rule: llm_prompt_injection_attempt

if (
    request.text matches /ignore previous instructions/i
    or request.text matches /system prompt/i
    or request.text matches /you are now/i
) -> alert (low priority — used for tuning, not response)
```

These aren't reliable detection on their own — too many false
positives — but in aggregate they're informative.

#### Training-data anomaly

```
rule: training_data_distribution_shift

if (
    feature_distribution(new_batch) differs from baseline by KL > 0.1
    and new_batch.source != approved_source
) -> alert
```

For systems with continuous retraining, anomalies in input data
distribution.

#### Membership-inference probe

```
rule: confidence_query_pattern

if (
    queries_with_confidence_disclosure(tenant_id) > 100 / hour
    and high_similarity_to_training_distribution
) -> alert (membership-inference probe candidate)
```

A pattern of confidence-disclosing queries against suspected
training records.

---

## 4. Triage and alert tuning

The chronic SecOps problem: too many alerts.

### 4.1 The alert pyramid (revisited)

From Module 08, applied here:

| Priority | Examples | Response time | Routing |
|---|---|---|---|
| **Critical** | Container escape, confirmed extraction, customer-data exfiltration | Page immediately | PagerDuty |
| **High** | Suspicious egress, prompt-injection cluster, supply-chain anomaly | On-call within 1 hour | PagerDuty (lower priority) |
| **Medium** | Authn anomalies, unusual API patterns | Next business day | Slack channel |
| **Low** | Configuration drift, info-only | Weekly review | SIEM queue |

Without this layering, every alert is treated equally —
meaning few are treated seriously.

### 4.2 Triage workflow

When an alert fires, the on-call:

1. **Acknowledge** in PagerDuty / Slack / wherever.
2. **Initial assessment** — is this real?
   - Check the audit chain for context.
   - Check the workload (`kubectl describe pod ...`).
   - Check the user / identity.
3. **Classify** — false positive, known issue, or real
   incident.
4. **For real incidents**: open an incident ticket, escalate
   per IR procedure (§5).
5. **For false positives**: tune the rule (open a PR; don't
   just dismiss).
6. **For known issues**: link to the related ticket; close.

### 4.3 Alert fatigue and tuning

Alert volume that exceeds triage capacity is alert fatigue.
The on-call starts ignoring alerts; real ones get missed.

The fix:

- **Tune ruthlessly.** A rule that produces 80% FPR isn't a
  rule, it's noise.
- **Suppress during expected events.** Planned maintenance,
  deploys, known operations.
- **Aggregate.** "100 events of pattern X in 5 minutes" is
  often a single signal, not 100.
- **Surface trends, not events.** "Tenant X's traffic is up
  3σ" is more useful than "tenant X just sent another request."

### 4.4 The on-call experience

A well-operated on-call:

- Receives **≤2-3 actionable pages per week**.
- Receives **≤10 informational alerts per week** (Slack-only).
- Has a **clear runbook** for each alert.
- Has **clear escalation paths** when they're stuck.
- Has **calibrated severity** — Critical means Critical.

A poorly-operated on-call:

- 50+ pages per week, mostly false positives.
- "Investigate" as the only runbook.
- No clear escalation.
- Critical / High / Medium are indistinguishable in practice.

The state of your on-call is a leading indicator of your
overall security posture.

---

## 5. Incident response procedures

When a real incident is confirmed, the IR procedure governs
what happens.

### 5.1 The phases

Modeled on NIST SP 800-61:

1. **Preparation** — having runbooks, contacts, tools ready
   *before* the incident.
2. **Detection and analysis** — confirming what happened.
3. **Containment, eradication, recovery** — stopping the
   damage and recovering.
4. **Post-incident activity** — postmortem, lessons learned.

The preparation phase is the unsexy one. It's also the one
that distinguishes good IR from bad.

### 5.2 The incident commander pattern

For non-trivial incidents, assign an **incident commander**
(IC):

- The IC owns the incident's overall coordination.
- The IC is not necessarily the engineer doing the technical
  work.
- The IC delegates investigation, communication, decisions.
- The IC ensures regulatory clocks (GDPR 72h, etc.) are
  tracked.
- The IC owns the postmortem follow-up.

For SmartRecs scale: the on-call who acknowledged the alert
becomes IC until they hand off. For larger incidents, the IC
role is explicitly transferred.

### 5.3 The playbook structure

For each incident class, have a playbook. From Modules 03, 05,
08, 10 you've built several:

- Secret-leak runbook (Module 05).
- Container-escape runbook (Module 08).
- Supply-chain incident runbook (Module 10).

Each playbook follows the same shape:

- Detection sources.
- Confirmation steps.
- Immediate containment.
- Investigation (forensics).
- Eradication.
- Recovery.
- Communication.
- Post-incident.

This module's contribution: an **IR procedure** that integrates
the playbooks into a coherent program.

### 5.4 Communication during an incident

Three channels:

- **Internal coordination** — Slack channel #incident-xxx, or
  voice / video room. Updates every 15-30 min.
- **Stakeholder updates** — exec + leadership; lower
  frequency, higher signal.
- **External communication** — customer + regulatory; per
  legal / comms team approval.

Common mistakes:

- Mixing the three (executive on the technical Slack →
  pressure on responders).
- Confidential details in widely-visible channels.
- No designated communicator (everyone or no one).

---

## 6. On-call patterns

Sustainable on-call is its own skill.

### 6.1 Rotation design

- **Pager rotation**: typically weekly. Daily rotations burn
  people out; monthly rotations make people lose context.
- **Geographic distribution** if possible: someone always
  awake.
- **Primary + secondary**: secondary covers when primary is
  unreachable.
- **Compensation**: paid on-call, on-call hours count as work,
  comp time for paged hours.

### 6.2 What's on the on-call's plate

- Acknowledge pages.
- Triage.
- Initial response (contain, escalate).
- *Not* deep investigation — that's the IR team / engineering
  team during business hours.

A common failure mode: putting all of investigation on the
on-call. Burnout follows.

### 6.3 Handoffs

End of a rotation: handoff to the next on-call.

- **What's in flight**: incidents not yet closed.
- **Known issues**: things firing alerts that are being
  tracked.
- **Recent changes**: deploys, infrastructure changes that
  might explain alerts.

A 15-minute sync at rotation end is the difference between
context-aware and lost on-call.

### 6.4 The MTTR / MTTD metrics

- **MTTD** (Mean Time To Detect) — how long from incident
  onset to alert.
- **MTTR** (Mean Time To Respond / Resolve — note the
  ambiguity) — how long from alert to containment, or to full
  resolution.

These metrics are useful but easy to game:

- Counting only confirmed incidents (vs. false positives)
  changes the picture.
- "Resolved" varies by definition.
- A single big incident with long MTTR distorts the average.

The healthy way to use them: as **trend indicators**, not
absolute scores. A team whose MTTR is increasing month over
month has a problem.

---

## 7. Forensics

When an incident is being investigated, forensics is the
discipline of preserving evidence and drawing defensible
conclusions.

### 7.1 The order of volatility

Evidence vanishes in order of how volatile it is:

1. **Process memory** — gone when process exits.
2. **Network state** — gone when connections close.
3. **Disk state** — preserved unless overwritten.
4. **Audit logs** — preserved if retention is sufficient.

The triage step "contain by killing the pod" loses (1) and
(2). For high-severity incidents, **preserve before contain**:

- Take a memory snapshot.
- Capture the process tree and network state.
- Then contain.

For lower-severity, containment first is OK — the trade-off is
acceptable.

### 7.2 The chain of custody

For incidents that might end up in legal proceedings or
regulatory submissions:

- Every artifact (log, memory dump, screenshot) has a recorded
  custodian.
- Every transfer of an artifact is logged.
- Hashes of artifacts are recorded at collection time and
  verified at use time.

For most operational incidents, this is overkill. For
nation-state-suspected incidents or regulatory ones, it's
essential.

### 7.3 Investigation patterns

A common investigation workflow:

1. **Establish the timeline** — when did each observed event
   happen?
2. **Identify the entry point** — how did the attacker get in?
3. **Identify the blast radius** — what did they touch?
4. **Identify the data taken** — what left the environment?
5. **Identify ongoing presence** — are they still there?

Each step has techniques and tools (audit-chain queries, log
analysis, file-system diffs, etc.) that this module's
exercises cover.

---

## 8. Threat intelligence

Threat intel is information about adversaries: their TTPs,
their tools, their targets.

### 8.1 Sources

- **Public**: MITRE ATT&CK / ATLAS, CISA advisories, OSINT.
- **Vendor**: threat-intel platforms (Recorded Future,
  CrowdStrike Intel, Mandiant) — expensive but timely.
- **ISACs** (Information Sharing and Analysis Centers) —
  industry-specific (Financial Services ISAC, Healthcare ISAC).
- **Open source**: blogs, Twitter / X, research papers.

For SmartRecs scale: CISA + MITRE ATLAS + a few well-curated
blogs is realistic. Commercial threat-intel feeds usually need
a dedicated analyst to be worth the cost.

### 8.2 What to do with threat intel

Three patterns:

1. **IOC matching** — block / alert on known-bad indicators
   (IPs, domains, file hashes). Tactical, short shelf-life.
2. **TTP mapping** — update detection rules for adversary
   tactics. Strategic, longer shelf-life.
3. **Threat-actor briefings** — know who's targeting your
   sector, what they prefer.

For ML platforms specifically: MITRE ATLAS is the key
reference. New ATLAS tactics + techniques are added as they're
documented in the wild; periodically review your detection
coverage against ATLAS.

### 8.3 What not to do

- **IOC overload** — blocking every IP an intel feed marks bad
  produces operational pain.
- **Confusing intel with detection** — intel informs detection;
  it isn't detection.
- **Treating threat intel as a checkbox** — paying for a feed
  without using it.

---

## 9. Tabletops and game days

Practice for incidents you've never had.

### 9.1 The tabletop format

A **tabletop exercise** is a discussion-based incident
simulation:

- 60-90 minutes.
- A facilitator presents a scenario in stages.
- Participants discuss what they'd do at each stage.
- A note-taker records gaps and questions.

No actual systems are touched. The output: a list of gaps in
the IR procedure, runbooks, escalation paths, communication.

### 9.2 Game days

A **game day** is more aggressive: actual fault injection in a
test (or in some cases production) environment, with the team
responding as if it were real.

- Longer (half-day to full-day).
- Requires planning and resource commitment.
- Higher value than tabletops because it tests *what actually
  works*, not what people say works.

For ML platforms: game days that include adversarial-input
scenarios (Module 06) or supply-chain compromise scenarios
(Module 10) are particularly valuable.

### 9.3 Cadence

- **Tabletops**: quarterly.
- **Game days**: annually at minimum; more often when feasible.
- **Drills** (smaller exercises focused on one runbook):
  monthly.

The point: by the time a real incident occurs, the team has
practiced response. The first time you run the runbook is *not*
during a real incident.

### 9.4 Scenarios to practice

From the modules:

- Container escape (Module 08).
- Secret leak (Module 05).
- CI compromise (Module 10).
- Customer-data exfiltration via authenticated API.
- Suspected model extraction.
- Suspected data poisoning detected via drift.
- LLM prompt-injection harm.
- Multi-tenant isolation bypass (feature store).

The exercises in this module include building tabletop
scenarios.

---

## 10. Postmortems

After every significant incident: a postmortem.

### 10.1 The blameless postmortem

The principle: people make mistakes; systems should be designed
so mistakes don't cause outages. Blaming individuals doesn't
fix the system.

In practice:

- The postmortem describes what happened, why, what was
  learned.
- Action items are systemic ("add monitoring for X") not
  personal ("Bob should be more careful").
- Names are used to credit work, not to assign blame.

### 10.2 Postmortem structure

A common structure:

1. **Summary** — one paragraph; what happened, when, impact.
2. **Timeline** — chronological events.
3. **Root cause analysis** — the technical / process cause.
4. **What went well** — celebrate the good responses.
5. **What went poorly** — name the gaps honestly.
6. **Action items** — concrete, owned, time-bounded.
7. **Lessons learned** — generalize beyond this incident.

### 10.3 Publication

- **Internal**: every postmortem goes into a shared repository.
- **Customer-facing**: significant customer-impacting incidents
  get a public-facing version (less detail, more reassurance).
- **Regulatory**: required for some breach types.

### 10.4 The 5 Whys

A common RCA technique: ask "why?" five times.

- Why did the incident happen? The model returned bad
  predictions.
- Why? The training data was poisoned.
- Why? An attacker submitted feedback that influenced
  retraining.
- Why? Feedback wasn't differentiated from training-eligible
  data.
- Why? The platform's data lifecycle didn't have a
  training-eligibility flag.

The deepest "why" is usually a process or design issue, not a
single mistake.

---

## 11. ML-specific incident response

Standard IR adapted for ML threats.

### 11.1 Model-extraction incident

Detection: per-tenant query rate spike + similarity-to-training
pattern.

Containment:
- Tighten rate limits on the suspect tenant.
- Quarantine the tenant (block API access).
- Preserve query logs.

Investigation:
- How many queries did the tenant send?
- How much of the decision surface could be reconstructed?
- Was this attacker-or-aggressive-legitimate-user?

Recovery:
- Customer-facing communication (transparent if appropriate).
- Model rotation if the threat is severe.

### 11.2 Data poisoning detection

Detection: drift in feature distributions; per-class accuracy
regression; behavioral test failure.

Containment:
- Stop the retraining pipeline.
- Roll back the most recent model promotion.
- Preserve the suspect training data.

Investigation:
- Who submitted the suspect data?
- What's the blast radius (how many models are affected)?
- Is this targeted (specific class boost) or untargeted?

Recovery:
- Re-train from clean data.
- Promote validated clean model.
- Customer communication if predictions were affected.

### 11.3 Prompt-injection / LLM harm incident

Detection: classifier flags + customer report.

Containment:
- Block the affected prompt pattern.
- Notify the affected customer if a specific tenant.
- Preserve logs.

Investigation:
- How was the injection delivered (direct vs. indirect)?
- What was the impact (data exposed, action taken)?
- Are other prompts in the wild?

Recovery:
- Update safety filters.
- Update tool authorization to prevent similar.
- Customer communication if applicable.

### 11.4 Customer-data exfiltration via ML

Detection: outbound anomaly in serving pod; audit-chain
anomaly.

Containment + investigation + recovery: standard data-breach
patterns + ML-specific provenance queries.

This is the case where Module 07's GDPR / HIPAA / SOC 2
timelines kick in — the 72-hour GDPR clock starts when you
become aware.

---

## 12. Metrics that matter

Beyond MTTD / MTTR:

| Metric | What it tells you |
|---|---|
| **Detection coverage** | % of MITRE ATLAS tactics with at least one detection |
| **Alert FPR** | % of alerts that are false positives |
| **Mean time to triage** | time from page to "real or not" decision |
| **Postmortem follow-through** | % of action items closed on time |
| **Drill cadence** | tabletops + game days run on schedule |
| **Detection-rule freshness** | % of rules updated in past 90 days |

These are leading indicators. MTTD / MTTR are lagging.

---

## 13. Operating SecOps at SmartRecs scale

A 6-engineer team can't run a 24/7 SOC. The realistic posture:

### 13.1 Day 1

- Elastic / Datadog Cloud SIEM with high-value sources (k8s
  audit, Falco, Cilium Hubble, audit chain).
- A small set of detection rules — 10-20, focused on the
  highest-leverage threats.
- On-call rotation with PagerDuty.
- Runbooks for the 5 most-likely incident classes.

### 13.2 Day 30

- Tune rules to <5 actionable pages per week per on-call.
- Quarterly tabletop scheduled.
- Postmortem template + first real run-through.
- MITRE ATLAS mapping of detection coverage.

### 13.3 Day 90

- Detection rule library (50+ rules) with full ATLAS coverage.
- Quarterly drill + annual game day.
- Threat-intel integration (CISA + MITRE ATLAS feeds).
- Customer-facing security communication template.

### 13.4 What you don't need at SmartRecs scale

- 24/7 dedicated SOC.
- Commercial threat-intel platform.
- Sophisticated UEBA.
- Full forensic-acquisition capability (lawyer-grade
  chain-of-custody).

When you reach 50+ engineers: time to revisit.

---

## 14. What you should be able to do after this module

- [ ] Evaluate SIEM options for an ML platform.
- [ ] Author a Sigma detection rule with MITRE ATLAS / ATT&CK
      mapping.
- [ ] Triage a Critical alert from acknowledge to containment
      decision.
- [ ] Run a tabletop exercise as facilitator.
- [ ] Write a blameless postmortem.
- [ ] Identify the four core ML-specific detection categories
      and write one rule for each.
- [ ] Calibrate alert severity to actual response cost.
- [ ] Operate an on-call rotation sustainably.

---

## 15. What this module deliberately doesn't cover

- **Specific SIEM product training** (Splunk SPL deep dive,
  KQL fluency) — buy a course.
- **Incident-response certifications** (GCIH, GCFA) — outside
  the scope.
- **Legal and regulatory IR specifics** — work with counsel.
- **Generic enterprise SOC operations** — not the SmartRecs
  scale.

---

## 16. Suggested reading order

After this:

1. Read [MITRE ATLAS](https://atlas.mitre.org/) carefully if
   you haven't.
2. Skim a [Sigma rules library](https://github.com/SigmaHQ/sigma)
   to see real rules.
3. Read NIST SP 800-61 (incident handling).
4. Move to **Module 12: Capstone**.

---

## Appendix A — Glossary

- **IC**: Incident Commander.
- **IR**: Incident Response.
- **IOC**: Indicator of Compromise.
- **ISAC**: Information Sharing and Analysis Center.
- **MTTD**: Mean Time To Detect.
- **MTTR**: Mean Time To Respond / Resolve.
- **MTTI**: Mean Time To Investigate.
- **Postmortem**: documented analysis of an incident.
- **RCA**: Root Cause Analysis.
- **SecOps**: Security Operations.
- **Sigma**: a generic detection-rule format.
- **SIEM**: Security Information and Event Management.
- **SOAR**: Security Orchestration, Automation, and Response.
- **SOC**: Security Operations Center.
- **TTP**: Tactics, Techniques, Procedures.
- **UEBA**: User and Entity Behavior Analytics.

---

## Appendix B — Common misconceptions

| Misconception | Reality |
|---|---|
| "We have alerts; we have SecOps." | Alerts that aren't triaged aren't SecOps. The discipline is the triage and response, not the alerting. |
| "We don't need IR procedures; we'll figure it out." | Mid-incident is the worst time to design IR. Pre-write. |
| "MTTR < 4 hours is good." | MTTR is a number with context. 4 hours might be excellent for some incident classes, terrible for others. |
| "More alerts = more security." | More alerts = more noise. Better-targeted alerts = more security. |
| "Postmortems should assign blame so people learn." | Blame culture suppresses honest reporting. Blameless postmortems produce better systemic learning. |
| "Our SIEM has everything." | SIEMs have what you fed them. The integration work is most of the SIEM value. |
| "Threat intel is for big-budget teams." | CISA and ATLAS are free. The discipline of operationalizing them is what matters, not the dollar amount spent. |

---

*Continue to the [exercises](./exercises/) when you're ready.*
