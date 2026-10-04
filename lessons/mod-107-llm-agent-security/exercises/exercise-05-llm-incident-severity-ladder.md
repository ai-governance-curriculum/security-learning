# Exercise 05 — LLM/Agent Incident Severity Ladder

**Estimated effort:** ~3 hours
**Deliverable:** A committed severity-ladder bundle for one
org's LLM/agent surface, consisting of (a) an **adapted
five-tier ladder** that fits the org's existing incident-
management vocabulary (SEV-1…SEV-5, P0…P4, S1…S4 — whatever
is in use), with the chapter-05 objective triggers tailored
to the org's products; (b) a **detector-to-tier policy
table** that maps every chapter 02/03/04 detector (plus any
org-specific signal) to a default tier and an escalation
rule; (c) a **disclosure-clock matrix** naming the external
obligations each SEV-1 / SEV-2 trigger starts, with the
regulator/body, the deadline, and the primary-source
citation to verify; (d) an **evidence-and-reach schema** for
the trajectory artefact every incident preserves, including
the reach counter; and (e) **two seeded-scenario runbook
fragments** — written as the pages the on-call sees at
3 a.m. — for two concrete incidents (a tool-call data exfil,
and a runaway-consumption / LLM10 event) drawn from the
chapter-05 ladder.
**Prerequisites:** Chapter 05 read end-to-end; chapters
02–04 referenced for the detectors and trajectories the
ladder consumes; exercise 01 complete (the mitigation map
tells you which categories are in scope and thus which
incidents can land); exercise 03 complete (the tool
registry tells you which tiers exist and which Tier-3 tools
exist as SEV-1 triggers); exercise 04 complete (the
regression gate is one of the detectors). Access to the
org's existing incident-management playbook — paging
targets, severity vocabulary, legal-and-comms escalation —
even if those documents are classical and not LLM-aware.

---

## Objective

Turn chapter 05's reference ladder into *this org's*
operational artefact. By the end of this exercise you have:

- A ladder adapted to the org's severity vocabulary and
  paging surface, not a straight copy of chapter 05.
- A policy table that lets the on-call read the tier off
  the detector, not off a prose paragraph.
- A disclosure-clock matrix the legal team can review
  (and will — this is the artefact that keeps the GDPR /
  HIPAA / EU AI Act clocks from drifting).
- Two concrete runbook fragments that someone paged at
  3 a.m. can follow without reading chapter 05.

You are producing an **operations-facing** artefact. The
audience is the on-call rotation, the incident commander,
the legal-liaison role, and the governance / audit function
that will ask what evidence was preserved.

If the org has no incident-management surface today, the
exercise is still worth doing — the output doubles as the
scaffold for a future surface and names the primitives any
such surface will need.

---

## Problem statement

Pick one org — your employer, a sponsor organisation, or a
well-defined fictional org with a documented product
surface — whose LLM/agent systems you can reason about.
Whatever you pick, name up front:

- **Product surface in scope.** Which LLM/agent products
  exist, their user populations, the data classifications
  they touch (PII / PHI / cardholder / regulated by
  sector).
- **Jurisdictions.** Which regulators the org answers to:
  EEA/UK (GDPR), US states (NCSL index), US sector rules
  (HIPAA for PHI, GLBA for financial, FERPA for
  education), PCI DSS if payment cards flow, EU AI Act if
  the org places high-risk AI systems on the EU market.
- **Existing severity vocabulary.** Whatever the org calls
  tiers today (SEV-1 / P0 / S1 / Critical / etc.). The
  adapted ladder uses the org's names, not chapter 05's.
- **Existing paging and command surface.** Who gets paged
  where, who the incident commander is, where the
  evidence bucket lives, how the legal page is sent.
- **Existing retention policy.** How long security
  incidents are retained; chapter 05 assumed 3–7 years,
  but the org's number is what matters.

If any of the five items above is unknown, pin a
reasonable placeholder and flag it in the bundle. "The
org retains security evidence for 7 years per policy X.Y
(verify)." is a passing output; silently assuming it is
not.

---

## Requirements

### Deliverable A — the adapted five-tier ladder

A table and five short descriptions. The table maps
chapter 05's tier definitions onto the org's vocabulary:

| Chapter-05 tier | Org tier (name) | One-line definition | Response SLA (page target, time) | Disclosure surface |
| --- | --- | --- | --- | --- |
| SEV-1 — Confirmed material harm | | | | |
| SEV-2 — Confirmed exposure | | | | |
| SEV-3 — Attack with runtime prevention | | | | |
| SEV-4 — Detected attempt | | | | |
| SEV-5 — Diagnostic / rate noise | | | | |

For each tier, a short description (3–6 sentences) that
answers:

- **Objective triggers.** The specific triggers chapter 05
  names, *adapted to the org's product surface*. Example:
  "Confirmed exfiltration of PII" becomes "Confirmed
  exfiltration of customer PII from the Support Agent, or
  of PHI from the Clinical Scribe, through any tool call
  or model response". The org's actual products are named.
- **Named owners.** Who is paged (role, not person) and
  by what mechanism. Specific pages: "Security on-call
  via PagerDuty rotation SEC-24X7; ML Platform on-call via
  rotation MLP-24X7; Legal duty officer via group email +
  SMS fallback".
- **The runtime action.** What the runbook has the on-call
  do *first* — contain, preserve, assess, disclose, or
  tune — tailored to the tier.
- **The disclosure surface.** The regulator / body / card
  brand / internal-governance surface the tier
  potentially lights up. "Potentially" because legal owns
  the determination; the ladder *starts the clocks*.

The $ORG_SEV1_THRESHOLD and $ORG_SEV2_THRESHOLD financial
cutoffs from chapter 05 are concrete numbers in this
deliverable. If the org has no documented numbers, pick
defensible ones and name the argument. A $100 cutoff and
a $1M cutoff are both bad answers; argue for yours.

### Deliverable B — detector-to-tier policy table

A table that lets the on-call read the tier directly off
the firing detector:

| Detector | Source | Default tier | Escalation rule | Owning team |
| --- | --- | --- | --- | --- |

Minimum rows (add org-specific ones as applicable):

- Chapter 02 input-side injection classifier alert.
- Chapter 02 retrieval-time poisoning detector.
- Chapter 02 provenance-label violation at tool gate.
- Chapter 03 Tier-2 tool call blocked by runtime.
- Chapter 03 Tier-3 tool call blocked by runtime.
- Chapter 03 Tier-2 tool call executed after HITL
  approval.
- Chapter 03 Tier-3 tool call executed after HITL
  approval.
- Chapter 04 regression-gate CI failure.
- Chapter 04 engagement in-progress finding above the
  per-finding severity threshold.
- Mod-106 membership-inference anomaly alert (for the
  underlying model).
- Mod-104 provenance-mismatch alert on a model artefact
  or retrieval chunk.
- LLM10 unbounded-consumption budget-exceeded alert
  (per-caller, per-tenant).
- System-prompt-leak DLP hit on an outbound response.
- Cross-tenant data-crossover alert (if your runtime
  instruments one; name the signal if it does not exist
  yet).

The **escalation rule** is a *coded* condition (prose is
acceptable here, but the shape must be codable):

> "A single input-classifier alert on one identity is
> SEV-4. Ten alerts on the same identity within one hour
> escalate to SEV-3. If a Tier-2 tool call was attempted
> by the same identity in the window, escalate to SEV-2.
> If the Tier-2 tool call *executed*, escalate to SEV-1."

Every row must have an escalation rule or an explicit
"no escalation" (with reason).

### Deliverable C — disclosure-clock matrix

A matrix the legal team can review. One row per
regulatory / contractual obligation the org potentially
faces for an SEV-1 or SEV-2 incident:

| Obligation | Trigger (what facts activate it) | Clock start | Deadline | Primary-source citation to verify |
| --- | --- | --- | --- | --- |

Required rows (add sector-specific ones as applicable):

- **GDPR Article 33** (EEA/UK supervisory authority
  notification): trigger — personal data breach;
  clock-start — controller becomes aware; deadline — 72
  hours; citation — Regulation (EU) 2016/679 Article 33,
  OJEU text.
- **GDPR Article 34** (data-subject notification):
  trigger — high risk to rights and freedoms;
  clock-start — controller becomes aware; deadline —
  "without undue delay"; citation — Regulation (EU)
  2016/679 Article 34.
- **HIPAA Breach Notification Rule** (US PHI): trigger —
  unsecured PHI breach; clock-start — discovery;
  deadline — 60 days to individuals; HHS annually or
  within 60 days for ≥500 individuals; citation — 45 CFR
  §§ 164.400–.414.
