# Exercise 04 — Governance Obligation to Security-Engineering Deliverable

**Estimated effort:** ~2 hours
**Deliverable:** One Markdown document containing a governance-to-
engineering crosswalk table + two enforcement stubs
**Prerequisite:** Chapter 04 read end-to-end; the outputs from
Exercises 01–03 available for cross-reference

---

## Objective

Translate a set of governance obligations from NIST AI RMF 1.0,
ISO/IEC 42001:2023, and EU AI Act Articles 9–15 into concrete
security-engineering deliverables for the fintech system. The
output is the row shape from chapter 04 §"The deliverable pattern":
obligation → security-engineering artifact → enforcement mechanism.

## Problem statement

Continue with the same fintech LLM-agent-plus-fraud-classifier
system. The head of AI governance (level 60) at your organisation is
preparing a briefing for the CISO and Legal. They need to be able to
say, for each of the following obligations, "we have engineering
evidence, here it is." Currently the answer for several of them is
"we have a policy."

You are asked to produce the crosswalk that turns the policy answer
into an engineering answer.

## The obligation set

Cover every row in the table below. Do not add extra rows in a first
pass; the exercise is about depth, not breadth.

| # | Framework | Identifier | Paraphrased obligation |
| --- | --- | --- | --- |
| 1 | NIST AI RMF 1.0 | GOVERN 3.1 (roles / accountability) | Roles and responsibilities for AI risk management are established, documented, and communicated. |
| 2 | NIST AI RMF 1.0 | MAP 5.1 (impacts / risks mapped) | Likelihood and magnitude of each identified risk are estimated. |
| 3 | NIST AI RMF 1.0 | MEASURE 2.7 (security / adversarial testing) | AI system security and resilience are evaluated and documented. |
| 4 | NIST AI RMF 1.0 | MANAGE 4.1 (post-deployment monitoring) | Post-deployment risk-management activities are integrated into the operating environment. |
| 5 | ISO/IEC 42001:2023 | Clause 8 (Operation) | The organisation plans, implements, and controls the processes needed to meet AI-management-system requirements. |
| 6 | ISO/IEC 42001:2023 | Clause 9 (Performance evaluation) | The organisation evaluates the AI system's performance, effectiveness of controls, and conformity. |
| 7 | EU AI Act | Article 9 (risk management system) | A documented, iterative risk-management system is established across the lifecycle of a high-risk AI system. |
| 8 | EU AI Act | Article 10 (data and data governance) | Training, validation, and testing datasets meet quality criteria; data-governance practices are documented. |
| 9 | EU AI Act | Article 12 (record-keeping / automatic logs) | The AI system technically allows for automatic recording of events during operation. |
| 10 | EU AI Act | Article 14 (human oversight) | The AI system is designed to be effectively overseen by natural persons during use. |
| 11 | EU AI Act | Article 15 (accuracy, robustness, cybersecurity) | The AI system achieves an appropriate level of accuracy, robustness, and cybersecurity. |

Confirm each identifier against the primary source before finalising
your deliverable — sub-category numbering and article language have
been revised in some releases.

## Requirements

Produce a Markdown document with the following two sections.

### Section 1 — Crosswalk table

One row per obligation in the table above. Columns:

| Column | Requirement |
| --- | --- |
| Obligation | Framework + identifier, one-sentence paraphrase, primary-source URL. |
| Owner | Who owns the obligation top-level (this role, peer, level 50, level 60, Legal, etc.). |
| Security-engineering artifact | The specific file, dashboard, log, policy, or run-log that satisfies the obligation. If the obligation's *security* slice does not exist in your Exercise 01–03 outputs, name the ticket to create the artifact. |
| Enforcement mechanism | Admission-time policy? Release gate? Runbook? Quarterly review? Which specific automation or ceremony makes the artifact non-optional. |
| Cross-reference | The OWASP row (Ex. 01), the ATLAS technique (Ex. 02), and/or the NIST 100-2 vocabulary tag (Ex. 03) that the artifact carries. |

