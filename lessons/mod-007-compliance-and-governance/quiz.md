# Module 07 Quiz — Compliance and Governance

> Closed-book first.

---

## Conceptual (10 questions)

### Q1
The lecture argues "compliance is evidence-driven" (§1).
Explain what this means in 3 sentences. Give one example of a
control that exists in policy but fails an audit due to lack
of evidence.

### Q2
Why does the principle of **purpose limitation** (GDPR Art 5)
strain ML systems specifically? Give one realistic scenario
where this becomes operational tension.

### Q3
For each GDPR subject right below, name the engineering control
that implements it:
- Right to access.
- Right to erasure.
- Right to data portability.
- Right not to be subject to automated decision-making.

### Q4
Explain why **erasure** is fundamentally hard for ML training
data, in 4-6 sentences. What's the practical compliance
interpretation most teams adopt?

### Q5
Compare SOC 2 Type 1 and Type 2. Which do enterprise customers
typically expect, and why?

### Q6
The EU AI Act categorizes AI systems by risk. For each scenario,
identify the likely risk tier:
- (a) A spam-filter model.
- (b) A model that recommends candidates to interviewers.
- (c) A chatbot for general customer support.
- (d) A model used in critical-infrastructure (energy grid)
  decisions.
- (e) A model that determines credit-approval thresholds.

### Q7
HIPAA's Security Rule is described as "flexible." What does
that mean operationally — how does it differ from a
prescriptive standard like PCI DSS?

### Q8
NIST AI RMF organizes work into four functions (§7.1). Name
them. For each, give one ML-system-specific activity that fits.

### Q9
Vendor risk is part of your compliance posture (§10). For each
vendor type, describe one risk it introduces:
- A foundation-model API vendor (OpenAI, Anthropic).
- An observability vendor (logs may contain user data).
- A CI/CD platform vendor.
- A cloud provider.

### Q10
The lecture argues "compliance ≠ security" (§11). Give two
concrete examples:
- (a) A control that passes audit but doesn't address a real
  threat.
- (b) A control that addresses a real threat but doesn't map
  to any audit framework.

---

## Applied (5 questions)

### Q11
SmartRecs is preparing for SOC 2 Type 2. The audit period
starts in 60 days. The team has implemented most controls in
their security program but evidence collection is ad-hoc.
Produce a **prioritized 60-day readiness plan** that covers:
- The 5 highest-impact gaps to close.
- The evidence collection automation each requires.
- The risk if any single item is not addressed.

### Q12
A new SmartRecs customer asks: "Are you GDPR-compliant?"
The product team wants to say "yes." The CISO wants to be
honest. Draft a response that:
- (a) Is defensible to the customer's CISO.
- (b) Doesn't overpromise.
- (c) Identifies what's in place and what's in progress.
- (d) Names the contractual mechanism (DPA, SCCs) needed.

### Q13
Design the **audit-chain entries** for the following events,
including required fields and signing identity:
- A subject erasure request (GDPR Art 17).
- A model promotion to production.
- A vendor sub-processor addition.
- A failed authentication attempt to the production API.
- A network-policy change to a critical namespace.

### Q14
The EU AI Act is in force. A SmartRecs feature predicts whether
to extend credit limits to existing customers. Walk through:
- (a) The likely risk classification.
- (b) The Article 9 (risk management) implications.
- (c) The Article 15 (accuracy / robustness / cybersecurity)
  obligations.
- (d) The Article 14 (human oversight) implementation.
- (e) The technical documentation Article 11 requires.

### Q15
A new OpenAI integration is being proposed for SmartRecs:
customer prompts containing PII will be sent to GPT-4. Conduct
the vendor risk review:
- (a) The data-flow analysis.
- (b) The regulations triggered (GDPR, HIPAA, sector-specific).
- (c) The contract terms needed (DPA, BAA, SCCs).
- (d) The technical controls needed (PII redaction, audit).
- (e) The decision: approve, modify, or reject.

Defend the decision in writing.

---

## Self-assessment rubric

Same as previous modules. Passing: average ≥ 2.0, no question
scored 0.
