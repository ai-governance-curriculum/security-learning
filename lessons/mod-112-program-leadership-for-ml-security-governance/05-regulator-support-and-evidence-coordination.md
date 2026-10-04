# Chapter 05 — Supporting Regulator Engagement: Evidence, Not Opinion

> **Note on AI-assisted content.** Nothing in this
> chapter is legal advice. Regulator interaction
> procedures, response windows, and required evidence
> shapes vary by jurisdiction, by regulator, and by the
> organisation's registered position (data controller /
> processor, high-risk-system provider / deployer,
> covered entity / business associate). Verify every
> procedural claim against the regulator's current
> published guidance and against counsel's direction
> for the specific interaction. The templates below are
> structural examples only; counsel owns the artefacts
> that cross a regulator's inbox.

---

## Why this chapter exists

Regulator engagement — a formal inquiry, a routine
audit, a mandatory incident notification, a response
to a draft enforcement action — is the one event in
the ML-security programme-lead's calendar where the
cost of a confused interface is highest. Legal counsel
has the right to speak for the organisation. The
programme-lead has the facts about the technical
controls. The failure mode is either role overstepping
or either role failing to supply the other with what
they need.

The failure mode this chapter is written against:

> A sector regulator opens a focused inquiry into the
> organisation's use of an AI/ML system following a
> customer complaint. The GC's office asks the
> ML-security programme for "the evidence". Two weeks
> are spent collecting disjoint PDFs from Slack
> threads and auditor emails. The eventual response
> package is thin, inconsistent, and includes a
> paragraph the programme-lead wrote describing why
> the organisation believes it meets the regulator's
> expectation. Counsel strikes the paragraph — because
> the programme-lead's "we believe we comply" is legal
> opinion that counsel did not render — and the
> package goes out two days late. The regulator asks
> three follow-ups the response did not address. A
> second response cycle begins.

A regulator-support operation that is calmly executed
has three properties: (1) a defined division of labour
between counsel and the programme-lead, with the
bright line held; (2) a pre-built evidence pack that
can be instantiated for a specific regulator
interaction in days, not weeks; (3) a running
coordination with counsel so each party knows the
other's constraints before the interaction, not during
it.

You leave this chapter able to:

- Describe the ML-security programme-lead's role in
  regulator interaction and the bright line against
  legal opinion.
- Identify the regulator-interaction categories, the
  response-time pressures each creates, and the
  evidence shapes each needs.
- Build and maintain the evidence pack that supports
  regulator engagement across the categories the
  organisation is likely to see.
- Run the coordination with counsel through the
  interaction cycle: initial letter, response-pack
  assembly, follow-ups, close-out.
- Avoid the standard failure modes: offering legal
  opinion, delivering evidence counsel has not seen,
  packaging evidence in a form the regulator cannot
  consume, and failing to version what was supplied
  so later asks are consistent.

---

## The bright line: evidence vs. opinion

The split is simple and non-negotiable:

- **Counsel renders opinion.** "The organisation
  complies with Article 15 of Regulation (EU) 2024/
  1689 because…"; "This incident does / does not
  meet the HIPAA breach-notification threshold
  because…"; "Our contractual obligations under this
  BAA require us to…". Any sentence of this shape is
  counsel's output.
- **Programme-lead supplies evidence.** "Here is the
  control-library section covering ATLAS techniques
  that correspond to adversarial inputs under Article
  15"; "Here is the model-card lineage for the
  system named in the inquiry"; "Here is the
  detection coverage map and its signed version at
  the date of the alleged incident".

The crisp test: if the sentence contains "complies",
"meets the threshold", "obligated", "satisfies", or
any term of legal construction, counsel owns it. If
it describes a technical artefact and points to
evidence, the programme-lead owns it. Edge cases
default to counsel.

In practice this means that in a regulator-response
package:

- The programme-lead's section is a factual
  description of controls and artefacts.
- Counsel's section is the mapping of those facts to
  the regulatory requirement and the organisation's
  legal position.
- The two are composed by counsel into the response;
  the programme-lead's section is editable by
  counsel; counsel's section is not editable by the
  programme-lead.

Why this matters: a programme-lead's errant "we
comply with…" line in a submission is both a legal
representation the organisation might not have
intended, and a limiter on counsel's room to argue
later. Protect the bright line even when the
regulator's framing invites you to cross it.

---

## Categories of regulator interaction

Different interactions have different time pressure
and different shape. Four common categories:

### 1. Statutory incident / breach notification

Specific regulations impose notification windows on
specific incidents:

- **HIPAA breach notification** — 60 days for a
  reportable breach of unsecured PHI (45 CFR 164.400
  et seq.); 500-or-more-affected rules are stricter.
  Covered entities have the primary obligation;
  business associates are also addressed.
- **GDPR Article 33** — 72 hours to notify the
  supervisory authority of a notifiable personal data
  breach; Article 34 for data subjects.
- **EU AI Act Article 73** — reporting of serious
  incidents involving high-risk AI systems (verify
  the article number and current timeline against
  the current OJEU text and implementing acts).
- **US SEC** — "material cybersecurity incident"
  reporting on Form 8-K within 4 business days
  (publicly-listed companies; verify current rule
  text).
- **State-law breach notification** — many US states
  have varying timelines and triggers; the GC's
  office maintains the matrix.
- **Sector-specific** — bank-regulator operational-
  incident reporting (OCC, Federal Reserve, FDIC
  joint rule); medical-device MDR; telecom; critical-
  infrastructure (NIS2 in the EU, CIRCIA in the US).

Response-time pressure: hours to days. The programme-
lead's job here is to run the facts side of mod-111's
incident-response playbook such that counsel has
unambiguous facts within the clock.

### 2. Routine audit / examination

A scheduled audit by a sector regulator (OCC exam, FDA
inspection, EU AI Act supervisory authority audit,
FCA / PRA review, state insurance regulator exam,
etc.) or by an external assessor (SOC 2, ISO 42001,
HITRUST). These have:

- A pre-notified scope and date range.
- A document request list ("DRL") sent before the
  on-site / live phase.
- Interviews with named functions.
- Follow-up requests during the engagement.
- A written finding or report at exit, with a
  management-response window.

Response-time pressure: days to weeks for individual
asks; the overall engagement is weeks to months.

### 3. Focused inquiry

A regulator opens a focused inquiry — a complaint,
a market event, a general industry sweep — and
sends an information request to the organisation.
These are often less structured than a formal
examination; the organisation has to decide (with
counsel) how to respond, what scope to accept, and
what to decline.

Response-time pressure: typically 15-60 days per
request, but regulators sometimes impose shorter
deadlines.

### 4. Enforcement action / consent order

The regulator has already decided (or is close to
deciding) that there is a problem; the interaction
is now about the remediation plan, the attestations,
the independent-monitor arrangement, and the terms
of the order. These are led by counsel; the
programme-lead supplies the plan, the attestations,
and the ongoing evidence to the monitor.

Response-time pressure: variable, often with multi-
year attestation obligations.

---

## The regulator-support evidence pack

The pack is not written in a response-cycle sprint;
it is maintained in steady-state so that a specific
response can be built from it quickly. The programme-
lead maintains a *library of evidence packs* —
pre-structured artefacts, signed, dated, versioned —
that cover the categories of regulator interaction
the organisation is likely to see.

### Standing artefacts

The following live in the evidence store and are
pulled per request:

- **System register.** The list of AI/ML systems in
  scope, with their classifications (EU AI Act
  risk level, sector-specific classifications, PHI /
  PII handling, model-risk tier). Updated per the
  mod-109 chapter 03 Article 6 classifier
  determination process.
- **Control-library section** (chapter 01) — current
  in-force controls with evidence attachments. The
  point-in-time query is essential; a regulator asks
  about state on a past date.
- **Threat models** (mod-102) — per in-scope system,
  with the current version and the versions in force
  during any period the regulator asks about.
- **Model cards and lineage** (mod-104) — per
  in-scope model, including training-data lineage,
  evaluations, and the attestation chain.
- **DPIAs / FRIAs / impact assessments** (mod-108 /
  mod-109) — per system that required one.
- **Supplier register and assessments** (mod-110) —
  per vendor model used, per material external
  dependency.
- **Incident-response playbooks and recent run
  records** (mod-111) — the playbook for the
  category of event in question, and the record of
  any recent exercise.
- **Metrics package** (chapter 04) — the most recent
  signed package, plus the historical series.
- **Audit history** — reports of recent audits,
  management responses, follow-up status.
- **Attestations from senior roles** — CISO, GC, head
  of AI governance, head of model risk have each
  signed, at defined cadences, that the artefacts in
  their domain are complete and accurate as of a
  date.

Each artefact in the standing library has:

