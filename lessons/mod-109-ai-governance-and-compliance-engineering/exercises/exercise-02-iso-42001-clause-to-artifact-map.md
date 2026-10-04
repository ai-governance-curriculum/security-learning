# Exercise 02 — ISO/IEC 42001 Clause-to-Artefact Map and Statement of Applicability

**Estimated effort:** ~3 hours
**Deliverable:** An **AIMS starter pack** for the organisation
hosting the exercise-01 system, consisting of (a) the ISO 42001
Clause → engineering-deliverable mapping extended into the
unified matrix as a new column, (b) the four auditor-first
documents — scope statement, AI policy, Statement of
Applicability (SoA), risk-treatment plan skeleton — in a shape
an accredited certifier would recognise, and (c) an internal-
audit-programme skeleton that drives the Clause 9.2 record.
**Prerequisites:** Exercise 01 complete and the v0.1 matrix in
hand. Chapter 02 read end-to-end. Access to (or willingness to
stub) the org's existing security management artefacts — the
27001 scope statement if certified, the ISMS risk-treatment
plan if one exists, the top-level security policy. If none
exist, this exercise produces the AI-specific versions from
scratch and names "27001 integration" as a future-state
dependency.

---

## Objective

Chapter 02's claim is that **42001 is audited by evidence of
operation, not by evidence of policy**. This exercise is the
exercise that converts the policy-shaped artefacts the org
has (or needs to write) into the operational hooks a stage-2
auditor can see running.

By the end of this exercise you have:

- An **extended control matrix** with ISO 42001 Clause and
  Annex A control references wired into every row from
  exercise 01, plus any new rows the ISO walk surfaced that
  the AI RMF walk did not.
- A **scope statement** (Clause 4.3) that names what the
  AIMS covers and justifies any exclusions.
- An **AI policy** (Clause 5.2) at the shape and length a
  certifier reads first.
- A **Statement of Applicability** (Clause 6.1.3) for Annex A
  — every control marked applicable (and the row of the
  matrix that implements it) or not-applicable with a
  one-paragraph justification.
- A **risk-treatment plan** skeleton (Clause 6.1.2) that
  references the per-system threat models and the matrix.
- An **internal-audit-programme** skeleton (Clause 9.2):
  twelve-month audit calendar, auditor independence rule,
  non-conformity register schema, corrective-action loop.
- A **management-review template** (Clause 9.3) with the
  agenda a certifier expects.

You are **not** running a stage-1 or stage-2 audit, chasing
accreditation, or writing a full nonconformity response. You
are building the deliverable set a certifier walks through
first.

---

## Problem statement

The target is the same system as exercise 01 (or the same
*portfolio* if the org wants a multi-system AIMS). State
before you start:

- Whether the AIMS being scoped is **standalone** (AI only)
  or **integrated** with an existing 27001 ISMS. The
  Statement of Applicability and the internal-audit
  programme look different in each case.
- Who the **top management** is — the accountable executive
  (CEO, CTO, CPO) who signs the AI policy. If the role is
  not yet appointed, state it and treat the sign-off block
  as pending.
- Whether the org intends to **certify** (external audit by
  an accredited certification body) or **operate** without
  certification. The deliverables are the same shape; the
  acceptance bar is tighter if certifying.

The AIMS scope is deliberately bounded. If the org has only
one production ML system, the AIMS can cover that system
plus the platform under it. If the org has twenty, the
Clause 4.3 statement explains why the AIMS covers (say) the
"enterprise ML platform and the ten production systems that
run on it" and excludes the five customer-managed
deployments. State the boundary; defend it.

---

## Requirements

### Deliverable A — the extended matrix

Load exercise 01's matrix. For every row, populate the
`cross_refs.iso_42001` field (previously stubbed to `null`)
with:

```yaml
cross_refs:
  iso_42001:
    clauses: ["4.1", "6.1.2"]           # the clause(s) the row evidences
    annex_a_controls: ["A.5.2", "A.6.1"] # Annex A controls, if any
```

Rules:

- Every row must have at least one Clause reference. "This
  row is Annex-A-only" is incorrect — Annex A controls land
  under Clause 8 (Operation) when operated.
- A row may reference multiple clauses. GV-1.1 (regulatory
  scope) satisfies Clause 4.1 (context) and Clause 6.1
  (planning).
- If an exercise-01 row has no corresponding Clause, flag
  the row and ask whether the AI RMF sub-category belongs
  in the AIMS at all. (Typically everything does; the question
  is where.)

The ISO walk will reveal gaps: Clauses that no AI RMF
sub-category directly answers (e.g. **Clause 7.2 competence**
has no AI-RMF-specific counterpart but is required by 42001).
For each such gap, **add a new matrix row** with:

- A clause reference (and no AI RMF sub-category, or a note
  "AI RMF indirectly via GOVERN 2.1 training").
- Owner, artefact pointer, verification method.
- Status (`implemented` / `partial` / `planned` / `gap`).

Expect at least five new rows from the ISO walk: 7.1
(resources), 7.2 (competence), 7.3 (awareness), 7.5
(documented information), 9.3 (management review).

### Deliverable B — scope statement (`aims/scope.md`)

One page. Shape:

1. **Organisation** — name; legal entity; locations in
   scope.
2. **Scope boundary** — the AIMS covers the following
   systems, sites, functions, and roles. Each in-scope
   system named and linked to the exercise-01 matrix.
3. **Exclusions** — systems the AIMS does not cover, with a
   written justification per exclusion. Acceptable
   justifications: "deployed and operated by the customer
   under their own AIMS"; "research-only, not in production,
   excluded until operational". Unacceptable: "we did not
   want to deal with that one".
4. **Interfaces** — upstream and downstream systems that
   the AIMS depends on but does not include (data producers,
   hosting providers, downstream consumer applications).
5. **Approval block** — top-management signature line and
   date.

The scope statement is the first document the auditor opens.
Write it so a non-engineer in top management reads it in two
minutes.

### Deliverable C — AI policy (`aims/ai-policy.md`)

Half a page to one page. Clause 5.2 requires:

- **Purpose** — what the AIMS exists to achieve.
- **Framework for setting AI objectives** — one or two
  sentences; the policy does not list the objectives, it
  states how they are set and reviewed.
- **Commitment to satisfying applicable requirements** —
  the regulatory landscape named in the exercise-01 scope
  statement.
- **Commitment to continual improvement** — one sentence.
- **Approval** — top-management signature line, version,
  effective date, next review date.

Do not pad. A six-page AI policy is a nine-page nonconformity
when any one page is contradicted by another. Keep it short
and under version control.

### Deliverable D — Statement of Applicability (`aims/soa.yaml`)

Clause 6.1.3(d) requires a SoA naming the Annex A controls,
their applicability, and the justification. Shape:

```yaml
soa:
  version: 2026.10
  controls:
    - id: A.2.2                      # AI policy
      title: AI policy
      applicable: true
      justification: >
        Required by Clause 5.2 and by every regime in the
        regulatory-scope hypothesis (NIST GV-1.1).
      implementing_matrix_rows: [GV-1.1, GV-5.1]
      implemented: true

    - id: A.3.2                      # AI roles and responsibilities
      title: AI roles and responsibilities
      applicable: true
      justification: >
        Required by Clause 5.3; MLSecurity Lead, ML
        Governance Lead, Product Owner, DPO assigned per
        system.
      implementing_matrix_rows: [GV-2.1]
      implemented: true

    - id: A.5.2                      # AI system impact assessment
      title: AI system impact assessment
      applicable: true
      justification: >
        System touches rights-affecting decisions (Annex III
        hypothesis under EU AI Act); impact assessment is
        the Clause 8.3 artefact.
      implementing_matrix_rows: [MP-3.1]
      implemented: partial            # impact assessment started; peer review not yet complete

    - id: A.6.1                      # AI system lifecycle
      title: AI system life cycle
      applicable: true
      implementing_matrix_rows: [MP-1.1, MS-1.1, MG-1.1]
      implemented: true

    - id: A.7.4                      # Data for AI systems — data provenance
      title: Data provenance
      applicable: true
      implementing_matrix_rows: [custom.data-provenance]  # new row added
      implemented: planned

    # ... every Annex A control, applicable or not
```

Rules:

- Every Annex A control from the published 42001:2023 Annex
  A appears in the SoA. "Not applicable" is a valid value
  with a one-paragraph justification. "Not listed" is a
  nonconformity.
- Every `applicable: true` row either names at least one
  matrix row implementing it or marks the implementation
  `planned` with an owner and a date.
- Any `applicable: false` row justifies the exclusion in a
  way the certifier will accept — "the organisation does
  not use third-party AI models" is a defensible exclusion
  for A.10.* only if the exercise-01 scope confirms it.

