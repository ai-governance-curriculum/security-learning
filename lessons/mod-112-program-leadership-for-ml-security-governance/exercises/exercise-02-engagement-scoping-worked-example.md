# Exercise 02 — Engagement Scoping: A Worked Example

**Estimated effort:** ~3 hours
**Deliverable:** A full engagement-scoping bundle for one
realistic ML system of your choosing (an internal ops
assistant, a customer-facing recommender, a clinical
decision-support tool, a RAG application, a frontier-tier
agent — anything concrete you can picture), consisting of
(a) a **signed asset inventory** covering data, models,
interfaces, infrastructure, and identities; (b) a **top-N
threat enumeration** of at least 10 threats drawn from
ATLAS + OWASP LLM/ML + sector sources + internal
intelligence, with current-posture ratings against the
hypothetical system; (c) a **cost-and-coverage matrix**
with three levels (minimum, full, beyond-full) per threat,
with honest engineering-week + compute-cost estimates and
dependency callouts; (d) a **release-gate requirements
pack** that would be installed as the engagement's exit
(policy-as-code rules, evidence artefacts, failure modes,
override roles); (e) an **engagement exit checklist**
instantiated for your system; and (f) a **short memo
(≤1 page) to the sponsor** that uses the matrix to
recommend a scope at a specific cost with named trade-offs.
**Prerequisites:** Chapter 02 read end-to-end. Familiarity
with ATLAS, OWASP LLM Top 10, OWASP ML Top 10. A chosen
hypothetical (or real) system. Working knowledge of the
mod-102 through mod-111 primitives referenced in the
chapter.

---

## Objective

Chapter 02's claim is that an ML-security engagement is
sized against a signed asset inventory, scoped against
a bounded top-N threat set, costed against a three-level
coverage matrix, and exits by installing release-gate
requirements — not by producing a memo. This exercise is
where you produce the artefact set for one concrete
system.

By the end of this exercise you have:

- An **asset inventory** that scopes the engagement.
- A **top-N threat enumeration** that is defensible
  against a sponsor's challenge.
- A **cost-and-coverage matrix** that gives the sponsor
  a real choice.
- A **release-gate requirements pack** that would
  install the engagement as a durable control, not a
  memo.
- An **exit checklist** that is signable.
- A **sponsor memo** that uses the matrix to make a
  recommendation.

You are **not** executing a 12-week engagement here;
you are producing the scoping artefacts the engagement
would execute against.

---

## Problem statement

Pick a plausible system up front and describe it in
three or four sentences:

- What it does.
- Who uses it.
- The data classes it touches (public / internal /
  confidential / restricted / PHI / PII / financial).
- The regulatory surface it sits on (EU AI Act high-
  risk? HIPAA covered? SR 11-7 model? SOC 2 scope?).

Then run the engagement scoping as if the sponsor had
just approved it.

If you work on a real ML system and have authorisation
to use it as the subject, do; the exercise is better
when it is grounded in reality. If you do not, use a
hypothetical with the properties above described in
enough detail to answer the exercise.

---

## Requirements

### Deliverable A — signed asset inventory

A YAML / JSON document matching the shape in chapter 02:

- `engagement_id` with a plausible identifier.
- `system`, `owner_team`.
- `asset_inventory.data[]` — at least two training
  datasets, one eval set, one runtime-input class,
  one retrieval corpus (if applicable), each with
  the full metadata (name, store, version,
  sensitivity, lineage pointer, owner).
- `asset_inventory.models[]` — the base model(s),
  any fine-tunes, any guardrail models.
- `asset_inventory.interfaces[]` — the inference
  endpoints, any tool integrations with tier /
  destination class, admin interfaces.
- `asset_inventory.infrastructure[]` — compute,
  secrets/keys, pipelines, platform services.
- `asset_inventory.identities[]` — human roles and
  workload identities.

Each asset's `sensitivity` is specified. The inventory
is accompanied by a signed provenance record (chapter
01 style) with a plausible signer-role and a date.

### Deliverable B — top-N threat enumeration

At least **10 threats** in a YAML document:

- Each with an id, one-line statement, ATLAS and
  OWASP mapping(s), affected-asset reference(s), and
  current-posture rating (covered / partial /
  uncovered).
- Drawn from at least three source classes (ATLAS,
  OWASP, sector intel or internal retrospectives).
