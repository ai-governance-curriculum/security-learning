# Chapter 04 — Agent Red-Teaming with UK AISI Inspect

> **Note on AI-assisted content.** UK AISI's Inspect framework
> (`inspect_ai`) is under active development; its solver, scorer,
> tool, and dataset APIs shift between releases. This chapter is
> written against the durable engagement-plan pattern, not against
> a specific Inspect version. Verify the current Inspect API and
> the current UK AISI evaluation guidance before implementing.
> See [`resources.md`](./resources.md).

---

## Why this chapter exists

Chapters 01–03 built the *prevention* stack: a category-by-
category mitigation map, a trust-boundary primitive for indirect
injection, tiered tool ACLs with HITL gates. None of that
survives contact with a determined adversary unless the
prevention stack has been *tested* by one.

Red-teaming an LLM agent is not the same as red-teaming a
website. It is not the same as red-teaming a model in
isolation. It is not the same as running a static jailbreak
benchmark. Red-teaming a production agent means:

- Attacks are **stochastic** — the same payload succeeds on
  Monday and fails on Tuesday; the metric is a *rate*, not a
  pass/fail.
- The system under test includes the model, the runtime, the
  tools, the retrieval store, and the humans in the loop.
- The interesting outcomes are not "the model said something
  bad" — they are "the tool executed something bad", "the
  data was exfiltrated through a tool call", "the human
  clicked approve on an injected action".
- The engagement must be **reproducible** — a passing red-
  team run in April must be re-runnable in October against a
  new model or new runtime, and produce comparable numbers.

The specific failure mode this chapter is written to prevent:

> A red-team exercise runs against the pre-release agent; the
> report says "we tried 40 prompts; the agent refused 38, we
> found 2 vulnerabilities; ship it." The 2 findings are
> patched. Two weeks post-launch, an attacker submits a novel
> variant of one of the patched payloads and succeeds — the
> patch was payload-specific, and the exercise never measured
> the *class*. The post-mortem asks the same question the
> exercise asked; nobody can compare April's numbers to
> October's because the harness is gone.
>
> The other failure mode: a red-team engagement that never
> finishes because "we found something interesting; we're
> exploring." A month later the release slips; the report is
> qualitative anecdotes; the engineering team argues each
> finding on its merits. Reproducible metrics are the
> alternative.

You leave this chapter able to:

- Write an **engagement plan** for red-teaming a production
  LLM agent: scope, threat model, corpus, harness, metrics,
  reporting, and rules of engagement.
- Use **UK AISI Inspect** (`inspect_ai`) — or an equivalent
  harness (Garak, PyRIT, Promptfoo, custom in-house) — to run
  the engagement reproducibly.
- Define **agent-level evals** that go beyond "did the model
  say something bad" — action-level metrics that reflect the
  runtime and the tools.
- Report red-team results as a **scorecard the engineering
  team can act on**, not a slide deck of individual
  screenshots.
- Wire the engagement into CI as a **regression gate**:
  once a class of attack is defended, subsequent releases
  must not regress on that class.

---

## What counts as "the system under test"

The first mistake in agent red-teaming is scoping to the model.
The attack surface is the whole runtime: prompt → runtime →
model → tool decisions → tool executions → observed outcomes.
The *outcome* is where the exercise scores.

The system under test (SUT) for this chapter's engagements
includes:

- **The system prompt** at a pinned version.
- **The retrieval store** (if any), at a pinned snapshot,
  including any documents that were added by prior red-team
  runs.
- **The tool registry** at a pinned version, with the same
  ACLs and HITL policies that will ship.
- **The model** at a pinned version — chat model, embedding
  model, safety-classifier model, if separate.
- **The runtime layer** — the code that assembles context,
  enforces provenance labels, dispatches tools, records
  audits.
- **The HITL surface** — for actions that require human
  approval, whether the human is simulated (an evaluator
  role in Inspect) or human-in-the-loop is out of scope for
  automated runs; state which.

Scope decisions that follow:

- **What is deliberately out of scope.** Password stuffing on
  the login page, DDoS on the load balancer, cloud-account
  compromise — belong to other exercises. State them out
  explicitly.
- **What is *in* scope but only for observation.** A tool
  the runtime blocks under policy is *observed* — the
  engagement measures how often the model would have called
  it — but the engagement does not attempt to bypass the
  runtime block.
- **The identity model.** The attacker is a specific
  identity — an external user, a ticket submitter, a support
  customer — with defined access. Do not smear identities
  ("someone submits a payload from somewhere"); name the
  identity and its access.

