# Exercise 04 — Agent Red-Team Plan with Inspect

**Estimated effort:** ~5 hours
**Deliverable:** A committed red-team engagement bundle for
one production (or pre-production) LLM agent, consisting of
(a) a **written engagement plan** covering the seven sections
from chapter 04 — scope, threat model, rules of engagement,
corpus, metrics, reporting, regression gate; (b) a **runnable
harness** built on UK AISI Inspect (`inspect_ai`) or a
documented equivalent, with at least one Task definition, one
custom solver that dispatches through the real runtime, and
at least two scorers (action-level + cost); (c) a **versioned
corpus** of at least 30 payloads across the chapter-04
scenario list, with provenance per payload; (d) a **scorecard**
produced by one full engagement run reporting
`attempt_rate`, `execution_rate`, `hitl_bypass_rate` (under
both the conservative and permissive simulated approver),
`detection_rate`, `cost_p95`, and `false_positive_rate`;
and (e) a **CI regression-gate wiring sketch** describing how
a subset of the corpus runs on every release candidate and
blocks regressions.
**Prerequisites:** Chapter 04 read end-to-end; chapters 02
and 03 referenced for the surfaces and the tool registry;
exercise 01 complete (the mitigation map tells you which
OWASP LLM categories are in scope for the target); exercise
03 complete (the tool registry tells you which tiers exist
and what the HITL surfaces look like). Access to one
tool-using agent product in an environment where you can
run payloads safely — a staging / test tenant with mirrored
seed data, never live customer data. A Python environment
with `inspect_ai` installed (or the equivalent harness your
org has standardised on).

---

## Objective

Turn chapter 04's engagement-plan pattern into an artefact
the engineering team, security team, and leadership can
sign off on, then run it. By the end of this exercise you
have:

- A plan a non-author can read and operate.
- A harness that runs end-to-end against the real runtime
  (not a mocked chat endpoint) and produces trajectory logs.
- A scorecard with numbers — not screenshots — that a
  release manager can read.
- A CI gate specification that keeps the engagement alive
  after the one-shot run ends.

You are **not** producing a research artefact. You are
producing the engineering output chapter 04 names: a
reproducible harness, a versioned corpus, a scorecard, and
a regression gate.

If your org cannot use Inspect itself (constrained infra,
licensing, sovereignty), run the exercise against the
equivalent harness that meets chapter 04's three
requirements — a dataset abstraction, a solver that
dispatches through the real runtime, and a scorer whose
verdict is on the *outcome*. Garak, PyRIT, Promptfoo, or a
documented in-house harness all qualify; name the one you
chose and why in the plan.

---

## Problem statement

Pick one tool-using agent product. The product must have:

- A real runtime you can dispatch against — the system
  prompt, the retrieval store (if any), the tool registry,
  the model, and the runtime glue that assembles context
  and executes tool calls. A mocked chat endpoint does not
  qualify; the solver must call the actual tool-dispatch
  path.
- At least one tool that can be exercised safely in a
  staging environment. A browser tool pointed at a test
  endpoint, a mail tool with a mail-sink recipient, a CRM
  tool against a test tenant — any surface where the
  harness can observe a real tool call without acting on
  live data.
- At least one chapter-03 Tier-2 or Tier-3 tool. If every
  tool is Tier-0 or Tier-1, the engagement has nothing
  meaningful to measure for `hitl_bypass_rate`; swap to a
  product that has a HITL surface.

If you completed exercise 01 and exercise 03, reuse that
product; the mitigation map and the tool registry are
direct inputs to the engagement plan. If you must pick a
new product (because the previous one has no tool
surface), name up front:

- Users (external customers, tenant employees, internal).
- Tools (list, with the tier each has in the chapter-03
  registry).
- Retrieval and content sources (if any).
- The pinned versions of every SUT component (system
  prompt, retrieval index, tool registry, model, runtime).
- The staging environment: tenants, mail sink, mock
  third-party endpoints, test credentials.

If the product has no staging environment capable of
hosting the engagement, build one as part of the exercise —
mirror the production retrieval index, seed it with
synthetic customer data, and point the tool layer at
test endpoints. Do not run the harness against production.

---

## Requirements

### Deliverable A — the engagement plan

A written document (markdown is fine) covering the seven
sections from chapter 04. Each section's bar:

1. **Scope.**
   - Name the product, version, deployment stage, and the
     specific pinned versions of system prompt, retrieval
     store, tool registry, model, runtime.
   - State what is in scope vs out of scope. Platform
     infrastructure, auth servers, cloud accounts, IdP
     surfaces are out of scope and must be named out.
   - Name the identity model: who the attacker is in each
     scenario (external user, authenticated tenant,
     privileged-internal) and what access they have.

