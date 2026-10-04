# Chapter 05 — The SOC / DFIR / Legal Interface and the AI-Security RACI

> **Note on AI-assisted content.** The RACI patterns and
> role vocabularies below reflect widely-published practice
> (NIST SP 800-61r3, SANS incident-handling, FIRST
> community guides) interpreted for an AI/ML-security
> programme. Enterprise role names ("SOC", "CSIRT", "DFIR",
> "GRC", "Office of the CISO") vary; the responsibilities
> described below often attach to differently-named groups
> depending on your org. Verify against your enterprise's
> actual charter documents. See [`resources.md`](./resources.md).

---

## Why this chapter exists

Chapters 01–04 produced detections, playbooks, and a
severity ladder. The missing question — the one that
sinks programmes that have everything else right — is
*who owns what*. Specifically:

- Who owns the **alert**: the first-line triage, the
  decision to open an incident, the acknowledgement SLA?
- Who owns the **response**: the technical actions,
  the containment, the eradication, the recovery?
- Who owns the **notification**: the determination that
  a regulator, a customer, a partner, or the public must
  be told, and the drafting of the message?

A programme without clean answers is one at 02:37 where
two teams each believe the other owns the response, or
where legal is paged *after* the regulatory clock has
run out, or where DFIR takes an image of a running
container only to discover the ML platform team already
deleted it as part of their "fix".

The AI/ML Security & Governance role described in this
track is a new function; it does not replace the SOC,
DFIR, legal, GRC, or the office of the CISO. It
interfaces with each of them. The failure mode this
chapter is written against:

> An org stands up an "AI Security Engineer". The role
> owns everything AI-related: detections, playbooks,
> severity, incident command, legal notification. Three
> months in, the person running the role is the only
> one who can be paged, has written the only runbooks
> that use the enterprise's incident-management tool,
> has not been read into the enterprise's regulatory
> notification process, and is on holiday the week a
> SEV-1 fires. The incident is managed by the SOC
> on-call who has not seen the AI playbooks, by a legal
> team that was not paged until Thursday, and by an
> executive who learns of the GDPR 72-hour obligation at
> hour 73.

The fix is a documented RACI: Responsible, Accountable,
Consulted, Informed, for each phase of an AI/ML
incident, with the AI/ML Security role as *one* participant
among several, not the whole response.

You leave this chapter able to:

- Identify the enterprise groups that an AI/ML security
  programme must interface with (SOC, DFIR, legal, GRC,
  comms, exec sponsor, finance, HR) and what they own.
- Author a per-playbook RACI matrix that is specific
  enough to be useful (not "legal is involved").
- Design the escalation and hand-off points: when the
  ML on-call hands off to the SOC incident commander,
  when the SOC hands off to legal, when legal brings in
  external counsel or a regulator relationship.
- Negotiate SLAs with each interfacing group — what the
  AI programme commits to delivering (telemetry,
  evidence, trajectory bundles) and what the group
  commits to in response (page time, decisions, reports).
- Keep the interface *rehearsed*; stale RACIs are worse
  than no RACIs because they create false confidence.

---

## RACI in one page

**R — Responsible.** Does the work. There is usually
*one* R per task, sometimes a small group.

**A — Accountable.** Owns the outcome. There is
*exactly one* A per task. The A delegates to the R; the
A takes the blame or the credit; the A signs the
after-action report.

**C — Consulted.** Must be asked before a decision is
made. Two-way communication.

**I — Informed.** Must be told after the fact. One-way
communication.

RACI matrices fail in three predictable ways:

- **Everyone is A.** Nobody owns the outcome.
- **Nobody is A.** Nobody owns the outcome.
- **A and R are confused with C and I.** The team
  being "informed" is in fact the team expected to
  take action.

The matrices below pick one A per row and are
deliberately short on C/I rows to avoid noise.

---

## The groups and what they own (enterprise-side)

Every enterprise's naming is slightly different. The
responsibilities below are the normal mapping.

### Security Operations Centre (SOC)

Owns the enterprise's detection content, alert triage,
first-line incident response, and the primary paging
rota. For an AI/ML incident, the SOC's
responsibilities are:

- Primary on-call. First to pick up the SIEM / Falco
  alert.
- First-line triage: confirm the alert is real,
  classify to the severity ladder (chapter 04),
  decide whether to open an incident.
