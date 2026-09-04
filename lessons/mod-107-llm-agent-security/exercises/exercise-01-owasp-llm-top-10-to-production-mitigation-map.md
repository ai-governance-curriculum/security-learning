# Exercise 01 — OWASP LLM Top 10 to Production Mitigation Map

**Estimated effort:** ~3 hours
**Deliverable:** A committed mitigation-map bundle for one
LLM/agent product, consisting of (a) the chapter-01 per-
category mitigation map filled in end-to-end, (b) a threat-
narrative section that walks the *product-specific* attack
path for each in-scope category, (c) a control-ownership
matrix that names the human owner and the platform
implementation for every "yes" row, and (d) a one-page
executive summary the product's PM and eng lead can act on.
**Prerequisites:** Chapter 01 read end-to-end. Access to
one target product — a chat assistant, a RAG-backed
customer support agent, a coding assistant, an email
triage agent, a browser-tool-using research assistant, or
similar. Chapter 02, 03, and 05 skimmed enough to know
where the primary controls live in this module.

---

## Objective

Turn the OWASP Top 10 for LLM Applications v2025 from a
list into a *decision*. Every LLM-integrated product has to
answer, per category:

- Is this category in scope for *this* product?
- What is the concrete attack path if it is?
- What is the primary control we ship?
- Who owns the control?
- What evidence proves the control is in place?

The mitigation map is the artefact that carries those
answers into design review, release gates, and governance
evidence (mod-109). Without it, "we handle prompt injection"
is a claim, not a control.

By the end of this exercise you have:

- A per-category map with owners, controls, and evidence
  pointers.
- A threat narrative that argues *why* each row is what it
  is — not just the row.
- A ranked list of the top three gaps the product ships
  with today, and what closing each requires.

You are producing a **security-facing** artefact — the audience
is the on-call security engineer, the product's tech lead, and
the governance / audit function.

---

## Problem statement

Pick one target product. Preferably a real one you have read
access to; failing that, a well-defined internal proof-of-
concept or a well-documented open-source LLM app (a public
"chat with your docs" template, an open-source support-agent
starter, an open-source coding assistant). Whatever you pick,
by the end of this exercise you must be able to name:

- Who its users are (external customers, tenant employees,
  internal-only, developers).
- What tools its agent has (or "chat-only, no tools").
- What content sources it reads (retrieval index, live
  search, mail, tickets, docs, chat).
- What actions it can take (send email, file tickets,
  update CRM, make payments, deploy code, none).
- Where it runs (cloud region, tenant model, data residency).

If you cannot answer these in one page, spend an hour talking
to the product's owner before writing the map. The map is
much easier when the product's shape is clear.

---

## Requirements

### Deliverable A — the mitigation map

Fill in the table from chapter 01 for the target product.
Every row is either "yes with control" or "no with reason":

| OWASP LLM ID | In scope? | Attack scenario for *this* product | Primary control | Owner | Evidence artefact |
| --- | --- | --- | --- | --- | --- |
| LLM01 direct | | | | | |
| LLM01 indirect | | | | | |
| LLM02 | | | | | |
| LLM03 | | | | | |
| LLM04 | | | | | |
| LLM05 | | | | | |
| LLM06 | | | | | |
| LLM07 | | | | | |
| LLM08 | | | | | |
| LLM09 | | | | | |
| LLM10 | | | | | |

Rules from chapter 01:

- **Every "yes" row has a named owner.** "Security team" is
  not a name; a specific person or a specific rotation is.
- **Every "no" row has a written reason.** "Not applicable"
  by itself is not a reason. "The agent has no tools and
  produces only bounded text; excessive agency is
  structurally not reachable" is a reason.
- **Every "primary control" is either implemented, on the
  short-term roadmap, or explicitly deferred with a target
  date.** "Something we should look at" is not a control.
- **Every "evidence artefact" points somewhere concrete** —
  a config file, a runtime metric, a red-team scorecard, a
  model card row, a CI job. If the evidence does not exist,
  the row is a *gap*; flag it as such (see Deliverable C).

Prefer *primary* control per row — the one thing you would
point at first — even where multiple controls exist. The
threat narrative can name the layered controls; the map
column is one line.

### Deliverable B — threat narrative

For every in-scope row, write a short paragraph — 3–8
sentences — that walks the product-specific attack:

- Who is the attacker? What identity do they have?
- What surface do they attack (specific tool, retrieval
  path, user input surface)?
- What does the payload look like (concrete example, if
  the category is one where a payload is meaningful)?
- What is the failure mode if unmitigated (harm to the
  product, its users, or the org)?
- Which control (the one in the map) blocks the attack
  path, and *at which point* — ingest, prompt assembly,
  model call, tool dispatch, output rendering?

This section is what turns the map from a checklist into a
document a reader can *reason from*. The failure mode a
mitigation blocks is often more revealing than the mitigation
itself.

### Deliverable C — control-ownership matrix

A companion table listing, for each in-scope row, the
technical implementation of the control:

| OWASP LLM ID | Control implementation (where in code / infra) | Owner (human) | Verification (how we know it is in place) | Gap? | Target date |
| --- | --- | --- | --- | --- | --- |

- **Control implementation** points at code, config, or
  infrastructure — "our RAG assembler at `services/rag/
  assembler.py` labels retrieved fragments with `trust=…`",
  "the tool registry at `agent/registry.yaml`", "the
  runtime config for the mail tool at `k8s/mail-tool/
  values.yaml`". Vague pointers ("in the codebase") are
  not implementations.
- **Verification** is the test or metric that proves the
  control is live. A CI job that runs the chapter-04 corpus;
  a runtime metric on trust-label enforcement; a red-team
  scorecard entry. If verification is "we intend to
  verify", the row is a gap.
- **Gap** is a boolean; True if the control is not fully
  in place today. Every gap has a **target date** and a
  named owner (may be the same as the row's map owner or
  someone else).

### Deliverable D — one-page executive summary

Written for the product's PM and eng lead, at the top of the
bundle. In this order:

1. **Product identity in one sentence.** Who uses it, what
   it does, what tools it has.
2. **Top three gaps.** Ranked by risk. Each is one line —
   category, gap, the concrete next step to close it.
3. **What is well-covered.** Two-to-three sentences — the
   categories where the product already ships the primary
   control.
4. **Governance and mod-109 hook.** One sentence naming
   the model-card / evidence-surface row this mitigation
   map feeds.

If a reader stops after this page, they should know what to
prioritise for the next release cycle.

---

## Starter guidance

- **Start with the product shape.** The five questions in
  the problem statement — users, tools, sources, actions,
  where — drive every row. Guessing produces a generic map;
  reading the product produces a specific one.
- **Do not try to write every row at once.** A pass across
  the ten categories saying "in scope? yes/no with a one-
  line reason" is faster than a full-detail pass on rows
  1–3 that leaves 4–10 stubbed.
- **Use the chapter-01 mitigation names as a starting
  point, not a final answer.** The primary mitigation per
  category is a *default* recommendation; the product's
  actual control may be stronger or weaker. Argue in the
  narrative if you diverge.
- **Do not overload LLM06.** Excessive agency is a huge
  category; its map row is a summary, and the tool-tier
  detail belongs to exercise 03. If the tier breakdown
  belongs anywhere in this exercise, put it in the
  ownership matrix as separate rows per tool.
- **A "no" row is a decision.** "No tools yet" is not a
  reason to strike LLM06 — it is a reason to strike the
  *current* row, with a note that adding tools reopens
  the row.
- **Cite chapter cross-references.** LLM03 goes to
  mod-110; LLM04 goes to mod-106 chapter 04 + mod-104;
  LLM02 goes to mod-108. Naming the sibling module in
  the map is fine and expected.

---

## Acceptance criteria

A passing bundle:

- Every row of the mitigation map is filled in, with
  either a control + owner + evidence pointer or a
  written reason for "no".
- The threat narrative walks each in-scope row with a
  concrete product-specific attack scenario.
- The control-ownership matrix names the implementation
  location, the owner, the verification method, and the
  gap status for every in-scope row.
- The executive summary names the top three gaps with a
  concrete next step per gap.
- Cross-references to sibling modules are used where
  the primary control lives outside mod-107.
- The bundle names the product-shape facts (users,
  tools, sources, actions, where) up front.

A failing bundle:

- Rows filled with generic OWASP boilerplate that could
  belong to any product.
- "Yes" rows without a named human owner.
- "No" rows without a written reason.
- Evidence pointers that don't resolve ("we will add
  telemetry").
- LLM10 struck as "not a security issue" without
  argument.
- LLM07 covered by "we have a good system prompt".
- LLM06 covered without any reference to blast-radius
  tiers or HITL patterns.

## Stretch goals

- **Add a fourth column to the map: "Detection surface"**
  — where does the alert fire if the control fails?
  Chapter 04's red-team gate, chapter 05's severity
  ladder, or nowhere yet.
- **Draft the chapter-05 severity ladder policy for the
  top three risks.** For each of the three highest-risk
  in-scope categories, name the SEV tier the incident
  would land at.
- **Cross-reference to the classical adversarial-ML map
  (mod-106 chapter 01).** LLM-inherited families — LLM04
  (poisoning), LLM02 (privacy) — get the mod-106 threat-
  model artefact filled in for the underlying model, and
  the mod-107 mitigation map cites it.
- **Wire the map into design-review.** Any change to
  the product's tool list, retrieval sources, or user
  scopes touches the mitigation map; the design-review
  template links to the map's current version.

## Do not

- Do not treat the OWASP list as sufficient governance —
  it is a *checklist*, not the whole programme. mod-109
  owns the governance record; this map feeds it.
- Do not blindly copy chapter 01's default mitigations
  into the primary-control column. The default is a
  starting point; the product-specific control may
  differ.
- Do not commit sensitive tool arguments or credentials
  as illustrative payloads. Redact.
- Do not commit a solution here — solutions live in the
  paired solutions repo.
