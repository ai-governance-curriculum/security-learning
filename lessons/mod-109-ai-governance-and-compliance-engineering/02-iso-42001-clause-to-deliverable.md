# Chapter 02 — ISO/IEC 42001 Clauses to Security-Engineering Deliverables

> **Note on AI-assisted content.** ISO/IEC 42001:2023
> ("Information technology — Artificial intelligence —
> Management system") is a certifiable standard. Certification
> is granted by accredited bodies against auditable evidence,
> not against this chapter. Verify clause numbering and Annex A
> control identifiers against the current published text of the
> standard (BSI, ANSI, ISO Store) before quoting to an
> auditor. See [`resources.md`](./resources.md).

---

## Why this chapter exists

ISO/IEC 42001 is the first international, certifiable AI
Management System (AIMS) standard. Publication (December
2023) started the same "management system" pattern that
ISO/IEC 27001 established for information security twenty
years earlier: a certifiable *shell* of policy, planning,
operation, evaluation, and improvement (Clauses 4–10), and an
**Annex A** of AI-specific controls the organisation applies
in an **applicability statement**.

The failure mode this chapter prevents:

> The security team is told to "get 42001-ready by Q4".
> They read Clauses 4–10 as if they were a checklist, produce
> a stack of policies, and stall. The auditor arrives, asks
> "show me the record of your last AI risk-treatment
> review", and there is no record — the policy said it would
> happen but nobody operated it. The certification stalls.

ISO management-system standards are audited by *evidence of
operation*, not by *existence of policy*. Every clause has a
"records", "documented information", or "shall retain
documented information" phrase; the security-engineering
deliverable per clause is the *thing that produces those
records automatically as work happens*, so the auditor sees
real operation rather than back-filled paper.

This chapter walks Clauses 4–10, calls out the shape of Annex
A, and maps each auditable requirement to a concrete
engineering deliverable. It closes with an **applicability
statement** template.

You leave this chapter able to:

- Explain what each clause of 42001 requires, and *what
  auditor evidence* satisfies it.
- Produce the AIMS scope statement, applicability statement,
  risk-treatment plan, and management-review record — the
  four documents an auditor asks for first.
- Wire the recurring clauses (internal audit, management
  review, corrective action) into the platform so records
  are generated as a by-product of engineering work.
- Extend the chapter 01 unified control matrix with the ISO
  42001 clause + Annex A control columns.

---

## The shape of 42001

42001 uses the standard **High-Level Structure** ("Harmonized
Structure") shared by 27001, 9001, 14001, etc. The clauses
progress:

- **Clause 4 — Context of the organisation.** What is the
  AIMS for; what's in scope; who are the interested parties.
- **Clause 5 — Leadership.** Top-management commitment; AI
  policy; roles and responsibilities.
- **Clause 6 — Planning.** AI risks and opportunities; AI
  objectives; risk treatment; **applicability statement**.
- **Clause 7 — Support.** Resources; competence; awareness;
  communication; documented information.
- **Clause 8 — Operation.** Operational planning and control;
  AI risk assessment; AI risk treatment; **AI system impact
  assessment**; controls in operation.
- **Clause 9 — Performance evaluation.** Monitoring,
  measurement, analysis; internal audit; management review.
- **Clause 10 — Improvement.** Nonconformity and corrective
  action; continual improvement.

**Annex A** enumerates the AI-specific controls the AIMS
applies. Annex A groups are (as published in 42001:2023):

- A.2 Policies related to AI.
- A.3 Internal organisation.
- A.4 Resources for AI systems.
- A.5 Assessing impacts of AI systems.
- A.6 AI system life cycle.
- A.7 Data for AI systems.
- A.8 Information for interested parties of AI systems.
- A.9 Use of AI systems.
- A.10 Third-party and customer relationships.

**Annex B** is guidance on implementing the Annex A controls.
**Annex C** relates 42001 objectives to the trustworthiness
attributes; **Annex D** cross-references to ISO 22989 and
23053 AI concept vocabulary.

The audit looks at Clauses 4–10 (the management system) *and*
the applicability of the Annex A controls to the org's
context. A control is either **applicable** and implemented
with evidence, or **not applicable** with a written
justification.

---

## The clause-to-deliverable map

### Clause 4 — Context of the organisation

**4.1 Understanding the organisation and its context.**
Auditable requirement: identify external and internal issues
relevant to the AIMS purpose.

- **Deliverable.** `aims/context.md` — the organisation's
  AIMS context statement. External issues (regulatory
  landscape: EU AI Act, GDPR, sector regs; customer
  expectations; supplier maturity). Internal issues
  (engineering practice; org structure; existing 27001
  posture).
- **Owner.** ML Governance Lead (or CISO in orgs that
  combine).
- **Evidence produced.** Signed context doc; annual review
  entry.

**4.2 Understanding the needs and expectations of interested
parties.**

- **Deliverable.** `aims/interested-parties.yaml` —
  register of interested parties (customers, regulators,
  employees, affected end-users, suppliers, investors,
  civil-society organisations). Per party: their AI-related
  needs and how the AIMS addresses each.
- **Owner.** ML Governance Lead.
- **Evidence produced.** Register; per-party requirement
  tracking.

**4.3 Determining the scope of the AIMS.**

- **Deliverable.** `aims/scope.md` — statement naming
  systems, sites, functions, and roles in scope. This is
  the *scope statement* the certifier prints on the
  certificate.
- **Requirement.** Scope must justify exclusions; a scope
  that excludes systems that would otherwise fall in is
  suspect.
- **Owner.** Top management.

**4.4 AI management system.**

- **Deliverable.** `aims/README.md` — the top-level document
  describing the AIMS structure, referring to the other
  clause artefacts.
- **Owner.** ML Governance Lead.

### Clause 5 — Leadership

**5.1 Leadership and commitment.** Top management shall
demonstrate leadership.

- **Deliverable.** Management-review meeting minutes
  (Clause 9.3); documented allocation of resources
  (Clause 7.1); management review of the AI policy.
- **Owner.** CEO / equivalent accountable executive.
- **Evidence produced.** Signed minutes; budget records;
  policy approval history.

**5.2 AI policy.**

- **Deliverable.** `aims/ai-policy.md` — the organisation's
  AI policy. Contains purpose, framework for setting AI
  objectives, commitment to satisfying applicable
  requirements, commitment to continual improvement.
- **Requirement.** Communicated within the organisation and
  available to interested parties as appropriate.
- **Owner.** Top management.
- **Evidence produced.** Policy in a controlled repo;
  distribution / acknowledgement records; review history.

**5.3 Roles, responsibilities, and authorities.**

- **Deliverable.** `aims/raci.yaml` — organisation-level
  RACI for AIMS operation. Cross-references chapter 01's
  GOVERN 2.1 RACI.
- **Owner.** Top management.

### Clause 6 — Planning

**6.1 Actions to address risks and opportunities.** The AIMS
shall address risks and opportunities.

- **Deliverable.** `aims/risk-treatment-plan.md` — the
  master risk-treatment plan for the AIMS. References the
  per-system risk registers (mod-102 threat models).
- **Owner.** ML Security Lead.

**6.1.2 AI risk assessment.** Auditable requirement:
processes for identifying AI risks, criteria for evaluation,
consistent and comparable results.

- **Deliverable.** `aims/risk-assessment-process.md` — the
  method used (STRIDE-for-ML, LINDDUN-GO, hybrid); the
  scoring rubric; the frequency; the reviewer roles.
- **Owner.** ML Security Lead.

**6.1.3 AI risk treatment.** Auditable requirement: a
process to select risk-treatment options, determine controls,
compare against Annex A, produce an **applicability
statement**.

- **Deliverable.** `aims/statement-of-applicability.yaml`
  — for each Annex A control: applicable? if yes, how
  implemented and evidence; if no, justification.
- **Owner.** ML Governance Lead + ML Security Lead.
- **Evidence produced.** SoA is *the* headline audit
  artefact after the AI policy. Template in the "SoA
  template" section below.

**6.1.4 AI system impact assessment.** New in 42001:
assessment of an AI system's impact on individuals and
societies, integrated with risk assessment.

- **Deliverable.** `impact-assessment.md` per system,
  templated by `aims/impact-assessment-template.md`. Covers
  intended use, affected groups, potential harms, mitigation
  approach.
- **Cross-ref.** Aligns with EU AI Act Article 27
  Fundamental Rights Impact Assessment (chapter 03) and
  NIST MAP 3.x (chapter 01).
- **Owner.** Product owner per system, with review from
  Legal / DPO.
- **Evidence produced.** Per-system impact assessment on
  file; reviewed at release-gate.

**6.2 AI objectives and planning to achieve them.**

- **Deliverable.** `aims/objectives.yaml` — measurable AI
  objectives (e.g., "≥ 95% of production models carry a
  current impact assessment"; "≥ 99% of high-risk model
  releases pass admission-gate policy on first attempt";
  "management review executed twice yearly on schedule").
- **Owner.** ML Governance Lead.
- **Evidence produced.** Objective trend on the governance
  dashboard; annual review of objectives.

**6.3 Planning of changes.**

- **Deliverable.** Change-management process references the
  AIMS: material changes to a production AI system trigger
  re-run of impact assessment and risk assessment.
- **Owner.** Change Advisory Board.

### Clause 7 — Support

**7.1 Resources.** Provide the resources needed for the AIMS.

- **Deliverable.** Budget line and headcount records for AI
  safety / security roles.
- **Evidence produced.** Annual budget artefact.

**7.2 Competence.** Ensure persons doing AI work are
competent.

- **Deliverable.** Role-competency matrix + training
  records. For each role (data engineer, ML engineer, ML
  security, red-team, DPO) name the required competencies
  and the training / certifications that evidence them.
- **Owner.** People / HR + ML Governance.
- **Evidence produced.** Per-employee training record;
  competency-gap analysis.

**7.3 Awareness.** Persons doing work under the AIMS are
aware of the AI policy, their contribution, and consequences
of non-conformity.

- **Deliverable.** AIMS awareness training in onboarding
  + annual refresher; completion tracked.
- **Owner.** People / HR.
- **Evidence produced.** Completion records.

**7.4 Communication.** Determine internal and external
communications relevant to the AIMS.

- **Deliverable.** `aims/communications-plan.md` — internal
  channels (Slack, all-hands), external channels (customer
  DPAs, transparency reports, regulator interfaces).
- **Owner.** Legal + Comms + ML Governance.

**7.5 Documented information.** Documented information
required by the AIMS shall be controlled.

- **Deliverable.** Every AIMS document lives in a
  version-controlled repository with named owners and
  reviewer roles. Retention policy matches audit needs
  (usually ≥ 3 years for records; indefinitely for
  applicability statements and management-review minutes).
- **Owner.** ML Governance Lead.
- **Evidence produced.** Version-controlled repo; access
  logs; retention policy.

### Clause 8 — Operation

**8.1 Operational planning and control.**

- **Deliverable.** Standard operating procedures for AI
  system lifecycle stages — design review, training, eval,
  deployment, monitoring, retirement. Ties to mod-103
  admission gates.
- **Evidence produced.** SOPs published; adherence measured.

**8.2 AI risk assessment.** Perform AI risk assessments at
planned intervals and when significant changes occur.

- **Deliverable.** Per-system risk-assessment records
  (mod-102 threat models); cadence tracked; change-triggered
  re-assessments recorded.
- **Evidence produced.** Risk-assessment log per system.

**8.3 AI risk treatment.** Implement the risk-treatment plan.

- **Deliverable.** Control implementation records — CI
  jobs, admission-gate policies (chapter 04), monitoring
  runbooks. The linkage from SoA control ID → engineering
  artefact is mechanical.
- **Evidence produced.** Per-control artefact index.

**8.4 AI system impact assessment.** Perform impact
assessments at planned intervals and when significant
changes occur.

- **Deliverable.** Per-system impact assessments; cadence
  tracked.

### Clause 9 — Performance evaluation

**9.1 Monitoring, measurement, analysis, and evaluation.**
The organisation shall determine what needs to be monitored,
methods, when, who evaluates.

- **Deliverable.** `aims/monitoring-plan.yaml` — per
  objective and per Annex A control: metric, method,
  frequency, reviewer, threshold.
- **Owner.** ML Governance + ML Security.
- **Evidence produced.** Governance dashboard with live
  trends; alerts on threshold breach; per-metric review
  cadence honoured.

**9.2 Internal audit.** Conduct internal audits at planned
intervals.

- **Deliverable.** `aims/internal-audit-plan.md` — annual
  audit programme; each audit produces a report; findings
  drive corrective actions (Clause 10.1).
- **Owner.** Internal Audit (independent of the audited
  function).
- **Evidence produced.** Audit reports; finding-tracker
  status.

**9.3 Management review.** Top management shall review the
AIMS at planned intervals.

- **Deliverable.** Management-review meeting held at least
  annually (semi-annually is a stronger posture); agenda
  includes objectives status, audit findings, corrective-
  action status, feedback from interested parties,
  effectiveness of risk treatment, opportunities for
  improvement.
- **Owner.** Top management.
- **Evidence produced.** Meeting minutes retained
  indefinitely; action items with owners and dates.

### Clause 10 — Improvement

**10.1 Nonconformity and corrective action.** When a
nonconformity occurs, react, evaluate need for action,
implement, review effectiveness.

- **Deliverable.** Nonconformity register (a ticket queue
  or dedicated tracker); each entry has root-cause analysis,
  corrective action, effectiveness review.
- **Owner.** ML Governance Lead.
- **Evidence produced.** Register with per-item lifecycle.

**10.2 Continual improvement.** Continually improve the
suitability, adequacy, and effectiveness of the AIMS.

- **Deliverable.** Annual improvement plan; objectives
  updated based on audit findings, management review, and
  interested-party feedback.
- **Owner.** ML Governance Lead.

---

## Annex A — the controls that get the "applicability"
treatment

Annex A of 42001 is the list of controls the org selects
from. The *statement of applicability* (SoA) is the
document that names, per control, whether it applies, and
if so how it is implemented and evidenced.

The Annex A groups (from 42001:2023):

- **A.2 Policies related to AI.** AI policy exists;
  alignment with other org policies; review cadence.
- **A.3 Internal organisation.** AI roles and
  responsibilities; reporting of concerns.
- **A.4 Resources for AI systems.** Documentation of
  resources (data, tooling, human, computational); life-
  cycle management.
- **A.5 Assessing impacts of AI systems.** Impact-assessment
  process; documentation of impact.
- **A.6 AI system life cycle.** Objectives for responsible
  AI development; processes for design, testing, deployment,
  operation, monitoring, retirement; documentation.
- **A.7 Data for AI systems.** Data management (acquisition,
  quality, provenance, preparation); data used for
  development and operation.
- **A.8 Information for interested parties of AI systems.**
  System documentation (model cards, system cards);
  information for users; incident reporting to interested
  parties.
- **A.9 Use of AI systems.** Intended-use policy; use
  monitoring.
- **A.10 Third-party and customer relationships.** Supplier
  management; customer-facing responsibilities.

For each Annex A control the SoA records:

- Whether the control is **applicable** to the AIMS scope.
- If applicable, **how** it is implemented (pointer to the
  engineering artefact).
- If not applicable, the **justification**.

The org's engineering pipeline should make the "how" column
mostly mechanical. If Annex A control A.6.2.4 ("processes
for evaluating AI systems throughout their life cycle") is
applicable, the implementation is "MEASURE eval bundle per
model version (chapter 01 MEASURE 2.x), enforced at
admission by policy `aims_control_A_6_2_4.rego` (chapter
04), evidence in `governance/aims/evidence/A.6.2.4/`". The
engineering artefacts already exist; SoA is a re-labelling
exercise.

---

## Statement of Applicability template

The SoA is the *headline* audit artefact. A workable
schema:

```yaml
# aims/statement-of-applicability.yaml
version: 2026.09
audit_scope:
  systems: [prod-recsys, prod-support-assistant, prod-fraud-classifier]
  functions: [ml-engineering, ml-security, ml-governance]

controls:
  - id: A.2.2
    name: "AI policy"
    applicable: true
    implementation:
      description: >
        AI policy `aims/ai-policy.md`, version 2026.03,
        approved by CEO, distributed to all engineering
        staff via onboarding + annual refresher.
      artefacts:
        - aims/ai-policy.md
        - aims/policy-approval-history.yaml
        - training-lms/awareness-completion.csv
    evidence_verification:
      method: quarterly review by ML Governance Lead
      last_verified: 2026-08-14
    cross_refs:
      nist_ai_rmf: [GV-5.1]
      eu_ai_act: [9]      # part of the risk-management-system requirement
      soc_2: [CC1.1]

  - id: A.5.2
    name: "Impact assessment process"
    applicable: true
    implementation:
      description: >
        Per-system impact assessment templated by
        `aims/impact-assessment-template.md`; required at
        design review; refreshed at material scope change
        or annually.
      artefacts:
        - aims/impact-assessment-template.md
        - governance/impact-assessments/**
    evidence_verification:
      method: admission-gate policy `impact_assessment.rego` fails release without a current impact-assessment reference
      last_verified: 2026-09-01
    cross_refs:
      nist_ai_rmf: [MP-3.1, MP-5.1]
      eu_ai_act: [27]      # FRIA
      generative_delta: >
        For GAI systems, the impact assessment enumerates
        dual-use pathways (chapter 01 MAP 3.4.001).

  - id: A.6.2.4
    name: "Processes for evaluating AI systems"
    applicable: true
    implementation:
      description: >
        MEASURE eval bundle per model version, executed at
        release-gate; result stored content-addressed.
      artefacts:
        - eval-plan.yaml (per system)
        - governance/eval-results/**
    evidence_verification:
      method: admission-gate `eval_bundle.rego` (chapter 04)
      last_verified: 2026-09-04
    cross_refs:
      nist_ai_rmf: [MS-2.1, MS-2.7]
      eu_ai_act: [15]

  - id: A.10.3
    name: "Suppliers"
    applicable: true
    implementation:
      description: >
        AI supplier assessment programme (mod-110). All
        production-tier imported models and datasets carry
        a signed supplier assessment.
      artefacts:
        - governance/suppliers/register.yaml
        - governance/suppliers/assessments/**
    evidence_verification:
      method: procurement gate blocks purchase without
        assessment; quarterly re-review by Governance Lead.
      last_verified: 2026-08-30
    cross_refs:
      nist_ai_rmf: [GV-6.1, MG-3.1]
      eu_ai_act: [25]     # obligations across the value chain

  - id: A.9.4
    name: "Intended use of the AI system"
    applicable: true
    implementation:
      description: >
        Every production model card carries `intended_use`
        and `out_of_scope_use` fields; runtime input
        classifier flags out-of-scope requests.
      artefacts:
        - model-card schema
        - runtime/out-of-scope-classifier config
    evidence_verification:
      method: model-card CI check; monitor on out-of-scope
        flag rate
      last_verified: 2026-09-02
    cross_refs:
      nist_ai_rmf: [MP-1.1, MG-4.1]

  - id: A.4.3
    name: "Computing resources"
    applicable: false
    justification: >
      Control addresses documentation of computing resources.
      In-scope systems all run on the shared platform whose
      compute inventory is maintained under the parent 27001
      programme (control A.8.1.1 in 27001 SoA). Reference
      that inventory rather than duplicating.
    cross_refs:
      iso_27001: [A.8.1.1]
```

Two properties an SoA has to have:

1. **Every applicable control has an artefact pointer that
   resolves.** Auditors will spot-check. A pointer to
   `governance/evidence/foo/` that is empty is a nonconformity.
2. **Every non-applicable control has a written
   justification.** "Not applicable" is not a justification.
   A justification either points at a scope boundary ("we
   don't develop foundation models") or at an alternative
   control ("addressed by parent 27001 SoA control X").

---

## Extending the chapter 01 matrix

Recall chapter 01's unified matrix schema. The ISO 42001
extension is straightforward — the control-mapping matrix
gains an `iso_42001` block per row:

```yaml
- id: NIST-AI-RMF.MP-5.1
  function: MAP
  ...
  cross_refs:
    iso_42001:
      clauses: [6.1.2, 6.1.4, 8.2, 8.4]
      annex_a: [A.5.2, A.5.3]
    ...
```

The mapping between NIST sub-categories and 42001 clauses is
*many-to-many* — one 42001 clause typically implements
several NIST sub-categories, and vice versa. Do the mapping
once, per organisation's actual controls, and version it.
The published NIST–ISO 42001 crosswalks in the literature are
starting points, not final answers.

For the SoA specifically, the mapping direction is inverted:
the SoA lists Annex A controls and points at the engineering
artefacts and NIST sub-categories they implement. Both views
are useful; the underlying data is the same.

---

## What certification actually requires

The audit path (via an accredited certification body):

- **Stage 1 audit.** Documentation review. The auditor
  reads the scope, policy, SoA, risk-treatment plan, and
  internal-audit programme. Finds gaps ("your SoA doesn't
  cover A.7.5"; "your risk assessment doesn't include
  training-data poisoning"). The org fixes.
- **Stage 2 audit.** Operation review. The auditor
  requests records demonstrating the AIMS is operating —
  audit reports, corrective-action records, management-
  review minutes, impact-assessment samples, incident
  records. Findings are classified as **major**
  nonconformities (block certification), **minor**
  nonconformities (require corrective-action plan), and
  **observations** (advisory).
- **Surveillance audits.** Annual (typically), narrower
  scope; certifier revisits parts of the AIMS to confirm
  continued operation.
- **Re-certification audits.** Every 3 years; full re-
  audit.

The audit cadence dictates the engineering discipline. If
management review is meant to happen annually, and the
audit falls in month 14, the certifier will find no record
of the year-14 management review if you haven't held it.

The org's operational cadence must exceed the audit
cadence, not match it. Semi-annual management review, monthly
risk-treatment review, quarterly SoA review, weekly control
verification (via chapter 04's admission-gate policies).

---

## Interaction with parent 27001 (and other management-system standards)

If the org already runs a 27001 AIMS, 42001 can share
common infrastructure — internal audit function, management-
review meetings (integrated agenda), corrective-action
tracker, competence and training programme, documented-
information controls, non-conformity register.

The 42001 additions on top of 27001 are:

- **AI-specific policy** (Clause 5.2) distinct from the
  information-security policy.
- **AI system impact assessment** (Clause 6.1.4 and Annex
  A.5) — not present in 27001.
- **AI-specific data-management controls** (Annex A.7)
  extending 27001 A.8 (asset management) with training-data,
  eval-data, and post-deployment-data considerations.
- **AI-specific supplier management** (Annex A.10) extending
  27001 A.5.19–5.23 (supplier relationships) with third-
  party model, dataset, and hosted-model API considerations.
- **AI-specific user information** (Annex A.8) — model cards,
  system cards, transparency to downstream users.
- **AI-specific incident reporting** — often overlaps with
  27001 A.5.24–5.28 (information-security incident
  management) but adds outcome monitoring, harm reporting,
  and (for high-risk) regulator notification.

The integrated-management-system pattern is: one document
set with 42001-specific extensions; one audit programme with
AI-scoped rounds; one management review with an AI-scoped
agenda item. Cheaper to run and simpler to defend than two
parallel programmes.

---

## Standard failure modes

- **SoA claims "applicable" but no artefact.** The most
  common finding. Fix: SoA schema requires resolving
  `artefacts` paths at commit time via a CI check.
- **SoA claims "not applicable" without justification.**
  Fix: `justification` is required whenever `applicable`
  is false.
- **Documented information not controlled.** Documents live
  on personal drives, shared Google Docs, wikis without
  history. Fix: Clause 7.5 says version control; make it
  literal — everything in a versioned repo with review
  workflows.
- **Management review that did not happen.** Auditor asks
  for minutes; there is a placeholder. Fix: management
  review is a scheduled meeting on the calendar, with
  agenda template, and a follow-up template that generates
  minutes automatically.
- **Impact assessments back-filled at audit time.** Fix:
  admission gate blocks deployment without a current
  impact assessment (chapter 04).
- **Objectives that are not measurable.** "Improve model
  safety" is not an objective. Fix: every objective in
  6.2 has a metric, a target, and a review cadence.
- **Corrective-action tracker unread.** Nonconformity is
  logged, ticket sits open indefinitely. Fix: SLA on close;
  breach alerts to Governance Lead; management review
  reads the register.
- **AIMS scope narrower than the actual work.** The scope
  excludes the LLM programme because "it isn't in scope
  yet". Fix: scope statement justifies exclusions; ambiguous
  exclusions become audit findings.
- **Statements about generative AI omitted from the SoA
  entirely.** Fix: the SoA notes how each Annex A control
  applies to generative-AI systems where the delta from
  classical ML is material.
- **Auditor asked "who owns X" and there is no answer.**
  Fix: every AIMS artefact has an `owner` field; the RACI
  is complete for AIMS operation.

---

## Summary

- ISO/IEC 42001 is a certifiable AI Management System
  standard. Clauses 4–10 are the management-system shell;
  **Annex A** is the AI-specific control catalogue.
- Every clause is auditable by **records**, not policy
  alone. The engineering deliverable per clause is the
  artefact that produces those records as a by-product of
  normal work.
- The **Statement of Applicability** — for each Annex A
  control, applicable-with-implementation or not-with-
  justification — is the headline audit artefact after the
  AI policy.
- The **AI system impact assessment** (Clause 6.1.4) is a
  42001 addition beyond 27001; it aligns with EU AI Act
  Article 27 (chapter 03) and NIST MAP 3.x (chapter 01).
- Certification requires **operational evidence**
  (management-review minutes, audit reports, corrective-
  action records) at a cadence that exceeds the audit
  cadence. Every 3 years is not a rate; monthly, quarterly,
  and semi-annually is a rate.
- The chapter 01 unified control matrix gains an
  `iso_42001` cross-ref block per row. The SoA and the
  matrix are two views of the same data.
- If a 27001 AIMS already exists, run 42001 as an
  integrated extension: shared audit, shared management
  review, shared documented-information controls.