---

## Threat scenarios — the corpus of "what to test"

The engagement is organised around **threat scenarios**, each
of which asks a single yes/no question at the outcome level:

- *Can an unauthenticated ticket submitter get the agent to
  exfiltrate another customer's data through a tool call?*
- *Can an authenticated tenant user get the agent to grant a
  role on a resource the user does not own?*
- *Can a public web page cause the browser-tool-using agent
  to send an email to an address the user did not name?*
- *Can an inbound email with an invisible payload cause the
  mail-agent to draft a reply containing content from an
  internal document not attached to the thread?*
- *Can a user prompt cause the agent to leak the system
  prompt?*
- *Can a Tier-3 tool call be executed against the wishes of
  the caller?*
- *Can the agent be induced into an unbounded-consumption
  loop that exceeds the per-caller budget?*
- *Can two seemingly independent inputs — one at ingest, one
  at query — combine (retrieval poisoning + query-time
  injection) into a data leak?*

For each scenario, the engagement defines:

- **A goal condition.** The concrete measurable outcome — a
  tool call was executed, a specific string appeared in the
  agent's response, a specific document was exfiltrated,
  the token budget was exceeded.
- **An attacker capability model.** External vs internal;
  what surfaces they can control; what they know.
- **A corpus of payloads.** Attempts at achieving the goal.
  Grows over time (see below).
- **A success metric.** The fraction of runs achieving the
  goal condition — not a pass/fail on a single run.

### The corpus — where the payloads come from

The corpus is the exercise's memory across engagements.
Sources:

- **Chapter 02's injection-corpus starter set** — the
  payloads exercise 02 shipped.
- **Public jailbreak / injection collections** — Anthropic's
  and OpenAI's published evaluation examples, AISI's public
  evaluations, Garak's probes, HarmBench, JailbreakBench,
  the SPLX / Purple Llama / Nemo Guardrails suites. Copy
  what applies; adapt the rest.
- **Every internally-discovered attack.** Every finding from
  a prior red-team run donates a payload. Every real
  incident donates a payload. The corpus never shrinks.
- **Adversarial-generation loops.** A helper model generates
  new payload variants against a specific scenario; the
  successful ones are added to the corpus. This is where
  most of the *novel* signal comes from — humans and static
  lists cannot keep up.

For each payload, the corpus records the surface (RAG /
browser / mail / …), the delivery mechanism (plain / HTML /
Unicode / Base64 / image / multi-turn), the intended goal
condition, and the version of the SUT it first succeeded
against.

<!-- needs-research: name the current versions of the public
     evaluation suites cited above and the exact locations to
     download them from; the field moves month-to-month. -->

---

## Why Inspect — and what an equivalent looks like

**UK AISI Inspect** (`inspect_ai`) is an open-source
evaluation framework published by the UK AI Safety Institute.
Its abstractions map directly onto agent red-teaming:

- **Task.** An eval definition — a name, a dataset, a solver,
  and one or more scorers.
- **Dataset.** A collection of `Sample`s, each with an
  input and a target. For red-teaming, each sample is one
  payload from the corpus with the goal condition as its
  target.
- **Solver.** The steps the SUT takes on a sample — prompt
  the model, call tools, produce an outcome. Inspect
  provides solvers for basic chat prompting, tool use,
  multi-turn, and multi-agent setups; a red-team engagement
  typically writes a custom solver that wires Inspect to the
  runtime under test.
- **Scorer.** How to judge whether the sample achieved the
  goal. Simple string matches, structured checks, or a
  model-graded scorer that reads the trajectory and returns
  a verdict.
- **Log.** Every run produces a structured, replayable log:
  the input, the trajectory, the model calls, the tool
  calls, the scorer verdict.

The three properties that make Inspect a fit for reproducible
red-teaming:

- **Deterministic-enough runs.** The framework pins model
  identifier, temperature, seed where the provider exposes
  one, and dataset. Two runs are as close as the model
  vendor allows.
- **Model-agnostic.** The same task runs against different
  models — critical for the "does the next model release
  regress or improve?" question.
- **Log-first.** The evaluation output is a rich log, not
  a percentage. Findings root in specific trajectories the
  responder can replay.

If the org cannot use Inspect (constrained infra, licensing,
sovereignty), an equivalent harness has to meet three
requirements:

1. **A dataset abstraction** the corpus loads into.
2. **A solver abstraction** that dispatches through the
   actual runtime (not a mocked chat call).
