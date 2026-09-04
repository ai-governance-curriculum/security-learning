# Chapter 05 — SOC 2 Trust Services Criteria and Sector Regulations (SR 11-7, FDA GMLP/PCCP, HIPAA)

> **Note on AI-assisted content.** This chapter maps four
> compliance regimes — SOC 2 (AICPA Trust Services Criteria),
> the U.S. Federal Reserve's SR 11-7 supervisory guidance on
> model risk management, the FDA's Good Machine Learning
> Practice (GMLP) and Predetermined Change Control Plan
> (PCCP) framework for medical device software, and the HIPAA
> Security Rule — onto the same control library established
> in chapter 01. It is engineering translation, not legal
> advice. Verify article and section numbers against the
> primary sources (see [`resources.md`](./resources.md))
> before quoting to counsel or an auditor.

---

## Why this chapter exists

An ML platform running in the U.S. under enterprise
customers typically has to answer at least four regimes at
once:

- **SOC 2** — every serious B2B customer's procurement due
  diligence.
- **HIPAA** — if any tenant handles PHI.
- **SR 11-7 / OCC 2011-12** — if any tenant is a federally-
  supervised bank building models for regulatory purposes.
- **FDA GMLP + PCCP** — if any product is medical device
  software (SaMD) subject to premarket review.

The failure mode this chapter prevents:

> The platform ships a shared foundation and each product
> team invents its own compliance overlay. The health
> product team writes its own PHI-in-training controls; the
> banking team writes its own model-risk-management runbook;
> the general SaaS team writes its own SOC 2 evidence.
> Three overlapping control libraries drift. When a
> customer's auditor asks whether "SOC 2 CC7.4 is
> operating", nobody knows which of the three answers is
> canonical.

The remedy is the same shape as chapters 01–03: **one control
library; multiple cross-references**. Every SOC 2 criterion,
every SR 11-7 sub-item, every FDA GMLP principle, and every
HIPAA safeguard maps onto rows in the unified matrix. The
implementation is shared; only the *labelling* differs per
regime.

You leave this chapter able to:

- Enumerate the SOC 2 Trust Services Criteria and identify
  the ML-relevant subset your platform needs to satisfy.
- Translate SR 11-7's three-pillar model-risk-management
  framework into ML platform primitives (model inventory,
  challenger models, monitoring, model-risk officer).
- Map FDA GMLP's 10 guiding principles and the PCCP
  structure onto engineering deliverables for SaMD
  submissions.
- Translate HIPAA Security Rule §§ 164.308 / 164.310 /
  164.312 into ML-specific controls (training-data PHI
  handling, inference PHI handling, log-scrub obligations).
- Extend chapter 01's unified matrix with SOC 2 criterion,
  SR 11-7 element, FDA GMLP / PCCP section, and HIPAA
  section columns.

---

## SOC 2 — the Trust Services Criteria

SOC 2 is an AICPA-published attestation report against the
**Trust Services Criteria** (TSC), organised as:

- **Common Criteria (CC)** — apply to every SOC 2 audit.
  CC1 (Control Environment), CC2 (Communication and
  Information), CC3 (Risk Assessment), CC4 (Monitoring),
  CC5 (Control Activities), CC6 (Logical and Physical
  Access), CC7 (System Operations), CC8 (Change
  Management), CC9 (Risk Mitigation).
- **Availability (A)** — optional; commitments about
  availability.
- **Processing Integrity (PI)** — optional; commitments
  about complete, valid, accurate, timely, authorised
  processing.
- **Confidentiality (C)** — optional; commitments about
  confidential information.
- **Privacy (P)** — optional; commitments about personal
  information.

The report itself comes in two flavours: **Type I** (design
of controls at a point in time), **Type II** (operating
effectiveness of controls over a period — typically 6 or 12
months).

For an ML platform, the ML-specific extensions land in:

### CC3 — Risk Assessment

CC3.1 (identifies risks) and CC3.2 (analyzes risks) are where
the AI/ML risk register (chapter 01 MAP + MEASURE) plugs in.

