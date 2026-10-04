# Chapter 03 — Running the CISO / Legal / AI Governance Interface

> **Note on AI-assisted content.** Specific org-chart
> placements of CISO, General Counsel, Chief AI Officer,
> Chief Privacy Officer, and ML/Model Risk functions vary
> widely by sector and company. The patterns in this
> chapter are structural; map them onto your organisation's
> actual reporting lines before adopting any artefact.

---

## Why this chapter exists

The ML-security programme does not operate in a bubble.
Its decisions are consumed by, and depend on, at least
three sibling functions:

- **CISO / enterprise security.** Owns the enterprise
  control library (chapter 01 is a *section* of their
  library), the SOC (mod-111 chapter 05), the identity
  programme, the incident-response programme at the
  enterprise level, and the board-facing security
  posture.
- **Legal / General Counsel.** Owns the regulatory
  surface, contracts with model providers, customer
  terms, breach-notification determinations, and the
  interface with external counsel and regulators
  (chapter 05).
- **AI Governance.** Owns the AI-specific policy
  framework (mod-109), the model-risk register, the
  frontier-tier gating (mod-109 chapter 06), and the
  interface with the board's AI oversight.

In large organisations each of these is a function
with its own leadership — CISO, General Counsel, Chief
AI Officer or head-of-AI-governance (the level-60
boss, in the vocabulary of this curriculum). The
ML-security programme-lead's job is to run the
*interface* with them deliberately: a quarterly
working cadence, a defined review cadence for
in-flight work, and an escalation path with named
decision rights.

The failure mode this chapter is written against:

> The ML-security programme ships controls; legal is
> only informed when a regulator writes to the general
> counsel's office; the CISO's quarterly board report
> reports AI-security as "coverage improving" because
> there is no feed; AI governance publishes a frontier-
> tier policy that bans a capability the ML-security
> team has already installed a workaround for. Each
> function is doing good work; the lack of a running
> interface means the organisation gets caught between
> their decisions.

The interface is not a stakeholder list. It is a
set of scheduled interactions, documented decision
rights, and an escalation path that is tested before
it is needed.

You leave this chapter able to:

- Describe the three sibling functions and the
  interfaces each needs with ML-security.
- Design the quarterly working session agenda and
  cadence.
- Design the per-engagement review cadence that keeps
  mid-flight engagements synchronised with the siblings.
- Design the escalation path for a mid-engagement
  decision that exceeds the programme-lead's authority.
- Avoid the standard failure modes: ad-hoc meetings,
  siloed decisions, escalation-path untested until
  it's needed.

---

## The three sibling functions in detail

### CISO / enterprise security

Decision rights the CISO retains for AI-security:

- The control-library *catalogue* owns the AI-security
  section at the schema level; the ML-security
  programme-lead owns the content.
- SOC paging, severity-ladder alignment (mod-111
  chapter 04), and SOC capacity.
- Identity and access management primitives
  (workload identity, SSO, MFA policy).
- Incident-command authority during enterprise-grade
  incidents (chapter 05 and mod-111 chapter 03/05).
- Board-level security reporting.

Decision rights the CISO delegates to the ML-security
programme-lead:

- Author and lifecycle of controls in the AI-security
  section.
- ATLAS coverage decisions and release-gate controls
  specific to ML systems.
- Red-team and adversarial-eval scoping within the ML
  programme.
- Detection content authoring for ML workloads (mod-
  111 chapter 01) within SOC's standards.

Shared decisions:

- SIEM-content promotion to paging (programme-lead
  authors, CISO's SOC accepts into paging rotation).
- Incident severity assignments at the boundary of
  AI-specific and enterprise taxonomies.
- Metrics selected for the board-level security
  report (chapter 04).

### Legal / General Counsel

Decision rights legal retains:

- All legal opinion. The programme-lead supplies
  evidence; counsel renders opinion.
- Breach-notification determinations under HIPAA,
  GDPR, state law.
- Regulator-facing communication (chapter 05).
- Contract terms with model-provider vendors (what
  the vendor commits to, what evidence they produce,
  what indemnities apply).
- Customer-facing terms (what the organisation
  commits to about its AI systems).
- Litigation-hold decisions.

Decision rights legal delegates to the programme-lead:

- Evidence collection and attestation (chapter 01).
- Technical content of regulator-support artefacts
  before legal review (chapter 05).
- Threat-model and control-coverage representations
  within the agreed template, pre-counsel review.

Shared decisions:

- When to escalate a security finding to a legal
  review (programme-lead flags; counsel decides what
  response is required).
- When a vendor contract clause needs renegotiation
  because evidence requirements changed (programme-
  lead sees the technical mismatch; counsel owns the
  renegotiation).
- The regulatory-triggered scope changes to in-flight
  engagements (chapter 02).

### AI Governance / head-of-governance (level 60)

Decision rights AI governance retains:

- The AI policy framework at the organisational level
  (mod-109 chapter 01-06).
- Model-risk register at the portfolio level.
- Frontier-tier gating (mod-109 chapter 06).
- Portfolio-wide AI metrics for the board (chapter 04).
- Interface with the board's AI oversight committee.

Decision rights AI governance delegates to the
programme-lead:

- ML-security section of the control library (chapter
  01).
- Security-specific release-gate controls.
- Technical content of security-related governance
  evidence.

Shared decisions:

- Frontier-tier promotion / demotion when security
  evaluations are a required input (mod-109 chapter
  06).
- Portfolio-level coverage priorities when budget is
  constrained.
- Metrics selected for the board-level AI report
  (chapter 04).

---

## The quarterly working session

The quarterly working session is the ritual that keeps
the three interfaces synchronised. It is a *working*
session, not a status readout: decisions are taken, not
merely reported.

### Attendees

- ML-security programme-lead (owner).
- CISO or delegate.
- GC's AI-security partner (an attorney with sign-off
  on AI matters, not a scheduled rotator).
