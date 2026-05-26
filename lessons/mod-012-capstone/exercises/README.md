# Capstone Exercises

Six exercises producing the capstone portfolio. Work them in
order; each builds on the prior.

| # | Exercise | Output | Time |
|---|---|---|---|
| 1 | [Threat model + risk register](./exercise-01-threat-model-and-risk-register.md) | STRIDE+ML + regulatory + prioritized register | 5 h |
| 2 | [Security architecture](./exercise-02-security-architecture.md) | Zero-trust + crypto + network + secrets | 6 h |
| 3 | [ML-specific controls](./exercise-03-ml-specific-controls.md) | Adversarial + privacy + LLM safety + provenance | 5 h |
| 4 | [Compliance + policy program](./exercise-04-compliance-and-policy.md) | SOC 2 + HIPAA + EU AI Act + policy-as-code | 5 h |
| 5 | [SecOps program](./exercise-05-secops-program.md) | Runtime + SIEM + IR + tabletop schedule | 5 h |
| 6 | [Stakeholder communication portfolio](./exercise-06-stakeholder-portfolio.md) | CFO brief + engineer README + customer CISO + EU AI Act doc | 4 h |

Total minimum: 30 hours. Realistic for quality: 50+ hours.

## Working notes

- Read [`../scenario-brief.md`](../scenario-brief.md) twice
  before starting.
- Each exercise's deliverable is a substantial document —
  expect 5-15 pages per exercise (depends on diagrams /
  tables).
- Don't optimize for "completed exercises." Optimize for
  artifacts you'd be proud to send to a hiring manager.

## Synthesis loop

The artifacts compose:

```
Ex 01 (threats) → Ex 02 (architecture) → Ex 03 (ML controls)
                                                 ↓
                                          Ex 04 (compliance)
                                                 ↓
                                          Ex 05 (SecOps)
                                                 ↓
                                          Ex 06 (communication)
```

When you finish Ex 06, return to Ex 01 with the
audience-targeted summaries — the threat register often needs
updates to be CFO-readable. Capstone work is iterative.
