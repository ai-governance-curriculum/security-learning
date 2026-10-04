# Exercise 05 — Regulator-Support Runbook

**Estimated effort:** ~4 hours
**Deliverable:** A committed regulator-support runbook
and standing-evidence-pack specification for the
ML-security programme-lead, consisting of
(a) a **bright-line policy** document that enumerates
what the programme-lead will supply (evidence,
technical facts) and what counsel will own (opinion,
regulatory determination, external communication), with
specific worked examples drawn from phrasings
regulators commonly use; (b) a **standing evidence-pack
specification** that lists every artefact the pack
maintains in steady state (system register, control-
library point-in-time query, threat models, model cards
and lineage, DPIAs/FRIAs, supplier assessments, IR
playbooks, metrics package, attestations), with
schemas, signers, retention policy, and classification
tags; (c) a **per-category response template set** for
four regulator-interaction categories (statutory
notification, routine audit, focused inquiry,
enforcement) each pre-approved by counsel in template
form; (d) an **interaction-cycle runbook** that walks
the programme-lead through phases 1-6 (pre-interaction
steady state, initial contact, evidence assembly,
submission, follow-ups, close-out) with concrete
timing, actions, artefact handoffs, and a litigation-
hold-handling appendix; (e) **two tabletop plans** —
one HIPAA breach-notification scenario and one EU AI
Act Article 73 scenario (or sector equivalents for your
organisation) — each with scenario, participants,
timeline, decision points, success criteria, and
after-action artefact; (f) a **jurisdictional applicability
matrix** that names the regulators the organisation is
likely to interact with and what categories apply to
each, pointing to the primary text for each.
**Prerequisites:** Chapter 05 read end-to-end.
Familiarity with at least one of HIPAA, EU AI Act,
GDPR, SR 11-7, SOC 2, FDA GMLP/PCCP, or sector-specific
regulation applicable to your organisation. Access to
your General Counsel's office (or a plausible model)
to review the bright-line policy and the templates.
Working knowledge of chapter 01 (evidence) and
chapter 03 (interface with counsel).

---

## Objective

Chapter 05's claim is that the regulator-support
operation runs calmly when it has three properties:
a bright line held between evidence and opinion, a
standing evidence pack ready to instantiate, and a
running coordination with counsel. This exercise is
where you build all three for your organisation.

By the end of this exercise you have:

- A **bright-line policy** that is specific enough
  that a programme-lead can read it the morning of
  a regulator inquiry and know what to say and not
  to say.
- A **standing evidence-pack specification** that an
  evidence-pipeline engineer can build to.
- A **per-category response template set** that
  counsel has approved in template form, so the
  response-cycle sprint is instantiation, not
  authorship.
- An **interaction-cycle runbook** that steps a
  programme-lead through a real interaction
  phase-by-phase.
- **Two tabletop plans** that would surface
  interface defects before a real event does.
- A **jurisdictional applicability matrix** so the
  programme does not discover an unmet obligation
  under a surprise regulator.

You are **not** running an actual regulator response
in this exercise; you are producing the artefacts
that would let you do so if one landed tomorrow.

---

## Problem statement

Define the scope at the start:

- The organisation (real or hypothetical) with its
  sector(s).
- The jurisdictions it operates in.
- The regulators it is likely to interact with
  (sector-specific + privacy + AI-specific where
  applicable).
- The categories of interaction that are credible:
  if HIPAA does not apply, drop that strand; if EU
  AI Act high-risk does not apply, drop that strand
  and substitute a strand that does.

The exercise is more useful grounded in a specific
organisation; the artefacts calibrate differently
for a healthcare SaaS, a European retail bank, a
US financial-services firm, a mid-size media
company deploying LLM features, etc.

---

## Requirements

### Deliverable A — bright-line policy

A document (≤2 pages) that:

- States the bright line in one paragraph.
- Enumerates **8-12 phrases regulators commonly
  use** and, for each, whether the programme-lead
  may respond with technical content and whether
  the response must route through counsel.
  Example phrasings:
  - "Please describe your controls that ensure…"
  - "Does the organisation comply with…"
  - "On what basis does the organisation
    determine…"
  - "Can you confirm that no [PHI / personal data /
    sensitive data] was accessed in…"
  - "What is your organisation's position on…"
  - "Would you consider this incident reportable?"
