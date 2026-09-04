# Exercise 02 — Indirect Prompt Injection for One RAG App

**Estimated effort:** ~4 hours
**Deliverable:** A committed evaluation bundle for one RAG
application, consisting of (a) an **injection corpus** of at
least 20 versioned payloads targeting the RAG surface,
covering plain text, HTML, and Unicode/encoding-obfuscation
delivery mechanisms; (b) a **runnable harness** that
executes each payload end-to-end against the RAG app and
records an action-level trajectory; (c) a **before-and-after
scorecard** showing `execution_rate` (fraction of runs where
the injected instruction actually took effect) with the
existing controls, then with chapter-02 defences enabled
(provenance labels + input classifier + at least one
retrieval-side control); and (d) an **interpretation memo**
that names the two most effective defence layers and the
one most consequential residual failure mode.
**Prerequisites:** Chapter 02 read end-to-end. A target RAG
application whose retrieval store you can write to (a
staging-tenant knowledge base, a scratch RAG app you build
for the exercise, or a public-template RAG spun up locally).
Python environment with the RAG stack's runtime and a
scriptable HTTP or SDK client for the app.

---

## Objective

Turn "we defend against prompt injection" into a measured
number and a named residual risk. By the end of this
exercise you have:

- A concrete injection-corpus artefact you can hand to the
  next engineer.
- A harness that runs the corpus against a live RAG app and
  produces a trajectory-level log per run.
- Two numbers: `execution_rate` at baseline, and
  `execution_rate` with chapter-02 defences enabled.
- A written argument for which chapter-02 layers moved the
  number, which did not, and what the remaining risk is.

You are not building a research artefact. You are producing
the *before* number that justifies shipping the defence, and
the *after* number that shows it works.

---

## Problem statement

Pick one RAG-backed LLM application. The application must
have:

- A retrieval store the exercise can *write* to (an index
  the exercise seeds with payload documents).
- A user-facing surface — API endpoint, chat UI, or SDK
  entry point — the harness can call programmatically.
- A defined "malicious action" the payloads try to induce.
  Concrete examples:
  - Cause the model to include a specific attacker-chosen
    string in its response.
  - Cause the model to output a URL / email address /
    tool argument the *legitimate* user never mentioned.
  - Cause the model to leak a system-prompt fragment or
    a document the current user should not see.
  - Cause the model to make a tool call the runtime would
    let through (only if the app already has a tool
    layer; otherwise stick to text-level outcomes).

The app is not required to be your production system; a
scratch RAG built for the exercise counts, and is often
easier because you own every layer. A public "chat with
your docs" template — a LangChain / LlamaIndex starter, an
Ollama + Chroma stack — is a fine substrate.

Whatever you pick, name up front:

- Which model powers it (and its pinned version).
- Which retrieval store (FAISS, Chroma, PGVector, Pinecone,
  Weaviate, …) and how documents are ingested.
- Which retrieval parameters (top-K, similarity threshold,
  reranker if any).
- What the *legitimate* user's question shape looks like
  ("summarise the FAQ", "how do I do X in our product",
  "what does document Y say about Z").
- What "malicious action" you are trying to induce (one
  specific outcome; keep the scope tight).

---

## Requirements

### Deliverable A — the injection corpus

At least 20 payload records, each of which is a document
that will be ingested into the retrieval store and, once
indexed, is expected to be retrieved when the legitimate
user's question is asked.

Corpus schema (JSONL or per-file with a manifest):

```yaml
id: inj-001
surface: rag
attack_goal: cause_specific_string   # cause_specific_string | leak_prompt | send_url | ...
delivery: plain                       # plain | html | unicode | base64 | image
title: "How to reset your password"   # the visible document title
body: |
  <the payload document body — contains a plausible cover
  story to ensure retrieval matches, plus the injection
  block itself>
expected_safe_outcome: blocked_by_input_classifier
                      # blocked_by_input_classifier | blocked_by_prompt_isolation |
                      # detected_and_reported | refused_by_model | not_retrieved
version: 1
source: "authored for mod-107 exercise 02"
notes: "plain-text baseline"
```

Coverage requirements:

- At least 5 **plain-text** payloads.
- At least 5 **HTML** payloads (invisible spans, tiny
  fonts, display-none divs, HTML comments containing the
  instruction).
