# Exercise 01 — NIST AI RMF Sub-Category to Control Map

**Estimated effort:** ~3 hours
**Deliverable:** The **v0.1 unified control matrix** for one
in-scope ML system. A single structured file (YAML preferred,
or a markdown table backed by YAML fragments) containing at
least **twenty NIST AI RMF sub-categories** translated into
`outcome / control / evidence` triples, each one owned, each
one pointing at a concrete artefact that already exists or is
explicitly on the backlog. Stubbed columns for ISO 42001, EU
AI Act, SOC 2, sector-reg and tier-policy cross-references so
exercises 02–05 can extend without reshaping.
**Prerequisites:** Chapter 01 read end-to-end. Access to one
real production or staging ML system — its model card, risk
register (or whatever the org has in place of one), service
registry entry, and the eval-plan if there is one. If no
real system is available, pick one of the chapter's running
examples (`prod-cv-screener`, `prod-recsys`, or a documented
internal assistant) and treat its artefact set as hypothetical
but internally consistent.

---

## Objective

Chapter 01's claim is that **a sub-category without a named
control and a named evidence artefact is a slogan, not a
control**. This exercise converts that claim into the matrix
the rest of this module (and the rest of the org's governance
programme) extends.

By the end of this exercise you have:

- **One scoped system** named, with a one-paragraph system
  description — intended use, data classes, deployment
  environment, in-scope regulatory regimes (even if the
  regime columns stay stubbed in this exercise).
- **At least 20 sub-category rows** spanning all four
  functions (GOVERN / MAP / MEASURE / MANAGE) — not twenty
  rows from GOVERN alone.
- **At least three rows drawn from the AI 600-1 Generative
  AI Profile** if the target system is generative; otherwise
  three rows that extend "traditional-ML" sub-categories
  with the generative-specific overlay the org would need
  if it adopted a GenAI system next.
- A **matrix schema** that is machine-parseable (so chapter
  04's OPA policies can load `data.controls` from it in a
  later exercise), with per-row fields consistent across the
  twenty rows.
- A **gap list** — the sub-categories you considered but
  cannot evidence today, with the artefact that would close
  the gap and a provisional owner.

You are **not** writing policy, running a certification
rehearsal, or performing an audit. You are producing the
inventory that every subsequent exercise in this module
walks across and extends.

---

## Problem statement

Pick one target system. Candidates (and the reason each is
useful for the exercise):

- **A production classical-ML system** (fraud scorer, churn
  model, demand forecaster). Easiest for the MEASURE
  function — the metrics already exist — but forces you to
  invent GOVERN rows if the org has not previously treated
  it as "AI".
- **A production LLM / assistant** (customer-support bot,
  internal knowledge agent). Forces you to use the AI 600-1
  Generative AI Profile for the GOVERN and MAP overlays.
- **A high-risk candidate** (CV screener; credit-decision
  support; medical-triage prototype). Lines up directly with
  the Article 9 risk-management file (exercise 03) and the
  SR 11-7 model inventory (exercise 05).
- **A platform-level system** (shared feature store;
  model-registry service; training-platform). GOVERN-heavy;
  gives you practice with cross-system controls.

Whichever you pick, state before you start:

- The system's purpose in one sentence.
- The data classes it uses (public / internal / personal /
  special-category / regulated-sector).
- Where it runs (prod, staging, developer sandbox) and which
  tenants it serves.
- Which regimes you believe apply (NIST AI RMF is always on;
  which others — ISO 42001, EU AI Act tier, SOC 2, HIPAA,
  SR 11-7, FDA GMLP — are "yes, apply" vs "maybe" vs "no").
  These will be refined in later exercises; this is the
  starting hypothesis.

If the picked system cannot answer those four questions
cleanly, pick a different one or add the gap to the system
description. A matrix row keyed to an under-described system
is a row no auditor can verify.

---

## Requirements

### Deliverable A — scope statement (half a page)

A short Markdown document at the top of the matrix file (or
in `scope.md` referenced from the matrix) that states:

1. **System name and version** (or "pre-launch" if not yet
   deployed).
2. **Intended use** — one paragraph; who the system serves
   and what decision or output it drives.