- Incident commander for SEV-3 and below (or by
  policy, for SEV-2 as well, until an executive
  commander takes over for SEV-1).
- The authoritative ticket system of record.

What the SOC does **not** own in an AI/ML context:

- The playbook content for AI-specific playbooks
  (chapter 03). The AI/ML role owns authoring; the
  SOC owns execution.
- The deep ML forensics (trajectory analysis, model-
  behaviour attribution). DFIR with ML/ML-security
  support owns that.
- The determination of regulatory notification. Legal
  owns that.

### Digital Forensics and Incident Response (DFIR / CSIRT)

Owns deeper forensic investigation when first-line
response is insufficient. For AI/ML incidents, DFIR
responsibilities are:

- Preservation of evidence to a forensically-sound
  standard: chain of custody, cryptographic hashes of
  evidence bundles, immutable storage, legal-hold tags.
- Root-cause analysis beyond "what did the model do":
  how did the attacker gain access, what identity was
  compromised, what lateral movement occurred.
- Co-ordination with external counsel / law
  enforcement when needed.
- The after-action report (sometimes jointly with the
  AI/ML role).

In organisations where DFIR is embedded within the
SOC, the lines are soft. In organisations where DFIR
is a separate function (common in financial services,
regulated industries, and larger enterprises), the
handoff is formal.

### Legal (incident liaison, privacy / data protection, outside counsel)

Owns the determination of external notification
obligations, the drafting of regulator submissions
and customer communications, and attorney-client
privilege around the investigation.

AI-specific legal responsibilities:

- Determining whether GDPR Articles 33 / 34 apply.
- Determining HIPAA breach-notification applicability
  (if the org handles PHI).
- Determining PCI DSS incident notification (if
  cardholder data flows).
- Determining EU AI Act Article 73 serious-incident
  reporting (for providers of in-scope high-risk AI
  systems placed on the EU market).
- Determining US SEC Form 8-K Item 1.05 material-
  cybersecurity-incident reporting (for US public
  companies).
- Determining state breach-notification obligations
  (NCSL index).
- Determining sector-specific reporting (financial
  services regulators, healthcare, telecoms, critical
  infrastructure).
- Determining customer-contract notification
  obligations.
- Preserving privilege around the investigation
  (which affects how the AI/ML role writes memos and
  conducts interviews).

Legal often has an on-call liaison for incidents; that
is the role the AI playbook pages, not legal's main
switchboard.

### Governance, Risk, and Compliance (GRC)

Owns the long-term governance evidence surface
(mod-109), the risk register, and the policy pack.
Not involved in the hot phase of an incident; closely
involved in the Lessons-Learned phase. GRC
responsibilities for AI incidents:

- Receiving every SEV-1 / SEV-2 after-action record
  for the governance evidence surface.
- Updating the risk register with the risk the
  incident surfaced.
- Updating the policy pack (if the incident
  implicates a policy gap).
- Reporting incident metrics to the audit function.

### Communications

Owns external messaging — status page, customer
emails, press, analyst briefings. Pre-approved
language for common scenarios is maintained by
comms before the incident; incident-time comms drafts
specific language. For AI incidents:

- Pre-approved language exists for "model misbehaviour",
  "data-integrity event", "service degradation
  attributable to AI subsystem".
- Media / analyst engagement is comms-led, legal-
  reviewed.

### Executive sponsor

Named individual (often CISO, CTO, or CPO depending on
the incident shape) who approves SEV-1 decisions,
including:

- The decision to publicly disclose beyond legal
  minimums.
- The decision to disable a user-visible product
  feature.
- The decision to roll back a model to a prior
  version with its own trade-offs.
- Resource allocation for the response (bringing in
  additional engineers, external IR firms, forensic
  tooling vendors).

### Finance

Involved when cost impact is the material axis
(mod-107 chapter 05 LLM10). Finance:

- Approves emergency budget to run under cost caps
  that need temporary lifting (and to pay for
  external IR support if needed).
- Co-owns the cost-impact section of the after-
  action report.
- Tracks cost-of-incident metrics over time.

### HR

Involved when an incident implicates an employee or
contractor: insider threat, model theft by departing
engineer, misuse by a known identity. HR owns:

- Access suspension co-ordinated with the IR team.
- Any disciplinary process.
- Co-ordination with legal around employment-law
  constraints.

### ML Platform / Data Platform / Agent-product teams

The teams that *own* the systems whose incidents are
being managed. They are not security teams; they are
engineering teams whose cooperation is essential:

- Deploy fixes.
- Operate the kill switches (chapter 03).
- Provide domain context the SOC / DFIR cannot.
- Rebuild from a known-good state during recovery.

### AI/ML Security & Governance Engineer (this role)

The role this track exists to produce. In the context
of this chapter, the role **does not** own primary
incident response. The role owns:

- Authoring the detection content and the playbooks
  (chapters 01–03).
- Authoring and maintaining the severity ladder
  (chapter 04).
- Being the subject-matter expert the SOC and DFIR
  call on during an incident.
- Owning the governance evidence surface for AI
  risks (mod-109).
- Rehearsing the playbooks with the SOC and DFIR;
  updating them.
- The post-mortem for AI-specific root causes;
  co-authoring with DFIR.

---

## A per-playbook RACI — the primary interface document

The RACI below is a shape, not a prescription. The org
fills in team names and roles. The point is that *every
row has exactly one A* and the *R / C / I rows name
teams, not individuals*.

### Phase: Preparation (ongoing)

| Task | R | A | C | I |
| --- | --- | --- | --- | --- |
| Author AI-specific detection content | AI/ML Security | AI/ML Security Lead | SOC Detection Eng | GRC |
| Approve detection content for prod | SOC Detection Eng | SOC Manager | AI/ML Security | GRC, ML Platform |
| Author AI-specific playbooks | AI/ML Security | AI/ML Security Lead | SOC Lead, DFIR Lead, Legal Liaison | GRC |
| Approve playbooks for use | SOC Manager | CISO (or delegate) | AI/ML Security Lead, DFIR Lead, Legal Liaison | GRC, ML Platform Leads |
| Maintain severity ladder | AI/ML Security | SOC Manager | Legal Liaison, GRC | ML Platform Leads |
| Rehearse playbooks (tabletop / live-fire) | AI/ML Security | SOC Manager | DFIR Lead, ML Platform Leads | Executive Sponsor |

### Phase: Identification

| Task | R | A | C | I |
| --- | --- | --- | --- | --- |
| First-line triage of AI-tagged alert | SOC L1 On-Call | SOC Shift Lead | AI/ML Security (SME on call) | ML Platform On-Call |
| Confirm severity against the ladder | SOC L1 On-Call | SOC Shift Lead | AI/ML Security (if ambiguous) | — |
| Open incident ticket (SEV-1 / SEV-2) | SOC L1 On-Call | SOC Shift Lead | — | Legal Liaison, ML Platform On-Call, Exec Sponsor |

### Phase: Containment

| Task | R | A | C | I |
| --- | --- | --- | --- | --- |
| Execute kill-switch (tool disable, identity revoke, index freeze) | ML Platform On-Call | SOC Incident Commander | AI/ML Security | SOC L1 On-Call, DFIR |
| Preserve evidence (trajectory, model digest, retrieval snapshot) | ML Platform On-Call + AI/ML Security | DFIR | SOC Incident Commander | GRC |
| Decide to broaden containment (freeze promotions, roll back model) | SOC Incident Commander (SEV-2+) / Exec Sponsor (SEV-1) | Exec Sponsor (SEV-1) / SOC Manager (SEV-2) | ML Platform Lead, Legal Liaison, AI/ML Security | GRC, Comms |

### Phase: Eradication and Recovery

| Task | R | A | C | I |
| --- | --- | --- | --- | --- |
| Deploy patch (runtime, policy, model) | ML Platform Team | ML Platform Lead | AI/ML Security, SOC Incident Commander | GRC |
| Verify fix against regression test (chapter 03) | AI/ML Security | SOC Incident Commander | ML Platform Team | GRC |
| Rebuild / rollback affected model | ML Platform Team | ML Platform Lead | AI/ML Security | Exec Sponsor (SEV-1) |
| Restore normal operations | ML Platform Team | ML Platform Lead | SOC Incident Commander | GRC, Comms, Exec Sponsor |

### Phase: Notification (the Legal-owned column)

| Task | R | A | C | I |
| --- | --- | --- | --- | --- |
| Determine regulatory applicability | Legal Liaison + Privacy Counsel | General Counsel | AI/ML Security (facts), SOC Incident Commander (facts), DFIR (facts) | CISO, Exec Sponsor |
| Draft regulator submission | Privacy Counsel + external counsel if required | General Counsel | Comms, AI/ML Security | CISO, Exec Sponsor |
| Draft customer / public communication | Comms | CMO or CCO | Legal, AI/ML Security, Product Lead | CISO, Exec Sponsor |
| Deliver regulator submission | Privacy Counsel | General Counsel | — | Everyone else via after-action |
| Deliver customer / public communication | Comms | CMO or CCO | Legal | Everyone else |