- Ordered by a priority rationale that is explicit
  in the artefact ("ordered by cost-to-close against
  risk; mundane retrieval-provenance gap sits above
  exotic model-extraction attack because closure cost
  is lower and the exposure is live").
- The current-posture rating for each is argued, not
  asserted ("uncovered because the LLM gateway does
  not emit retrieval-provenance labels today; see
  INFRA-04").

### Deliverable C — cost-and-coverage matrix

A table (Markdown, YAML, or spreadsheet) with:

- One row per threat.
- One current-posture column.
- Three level columns: minimum / full / beyond-full.
- Each cell: a description of the control(s), the
  engineering-week estimate, any compute cost, any
  non-engineering cost (legal review time, SOC
  capacity, review-board time).
- Dependency callouts — threats sharing a control
  are flagged so cost is not double-counted.
- Columns for cumulative cost per level (so the
  sponsor sees the total of choosing "full across
  the top-5").
- A programme-lead recommendation column, with a
  reason, per threat.

Costs must be honest. If you do not know the
engineering-week estimate for a control, say so
rather than inventing a number. "Compute cost
unknown; needs ML-platform estimate" is a better
answer than a confident "$200k".

### Deliverable D — release-gate requirements pack

The engagement's exit, as a YAML artefact (chapter 02
shape):

- One entry per threat you are addressing at
  minimum-or-above coverage.
- Each entry: control-library ID (link to a
  plausible AISEC-* control, created in exercise 01
  if you did it, otherwise referenced), the policy-
  as-code rule's path + package, the required
  evidence, the failure mode (hard block / soft
  warning / advisory), the override role and
  constraints.
- Each entry's **evidence pipeline is marked live
  or planned**. A planned pipeline cannot support a
  hard-block requirement; address this honestly.

### Deliverable E — engagement exit checklist

The checklist from chapter 02, instantiated for your
system:

- Each item either checked (with evidence pointer)
  or explicitly deferred (with a scheduled
  follow-up).
- "Deferred" items have a named owner and a date.

### Deliverable F — sponsor memo (≤1 page)

A one-page memo to the sponsor using the matrix to
recommend a scope. The memo:

- States the system and the engagement objective in
  one paragraph.
- Names the top-3 threats you recommend closing to
  Full coverage; the ones you recommend closing to
  Minimum; the ones you recommend accepting with a
  decision record (chapter 03 shape).
- States the recommendation's total cost (engineer-
  weeks, compute dollars) and the coverage % against
  the top-N.
- Lists the three biggest risks of the recommended
  scope.
- Asks for the specific decision the sponsor needs
  to make (approve / escalate / request alternative).

The memo is **scannable in two minutes**. If the
sponsor cannot make the decision from the memo alone,
rework the memo.

---

## Starter guidance

- **Spend an hour on the inventory before writing a
  single threat.** The inventory shape determines
  what threats apply. A rushed inventory leaves
  threats floating.
- **Enumerate threats before costing.** Costing
  before you have the full top-N biases the matrix
  toward threats whose cost you already know.
- **Costs include the compute bill.** DP-SGD retrain
  is not an engineer-week; it is a compute
  commitment. Call this out.
- **The matrix is for a sponsor who has 15 minutes.**
  Three levels per threat; dependency callouts;
  cumulative totals. Not a 40-column spreadsheet.
- **Release-gate requirements are the engagement's
  memory.** If this engagement finishes and the
  release-gate requirements are not installed, the
  next engagement will re-discover the same
  threats. The pack is the durable artefact.
- **The exit checklist includes the follow-ups.**
  Deferred items are tracked, not forgotten.
- **The sponsor memo is written last.** The memo
  summarises; it does not drive the matrix.
- **Verify every ATLAS / OWASP ID.** Secondary
  summaries drift; cite primary pages.

---

## Acceptance criteria

A passing bundle:

- A signed asset inventory with every asset class
  populated.
- A top-N enumeration of ≥10 threats from ≥3 source
  classes, with current-posture ratings argued and
  priority rationale explicit.
- A cost-and-coverage matrix with three levels per
  threat, honest costs including compute, dependency
  callouts, and a recommendation column with
  reasons.
- A release-gate requirements pack with policy-as-
  code binding, evidence shapes, failure modes, and
  override roles.
- An exit checklist instantiated and signable.
- A sponsor memo ≤1 page that a sponsor could
  decide from.

A failing bundle:

- Inventory with "all AI" or similar unresolvable
  scope.
- Threat enumeration without ATLAS/OWASP mappings or
  with current-posture ratings not argued.
- Cost matrix with "TBD" costs in critical cells.
- Release-gate requirements pack where the hard-
  block requirements depend on evidence pipelines
  that do not yet exist.
- Memo >1 page.
- Memo that does not state a decision ask.

---

## Stretch goals

- **Multi-system engagement.** Scope the engagement
  against two systems whose owner teams share a
  platform. Show how the inventory, matrix, and
  release-gate requirements compose or diverge.
- **Compute cost grounded in a quote.** For the DP-
  SGD retrain line (or any compute-heavy line),
  produce an actual quote from an ML-platform
  engineer or a published benchmark; cite it.
- **Scope-change simulation.** Simulate a mid-
  engagement scope change (regulator imposes a new
  requirement, sponsor cuts budget by 40 %) and
  produce the updated artefacts.
- **Portfolio view.** Scope two engagements and show
  how the aggregate matrix feeds the metrics
  package (chapter 04).
- **Automation.** Build a small CLI that validates
  an inventory + threat enumeration + matrix
  against a schema and produces the sponsor-memo
  skeleton automatically.
- **Decision-record integration.** Attach the
  sponsor's decision as a chapter 03 decision
  record and show how it threads to the exit
  checklist.

---

## Do not

- Do not invent compute benchmarks ("DP-SGD costs
  $500k") without a source; if unknown, say so.
- Do not scope "the AI assistant" without an asset
  inventory; the inventory is the scope.
- Do not deliver release-gate requirements whose
  policy rules exist only as prose; they bind to
  real code, or they are planned.
- Do not fold three threats into one for the matrix;
  distinct threats merit distinct rows.
- Do not deliver a sponsor memo >1 page.
- Do not commit the solution bundle to this repo.
  Solutions live in the paired `-solutions` repo.