- Specifies the escalation action when the
  programme-lead is unsure which side of the line
  the response falls on (default to counsel; here
  is who to call).
- Specifies the handling of direct contact —
  regulator-to-programme-lead calls, emails,
  conference approaches.
- Is signed by the programme-lead and
  counter-signed by the GC's AI partner.

### Deliverable B — standing evidence-pack specification

A machine-readable specification of the standing
evidence pack. For each artefact category:

- The specific artefact(s) in the category.
- The producer (role or system).
- The schema (reference to a schema file or an
  inline schema).
- The signing identity.
- The storage location (classification zone +
  path).
- The retention term and the regulatory basis.
- The query interface (how retrieval at a date
  works).
- The maintenance cadence.
- The reviewer (who confirms the artefact is still
  current).

Artefact categories (chapter 05):

- System register
- Control-library point-in-time query artefacts
- Threat models (per in-scope system)
- Model cards and lineage records
- DPIAs / FRIAs / impact assessments
- Supplier register and per-supplier assessments
- Incident-response playbooks and exercise
  records
- Metrics package (latest + historical series)
- Audit history
- Attestations from senior roles

If any artefact's pipeline is not yet live, mark
it so and name the gap.

### Deliverable C — per-category response template set

Four templates, each in a form that counsel could
sign off on *as a template*:

- **Statutory incident / breach notification**
  (HIPAA breach notification, EU AI Act Article 73,
  SEC 8-K, or an applicable sector equivalent;
  pick one or more as fits your scope).
- **Routine audit / examination** (SOC 2, ISO
  42001, OCC exam, FDA inspection, as fits).
- **Focused inquiry** (ad hoc regulator information
  request).
- **Enforcement action / consent order** (post-
  decision remediation).

Each template:

- Specifies sections where counsel owns the
  content and sections where the programme-lead
  supplies.
- Provides pre-written language from counsel for
  counsel's sections (placeholder where the
  specific facts of the interaction instantiate).
- Specifies the artefact bundle attached (which
  from deliverable B).
- Specifies the signing roles.
- Specifies the submission format (PDF, structured
  portal upload, signed envelope).

### Deliverable D — interaction-cycle runbook

A runbook covering phases 1-6 from chapter 05, with:

- **Phase 1** (steady state): the maintenance
  calendar for the standing pack, the tabletop
  schedule, the counsel-contact-list verification
  cadence.
- **Phase 2** (initial contact): the one-business-
  hour notification path to counsel; the one-
  business-day response-plan artefact; the Slack /
  Teams channel policy (there is one, and it is
  the programme-lead's — not the general ML
  channel); the litigation-hold triage.
- **Phase 3** (evidence assembly): the artefact-
  check runbook (every attached artefact pulled
  from the store, signed, hashed); the programme-
  lead's draft routing to counsel.
- **Phase 4** (submission): counsel's sign-off
  mechanism; the archive-to-evidence-store
  mechanism; the classification-tagging mechanism.
- **Phase 5** (follow-ups): the composition
  mechanism against prior submissions; the
  factual-change-callout mechanism.
- **Phase 6** (close-out): the control-library
  update, the engagement-portfolio update, the
  metrics-package update.

Include a **litigation-hold-handling appendix**:
when it applies, what it means for Slack/Teams,
Jira/Linear, email, document-management-system
retention; who issues the hold; how the hold is
lifted.

### Deliverable E — two tabletop plans

Two scenarios, each with a 60-90-minute plan:

**Scenario A — HIPAA breach notification** (or
jurisdictional equivalent):

- Starting event (narrated).
- Participants (map to real roles).
- Minute-by-minute timeline from discovery
  through notification deadline.
- Decision points (is this reportable? which
  class? affected count? what artefact set?
  external counsel engagement?).
- Success criteria.
- Failure modes.
- After-action artefact.

**Scenario B — EU AI Act Article 73 serious
incident** (or sector equivalent — SR 11-7
model-performance incident, FDA MDR, GDPR Article
33 notification, etc.):

- Same structure as Scenario A.

Each scenario is **realistic**, not sanitised.
Discovery delays, incomplete evidence, counsel
unavailable at the start, retention-system
limitations — these are the lessons the tabletop
teaches.