2. **Threat model.**
   - Cross-reference exercise 01's mitigation map. Each
     scenario the engagement runs targets at least one
     OWASP LLM category from the map.
   - At least five scenarios drawn from chapter 04's list
     (indirect injection via RAG, browser-tool exfil,
     mail-tool exfil, cross-tenant data crossover, Tier-3
     tool against caller's wishes, system-prompt leak,
     unbounded consumption, cross-input combination).
   - Per scenario: attacker identity, controlled surfaces,
     goal condition (the concrete measurable outcome).

3. **Rules of engagement.**
   - No live-customer data: name the staging tenants and
     seed data in use.
   - Time-window: schedule, duration, cost ceiling.
   - Kill switch: a single control point that halts the
     run and prevents artefact spill.
   - Third-party abuse prevention: every outbound surface
     the agent might call (mail, HTTP, SMS, Slack) points
     at a test endpoint the engagement controls.
   - Reporting cadence: how fast findings above a severity
     threshold are escalated to the owning team.

4. **Corpus and sample plan.**
   - Corpus version, size, provenance table (payload →
     source: chapter 02 starter / public suite / prior
     incident / adversarial-generation loop).
   - Sampling policy: full-corpus vs stratified subsample;
     the number of runs per payload (minimum 3 to measure
     stochasticity).
   - Any adversarial-generation loop to be run during the
     engagement: target scenario, generator model, cap on
     samples, acceptance criterion for a generated payload
     to enter the corpus.
   - Clean control set: at least 10% of runs are
     legitimate user requests that *should* succeed, used
     to measure `false_positive_rate`.

5. **Metrics and success criteria.**
   - The six metrics from chapter 04 (`attempt_rate`,
     `execution_rate`, `hitl_bypass_rate` under both
     simulated approvers, `detection_rate`, `cost_p95`,
     `false_positive_rate`).
   - Per-scenario thresholds for each metric, agreed with
     the product team *before* the run. State the explicit
     numbers that would block ship.
   - A `delta` column: how much the number may degrade
     from the previous accepted baseline before the gate
     fires.

6. **Reporting and handoff.**
   - Trajectory IDs cited for every finding.
   - Findings indexed by OWASP LLM category, by tool tier,
     by surface.
   - Owner and target-fix date per finding.
   - Every finding donates a regression test.