### Phase: Lessons Learned

| Task | R | A | C | I |
| --- | --- | --- | --- | --- |
| Author post-mortem | AI/ML Security + DFIR | SOC Incident Commander | ML Platform Team, Legal Liaison | GRC, Exec Sponsor |
| Update playbook / detection / Falco / policy pack | AI/ML Security | AI/ML Security Lead | SOC Detection Eng | GRC |
| Update governance evidence surface | AI/ML Security | GRC Lead | — | Exec Sponsor, CISO |
| Approve closure | SOC Incident Commander | SOC Manager (SEV-2) / CISO (SEV-1) | AI/ML Security, GRC | Exec Sponsor |

**The pattern.** Primary ownership (A) moves from SOC
during identification, to a specific operations team
during containment / eradication / recovery, to legal
during notification, back to SOC for closure. The
AI/ML Security role is *consulted* almost everywhere
and *responsible* for a specific set of authoring and
after-action tasks — but is only *accountable* for
the detection content, playbook authoring, and the
AI-specific post-mortem portions.

---

## Negotiating the SLAs

A RACI without SLAs is a diagram. The interfaces need
numbers:

### Between AI/ML Security and SOC

- SIEM content pack reviewed quarterly by SOC
  Detection Engineering.
- New AI/ML detection rules go through SOC Detection
  Engineering's standard CI gate.
- SOC commits to an acknowledgement SLA on AI-tagged
  alerts no slower than its baseline (SEV-1: 15 min;
  SEV-2: 30 min; SEV-3: 1 h).
- AI/ML Security commits to an SME-on-call rota
  reachable within 30 minutes for SEV-1 / SEV-2.
- AI/ML Security commits to playbook updates within
  one week of any post-mortem.

### Between AI/ML Security and DFIR

- DFIR has read access to the trajectory bundle
  format and the evidence-manifest schema.
- The chain-of-custody expectations are documented
  before the first incident, not during.
- AI/ML Security provides a one-pager per playbook
  explaining the AI-specific evidence surface.

### Between AI/ML Security and Legal

- Legal liaison is paged on every SEV-1 and SEV-2
  with regulated-data signal within the SOC's SEV-1 /
  SEV-2 window.
- The jurisdictions-in-scope list is maintained by
  legal and consumed by the disclosure-clock
  service (chapter 04).
- Legal has pre-approved language for the common AI-
  incident shapes.
- AI/ML Security does not opine on legal
  determinations.

### Between AI/ML Security and ML Platform

- The ML platform operates the kill switches and the
  rollback paths. The playbook names the specific
  command / tool and the identity authorised to run it.
- The platform commits to a pre-authorised set of
  containment actions executable within SLA (tool
  disable within 1 minute, identity revoke within 2
  minutes, index freeze within 5 minutes).
- The platform's engineering review loop processes
  the regression tests from mod-107 chapter 04.

### Between AI/ML Security and GRC

- Every SEV-1 and SEV-2 after-action lands in the
  governance evidence surface (mod-109 chapter 04).
- Chronic SEV-3 patterns feed the risk register.
- The AI content pack coverage map (chapter 01) is
  published quarterly.

---

## Hand-off points

Two moments in an incident are especially error-prone;
the hand-offs below must be explicit.

### SOC-to-DFIR hand-off

When: SEV-1 confirmed or SEV-2 with signal that
suggests classical compromise (credential theft,
lateral movement) alongside the AI surface.

What transfers: incident commander baton; evidence
custody; the playbook stays in force but the follow-
through moves to DFIR. The SOC remains in the room
(C) throughout.

### Response-to-notification hand-off

When: facts sufficient to brief legal are available
(usually at the end of containment).

What transfers: the responsibility for the
notification determination is explicitly legal's; the
AI/ML Security and SOC roles are consulted for facts,
not asked for opinions on whether to disclose. The
disclosure-clock service (chapter 04) tracks the
clock continuously; the hand-off is about the
*drafting* and *delivery*, not about awareness.

---

## Rehearsing the interface

