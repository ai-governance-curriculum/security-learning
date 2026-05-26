# Exercise 04 — Continuous Compliance Design

**Estimated time**: 2 hours
**Deliverable**: An architecture document + evidence-generation
inventory

---

## The assignment

Design SmartRecs' **continuous compliance** infrastructure: how
evidence is generated, signed, stored, queried, and presented to
auditors *without* a panic week before every audit.

## What the design must cover

1. **Audit-chain integration**. Module 03's hash-chain audit
   log is the substrate. Design which events go in, who signs,
   and how to query.
2. **Per-control evidence streams**. For each major control
   class, where the evidence is produced and how it's
   collected.
3. **Continuous control monitoring**. Automated checks that
   verify control operation and produce evidence directly.
4. **Compliance dashboards**. What an engineer / auditor sees
   when looking at "how are we doing?"
5. **Evidence retention** policy aligned with each
   regulation's expectations.
6. **The "build vs. buy" decision** between building this
   yourself with OPA + audit chain vs. using Drata / Vanta /
   Secureframe.

## Required: at least 10 controls with evidence design

For each, specify:

- **Control name** (e.g., "Encryption in transit").
- **Regulatory mapping** (which SOC 2 / GDPR / HIPAA item it
  satisfies).
- **Evidence type** (log entry, scan result, sign-off record,
  metric).
- **Evidence producer** (which workload, when).
- **Evidence consumer** (audit-chain entry, dashboard,
  exported report).
- **Retention** (per regulation: GDPR 6 years, HIPAA 6 years,
  SOC 2 audit period + 1 year typical).
- **Anomaly alert** (when does the absence of evidence trigger
  an alert?).

## Format

```
# Continuous Compliance Design: SmartRecs

## Architecture

(Diagram: evidence producers → audit chain → consumers /
dashboards / exports.)

## Evidence streams (10+ controls)

| Control | Mapping | Producer | Type | Audit chain entry | Retention | Anomaly alert |
|---|---|---|---|---|---|---|

## Continuous control monitoring rules

(Examples — actual rego or pseudo-rules.)
- Rule 1: TLS 1.3 enforced on every public endpoint
- Rule 2: Every model promotion has signed approval
- Rule 3: ...

## Compliance dashboards

### For engineering
### For executives
### For auditors during their engagement

## Evidence retention

| Regulation | Retention period | Source of truth |
|---|---|---|

## Build vs. buy decision

### Build (OPA + audit chain) — cost, time, ownership
### Buy (Drata / Vanta / Secureframe) — cost, time, dependency

### Recommendation for SmartRecs

## Migration plan
(From current ad-hoc to continuous; phased.)

## What this still doesn't cover
(Things automation can't do: tabletops, risk assessment
judgment, etc.)
```

## Quality criteria

A passing design:

- The audit-chain integration is **specific** — names the
  entry types, signing identities, query patterns.
- At least 10 controls with full evidence design.
- The build-vs-buy decision is **defended** for SmartRecs'
  specific context.
- Acknowledges what continuous compliance **doesn't** do.

A failing design:

- "Send everything to the audit chain" without specifying
  entry structures.
- Generic build-vs-buy "depends on the team" with no decision.
- Treats compliance dashboards as "a Grafana dashboard."

## Reflection questions

1. Which control is hardest to instrument? Why?
2. The team objects: "Drata is $20k/year; we should build it."
   Argue both sides — when is building justified?
3. If you had to cut the evidence retention to half the
   regulatory minimum, which controls would you trim and why?