- **Engineering artefact.** Risk assessment process
  document extended with AI/ML-specific threats:
  poisoning, extraction, membership inference, prompt
  injection, tool misuse, model drift. Ties to the mod-102
  threat model.
- **Auditor evidence.** Sample of per-system threat models
  with signed sign-off; risk register queries showing
  coverage.

### CC6 — Logical and Physical Access

CC6.1 (implements logical access controls), CC6.2 (registers
and authorises new users), CC6.3 (authorises, modifies,
removes access) all apply to ML resources. The **model
registry**, the **training data store**, the **feature
store**, the **KMS keys**, and the **inference endpoints**
are all access-controlled resources subject to CC6.

- **Engineering artefact.** IAM policy generator over the
  ML platform's resources; access-review evidence sampling.
  Chapter 04's OPA policies enforce.
- **Auditor evidence.** Access-review reports per quarter;
  policy hits over the audit period.

### CC7 — System Operations

CC7.1 (detects security events), CC7.2 (analyses events),
CC7.3 (evaluates significance), CC7.4 (responds). All apply
to ML security events.

- **Engineering artefact.** ML-specific monitors —
  jailbreak-attempt rate, safety-classifier hits,
  extraction-query rate, drift alerts — feed the same
  incident-response pipeline as classical security events
  (mod-111).
- **Auditor evidence.** Alert history; incident tickets;
  runbook execution records.

### CC8 — Change Management

CC8.1 (authorises, designs, develops, tests, approves,
implements changes). For ML systems, changes include: model
version updates, training-data updates, prompt-template
changes, tool-registry changes, guardrail updates.

- **Engineering artefact.** Model-registry promotion gate
  (chapter 04); training-data update workflow with
  approval; agent-tool-registry review.
- **Auditor evidence.** Sample of model releases showing
  full change record — PR, review, tests, approvals,
  deployment.

### CC9 — Risk Mitigation

CC9.1 (identifies risk mitigation activities), CC9.2
(assesses risks from vendor / business partners). Vendor-risk
management for imported models / hosted APIs (mod-110).

- **Engineering artefact.** AI supplier register and per-
  supplier assessment.
- **Auditor evidence.** Supplier register at audit time;
  per-supplier assessment sampling.

### Availability

If the platform commits to availability, ML-specific
availability considerations include: model rollback SLA,
fallback path for hosted-model outages (mod-107 chapter 05),
capacity planning for inference (auto-scale ceilings).

### Processing Integrity

ML systems produce outputs whose "integrity" is more subtle
than transaction integrity. Useful engineering framings:

- **Complete.** Every input receives an output; failed
  inferences are tracked and re-run.
- **Valid.** Output is in the expected format (schema
  validation on structured-output).
- **Accurate.** Output tracks the declared eval metric
  within SLO (regression alerts).
- **Timely.** Latency SLOs met.
- **Authorised.** Every inference is attributed to an
  authenticated caller with authorisation.

### Confidentiality

Confidential inputs and outputs (customer prompts, tenant
data) are subject to the same protections as any confidential
data. ML-specific: **prompt-log confidentiality**, **cross-
tenant leakage prevention**, **training-data confidentiality**.

- **Engineering artefact.** Prompt-log DLP (mod-108 chapter
  03); tenant-isolation controls on the platform (mod-103
  chapter 04); training-data KMS + access control
  (mod-105).
- **Auditor evidence.** DLP coverage report; tenant-boundary
  test suite; KMS grant audits.

### Privacy

Privacy has its own criteria (P1–P8) covering notice, choice,
collection, use/retention/disposal, access, disclosure,
security, quality, and monitoring. For ML: **notice**
(model card intended-use section), **use/retention/disposal**
(training-data retention policy, DP claim), **quality**
(eval results, fairness reports), **monitoring** (post-market
monitoring per chapter 03 Article 72).

**Engineering artefact for SOC 2 as a whole.** A **SOC 2
control-mapping matrix** that lists every TSC criterion the
audit covers, the platform's implementation, the evidence
artefacts, and the operating cadence. Same shape as the
chapter 01 matrix; add a `soc_2` cross-reference block per
row.

---

## SR 11-7 — Model Risk Management (banking)

