# Exercise 02 — MITRE ATLAS TTP Tour and Detection Map

**Estimated effort:** ~2 hours
**Deliverable:** One Markdown document with a technique-coverage
register + three detection-content stubs + one runbook stub
**Prerequisite:** Chapter 02 read end-to-end; the coverage matrix
from Exercise 01 available for cross-reference

---

## Objective

Walk a chosen ATLAS tactic technique by technique, produce a
data-source-and-detection **coverage register** for the target
system, and draft three ATLAS-tagged detection-content stubs plus
one runbook stub. The output is the kind of artifact your peer
`ai-evaluation-engineer` needs to see attached to a release gate and
that mod-111 will build on.

## Problem statement

Continue with the fintech LLM-agent-plus-fraud-classifier system
from Exercise 01. You do **not** need to redo the system description
— reference Section 1 of that document.

You have decided to start with the **ML Model Access** tactic
because model-extraction and query-based inference attacks are the
top-three risk for both surfaces in your Exercise 01 executive
summary.

## Requirements

Produce a Markdown document with the following structure:

### Section 1 — Tactic selection and scope

- Which ATLAS tactic you are walking (ML Model Access; if you argue
  for a different tactic, defend the choice).
- Which system asset (fraud model, LLM agent, or both) the tactic
  applies to.
- The refresh date and matrix version you walked ATLAS against — the
  framework is living; version-pin the artifact.

### Section 2 — Technique coverage register

For each technique under the chosen tactic on
[atlas.mitre.org](https://atlas.mitre.org/), produce a row in a
coverage register with columns:

| Column | Requirement |
| --- | --- |
| Technique ID | Verified from the live catalogue. |
| Technique title | Verified from the live catalogue. |
| Applies to system? | YES / NO with a one-sentence justification specific to the fintech system. |
| Data source required | The concrete log source / metric / trace the technique produces. |
| Data source available? | YES / NO / PARTIAL against the fintech's assumed logging posture (state your assumption). |
| Detection status | Implemented / Drafted / Gap. |
| Preventive mitigation status | The OWASP-column control from Exercise 01 that reduces this technique's likelihood. |
| Cross-reference | The Exercise 01 OWASP row (or NIST AI 100-2 attack family from chapter 03) this technique maps to. |

The register does not require every technique to be Implemented; it
requires every technique to be **classified**.

### Section 3 — Three detection-content stubs

For three techniques from the register that you classified as
"Drafted" or "Gap", produce a stub in pseudo-Sigma (or the
SIEM-native equivalent). Each stub must include:

- Title referencing the ATLAS technique.
- `atlas_technique_id` and `atlas_tactic_id` tags in metadata.
- Detection logic — pseudo-query with a threshold and a window.
- The `logsource` (which pipeline produces the events).
- False-positive shape and a note on tuning.
- A pointer to the runbook that fires on the alert.

You are not implementing production Sigma rules. You are producing
an authoring stub that a mod-111 detection engineer can turn into a
production rule.

### Section 4 — One runbook stub

For the highest-impact technique in Section 3, produce a runbook
stub with the sections:

- **Trigger**: which alert(s) route here.
- **Triage**: what to check first (adjacent telemetry, correlated
  events, tenant context).
- **Containment**: revoke / rotate / restrict actions and their
  side effects.
- **Root-cause investigation**: which ATLAS tactic came before,
  which technique enabled it, what to preserve for forensics.
- **Notification path**: owner team, CISO, Legal, deployer, end-user
  (where applicable), regulator (where applicable).
- **Recovery**: how the platform returns to green.
- **Post-incident review hook**: which sections to add to the PIR
  document.

The runbook stub does not need to be exhaustive. It needs to be
walkable by an on-call engineer at 03:00.

### Section 5 — Coverage-gap summary (0.5 page)

- Techniques with no data source available (the mod-112 logging-
  investment ticket).
- Techniques with data source but no detection content (the mod-111
  detection-authoring backlog).
- Techniques that require an ATT&CK (not ATLAS) counterpart —
  mark them and note the enterprise handshake.

## Starter guidance

- Open [atlas.mitre.org](https://atlas.mitre.org/) and refresh the
  ML Model Access technique list before you start. Do not rely on
  the tactic list in chapter 02 alone — it is illustrative and may
  lag the live matrix.
- The pseudo-Sigma stub in chapter 02 is a template. Copy it and
  adjust the tags, the logsource, and the threshold to your case.
- If a technique's data-source requirement is not something your
  system produces today, do not fake availability. Mark the source
  as "Gap" and file it against mod-112 logging investment.

## Acceptance criteria

A passing coverage register:

- Every technique in the chosen tactic on the live ATLAS catalogue
  has a row.
- The matrix version is version-pinned in Section 1.
- At least one technique is classified as a Gap (a coverage
  register that shows 100% coverage is almost certainly wrong for a
  first pass).
- Every "NO" applies-to-system answer defends the negation.

A passing detection stub:

- The `atlas_technique_id` tag matches a technique in the current
  live matrix.
- The detection has a threshold and a window, not just a keyword
  match.
- The false-positive shape is described (it is not "none").
- The runbook the alert routes to is named.

A passing runbook stub:

- The Triage → Containment → Root-cause chain is walkable — a
  responder without ATLAS expertise could execute it.
- The Notification path is not vague. Roles are named.

A failing deliverable:

- Skips the version-pin.
- Uses invented ATLAS IDs not present in the live catalogue.
- Uses "monitor for suspicious activity" as detection logic.
- Skips the runbook stub because "IR is out of scope of this
  module."

## Stretch goals

- Extend the exercise to a second ATLAS tactic (ML Attack Staging is
  a natural pair). Reuse the register format.
- Write one paragraph analysing the ATLAS ↔ ATT&CK bridge for the
  fintech system: which techniques in your register are actually
  ATT&CK-generic (Initial Access via web exploit, Credential Access
  via credential stuffing) and how does that change ownership.
- Sketch the mod-112 logging-investment ticket the register
  produces: which data sources need to be added, roughly what they
  cost to add, and roughly what coverage they unlock.

## Do not

- Do not invent technique IDs. Every ID cited must be verifiable at
  atlas.mitre.org.
- Do not commit a solution — solutions live in the paired solutions
  repo.
- Do not treat the runbook stub as a policy document. It is an
  operational document; write it for an on-call engineer.
