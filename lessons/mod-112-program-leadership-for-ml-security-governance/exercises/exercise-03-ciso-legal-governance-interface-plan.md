# Exercise 03 — CISO / Legal / AI Governance Interface Plan

**Estimated effort:** ~3 hours
**Deliverable:** A committed interface-operations plan for
the ML-security programme-lead's running interface with
the CISO, General Counsel, and head of AI governance
(level 60), consisting of (a) a **stakeholder map** that
names the three sibling functions in your organisation
(or a plausible org), the specific roles the interface
runs with, and the decision rights each function retains
vs. delegates to the programme-lead; (b) a **quarterly
working-session design** — attendees, standing agenda,
pre-read package, decision-record template; (c) a
**per-engagement review cadence design** — weekly
operational standup, biweekly engagement sync, monthly
interface check-in — with agendas and attendees for each;
(d) an **escalation path** expressed as a decision-rights
matrix across the categories in chapter 03, calibrated to
your organisation's actual approval authorities;
(e) a **RACI chart** for the operational activities in
chapter 03, extended with any organisation-specific
activities; (f) a **tabletop exercise plan** for the
escalation path — one scenario walked through end-to-end
with the stakeholders and the artefact flow; and
(g) **three worked decision records** showing the
quarterly's output shape on three different kinds of
decisions.
**Prerequisites:** Chapter 03 read end-to-end. Access to
your organisation's actual CISO, Legal, and AI-governance
org chart (or a credible model). Familiarity with
chapter 01 (control library) and chapter 02 (engagement
scope) since the interface references artefacts from both.

---

## Objective

Chapter 03's claim is that the running interface with
the sibling functions determines whether the ML-security
programme is coherent with the rest of the organisation
or operates in a silo. This exercise is where you
design, calibrate, and tabletop the interface for your
organisation.

By the end of this exercise you have:

- A **stakeholder map** that is specific to your
  organisation — named roles, decision rights, and
  the delegation each has agreed to.
- A **quarterly working-session design** that is
  schedulable and produces decision records, not
  status updates.
- A **per-engagement cadence** that handles mid-flight
  decisions without burdening the quarterly.
- An **escalation path** that is tested rather than
  theoretical.
- A **RACI** calibrated to your organisation.
- A **tabletop plan** that would surface interface
  defects before a real crisis does.
- **Decision records** showing the output of the
  interface in practice.

You are **not** running the actual quarterly in this
exercise. You are producing the design and the
artefacts that make the quarterly run.

---

## Problem statement

If you have a real organisation to design for, use it;
the exercise is better grounded. If you do not, use a
plausible mid-size organisation with:

- A CISO reporting to CIO or CTO.
- A General Counsel's office with an AI-specific
  partner or group.
- A head of AI governance (level 60 in this
  curriculum's vocabulary; title varies — Chief AI
  Officer, Head of AI, Head of Responsible AI, Head
  of Trustworthy AI).
- A SOC that is part of the CISO's organisation.
- A Model Risk Officer in sector-regulated contexts
  (financial services, healthcare, insurance).
- A Chief Privacy Officer / DPO.

State at the start of your deliverables:

- The organisation (real or hypothetical) with its
  sector.
- The reporting lines of the four principal roles
  (ML-security programme-lead, CISO, GC's AI
  partner, head of AI governance).

---

## Requirements

### Deliverable A — stakeholder map

For each of the three sibling functions:

- The specific role or role-pair that is the
  programme-lead's primary interface (e.g. "the
  CISO's deputy for enterprise architecture + the
  CISO's SOC director").
- The decision rights the function retains for the
  ML-security scope.
- The decision rights the function delegates to the
  programme-lead.
- The decisions that are shared.

Beyond the three primaries, name:

- The SOC leader, the Model Risk Officer (if
  applicable), the Chief Privacy Officer, the Chief
  AI Officer (if separate from the head of AI
  governance), and the Chief Information Officer
  as adjacent stakeholders.
