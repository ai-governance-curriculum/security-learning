# Chapter 01 — Why Threat Modelling for ML Needs New Assets

> **Note on AI-assisted content.** These lecture chapters were drafted
> with AI assistance and are under human review. Verify every
> framework version, technique ID, and control claim against the
> primary source before quoting in production work. See
> [`resources.md`](./resources.md).

---

## Why this chapter exists

Traditional threat modelling — Shostack's *Threat Modeling: Designing
for Security*, Microsoft's SDL, OWASP's methodology — was written
for classical software systems: web apps, services, databases,
message buses. Its core moves (draw the data-flow diagram, name the
trust boundaries, walk STRIDE against every element or interaction,
score the results) still work, but the *asset vocabulary* it
provides — data stores, processes, data flows, external entities —
is under-specified for ML.

The specific failure mode this chapter is written to prevent:

> A team draws a classical DFD of the ML system. The model shows up
> as a "process" and the training data as a "data store". STRIDE is
> walked against them as if they were an ordinary microservice and a
> Postgres instance. The resulting threat model catches
> authentication threats and log-injection threats but *entirely
> misses* evasion, poisoning, extraction, inversion, membership
> inference, prompt injection, and every ML-native attack in mod-101.
> The threat model passes review; six months later, an ATLAS-tagged
> incident lands in the queue for which the model was silent.

This is not a hypothetical mistake — it is what a threat model
authored without the ML asset vocabulary produces every time.

The fix is not to abandon STRIDE. STRIDE is fine. The fix is to
elevate five ML-specific things — training data, model artifact,
decision surface, prompt/tool graph, embedding index — to
**first-class asset classes** on the DFD, and to walk STRIDE against
each of them with ML-native attacks in mind.

This chapter installs the motivation for that move, the shape of the
DFD that supports it, and the trust-boundary reasoning specific to
ML systems. Chapter 02 defines each asset class; chapter 03 walks
STRIDE-per-element against them.

---

## What classical STRIDE misses in an ML system

Classical STRIDE catalogues six threat categories:

| Letter | Threat category | Classical example |
| --- | --- | --- |
| **S** | Spoofing | Attacker impersonates a user or a service. |
| **T** | Tampering | Attacker modifies data or code at rest / in transit. |
| **R** | Repudiation | Actor denies performing an action; system cannot prove it. |
| **I** | Information disclosure | Confidential data leaks to a party not authorised for it. |
| **D** | Denial of service | System becomes unavailable or too slow. |
| **E** | Elevation of privilege | Attacker gains capabilities they should not have. |

Every ML-native attack in mod-101 collapses awkwardly into one or
more of these letters:

- **Evasion (OWASP ML01)** is Tampering — but *at inference time,
  through the model's normal input surface*, without touching data
  at rest. Classical Tampering rows for a data flow do not model
  this.
- **Poisoning (OWASP ML02)** is Tampering — but *at training time,
  months before impact*, and the "tamper" is a well-formed training
  record.
- **Extraction / model theft (OWASP ML05)** is Information
  disclosure — but the disclosed information is *the model's
  decision function*, not a data store.
- **Inversion (OWASP ML03)** is Information disclosure — but the
  disclosed information is *training-data reconstructions* produced
  from an ostensibly public inference API.
- **Membership inference (OWASP ML04)** is Information disclosure —
  but the disclosed information is *the training-set membership of
  a specific record*, not the record itself.
- **Prompt injection (OWASP LLM01:2025)** is Tampering + Elevation
  of privilege — but the "tamper" is a *natural-language string*
  reaching the model through a retrieval channel, and the
  "elevation" is *the model taking a tool action outside its
  intended scope*.
- **Excessive agency (OWASP LLM06:2025)** is Elevation of privilege
  — but the elevation happens at agent-loop runtime, mediated by
  the LLM, not by a classical auth bypass.

Every ML attack *fits* into STRIDE with a reasonable amount of
squinting. The problem is that STRIDE *alone* does not tell you to
look for these attacks — the letters do not prompt you to consider
"could an inference query be a training-data reconstruction
attack?" because the classical DFD does not have "the training data
that the model has memorised" as a distinct asset from "the
training data at rest in S3".

The fix is to name the ML assets and let the STRIDE walk *per
asset* prompt the ML-native failure modes. Chapter 03 does this.