The Federal Reserve's SR 11-7 (2011) — jointly with OCC
2011-12 — is the U.S. banking regulator's model-risk
management (MRM) framework. Its scope is any model used for
regulatory purposes (capital, liquidity, credit, market risk,
fraud, BSA/AML). ML models increasingly fall under it.

SR 11-7's three pillars:

### Pillar 1 — Robust Model Development, Implementation, and Use

Model development covers design, theory and logic, data,
testing, and documentation. Engineering translation:

- **Model design record.** Design ADR per model naming the
  chosen algorithm, feature set, and rationale.
- **Data-quality assessment.** Provenance + representative-
  ness (aligns with chapter 03 Article 10; mod-104
  lineage).
- **Testing.** Out-of-sample, out-of-time, and (for higher-
  tier models) **benchmarking against alternative
  approaches** — SR 11-7's "challenger model" concept.
- **Documentation.** Comprehensive model documentation
  package — often called a "model file" — that another
  competent modeller can reproduce the model from.

### Pillar 2 — Effective Validation Framework

Validation is **independent** of development. Elements:

- **Evaluation of conceptual soundness.** Is the model
  design appropriate for the intended use?
- **Ongoing monitoring.** Post-deployment performance,
  benchmarking, and outcomes analysis.
- **Outcomes analysis.** Comparison of model outputs to
  actual outcomes (backtesting).

Engineering artefacts:

- **Independent validation report** per material model,
  produced by a validation function organisationally
  separate from development.
- **Ongoing-monitoring dashboard** tracking model
  performance vs baseline and vs challenger models;
  degradation triggers re-validation.
- **Backtesting record** — for each model, comparison of
  predictions to realised outcomes over the audit period.

### Pillar 3 — Governance, Policies, and Controls

Model governance:

- **Model inventory.** A complete inventory of all models
  in use — the "model inventory management system" (MIMS).
- **Roles and responsibilities.** Model owner, model user,
  model developer, model validator, model risk officer.
- **Policies.** Written model-risk policy defining tiers,
  approval requirements, validation frequency, and
  documentation standards.
- **Effective challenge.** Culture of challenge from
  validation and risk-management functions.

Engineering artefacts:

- **Model inventory.** Not a spreadsheet — a queryable,
  authoritative registry with per-model tier, owner,
  validation status, last-validated date, next-validation-
  due date. The **model registry** (MLflow, Vertex Model
  Registry, bespoke) is the inventory; SR 11-7 requires it
  be authoritative and complete.
- **RACI for MRM.** Names the Model Risk Officer (MRO),
  model owner, developer, validator.
- **Tiering policy.** Per model, a tier assignment (Tier 1:
  material to regulatory capital; Tier 2: material to
  business; Tier 3: informational). Tier drives
  validation frequency, documentation depth, monitoring
  intensity.

Cross-reference to chapter 04: SR 11-7 tier and validation
status are inputs to the model-registry promotion policy.
A model with `validation_status != current` cannot promote
to production (for Tier 1/2).

### Sample matrix extension

```yaml
- id: SR-11-7.II.1
  regime: sr_11_7
  clause: "Independent validation"
  requirement: >
    Model validation is performed by parties independent
    of model development.
  applies_to_tiers: [tier_1, tier_2]
  implementation:
    description: >
      Validation function reports to Model Risk Officer,
      separate from ML Engineering. Per material model,
      validation report produced before production
      promotion; refreshed annually.
    artefacts:
      - validation-reports/<model>/<version>.md
      - governance/mrm/raci.yaml
  evidence:
    verification: >
      Chapter 04 policy `mrm_validation_current.rego` blocks
      promotion of Tier 1/2 models without a current
      validation report.
  cross_refs:
    nist_ai_rmf: [MS-2.1, MS-2.9]
    iso_42001: [8.2, 8.4]
```

### What SR 11-7 does not (yet) directly address

SR 11-7 predates modern ML by a decade. It does not name
adversarial robustness, fairness, prompt injection, or
generative-AI-specific risks. Supervisory expectations
extend the framework informally (OCC's 2021 model risk
management handbook update, joint federal-agency AI/ML
statements). The engineering translation: treat SR 11-7 as
the *skeleton*; add the AI-specific controls from chapters
01–03 on top.

