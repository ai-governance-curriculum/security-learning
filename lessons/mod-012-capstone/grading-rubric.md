# Capstone Grading Rubric

For instructor / peer / self-evaluation of the completed
capstone portfolio.

## Scoring methodology

Each criterion is scored 0-3:

| Score | Meaning |
|---|---|
| **3** | Strong — defensible under expert questioning; would impress a hiring manager. |
| **2** | Adequate — correct but uneven in places; would pass a competent review. |
| **1** | Weak — addresses the criterion but with material gaps. |
| **0** | Missing or fundamentally flawed. |

A passing capstone: **average ≥ 2.0** across all rubric items
AND **no item scored 0**.

A strong capstone: **average ≥ 2.5** AND **most items at 3**.

---

## Section 1: Threat modeling and risk prioritization

### Criterion 1.1: Threat model completeness
Does the threat model address all four threat classes from
the scenario (regulated-data, clinical safety, supply-chain,
operational maturity)?

- 3: All four addressed with concrete threats and named
  affected models / data flows.
- 2: All four addressed but some at a high level only.
- 1: Two or three classes addressed concretely.
- 0: Generic threat model without scenario tailoring.

### Criterion 1.2: Risk prioritization
Is the risk register defensible against alternative orderings?

- 3: Each risk has explicit likelihood × impact reasoning and
  the ordering survives scrutiny.
- 2: Ordering is reasonable; reasoning is partial.
- 1: Ordering exists; reasoning is mostly missing.
- 0: No prioritization, or arbitrary.

### Criterion 1.3: Regulatory applicability
Does the analysis correctly identify HIPAA, GDPR, EU AI Act,
SOC 2 obligations and their interaction?

- 3: All four addressed with article-level specificity where
  relevant; interactions noted.
- 2: All four addressed; some interactions missed.
- 1: Two or three addressed.
- 0: Regulatory analysis is generic.

---

## Section 2: Architecture

### Criterion 2.1: Zero-trust integration
Does the architecture demonstrate true zero-trust principles
(NIST SP 800-207) tailored to NorthBridge?

- 3: Identity-first design with workload identity for every
  workload class; appropriate microsegmentation; explicit
  trust boundaries.
- 2: Most workloads have identity; some gaps in
  microsegmentation.
- 1: Some zero-trust elements but key surfaces (e.g.,
  notebooks, training jobs) lack identity scoping.
- 0: Network-perimeter-based architecture.

### Criterion 2.2: Cryptography decisions
Are the encryption / KMS / signing choices defensible?

- 3: Per-purpose key separation; appropriate KMS; Cosign
  keyless integrated; encryption-in-use considered for the
  PHI cases.
- 2: Most areas correct; minor gaps in key separation or
  rotation.
- 1: Major reliance on long-lived secrets or unsigned
  artifacts.
- 0: Hardcoded credentials, no signing, default-trust.

### Criterion 2.3: Network design
Does the network design address ingress + egress + cluster-
internal correctly?

- 3: Default-deny NetworkPolicies; FQDN-based egress where
  relevant; mesh policies with workload-identity principals;
  cloud-metadata blocked.
- 2: Solid ingress; egress partial.
- 1: Ingress only; egress an afterthought.
- 0: No NetworkPolicy or default-allow.

---

## Section 3: ML-specific controls

### Criterion 3.1: Adversarial defense plan
Are the per-model defense choices justified given the scenario?

- 3: Each clinical model has a defense plan with quantified
  trade-offs (clean accuracy, robust accuracy); DP-SGD applied
  where membership inference is a credible threat.
- 2: Most models addressed; trade-offs partially quantified.
- 1: Generic "adversarial training" applied to everything.
- 0: No adversarial considerations.

### Criterion 3.2: LLM safety (Ambient-Doc + Wellness-Coach)
Is the LLM safety pipeline multi-layered and explicitly
addresses both direct and indirect prompt injection?

- 3: Multi-layer pipeline; output filtering; tool authorization
  separated from LLM judgment; indirect prompt injection
  defended; adversarial corpus + regression testing.
- 2: Most layers in place; some specifics missing.
- 1: Single safety layer or only model-level RLHF reliance.
- 0: No LLM-specific safety.

### Criterion 3.3: Provenance for models and data
Are model and dataset provenance, signing, and admission
verification integrated?

- 3: Models signed; in-toto attestations for training +
  validation + approval; datasets signed; admission verifies
  chain.
- 2: Models signed; partial attestation chain.
- 1: Cosign on container images only; no model-level signing.
- 0: No signing.

---

## Section 4: Compliance and policy

### Criterion 4.1: SOC 2 readiness
Is the SOC 2 plan realistic for the 9-month timeline?

- 3: Phased plan with evidence streams; addresses the existing
  gaps; identifies what stays out of audit scope intentionally.
- 2: Plan exists but some phases optimistic.
- 1: Generic SOC 2 checklist without sequencing.
- 0: No SOC 2 plan.

### Criterion 4.2: EU AI Act readiness
Does the plan address the high-risk classification of the
clinical models?

- 3: Article 9 (risk management), Article 15 (accuracy /
  robustness / cybersecurity), Article 14 (human oversight),
  Annex IV (technical documentation) addressed; clinical
  models classified correctly; timeline aware.
