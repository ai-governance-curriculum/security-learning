# Exercise 03 — AI Incident-Response Playbook Set

**Estimated effort:** ~3 hours
**Deliverable:** A committed playbook set for one
organisation's AI/ML surface, consisting of (a) **four
PICERL / SP 800-61-shaped playbooks** — Data-Poisoning
Discovery, Prompt-Injection Exploitation, Model Theft,
Agent Misuse — adapted to the org's incident-management
tooling, naming, and paging surface; (b) a **shared
evidence-manifest template** reused by all four playbooks
listing the exact artefacts to preserve (trajectory bundle,
model digest, retrieval-index version, tool-registry
version, audit windows) with the storage target and
retention period; (c) a **containment-controls inventory**
naming the specific kill switches, revocation primitives,
and freeze mechanisms the playbooks depend on, each with
the identity authorised to run it and the SLA for its
execution; (d) a **rehearsal plan** scheduling tabletop
and live-fire exercises per playbook across the next
twelve months with explicit scenarios, participants, and
success criteria; (e) one **worked tabletop scenario** per
playbook (short — a page each) framed as the inject the
exercise leader reads to participants; and (f) a one-page
**gap report** identifying playbook steps the org *cannot
yet execute* and the engineering tasks (owner, effort)
required to close those gaps.
**Prerequisites:** Chapter 03 read end-to-end for the
playbook scaffold. Chapter 01 and chapter 02 referenced
for the detector set that triggers each playbook.
Chapter 04 read for the severity ladder each playbook
feeds. Chapter 05 read for the RACI the playbooks execute
against. Mod-107 chapters 02 / 03 / 05 (prompt injection,
tool ACLs, trajectory evidence) and mod-110 (supply-chain
signing) referenced for the mod-level primitives the
playbooks assume.

---

## Objective

Chapter 03's claim is that an AI/ML programme needs
*four specific playbooks*, written in the PICERL / SP
800-61 shape, each executable at 3 a.m. by someone who
did not design the system. This exercise is where those
playbooks are adapted to *your* organisation — its
incident-management tool, its paging surface, its
specific kill switches, its specific trajectory format
— and rehearsed enough that a real incident does not
start from scratch.

By the end of this exercise you have:

- Four organisation-specific playbooks, each
  structurally aligned to chapter 03 but populated
  with the org's actual systems, commands, and
  owners.
- A shared evidence-manifest template so the four
  playbooks collect comparable artefacts.
- An inventory of the containment controls the
  playbooks rely on, honest about which exist today
  and which are planned.
- A rehearsal plan that puts a tabletop or live-fire
  exercise on the calendar for each playbook within
  twelve months.
- Four worked tabletop scenarios ready to run.
- A gap report that is useful to engineering leaders:
  these are the controls we need to build to make the
  playbooks actually executable.

You are **not** running a real incident in this
exercise. You are producing the artefacts that make a
real incident runnable without panic.

---

## Problem statement

Pick one organisation up front — your employer, a
sponsor organisation, or a well-defined fictional org
with a documented product surface. Name:

- **Product surface in scope.** Which AI/ML products
  (serving models, agents, retrieval systems), their
  user populations, their data classifications.
- **Incident-management stack.** PagerDuty / Opsgenie
  / xMatters paging; Jira / ServiceNow / Shortcut
  tickets; Slack / Teams channel conventions; status-
  page system.
- **Kill-switch surface.** What exists today: tool-
  registry disable, identity revocation (OIDC / IAM),
  retrieval-index freeze, deployment-admission freeze,
  budget cap, model rollback.
- **Owners.** Teams named for SOC, ML Platform, DFIR,
  Legal Liaison, GRC, Comms, Exec Sponsor — chapter
  05's RACI applies.

If any of these are not in place, say so; the gap
report will capture them.

---

## Requirements

### Deliverable A — four playbooks

For each of the four playbooks (A: Data-Poisoning
Discovery, B: Prompt-Injection Exploitation, C: Model
Theft, D: Agent Misuse), produce a document with:

- **Metadata header.** Playbook ID, title, version,
  owner, last reviewed, next review.
- **Trigger block.** The specific detectors (named by
  rule ID from exercises 01 and 02 if available, or
  by chapter-01/02 reference) and signals that fire
  the playbook.
- **Severity default + escalation rules.** The default
  tier from chapter 04, with the escalation triggers.
- **RACI reference.** Pointer to the matrix in
  exercise 05; name the roles explicitly here even if
  the matrix is the source of truth.