---

## The DFD conventions this module uses

Every threat model needs a data-flow diagram. For ML systems, the
DFD conventions are the classical Shostack set (external entity,
process, data store, data flow, trust boundary) plus a few
additions:

### The five ML asset classes as DFD elements

Chapter 02 defines these in depth. For the DFD, treat each of the
five as its own kind of element with its own icon or annotation:

- **Training data** — the corpus the model learned from. On the DFD,
  a distinct data-store shape from ordinary application data.
- **Model artifact** — the file(s) that hold the trained weights,
  the architecture, and the tokenizer/preprocessor. On the DFD, a
  distinct kind of data store — signed, versioned, immutable.
- **Decision surface** — the model's input-to-output function, as
  exposed by the serving process. On the DFD, an interaction
  boundary that admits queries and emits predictions, not a
  process.
- **Prompt / tool graph** — for LLM apps, the composition of system
  prompt + user turns + retrieved content + tool schemas + tool
  outputs. On the DFD, a construction step inside the serving
  process, drawn explicitly, with each token source as its own
  trust level.
- **Embedding index** — for RAG apps, the vector store holding
  embeddings of documents that get retrieved into the prompt. On
  the DFD, a queryable data store with per-tenant namespaces and
  ACL semantics.

### Trust boundaries specific to ML

Classical trust boundaries in a web app run between the browser and
the server, between the server and the database, between the
company network and the internet. ML systems add three more:

- **Training-eligible boundary.** The perimeter around data that is
  allowed to become training gradient. Anything outside this
  boundary — production user feedback, third-party feeds, scraped
  content — is not training-eligible unless it crosses a signed,
  audited promotion step. Model-skewing (OWASP ML08) is the failure
  mode when this boundary is fuzzy.
- **Model-artifact boundary.** The perimeter around the model
  registry. Read/verify is broad; write is narrow. The signature
  scheme (mod-105) is the gate. Model poisoning (OWASP ML10) is the
  failure mode when this boundary is fuzzy.
- **Retrieval / tool-response boundary.** For LLM apps, the
  perimeter separating tokens the developer authored (system
  prompt, tool schemas) from tokens the model retrieved or received
  from tools (untrusted). Indirect prompt injection (OWASP
  LLM01:2025) is the failure mode when this boundary is not drawn.

Every ML asset on the DFD sits inside one or more of these trust
boundaries; a STRIDE walk that ignores the boundaries produces
threat rows that are structurally impossible in the actual
architecture and misses threats that are structurally likely.

---

## The end-to-end artifact this module produces

By the end of the module, for a target ML system, you produce one
threat-model packet with six components. This chapter previews
their shape; the following chapters walk their construction.

1. **Asset inventory** (chapter 02 + exercise 01). One row per asset,
   with its class, its sensitivity classification, its blast-radius
   estimate, and its trust-boundary membership.
2. **Data-flow diagram**. The DFD with the five ML asset classes as
   first-class elements and the three ML-specific trust boundaries
   drawn.
3. **STRIDE-per-element table** (chapter 03 + exercise 02). One row
   per (element, STRIDE letter) intersection that has a real threat,
   with the specific attack, the affected asset, and the
   preventive / detective / evidence sketch.
4. **ATLAS + NIST AI 100-2 mapping** (chapter 04 + exercise 03). One
   row per STRIDE threat with its ATLAS tactic + technique IDs, its
   NIST AI 100-2 family + capability / knowledge / lifecycle stage,
   and a stub IR runbook reference. This is the **IR-consumable
   inventory**.
5. **Attack trees** (chapter 05 + exercise 04). Three trees, one per
   top-ranked threat, each tracing initial access → discovery →
   staging → impact. Nodes are ATLAS techniques where possible;
   leaves are attacker capabilities the attacker must acquire.
6. **Mitigation prioritisation scorecard** (chapter 06 + exercise 05).
   One row per candidate mitigation with its cost, its coverage
   (which attack-tree paths it cuts), its detectability (does it
   leave an evidence artifact), and its resulting priority in the
   sequenced roadmap.

Every component references the previous. The asset inventory
determines the STRIDE rows; the STRIDE rows drive the ATLAS mapping;
the top-ranked threats drive the attack trees; the attack trees
determine which mitigations are worth investing in.

