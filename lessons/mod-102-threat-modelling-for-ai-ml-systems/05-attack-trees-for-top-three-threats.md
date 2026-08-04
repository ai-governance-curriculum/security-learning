# Chapter 05 — Attack Trees for the Top Three Threats

> **Note on AI-assisted content.** Attack-tree methodology
> references (Schneier 1999, Shostack 2014) and MITRE ATT&CK / ATLAS
> tactic identifiers must be verified against the primary sources
> before quoting. See [`resources.md`](./resources.md).

---

## Why this chapter exists

The IR-consumable inventory from chapter 04 gives you rows — one
per threat. Rows are flat. They do not show the *chain of
capabilities* an attacker must acquire, in order, to realise a
threat, and they do not show *where* along that chain the defender
can interdict.

Attack trees do. An attack tree decomposes a top-level attacker
goal into the sub-goals and prerequisites the attacker must
satisfy. Each internal node is a required condition; each leaf is
either a capability the attacker starts with or a step the attacker
must take. Nodes are combined with **AND** (all required) or **OR**
(any suffices).

For the module deliverable, you author attack trees for the **top
three threats** in the inventory — the three whose combination of
impact and likelihood dominates the risk profile. The tree does
three jobs:

1. **Traces the kill chain** from initial access, through discovery
   / staging / execution, to impact — in ATLAS-tactic language.
2. **Surfaces the least-cost path** — the cheapest path from root
   to leaves. This is where the attacker actually goes; the
   defender who cuts a link on this path removes the attack.
3. **Identifies detection-interdict points** — nodes where the
   defender's telemetry can fire before the leaves realise impact.
   These points are the input to mod-111's detection prioritisation.

The rule this chapter is trying to install:

> A threat model without attack trees for its top-ranked threats
> gives you rows, not paths. You cannot prioritise mitigations
> defensibly without knowing which mitigations cut which paths.
> Chapter 06 depends on this chapter's output.

---

## Attack-tree fundamentals

Attack trees originated in Schneier's 1999 paper (*Attack Trees*,
Dr. Dobb's Journal) and were formalised in the ISO/IEC 15408
Common Criteria threat-analysis tradition. Shostack's *Threat
Modeling* book codifies the practitioner form.

### Node types

- **Root** — the attacker's top-level goal, drawn from the STRIDE
  row. Example: *Extract a functionally equivalent surrogate of
  the fraud model to serve outside the platform.*
- **Internal node** — a sub-goal or a required condition.
  Combined with its children using:
  - **AND** — all children must be satisfied.
  - **OR** — any single child suffices.
- **Leaf** — an atomic capability or step the attacker must
  acquire.
- **Annotated leaf / node** — carries metadata: cost to attacker,
  probability of success, detection status, ATLAS technique ID.

### Node annotations for the ML domain

Each node carries the fields:

| Field | Contents |
| --- | --- |
| **ATLAS tactic + technique** | Where in the ATLAS matrix this node sits. Enables detection-content mapping. |
| **NIST AI 100-2 capability required** | The attacker capability the node presumes (query access, score access, training-data write, etc.). |
| **Cost to attacker** | Ordinal (low / medium / high / infeasible-at-scale) or an approximate dollar/token/time figure where the target requires quantitative risk analysis. |
| **Probability of success** | Ordinal (unlikely / plausible / likely / near-certain) given the assumed defensive posture. |
| **Detectable?** | Yes / no / partial — is there a telemetry source and a rule that would fire when this node is exercised? |
| **Interdict-here mitigation** | The named mitigation from chapter 06 that, if implemented, cuts this node. Filled in during chapter 06. |

Nodes without these annotations are decoration; nodes with them are
input to chapter 06.

### Choosing AND vs OR

The choice of AND vs OR is not stylistic — it is the difference
between "*every* one of these paths is required" and "*any* single
path suffices". The defender's cost of interdicting an AND node is
lower (any one child, defended, breaks the AND); the defender's
cost of interdicting an OR node is higher (must defend all
children). Get the operator wrong and the mitigation ranking in
chapter 06 is wrong.

Two heuristics:

- If the attacker needs *both* a capability and its usage step
  (e.g., "obtain valid tenant credentials" AND "issue extraction
  queries under them"), the node is AND.
- If the attacker can achieve a sub-goal by *multiple independent
  means* (e.g., obtain training-corpus write via CI/CD compromise
  OR via a compromised annotator OR via a poisoned ingest source),
  the node is OR.

---

## Selecting the top three threats

The attack-tree deliverable is bounded to three trees for a
reason: attack trees are expensive to author well, and marginal
trees past three rarely change the mitigation ranking. Selection
uses a two-axis rank:

- **Impact** — the blast radius from chapter 02, informed by the
  asset's sensitivity classification and the STRIDE row's
  description. Ordinal 1–5.
- **Likelihood** — informed by:
  - The current preventive posture from chapter 04's status block
    (gap / partial / live).
  - The public-attack maturity for the threat (well-known attack
    with off-the-shelf tooling → higher; academic-paper attack
    without runnable exploit → lower).
  - The external attack surface (public-facing endpoint → higher;
    internal-only → lower).
  - Ordinal 1–5.

Pick the top three by `impact × likelihood`, breaking ties by
preferring threats whose attack tree teaches the most (unfamiliar
kill chains > well-understood ones).

For the fintech reference system, a defensible top three is:

1. **Indirect prompt injection via retrieved support emails →
   excessive-agency tool call.** (LLM01:2025 + LLM06:2025 chain.)
   Highest by impact × likelihood on the LLM surface.
2. **Model extraction of the fraud decision surface for offline
   evasion.** (ML05 → ML01 chain.) Highest by impact × likelihood
   on the classical-ML surface.
3. **Training-data poisoning of the fraud training corpus via a
   compromised ingest source.** (ML02, with the ML07 transfer-
   learning shape if the fintech consumes any pretrained model.)

The rest of the chapter walks the first two trees at illustrative
depth. Exercise 04 asks you to complete all three for a target
system.

---

## Worked tree 1 — Indirect prompt injection → excessive-agency
tool call

**Root goal.** Cause the LLM agent to invoke
`propose-savings-transfer` with attacker-chosen arguments (recipient
account, amount) *without human-in-the-loop confirmation firing*.

**Impact.** Money-loss for the user; regulator notification event
for the fintech; brand impact.

The tree, in indented outline form. ATLAS IDs are placeholders —
verify against the current matrix.

```
ROOT: Invoke propose-savings-transfer with attacker-chosen args
      without HITL firing
[AND]
├── A1. Attacker's instruction reaches the model context
│   [OR]
│   ├── A1a. Plant instruction in a customer-support email
│   │       ingested into asset.assistant-rag.embedding-index
│   │       .customer-support-emails
│   │       [ATLAS: Initial Access via ingest]
│   │       Cost: LOW  Prob: LIKELY  Detectable: partial (content classifier)
│   ├── A1b. Plant instruction in a document uploaded to
│   │       user-visible knowledge base indexed by RAG
│   │       [ATLAS: Initial Access via ingest]
│   │       Cost: LOW  Prob: LIKELY  Detectable: partial
│   └── A1c. Direct-injection via own authenticated chat session
│           (attacker is a customer)
│           [ATLAS: Execution via user turn]
│           Cost: LOW  Prob: NEAR-CERTAIN  Detectable: yes (input scanner)
│
├── A2. Model treats the instruction as authoritative
│   [OR]
│   ├── A2a. System prompt does not distinguish retrieved-content
│   │       trust level from user-turn trust
│   │       [Design flaw — not a runtime action]
│   │       Cost: NIL  Prob: NEAR-CERTAIN (if flaw present)
│   │       Detectable: no (design-time)
│   └── A2b. Jailbreak pattern that suppresses safety-fine-tune
│           refusal
│           [ATLAS: ML Attack Staging]
│           Cost: LOW  Prob: LIKELY  Detectable: partial
│
├── A3. Agent decides to call propose-savings-transfer
│   [AND]
│   ├── A3a. Agent has propose-savings-transfer in its tool list
│   │       (release-gate-approved capability)
│   │       Cost: NIL  Prob: NEAR-CERTAIN (post release-gate)
│   ├── A3b. Agent chooses recipient account and amount as
│   │       specified in the injected instruction
│   │       Cost: NIL  Prob: LIKELY  Detectable: yes (tool-call log)
│
├── A4. Tool ACL does not block the call
│   [OR]
│   ├── A4a. Tool ACL is bound to the agent's service account,
│   │       not the user session identity
│   │       [Design flaw]
│   │       Cost: NIL  Prob: NEAR-CERTAIN (if design flaw)
│   ├── A4b. Attacker also compromises the user session (see A5)
│           and the ACL cannot distinguish attacker-in-session
│           from user-in-session
│
├── A5. Human-in-the-loop confirmation does not fire OR is bypassed
│   [OR]
│   ├── A5a. HITL threshold is above the injected amount
│   │       (attacker chooses amount < threshold)
│   │       Cost: NIL (attacker sets amount)  Prob: NEAR-CERTAIN
│   ├── A5b. HITL is disabled in a subset of code paths (e.g. after
│   │       user-elected "auto-approve small transfers" mode)
│   │       Cost: NIL  Prob: PLAUSIBLE (if opt-in feature exists)
│   └── A5c. HITL prompt confirmation is auto-answered because
│           model impersonates the confirmation flow
│           [Advanced — requires additional injection]
│           Cost: MEDIUM  Prob: PLAUSIBLE  Detectable: partial
│
└── A6. Impact: transfer completes and settles
        [ATLAS: Impact]
        Prob: contingent on A1..A5 all satisfied
        Detectable: yes (post-hoc — money is gone)
```

### Reading the tree

- The **least-cost path** — cheapest for the attacker — is A1a-or-b
  → A2a → A3 → A4a → A5a. All low-cost / no-cost. This is where
  the attacker will actually go.
- The **AND at the root** means the defender who cuts *any single
  child* removes the attack. Six candidate cuts, in priority order:
  1. Fix A2a (design flaw) — separate trust levels of every context
     source. Cuts the root regardless of A1.
  2. Fix A4a (design flaw) — bind tool ACL to the user session
     identity. Cuts the root regardless of A2.
  3. Fix A5a — make HITL threshold configurable *by the platform*
     with a lower default, not by the user; disallow low-amount
     bypass.
  4. Detect A1a / A1b at ingest — content classifier for
     injection payloads on all ingest sources.
  5. Detect A2b — jailbreak-pattern scanner on user turns.
  6. Detect A3b — tool-call sequence detector for unusual
     recipient-account values.
- **Detection-interdict points**: A1 (ingest scanner), A2b (input
  scanner), A3b (tool-call log), A5c (HITL-flow anomaly). These
  become the mod-111 detection backlog for this threat.

### Cost-of-defence ranking, sketched

The cuts above map to mitigations in chapter 06's scorecard:

| Cut | Mitigation | Coverage (paths cut) | Cost | Detectability |
| --- | --- | --- | --- | --- |
| Fix A2a | Trust-level separation in prompt composition | All root paths (100%) | Medium engineering | Preventive only |
| Fix A4a | Tool ACL bound to user session | All root paths (100%) | Medium engineering | Preventive only |
| Fix A5a | HITL threshold on all transfers | Most (90%) | Low engineering | Both — HITL denials are events |
| Detect A1 | Ingest content classifier | Cuts ~50% of paths at ingest | Medium ops | Detective only |
| Detect A2b | Input jailbreak scanner | Cuts direct-injection paths | Low ops | Detective |

Chapter 06 formalises this table into the scorecard shape.

---

## Worked tree 2 — Model extraction of the fraud decision surface

**Root goal.** Reconstruct a functionally equivalent surrogate of
`fraud-v42` such that the attacker can adversarially test evasion
inputs offline and then deploy them at inference-time.

**Impact.** Downstream evasion by the same attacker or a customer
of theirs (evasion service). Regulator notification if the model is
a SR 11-7 model whose integrity is now compromised.

```
ROOT: Deploy an offline surrogate of fraud-v42 usable to craft
      evasion attacks
[AND]
├── B1. Obtain query access to fraud-v42.decision-surface
│   [OR]
│   ├── B1a. Legitimate tenant credentials (customer of the fintech)
│   │       Cost: LOW  Prob: NEAR-CERTAIN  Detectable: N/A
│   ├── B1b. Compromised internal service-account credential
│   │       [ATLAS: Credential Access]
│   │       Cost: HIGH  Prob: UNLIKELY  Detectable: partial (mod-111)
│   └── B1c. Query proxy — attacker pays a customer for their queries
│           Cost: MEDIUM  Prob: PLAUSIBLE  Detectable: partial
│
├── B2. Issue enough queries to cover the decision surface
│   [AND]
│   ├── B2a. Rate limit allows the required query volume
│   │       [ATLAS: Discovery]
│   │       Cost: contingent on B2b  Prob: contingent
│   │       Detectable: yes (per-tenant query counter)
│   ├── B2b. Distribute queries across tenants / sessions to evade
│   │       per-tenant coverage detector
│   │       [ATLAS: Defense Evasion]
│   │       Cost: MEDIUM  Prob: PLAUSIBLE  Detectable: partial
│
├── B3. Receive rich enough responses to train a surrogate
│   [OR]
│   ├── B3a. Score-based responses (full confidence vector)
│   │       Cost: NIL (if surface exposes)  Prob: NEAR-CERTAIN
│   │       Detectable: N/A
│   ├── B3b. Only top-1 label — attacker still succeeds but needs
│   │       more queries
│   │       [Increases B2 cost]
│   │       Cost: HIGH  Prob: PLAUSIBLE
│
├── B4. Train the surrogate offline
│   [ATLAS: ML Attack Staging]
│   Cost: LOW  Prob: NEAR-CERTAIN  Detectable: no (offline)
│
└── B5. Deploy surrogate to craft evasion inputs
    [ATLAS: Impact]
    Cost: NIL  Prob: NEAR-CERTAIN
```

### Reading the tree

- **Least-cost path**: B1a (customer credential) → B2a + B2b →
  B3a → B4 → B5. This is the path the extraction detector must
  see.
- **AND at the root**: cuts on any of B1, B2, or B3 remove the
  attack. B4 and B5 are offline and unreachable by defence.
- **Interdict priorities**:
  1. Cut B3a: **truncate output to top-1** for tenants outside a
     score-access allow-list. Cuts B3a directly; downgrades B3 to
     B3b (much higher B2 cost).
  2. Cut B2b: **cross-tenant coverage detector** that aggregates
     over tenant identity families to spot distributed queries.
  3. Cut B2a: **tighten per-tenant rate limit** and add coverage-
     shaped alerts (mod-101 chapter 02 Sigma stub).
  4. Cut B1c: **query-proxy detection** (unusual query patterns
     from customer accounts inconsistent with product usage).
- **Detection-interdict points** are B2a, B2b, and cross-references
  to mod-111 for extraction-pattern detectors.

---

## Worked tree 3 — Sketched

For the training-data poisoning attack (top-three item 3), the
attack tree sketches similarly. Exercise 04 asks you to author it
in full. As a preview, its root is:

```
ROOT: Cause fraud-v42 to systematically underclassify
      attacker-selected transaction patterns as non-fraud
[AND]
├── C1. Get attacker-authored records into the training-eligible
│      corpus
│   [OR]
│   ├── C1a. Compromise a downstream data source that ingest promotes
│   ├── C1b. Compromise a human annotator or annotation vendor
│   ├── C1c. Compromise the CI/CD path that promotes ingest batches
│   └── C1d. Poison a public dataset the corpus subsumes
├── C2. Craft records with a trigger pattern OR statistical bias
├── C3. Survive canary-set regression at retraining acceptance
├── C4. Deployed model exhibits the crafted defect at inference
└── C5. Attacker uses defect against production traffic
```

The full tree, with cost / probability / detectability annotations
per node, is exercise 04's deliverable.

---

## Attack-tree tooling and formats

For a small model (top-3 trees), Markdown outline form is fine and
is what this module uses. For larger models, three tool categories
are worth knowing:

- **Text-based DSL tools** — attacktree-based DSLs, Kroki-renderable
  syntax. Version-controllable.
- **Mermaid / Graphviz** — render an outline as a diagram for
  design-review presentation.
- **Full threat-modelling suites** — OWASP Threat Dragon, IriusRisk,
  Microsoft Threat Modeling Tool. These carry attack-tree metadata
  as first-class objects; they are heavier but export to shapes IR
  tools can consume.

Whichever tool you pick, the requirement is:

- The tree is **versioned** in source control.
- Every node has **ATLAS + NIST vocabulary annotations** (so the
  cross-references to chapter 04 hold up).
- Every node has **cost / probability / detectability** annotations
  (so chapter 06 can rank cuts).

---

## The output artifact this chapter produces

By the end of this chapter and exercise 04, for the top three
threats:

- Three attack trees, one per threat, in versioned source form
  (Markdown outline is fine).
- Each tree annotated with cost / probability / detectability /
  ATLAS-tag per node.
- The least-cost path highlighted.
- A candidate-cut list per tree, sorted by coverage-of-paths,
  ready to be scored in chapter 06.

---

## The mistakes this chapter is trying to prevent

- **AND / OR confusion.** Get the operator right or the mitigation
  ranking is wrong.
- **Trees without cost annotations.** A tree with no cost / prob
  numbers is a diagram, not a decision aid. Even ordinal labels
  (low / medium / high) are enough to rank cuts.
- **Trees only for the "scariest" threat.** The top-three by
  impact × likelihood is the rule. Scary is not the same as
  impactful × likely.
- **Publishing trees as slides.** Version-control the source form.
  Slides are for the audience; the source is for the pipeline.
- **Ignoring detection-interdict points.** A cut at a leaf close to
  impact (A5c above) is worse than a cut higher up (A2a) — but the
  detection at A5c may be the only feasible layer. Chapter 06
  ranks these; do not pre-empt it here.

---

## Summary

- Attack trees decompose top-level attacker goals into the
  capabilities and steps the attacker must acquire, connected by
  AND / OR operators.
- Author trees for the top three threats by impact × likelihood
  from the inventory in chapter 04.
- Every node carries ATLAS tag + NIST vocabulary + cost + probability
  + detectability. Nodes without these annotations are decoration.
- The least-cost path is where the attacker actually goes; the
  defender who cuts a link on that path removes the attack.
- The candidate-cuts per tree are the input to chapter 06's
  mitigation prioritisation scorecard.