---

## FDA — Good Machine Learning Practice (GMLP) and PCCP

The FDA regulates ML-based **Software as a Medical Device
(SaMD)** under existing device pathways (510(k), De Novo,
PMA). The AI/ML-specific guidance:

- **Good Machine Learning Practice for Medical Device
  Development: Guiding Principles** (2021, jointly with
  Health Canada and the MHRA) — 10 principles.
- **Predetermined Change Control Plan (PCCP)** — the FDA's
  mechanism for pre-authorising a set of future model
  changes without a new submission for each; guidance
  finalised December 2024.

### The 10 GMLP guiding principles

Summarised (verbatim titles from the guidance):

1. Multi-Disciplinary Expertise Is Leveraged Throughout the
   Total Product Life Cycle.
2. Good Software Engineering and Security Practices Are
   Implemented.
3. Clinical Study Participants and Data Sets Are
   Representative of the Intended Patient Population.
4. Training Data Sets Are Independent of Test Sets.
5. Selected Reference Datasets Are Based Upon Best
   Available Methods.
6. Model Design Is Tailored to the Available Data and
   Reflects the Intended Use of the Device.
7. Focus Is Placed on the Performance of the Human-AI Team.
8. Testing Demonstrates Device Performance during Clinically
   Relevant Conditions.
9. Users Are Provided Clear, Essential Information.
10. Deployed Models Are Monitored for Performance and
    Retraining Risks Are Managed.

### Engineering translation

Each principle becomes a deliverable:

- **P1 (multi-disciplinary).** Design-review roster
  requires clinical, engineering, regulatory, and quality
  representation.
- **P2 (software engineering + security).** IEC 62304
  software-lifecycle documentation + IEC 81001-5-1 health-
  software security lifecycle + the existing platform
  security controls (mod-103, mod-105).
- **P3 (representative data).** Article-10-shaped
  representativeness assessment specific to the intended
  patient population — age, sex, race, comorbidities, site
  variability, imaging-device variability.
- **P4 (train/test independence).** Enforced by the eval
  pipeline: training-set and test-set hashes must be
  disjoint at eval time; audit-visible.
- **P5 (reference datasets).** Documented rationale for
  reference datasets; comparison to community benchmarks
  where they exist.
- **P6 (design fit to data).** Design record justifies the
  algorithm choice against dataset size and characteristics.
- **P7 (human-AI team performance).** Human factors
  engineering: performance measured as the joint system
  (clinician + model), not model in isolation.
- **P8 (clinically-relevant testing).** Eval bundle
  includes clinically-relevant subgroups, edge cases,
  failure-mode injection.
- **P9 (user information).** Labelling — instructions for
  use, model output interpretation, known limitations —
  meets 21 CFR Part 801.
- **P10 (monitoring + retraining risk).** Post-market
  surveillance (aligns with chapter 03 Article 72); real-
  world performance monitoring; retraining-triggered re-
  submission or PCCP-covered.

### PCCP — the pre-authorised change

For a locked-model SaMD, any change to the model (retraining
on new data, new modality, new indication) requires a new
submission. The PCCP allows the sponsor to submit **at the
time of initial authorisation** a plan for future
modifications the FDA reviews and pre-authorises.

A PCCP has three components:

- **Description of Modifications.** Which changes are
  planned (retraining cadence, expansion of input types,
  performance updates); explicitly bounded.
- **Modification Protocol.** How each change will be
  developed, validated, and implemented — including
  data-management, retraining triggers, performance
  metrics, thresholds, verification and validation
  procedures, and update procedures.
- **Impact Assessment.** Analysis of benefits and risks of
  the changes; comparison of modified vs unmodified
  version; risks of introducing the modifications; how
  they will be mitigated.

**Engineering artefacts.**

- `pccp/description-of-modifications.md`
- `pccp/modification-protocol.md` — this is where
  chapter 04's OPA policies get referenced explicitly (the
  admission gate that enforces "no retraining outside the
  pre-authorised modality"; the eval-threshold policy that
  blocks release if PCCP-declared performance floor is
  breached).