---

## Where threat modelling for ML *stops* on this ladder

Chapter 05 of mod-101 established the deferral contract. Two lines
apply to this module:

- **Detailed adversarial-ML mitigation implementation** — DP-SGD,
  PGD training, TRADES, certified defences — is authored in mod-106,
  not this module. The threat model *names* the mitigation; the
  mitigation module *implements* it.
- **Detection-content authoring at implementation depth** — Sigma
  rules, KQL queries, SPL, EQL — is authored in mod-111. The threat
  model *names* the detection requirement and its ATLAS tag; the
  SecOps module *authors* the rule.

For this module, "the mitigation is DP-SGD with ε=8 at model version
N" is a fully-formed threat-model artifact. Do not stall the model
by trying to fully implement the mitigation inline.

---

## What "good" looks like versus what "bad" looks like

A concrete contrast, adapted from a threat model of the fintech LLM
agent introduced in mod-101 exercise 01:

**Bad row — classical STRIDE, no ML asset vocabulary.**

| Element | Threat | Notes |
| --- | --- | --- |
| Model service | Information disclosure | The service could leak PII. Add TLS. |

That row is not wrong, but it does not model the actual failure
mode: an authenticated tenant queries the model in a way that
reconstructs training-data records from other tenants (OWASP ML03,
NIST AI 100-2 model inversion). TLS does not touch the failure. The
row wastes design-review time and generates no useful control.

**Good row — asset-aware, ML-adapted STRIDE.**

| Asset | Element | STRIDE | Threat (attack) | ATLAS | NIST AI 100-2 |
| --- | --- | --- | --- | --- | --- |
| Model artifact `fraud-v42` decision surface | inference endpoint | I | Model inversion — authenticated tenant reconstructs training-record features by score-based query optimisation. | Reconnaissance / ML Model Access (verify IDs) | Model inversion; inference-time; score-access; grey-box (verify) |

That row is a working artifact. The preventive mitigation (DP-SGD +
score-truncation), the detective mitigation (query-pattern monitor
mapped to ATLAS), and the evidence artifact (signed DP training
report + query-monitor rule) can each be sourced from mod-106 /
mod-108 / mod-111 without further translation.

The remaining chapters teach you to produce rows of the second
shape systematically.

---

## The mistakes this chapter is trying to prevent

- **Modelling the ML system as ordinary microservices.** If the DFD
  contains no ML-specific asset icons, the threat model will find
  no ML-specific threats.
- **Doing STRIDE-per-interaction only.** STRIDE-per-interaction
  works for microservice interactions but omits threats that
  target an asset in place (poisoning, artifact tampering,
  inversion). Prefer STRIDE-per-element, with per-interaction
  passes as a supplement.
- **Skipping the trust boundaries.** A threat model with no
  training-eligible boundary drawn cannot express the model-skewing
  or indirect-prompt-injection threat rows correctly.
- **Naming assets without classifying them.** An asset without a
  sensitivity classification and a blast-radius estimate cannot be
  ranked; the scorecard in chapter 06 loses its input.
- **Skipping the mapping to ATLAS and NIST vocabulary.** A threat
  model that cannot be handed to the mod-111 detection engineer
  or the peer `ai-evaluation-engineer` verbatim is a threat model
  that stops at the security team's desk. That is not the role's
  deliverable.

---

## Summary

- Classical STRIDE was written for classical software. Every
  ML-native attack in mod-101 fits into STRIDE only with squinting,
  and STRIDE alone does not prompt you to look for the attack.
- The fix is not to abandon STRIDE. The fix is to elevate five ML
  asset classes — training data, model artifact, decision surface,
  prompt/tool graph, embedding index — to first-class DFD elements
  and walk STRIDE against each with ML-native attacks in view.
- The DFD needs three ML-specific trust boundaries in addition to
  classical ones: training-eligible, model-artifact, and retrieval
  / tool-response.
- The module produces a six-component packet: asset inventory, DFD,
  STRIDE table, ATLAS + NIST-mapped inventory, attack trees for the
  top three threats, and a prioritised mitigation scorecard.
- What this module does *not* do: implement mitigations (mod-106,
  mod-107, mod-108, mod-110) or author detection content (mod-111).
  It produces the threat model those modules consume.
