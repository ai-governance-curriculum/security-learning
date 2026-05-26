# Capstone Exercise 01 — Threat Model + Risk Register

**Estimated time**: 5 hours
**Deliverable**: A 6-10 page combined document

---

## The assignment

Produce NorthBridge Health's foundational security artifact: a
threat model + regulatory applicability + prioritized risk
register. This is the document that drives every later
capstone deliverable.

## What the deliverable must include

### Section A: System inventory

For each of the 5 production ML systems (Triage-Risk,
HAI-Predict, Med-Verify, Ambient-Doc, Wellness-Coach):

- The data it touches (PHI? PII? Aggregated only? EU
  residents?).
- The customers it serves.
- The clinical impact if it fails (life-safety / care-quality /
  operational / consumer).
- The architectural surface (training, serving, inference
  data, output).

### Section B: STRIDE+ML threat model

Apply Module 01 STRIDE+ML to NorthBridge. Each of the 6 STRIDE
categories + the 3 ML-specific categories gets concrete
threats:

- Spoofing — for each system.
- Tampering — for each system.
- Repudiation — for clinical decisions especially.
- Information disclosure — heavy for PHI / PII.
- Denial of service — including inference-cost amplification.
- Elevation of privilege — multi-tenant boundary risks.
- Model quality degradation.
- Fairness regression.
- Decision authority overreach.

For each cell, name **specific** threats to **specific**
NorthBridge systems.

### Section C: Regulatory applicability matrix

Reuse the Module 07 Exercise 01 pattern. For each regulation:

- HIPAA.
- GDPR.
- EU AI Act.
- SOC 2 (Security + Confidentiality).
- CCPA / state US privacy laws.
- (Watch list: ISO 42001, FDA's emerging AI/SaMD guidance.)

For each: applicable? triggering activity? high-level
obligations? current gap? owner? effort to close?

### Section D: Risk register

The prioritized list. For each risk:

- Risk ID + name.
- Affected systems.
- Likelihood (with reasoning).
- Impact (life-safety / regulatory / financial / reputational).
- Severity (Critical / High / Medium / Low).
- Current mitigations.
- Required mitigations.
- Owner.
- Target date.

### Section E: Top 10 risks discussion

For the top 10 risks: 1-paragraph each explaining:

- Why this is at this rank.
- What's the worst-case outcome.
- What the first mitigation step is.

## Quality criteria

A passing exercise:

- **All 5 production systems** are inventoried specifically.
- **STRIDE+ML threats** are NorthBridge-specific (not generic).
- **All 5 regulations** addressed; EU AI Act high-risk
  classification is correct.
- **Risk register has 20+ named risks** with defended
  prioritization.
- **Top 10 discussion** survives expert questioning.

A failing exercise:

- Generic threats not tied to NorthBridge specifics.
- EU AI Act mentioned without classification.
- 5-10 risks (too few to be useful).
- Prioritization is alphabetical or by area, not by impact.

## Reflection questions (don't submit, but answer for yourself)

1. Which risk is most likely to **block a hospital customer
   renewal** today?
2. Which risk is most likely to cause **patient harm**?
3. Which risk is most likely to produce a **regulatory fine**?
4. Which risk's mitigation has the **lowest cost per unit risk
   reduced**?
5. Which risk would you be most **professionally accountable
   for** if it materialized?

## How this artifact gets used

- **Exercise 02**: the threat register drives the architectural
  controls.
- **Exercise 03**: ML-specific risks drive the adversarial
  defense plan.
- **Exercise 04**: regulatory risks drive the compliance
  roadmap.
- **Exercise 05**: residual risks drive the detection
  ruleset.
- **Exercise 06**: the top risks become the CFO + customer-
  facing risk narrative.

## Time budget

- System inventory: 30 min.
- STRIDE+ML threat model: 90 min.
- Regulatory applicability: 60 min.
- Risk register: 90 min.
- Top 10 discussion: 30 min.

If you're under 4 hours when "done," it's too shallow.