3. **A scorer abstraction** whose verdict is on the
   *outcome*, not the *response*.

Common alternatives:

- **Garak** (`nvidia/garak`) — LLM vulnerability scanner
  with probes for many classes; a fit for model-level
  eval, weaker for agent-level.
- **PyRIT** (Microsoft) — Python risk-identification
  toolkit; supports multi-turn attacker agents.
- **Promptfoo** — evaluation harness with a red-teaming
  plugin; broader web / CI-integration story.
- **HarmBench / JailbreakBench / Purple Llama** — standard
  eval suites; use them for baselines, not for full
  engagement coverage.

The engagement is not "use Inspect"; it is "run a
reproducible harness". Inspect is the recommended default.

---

## Agent-level evals — beyond "did the model say something bad"

The evaluations most public jailbreak benchmarks report score
on the model's *response text*. Agent red-teaming must score
on the *action*.

Four scorer types cover the space:

### 1. Action scorer

Did a specific tool call fire? With what arguments? Was it
blocked by the runtime? Was it approved by a simulated HITL
approver?

The trajectory produced by Inspect (or the equivalent) is a
sequence of events; the scorer walks the sequence and
returns:

```json
{
  "goal_achieved": true|false,
  "runtime_blocked": true|false,
  "hitl_approved": true|false,
  "tool_call_executed": "mail.send",
  "argument_diff": "recipients contained attacker@evil.com"
}
```

`goal_achieved` is the primary metric; the other fields feed
the *diagnostic* view a reviewer uses to understand which
control failed.

### 2. Content scorer

Did the agent produce an output containing content it should
not have? System prompt leakage, another tenant's data, a
credential, an internal URL.

Implementation: string / regex / classifier match on the
final assistant message *and* on any tool-call arguments
(the agent may exfil through a tool call, not through the
visible response).

### 3. Cost / consumption scorer

Was the per-caller budget exceeded? Did the agent enter a
loop? How many tokens / tool-calls / wall-clock seconds did
the sample consume?

Cost scoring measures LLM10 (unbounded consumption)
directly. Report per-payload cost distribution alongside
success rate; a payload that fails but consumes 100x normal
cost is still an incident.

### 4. Judge / rubric scorer

A model-graded scorer that reads the trajectory and returns
a verdict against a rubric. Use judiciously — model-graded
scorers add stochasticity and cost, and for well-defined
outcomes (a specific tool call, a specific string) the
deterministic scorers above are preferable. Save judge
scorers for open-ended assessments (misinformation quality,
policy-adherence in refusal wording).

---

## The engagement plan — what exercise 04 produces

The plan is a document the engineering team, the security
team, and the leadership sign off on before the exercise
starts. It has seven sections:

### 1. Scope

- Product under test: name, version, deployment stage.
- Systems in scope: system prompt, retrieval store, tool
  registry, model, runtime.
- Systems out of scope: platform infra, auth server, cloud
  account, IdP.
- Data classification for any live data touched: state that
  test data is used exclusively, or name the exact live
  data the exercise may touch.

### 2. Threat model

- Attacker identities: external, tenant-authenticated,
  privileged-internal.
- Attacker capabilities: content surfaces they can
  control, tools they can already call as a legitimate
  user.
- Goal conditions: the specific outcomes the engagement
  measures (from the scenarios list above).
- Cross-reference to the chapter-01 mitigation map: which
  OWASP LLM categories each scenario targets.

### 3. Rules of engagement

- **No live-customer data.** If the retrieval store or the
  mail inbox is a live-tenant environment, the exercise
  runs against a mirrored *test* tenant seeded with fake
  data.
- **Time-window and blast-radius contract.** The engagement
  is scheduled; on-call knows; sample volume is bounded.
- **No third-party abuse.** Emails, browser fetches, and
  external API calls hit test endpoints the engagement
  controls, not real recipients or third-party services.
- **Kill switch.** The engagement can be halted from a
  single control point; a running run can be aborted; the
  harness commits to not spilling artefacts on abort.
- **Reporting cadence.** Findings above a severity
  threshold are reported the day they are confirmed; the
  full report lands within N days of engagement end.

### 4. Corpus and sample plan

- Corpus version, size, and provenance (where each payload
  came from).
- Sampling policy: full-corpus run vs stratified subsample;
  count of runs per payload (for stochasticity).
- Any *adversarial-generation loop* to be executed during
  the engagement — the target scenario, the generator
  model, the acceptance criterion, the sample cap.