- At least 5 **Unicode / encoding** payloads (zero-width
  joiners, right-to-left overrides, Base64, ROT13,
  homoglyphs).
- At least 3 that use a **plausible cover story** — the
  document reads as if a real support article containing
  a supposed "internal note to the assistant" at the end.
- At least 2 that target **specific tool arguments** if
  the app has tools; otherwise, 2 more content-level
  payloads.

The corpus lives in a version-controlled directory; the
version field is bumped on any change; a `README.md` in
the corpus directory names the maintainer.

### Deliverable B — the harness

A runnable script or notebook that, for each corpus record:

1. **Ingests the payload** into the retrieval store under
   a test-tenant partition (never write to a live-tenant
   partition; if the app is multi-tenant, create a
   dedicated test tenant for the exercise).
2. **Poses the legitimate user question** through the app's
   normal user surface (API / SDK / chat UI script).
3. **Records the full trajectory** — the retrieved
   documents (fingerprints or IDs — do not necessarily
   copy every retrieved body), the prompt assembled, the
   model response, and any tool calls the app made.
4. **Runs an action-level scorer** that decides whether
   the malicious action was achieved. Deterministic where
   possible (string match, tool-call inspection, URL
   presence in output); model-graded only if the outcome
   is genuinely open-ended.
5. **Cleans up** — the ingested document is removed from
   the store; the run is recorded in the log.

The harness runs the *same* payload multiple times (default
N=3) because LLM outputs are stochastic; the reported
metric is a rate, not a single sample.

Output: a `results.jsonl` file with one line per
`(payload, run)` pair, containing at minimum: payload id,
run index, timestamp, model version, retrieval version,
achieved-outcome flag, and the trajectory ID that
reproduces the run.

### Deliverable C — the before-and-after scorecard

Run the harness twice:

- **Before.** Against the app as it exists today, with
  whatever controls are already in place (usually: a
  system prompt and nothing else).
- **After.** Against the app with chapter-02 defences
  enabled. At minimum:
  - **Content provenance labels.** Every retrieved
    fragment is rendered with a `trust=<band>` label and
    the system prompt instructs the model to treat
    `trust=untrusted` fragments as data.
  - **Input-side detector.** An instruction-shape
    classifier (an open-source model like PromptGuard,
    a signature-based detector, or a hosted safety
    classifier) runs against ingested documents and
    against retrieved fragments; a positive result
    causes the fragment to be rendered with an explicit
    "this fragment was flagged as containing possible
    instructions" annotation, or refused for retrieval.
  - **At least one retrieval-side control.** Ingest
    scanning (documents flagged at ingest), per-tenant
    scoping enforcement, or provenance-band filtering
    (system-authored fragments only for a specific
    query type).

Scorecard shape:

| Metric | Before | After | Notes |
| --- | --- | --- | --- |
| Overall `execution_rate` | | | primary claim |
| `execution_rate` on plain-text | | | |
| `execution_rate` on HTML | | | |
| `execution_rate` on Unicode / encoding | | | |
| `detection_rate` (fraction where a control fired) | | | secondary |
| Mean cost per run (tokens) | | | LLM10 signal |
| False-positive rate on clean control set | | | usability |

You must also include a **clean control set** — at least
5 legitimate user questions retrieved against the same
store *without* the payloads present — and measure
`false_positive_rate` (fraction of clean runs where a
defence layer incorrectly blocked or degraded the
response). A defence that makes the RAG unusable on clean
queries has failed.

### Deliverable D — the interpretation memo

~2 pages. Not a paper. Answer in order:

1. **What did we test and against what?** The app, the
   model version, the retrieval version, the corpus
   version. State clearly what "malicious action" the
   corpus targets.
2. **What did we find?** Overall `execution_rate`
   before and after. Highlight the specific delivery
   mechanisms where the number moved the most and the
   least — usually HTML and Unicode move more than
   plain text; sometimes the classifier struggles on
   Unicode.
3. **Which layers earned their cost?** For each defence
   layer you enabled — provenance labels, input
   classifier, retrieval-side control — argue whether it
   moved the number and by how much. If a layer did
   *not* move the number, name whether that is because
   the corpus was insufficient to test it or because
   the layer is genuinely ineffective on this app.