- A stable identifier.
- A signed-at date.
- A version history.
- A classification (public / internal / restricted /
  attorney-client privileged).
- A pointer to its source of truth.

### Per-category response templates

For each category above, a response template exists
that counsel approved pre-crisis. The template is a
*structure*, not a canned response; counsel instantiates
it with the specific facts of the interaction.

Example skeleton for a focused-inquiry response:

```markdown
# Response to [Regulator Name] Request [Reference]
# Dated [Date]; counsel: [Attorney]
# ML-security contact: [Programme-Lead]

## 1. Scope of this response
# counsel owns this section

## 2. System(s) in scope
# programme-lead supplies the system-register extract
# with classification, model lineage pointers,
# effective dates

## 3. Controls in force on [Date]
# programme-lead supplies the point-in-time control-
# library section with evidence pointers; counsel
# authors the lead paragraph interpreting it

## 4. Specific question responses
# ordered to match the regulator's request;
# counsel owns each response's lead paragraph;
# programme-lead supplies each referenced artefact

## 5. Attestations
# signed by appropriate roles at counsel's direction

## Attachment index
# every artefact referenced above, in the regulator's
# preferred format (PDF with signed envelope, or
# whatever the regulator will accept)
```

### Versioning what was supplied

Every outbound package is versioned, with a hash of
each attached artefact. Later requests ("provide
the artefact you supplied on 2025-07-14, plus any
subsequent changes") are then trivially answered.
This is also the artefact the organisation would
need if a dispute arose about what had been
represented when.

---

## Running the interaction cycle

Each regulator interaction has a lifecycle. The
programme-lead's role in each phase:

### Phase 1 — pre-interaction (steady state)

- Maintain the standing evidence pack.
- Keep the per-category templates current with
  counsel's input.
- Run tabletops for notification scenarios twice a
  year with counsel participating. The HIPAA breach-
  notification tabletop in particular tends to find
  real gaps.
- Ensure the roles with signing authority on the
  attestations above have an in-force signing key
  (mod-105).
- Confirm counsel's contact list for each regulator
  the organisation is likely to interact with.

### Phase 2 — initial contact / inquiry received

- Within one business hour: notify counsel; counsel
  determines whether the interaction is in-scope for
  external-counsel engagement and whether a
  litigation hold applies.
- Within one business day: a response plan with
  counsel: who leads, what artefacts are expected,
  what the clock is.
- Classify the request type (incident notification /
  audit / inquiry / enforcement) and pull the
  template.
- The programme-lead's internal communications about
  the interaction follow counsel's instructions for
  privilege and litigation-hold handling. Not every
  internal Slack channel is a safe place to discuss
  the matter.

### Phase 3 — evidence assembly

- Build the response package to the template.
- Programme-lead's sections are drafted and submitted
  to counsel; counsel edits and composes the final.
- Every artefact attached is a signed, versioned
  pull from the evidence store. No "quickly produced
  for this response" artefacts. If an artefact does
  not exist, that is a finding; the response
  acknowledges the gap under counsel's direction.
- Programme-lead signs the technical artefacts and
  attestations within their authority; roles with
  broader authority sign at counsel's direction.

### Phase 4 — submission

- Counsel submits.
- A copy of the submitted package, with every
  attachment, lands in the evidence store with a
  retention lock.
- The submission artefact is marked attorney-client-
  privileged or work-product as counsel directs; the
  programme-lead honours the classification in all
  downstream handling.

### Phase 5 — follow-ups

- Each follow-up request is handled under the same
  mechanic.
- Prior submissions are referenced by their versioned
  identifiers so the responses compose.
- Any factual change between submissions is called
  out explicitly ("the control described in response
  §3 of our 2025-07-14 submission was superseded on
  2025-09-02 by AISEC-OPS-004 v2.2.0; the superseded
  version remains queryable at [pointer]").

### Phase 6 — close-out

- The regulator issues a finding, a letter, an
  acceptance, or an enforcement action, as the
  category dictates.
- The programme-lead files the outcome into the
  control library (chapter 01) with any required
  changes, into the engagement portfolio (chapter
  02) as a scope input, and into the metrics
  package (chapter 04) as a finding.
- Counsel owns the external communication and the
  record of the matter's closure.

---

## Specific regulator-category working notes

Non-authoritative starting points. Verify against
current guidance for the regulator in question.

### HIPAA breach-notification support

- The programme-lead's job: produce the timeline,
  the technical facts, the access-log evidence, the
  encryption state at the time, and the risk-
  assessment inputs (nature and extent of PHI,
  unauthorised recipient, acquisition / viewing,
  mitigation).
- Counsel's job: the breach determination against
  the four-factor risk assessment (45 CFR 164.402),
  the notification obligations, and the content of
  the notification.
- Timeline reminder: 60 days from discovery for most
  cases; faster for 500+ affected individuals; media
  notification for larger breaches.

### EU AI Act Article 73 (serious incidents)

- The programme-lead's job: a factual report of the
  incident on a high-risk system, the system
  classification, the model lineage, the detection
  timeline, the mitigation steps taken.
- Counsel's job: whether the incident is "serious"
  within the Article 73 definition, which market
  surveillance authority is addressed, and the
  content and timing of the notification. Verify the
  current implementing-act timelines (they have
  moved during implementation).

### SOC 2 / ISO 42001 audit support

- The programme-lead's job: respond to the DRL from
  the external auditor with evidence artefacts; be
  available for walkthrough interviews; respond to
  management-response letters.
- Counsel's job: review of the final report, any
  qualification language, and the engagement letter
  terms.
- These are not strictly "regulators" but the
  running mechanics are the same.

### Federal Reserve / OCC / FDIC model-risk
examination (SR 11-7)

- The programme-lead's job: supply the model-risk
  evidence for ML-based models — model-development
  documentation, independent validation reports,
  ongoing monitoring, model-use governance — paired
  with the model-risk officer's artefacts.
- Counsel's job: engagement management with the
  examiner, any required responses to findings, and
  the matters-requiring-attention / consent-order
  dynamics.

### FDA inspection for AI/ML-enabled SaMD

- The programme-lead's job: evidence that the
  predetermined change control plan (PCCP) is being
  honoured, that the ML development documentation
  meets the GMLP principles, and that monitoring is
  operating.
- Counsel's job: regulatory affairs lead typically
  owns FDA interaction; the programme-lead supports
  through regulatory affairs rather than directly.

---

## Standard failure modes

- **Programme-lead speaks on behalf of the
  organisation.** A quote from the programme-lead in
  a direct email to a regulator is a legal
  representation. All regulator-facing
  communications route through counsel.
- **Evidence invented for the response.** An
  artefact first produced to answer a regulator
  question is unverifiable; the regulator will
  challenge it and the finding will be worse. If
  the artefact did not exist, say so with counsel's
  framing.
- **Standing library drift.** The system register
  not updated, the control-library point-in-time
  query broken, the model lineage records
  incomplete. The library has to be exercised
  before the response-cycle clock starts.
- **Unversioned supplies.** Later requests cannot be
  answered consistently with earlier ones because
  nobody kept a hash of the submitted file.
- **Classification mishandling.** A privileged
  artefact circulated in a public Slack channel; a
  litigation-hold-covered Jira issue closed-and-
  purged by the normal retention policy. Counsel's
  classification instructions bind the programme-
  lead's team.
- **Submitting without counsel's final sign-off.**
  Even a "small" follow-up submission goes through
  counsel.
- **No tabletop before the real event.** The
  HIPAA notification clock starts and nobody has
  ever run the mechanism; two business days are
  lost learning the pipeline.
- **Counsel first-learns the facts in the response-
  assembly meeting.** The monthly interface check-
  in (chapter 03) covers this: counsel has a
  running awareness of the posture before any
  incident, so the response is a continuation of a
  conversation rather than its start.

---

## Summary

- Regulator interaction has a bright line: counsel
  renders opinion; the programme-lead supplies
  evidence.
- The common categories — statutory notification,
  routine audit, focused inquiry, enforcement — each
  have their own response-time pressure and shape.
- A **standing evidence pack** (system register,
  control library at point-in-time, threat models,
  model cards and lineage, DPIAs/FRIAs, supplier
  assessments, IR playbooks, metrics package,
  attestations) is maintained in steady state so a
  response can be built in days rather than weeks.
- A **per-category response template** approved by
  counsel pre-crisis structures the eventual
  response.
- The interaction cycle — pre-interaction, initial
  contact, evidence assembly, submission, follow-up,
  close-out — has defined phases with defined
  programme-lead and counsel responsibilities at
  each phase.
- The standard failure modes are speaking as the
  organisation, evidence invented for the response,
  standing-library drift, unversioned supplies,
  classification mishandling, and running the
  response-cycle mechanism untested.
