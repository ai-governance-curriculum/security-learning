# Exercise 01 — ML Asset Inventory and Classification

**Estimated effort:** ~2 hours
**Deliverable:** One Markdown document containing (a) an asset
inventory table, (b) an asset-dependency graph, and (c) a first-draft
data-flow diagram.
**Prerequisites:** Chapters 01 and 02 read end-to-end. The fintech
reference system from mod-101 exercise 01 is the recommended target
system — use it if you do not have a real system in front of you.

---

## Objective

For a target ML/LLM system, produce the **ML asset inventory** that
serves as the input to every subsequent exercise in this module.
Every asset must be one of the five first-class ML asset classes
introduced in chapter 02 (training data, model artifact, decision
surface, prompt/tool graph, embedding index), and every asset must
carry the full row-template fields.

By the end of the exercise, you should be able to point at any
element on the DFD and answer, from the inventory, "what class of
asset is this, what is its blast radius if compromised, and what
trust boundary is it inside?"

## Problem statement

You are the AI/ML Security & Governance Engineer for the fintech
introduced in mod-101 exercise 01. The system in scope:

- **A classical fraud-detection model** (`fraud-v42`) — XGBoost
  classifier retrained monthly on 24 months of internal transaction
  data (PII tier). Deployed internally, consumed by a decisioning
  service.
- **An LLM-powered assistant** — chat surface for external
  customers. Tools currently in scope: `get-transactions`,
  `categorise-transaction`. A third tool,
  `propose-savings-transfer`, is pending release-gate approval and
  moves money between the user's linked accounts subject to
  human-in-the-loop confirmation.
- **A RAG layer** feeding the assistant — two embedding indexes:
  - `customer-help-docs` — public product help pages, per-tenant
    namespace inherited from doc scope.
  - `customer-support-emails` — historical support ticket emails,
    PII tier, per-tenant namespaces. **A recent public white paper
    demonstrated indirect prompt injection via customer-support
    email corpora on similar assistants.**
- **A signing / registry stack** — cosign-signed model artifacts
  registered in an internal registry; SLSA v1.0 provenance
  attestations attached; ML-BOM generated per release.
- **A downstream** — the assistant's decisions land in customer-
  facing UI; the fraud model's decisions are consumed by an
  automated decisioning service.

If you have a real system in front of you (an internal ML platform,
a public research system you have permission to model), substitute
it — the exercise structure is identical.

## Requirements

Produce a single Markdown document with the following sections.

### Section 1 — Target system summary (max 0.5 page)

- One-paragraph description of the system.
- The data flows in prose: from data ingest through
  training / retrieval / serving / consumption.
- The external surface: which endpoints an unauthenticated attacker
  can reach; which authenticated tenants can reach; which internal
  services can reach.

Assume the reader knows the ML asset vocabulary from chapter 02;
do not re-teach it. Assume the reader has *not* seen the specific
target system before.

### Section 2 — Asset inventory table

One row per asset. Use the full row template from chapter 02:

| Asset ID | Class | Owner | Sensitivity | Blast radius | Trust boundary | Admissible operations | Signature / provenance | Retention | Dependencies |

Rules:

- Every asset must be one of the five classes. If you find yourself
  wanting a sixth class, reread chapter 02 — it is almost always a
  process or an interaction that should be modelled separately, not
  a new asset class.
- Every asset ID must be stable and machine-parseable — kebab-case,
  hierarchical, e.g. `asset.fraud-v42.model-artifact`.
- Blast radius must be quantified where the target system permits.
  "Data breach" is not a blast-radius; "24 months of PII for N
  customers, GDPR/GLBA notification event, worst-case £X in
  regulator penalties" is.
- Admissible operations must be tight enough to *exclude* the
  attacker action later. Do not write "all standard operations" —
  that concedes STRIDE rows in advance.

### Section 3 — Asset dependency graph

For every asset in the inventory, list its dependencies (other
inventory rows it depends on) and its dependents (other inventory
rows that depend on it). Render as a bulleted list or a Mermaid
graph — the shape must be traversable in either direction so the
chapter-05 attack-tree walk can start at any node.

### Section 4 — First-draft data-flow diagram

Draw a DFD (Mermaid, PlantUML, ASCII, image — any format that is
version-controllable) that shows:

- Every asset from the inventory as a first-class element with an
  icon or annotation distinguishing its class.
- Every process (serving pod, training job, ingest job, retrieval
  layer) as a classical process element.
- Every external entity (customer, internal decisioning service).
- Every data flow between them (arrows with the payload named).
- The three ML-specific trust boundaries from chapter 01:
  training-eligible, model-artifact, retrieval / tool-response.
- The classical trust boundaries (internet ↔ platform, platform ↔
  training environment, tenant ↔ tenant).

Legend included, all boundaries labelled.

## Starter guidance

- Enumerate assets *by walking the lifecycle*: data ingest →
  training → model registration → serving → consumption →
  retention. You will find gaps in the given system description;
  fill them with defensible assumptions and mark them as
  assumptions.
- Use the mod-101 exercise-01 coverage matrix (if you completed it)
  as a starting corpus of assets and controls — do not re-invent it.
- Do the LLM side first. The prompt/tool-graph and embedding-index
  classes are less familiar than training-data / model-artifact /
  decision-surface, and their omission is the most common mistake.
- Draw the DFD *after* the inventory is complete. A DFD without a
  filled inventory is a doodle.
- Where the target system has no such asset (e.g., an
  LLM-only system with no classical model), say so explicitly in
  the summary rather than omitting the class silently.

## Acceptance criteria

A passing inventory:

- Contains at least one asset for every class present in the target
  system, and explicitly notes classes not present.
- Every row has every field populated — no TBDs.
- Every blast-radius field is quantified against the target system
  (customers, records, regulator, financial figure), not generic
  boilerplate.
- Every trust-boundary field names both classical and
  ML-specific boundaries where they apply.
- The dependency graph is traversable in both directions — every
  edge appears in both endpoints' rows.
- The DFD legend distinguishes all five ML asset classes visually
  and draws all three ML-specific trust boundaries.

A failing inventory:

- Models the model as a "process" and the training data as a
  generic "database" — the exact mistake chapter 01 flagged.
- Uses "PII" as a blast-radius answer.
- Omits the embedding-index class entirely for a RAG system.
- Draws a DFD with no trust boundaries.
- Uses "future work" or "TBD" in any row.

## Stretch goals

- Extend each row with a **retention-obligation** column citing the
  specific GDPR / HIPAA / SR 11-7 / GLBA / PCI DSS clause driving
  the retention decision (references from mod-101 chapter 04 and
  resources.md).
- Rank assets by an initial impact score you will re-use in chapter
  05 for top-three selection. Defend the ranking in two sentences
  per rank.
- Compare the fintech asset inventory to the inventory for an
  imagined **healthcare imaging** system (a classical vision model
  on CT scans, PHI tier). Which asset classes are different in kind
  (not just in classification)? Which are the same?

## Do not

- Do not paper over assets you do not have information about.
  Assumptions are fine when marked; unmarked guesses are not.
- Do not commit a solution to any repository — solutions live in
  the paired solutions repo.
- Do not skip the DFD in favour of "we'll do it in exercise 02."
  Chapter 03's STRIDE walk depends on the DFD.
