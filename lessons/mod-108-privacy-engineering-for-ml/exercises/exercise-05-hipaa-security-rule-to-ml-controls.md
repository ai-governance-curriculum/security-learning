# Exercise 05 — HIPAA Security Rule to ML Platform Controls

**Estimated effort:** ~3 hours
**Deliverable:** A committed HIPAA control-mapping bundle for
one PHI-using ML system, consisting of (a) a PHI-surface
inventory enumerating every store that holds ePHI on the
platform, (b) a filled-in control-mapping matrix with a row per
Security Rule standard and a column per PHI surface, (c) a
written **risk-analysis document** per §164.308(a)(1)(ii)(A)
covering the enumerated surfaces, (d) a BAA register listing
every third party touching ePHI with the status of the
agreement, (e) addressable-determination documents for each
addressable implementation specification that was *not*
implemented (or was implemented with a non-standard
alternative), (f) a prioritised remediation plan for the gaps
the mapping surfaces, and (g) a breach-notification playbook
sketch tying the ML incident runbook to the Breach
Notification Rule discovery clock.
**Prerequisites:** Chapter 05 read end-to-end. The chapter-01
tier placement (exercise 01) and chapter-02 inference-attack
packet (exercise 02) ideally completed for the target system
— the HIPAA risk analysis cross-references both. Access to
the target system's architecture (training, serving, logging,
retrieval, backup topology) and the list of third-party
services in the data flow. Access to the org's existing BAA
templates and risk-analysis template if one exists.

---

## Objective

Chapter 05's thesis is that the HIPAA Security Rule is not a
technology stack; it is a **programme** with required and
addressable standards that an ML platform's controls must
discharge, and the discharge is a mapping artefact — not a
claim.

By the end of this exercise you have:

- A PHI-surface inventory covering every place ePHI lives on
  the platform, including the surfaces teams routinely miss
  (prompt logs, canary sets, backups, monitoring dashboards).
- A **control-mapping matrix** per standard per surface,
  naming the concrete platform control, the owner, and the
  evidence artefact.
- A **risk-analysis document** that the Security Officer can
  sign, cross-referencing the tier-map placement and the
  inference-attack threat model.
- A **BAA register** that enumerates every third-party service
  touching ePHI and the status of its agreement.