3. **Out-of-scope uses** — one paragraph; the use cases the
   model card declares off-limits (or that you are declaring
   off-limits as part of this exercise).
4. **Data classification** — the classes of data in
   training, inference input, and inference output; cite
   the org's data-class taxonomy if one exists, or the
   mod-108 chapter 01 starter tier map.
5. **Regulatory-scope hypothesis** — the regimes you think
   apply. State confidence: "yes, apply", "likely", "to
   confirm".
6. **System boundary** — what is in scope (the model + its
   training pipeline + its serving plane) and what is out
   (the upstream data producer; the downstream consumer
   application).

### Deliverable B — the matrix (≥ 20 rows)

A single file (YAML preferred for machine-parseability — see
example schema below) with one row per sub-category.

Required functional coverage across the twenty rows:

- **≥ 5 GOVERN sub-categories.** Including at least GV-1.1
  (regulatory scope), GV-2.1 (RACI), GV-5.1 (AI/ML policy),
  GV-6.1 (third-party / supplier posture), and one GOVERN
  row that is specifically **generative-AI-flavoured** if
  the target system is generative — e.g. GV-1.3.001 (GAI
  policy addendum) or GV-4.1.001 (downstream-harm reporting
  channel).
- **≥ 5 MAP sub-categories.** Including at least MP-1.1
  (intended use + out-of-scope), MP-4.1 (threat model with
  AI-specific categories), MP-5.1 (risk register with
  inherent / residual scoring), and one MAP row that
  surfaces a *dual-use* consideration if the system is
  generative or agentic (MP-3.4.001).
- **≥ 5 MEASURE sub-categories.** Including at least MS-1.1
  (eval plan), MS-2.1 (test-set reproducibility), MS-2.7
  (robustness / adversarial evaluation), and one row that
  measures a **privacy** property (e.g. the mod-108 chapter
  02 MI-AUC monitor).
- **≥ 5 MANAGE sub-categories.** Including at least MG-1.1
  (risk-based prioritisation), MG-2.3 (incident response
  for AI-specific incidents), MG-4.1 (continual improvement
  and lessons-learned loop), and one row that enforces a
  **capability-disable** / tier-step-down (chapter 06
  analogue of MG-2.4.001).

### Deliverable C — per-row schema

Each row carries at minimum:

```yaml
- sub_category: GV-1.1
  function: GOVERN                     # GOVERN / MAP / MEASURE / MANAGE
  outcome: >                           # the AI RMF sub-category outcome, paraphrased
    Legal and regulatory requirements involving AI are
    understood, managed, and documented.
  control:
    what: >
      Per-system regulatory-scope register naming every
      regime (GDPR, HIPAA, EU AI Act tier, SOC 2, SR 11-7,
      FDA GMLP, sector-specific) and contractual obligation
      (DPAs, BAAs).
    where:
      - service-registry annotation `regulatory_scope`
      - governance/scope-register.yaml
    owner: role:dpo                    # a role, not a person
  evidence:
    artefact_type: register            # register / policy / eval-report / runbook / signed-record
    artefact_pointer: >
      governance/scope-register.yaml referenced from
      the model card
    verification: >
      CI job fails if `regulatory_scope` annotation is
      missing on any production-tier service; DPO signs
      quarterly review record.
    produced_by: platform              # engineer / platform / review-board
    retention: 7 years
  cross_refs:
    iso_42001: null                    # filled in exercise 02
    eu_ai_act: null                    # filled in exercise 03
    soc2: null                         # filled in exercise 05
    sector: null                       # filled in exercise 05
    deployment_tier: null              # filled in exercise 05
  status: implemented                  # implemented / partial / planned / gap
  gap_note: null
  last_reviewed: 2026-10-04
```

Rules the schema enforces:

- **`owner` is a role**, not a person. "Alice" moves teams;
  "role:ml-security-lead" does not. If the row cannot be
  owned by a role the org has defined, the row's `status`
  must be `planned` or `gap`.
- **`artefact_pointer` is a path**, not a sentence. "In the
  model card" is not an artefact pointer; `models/prod-cv-
  screener/3.4.2/card.yaml#risk_management` is.