- **PICERL phases.** P (ongoing), I, C, E, R, L. Each
  phase has numbered steps; each step is executable
  (command / tool / expected output / next step),
  not narrative.
- **Evidence manifest.** Reference deliverable B;
  state the playbook-specific additions.
- **Disclosure clocks.** Reference the clock-tracker
  (chapter 04); state which obligations typically
  apply.
- **Communications.** Internal channel, external
  language reference, specific pre-approved snippets.

Rules:

- **Commands, not narrative.** "Investigate the
  session" is not a step; "`kubectl -n ml-serving
  logs <pod> --since=1h --timestamps`" is.
- **Specific tools, specific commands.** Reference
  the actual CLI invocations against the actual
  systems; placeholders where the system doesn't
  exist, with a note referencing the gap report.
- **No new terminology.** Use chapter 03's naming
  (trajectory, reach counter, tool tier) consistently.
- **Length ≤ 10 pages each.** A playbook longer than
  that is unreadable at 3 a.m.

### Deliverable B — shared evidence-manifest template

A single template referenced by all four playbooks,
listing the artefact types to preserve. Shape:

```yaml
evidence_manifest:
  storage_target:
    primary: "s3://ir-evidence-<org>/incident-<id>/"
    retention_days: 2555   # ~7 years; adjust per org policy
    immutability: "object-lock-governance"
    access: "legal-hold-tag; two-person approval for export"

  artefacts:
    trajectory:
      source: "llm_gateway.trajectory_bundle_ref"
      format: "ndjson with provenance labels"
      size_bound: "~N MB per session; grab full window"
      required_for: [playbook-A, playbook-B, playbook-D]

    model_version_pin:
      source: "model_registry.resolve_digest(<model_name>, <serving_time>)"
      format: "sha256 digest + signed attestation reference"
      required_for: [all]

    retrieval_index_snapshot:
      source: "retrieval_store.snapshot(<time>)"
      format: "full index + content-store objects at the point in time"
      required_for: [playbook-A, playbook-B]

    tool_registry_version:
      source: "tool_registry.get_version(<time>)"
      required_for: [playbook-B, playbook-D]

    identity_access_log:
      source: "oidc_provider.access_log(<identity>, <window>)"
      required_for: [playbook-B, playbook-C, playbook-D]

    object_store_audit:
      source: "<cloud>.audit_log(<bucket>, <window>)"
      required_for: [playbook-A, playbook-C]

    system_prompt_version:
      source: "prompt_template_store.get_version(<time>)"
      required_for: [playbook-B]

    chain_of_custody:
      source: "ir_tool.chain_of_custody_record(<incident-id>)"
      required_for: [all]
```

Rules:

- **Each artefact names its upstream source.** No
  artefact comes from "we'll figure it out".
- **Retention is one number** per org policy, cited.
- **Immutability is explicit.** Object lock, write-
  once storage, or a signed append-only log; not
  "we trust the bucket".

### Deliverable C — containment-controls inventory

A table or YAML listing every kill switch /
revocation / freeze the playbooks depend on. For each:

- **Name.** "Tool-registry disable", "Identity
  revocation (OIDC)", "Retrieval-index freeze",
  "Deployment-admission freeze", "Budget cap", "Model
  rollback".
- **Mechanism.** The specific tool and the command
  pattern.
- **Authorised identity.** The role that may execute
  it (RACI).
- **SLA.** The time budget for executing (minutes).
- **Blast radius.** What breaks if run on a false
  positive.
- **Status.** Exists / planned / gap.
- **Playbook consumers.** Which playbooks depend on
  this control.

Entries marked `planned` or `gap` feed deliverable F.

### Deliverable D — rehearsal plan

A calendar document covering twelve months with:

- **Per playbook:** one tabletop per quarter, one
  live-fire per year, participants named by role.
- **Scenarios per exercise.** A one-line description
  of the scenario each exercise will run (do not
  reuse the same scenario within six months).
- **Success criteria.** Mean time to acknowledge,
  mean time to contain, playbook adherence rate,
  evidence completeness.
- **Governance tie-in.** Each exercise produces an
  after-action record that feeds the mod-109
  evidence surface.

A calendar page is enough; it is a planning artefact,
not a Gantt chart.

### Deliverable E — one worked tabletop per playbook

For each playbook, write a single-page tabletop
scenario the exercise lead reads to participants. Each
scenario includes:

- **Pre-brief** (two sentences) — product and
  context.
- **Inject timeline** — the sequence of events the
  lead reveals: initial detector fire, follow-up
  signals, external developments (a journalist
  reaches out, a customer tweets, legal asks a
  question). Four to six events per scenario.
