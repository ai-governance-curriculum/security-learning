# Exercise 01 — Regulatory Applicability Matrix

**Estimated time**: 2 hours
**Deliverable**: A 2-page matrix + analysis

---

## The scenario

SmartRecs has the following situation:

- HQ in San Francisco (US).
- Customers: 60% US, 30% EU, 10% rest-of-world.
- Customer mix includes:
  - Consumer e-commerce (no PHI).
  - A healthcare network (PHI flowing into the system).
  - One EU government department (regulated personal data).
- ML workloads:
  - Recommender (consumer data).
  - Fraud-detection (some PII for authorization).
  - New customer-support LLM (Module 06 scenario).
- Engineering: 6 engineers, no dedicated compliance staff.
- Plans: pursuing SOC 2 Type 2 (customer-driven), exploring
  HIPAA, watching EU AI Act.

## The assignment

Produce a regulatory applicability matrix that:

1. Lists every potentially-applicable regulation / framework.
2. Identifies which **specifically apply** to SmartRecs (with
   reasoning).
3. For each that applies, identifies:
   - The triggering activity / data.
   - The high-level obligations.
   - The current state vs. compliant state.
   - The owner (legal, engineering, security, or shared).
   - Effort estimate to reach compliant state.
4. Identifies the regulations / frameworks that do **not**
   apply (with a one-sentence reason).
5. Identifies regulations that will likely apply in the next 18
   months (EU AI Act phases, new state privacy laws, etc.).

## Regulations / frameworks to consider

At minimum:
- GDPR.
- CCPA / CPRA.
- HIPAA.
- SOC 2 (Trust Services Criteria).
- EU AI Act.
- ISO 27001.
- ISO 42001.
- NIST AI RMF.
- PCI DSS.
- FedRAMP.
- State-level US privacy laws (CO, VA, CT, UT, TX, etc.).

## Format

```
# Regulatory Applicability Matrix: SmartRecs

## Context summary

## Currently applicable

| Regulation | Triggered by | Current state | Compliant state | Owner | Effort |
|---|---|---|---|---|---|

## Watch list (likely within 18 months)

| Regulation | Trigger condition | When to act |
|---|---|---|

## Not applicable (with reason)

| Regulation | Why not |
|---|---|

## Analysis

### Priority for the next quarter
### Resource gaps
### Open questions for legal counsel
```

## Quality criteria

A passing matrix:

- Each applicability decision is **defended** — not just "yes /
  no" but the reason.
- Identifies at least one regulation that's currently
  applicable that the team has likely overlooked.
- Flags the EU AI Act watch — even if not yet binding for
  SmartRecs.
- Identifies HIPAA applicability via the healthcare customer
  (PHI flows through the system).
- Acknowledges where engineering can't decide alone (legal
  judgment calls).

A failing matrix:

- "GDPR: applicable" with no reasoning.
- Misses HIPAA because "we don't directly serve patients."
- Treats SOC 2 as a regulation (it's a framework).
- No watch list (everything compliance-relevant gets caught
  too late).

## Reflection questions

1. Which regulation, if it applied surprisingly, would have the
   largest engineering impact?
2. The team objects: "We're too small for all of this." Defend
   keeping the matrix anyway. What's the cost of not having it?
3. Which item in the watch list deserves the most preparation
   investment now?