- The business-unit security partners whose
  portfolios the programme-lead's engagements touch.

Include an interface-contract memo (≤1 page) that the
four principals would sign to formalise the delegation
pattern. The memo is specific: it does not say
"appropriate collaboration"; it says "the ML-security
programme-lead has author-and-publish authority on
AISEC-* controls up to MAJOR change; MAJOR changes
require [specific role]'s approval".

### Deliverable B — quarterly working-session design

The quarterly's full operating specification:

- Attendees (owner, principals, standing guests,
  rotating guests, invitation criteria).
- Date mechanism — standing slot vs. floating; who
  owns protection of the slot.
- Pre-read package: what is sent, when it is sent,
  who signs it.
- Standing agenda, in time budget (chapter 03's
  shape or a documented variation).
- Decision-record template (reproduce in full; not
  a sentence saying "we have a template").
- Follow-up mechanism — expiring decisions, next-
  quarter agenda construction.

Include a **sample pre-read package** against a
hypothetical quarter end-state. The pre-read is
real content: a trimmed metrics package (chapter 04),
an engagement portfolio summary (chapter 02), a
control-library-change list (chapter 01), an
incident-retro summary (mod-111), a regulatory-
horizon brief.

### Deliverable C — per-engagement cadence design

The three sub-cadences from chapter 03:

- **Weekly operational standup** — attendees, time
  budget, agenda, artefact.
- **Biweekly engagement sync** — attendees (sponsor
  + programme-lead + affected business unit),
  agenda, artefact.
- **Monthly interface check-in** — the critical
  one; attendees (programme-lead + CISO delegate +
  GC's AI partner + head of AI governance's
  delegate), standing agenda, decision-record
  mechanism, artefact.

For each, include a sample artefact (standup notes,
engagement-sync memo, monthly check-in minutes with
decisions).

### Deliverable D — escalation path

A decision-rights matrix (chapter 03 shape) covering
the categories in that chapter plus any organisation-
specific categories:

- Control-library changes (PATCH / MINOR / MAJOR).
- Release-gate requirement installation and
  overrides.
- Detection severity changes.
- Engagement scope changes (expansion, contraction,
  accept-risk).
- Regulator-facing items.
- Vendor contract renegotiation.
- Litigation-hold instruction execution.

Each row names: who drafts, who approves, who is
informed, what artefact triggers the row.

Alongside the matrix, include an **escalation-path
runbook** — a step-by-step document a programme-
lead who inherited the role tomorrow could execute
from.

### Deliverable E — RACI chart

The RACI from chapter 03 extended for your
organisation's specific activities. The chart has:

- Columns: ML-sec PL, CISO delegate, GC's AI
  partner, head of AI governance (or delegate),
  Sponsor, SOC director, Model Risk Officer,
  Chief Privacy Officer, as applicable.