- **`verification` is checkable**. Either an automated
  check runs (CI, admission gate, monitoring query) or a
  human review runs on a stated cadence with a stated
  reviewer role. Rows that say "we check this when we think
  of it" are gaps dressed up as controls.
- **`status: implemented`** requires that the artefact exists
  *right now* and the verification has run at least once in
  the retention window. Everything else is `partial`,
  `planned`, or `gap`.
- **`cross_refs`** are stubbed to `null` for now; later
  exercises populate them. Keep the keys present so
  downstream schema validators do not re-key the file.

### Deliverable D — generative-AI delta (if applicable)

If the system is generative or agentic, add a sub-section at
the end of the matrix file titled **"AI 600-1 overlay"**
listing the rows you drew from the Generative AI Profile and
what makes them different from the base sub-category. Each
overlay row names:

- The base sub-category it extends (e.g. GV-1.3 extended to
  GV-1.3.001 by GAI).
- What the overlay adds — new risk, new control type, or new
  evidence requirement.
- The chapter 06 tier at which the overlay row becomes
  binding (Tier 1 and above? Tier 3 and above?). Flag that
  the tier mapping is provisional until exercise 05.

If the system is not generative, add a one-paragraph note
stating what the overlay would add *if* the org adopted a
GenAI assistant for this use case next. This is the
chapter 01 "the AI 600-1 is a delta, not a separate
framework" claim made concrete.

### Deliverable E — gap list

A separate section (or a filter on the matrix: `status in
[partial, planned, gap]`) listing every sub-category you
considered but could not implement today. For each gap:

- The sub-category.
- The missing artefact.
- The provisional owner.
- The order-of-magnitude effort (hours / days / weeks).
- Whether the gap blocks any downstream exercise or regime
  (e.g. a missing eval-plan artefact blocks the Article 15
  accuracy/robustness report in exercise 03).

The gap list is the input to exercise 02's internal-audit
programme and exercise 05's accepted-risk register. Write it
so the next exercise can lift it verbatim.

### Deliverable F — matrix validator script (optional but
recommended)

A short script (Python or `rego` is fine; `jq` works too)
that reads the matrix file and asserts:

- Every row has all required fields.
- Every row's `owner` matches a role from a stated role
  catalogue (even a stub list is enough).
- Every row's `artefact_pointer` is a path or URL, not a
  sentence.
- No two rows share the same `sub_category` value.
- Function coverage satisfies the ≥ 5 rule per function.

Commit the validator alongside the matrix. If the validator
is skipped, state in the deliverable notes why (and plan to
add it in exercise 04 as part of the policy pack).

---

## Starter guidance

- **Start with GOVERN 1.1.** It is the only row where every
  org has data (the regulatory landscape). Writing it first
  forces you to state the regime hypothesis cleanly, which
  the rest of the module reuses.
- **Walk the system card first, matrix second.** The MAP
  rows (intended use, known limitations, risk register) are
  essentially the model card restructured. If the model card
  is sparse, writing the matrix will tell you where to
  invest.
- **Use the chapter 01 sub-category snippets as templates.**
  The chapter's `GV-1.1`, `MP-1.1`, `MS-1.1`, `MG-2.3`
  worked examples are directly reusable for your matrix.
  Don't copy them verbatim — adapt them to the target
  system's specifics — but reuse the shape.
- **Pick the five MANAGE rows carefully.** MANAGE is the
  function orgs most often fake. "We have an incident
  runbook" is easy to say; the row's `verification` field
  — "the runbook has been exercised in the last N months
  with a dated record" — is where the posture is actually
  tested. If you cannot name the exercise record, mark the
  row `partial`.
- **State what you excluded.** The matrix is twenty rows,
  not all seventy-two sub-categories. Add a trailing
  `excluded.md` or an in-file list naming the sub-categories
  you deliberately did not include (not applicable to the
  system, duplicate of another row, deferred to another
  module). An auditor who sees twenty rows asks "where are
  the other fifty-two?"; have the answer.

---

## Acceptance criteria

A passing matrix:

- Covers ≥ 20 sub-categories, ≥ 5 per function, with the
  specific rows listed under Deliverable B present (or
  justified exclusion documented).