- **PCI DSS incident response**: trigger — compromise
  involving cardholder data; clock-start — detection;
  deadline — per acquirer contract (often same-day);
  citation — PCI DSS v4.x Requirement 12.10.
- **EU AI Act serious-incident reporting**: trigger —
  serious incident of a high-risk AI system placed on the
  EU market; clock-start — provider's awareness;
  deadline — verify against the current OJEU
  consolidated text and any adopted implementing acts;
  citation — Regulation (EU) 2024/1689; article number
  must be verified at time of writing.
- **US state breach-notification laws**: trigger —
  resident of state X affected; clock-start / deadline —
  per state; citation — NCSL state-by-state index. One
  catch-all row with the NCSL pointer is acceptable; the
  org's legal team drives the state-specific detail.
- **Sector-specific**: GLBA (financial), FERPA
  (education), state insurance / telecom / healthcare
  rules — a row per obligation the org actually faces.
  Name the obligation or state out "not applicable
  because the org does not operate in sector X".

The matrix explicitly flags every row with a
`<!-- verify: ... -->` HTML comment pointing at the
primary source that must be re-checked (regulator pages,
OJEU consolidated text, NCSL index, HHS guidance, the
org's current contract with the acquirer). The on-call
runbook does not treat the matrix as authoritative; the
runbook *pages legal* with the facts and the matrix
*starts the clocks*.

### Deliverable D — evidence-and-reach schema

A schema (YAML or JSON Schema) for the trajectory artefact
every incident preserves. Chapter 05's required contents:

```yaml
trajectory_record:
  incident_id: string
  severity_tier: SEV-1 | SEV-2 | SEV-3 | SEV-4 | SEV-5
  detected_at: iso-8601
  detector:
    name: string
    policy_version: string
  caller_identity:
    workload_id: string
    user_id: string | null
    tenant_id: string
    identity_chain_cite: string
  sut_versions:
    system_prompt: string
    retrieval_index_snapshot: string
    tool_registry: string
    model: string
    runtime_commit: string
  prompt_record:
    fragments:
      - content: string
        provenance_label: system | user | tenant | retrieval | tool | unknown
        source_cite: string
  model_responses:
    - content: string
      tool_calls:
        - name: string
          arguments: object
          tier: 0 | 1 | 2 | 3
          runtime_decision: allow | block | hitl_required
          hitl:
            fired: boolean
            approver_simulated: null | conservative | permissive
            approver_decision: approve | deny
          result_summary: string
  reach_counter:
    affected_sessions: integer
    affected_users: integer
    affected_tenants: integer
    computed_at: iso-8601
    computation_method: string
  retention:
    classification: regulated
    retention_until: iso-8601
    access_log_pointer: string
```

Fields that are more constraints than data:

- **`reach_counter`.** Required for SEV-1 and SEV-2.
  Chapter 05 is explicit: "one user saw this" is a
  different disclosure surface from "ten thousand users
  saw this". If the runtime cannot currently compute the
  reach counter, name it as a *gap* with the owner who
  will build the instrumentation.
- **`provenance_label`.** Composes with chapter 02's
  trust-boundary primitive; a trajectory where the
  provenance labels were stripped is a chapter-02 bug
  surfaced by chapter 05.
- **`sut_versions`.** Pins exactly what the runtime
  saw. Composes with chapter 04's SUT version string.
- **`retention`.** Trajectories are regulated data —
  encrypted at rest, access-logged, non-exportable
  without approval. The schema names the retention
  class.

### Deliverable E — two seeded-scenario runbook fragments

Two short, concrete runbook pages. Each is written as the
material the on-call reads when paged, not as a lecture.

**Scenario 1 — Tool-call data exfil (SEV-1 candidate).**

Setup: at 02:14 UTC on a weekday, the detector `tool-gate.provenance_violation`
fires. The detector reports that `mail.send` was called with
a recipient address never present in the user turn, after a
retrieval chunk with `provenance_label: retrieval` injected
instructions. The runtime did *not* block the call because
the chapter-02 provenance policy for mail was `max_source_trust: tenant`
and the chunk's label was `tenant`.

The runbook page covers, in order:

1. **Initial tier and page targets.** State the tier (SEV
   from Deliverable A), who gets paged, and the SLA
   (minutes).
2. **Immediate containment steps.** Pre-authorised
   actions the on-call can take without approval — kill
   the agent identity, disable the `mail.send` tool at
   the registry (chapter 03), snapshot the retrieval
   index. State the specific commands or runbook links.
3. **Evidence preservation steps.** Which trajectory is
   captured, where it lands, who gets a copy of the
   access log. Legal-hold notice if SEV-1.
4. **Reach computation.** The query / procedure that
   produces `affected_sessions`, `affected_users`,
   `affected_tenants` for the retrieval chunk during
   the exposure window.
5. **Legal page.** The specific message the on-call
   sends to legal with the facts in hand. Chapter 05 is
   explicit: on-call *starts* the clocks, does not
   *decide* what to disclose.
6. **Clocks activated.** The rows from Deliverable C
   that fire for these facts: GDPR 72h, HIPAA 60d (if
   PHI touched), EU AI Act serious-incident report (if
   high-risk AI).
7. **Regression test owed.** The payload donates to the
   chapter-04 corpus; the sample ID the on-call files.
8. **What *not* to do.** Specific antipatterns: do not
   delete the retrieval chunk (preserve it); do not
   silently patch the tool (change management applies
   even in incidents); do not decide disclosure.

**Scenario 2 — Runaway consumption (LLM10, SEV-2
candidate).**

Setup: at 11:42 UTC, finance's cost-anomaly dashboard pages
the ML platform on-call: a single tenant's agent spend
over the past 90 minutes is 45× the tenant's daily p95 and
is accelerating. The runtime's per-identity budget cap
*did* fire for 4 of the 11 affected agent sessions, but
the cap is per-session, not per-identity, so the fifth
through eleventh sessions proceeded.

The runbook page covers, in order:

1. **Initial tier and page targets.** State the tier,
   who gets paged (security, ML platform, finance), the
   SLA.
2. **Immediate containment.** Disable the tenant's
   agent-budget grant (freezes further spend without
   requiring per-session kills), revoke the identity
   driving the loop, snapshot the trajectory.
3. **Classify the signal.** Chapter 05 is explicit —
   runaway consumption *can* be a security incident. The
   runbook has the on-call answer the specific question:
   is this a compromised identity (SEV-1 if cross-tenant,
   SEV-2 otherwise) or an unintended loop (SEV-2 on cost
   alone, SEV-3 after remediation)?
4. **Evidence preservation.** The trajectory of the
   runaway loop; the per-session cost breakdown; the
   finance ledger entry.
5. **Finance notification.** The specific message
   finance gets with the facts (amount, time window,
   tenant, next steps).
6. **Clocks activated.** Usually none regulatory; the
   contractual-SLA clock to the tenant may fire if the
   budget is customer-contracted. The matrix row that
   applies.
7. **Regression test owed.** The runtime bug (per-
   session cap instead of per-identity) donates a
   chapter-04 regression sample.
8. **What *not* to do.** Do not disable the model entirely
   (unneeded scope); do not report the amount externally
   without legal + comms review; do not treat it as
   "just ops".

Each fragment is 1–2 pages maximum. Prose written for a
tired human; bullet points and numbered steps preferred;
the role / page target / command *concrete*.

---

## Starter guidance

- **Start from the org's vocabulary.** Do not try to
  convince the org to adopt "SEV-1" if it has P0; map
  chapter 05's tiers onto the names in use. The names are
  a cosmetic layer; the triggers are the content.
- **The matrix is a legal collaboration.** Deliverable C
  is the artefact you ask legal to review. Pre-reading
  the primary sources (links in `resources.md`) lets you
  walk in with a draft rather than a question. Do not
  publish an unreviewed matrix as if it were
  authoritative.
- **Reach counter is boring and essential.** Chapter 05
  calls it out; the instrumentation to compute it is
  often missing in practice. If the runtime cannot
  produce it today, Deliverable D's gap flag is a
  real planning deliverable, not a shortcoming of the
  exercise.
- **Keep the runbook fragments concrete.** The on-call is
  tired and under time pressure. "Contact legal" is not
  as useful as "send this templated message to
  legal-pager@org via SMS; legal duty officer answers
  within 15 minutes per rota L-24X7". Specificity beats
  completeness.
- **Severity is code, not prose.** If a detector cannot
  programmatically emit a tier, that is a gap. The
  escalation rule in Deliverable B must be codable.
- **Don't double-count the model-text detector.** A DLP
  hit on an outbound response is one detector; the
  Tier-2 tool-call-executed signal is another. Chapter 05
  is strict about this — detection ≠ prevention.
- **Cost is a severity axis, not a special case.** The
  LLM10 scenario is a first-class incident; the schema in
  Deliverable D records cost as part of the trajectory.

---

## Acceptance criteria

A passing bundle:

- The ladder is adapted to the org's existing severity
  vocabulary and paging surface, not a verbatim
  chapter-05 copy.
- Objective triggers are tailored to named products —
  "the Support Agent" / "the Clinical Scribe" / "the
  Research Browser Agent", not "the agent".
- Every detector in Deliverable B has a default tier *and*
  a codable escalation rule, or an explicit "no
  escalation" with reason.
- The disclosure-clock matrix cites a primary source per
  row and flags each row with a `<!-- verify: ... -->`
  pointer. Legal has either reviewed the matrix or the
  bundle names the open review as a gap.
- The trajectory schema is machine-readable (YAML or
  JSON Schema) and includes the reach counter and
  retention metadata. Missing instrumentation is named as
  a gap with an owner.
- The two runbook fragments are concrete: specific
  commands, specific page targets, specific legal
  message, specific clocks, specific "do not" steps.
- Cross-references to chapters 02 (provenance), 03 (tool
  tier), 04 (trajectory, regression), and sibling
  modules (104 lineage, 105 identity revocation, 109
  evidence, 111 incident-management) are present where
  relevant.

A failing bundle:

- The ladder is a copy of chapter 05 with no org-specific
  content.
- Triggers written in prose that require narrative
  interpretation ("significant exposure", "material
  harm" — numbers and defined terms are required).
- A disclosure-clock matrix published as authoritative
  without a legal review and without `<!-- verify: ... -->`
  flags.
- A reach counter marked "we'll instrument later" with
  no owner and no target date.
- Runbook fragments that read like essays or that offload
  the decision to the human ("page security and figure
  it out") — the runbook is a procedure.
- The LLM10 scenario filed as "an ops issue" rather than
  an incident with a tier.
- "User error" assigned as the root cause for a HITL
  bypass without a referential pointer back to chapter 03
  (rubber-stamp risk is a design finding, not a human
  failing).

## Stretch goals

- **Playbook integration.** Translate the two runbook
  fragments into the org's incident-management tool's
  native format (PagerDuty runbooks, Opsgenie actions,
  Jira templates). Attach them to the detector that
  fires them.
- **Incident-clock service sketch.** Chapter 05 mentions
  an "incident-clock service" that reads the SEV-1/
  SEV-2 feed and tracks deadlines. Sketch the service's
  API — the fields it needs, the backing store, the
  escalation surface, the retention.
- **Governance-evidence export.** Emit each incident
  record in the format mod-109's evidence surface
  expects. Attach the trajectory ID, the detector, the
  SUT versions, the reach counter, and the disclosure
  outcome.
- **Chronic-pattern feedback.** Specify how chronic SEV-3
  / SEV-4 volume against a specific detector triggers a
  tuning review and feeds the chapter-04 corpus. Chapter
  05 names this as a corpus-growth path.
- **Tabletop exercise.** Author a tabletop script that
  walks a cross-functional group (security, ML platform,
  legal, comms, exec) through one of the two seeded
  scenarios. Record the exercise's findings as the first
  entries in a lessons-learned register.
- **Model-card hook.** Pair each SEV-1 / SEV-2 trigger
  with the model-card (mod-104, mod-109) row that must
  be updated post-incident. The hook is what makes the
  evidence surface *authoritative* over time.

## Do not

- Do not publish a disclosure-clock matrix without legal
  review; the matrix is a working artefact, not an org
  policy, until legal signs off.
- Do not treat the ladder as a static document. Chapter
  05 says it; every incident is a feedback loop; the
  ladder evolves.
- Do not write runbook steps that assume calm.  A tired
  human reads the page; the steps match that reader.
- Do not conflate detection with prevention in the
  policy table. A detector that fired is one row; the
  runtime block (or non-block) is another.
- Do not store trajectory data with weaker protections
  than the data classification it contains. A trajectory
  that touched PHI is PHI.
- Do not commit a solution here — solutions live in the
  paired solutions repo.