- `pccp/impact-assessment.md`

The PCCP is **binding**. Once accepted, the sponsor is
committed to executing changes only within its scope.
Violations trigger enforcement action. The policy-as-code
layer is not decorative here — it is the technical
enforcement of a regulatory commitment.

### Sample matrix extension

```yaml
- id: FDA-GMLP.P10
  regime: fda_gmlp
  clause: "Deployed Models Are Monitored for Performance and Retraining Risks Are Managed"
  requirement: >
    Post-market monitoring for real-world performance;
    retraining risks are managed.
  implementation:
    description: >
      Real-world performance monitor per PCCP-declared
      metrics; drift monitor; retraining trigger gates
      through PCCP protocol.
    artefacts:
      - monitoring/dashboards/samd-performance.json
      - pccp/modification-protocol.md
      - runbooks/samd-drift-response.md
  evidence:
    verification: >
      Chapter 04 policy `pccp_retraining_scope.rego`
      blocks retraining runs outside the PCCP-declared
      scope; monitoring dashboard reviewed monthly by
      Quality.
  cross_refs:
    nist_ai_rmf: [MG-2.3, MG-4.1]
    iso_42001: [9.1, 10.1]
    eu_ai_act: [72]
```

---

## HIPAA Security Rule — ML platform mapping

The HIPAA Security Rule (45 CFR Part 164 Subpart C) applies
to Protected Health Information (PHI) held by Covered
Entities and their Business Associates. Three families of
safeguards:

- **Administrative** (§ 164.308)
- **Physical** (§ 164.310)
- **Technical** (§ 164.312)

Each standard is either **Required** (must be implemented)
or **Addressable** (implement if reasonable and appropriate;
if not, document why and implement an equivalent).

mod-108 chapter 05 covers HIPAA-in-ML in depth. This
chapter's contribution is the **mapping into the unified
control matrix** so the same evidence surface satisfies SOC 2,
ISO 42001, EU AI Act, and HIPAA at once.

### Administrative safeguards (§ 164.308) — ML relevance

- **Security Management Process (§ 164.308(a)(1)).** Risk
  analysis + risk management + sanction policy +
  information system activity review. Maps to chapter 01
  GOVERN + MANAGE; the AI-specific extension names
  training-data breach, model extraction, prompt-log
  exposure as security-relevant events.
- **Assigned Security Responsibility (§ 164.308(a)(2)).**
  Named security official; typically the CISO.
- **Workforce Security (§ 164.308(a)(3)).** Authorisation
  and supervision of workforce members with access to PHI
  in ML systems (data scientists with training-data
  access; ML engineers with model access; annotators with
  labelling access).
- **Information Access Management (§ 164.308(a)(4)).**
  Access authorisation to ePHI-containing systems.
- **Security Awareness and Training (§ 164.308(a)(5)).**
  Training on PHI handling, extended with ML-specific
  modules (prompt-injection risks, training-data leakage,
  model-extraction risks).
- **Security Incident Procedures (§ 164.308(a)(6)).**
  Incident-response procedures extended for ML incidents
  (mod-111).
- **Contingency Plan (§ 164.308(a)(7)).** Data-backup,
  disaster-recovery, emergency-mode-operation plans
  extended to model checkpoints, training-data snapshots,
  feature-store state.
- **Business Associate Contracts (§ 164.308(b)).** BAAs
  with any downstream party handling PHI, including
  hosted-model providers, dataset vendors, labelling
  vendors. mod-110 supplier register annotates BAA
  status.

### Physical safeguards (§ 164.310) — ML relevance

- **Facility Access Controls (§ 164.310(a)(1)).** For
  cloud-hosted ML platforms, the cloud provider's SOC 2
  and physical-security controls satisfy this on behalf of
  the covered entity; the BAA references them.
- **Workstation Use (§ 164.310(b)) / Security
  (§ 164.310(c)).** Applies to workstations where
  engineers access PHI-containing datasets — endpoint
  posture, screen-lock, no-local-copy policies.