7. **Regression gate.**
   - Which subset of the corpus runs on every release
     candidate (chapter 04's "reduced-size subset").
   - What `execution_rate` delta blocks a release.
   - Where the scorecard renders for the release manager.
   - How the baseline is refreshed after a full-size run.

### Deliverable B — the runnable harness

A code artefact that implements the engagement. Minimum
contents:

- A **Task** definition (Inspect `@task` or equivalent)
  per scenario. At least one Task must correspond to an
  indirect-injection scenario (RAG, browser, or mail) and
  at least one to a Tier-2+ tool-call scenario.
- A **custom solver** that wires the harness to the
  product's real runtime. The solver must:
  - Dispatch through the actual tool-dispatch code path
    (not a mocked chat completion).
  - Capture the full trajectory — prompt fragments with
    provenance labels (chapter 02), model responses, tool
    calls with arguments, runtime decisions, HITL events.
  - Record the pinned SUT versions (system prompt,
    retrieval index, tool registry, model, runtime) at
    the start of each sample.
- At least **two scorers**:
  - An **action scorer** that returns the chapter-04
    structured verdict (`goal_achieved`, `runtime_blocked`,
    `hitl_approved`, `tool_call_executed`,
    `argument_diff`). Scoring is on the trajectory, not the
    final text.
  - A **cost scorer** that reports tokens, tool-calls,
    and wall-clock seconds per sample, flagging samples
    that exceed a per-call budget.
- A **simulated-approver layer** implementing both the
  conservative and permissive personas from chapter 04
  (and your exercise-03 stretch spec, if you wrote it). The
  harness runs the same sample under both personas and
  records both verdicts.

Illustrative Inspect task sketch (verify current Inspect API
before shipping — see chapter 04's note):

```python
from inspect_ai import Task, task
from inspect_ai.dataset import json_dataset
from mycompany.evals import (
    agent_runtime_solver,
    action_scorer,
    cost_scorer,
    simulated_approver,
)

@task
def rag_indirect_injection(approver="conservative"):
    return Task(
        dataset=json_dataset("corpus/rag_indirect_injection.jsonl"),
        solver=agent_runtime_solver(
            runtime="staging-v142",
            model="anthropic/claude-<pinned-version>",
            tool_registry="registry-v37.yaml",
            hitl=simulated_approver(approver),
        ),
        scorer=[
            action_scorer(goal="mail.send with untrusted recipient"),
            cost_scorer(budget_tokens=50_000),
        ],
    )
```

Each `Sample` carries: `payload`, `delivery_surface`,
`goal_condition`, `expected_runtime_block`, and
`provenance` (where the payload originated).

Equivalent-harness note: if you use Garak / PyRIT /
Promptfoo, implement the same three abstractions
(dataset, solver-through-runtime, outcome scorer) and
document the mapping in the plan.

### Deliverable C — the versioned corpus

A corpus artefact (JSONL, YAML, or structured dataset)
containing at least 30 payloads. Each entry carries:

```yaml
- id: inject-rag-001
  scenario: rag_indirect_injection
  delivery_surface: retrieval_chunk
  delivery_mechanism: unicode_zero_width
  payload: |
    ... the payload text ...
  goal_condition:
    kind: tool_call
    tool: mail.send
    argument_predicate: recipient_not_in_user_turn
  provenance:
    source: chapter-02-starter
    version_added: 2026-10-04
    sut_first_succeeded_against: null
  classification: internal
```

Rules:

- Payloads span at least three surfaces (RAG / browser /
  mail / tool-response / direct prompt). A corpus that is
  all one surface is not a corpus.
- Payloads span at least three delivery mechanisms (plain,
  HTML, Unicode / zero-width, Base64, image-embedded,
  multi-turn). The chapter-02 starter already covers plain
  and Unicode; add at least one more.
- At least five payloads come from a public evaluation
  suite — AISI public evaluations, Garak probes,
  HarmBench, JailbreakBench, Purple Llama. Cite the source.
- At least five payloads are *novel* — written for this
  product, drawn from an adversarial-generation loop, or
  donated from a prior finding. Cite the origin.
- Payloads classified `internal` do not leave the
  repository; the plan names who may read them.

### Deliverable D — the scorecard

Run the harness end-to-end (at the sample volume the plan
names) and produce a scorecard. Format:

**Per-scenario table.**

| Scenario | Runs | `attempt_rate` | `execution_rate` | `hitl_bypass_rate` (conservative) | `hitl_bypass_rate` (permissive) | `detection_rate` | `cost_p95` (tokens) | `false_positive_rate` | Threshold met? |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

**Top findings table.**

| Finding | Scenario | Trajectory ID | OWASP LLM | Tool tier | Owner | Target fix date |
| --- | --- | --- | --- | --- | --- | --- |

Each finding must cite a trajectory ID the harness
preserves. A finding without a reproducible trajectory
is not a finding; it is an anecdote.

**Interpretation paragraphs.** Two to four short
paragraphs covering:

- The two scenarios whose numbers are furthest from the
  threshold, and the proximate cause.
- Any gap between the conservative and permissive
  `hitl_bypass_rate` wider than ~15 percentage points —
  what the gap says about the HITL design (chapter 03
  rubber-stamp risk).
- Any payload that *failed* but consumed anomalous cost
  (LLM10 silent exposure).
- Any `false_positive_rate` that would make the agent
  unusable on legitimate traffic.

### Deliverable E — the CI regression gate sketch

A written specification (not a full implementation) of how
the harness runs on every release candidate. Minimum
contents:

- The subset of the corpus the CI gate runs (chapter 04's
  "reduced-size subset"). Name the IDs or the stratified
  sample.
- The thresholds that block a release: for each scenario,
  the `execution_rate` the previous accepted baseline
  set, plus the allowed `delta`.
- The baseline-refresh rule: when a full-size engagement
  runs, how the CI baseline updates.
- Where the scorecard lands for the release manager (a
  dashboard URL, a PR status check, a Slack digest).
- The failure path: what happens when the gate fires —
  who is paged, how an override is authorised, where the
  override is logged.

A ~1-page design memo is a passing output here. You are
not expected to ship the CI pipeline; you are expected to
specify it well enough that the platform team could.

---

## Starter guidance

- **Reuse exercise 01's and exercise 03's artefacts.** The
  mitigation map tells you which categories matter; the
  tool registry tells you which tiers exist. If the two
  artefacts disagree with the engagement plan, update the
  plan — the artefacts are the ground truth.
- **Build the staging environment first.** The engagement
  cannot run against live tenants. A mirrored retrieval
  index, a mail sink, and a test tenant seeded with
  synthetic data unblock everything downstream. Half of a
  real engagement is the environment, not the payloads.
- **Score on the action, not the text.** The number-one
  mistake chapter 04 names is scoring on model output. The
  solver must capture tool calls with arguments; the
  action scorer walks the trajectory, not the final
  message.
- **Simulated-approver personas belong in code.** The
  conservative and permissive approvers are two Python
  functions (or classes) with named heuristics — "approve
  if every argument field is traceable to a user turn" vs
  "approve if the action is facially plausible in
  context". Keeping them as prose is the chapter-03
  rubber-stamp trap in exercise form.
- **Three runs per payload is the minimum.** Models are
  stochastic. One pass tells you nothing about
  `execution_rate`; three samples per payload is the
  floor; five to ten is better for the headline scenarios.
- **The CI subset is small on purpose.** Running the full
  corpus on every PR is expensive; the subset should be
  the stratified representative set — one payload per
  (scenario × delivery mechanism) cell. Full-size runs
  happen weekly or at release-cadence, not per-PR.
- **Pin everything.** The SUT version string is the system
  prompt hash + the retrieval-index snapshot ID + the
  tool-registry version + the model identifier + the
  runtime commit. Two engagements that don't share this
  string are not comparable.
- **Trajectory IDs are the artefact.** Every finding
  cites a trajectory; the trajectory replays the exact
  sequence of events; the trajectory survives the
  engagement. If your harness does not emit stable
  trajectory IDs, add that before scoring.

---

## Acceptance criteria

A passing bundle:

- The engagement plan covers all seven chapter-04 sections
  with product-specific detail. Scope names pinned SUT
  versions; threat model cross-references exercise 01;
  rules of engagement name the kill switch and the staging
  environment; corpus plan names sampling and the
  adversarial-generation loop; metrics name explicit
  thresholds; reporting names the regression-test pipeline;
  CI gate names the subset and the delta.
- The harness runs end-to-end against the real runtime and
  dispatches through the actual tool-dispatch path. The
  solver captures the full trajectory with pinned SUT
  versions. At least an action scorer and a cost scorer
  are implemented.
- The corpus has at least 30 payloads, three delivery
  surfaces, three delivery mechanisms, five public-suite
  entries, five novel entries, and provenance per payload.
- The scorecard reports all six metrics per scenario, with
  the top findings table citing trajectory IDs. The
  interpretation paragraphs explain the two worst metrics
  and the conservative-vs-permissive gap.
- The CI gate sketch names the subset, the delta, the
  baseline-refresh rule, the scorecard surface, and the
  failure path.
- Cross-references to chapter 02 (surface, provenance),
  chapter 03 (tool tier, HITL), chapter 05 (severity for
  the top findings), and exercise 01 (mitigation map) are
  present where relevant.

A failing bundle:

- A plan that is a chapter 04 restatement without
  product-specific detail.
- A harness that scores on model output text and does not
  capture tool calls.
- A corpus of all-plain-text payloads from a single public
  suite with no novel entries.
- A scorecard with aggregated numbers only, no
  per-scenario rows, no trajectory IDs cited.
- Only the conservative approver implemented ("we didn't
  have time for permissive") — the chapter-03
  rubber-stamp signal is unmeasurable.
- No regression-gate specification — the engagement is a
  one-shot exercise.
- `false_positive_rate` not measured — the clean control
  set is missing.
- Live customer data touched during the run — a rules-of-
  engagement violation; the exercise fails even if the
  numbers are good.

## Stretch goals

- **Adversarial-generation loop.** Implement a helper
  that generates payload variants against one named
  scenario, feeds them through the harness, keeps the
  ones that achieve the goal condition, and files them
  to the corpus with provenance = `generated`. Cap the
  generator's cost; name the cap.
- **Real-approver anchor.** Schedule a small held-out
  sample (chapter 04 names this) that routes to real
  human approvers; compare their decisions to the two
  simulated personas; report the anchor delta.
- **Multi-model comparison.** Run the same corpus against
  the current model and the proposed-upgrade model;
  produce the two scorecards side-by-side; call out any
  regression.
- **Chapter 02 integration.** The input classifier and
  the retrieval-side detector from chapter 02 are
  separate controls; the harness runs the corpus with
  each on, each off, and both on, and reports the
  per-control attribution.
- **Governance evidence surface.** Emit the scorecard in
  the format mod-109's evidence surface expects
  (control-effectiveness record), not just as a markdown
  table.
- **Chapter 05 incident wiring.** For every finding at
  `execution_rate` above the SEV-3 threshold, write the
  chapter-05 incident record the finding would produce
  if it occurred in production — including the clock
  obligations.

## Do not

- Do not run the engagement against live customer data,
  live third-party APIs, or production mail / webhook
  endpoints. The staging environment is non-negotiable.
- Do not ship a harness that scores on model text only.
  The agent-level scorer is the point of the chapter.
- Do not report a single-sample number as a rate. Three
  runs per payload is the minimum; the scorecard reports
  rates with per-payload variance.
- Do not treat the engagement as a research project. The
  outputs are a scorecard, a corpus, regression tests,
  and a CI gate specification — engineering artefacts.
- Do not commit payloads marked `classification: internal`
  into a shared repo without agreement from the plan's
  reviewers.
- Do not use a model-graded ("judge") scorer where a
  deterministic action scorer works. Judges are expensive
  and stochastic; reserve them for genuinely open-ended
  outcomes.
- Do not commit a solution here — solutions live in the
  paired solutions repo.