- Rows: at least 15 operational activities,
  including every category in the escalation
  matrix plus activities not in the matrix (e.g.
  "publish quarterly metrics", "author red-team
  scope", "approve detection content for paging").
- R / A / C / I in each cell; no cell empty.
- The A column consistent with the escalation
  matrix.

### Deliverable F — tabletop exercise plan

A plan for a 90-minute tabletop that exercises the
escalation path on one scenario end-to-end. Choose
a scenario — a mid-engagement regulator query, a
proposed MAJOR change to a release-gate control, a
disputed accept-risk on an uncovered top-N for a
second quarter. The plan:

- The scenario in a short narrative.
- The intended participants (map to real roles).
- The step-by-step events (minute 0: letter
  arrives; minute 10: programme-lead files decision
  memo; minute 25: head of AI governance's
  delegate requests legal review; …).
- The decision points — where participants have to
  make a call.
- The success criteria — what the tabletop proves
  if it goes well.
- The failure modes — what the tabletop finds if
  the interface has defects.
- The after-action artefact — the decision records
  that would land, the control-library changes
  that would file.

### Deliverable G — three worked decision records

Three decision records in the chapter 03 template:

- One **portfolio-level** decision (e.g. accept-
  risk on a coverage gap for one quarter).
- One **engagement-level** decision (e.g. scope-
  expand an engagement by 30 %).
- One **control-library** decision (e.g. MAJOR
  change to a release-gate control).

Each with the full fields (decision_id, session,
date, decision, rationale, decided_by, expires,
review_at, tracks). The three together show the
range of decision shapes the interface produces.

---

## Starter guidance

- **Build the stakeholder map first, before the
  cadences.** The cadence design is downstream of the
  decision rights.
- **The quarterly's pre-read is the real artefact.**
  A quarterly without a signed pre-read is a status
  readout. Make the sample pre-read a credible
  artefact.
- **Decision records are the quarterly's output.**
  The quarterly produces decisions, not notes. If
  the output of your sample quarterly is three bullet
  points of "noted", the design is incomplete.
- **The monthly check-in is where most defects would
  surface.** Design it with care; it is the lightest
  touch with the highest leverage.
- **The RACI is calibrated.** A chart where
  programme-lead is A on everything is a chart that
  the audit will question; a chart where sponsor is
  A on nothing is a chart that disempowers the
  sponsor.
- **The tabletop plan has a definite failure
  surface.** Design the scenario so the exercise
  can actually fail; if the escalation path handles
  everything smoothly, the scenario was too easy.
- **Decision records use absolute dates.** "Next
  quarter" is a drifting phrase; "2025-10-14" is
  not.

---

## Acceptance criteria

A passing plan:

- Stakeholder map that names roles and specific
  decision rights with a signed interface-contract
  memo.
- Quarterly working-session design with full
  operating specification and a credible sample
  pre-read.
- Per-engagement cadence design with the three
  sub-cadences each specified end-to-end.
- Escalation-path matrix and runbook.
- RACI chart calibrated to the organisation,
  consistent with the escalation matrix.
- Tabletop plan on one scenario with success /
  failure criteria and an after-action artefact.
- Three worked decision records across portfolio,
  engagement, and control-library categories.

A failing plan:

- Stakeholder map that lists titles without
  decision rights.
- Quarterly design without a decision-record
  template.
- Monthly check-in missing.
- Escalation matrix without a runbook.
- RACI with programme-lead A on every row.
- Tabletop plan without failure modes.
- Decision records missing the expires /
  review_at / tracks fields.

---

## Stretch goals

- **Multi-business-unit extension.** Extend the
  design for a federated organisation with multiple
  business units having their own partial-ML-security
  programmes. The programme-lead now runs the
  interface at the enterprise level.
- **Executive-briefing integration.** Add an
  executive-briefing cadence (quarterly readout to
  the CEO or risk committee), show how it is fed
  from the quarterly, and keep the raw-numbers
  discipline from chapter 04 intact.
- **Interface-SLA definition.** Define the SLAs for
  each interface interaction (monthly check-in
  turnaround on decision requests, quarterly pre-
  read reading time, escalation acknowledgement
  time) and build a dashboard that reports SLA
  attainment.
- **Interface-change management.** Design the
  process for a change to the interface itself
  (e.g. the SOC director's delegate joins the
  monthly) — the interface's own version-history.
- **Shadow-RACI reconciliation.** If your
  organisation has multiple existing RACIs that
  touch AI-security, produce a reconciliation of
  the authoritative RACI against the shadow
  versions.

---

## Do not

- Do not design a quarterly whose output is only
  slides. Decisions in writing, in a signed record,
  or the quarterly did not happen.
- Do not conflate "informed" with "consulted". A
  stakeholder who got a copy of the meeting notes
  is informed; a stakeholder whose opinion was
  solicited pre-meeting is consulted.
- Do not design escalation whose top is "the CEO".
  The CEO is a limited resource; identify the risk-
  committee or chief-risk-officer tier below CEO
  for most escalations.
- Do not use relative dates ("Q+1") in decision
  records.
- Do not commit the solution bundle to this repo.
  Solutions live in the paired `-solutions` repo.
