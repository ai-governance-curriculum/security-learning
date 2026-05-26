# Exercise 03 — SOC 2 Readiness Assessment

**Estimated time**: 2 hours
**Deliverable**: A gap-list + 90-day readiness plan

---

## The setup

SmartRecs has 90 days until its SOC 2 Type 2 audit period
begins. The team is partway through several controls:

- ✅ Encryption at rest (KMS-backed, on all production
  datastores).
- ✅ Encryption in transit (TLS 1.3 on customer-facing
  endpoints; TLS 1.2 for internal; some non-mesh services still
  plaintext).
- ✅ Access controls (RBAC in Kubernetes; some shared service
  accounts).
- ✅ Logging (Loki for application logs; no central audit
  chain).
- ⚠ Change management (PRs are reviewed but no enforced
  approver requirements; ~40% have approval evidence in audit).
- ⚠ Incident response plan exists; one tabletop run in the past
  year; no formal post-incident reviews documented.
- ❌ Vendor risk reviews — informal; no documented process.
- ❌ Continuous control monitoring — manual quarterly checks.
- ❌ Risk assessment — last formal one was 18 months ago.
- ❌ Pen test — none in the past year.
- ❌ Access reviews — ad-hoc; no quarterly cadence.

Target: **Security** + **Confidentiality** criteria.

## The assignment

Produce a SOC 2 readiness assessment:

1. **Gap analysis** — control-by-control state with severity.
2. **Prioritized 90-day plan** — what to ship, in what order.
3. **Evidence strategy** for each gap — what gets logged,
   where.
4. **Residual risks** — what remains after 90 days.
5. **Auditor-facing artifacts** — what to prepare for the
   eventual audit.

## Specific controls to address (minimum)

Cover these in the gap analysis:

- Access control (provisioning, deprovisioning, review).
- Change management (deploy approvals, evidence retention).
- Encryption (at rest, in transit, in use where applicable).
- Logging and monitoring (audit-log production, retention,
  alerts).
- Backup and DR.
- Incident response (plan, training, drills, post-incident
  review).
- Risk assessment.
- Vendor risk management.
- Asset inventory.
- Personnel security (background checks, training,
  termination).
- Continuous control monitoring.

## Format

```
# SOC 2 Readiness Assessment: SmartRecs

## Audit scope
- Trust Services Criteria
- Audit period
- Trusted system description

## Gap analysis (table)

| Control | Current state | Gap | Severity | Effort |
|---|---|---|---|---|

## Prioritized 90-day plan

### Days 1-30 (Foundation)
- Deliverable 1
- Deliverable 2

### Days 31-60 (Coverage)
...

### Days 61-90 (Continuous evidence)
...

## Evidence strategy per control

| Control | Evidence | Source | Retention |
|---|---|---|---|

## Residual risks after 90 days
(Honest list of what's still incomplete.)

## Auditor-facing prep

### Statement of Applicability draft
### System Description draft
### Management Assertion draft
```

## Quality criteria

A passing assessment:

- Each control has a **current state**, a **gap**, and a
  **severity**.
- 90-day plan is sequenced — foundation work before
  continuous-evidence automation.
- Evidence strategy is **specific** — not "log it" but "weekly
  TLS scan, results in `audit/tls-scan/<date>`."
- Residual risks are named honestly. A clean "no residuals"
  answer is overclaiming.

A failing assessment:

- Marks everything green.
- "Implement monitoring" without specifying what or where.
- No sequencing — treats all controls as equally urgent.
- No auditor-facing prep section.

## Reflection questions

1. Which control will the team push back on most? How do you
   justify the priority?
2. Which gap, if not closed, would be the most likely to
   produce an audit finding?
3. The board asks: "Can we delay the audit by a quarter?"
   What's the cost-benefit?