- Head of AI governance (or delegate at level 60's
  discretion).
- Head of SOC (invited for the SOC-interface portion).
- Chief Privacy Officer or DPO (invited for the
  privacy portion when a quarter's work touches
  mod-108).

Rotating guests:

- Model Risk Officer (sector-dependent; standing
  guest in financial services).
- Clinical Affairs lead (healthcare).
- Business-unit security leads whose portfolio was
  affected by the quarter's engagements.

The session cannot be scheduled with "the first
available calendar time of each attendee"; it is a
reserved standing slot held open on the quarter's
scheduling spine, with the session's agenda owning
the preparation window.

### Standing agenda

The agenda is published two weeks in advance with
pre-read materials. One ninety-minute session,
roughly:

1. **Portfolio-level coverage review (15 min).**
   The ML-security metrics package (chapter 04)
   version in-force at the start of the quarter is
   walked through: ATLAS coverage %, vulnerability
   burn-down, SLSA attainment, IR MTTD/MTTR for AI
   incidents. Deltas since last quarter and reasons.
2. **Engagement portfolio (20 min).** Each live
   engagement (chapter 02) with status, cost burn,
   coverage delta, and any sponsor-escalations
   pending. Engagements that need a scope-change
   decision are flagged.
3. **Control-library changes (10 min).** New
   controls, deprecations, supersessions in the
   AI-security section since last quarter. MAJOR
   changes are approved here; MINOR changes are
   reported.
4. **Incident retrospectives (15 min).** AI-related
   incidents since last quarter. The ones under
   litigation hold are referenced by number only;
   legal's handling of them is reported procedurally,
   not substantively.
5. **Regulatory horizon (10 min).** Legal walks
   through regulatory developments: EU AI Act
   implementing acts, state laws, sector-regulator
   signals, enforcement actions in sibling
   organisations. The programme-lead presents the
   security-side implications.
6. **Decisions (15 min).** Explicit decision list,
   each with a decision-record ID that lands in the
   control-library audit trail. "Noted" is not a
   decision; "accept risk until Q+1 subject to
   review" is.
7. **Next quarter's priorities (5 min).** The
   coverage targets for next quarter and the
   engagements planned.

### Decision records

Every decision taken in the session produces a
record:

```yaml
decision_id: DEC-2025-Q3-07
session: 2025-Q3 working session
date: 2025-07-14
decision: >
  Accept partial coverage of AML.T0024.001 across the
  recommender-model portfolio for 2025-Q3 pending the
  DP-SGD budget allocation decision in 2025-Q3 budget
  cycle.
rationale: >
  Full coverage requires DP-SGD training re-runs
  costed at $380k GPU-hours. Portfolio prioritisation
  places this behind the LLM-agent HITL work.
decided_by:
  - ml-security-programme-lead
  - head-of-ai-governance
  - ciso (concurring)
expires: 2025-10-01
review_at: 2025-Q4 working session
tracks:
  - engagement: ENG-2025-038
  - control: AISEC-PRIV-002
```

The record is signed, lands in the evidence store,
and surfaces on next quarter's agenda when it
expires. Decisions that drift out of memory are
decisions that have to be re-litigated.

---

## The in-engagement review cadence

Between quarterlies, each in-flight engagement needs
a lightweight review cadence so decisions are not
deferred to the quarterly:

- **Weekly operational standup** (programme-lead +
  engagement engineers). Internal; not for sibling
  functions.
- **Biweekly engagement sync** (programme-lead,
  sponsor, affected business unit). The sponsor
  tracks cost burn and coverage delta.