- **Device and Media Controls (§ 164.310(d)).** Applies to
  ML-specific media: model checkpoints containing PHI-
  memorised weights, training-data snapshots, embedding
  stores. Disposal and reuse procedures cover destruction
  of these artefacts.

### Technical safeguards (§ 164.312) — ML relevance

- **Access Control (§ 164.312(a)(1)).** Unique user
  identification, emergency access, automatic logoff,
  encryption of PHI. For ML: unique workload identities
  (mod-103), authorisation via chapter 04 policies,
  encryption of training-data and model checkpoints via
  mod-105 KMS.
- **Audit Controls (§ 164.312(b)).** Hardware, software,
  procedural mechanisms that record and examine activity.
  For ML: chapter 03 Article-12-shaped logging, extended
  with per-inference logging of who accessed which PHI
  record.
- **Integrity (§ 164.312(c)).** Mechanism to authenticate
  ePHI (not altered or destroyed inappropriately). For
  ML: content-addressed training-data snapshots (mod-104
  lineage); model checkpoint hashes.
- **Person or Entity Authentication (§ 164.312(d)).**
  Verify identity. For ML: workload identity + user
  identity end-to-end.
- **Transmission Security (§ 164.312(e)).** Integrity and
  encryption in transit. For ML: mTLS between ML
  platform components (mod-103 chapter 03).

### Sample matrix extension

```yaml
- id: HIPAA.§164.312(b)
  regime: hipaa
  clause: "Audit Controls"
  requirement: >
    Implement hardware, software, and procedural
    mechanisms that record and examine activity in
    information systems that contain or use electronic
    protected health information.
  applies_when: system_scope includes phi
  implementation:
    description: >
      Article-12-shaped logging spec extended with
      per-inference PHI-access log — which record
      classes accessed, by which workload identity,
      for which caller identity.
    artefacts:
      - logging-spec.yaml
      - governance/hipaa/audit-log-retention-policy.md
  evidence:
    verification: >
      Chapter 04 policy `logging_spec_required.rego`
      blocks deployment without a logging spec; audit-
      log retention monitor.
  cross_refs:
    nist_ai_rmf: [MG-2.3, GV-1.1]
    iso_42001: [7.5, 9.1]
    eu_ai_act: [12]
    soc_2: [CC7.2]
```

---

## The unified matrix — one library, four regime columns

Chapter 01's matrix schema, extended:

```yaml
- id: NIST-AI-RMF.MS-2.10
  function: MEASURE
  ...
  cross_refs:
    iso_42001:
      clauses: [8.2, 9.1]
      annex_a: [A.7.2, A.7.4]
    eu_ai_act:
      articles: [10, 15]
    soc_2:
      criteria: [CC7.4, P4.1, C1.1]
    sr_11_7:
      pillars: [pillar_1_data_quality]
    fda_gmlp:
      principles: [P3, P8]
    hipaa:
      sections: ["§164.312(b)", "§164.312(c)"]
```

For any given system, only a subset of the regime columns
applies:

- A B2B SaaS ML tool → SOC 2 + (if PHI) HIPAA + (if EU
  customers) EU AI Act + (if healthcare classifier)
  possibly FDA.
- A US retail bank's credit-scoring model → SR 11-7 + SOC
  2 + (if handles regulated PII) HIPAA/state privacy laws.
- A hospital's radiology triage → FDA + HIPAA + SOC 2 (as
  a business associate of the hospital IT vendor).

The **scope statement** (chapter 01 GV-1.1 + chapter 02
Clause 4.3) names which regimes apply per system. The
platform runs the union of applicable regimes; the audit
runs a per-regime slice of the same evidence.

---

## The audit surface

Auditors from different regimes ask overlapping questions.
The engineering discipline is to answer *once* per question
and let each audit consume the same answer.

Typical overlaps:

- **Change management.** SOC 2 CC8, ISO 42001 Clause 6.3
  + 8.1, EU AI Act Article 43 (conformity assessment for
  substantial modifications), SR 11-7 Pillar 3
  (governance of model changes), HIPAA § 164.308(a)(1)
  (risk analysis on changes) — all satisfied by the
  chapter 04 admission-gate policy suite plus the change-
  management workflow.