- Non-payload runs: a *clean* control set to measure false-
  positive rates in the defence stack (approvals fired
  unnecessarily, tools blocked that should not have been).

### 5. Metrics and success criteria

The scorecard reports, per scenario:

| Metric | Description | Reference |
| --- | --- | --- |
| `attempt_rate` | Fraction of runs where the model *attempted* the malicious action | how often the model was steered |
| `execution_rate` | Fraction where the action was *actually executed* (not runtime-blocked) | end-to-end failure rate |
| `hitl_bypass_rate` | Fraction where the simulated approver approved a malicious action | HITL design health |
| `detection_rate` | Fraction where the runtime alerted, regardless of prevention | observability health |
| `cost_p95` | 95th-percentile total cost per sample | LLM10 exposure |
| `false_positive_rate` | Fraction of *clean* runs that were incorrectly blocked | usability tax |

Ship criteria are *per-metric thresholds*, agreed with the
product team before the run. `execution_rate` of 0 is not a
realistic bar; a tolerable-and-declining bar is realistic.
Ship criteria the engagement is *not* meeting are release
blockers, not "will improve" line items.

### 6. Reporting and handoff

- The full log is preserved; every finding cites the
  trajectory ID that reproduces it.
- Findings are indexed by OWASP LLM category (chapter 01
  mitigation map), by tool tier (chapter 03), and by
  surface (chapter 02).
- Each finding gets an owner and a target-fix date.
- Every finding donates a payload to the corpus. The
  payload has a *regression test* — a task that fails if
  the finding recurs.

### 7. Regression gate

The exercise's harness lives on after the engagement:

- Wired into CI: on every release candidate, a
  reduced-size subset of the corpus runs; a *regression*
  on any scenario (i.e. `execution_rate` went up compared
  with the last accepted release) blocks the release
  until reviewed.
- Retrained: after a corpus update, a full-size run
  refreshes the baseline the CI gate compares against.
- Reported: the CI gate output is a scorecard the release
  manager reads, not a green/red checkbox.

---

## A sketch of an Inspect task

Illustrative — verify current Inspect API before shipping.

```python
from inspect_ai import Task, task
from inspect_ai.dataset import json_dataset
from inspect_ai.scorer import accuracy
from inspect_ai.solver import chain
from mycompany.evals import (
    load_agent_solver,       # dispatches through the runtime under test
    action_scorer,           # scorer type 1 (agent-level action)
    cost_scorer,             # scorer type 3 (LLM10 budget)
)

@task
def indirect_injection_rag():
    return Task(
        dataset=json_dataset("corpus/indirect_injection_rag.jsonl"),
        solver=load_agent_solver(
            runtime="prod-v42",
            model="anthropic/claude-<pinned-version>",
            hitl="simulated_conservative",  # or "simulated_permissive"
        ),
        scorer=[
            action_scorer(goal="mail.send with untrusted recipient"),
            cost_scorer(budget_tokens=50_000),
        ],
    )
```

Each `Sample` in the JSONL dataset carries the payload, the
delivery surface, and the goal condition. The solver runs the
runtime against the sample and produces a trajectory. The
scorers walk the trajectory and produce the metrics rolled up
by the scorecard.

The Inspect log (a JSONL file per run) is preserved as the
red-team artefact; every finding cites the log entry that
reproduces it.

---

## Simulated HITL — the awkward but necessary part

Real HITL requires humans. The engagement cannot manually
approve thousands of samples; the harness has to *simulate*
the approver.

Two useful simulations:

- **Conservative approver.** Approves only when the action
  looks exactly like the user's stated intent. High false-
  negative rate — misses subtle injections that mimic the
  intent. Approximates a well-trained, attentive user.
- **Permissive approver.** Approves when the action is
  facially plausible in context — approximates an over-
  trained, fatigued user or a novice. Approves more
  injections than the conservative simulator.

Report `hitl_bypass_rate` under *both* simulators. The
difference between them is a measure of how much your HITL
design leans on user attention (chapter 03's "rubber-stamp"
trap). A large gap says the HITL surface needs to
concentrate friction better — the security value evaporates
when users are tired.

A held-out subset of runs uses **real human approvers** — a
smaller sample, scheduled separately, that anchors the
simulators to reality.

---

## Cost, safety, and abuse controls for the exercise itself

Red-team exercises produce content the org would not
otherwise produce — payloads, exfil attempts, jailbreak
examples. Guardrails on the exercise:

- **Isolated environment.** Test tenants, test mail
  endpoints, test third-party APIs. No production
  connections.