- **Decision points** — the moments where the
  exercise lead stops and asks what the responders
  decide.
- **Expected trajectory** — the shape the exercise
  should take if the playbook is followed; useful
  for the after-action.

Scenarios should be realistic and specific — a tool
name, a dataset name, a time of day. Scenarios should
touch the playbook's edge cases (containment under
cost pressure; disclosure clock pressure; cross-team
hand-off).

### Deliverable F — gap report

A one-page report identifying playbook steps the org
*cannot execute today*. Each gap includes:

- **Playbook phase and step.**
- **Why it is a gap.** The specific control, tool,
  identity, or process that is missing.
- **The engineering task to close it.** Named
  deliverable, owner (team), effort estimate (1–4
  weeks).
- **Risk until closed.** What the responder has to
  improvise today.

Gaps feed the programme's roadmap.

---

## Starter guidance

- **Start from one real recent incident shape** your
  org (or industry) has experienced, not from the
  abstract. The playbook writes itself when you
  grind through "what would we have done at 02:37".
- **Numbered steps or no steps.** Prose paragraphs
  belong in the chapter; the playbook is checklists.
- **Specify who clicks what.** "The ML platform on-
  call disables the tool via `toolctl disable
  <tool-id> --reason incident/<id>`." Not "the
  platform disables the tool".
- **Containment first, investigation second.**
  Playbooks structured as Investigate → Contain →
  Preserve lose time. The chapter 03 order is Preserve
  → Contain → Investigate.
- **Legal paged early.** Every SEV-1 and SEV-2
  playbook includes a legal page in the first
  identification steps, not in notification.
- **Reach is a required output of identification.**
  The playbook does not continue past I without a
  reach number (or the explicit note that reach is
  being computed and the ticket is updated when it
  arrives).
- **Rehearsals are on the calendar.** Not "we will
  rehearse"; a date.
- **Gaps are specific.** "Tool-registry does not
  support cross-tenant disable" is a gap; "the
  tool registry is immature" is not.

---

## Acceptance criteria

A passing bundle:

- Four playbooks structurally aligned to chapter 03,
  populated with org-specific systems and commands.
- A shared evidence-manifest template referenced by
  all four.
- A containment-controls inventory with status per
  control and blast-radius assessment.
- A twelve-month rehearsal plan.
- Four worked tabletop scenarios.
- A gap report with sized engineering tasks.

A failing bundle:

- Playbooks written as narrative paragraphs.
- Evidence manifests that omit retention,
  immutability, or chain-of-custody.
- Containment controls that are "planned" with no
  engineering task to actually build them.
- Rehearsal plan that is "we'll do a tabletop
  someday".
- Tabletop scenarios that are abstract.
- Gap report that is a list of principles instead of
  tasks.

---

## Stretch goals

- **Automation hooks.** Where a step is scripted
  (`toolctl disable`, `revoke-identity`), wrap it in
  a safe-mode runbook action in the IR tool
  (StackStorm, Tines, Shuffle, PagerDuty Rundeck)
  such that it is one click rather than a free-
  text command.
- **Multi-tenant posture.** Add scenarios where the
  incident spans two tenants of a multi-tenant AI
  product; show how containment separates them.
- **Red-team integration.** Build one scenario
  jointly with a mod-107 chapter 04 red-team run so
  the live-fire exercise is a scheduled red-team
  campaign the SOC does not know about.
- **Metrics instrumentation.** The IR tool emits
  MTTR / MTTA / playbook-adherence per exercise; the
  metrics flow to the governance dashboard.
- **Disclosure-clock rehearsal.** Include a GDPR 72-
  hour clock in one tabletop and run the real
  clock-tracker in test mode; measure whether the
  rehearsal would have met the deadline.
- **Insider-threat scenario.** For playbook C,
  write a scenario where the attacker is an
  employee leaving the company; involve HR and
  legal early.
- **Chain-of-custody deep dive.** Build a one-page
  SOP for how trajectory bundles are hashed, stored
  under object-lock, and exported for external
  counsel.

---

## Do not

- Do not design playbooks that assume systems you
  are not sure exist. Mark the dependency and feed
  the gap report.
- Do not conflate severity levels across the four
  playbooks; defer to chapter 04 and exercise 04.
- Do not include legal-notification *content*
  (actual regulator wording) in the playbook; the
  playbook pages legal, legal drafts.
- Do not include the solution bundle in this repo.
  Solutions live in the paired `-solutions` repo.
- Do not treat a tabletop as optional. The playbook
  that is never rehearsed will fail its first real
  incident.