- Every row has owner, artefact pointer, verification
  method, cross-ref stubs, status, and last-reviewed date.
- Every `implemented` row's artefact pointer resolves to a
  file / path / URL that the reviewer can open.
- The scope statement names the system, intended use,
  out-of-scope use, data classes, and regulatory-scope
  hypothesis.
- The gap list exists and names at least three gaps (any
  twenty-row matrix of a real system has gaps; a gap list
  of zero is itself a gap).
- The AI 600-1 overlay section is present either as live
  overlay rows (generative system) or a note (non-
  generative system) stating the overlay would add.
- The matrix file is machine-parseable — a reviewer can run
  the Deliverable F validator (or `yq` / `jq`) and the file
  loads cleanly.

A failing matrix:

- Rows citing frameworks instead of artefacts — "we comply
  with GOVERN 1.1" with no `artefact_pointer`.
- `owner` fields naming a person rather than a role.
- `verification` fields reading "the team reviews this
  periodically" with no cadence and no reviewer role.
- A single-function matrix (all GOVERN; nothing in MEASURE
  or MANAGE) — the point of the four functions is coverage.
- `cross_refs` keys deleted or renamed — later exercises
  cannot populate them if they are gone.
- A gap list of zero on a real system with any history.

---

## Stretch goals

- **Twenty-row → fifty-row extension.** Walk the remainder
  of the AI RMF sub-categories and classify each as
  "applies, implemented", "applies, gap", "not applicable
  (justify)". Produces a full-coverage matrix the org can
  present to a customer asking "which sub-categories do you
  address?".
- **Multi-system matrix.** Extend the schema with a
  `system` key per row and add rows for a second system.
  Produces the per-system column vs cross-system row
  distinction that chapter 02's Statement of Applicability
  (exercise 02) formalises.
- **Evidence-freshness report.** Script that walks the
  matrix and reports, per row, the age of the artefact
  pointed at (last-modified of the file; last run of the
  CI check; last signature on the review record). Rows
  older than their stated review cadence are flagged.
  This is the "operational" vs "paper" distinction
  chapter 02 Clause 9.1 asks for.
- **GOVERN 1.2 trustworthiness-characteristic walk.** Add
  a per-system view that enumerates the seven AI RMF
  trustworthiness characteristics (valid & reliable; safe;
  secure & resilient; accountable & transparent; explainable
  & interpretable; privacy-enhanced; fair with harmful bias
  managed) and names the matrix row(s) backing each. Produces
  the per-characteristic answer to "how does your system
  address *X*?"
- **GenAI red-flag scan.** For each GOVERN row, note any
  AI 600-1 risk the row does not currently address
  (confabulation; data leakage; dual-use; copyright) and
  the row that would. Useful whether or not the current
  system is generative.
- **Role-catalogue stub.** Produce a one-page role catalogue
  (ML Governance Lead, ML Security Lead, Product Owner,
  DPO, Model Risk Officer, Clinical SME, Credit SME,
  Review Board Chair, Executive Sponsor) and reference it
  from every row's `owner`. The catalogue is the input to
  chapter 02 Clause 5.3 (exercise 02) and chapter 05 SR
  11-7's three-pillar structure.

---

## Do not

- Do not merge the matrix into main until it has been read
  by a role other than its author. The matrix is a
  governance artefact; single-author governance artefacts
  are an anti-pattern.
- Do not mark rows `implemented` to clear the gap list.
  `partial` is a legitimate status; `gap` is a legitimate
  status; `implemented without evidence` is not.
- Do not conflate sub-categories. "MP-5.1 and MG-1.1 are
  basically the same" is wrong — one is identifying and
  scoring; the other is prioritising and acting. Keep them
  as separate rows.
- Do not add bespoke sub-category IDs. If the system needs a
  control the AI RMF does not mention, add it as a
  `custom.*` row and flag it; do not invent a GV-10 that
  does not exist.
- Do not quote the AI RMF sub-category wording verbatim as
  the `outcome` field. Paraphrase so the row is readable
  without a sidebar; the primary-source quote lives in the
  resources file and the auditor's own copy.
- Do not commit the solution matrix (filled-in exercises)
  to this repo. Solutions live in the paired `-solutions`
  repo.