- **Addressable-determination documents** that explain the
  addressable specifications that were not implemented with
  the default control (per the chapter: "we decided not to
  bother" is not a documented rationale).
- A **remediation plan** that prioritises the gaps.
- A **breach-notification playbook** sketch connecting the
  §164.308(a)(6) incident procedures to the §164.400–414
  Breach Notification Rule.

You are producing the artefacts an OCR auditor is handed.

> **Caveat.** This exercise does not provide legal advice.
> HIPAA compliance determinations belong to counsel and the
> org's Security Officer; this exercise trains the
> engineering muscle that produces the mapping and the
> technical evidence they review.

---

## Problem statement

Pick one PHI-using ML system. In order of preference:

1. A real ML product in your org that touches ePHI, under a
   BAA with a covered entity or operating as a covered entity.
2. A well-defined internal proof-of-concept — "a chat
   assistant for a clinical-decision-support team that reads
   patient notes and summarises for clinicians".
3. A hypothetical with enough detail that the mapping is
   specific — "a retrieval-augmented clinical-coding assistant
   fine-tuned on anonymised discharge summaries but serving
   production queries that contain patient-level details".

Whatever you pick, by the end of this exercise you must be
able to state:

- Covered-entity vs business-associate status; if business
  associate, the covered entity's identity (even in a hypo).
- Which PHI categories are processed (clinical notes, lab
  results, imaging, demographics, billing, etc.).
- Whether de-identification per §164.514 (Safe Harbor or
  Expert Determination) is in play, and for which data flows.
- Subcontractors / downstream services in scope (hosted LLM
  APIs, managed vector DBs, observability providers, cloud
  providers).

---

## Requirements

### Deliverable A — PHI-surface inventory

A one-page section enumerating every surface where ePHI lives
on the platform. Chapter 05 names seven; your inventory names
at least these and any others the system has:

1. PHI in **training data** (patient records, clinical notes,
   imaging — the corpus the model trains on).
2. PHI at **inference** (prompt / feature content at serving
   time).
3. PHI in **trajectory / prompt logs** (retained logs of
   prompts, tool calls, completions).
4. PHI in the **retrieval / RAG store** (indexed documents).
5. PHI in **model artefacts** (memorised weights; embeddings).
6. PHI in **supporting artefacts** (canary sets, feature-
   store snapshots, backups, log-analysis pipelines,
   monitoring dashboards that render PHI).
7. PHI in **downstream integrations** (third-party APIs the
   system calls; downstream consumers of model output).

Per surface, record:

- Store type and location.
- Volume (approximate; current / 90-day peak).
- Access control at today (role + mod-103 identity primitive).
- Retention policy today.
- Known gaps that this exercise's mapping will surface.

A surface that is "we don't retain prompt logs" counts; state
it and the enforcement mechanism (log drop at ingest, no
observability pipeline). A surface that is "we think we don't
retain prompt logs" is a gap — the enforcement mechanism is
what makes the claim real.

### Deliverable B — control-mapping matrix

A table following the chapter-05 template, with a row per
Security Rule standard / implementation specification and a
column (or a per-row annotation) per PHI surface. Minimum rows:

- Administrative safeguards (§164.308(a)(1)–(8), §164.308(b))
  — nine standards.
- Physical safeguards (§164.310(a)(1), (b), (c), (d)(1)) —
  four standards.
- Technical safeguards (§164.312(a)(1), (b), (c)(1), (d),
  (e)(1)) — five standards.
- Organizational (§164.314(a)) — BAA content.
- Documentation (§164.316(a), (b)(1)–(3)) — policies,
  retention, availability, updates.

Per row:

| §-ref | Standard / spec | R/A | ML platform control | PHI surface(s) | Owner | Evidence | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |

- `R/A` — required vs addressable per the Rule's text.
- `ML platform control` — the concrete control (not "we have
  security"). Where the control is cross-module, cite
  mod-103 / mod-104 / mod-105 / this chapter / etc.
- `PHI surface(s)` — the subset of Deliverable A surfaces
  this row covers. A row that applies universally says "All".
- `Owner` — the role / team accountable; the Security
  Officer is accountable for the programme but the row-level
  owner is often a different role (Platform IAM, SRE, legal).
- `Evidence` — the document path, dashboard URL, or
  config/key reference proving the control exists.
- `Verdict` — implemented / partial / gap. Partial rows
  state what is partial.

Every row has an answer. "N/A" is answerable only with a
documented reason — the exercise rejects implicit N/A.

### Deliverable C — risk-analysis document

A multi-page document that satisfies §164.308(a)(1)(ii)(A).
Structure:

1. **Scope.** The ML system, its data categories, its data
   subjects, its PHI surfaces (from Deliverable A), its
   covered-entity / business-associate posture.
2. **Threats.** The threats specific to each surface. Draw
   from:
   - mod-102 (threat modelling).
   - mod-106 (adversarial ML — model poisoning, evasion,
     extraction).
   - mod-107 (LLM / agent threats — indirect injection,
     tool-abuse, trajectory leakage).
   - Chapter 02 (inference attacks on the deployed model).
   - Chapter 03 (training-data / prompt-log leakage).
   - General IT-security threats (storage compromise,
     insider misuse, lost laptop, misconfiguration).
3. **Vulnerabilities.** The system's current weaknesses that
   those threats could exploit. Draw from Deliverable B's
   "partial" and "gap" verdicts.
4. **Likelihood × impact.** Per threat × surface, a
   likelihood estimate, an impact estimate, and a pre-
   mitigation risk score. Use the org's scale; or a 1–5
   scale with definitions in the preamble.
5. **Existing controls.** The implemented rows from
   Deliverable B that mitigate the risk.
6. **Residual risk.** Per threat × surface, the risk after
   existing controls — the number that drives Deliverable F
   remediation prioritisation.
7. **Review cadence.** Annual + on material change (new PHI
   surface, new subcontractor, new attack class, new
   regulation guidance).
8. **Sign-off.** Security Officer, platform SRE / IAM leads,
   ML security lead.

The risk analysis references:

- The exercise-01 tier placement (which puts PHI in the
  personal-sensitive band with `ε ≤ 1` targets).
- The exercise-02 inference-attack packet (threat model +
  SLOs).
- The exercise-03 DLP coverage report (recall per PHI entity).
- mod-104 lineage (training-run provenance; audit log).
- mod-105 KMS and key-rotation posture.

### Deliverable D — BAA register

A YAML / spreadsheet listing every third party that touches
ePHI on behalf of the platform. For each entry:

- Vendor name.
- Service / function used.
- Which PHI surface the vendor touches (training, inference,
  logging, retrieval, backup, monitoring).
- BAA status — in place (date, scope), negotiated, no BAA
  available.
- Subcontractor chain — if the vendor subcontracts to another
  provider that also touches ePHI, record the chain and
  verify the subcontractor BAAs exist (per §164.308(b)(2)
  and §164.502(e)).
- Enforcement — the platform mechanism that prevents PHI
  from reaching a non-BAA-covered vendor. Chapter 03's DLP
  is the usual answer; mod-107 chapter 03's tool ACLs
  reinforce for agent systems.

If a vendor has no available BAA, the register names the
enforcement that keeps PHI out of their path or flags that
the vendor cannot be used for PHI workloads.

Common ML-platform BAA entries:

- Hosted LLM APIs (OpenAI, Anthropic, Google, Azure, AWS
  Bedrock) — BAAs are available from some; not all SKUs are
  covered. Verify per contract.
- Managed vector databases.
- Observability / APM / log-aggregation providers.
- Cloud providers (BAA usually at the master-services-
  agreement level; verify it covers the specific ML services
  used).
- Fine-tuning marketplaces.
- Data-labelling vendors.

### Deliverable E — addressable-determination documents

For every addressable implementation specification in
Deliverable B that is **not** implemented in the default form,
produce a short document stating:

- The spec cited (§-ref, text).
- The decision — implemented with alternative X, or not
  implemented.
- The rationale — "reasonable and appropriate given
  <environment / cost / risk>". The chapter is explicit:
  "we decided not to bother" is not a rationale.
- The equivalent / compensating control, if any.
- The sign-off (Security Officer).

Classic cases:

- Encryption at rest (§164.312(a)(2)(iv)) — addressable; if
  not implemented, document loudly. In practice, the right
  answer is always to encrypt; a not-encrypted path with a
  convincing rationale is rare.
- Automatic logoff (§164.312(a)(2)(iii)) — common place where
  teams document an alternative session-management approach.
- Transmission encryption (§164.312(e)(2)(ii)) — same note as
  at rest.

If every addressable spec is implemented, Deliverable E is a
short note stating "all addressable specs implemented in
default form; no determination documents required".

### Deliverable F — remediation plan

A prioritised list of the gaps the mapping and the risk
analysis surfaced. Each entry:

- Gap description (what is missing / partial / wrong).
- Standard(s) affected.
- Risk score (from the risk-analysis Deliverable C).
- Owner.
- Target close date.
- Interim compensating control (what reduces the risk while
  the fix is in flight).

Prioritise by risk score. The top three entries carry a one-
paragraph justification each.

### Deliverable G — breach-notification playbook sketch

A one-page playbook sketch tying the ML incident runbook
(§164.308(a)(6) artefact) to the Breach Notification Rule
(§§ 164.400–414). The sketch:

- **Trigger inventory.** Named ML-specific triggers that
  likely constitute breaches: prompt-log exposure of PHI,
  cross-tenant retrieval hit, training data uploaded to a
  non-BAA-covered service, model-extraction attempt with PHI
  inputs, MI-AUC regression confirming membership for a
  specific patient.
- **Discovery clock.** Who starts it (Security Officer
  notification is step 1); when it starts (discovery, not
  containment); the §164.404 60-day cap and the §164.410
  business-associate-to-covered-entity notification path (and
  the typically-shorter BAA-contractual timeline).
- **Risk assessment.** The §164.402 four-factor low-
  probability-of-compromise test; who signs off.
- **Notification obligations.** Individuals (§164.404),
  Secretary (§164.408 — immediate for 500+, annual
  otherwise), media (§164.406 — 500+ in a jurisdiction).
- **Parallel clocks.** If the system also processes EEA data,
  the GDPR Art. 33 72-hour supervisory-authority clock runs
  in parallel; the playbook triggers both.
- **Documentation.** What is retained per §164.316 (six-year
  floor): the breach record, the risk assessment, the
  notification artefacts.

---

## Starter guidance

- **The hardest-to-see PHI surfaces are the ones that cost
  you.** Prompt logs, canary sets with members' PHI, monitoring
  dashboards that render patient IDs — these are the common
  OCR findings. Deliverable A exists specifically to make the
  team state them.
- **A control that cites "we have security" is a gap.** Every
  cell in the matrix is a named primitive (mod-103 identity,
  mod-105 KMS, chapter 03 DLP) with a configuration path.
- **Addressable ≠ optional.** The chapter is explicit, OCR
  guidance is explicit, and auditors are explicit. Encryption
  at rest and in transit is practically always the right
  answer; if you choose otherwise, write the rationale
  carefully.
- **Named Security Officer.** The §164.308(a)(2) role is a
  real person with real release-gate authority. If the role is
  a title on a policy, that is itself a gap.
- **BAA register is the enforcement question, not just the
  contract question.** A BAA with a vendor whose API you still
  send PHI to without the DLP check is a contract that papers
  over the real risk. The register's "enforcement" column is
  where the DLP / tool-ACL control lives.
- **De-identification as scope reduction.** If part of the data
  flow can run on §164.514-de-identified data (Safe Harbor or
  Expert Determination), the Security Rule surface for that
  flow shrinks dramatically. Explicitly identify where
  de-identification is possible; where it is not, defend the
  position with the tier-map band.
- **Breach-notification clocks run from discovery.** The
  playbook's first step is Security Officer notification;
  containment comes after discovery and does not stop the
  clock.
- **Six-year retention is a floor.** State the retention per
  artefact type (risk analysis, audit log, incident records,
  BAA documentation, policy documents) and verify the system
  can honour the floor across every store that holds the
  artefact. mod-104's immutable audit log is usually the
  primary store; the floor applies to backups too.

---

## Acceptance criteria

A passing bundle:

- The PHI-surface inventory enumerates at least the seven
  surfaces chapter 05 names, plus any system-specific
  additions, with current access control, retention, and
  known gaps.
- The control-mapping matrix has a row per Security Rule
  standard / implementation specification, with ML-platform
  control, PHI surface, owner, evidence, and verdict per row.
- Every addressable specification is either implemented in
  default form or has an addressable-determination document.
- The risk-analysis document covers scope, threats,
  vulnerabilities, likelihood × impact, existing controls,
  residual risk, review cadence, and sign-off, with cross-
  references to the technical exercises and modules.
- The BAA register enumerates every third-party vendor
  touching ePHI with BAA status, subcontractor chain, and
  the platform enforcement that prevents PHI reaching a
  non-BAA vendor.
- The remediation plan is prioritised by risk score and names
  owners, target dates, and compensating controls.
- The breach-notification playbook names ML-specific triggers,
  the §164.404 60-day cap, the business-associate 60-day
  notification path, and the parallel GDPR clock if
  applicable.

A failing bundle:

- Prompt logs or canary sets missing from the PHI-surface
  inventory.
- A matrix with "we have security" cells.
- Addressable specifications marked "optional" or "N/A"
  without a determination document.
- A risk analysis that does not cross-reference the chapter-
  01 tier placement or the chapter-02 inference-attack
  threat model.
- A BAA register listing a vendor as "BAA in place" without
  evidence or without the enforcement that keeps PHI inside
  BAA-covered paths.
- "The Security Officer is TBD".
- A breach-notification playbook that does not state that
  discovery (not containment) starts the clock.

---

## Stretch goals

- **De-identification feasibility study.** For the training
  data, draft a §164.514 Safe Harbor pass of the 18
  identifiers and determine which can be removed losslessly;
  for the ones that cannot (free-text clinical notes),
  propose the Expert Determination path and estimate the
  statistician engagement. Produce a one-page recommendation.
- **Subcontractor BAA trace.** For one third-party vendor in
  the BAA register, trace the subcontractor chain down to
  the actual data-handling party and verify the BAA chain is
  intact. Report the exposure if a gap is found.
- **Emergency-access rehearsal.** Design and (if feasible)
  rehearse the §164.312(a)(2)(ii) break-glass path for an
  on-call responder retrieving a specific patient's
  trajectory under incident conditions. Produce the audit-
  log trace of the rehearsal.
- **HIPAA + GDPR tension resolution.** Pick one tension
  (minimum-necessary vs. subject-access rights; breach-
  clock delta; cross-border transfer vs. HIPAA disclosure)
  and produce a one-page resolution memo describing how the
  Security Officer and the DPO coordinate.
- **Audit-log review runbook.** The §164.308(a)(1)(ii)(D)
  information-system-activity review is often a quiet gap —
  the audit log is retained but not reviewed. Produce the
  review runbook: who, how often, what signals trigger a
  deeper investigation, where the findings go.
- **42 CFR Part 2 overlay.** If the system touches substance-
  use-disorder records subject to Part 2, draft the Part 2
  overlay — stricter consent, re-disclosure prohibitions — on
  top of the HIPAA matrix. Flag the places where Part 2
  dominates.
- **OCR enforcement study.** Pick two recent OCR resolution
  agreements (from the HHS "Enforcement Highlights" or the
  Breach Portal) and produce a one-page "what would this
  enforcement action have cost us?" assessment against the
  current mapping.
- **State privacy-law overlay.** Overlay one state law (TX
  HB 300, CA CMIA, WA My Health My Data Act) on the HIPAA
  matrix; flag the deltas; name the rows where the state law
  dominates.

---

## Do not

- Do not accept "the covered entity did a risk analysis" as a
  substitute for the business associate's own risk analysis.
  §164.308(a)(1)(ii)(A) applies directly to business
  associates.
- Do not treat addressable implementation specs as optional.
  Default is to implement; non-default requires a written
  determination.
- Do not list "we have a BAA with AWS" without checking the
  BAA covers the specific services the ML workload uses.
  BAA scope varies by service and SKU.
- Do not log PHI in the control-mapping matrix itself. The
  matrix is widely read; keep patient-identifying content
  out of it.
- Do not confuse de-identified data with pseudonymised data.
  §164.514 de-identification (Safe Harbor or Expert
  Determination) is a specific regulatory status; hashed
  identifiers are not it.
- Do not design the break-glass emergency-access path without
  the audit log. Every invocation writes to mod-104's
  immutable store; the Security Officer reviews.
- Do not treat "we'll fix it later" as remediation. Interim
  compensating controls are named in Deliverable F; "later"
  is not a compensating control.
- Do not commit the solution bundle to this repo; solutions
  belong in the paired `-solutions` repo.