An obligation whose engineering slice is genuinely out of scope for
this role (e.g., a fairness-metric obligation) should be marked with
the correct owner (`ai-risk-engineer`, `ai-evaluation-engineer`, or
Legal) rather than skipped, and the handshake handoff should be
named.

### Section 2 — Two enforcement stubs

Pick two rows from the crosswalk where the enforcement mechanism is
an **admission-time policy** or a **release-gate check**. For each,
produce a pseudo-policy stub — you are not implementing production
Rego or Gatekeeper policy; you are showing what the policy inspects
and rejects.

Example shape (for one of the two you choose):

```rego
# Pseudo-policy — illustrative, not a runnable Rego module.
# Purpose: enforce EU AI Act Article 15 robustness evidence at
# admission time.
package ai_ml_security.article_15_robustness

deny[msg] {
    input.model.risk_tier == "high"
    not input.model.evidence.adversarial_training_report
    msg := "high-risk model missing adversarial-training report"
}

deny[msg] {
    input.model.risk_tier == "high"
    input.model.evidence.adversarial_training_report.attack_family != "PGD"
    msg := "adversarial-training report must include PGD attack family"
}

deny[msg] {
    input.model.risk_tier == "high"
    input.model.evidence.adversarial_training_report.epsilon_max < 8/255
    msg := "adversarial-training report must include ε ≥ 8/255"
}
```

Each stub must:

- Name the obligation it enforces.
- Name the evidence fields it inspects.
- Show the rejection reasons in plain English.
- Note the false-positive shape (obligations for which the policy
  might reject a legitimate model — e.g., an experimental
  low-risk-tier model).

### Section 3 — One paragraph on the interface with the peer

Explain, in one paragraph, how the Section 1 crosswalk is consumed
by your peer `ai-evaluation-engineer` (level 35). What is the shape
of the handoff — a per-release evidence bundle, a control-library
sync, a quarterly review meeting? Which artifacts move; which
artifacts stay in the security-team registry?

## Starter guidance

- Chapter 04's per-framework sections are the reference for each
  obligation. Reread the section for a framework before writing
  its rows.
- Do not restate the obligation's language as if that were the
  deliverable. The obligation is the input; the artifact is the
  output.
- Article 15 is the *operative* article for this role. Two rows in
  your crosswalk should ideally map to Article 15 (accuracy,
  robustness — one; cybersecurity — one).
- Article 14 (human oversight) is where LLM06:2025 Excessive Agency
  from Exercise 01 shows up. Cross-reference explicitly.
- Verify article numbering against
  [EUR-Lex 2024/1689](https://eur-lex.europa.eu/eli/reg/2024/1689/oj)
  before quoting.

## Acceptance criteria

A passing crosswalk:

- One row per obligation.
- Every artifact is named specifically, not "documented process."
- Every enforcement mechanism is a named automation or ceremony.
- Every cross-reference cites at least one Exercise 01–03 output
  where the artifact lives.

A passing enforcement stub:

- Names the obligation.
- Inspects specific evidence fields.
- Shows the rejection reasons and the false-positive shape.

A failing deliverable:

- Restates the framework's language in the artifact column.
- Uses "policies and procedures" as the artifact.
- Uses "compliance review" as the enforcement without naming what
  the review checks.
- Skips the peer-interface paragraph — the interface is the point.

## Stretch goals

- Extend the crosswalk with three sector-reg rows: one from the
  HIPAA Security Rule (technical safeguard), one from SR 11-7 (model
  risk management), and one from the EU Cyber Resilience Act. Use
  the same row shape.
- For one Article 15 sub-obligation, chase the artifact all the way
  from the training-pipeline hook to the release gate: which code
  runs, which config produces the evidence, which registry stores
  it, which policy inspects it.
- Sketch a machine-readable version of the crosswalk (YAML/JSON) —
  the shape a future control-library ingest would consume.

## Do not

- Do not skip Article 15. It is the operative article for the role.
- Do not treat obligations you consider "governance-only" as out of
  scope. The whole point of this exercise is that they are not.
- Do not commit a solution — solutions live in the paired solutions
  repo.
