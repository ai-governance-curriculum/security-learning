# Exercise 02 — GDPR Controls Implementation Plan

**Estimated time**: 2–3 hours
**Deliverable**: A 3-page plan + a DPIA-style outline for one model

---

## The assignment

For SmartRecs (the EU customer mix from Exercise 01 makes GDPR
binding), produce an implementation plan covering:

1. **Subject-rights API** — endpoint design for access,
   rectification, erasure, portability, restriction, objection,
   automated-decision-related rights (Art 22).
2. **Lawful basis catalog** — per-purpose, per-dataset.
3. **DPIA process** — when triggered, who runs it, the
   template.
4. **Cross-border transfer mechanism** — for data flows to your
   US infrastructure from EU customers.
5. **Breach response** — the 72-hour clock, who decides,
   notification templates.
6. **Records of Processing Activities (Art 30)** — what they
   contain.

For the DPIA portion: produce a worked DPIA-style outline for
the **fraud-detection model**. (DPIAs are required for
high-risk processing; ML models making decisions affecting
people typically qualify.)

## Format

```
# GDPR Controls Implementation Plan: SmartRecs

## Subject-rights API

### Endpoint design
| Right | Endpoint | Input | Output | SLA |
|---|---|---|---|---|

### Implementation notes
(How the API integrates with the audit chain, model registry,
feature store, etc. Reference the Module 03 Project 4
governance code.)

### What gets erased on Art 17 request
- Feature-store records: <approach>
- Audit-log entries: <not deleted, but marked>
- Trained models: <interpretation: ...>
- Backups: <retention windows>

## Lawful basis catalog

| Dataset / processing | Lawful basis | Rationale |
|---|---|---|

## DPIA process

### Triggers
### Template
### Workflow (who, when, how)

## Cross-border transfer

### Mechanism (SCCs, DPF)
### Implementation
### Documentation

## Breach response

### Detection sources
### Decision authority (who calls "this is a breach")
### 72-hour communication template
### Sub-72-hour internal escalation

## Records of Processing Activities

### Format
### Maintenance cadence
### Ownership

---

# DPIA Outline: Fraud-Detection Model

## 1. Description of processing
## 2. Necessity and proportionality
## 3. Risks to data subjects
## 4. Measures to address risks
## 5. Consultation (DPO, affected stakeholders)
## 6. Sign-off
```

## Quality criteria

A passing plan:

- The subject-rights API has **concrete endpoints** with
  inputs/outputs/SLAs.
- Erasure (Art 17) is addressed honestly — including the
  "trained model" complication.
- The DPIA outline addresses the **specific** fraud-detection
  model, not generic ML risks.
- The breach response timeline is realistic and includes
  internal escalation, not just external notification.

A failing plan:

- Generic "implement subject rights" without endpoint design.
- Claims erasure removes data from trained models.
- DPIA outline is a template with no specifics filled in.

## Reflection questions

1. The erasure-of-training-data problem doesn't have a clean
   solution. What's the most defensible interpretation, and
   what would you tell a regulator who asked?
2. The team objects: "Subject requests will take forever to
   service." What's the engineering solution that makes them
   fast?
3. Which DPIA risk is hardest to mitigate? What residual risk
   do you accept, and how do you document it?