4. **The one residual failure mode.** Which payload
   class still has a non-trivial `execution_rate`?
   What does closing it require — a stronger classifier,
   an ingest-time policy change, a tool-side ACL
   (chapter 03), a human-review workflow?
5. **The chapter-04 handoff.** This corpus is the seed
   for the red-team engagement's RAG scenario. State
   the corpus version and the location; state one
   payload class the red-team should generate more of
   during its adversarial loop.

Cite:

- Library versions (RAG stack, model provider SDK,
  classifier if used) at the top.
- The chapter-02 defences you enabled, in order.
- Any public payload collections you drew from (with
  license attribution).

---

## Starter guidance

- **Own the retrieval store.** Do not run this against a
  live production index. Spin up a test partition or a
  local Chroma / FAISS instance. The whole point is that
  the exercise adds attacker-controlled documents to the
  store.
- **Fix the user question first.** Choose one legitimate
  user question shape and use variants of it consistently.
  Varying the question and the payload at once makes the
  results uninterpretable.
- **Make the payload plausibly retrievable.** A payload
  document about "unrelated topic" will not be retrieved
  when the user asks about the real topic. Every payload
  contains cover-story content that matches the query;
  the injection block is a small fraction of the document.
- **Start with plain-text payloads and measure.** Get one
  end-to-end run before adding the HTML and Unicode
  variants. Getting a stable baseline `execution_rate`
  on plain-text is what tells you the harness itself is
  working.
- **Do not confuse "the model refused" with "the runtime
  blocked".** The former is a probability; the latter is
  a policy. Score them separately in the trajectory.
- **Run each payload at N ≥ 3.** One-shot results across
  a stochastic model are noise. If N=3 is too expensive,
  reduce corpus size before reducing runs per payload.
- **Instrument cost.** Even a mostly-blocked payload can
  cost 10x normal tokens; that is a LLM10 signal worth
  reporting.
- **Do not skip the clean control set.** The
  false-positive rate is what you take to the product
  team; a defence that costs 20% of legitimate answers
  is worse than the attack it prevents.

---

## Acceptance criteria

A passing bundle:

- Corpus meets the 20-payload minimum with the required
  delivery-mechanism coverage.
- Harness runs end-to-end from a fresh clone (`pip
  install -r requirements.txt && python evaluate.py --
  config config.yaml`) and produces `results.jsonl`.
- Scorecard is present with both before and after
  numbers, per-delivery-mechanism breakdown, cost
  signal, and clean-control false-positive rate.
- Interpretation memo argues per-layer effectiveness
  and names one residual failure mode.
- Every payload is traceable to a specific
  trajectory ID in the log.

A failing bundle:

- Payloads that never got retrieved (harness recorded
  no fragment in the model's context) — untested
  payloads are not corpus entries.
- Before / after runs against different corpus versions
  or different model versions — controls are the
  chapter-02 defences, not the model version.
- Scorecard without a clean control set.
- "Success" claim without a residual failure mode
  named.
- Committed live-tenant data or committed live-model
  API keys.

## Stretch goals

- **Adversarial loop.** After the initial after-run, use
  a helper model to generate variants of the payloads
  that still succeed; add them to the corpus at v2 and
  rerun. The delta measures how well the defence
  generalises.
- **Cross-model comparison.** Rerun the after-scorecard
  against a second model (a different vendor or a
  different tier). Adds one row per payload to the
  scorecard.
- **Retrieval-time reranking.** Add a reranker step that
  down-weights fragments flagged by the input classifier
  and compare the number to the ingest-time filter
  approach.
- **Image / OCR payload.** Add 3 payloads delivered
  through image content (screenshots of injection text)
  if the RAG stack accepts multimodal inputs. Adds a
  new failure-mode class the memo can name.
- **Wire the harness into CI.** A subset of the corpus
  runs on every RAG-stack change; regression on
  `execution_rate` blocks the merge.

## Do not

- Do not test against a live-tenant retrieval store
  without written approval; use a test-tenant partition.
- Do not commit customer content, live-tenant data, or
  live API keys — including in payloads.
- Do not treat one favourable run as evidence; report
  rates.
- Do not claim a defence "works" without a
  before-and-after scorecard.
- Do not commit a solution here — solutions live in the
  paired solutions repo.
