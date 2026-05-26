# Exercise 03 — IR Procedure for ML Threats

**Estimated time**: 2–3 hours
**Deliverable**: IR procedure document + 5 playbooks

---

## The assignment

Produce SmartRecs' IR procedure plus 5 detailed playbooks for
the most likely incident classes.

## Part 1 — The IR procedure (overarching)

Cover:

1. **Roles and responsibilities**
   - Incident Commander (IC) — who, how appointed.
   - Communications lead.
   - Technical responders.
   - Stakeholder liaison.

2. **Severity classification**
   - SEV1 / SEV2 / SEV3 with clear criteria.
   - How severity affects response.

3. **Phases**
   - Detection → Triage → Containment → Investigation →
     Eradication → Recovery → Post-incident.
   - Time bounds for each.

4. **Communication structure**
   - Internal coordination channel.
   - Stakeholder updates.
   - External communication (customer, regulatory).

5. **Tools and access**
   - SIEM queries.
   - Audit-chain queries.
   - Containment tools (kubectl cordon, IAM revoke, etc.).
   - Communication tools.

6. **Regulatory clocks**
   - GDPR 72h.
   - HIPAA 60-day.
   - SOC 2 (customer-impact disclosures).
   - When the clock starts; who decides.

## Part 2 — Five playbooks

Each playbook follows the structure from Module 08's
container-escape runbook. Cover:

### Playbook 1: Suspected model extraction
(Detection from the per-tenant query rate spike rule from
Exercise 02.)

### Playbook 2: Suspected data poisoning
(Detection from the training-data distribution shift rule.)

### Playbook 3: Confirmed LLM prompt-injection harm
(Customer reports the LLM took a harmful action; or output
filtering caught a clear injection.)

### Playbook 4: Customer-data exfiltration from ML pipeline
(Hubble flow anomaly + audit-chain anomaly.)

### Playbook 5: Container escape from training pod
(Falco container-escape alert.)

For each, the playbook covers detection → containment →
investigation → eradication → recovery → communication → post-
incident.

## Format

```
# SmartRecs IR Procedure

## Overview

## Roles
| Role | Responsibilities | Authority |
|---|---|---|

## Severity classification
| Severity | Criteria | Response time | Comm requirements |
|---|---|---|---|

## Phases and time bounds

## Communication structure

## Tools and access

## Regulatory clocks

---

## Playbook 1: Suspected model extraction

### Detection sources
### Triage steps
### Containment
### Investigation
### Eradication
### Recovery
### Communication
### Post-incident

## Playbook 2: ...
## Playbook 3: ...
## Playbook 4: ...
## Playbook 5: ...
```

## Quality criteria

A passing procedure:

- Roles are **named** with authority bounds.
- Severity classification has **objective criteria**.
- Each playbook is **specific** — commands, not abstractions.
- Regulatory clocks are addressed with the start condition
  named.

A failing procedure:

- "The on-call decides" without criteria.
- Playbooks of the form "investigate, fix, communicate."
- No regulatory-clock awareness.
- No tools / access section.

## Reflection questions

1. Which playbook will the team need most often?
2. Which playbook is most likely to be **executed wrong** the
   first time? How do you mitigate?
3. The IR procedure is a living document. Who owns updates,
   and on what cadence?