- **Access control.** SOC 2 CC6, ISO 42001 Clause 8, EU
  AI Act Article 15 (cybersecurity), HIPAA § 164.312(a)
  — one workload-identity + user-identity implementation;
  four regime column entries.
- **Incident response.** SOC 2 CC7.3–7.4, ISO 42001
  Clause 10, EU AI Act Article 73, HIPAA § 164.308(a)(6)
  — one runbook; four regime-specific notification
  branches inside it.
- **Vendor / supplier management.** SOC 2 CC9.2, ISO
  42001 Annex A.10, EU AI Act Article 25, HIPAA
  § 164.308(b), SR 11-7 (vendor models) — one supplier
  register.

---

## Standard failure modes

- **One-team-per-regime.** SOC 2 team, HIPAA team, banking
  team, FDA team all build separate control libraries.
  Fix: single unified matrix; per-regime views are
  reports over the matrix, not separate libraries.
- **SOC 2 evidence-scramble at audit time.** Team learns
  the audit period starts next month; controls that were
  "in place" turn out to have no operating evidence. Fix:
  chapter 04 admission gates run continuously; audit
  period is a query over the retained decisions.
- **SR 11-7 challenger models skipped for ML.** "We use
  ML, not a linear model, so challenging is not
  meaningful". Fix: challenger models for ML systems are
  simpler baselines (logistic regression, gradient
  boosting, previous model version) whose failure to keep
  up is documented; the point is *ongoing effective
  challenge*, not a specific alternative.
- **FDA PCCP written broad, executed narrow.** Sponsor
  requests wide latitude; enforcement of the narrow
  execution is missing. Fix: chapter 04 policy encodes
  the PCCP's declared bounds; retraining outside the
  bounds fails admission.
- **HIPAA "we don't handle PHI" without proof.** The
  platform accepts PHI in prompts and no one classified
  it. Fix: DLP on the ingest (mod-108 chapter 03); tenant-
  scoped PHI flag on the platform inventory.
- **BAA missing for a downstream vendor.** Prompt logging
  goes to a hosted analytics tool that has no BAA. Fix:
  supplier register (mod-110) tracks BAA status;
  procurement gate blocks purchase without a BAA if the
  supplier will handle PHI.
- **SOC 2 Privacy criteria adopted without a privacy
  engineer.** The org opts into the Privacy criteria
  because it "looks good" and cannot operate them. Fix:
  audit scope reflects capability; opting into criteria
  the org cannot operate is a nonconformity risk.
- **Regime cross-refs missing on the matrix.** Row exists
  for the control but the cross-ref block is empty. Fix:
  cross-ref block filled at row creation; missing cross-
  refs surface in the governance dashboard.

---

## Summary

- **SOC 2** — Common Criteria + optional Availability,
  Processing Integrity, Confidentiality, Privacy. Every
  ML resource falls under CC6 (access), CC7 (operations),
  CC8 (change), CC9 (risk). ML-specific extensions live
  in the Confidentiality (prompt logs) and Privacy
  (training data) additional criteria.
- **SR 11-7** — three pillars: robust development, effective
  validation, governance. **Model inventory** is the
  ground truth; **validation independent of development**
  is the discipline; **effective challenge** is the
  culture. Applies to any bank model with regulatory
  material — ML models are increasingly in scope.
- **FDA GMLP + PCCP** — 10 guiding principles cover data,
  design, testing, human factors, and monitoring across
  the total product lifecycle. **PCCP** pre-authorises
  bounded future changes; policy-as-code enforces the
  bounds.
- **HIPAA Security Rule** — administrative, physical, and
  technical safeguards for ePHI. ML additions: PHI-in-
  training-data, PHI-in-prompt-logs, PHI-in-model-
  weights (memorisation), workload identity, per-
  inference PHI-access logging.
- The **unified control matrix** — one library, per-regime
  cross-reference columns. The same admission-gate
  policies (chapter 04) satisfy multiple regimes; the
  same evidence surface answers multiple audits.
- The engineering discipline is *audit-time is a query*,
  not a scramble. If the platform produces evidence
  continuously, any regime can consume its slice on
  demand.