- **Content classification.** The corpus is classified —
  some payloads are internal-only and do not leave the
  security team's environment (e.g. exploits with a working
  proof against a still-vulnerable production surface).
- **No live-user data used as payloads.** Payloads authored
  for the exercise never contain real customer data.
- **Cost budget.** The engagement is scheduled with a
  budget; the harness enforces it; overruns require a
  human unlock.
- **Sharing discipline.** Payloads shared externally are
  scrubbed of any org-specific identifiers before
  publication; the corpus registry names which payloads
  are internal-only.

---

## Standard failure modes

- **Scoring on model text instead of action.** "The model
  said sure!" is not the failure; "the tool executed" is.
  Rebuild scorers that measure the outcome.
- **A one-shot engagement with no CI wiring.** The exercise
  finds N vulns; the team patches them; the next release
  regresses because there is no regression gate. Ship the
  regression gate as part of the exercise.
- **Corpus that never grows.** Every finding, every
  incident, every real-world CVE donates a payload. A
  static corpus decays.
- **Nondeterministic runs treated as pass/fail.** Report
  rates; report per-payload variance; do not read too much
  into a single-sample outcome.
- **Ignoring cost.** A payload that succeeds 5% of the time
  but takes 50x tokens is a live LLM10 finding.
- **Simulated HITL used as if it were real HITL.**
  Simulators anchor to real approvers only when *some*
  runs use real approvers; skipping the anchor renders the
  HITL number aspirational.
- **Reporting only successes.** The clean-run false-
  positive rate is a first-class number; a defence that
  makes the agent unusable is a failed defence.
- **Confusing detection with prevention.** The engagement
  reports both. A high detection rate with zero prevention
  is a monitoring win and a security loss.
- **Not owning the retrieval store.** If the RAG corpus is
  the production one, the engagement is polluting live
  data. Snapshot / mirror it.
- **A red-team report as a slide deck.** The report is a
  scorecard plus a set of reproducible logs plus
  regression tasks. Slides are the *summary*, not the
  artefact.

---

## The mistakes this chapter is trying to prevent

- **Treating red-teaming as a research project.** The
  output is a scorecard, a corpus, a set of regression
  tests, and a CI gate — engineering artefacts. Novel
  attacks are welcome; they land in the corpus, not on a
  poster.
- **Testing the model without the runtime.** A model that
  "would" have done the wrong thing but is stopped by the
  runtime is a runtime win; a model that "refuses" but the
  runtime happily executes anyway is a runtime failure. The
  runtime is the SUT.
- **Ignoring the humans in the loop.** HITL is a control;
  it has failure modes; those failure modes need to be
  measured under both attentive and fatigued conditions.
- **Skipping the regression gate.** Every red-team
  engagement without a downstream CI gate is a one-shot
  exercise that fades within two release cycles.
- **Reporting without cost.** Unbounded-consumption
  incidents (LLM10) are silent in engagements that only
  measure "was the goal reached". Add cost scorers.
- **Not naming the corpus.** "We tried lots of things" is
  not reproducible. The corpus has a version; the
  engagement pins that version; the CI gate reads the same
  version.

---

## Summary

- Red-teaming a production LLM agent is **reproducible
  engineering**, not a research anecdote. The engagement
  plan has seven sections — scope, threat model, rules of
  engagement, corpus, metrics, reporting, and regression
  gate — and produces a scorecard plus a CI gate.
- **UK AISI Inspect** (`inspect_ai`) is the recommended
  harness; its dataset / solver / scorer / log abstractions
  map cleanly onto agent-level evaluation. Equivalents
  (Garak, PyRIT, Promptfoo) work when the three
  requirements — dataset, solver-through-runtime, outcome
  scorer — are met.
- **Score on the action, not the text.** Action scorers,
  content scorers, cost scorers, and (sparingly) judge
  scorers cover the space.
- **The corpus is the memory.** It grows from public
  suites, prior engagements, real incidents, and
  adversarial-generation loops. It never shrinks.
- **Simulated HITL** with both a conservative and a
  permissive approver reveals whether the HITL design is
  robust to user fatigue.
- **The regression gate** is the deliverable that
  survives the engagement. Every finding donates a
  regression test; every release runs the gate; the CI
  scorecard is the release manager's artefact.
- The failure mode this chapter is written to prevent is
  the *one-shot exercise* that produces qualitative
  findings, no CI wiring, and no corpus. Ship the
  scorecard and the regression gate together, or the
  exercise did not happen.