If the published Annex A listing is not readily available
(the standard is paywalled), state the version you are
mapping against (e.g. "ISO/IEC 42001:2023 Annex A as
summarised in ISO's own public preview"). Add a `needs-
research: ...` marker where the mapping is uncertain so a
reviewer can validate against the primary text.

<!-- needs-research: cross-check A.* control IDs against the
published 42001:2023 Annex A; the current list reflects the
chapter 02 walk, which was itself written against the public
previews. -->

### Deliverable E — risk-treatment plan skeleton (`aims/risk-treatment-plan.md`)

Clause 6.1.2 requires a risk-treatment plan. The skeleton
contains:

1. **AI risk-assessment method.** A short description of
   how AI risks are identified, analysed, and evaluated.
   Reference the mod-102 threat-modelling practice and the
   exercise-01 matrix MAP rows.
2. **Treatment options matrix.** For each identified
   high-level AI risk, state the treatment option — avoid,
   mitigate, transfer, accept — and the matrix row(s)
   implementing the treatment.
3. **Residual-risk acceptance process.** Who signs off on
   residual risks and under what criteria. Cross-reference
   the GV-2.1 RACI and the Clause 5.1 top-management
   authority.
4. **Monitoring and review of risks.** How often the
   treatment plan is reviewed (quarterly is typical);
   cadence of per-system risk-register review.

Do not fill the plan with every per-system risk; that's a
Clause 8.2 artefact. The plan explains the *method*; the
system-level registers are the records.

### Deliverable F — internal-audit programme (`aims/internal-audit-programme.yaml`)

Clause 9.2 requires an internal audit at planned intervals
and auditor independence from the activity audited. Shape:

```yaml
audit_programme:
  version: 2026.10
  cycle_months: 12
  rules:
    - auditor_independence: >
        An auditor shall not audit activities for which they
        are directly responsible. ML Security Lead cannot
        audit the ML security controls they operate; a peer
        role or an external auditor is engaged.
    - evidence_rule: >
        Every audit finding references the matrix row and the
        artefact that failed. Findings without pointers are
        unenforceable.
  audits:
    - id: audit-2026-Q4-1
      scope: Clauses 4, 5, 6                        # context + leadership + planning
      systems: [prod-cv-screener]
      auditor_role: internal-audit-lead
      planned_window: 2026-11-02..2026-11-13
      deliverables: [report, nonconformity-list, corrective-action-tracker]
    - id: audit-2027-Q1-1
      scope: Clause 8                               # operation
      systems: [prod-cv-screener, prod-recsys]
      auditor_role: external-contractor
      planned_window: 2027-02-02..2027-02-13
    - id: audit-2027-Q2-1
      scope: Clauses 9, 10                          # performance + improvement
      systems: all-in-scope
      auditor_role: internal-audit-lead
      planned_window: 2027-05-04..2027-05-15
  nonconformity_schema:
    - id
    - audit_id
    - clause
    - matrix_row
    - description
    - severity                    # minor / major
    - corrective_action
    - owner
    - due_date
    - status                      # open / in-progress / closed-verified
```

Rules:

- Every clause (4 through 10) is covered by at least one
  audit per 12-month cycle. The AIMS cannot stay stage-2-
  ready if Clauses 6 and 10 were last audited eighteen
  months ago.
- Each audit's `auditor_role` has to be independent of the
  activity. If the org is too small for role independence,
  the audit is contracted externally; state that in the
  rules.
- Nonconformities and corrective actions have due dates and
  owners. The absence of a corrective-action loop is itself
  a nonconformity under Clause 10.1.

### Deliverable G — management-review template (`aims/management-review-template.md`)

Clause 9.3 requires management review at planned intervals.
The template fixes the agenda — the inputs the certifier
will check for in the minutes:

1. Status of actions from previous management review.
2. Changes in external and internal issues relevant to the
   AIMS.
3. Information on AIMS performance:
   - Audit results (from Deliverable F).
   - Measurement results (which exercise-01 MEASURE rows
     ran, and what they said).
   - Nonconformities and corrective actions.
   - Status of risk treatment (from Deliverable E).
   - Status of risks and opportunities.
4. Feedback from interested parties.
5. Opportunities for continual improvement.
6. Decisions and allocation of resources.

Each management-review session instantiates the template.
The minutes are the Clause 9.3 record.

---

## Starter guidance

- **Write the scope first.** Everything else — SoA,
  internal-audit programme, management-review agenda —
  references the scope. If the scope is wrong, every
  downstream document is wrong.
- **Reuse the exercise-01 matrix.** The ISO cross-references
  are almost entirely a labelling exercise once the AI RMF
  rows exist. Do the labelling; add the five or so new rows
  for the ISO-only clauses; move on.
- **For the AI policy, imitate a 27001 security policy if
  one exists.** Length, tone, approval structure. If
  nothing exists, imitate ISO's own structure — the AIMS
  model is deliberately 27001-shaped.
- **For the SoA, mark controls `applicable: false` when
  they genuinely are.** Over-inclusive SoAs are a common
  anti-pattern. If the org does not use third-party models,
  A.10.* exclusions are legitimate.
- **For the audit programme, pick a cadence you can keep.**
  Over-ambitious cadences that slip are a Clause 9.2
  finding; a sustainable cadence that holds is not.
- **For the management-review template, map Clause 9.3's
  bullet list to agenda items.** The certifier reads 9.3
  with the agenda in one hand and the minutes in the other.
  Make the mapping obvious.

---

## Acceptance criteria

A passing AIMS starter pack:

- Every exercise-01 row has at least one `cross_refs.iso_42001`
  entry (or the row is marked "AI-RMF-only, parked for future
  SoA review" with a dated note).
- New matrix rows for Clauses 7.1/7.2/7.3/7.5/9.3 are present
  with owners, artefact pointers, and status.
- Scope statement states the systems in scope, the
  exclusions with justification, and the top-management
  approval.
- AI policy is under version control, cites applicable
  requirements, commits to continual improvement, and names
  its approver.
- Statement of Applicability covers every Annex A control
  with `applicable: true/false` and a justification; every
  applicable control is linked to at least one matrix row
  or marked `planned` with an owner.
- Risk-treatment plan skeleton names the method, treatment
  options, residual-risk acceptance process, and review
  cadence.
- Internal-audit programme has ≥ 3 audits planned over the
  next 12 months, covers every clause 4–10 at least once,
  names auditor roles with independence rules, and defines
  the nonconformity schema.
- Management-review template matches the Clause 9.3 agenda.

A failing starter pack:

- Scope statement with no exclusions or no justification for
  exclusions.
- SoA that lists `applicable: true` for every Annex A
  control without matrix evidence (`applicable: true,
  implemented: implemented` on every row is a flag).
- SoA missing controls — a partial SoA is a nonconformity
  on its own.
- Audit programme that puts all audits on the same auditor,
  violating independence.
- AI policy that is nine pages of marketing text with no
  commitment to applicable requirements.
- Risk-treatment plan that lists per-system risks (that's a
  Clause 8 artefact) and nothing about the method.

---

## Stretch goals

- **Integrated 27001+42001 Statement of Applicability.** If
  the org has a 27001 ISMS, produce a single SoA that
  covers both standards' control catalogues with a shared
  column structure. The chapter 02 recommendation that
  27001 and 42001 be run together finds concrete form.
- **Stage-1 readiness checklist.** Walk the standard
  stage-1 scope — scope statement, policy, risk-assessment
  method, SoA, internal-audit evidence — and self-score
  readiness. Flag the top three gaps the stage-1 auditor
  would raise.
- **Nonconformity register seeded with real gaps.**
  Instantiate the Deliverable F nonconformity schema with
  the gaps from exercise 01's gap list. Produces the
  starting state of the corrective-action loop before
  stage 1.
- **Clause 8.3 AI system impact assessment template.** The
  template Clause 8.3 requires (impact of the AI system on
  individuals, groups, society; cross-ref to EU AI Act
  Article 27 FRIA from exercise 03). Produces the shared
  artefact exercise 03 extends.
- **Supplier-register template.** The A.10.* controls on
  third-party relationships need a supplier register. Draft
  the register schema (one row per imported model / dataset
  / hosted API) and reference it from the SoA. Lines up
  directly with mod-110 and chapter 06's imported-capability
  posture.
- **42001 ↔ 27001 Annex A gap map.** For each 42001 Annex A
  control, identify the nearest 27001:2022 Annex A control
  (where one exists) and the delta — the 42001 extension
  that 27001 does not cover. Produces the paper the CISO
  uses to argue "we already have 27001; what else does
  42001 need?"

---

## Do not

- Do not write the AI policy to "cover every regime". A
  policy that quotes GDPR, HIPAA, EU AI Act, SR 11-7, FDA
  GMLP in-line is a document no one reads. Reference the
  regulatory-scope register; cover the commitments at
  policy altitude; leave the per-regime detail in the matrix.
- Do not mark Annex A controls `not applicable` because
  implementation is hard. "Hard" is a Clause 10 opportunity-
  for-improvement, not a Clause 6.1.3 exclusion.
- Do not pull live auditor records into this exercise. If
  the org is already in a real audit cycle, use the
  exercise to produce the shadow starter pack; do not touch
  the production auditor's artefacts.
- Do not treat the internal-audit programme as a theatre
  exercise. The programme is the thing that drives
  nonconformity closure. A programme that runs and surfaces
  no findings in a 12-month cycle is a programme that is
  not being run.
- Do not conflate "scope" with "ambition". The AIMS scope is
  what you are willing to be audited on today. Growth is
  Clause 10's job.
- Do not commit the solution starter pack to this repo.
  Solutions live in the paired `-solutions` repo.