A RACI exists but has never been exercised is nearly
as bad as no RACI. The rehearsal cadence:

- **Tabletop per playbook per quarter.** All
  interfacing teams in the room. Scenario is pulled
  from the chapter-03 playbook set and run against
  the RACI. Gaps become edits.
- **Live-fire per playbook per year.** The red team
  fires a payload against a non-production replica
  (or against a flagged-off path in production);
  nobody tells the on-call it is a drill. The
  interface is tested in anger. Measurements become
  the metrics.
- **Rota verification monthly.** A simple ping-test
  of each named rota (SOC, DFIR, Legal, ML Platform,
  Exec Sponsor) confirms the paging works and the
  phone is answered.

Rehearsals produce findings. The findings are tracked
as any other incident finding: in the incident-
management tool, with owners, with SLAs. "We will
tabletop more often" is not a finding.

---

## Standard failure modes

- **One hero model.** A single engineer who knows the
  AI stack, the SIEM content, the playbooks, and the
  legal interface. Great until they leave. The RACI
  distributes the responsibility across teams; the
  rehearsal keeps the distribution real.
- **"The AI team owns everything AI."** The
  programme is scoped out of the SOC's existing
  surface; the SOC never gets involved; the AI team
  becomes a parallel SOC with weaker tooling and no
  rota depth. Fix: AI incidents are SOC incidents.
- **Legal paged after the clock has run.** Clock
  starts at awareness; the on-call pages legal from
  the first SEV-1 / SEV-2 confirmation. The playbook
  requires it; the ticket intake enforces it.
- **DFIR arrives after the ML platform team has
  "cleaned up."** The container is gone, the logs
  are rotated, the retrieval index is overwritten.
  Containment preserves evidence; the playbook
  order is Preserve-then-Clean, not Clean-then-
  Preserve.
- **RACI never rehearsed.** The matrix exists in a
  Confluence page from eighteen months ago; team
  names and system names have changed; the rotations
  no longer page the people the matrix lists.
  Quarterly tabletops surface the drift.
- **"Consulted" treated as "informed."** The AI/ML
  Security role is Consulted on a containment
  decision; the SOC takes the decision without
  asking. The RACI is clear; the culture around it
  is not; chapter 05's exercise fixes the specific
  rows.
- **Executive sponsor named but not briefed.** The
  CISO is on the matrix as the SEV-1 approver; the
  CISO has never seen the AI playbooks. First real
  incident, the approver is reading the playbook
  during the war room.
- **No single accountable.** A row with "SOC Manager
  and AI/ML Security Lead and DFIR Lead" as A dilutes
  into no accountability. Pick one.
- **RACI written by one team.** The AI/ML Security
  Lead drafts the matrix in isolation; the SOC
  Manager has not signed off; execution reality
  diverges from the diagram. Fix: the RACI is a
  negotiated artefact.

---

## Summary

- **Three ownerships to assign** — the alert, the
  response, the notification — distributed across
  SOC, DFIR, legal, GRC, comms, exec, finance, HR,
  ML Platform, and the AI/ML Security role.
- **The AI/ML Security role does not run primary
  incident response.** It authors the detection
  content and the playbooks, maintains the severity
  ladder, provides the SME-on-call, co-authors the
  post-mortem, and owns the AI-specific portions of
  the governance evidence surface.
- **RACI per playbook phase** — Preparation,
  Identification, Containment, Eradication / Recovery,
  Notification, Lessons Learned — with exactly one A
  per row, teams named (not people), C and I kept
  narrow enough to be meaningful.
- **SLAs between interfaces** are negotiated in
  writing, not inferred. The SOC commits to
  acknowledgement time; the AI/ML Security role
  commits to SME-on-call; legal commits to
  notification-decision timelines; ML Platform
  commits to kill-switch execution within specific
  windows.
- **Two hand-offs** matter most: SOC-to-DFIR when the
  incident goes deep, and response-to-notification
  when the facts are ready for legal. Both must be
  explicit in the playbook.
- **Rehearsal is mandatory.** Tabletop per playbook
  per quarter; live-fire per playbook per year; rota
  verification monthly. A RACI never rehearsed is a
  diagram, not a plan.
- Standard failure modes are hero models, parallel
  AI SOCs, late legal paging, premature cleanup,
  unrehearsed matrices, consulted-treated-as-
  informed, undocumented accountability, and RACIs
  authored by one team.
