# Chapter 04 — Mapping Threats to ATLAS TTPs and NIST AI 100-2 Attack Families

> **Note on AI-assisted content.** Every ATLAS tactic / technique
> identifier and every NIST AI 100-2 family name in this chapter
> must be verified against the primary source at the time of use.
> ATLAS is a living framework and IDs change; NIST AI 100-2 e2023 is
> the pinned edition at the time of writing. See
> [`resources.md`](./resources.md).

---

## Why this chapter exists

Chapter 03 produced a STRIDE-per-element table of ML threats. That
table lives on the security team's desk in the shape STRIDE
prescribes. It is *not yet* in the shape the downstream consumers
need:

- The **incident-response function** (mod-111) reads threats as
  detection content indexed by MITRE ATLAS technique. A STRIDE row
  without an ATLAS tag cannot be routed to a Sigma rule or a
  playbook.
- The **peer `ai-evaluation-engineer` (level 35)** reads threats in
  NIST AI 100-2 vocabulary — attacker goal, capability, knowledge,
  lifecycle stage — so red-team engagement scoping and evaluation
  designs align with the threat model.
- The **program-leadership slice** (mod-112) reads threats as
  ATLAS-tactic coverage against the threat-model surface, feeding
  the board-visible metrics package.

This chapter installs the translation step. Its output is the
**IR-consumable threat inventory** — the third component of the
module's threat-model packet, and the artifact mod-111 ingests as
its detection-content backlog.

The rule this chapter is trying to install:

> Every STRIDE row from chapter 03 must be tagged with (a) at
> least one MITRE ATLAS tactic + technique pair, (b) a NIST AI 100-2
> attack family plus attacker goal / capability / knowledge /
> lifecycle stage, and (c) either an existing IR runbook reference
> or a stub runbook ID. A row without these tags is a row the
> downstream consumers cannot use.

---

## The IR-consumable row template

Every STRIDE row from chapter 03 acquires the following additional
fields:

| Field | Contents |
| --- | --- |
| **ATLAS tactic ID(s)** | The `TA####` identifier(s) of the ATLAS tactic(s) this threat corresponds to. Verify at [atlas.mitre.org](https://atlas.mitre.org/). |
| **ATLAS technique ID(s)** | The `AML.T####` identifier(s). A single threat often maps to multiple techniques across multiple tactics (initial access, staging, impact). List them all. |
| **NIST AI 100-2 family** | Evasion, data poisoning, backdoor / trojan, model extraction, membership inference, model inversion, attribute inference, reprogramming, prompt injection, data extraction / memorisation, abuse violation, or the closest published family. |
| **Attacker goal** | Availability, integrity (targeted / untargeted), privacy, or abuse. |
| **Attacker capability** | Training-time / inference-time; query-only / score / gradient; query budget assumption. |
| **Attacker knowledge** | White-box / grey-box (specify what) / black-box (query / score / decision). |
| **Lifecycle stage** | Training, inference, post-deployment. |
| **Reference attack** | The canonical academic reference for the attack shape (Szegedy, BadNets, Tramèr, Shokri, Fredrikson, Carlini, Greshake, etc.). |
| **IR runbook ID** | The runbook the alert routes to (`IR-ML-EVASION-01`, `IR-ML-EXTRACT-01`, `IR-LLM-INJECT-01`, ...). Stub if not yet authored — mod-111 owns the depth. |
| **Data source requirement** | The telemetry required for detection. Fed into mod-112's logging-investment argument. |

Every field in this template answers a question the downstream
consumer asks. Skipping any field breaks the handoff.

---

## Direction of the mapping

The mapping is not one-to-one; each direction serves a different
consumer.

### STRIDE → ATLAS (for detection engineering)

Start with the STRIDE row. Ask: *what is the attacker actually
doing on the wire, at the file system, at the model interface?*
That behavioural description matches an ATLAS technique.

- STRIDE `THREAT-DS-I-1 — Model extraction / stealing` → ATLAS
  technique under the *ML Model Access* / *ML Attack Staging*
  tactics (verify current ID for "Craft Adversarial Data" / "Verify
  Attack" / relevant staging techniques at atlas.mitre.org).
- STRIDE `THREAT-PT-T-1 — Indirect prompt injection via retrieval`
  → ATLAS technique under *Execution* / *ML Attack Staging* for
  prompt-injection variants (verify current AML.T#### at
  atlas.mitre.org — ATLAS has explicit prompt-injection technique
  coverage in the current matrix).
- STRIDE `THREAT-MA-T-1 — Artifact substitution` → ATLAS
  technique under *Persistence* / *Impact* aligned with model-
  artifact tampering (verify IDs).

Where a STRIDE row maps to *multiple* ATLAS techniques across the
kill chain — for example, an extraction attack has *Reconnaissance*,
*ML Model Access*, and *Exfiltration* steps — list all of them and
mark the technique with the strongest detection opportunity as the
primary.

### STRIDE → NIST AI 100-2 (for evaluation and control specification)

Same start; ask: *what family, what capability, what knowledge,
what lifecycle stage?*

- STRIDE `THREAT-DS-T-1 — Evasion` → NIST family *evasion*,
  inference-time capability, query-limited black-box knowledge is
  the deployed threat; white-box knowledge is the red-team
  threat.
- STRIDE `THREAT-TD-T-1 — Poisoning at ingest` → NIST family
  *data poisoning*, training-time capability, grey-box knowledge
  typical.
- STRIDE `THREAT-PT-T-1 — Indirect prompt injection` → NIST family
  *prompt injection* (GenAI extension), inference-time capability,
  black-box knowledge, post-deployment surface.

Every row now carries the vocabulary the peer evaluation engineer
uses when scoping evaluation runs and the vocabulary the auditor
uses when reading a red-team report.

### STRIDE ↔ OWASP (for the coverage matrix from mod-101)

The STRIDE row also carries its OWASP ML / LLM ID from chapter 03,
which was the mod-101 exercise-01 anchor. This closes the loop
between the coverage matrix and the threat model — the same row
appears in both artifacts, with the same identifiers.

---

## A worked example — the fintech reference system

Take the STRIDE rows from chapter 03 for the fintech LLM agent
introduced in mod-101 exercise 01. The following table shows the
IR-consumable inventory shape for a handful of representative rows.
Every identifier below must be verified against the primary source
at the time of publication.

<!-- needs-research: verify every AML.T#### and TA#### identifier below against atlas.mitre.org at the time this content is quoted. The technique numbering used here reflects the published matrix at authoring time and may drift. -->

### Row 1 — Indirect prompt injection via retrieval

- **STRIDE ID**: THREAT-PT-T-1
- **Asset**: `asset.assistant-rag.embedding-index.customer-support-emails`
- **STRIDE letter**: T (Tampering) — and E via downstream tool
  invocation.
- **OWASP**: LLM01:2025 (indirect) + LLM08:2025.
- **ATLAS tactics (verify)**: ML Attack Staging; Execution;
  possibly Impact.
- **ATLAS techniques (verify current IDs)**: prompt-injection
  technique under staging + execution.
- **NIST AI 100-2 family**: prompt injection (indirect).
- **Attacker goal**: integrity / abuse.
- **Attacker capability**: inference-time; ability to plant
  content in an ingested source (customer-support email).
- **Attacker knowledge**: black-box; requires knowledge that the
  support-email corpus is ingested.
- **Lifecycle stage**: post-deployment (ingest of untrusted
  content into a live index).
- **Reference attack**: Greshake et al. 2023 (indirect prompt
  injection).
- **IR runbook ID**: `IR-LLM-INJECT-01` (stub — mod-111 authors
  the depth).
- **Data source requirement**: retrieval log with source-URI of
  each retrieved chunk; prompt/tool-graph log per turn; tool-call
  audit.

### Row 2 — Model extraction on the fraud decision surface

- **STRIDE ID**: THREAT-DS-I-1
- **Asset**: `asset.fraud-v42.decision-surface`
- **STRIDE letter**: I (Information disclosure).
- **OWASP**: ML05.
- **ATLAS tactics (verify)**: Reconnaissance; ML Model Access;
  Exfiltration.
- **ATLAS techniques (verify current IDs)**: model-stealing /
  functional-extraction technique under Model Access;
  exfil-of-model-artifact-or-surrogate under Exfiltration.
- **NIST AI 100-2 family**: model extraction.
- **Attacker goal**: privacy (IP disclosure).
- **Attacker capability**: inference-time; query budget assumed at
  10⁴ / tenant / day per rate limit; assume score access.
- **Attacker knowledge**: black-box.
- **Lifecycle stage**: inference.
- **Reference attack**: Tramèr et al. 2016 (score-based
  extraction); Jagielski et al. 2020 for high-accuracy variants.
- **IR runbook ID**: `IR-ML-EXTRACT-01` (stub).
- **Data source requirement**: per-tenant query log with input
  embedding features (or a proxy — coverage of decision regions);
  authenticated tenant identity per query.

### Row 3 — Model inversion on the fraud decision surface

- **STRIDE ID**: THREAT-DS-I-2
- **Asset**: `asset.fraud-v42.decision-surface` (paired with
  `asset.fraud-v42.training-corpus`, THREAT-TD-I-2).
- **STRIDE letter**: I (Information disclosure).
- **OWASP**: ML03.
- **ATLAS tactics (verify)**: ML Model Access; Collection.
- **ATLAS techniques (verify current IDs)**: inversion / attribute
  inference / reconstruction technique.
- **NIST AI 100-2 family**: model inversion.
- **Attacker goal**: privacy.
- **Attacker capability**: inference-time; score access preferred
  but grey-box works.
- **Attacker knowledge**: black-box (score-based) or grey-box.
- **Lifecycle stage**: inference.
- **Reference attack**: Fredrikson et al. 2015; for LLMs Carlini et
  al. 2021 on data extraction from LLMs.
- **IR runbook ID**: `IR-ML-INVERSION-01` (stub).
- **Data source requirement**: per-tenant query stream + response
  scores; ability to compute optimisation-signature features (small
  perturbations across queries).

### Row 4 — Data poisoning at ingest against fraud training corpus

- **STRIDE ID**: THREAT-TD-T-1
- **Asset**: `asset.fraud-v42.training-corpus`
- **STRIDE letter**: T (Tampering).
- **OWASP**: ML02.
- **ATLAS tactics (verify)**: Resource Development; Initial
  Access; Persistence; Impact.
- **ATLAS techniques (verify current IDs)**: data-poisoning
  technique under Resource Development + backdoor-insertion
  variant.
- **NIST AI 100-2 family**: data poisoning (and backdoor / trojan
  variant).
- **Attacker goal**: integrity (targeted with backdoor / untargeted
  without).
- **Attacker capability**: training-time; ability to author
  records the ingest pipeline promotes.
- **Attacker knowledge**: grey-box typical (know the ingest
  schema).
- **Lifecycle stage**: training.
- **Reference attack**: Biggio et al. 2012; Gu et al. 2017
  (BadNets).
- **IR runbook ID**: `IR-ML-POISON-01` (stub).
- **Data source requirement**: ingest audit log with per-record
  provenance edge; canary-set delta per retraining run.

### Row 5 — Model artifact substitution in the registry

- **STRIDE ID**: THREAT-MA-T-1
- **Asset**: `asset.fraud-v42.model-artifact`
- **STRIDE letter**: T (Tampering).
- **OWASP**: ML10.
- **ATLAS tactics (verify)**: Persistence; Impact; possibly
  Initial Access via CI/CD compromise.
- **ATLAS techniques (verify current IDs)**: model-artifact
  substitution / supply-chain-compromise technique.
- **NIST AI 100-2 family**: (model modification — not one of the
  primary academic families; falls under supply-chain and
  integrity attacks, cross-reference OWASP ML10 and ML06).
- **Attacker goal**: integrity.
- **Attacker capability**: write access to registry or its
  backing store, or ability to substitute in transit.
- **Attacker knowledge**: varies.
- **Lifecycle stage**: post-training, pre-serving.
- **Reference attack**: BadNets / model-supply-chain literature.
- **IR runbook ID**: `IR-ML-ARTIFACT-TAMPER-01` (stub).
- **Data source requirement**: cosign signature verification log
  at model load; registry access audit; file-integrity monitor on
  backing store.

Five rows in this shape are enough to teach the pattern. Exercise
03 produces a full inventory for the fintech system.

---

## The inventory as a machine-parseable artifact

The inventory belongs in a source-controlled file, not a PDF. YAML
or JSON is the right shape because downstream tooling (detection
libraries, dashboards, mod-112 metric collectors) parses it.

An illustrative row in YAML:

```yaml
# Illustrative — verify all IDs before use.
- stride_id: THREAT-PT-T-1
  asset_id: asset.assistant-rag.embedding-index.customer-support-emails
  asset_class: embedding-index
  stride_letter: T
  abuse_col: true
  owasp: [LLM01:2025, LLM08:2025]
  atlas:
    tactics: [TA0028, TA0026]        # verify at atlas.mitre.org
    techniques: [AML.T0051, AML.T0056] # verify at atlas.mitre.org
  nist_ai_100_2:
    family: prompt_injection_indirect
    attacker_goal: integrity_and_abuse
    attacker_capability: inference_time_with_ingest_influence
    attacker_knowledge: black_box
    lifecycle_stage: post_deployment
  reference_attack:
    - "Greshake et al. 2023 (arxiv:2302.12173)"
  ir_runbook_id: IR-LLM-INJECT-01
  data_source_requirement:
    - retrieval_log_with_source_uri
    - prompt_tool_graph_log_per_turn
    - tool_call_audit
  status:
    detection_content: gap        # to be authored in mod-111
    preventive_mitigation: partial
    evidence_artifact: gap
```

The status block (last three fields) is the interface to chapter 06
(mitigation prioritisation) and to the mod-112 metrics package. It
answers, per threat: is the detection content live, is the
preventive mitigation live, is the evidence artifact required at
admission time yet?

---

## Coverage-vs-gap reporting

The inventory in the shape above supports a **coverage-vs-gap
report** — the single artifact you carry into a design review or a
board slide:

- Per ATLAS tactic: number of covered techniques, number of
  gap-status techniques.
- Per NIST AI 100-2 family: number of covered rows, number of
  gap-status rows.
- Per asset class: coverage percentage.
- Per data-source-requirement: which data sources are missing (a
  logging-investment argument for mod-112).

An example gap report (illustrative):

```
Coverage-vs-gap — Fintech reference system, YYYY-MM-DD
Inventory rows total: 47
  Preventive mitigation: live 22, partial 12, gap 13
  Detection content:     live 8,  partial 4,  gap 35
  Evidence artifact:     live 15, partial 8,  gap 24

Gaps by ATLAS tactic (verify IDs at atlas.mitre.org):
  Reconnaissance         : 3 gap-status rows (2 threats have no data source)
  ML Model Access        : 5 gap-status rows
  ML Attack Staging      : 7 gap-status rows (5 threats have no data source)
  Impact                 : 4 gap-status rows

Top data-source gaps:
  - per-tenant query stream with input-embedding features
  - full prompt/tool graph log per session
  - retrieval log with source-URI per chunk

Recommended next investment:
  1. Emit prompt/tool-graph log per session — closes 7 detection gaps.
  2. Emit per-tenant query embedding features — closes 5 gaps.
  3. Retrieval source-URI logging — closes 4 gaps.
```

That report is a working artifact — an ML platform team can
prioritise logging work against it; a mod-112 program-leadership
argument can quote it; an IR tabletop can drill against it.

---

## Handshake to mod-111 (SecOps and IR)

Mod-111 consumes this inventory as its detection-content backlog.
The handshake responsibilities:

- **This role produces**: the inventory + coverage-vs-gap + data-
  source-requirement list.
- **Mod-111 produces**: the Sigma / KQL / SPL detection rule per
  covered row, tagged with the same `atlas.T####` and
  `stride_id`; the IR runbook per rule; the false-positive
  characterisation.

Neither side should be writing the other's artifact. When the
handshake is clean, a new row added to the inventory automatically
enters mod-111's backlog with all the metadata a detection engineer
needs.

---

## Handshake to the peer `ai-evaluation-engineer` (level 35)

The peer reads the inventory as the input to red-team engagement
scoping. The handshake:

- **This role produces**: the row with NIST AI 100-2 capability /
  knowledge / lifecycle-stage fields.
- **Peer produces**: the red-team run under the specified capability
  envelope, with the attack success rate reported in vocabulary
  that references the row.

Mod-101 chapter 03 example 2 is the shape of the resulting red-team
report — attack success rate reported per NIST capability envelope,
per row.

---

## The two artifacts this chapter produces

By the end of this chapter and exercise 03, you produce:

- The **IR-consumable inventory** (YAML / JSON in source control),
  one row per STRIDE threat with all ATLAS + NIST + IR runbook
  fields filled.
- The **coverage-vs-gap report** — the derivative view that drives
  the next-investment ranking and the mod-112 metric package.

Both are input to chapter 06 (the mitigation prioritisation
scorecard reads the status block to rank remediation work).

---

## The mistakes this chapter is trying to prevent

- **Skipping the ATLAS mapping "because ATLAS moves too fast".** It
  does move, but the version pinning discipline (mod-101 chapter 02
  §Living-framework hygiene) is the answer. Do not use volatility
  as an excuse to skip the tag.
- **Skipping the NIST vocabulary "because it is academic".** The
  vocabulary is what the evaluation engineer, the auditor, and the
  red-team report all use. A row without it is unusable at the
  next handoff.
- **Publishing the inventory as a PDF.** The consumers are tools
  and pipelines. YAML or JSON in a repository, or a database with a
  schema.
- **Skipping the data-source-requirement column.** Without it, the
  mod-112 logging-investment argument has nothing to quote.
- **Filing the inventory as a one-time artifact.** ATLAS is a
  living framework, the model changes, the threat model must
  refresh on a cadence. The inventory has a version. Diff it.

---

## Summary

- Every STRIDE row from chapter 03 acquires ATLAS + NIST + IR-runbook
  + data-source metadata; the result is the IR-consumable inventory.
- The inventory belongs in a source-controlled machine-parseable
  file, not a document, because its consumers are pipelines.
- The coverage-vs-gap report is the derivative artifact you carry
  into design reviews and program-leadership slides.
- The handshakes to mod-111 (SecOps + IR) and to the peer evaluation
  engineer land on the inventory's tags; neither side authors the
  other's artifact.
- Version the inventory. ATLAS and NIST AI 100-2 both evolve.