- **Monthly interface check-in** (programme-lead,
  CISO delegate, GC's AI-security partner, head of
  AI governance's delegate). Thirty minutes.
  Agenda:
  - Any engagement with a scope-change proposal.
  - Any finding that may trigger a legal review.
  - Any control-library MAJOR change in draft.
  - Any coverage metric that has deteriorated
    since the last quarterly.

The monthly is where a decision that *could* wait
for the quarterly is tested: either resolved now, or
deliberately deferred to the quarterly with a
decision-record. "Deferred by inaction" is the
anti-pattern.

### Escalation path

Decisions that exceed the programme-lead's authority
have a path. It is tested with a tabletop twice a
year and documented so a new programme-lead can run
it from the artefact.

| Decision type                                                 | Programme-lead | +Sibling | +Head of function | +Exec |
|---------------------------------------------------------------|----------------|----------|-------------------|-------|
| Add a new control to the AI-security section (MINOR)          | Yes            | —        | —                 | —     |
| Change a control's intent (MAJOR)                             | Draft          | Decides  | —                 | —     |
| Install a new release-gate requirement at hard-block severity | Draft          | Decides  | —                 | —     |
| Grant override of a hard-block release-gate (≤14 days)        | Decides        | Informs  | —                 | —     |
| Grant override of a hard-block release-gate (>14 days)        | Draft          | Draft    | Decides           | —     |
| Change the detection severity of an in-force rule             | Draft          | Decides  | —                 | —     |
| Scope-expand an engagement >25 % of initial cost              | Draft          | —        | Decides           | —     |
| Scope-contract an engagement that leaves a top-N uncovered    | Draft          | Draft    | Decides           | —     |
| Accept risk on an uncovered top-N for >1 quarter              | Draft          | Draft    | Draft             | Decides |
| Vendor contract renegotiation (security evidence terms)       | Flags          | GC leads | —                 | —     |
| Regulator-facing communication                                 | Supplies       | GC leads | —                 | —     |
| Litigation-hold instruction                                    | Executes       | GC decides | —                | —     |

"Sibling" here means the counterpart function
whose decision rights the row touches: for release-
gate items the CISO delegate; for regulatory items
the GC partner; for control-library items the head of
AI governance's delegate.

The escalation path is not a hierarchy; it is a
decision-rights map. Running an item up the ladder
when it did not need to be is as expensive as not
escalating something that did.

---

## RACI, briefly

A compact RACI pinned to the engagement template
avoids re-arguing roles on every engagement:

| Activity                                            | ML-sec PL | CISO | GC  | Head AI Gov | Sponsor |
|-----------------------------------------------------|-----------|------|-----|-------------|---------|
| Author AI-security control                          | R, A      | C    | I   | C           | I       |
| Approve MAJOR control change                        | R         | C    | I   | A           | I       |
| Install release-gate requirement                    | R, A      | C    | I   | I           | C       |
| Approve release-gate override                       | R, A      | C    | I   | I           | I       |
| Collect evidence for an audit                       | R, A      | C    | C   | I           | I       |
| Supply evidence to a regulator                      | R         | C    | A   | C           | I       |
| Render legal opinion on a security finding          | I         | I    | R, A | I           | I       |
| Determine breach-notification obligation            | I         | C    | R, A | I           | I       |
| Promote detection content to paging                 | R         | A    | I   | I           | I       |
| Portfolio AI metrics on board report                | R         | C    | I   | A           | I       |

R responsible, A accountable, C consulted, I informed. The
column that an audit will question is the A column; a
control with no A is a control that stalls.

---

## Standard failure modes

- **Ad-hoc engagement.** No standing quarterly, no
  monthly interface check-in; interactions happen when
  something is on fire. Fires compound.
- **Status readouts, not working sessions.** A
  quarterly where no decision is taken is a status
  report with lunch; schedule it as such and run the
  real working session elsewhere.
- **Decisions in meetings, not in writing.** A
  decision that is not in a signed record did not
  happen. The next quarter will re-litigate it.
- **Legal consulted at the end.** Counsel brought in
  for the first time at regulator-engagement moment
  will spend the first week catching up. The monthly
  interface check-in prevents this.
- **Shadow control library.** The ML-security team
  maintains a "working copy" of the controls because
  the GRC platform is too slow. Shadow copies drift;
  the audit will catch the drift.
- **Untested escalation path.** The path works until
  the first escalation; then the person two levels
  up has not seen the format and the hour is spent on
  explaining the artefact instead of making the
  decision. Run two tabletops a year.
- **Decision records that expire into memory.** The
  quarterly agenda has to pull up expiring decisions
  automatically or they rot in the archive. Decision
  rot is risk rot.
- **One-way reporting to the CISO.** A quarterly
  report with no round-trip is a monologue. The
  interface is bidirectional: the CISO's inputs on
  SOC capacity, identity programme, and board context
  shape next quarter's ML-security plan too.

---

## Summary

- The ML-security programme-lead operates three
  structured interfaces: with the CISO, with legal,
  and with the head of AI governance.
- Each interface has defined decision rights — what
  stays with the sibling, what is delegated to the
  programme-lead, what is shared.
- The **quarterly working session** is the primary
  cadence: ninety minutes, pre-read, decisions
  recorded, next-quarter priorities named.
- The **monthly interface check-in** and the
  per-engagement sync keep in-flight work synchronised
  so decisions do not pile up for the quarterly.
- The **escalation path** is a decision-rights map,
  not a hierarchy, documented and tested with
  tabletops.
- A **compact RACI** pinned to the engagement
  template avoids re-arguing roles.
- The standard failure modes are ad-hoc engagement,
  status-only readouts, decisions-not-in-writing,
  legal-consulted-last, shadow libraries, and an
  untested escalation path.
