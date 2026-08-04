# Exercise 05 — Role Scope and Deferral Contract

**Estimated effort:** ~2 hours
**Deliverable:** One signed-shape deferral contract document
(~5–6 pages Markdown)
**Prerequisite:** Chapter 05 read end-to-end; Exercises 01–04
outputs referenced

---

## Objective

Produce the **signed deferral contract** described in chapter 05 — a
single document that names, for every security-engineering artifact
this role could plausibly own, who owns it, who consumes it, and
what handshake happens at the boundary. This is Exercise 05's
deliverable and the artifact you will maintain in mod-112 for the
rest of the track.

## Problem statement

You have been in the AI/ML Security & Governance Engineer role at
your fintech for six weeks. Your manager (the head of AI governance,
level 60) has flagged three symptoms:

- Two design reviews last month stalled because nobody agreed
  whether the LLM harm-classification work sat with you or with the
  level-25 AI Risk Engineer.
- Your peer `ai-evaluation-engineer` has been shipping release
  reviews for a fraud-model refresh that use language identical to
  your Exercise 03 vocabulary rewrite — good — but they have also
  been drafting the OPA/Gatekeeper policies themselves, which
  should be your queue.
- The SOC opened an on-call ticket last week paging you at 03:00 for
  a fairness regression that turned out to be a model-quality
  incident owned by the ML team, not a security incident.

The head asks you to bring a deferral contract to the next AI
governance leadership meeting.

## Requirements

Produce a Markdown document with the following structure. The
document is the artifact — the layout is the shape of the artifact,
not a suggestion.

### Section 1 — Preamble

- The role's charter in one paragraph. Chapter 05 §"The role's
  charter in one paragraph" is the template — you may paraphrase for
  your own organisation but keep the shape.
- The scope statement: "This document defines the working boundary
  between the AI/ML Security & Governance Engineer role and the
  adjacent roles listed below, effective from <date> until the next
  annual review."

### Section 2 — Adjacent-role scope tables

One table per adjacent role. Chapter 05 §§ 5.1–5.7 provide the
templates. For each of the seven relationships, produce a table with
columns:

| Artifact | This role | Adjacent role | Handshake |
| --- | --- | --- | --- |

Adjacent roles required (do not omit any):

1. `ai-risk-engineer` (level 25).
2. `ai-evaluation-engineer` (peer, level 35).
3. `agentic-safety-engineer` (level 40).
4. `senior-ai-governance-architect` (level 50).
5. `head-of-ai-governance` (level 60).
6. Enterprise Security Operations / DFIR.
7. Legal counsel.

Every row per table must name the artifact, mark ownership
(`Owns` / `Contributes` / `Consumes` / `Reviews` / `Out of scope`)
for each side, and describe the handshake in one clause.

You may add rows to any table for artifacts specific to your
Exercise 01–04 outputs (e.g., "the fintech LLM agent's tool ACL
configuration"). Do not add rows that duplicate rows in another
table.

### Section 3 — Escalation path and trigger set

- **Escalation path.** A one-diagram or bulleted list showing where
  this role escalates and to whom, and where adjacent roles escalate
  when they need this role.
- **Escalation triggers.** At least five explicit trigger criteria.
  Examples: "an incident where SOC MTTR crosses the SLO," "a
  release-gate rejection whose remediation exceeds two eng-weeks,"
  "a threat-model finding that names an attack class published in
  the last quarter." Trigger criteria must be observable — an
  automated check can identify them without asking the engineer.

### Section 4 — Review cadence

- Quarterly review with each adjacent role: one-line agenda, meeting
  cadence, owner.
- Annual re-sign with the full set of signatories.
- Ad-hoc trigger for out-of-cycle updates (new framework, new attack
  class, org restructure).

### Section 5 — Signature block

The signature block for:

- This role (you).
- Each adjacent role (seven signatures).
- The CISO organisation representative (one signature).
- The head of AI governance (one signature).

The document is signed by name and role, with a version and an
effective date. Use placeholder names for the exercise; the shape is
the point.

### Section 6 — Resolution of the three symptoms

At the end of the document, add a short section (three paragraphs
maximum) addressing the three symptoms the head named in the
Problem Statement:

1. Whether the LLM harm-classification design work sits with this
   role or with `ai-risk-engineer` (level 25) — cite the relevant
   row of the § 5.1 table.
2. Whether the OPA/Gatekeeper policy authoring sits with this role
   or with the peer `ai-evaluation-engineer` — cite the § 5.2 row.
3. How the SOC-page-for-fairness-regression is prevented next time
   — cite the § 5.6 row and reference the incident classification
   rule the runbook should use.

## Starter guidance

- Chapter 05 is a working template. Use it. The exercise is not to
  reinvent the shape; it is to fill it in with the fintech's
  specifics.
- The three symptoms in the problem statement are the acceptance
  test. If your contract does not resolve them, it is not doing its
  job.
- The escalation trigger set is where most first-draft contracts are
  weak. Trigger criteria should be observable and automatable.

## Acceptance criteria

A passing deferral contract:

- Has all seven adjacent-role tables.
- Every table has at least the rows shown in chapter 05, plus any
  fintech-specific additions.
- Every row has ownership marks for both sides and a handshake
  clause.
- The escalation trigger set has at least five observable criteria.
- The three symptoms in the problem statement are resolved by
  citation to the relevant table row.

A failing deferral contract:

- Skips a table because "we don't really deal with them" (this role
  deals with all seven).
- Uses "shared ownership" as a resolution — the whole point is to
  decide.
- Has no escalation trigger set, or has triggers that require
  subjective judgement to identify.
- Cannot resolve the three symptoms.

## Stretch goals

- Extend the contract with an eighth table for a role your
  organisation actually has that chapter 05 does not cover: a
  Product Security team, a Trust & Safety team, a data-privacy
  officer, an internal audit function, a research safety team.
- Sketch the annual-re-sign checklist that mod-112 will run against
  this document: what needs to be reviewed, by whom, in what order,
  with which supporting evidence.
- Draft an FAQ page — the ten questions your peers most commonly
  ask about the boundary, and the contract-derived answers.

## Do not

- Do not use "shared ownership" as an answer. If a row is genuinely
  shared, the artifact splits into two artifacts with distinct
  owners.
- Do not skip Legal or Enterprise SOC because they seem too senior
  or too far away. They are on the contract because they are on the
  handshake path daily.
- Do not commit a solution — solutions live in the paired solutions
  repo.