### Deliverable F — jurisdictional applicability matrix

A matrix of regulators × interaction categories ×
organisational scope. Columns:

- Regulator (and primary-text citation URL).
- Jurisdiction.
- Interaction categories that apply.
- Trigger / notification obligation.
- Response-time window.
- Primary artefacts (reference into deliverable B).
- Counsel's named lead for this regulator.
- Last verified-current date.

The matrix is maintained; it is reviewed on a
documented cadence (quarterly is a reasonable
default).

---

## Starter guidance

- **Build the bright-line policy before the
  templates.** The templates reflect the policy.
- **Counsel reviews before this exercise is "done".**
  The templates and the bright-line policy are
  jointly-signed artefacts; if you cannot get
  counsel's sign-off in the exercise window, mark
  the sign-off as pending and record what counsel's
  review would check.
- **Primary texts, not blog summaries.** Every
  regulatory reference in the applicability matrix
  is cited to the official text.
- **The standing pack is maintenance, not creation.**
  The programme already has threat models (mod-102),
  model cards (mod-104), incident playbooks (mod-
  111), etc. — the pack specification references
  those; it does not re-author them.
- **Tabletops have realistic failure.** A tabletop
  that goes smoothly taught nothing; design the
  scenarios so plausible gaps are exposed.
- **Litigation hold is a specific appendix.** It is
  often where programmes get tripped; chapter-05 is
  explicit about it and so is this exercise.
- **Jurisdictional matrix needs quarterly review.**
  The applicable regulators change over time; the
  review cadence is part of the design.

---

## Acceptance criteria

A passing runbook:

- A bright-line policy with worked phrasings and
  escalation guidance; signed by programme-lead
  and (planned or actual) counsel.
- A standing evidence-pack specification covering
  all chapter-05 artefact categories with producer,
  schema, signer, storage, retention, query,
  cadence, reviewer.
- Four per-category response templates with
  counsel-vs.-programme-lead section ownership and
  pre-written language in counsel's sections.
- A phase-1-through-6 interaction-cycle runbook
  with a litigation-hold appendix.
- Two tabletop plans with realistic failure modes
  and after-action artefacts.
- A jurisdictional applicability matrix with
  primary-text citations.

A failing runbook:

- A bright-line policy that reads "collaborate
  with legal" without worked phrasings.
- An evidence pack specification whose artefacts
  do not point to real producers.
- Templates authored by the programme-lead alone
  without counsel review (or without even a
  "counsel review pending" marker).
- A runbook that treats litigation hold as "legal
  will handle it".
- Tabletops without failure modes.
- A matrix without primary-text citations.

---

## Stretch goals

- **Automation.** Build a small CLI that renders
  a per-category response skeleton from the
  templates + standing pack, given a selection of
  artefacts and a regulator.
- **Counsel's engagement letter.** Draft (with
  counsel) the engagement letter that defines the
  programme-lead's relationship with external
  counsel when the organisation retains outside
  counsel for a regulator interaction.
- **Independent-monitor scaffolding.** For the
  enforcement-action template, build the
  attestation and evidence pipeline for an
  independent monitor arrangement — the monthly
  evidence feed, the quarterly attestation
  signature, the scope of what the monitor sees.
- **Cross-jurisdiction scenario.** Add a tabletop
  where a single incident triggers obligations in
  multiple jurisdictions with different timelines
  (US HIPAA + EU GDPR + state law), and the
  programme-lead has to sequence the responses.
- **Retention-policy compatibility check.** Audit
  the organisation's existing retention policies
  (email, Slack/Teams, Jira, DMS) against the
  litigation-hold appendix; produce the gap list.
- **Regulator-perspective review.** Have someone
  with regulator-experience read the templates
  and the runbook as if they were the regulator;
  record and act on the review's defects.

---

## Do not

- Do not author legal opinion in any artefact.
- Do not fabricate statutory timelines; verify
  every "X days" claim against the regulator's
  primary text and cite it.
- Do not supply artefacts without a signature trail.
- Do not design templates that bypass counsel.
- Do not write the bright-line policy as "we work
  with legal". The policy is specific.
- Do not commit the solution bundle to this repo.
  Solutions live in the paired `-solutions` repo.