- 2: Most articles addressed; classification correct.
- 1: Mention without specifics.
- 0: EU AI Act ignored.

### Criterion 4.3: Policy as code
Is the policy-as-code program designed (engine choice, library,
testing, distribution, audit)?

- 3: Engine chosen with rationale; ML-specific policies
  (model promotion gate, training-data governance, tenant
  isolation) authored; CI + admission + runtime integrated.
- 2: Engine chosen; some policies; partial integration.
- 1: Engine choice only; no policies authored.
- 0: No policy-as-code program.

---

## Section 5: SecOps

### Criterion 5.1: Detection coverage
Are detections mapped to MITRE ATLAS + ATT&CK with ML-
specific coverage?

- 3: 15+ rules covering ATLAS tactics; per-tenant and
  ML-specific detections present; coverage gaps named.
- 2: 10+ rules; some ATLAS mapping; gaps acknowledged.
- 1: Generic infrastructure detections; little ML-specific.
- 0: No detection ruleset.

### Criterion 5.2: IR procedure
Is the IR procedure usable by an actual on-call engineer?

- 3: Severity classification; per-class playbooks; regulatory
  clocks tracked; communication structure defined; tools and
  access documented.
- 2: Most elements present; one or two underdeveloped.
- 1: High-level procedure; few specific playbooks.
- 0: No formal IR procedure.

### Criterion 5.3: Operational sustainability
Is the SecOps program operable by an 8-engineer team growing
to 25?

- 3: Alert volume calibrated; on-call rotation realistic;
  growth-aware (what changes at 25 engineers); tabletop +
  postmortem cadence.
- 2: Operations addressed; growth-aware in places.
- 1: Today's team only; no growth consideration.
- 0: Enterprise SOC design dropped onto an 8-engineer team.

---

## Section 6: Stakeholder communication

### Criterion 6.1: Audience targeting
Are the four audience portfolios genuinely different in
framing?

- 3: CFO brief is finance-focused; engineer README is
  architecture-focused; customer CISO response is compliance-
  focused; regulator doc is AI Act-focused; each is appropriate
  to its reader.
- 2: Most are differentiated; one or two overlap too much.
- 1: Mostly one rewritten document.
- 0: One generic document for all audiences.

### Criterion 6.2: Honesty
Do the artifacts acknowledge gaps and limitations honestly?

- 3: Each artifact names what's still unresolved; the customer
  CISO response includes a candid maturity statement; the CFO
  brief includes risk where the plan is incomplete.
- 2: Most artifacts honest; one or two over-claim.
- 1: Frequent over-claims.
- 0: Marketing-grade claims without substance.

### Criterion 6.3: Actionability
Could the artifacts drive next-quarter execution?

- 3: Specific commitments with owners and dates; the engineer
  README could ship as a planning doc; the CFO brief includes
  budget; the regulator doc is filable.
- 2: Mostly actionable; some hand-waving.
- 1: High-level direction only.
- 0: Aspirational without execution detail.

---

## Section 7: Overall quality

### Criterion 7.1: Internal consistency
Do the six artifacts cohere?

- 3: Decisions in one artifact are referenced and consistent
  in others; the threat model in Exercise 01 actually
  drives the controls in Exercise 02.
- 2: Mostly consistent; minor inconsistencies.
- 1: Several inconsistencies between artifacts.
- 0: Artifacts read as if written by different people for
  different scenarios.

### Criterion 7.2: Scenario fidelity
Does the portfolio actually address NorthBridge's specific
situation (not just generic ML security)?

- 3: Clinical safety, EU AI Act, HIPAA, growth from 8 to 25,
  specific products (Ambient-Doc, Wellness-Coach) all
  addressed.
- 2: Most scenario specifics addressed.
- 1: Generic ML security with NorthBridge name appended.
- 0: Generic content unmodified from prior modules.

### Criterion 7.3: Time / cost realism
Are the proposed timelines and costs credible?

- 3: Phasing matches team size; SOC 2 in 9 months is shaped
  realistically; EU AI Act timeline acknowledges the longer
  arc; costs are budgetable.
- 2: Mostly realistic; one or two optimistic items.
- 1: Significant time / cost optimism.
- 0: Fantasy timelines / unbudgetable proposals.

---

## Aggregate scoring

| Section | Criteria | Weight |
|---|---|---|
| 1: Threat modeling | 3 | 15% |
| 2: Architecture | 3 | 15% |
| 3: ML controls | 3 | 20% |
| 4: Compliance + policy | 3 | 15% |
| 5: SecOps | 3 | 15% |
| 6: Stakeholder communication | 3 | 10% |
| 7: Overall quality | 3 | 10% |

Weighted average ≥ 2.0 and no 0 score: passing.

Weighted average ≥ 2.5: strong.

---

## Reviewer notes section

For peer / instructor review, include free-text fields:

- **Three things the capstone does well**:
  1. ...
  2. ...
  3. ...

- **Three substantive concerns**:
  1. ...
  2. ...
  3. ...

- **One question I would ask in an interview**:
  ...

- **Overall recommendation**:
  - Strong pass (≥ 2.5 weighted)
  - Pass (≥ 2.0 weighted)
  - Revise and resubmit
  - Fail
