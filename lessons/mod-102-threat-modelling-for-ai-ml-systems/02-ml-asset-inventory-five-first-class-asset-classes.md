# Chapter 02 — The ML Asset Inventory: Five First-Class Asset Classes

> **Note on AI-assisted content.** Verify every framework term and
> asset-class definition against the primary sources in
> [`resources.md`](./resources.md) before quoting externally.

---

## Why this chapter exists

Chapter 01 argued that classical STRIDE misses ML-native attacks
because the DFD it walks does not have the right asset vocabulary.
This chapter defines the vocabulary — five ML-specific asset classes
that must appear as first-class elements on the DFD, each with its
own sensitivity classification, blast-radius characterisation, trust
boundary membership, and admissible-operations envelope.

The five classes:

1. **Training data** — the corpus the model learned from.
2. **Model artifact** — the file(s) that carry the trained parameters,
   the architecture, and the tokenizer/preprocessor.
3. **Decision surface** — the model's input-to-output function, as
   exposed by the serving path.
4. **Prompt / tool graph** — for LLM apps, the composition of the
   context window at inference time and the tools the model can
   invoke.
5. **Embedding index** — for RAG apps, the vector store whose
   contents are retrieved into the prompt.

The chapter walks each class and gives you the row template you
carry into exercise 01.

The rule this chapter is trying to install:

> If any of these five classes exists in your target system and
> does *not* appear as its own row in the asset inventory (with
> class, classification, blast radius, boundary, and admissible
> operations filled in), your threat model is under-scoped.

---

## The row template every asset gets

Every ML asset in the inventory gets a row with the following
fields:

| Field | Contents |
| --- | --- |
| **Asset ID** | Stable identifier used in the STRIDE table, the ATLAS mapping, and the attack trees. Example: `asset.fraud-v42.model-artifact`. |
| **Class** | One of the five: training-data, model-artifact, decision-surface, prompt-tool-graph, embedding-index. |
| **Owner** | The team that authors, maintains, and is on-call for the asset. Not the security team — the *owning* team. |
| **Sensitivity classification** | The organisation-standard tier (public, internal, confidential, regulated / PII / PHI / PCI). Each tier has a distinct control envelope. |
| **Blast radius** | If this asset is compromised — read, tampered, exfiltrated — what is the worst-case impact on customers, on regulatory posture, on the business? Quantified where possible: `revenue at risk`, `customers affected`, `regulator that must be notified`. |
| **Trust boundary membership** | Which of the classical + ML-specific trust boundaries the asset sits inside (see chapter 01 §"Trust boundaries specific to ML"). |
| **Admissible operations** | The set of operations that the asset's normal lifecycle permits — for example, "training-time write from lineage-tracked ingest job; inference-time read; no write from serving process." |
| **Signature / provenance requirement** | The signing / lineage / attestation the asset must carry before it is accepted downstream. `signed by internal-cosign-key`, `has SLSA v1.0 provenance attestation`, `has DP-SGD training log attached`. |
| **Retention / lifecycle** | How long the asset must be kept, how long it can be kept, and the destruction mechanism. Feeds GDPR / HIPAA / SR 11-7 obligations from mod-101 chapter 04. |
| **Dependencies** | Other assets this one depends on. Example: `asset.fraud-v42.model-artifact` depends on `asset.fraud-v42.training-corpus`. Dependencies drive attack-tree fan-out in chapter 05. |

The remainder of the chapter defines each class along the dimensions
above.

---

## Asset class 1 — Training data

### What it is

Every record that ever became a gradient the current model was
optimised against. This includes:

- The pre-training corpus (foundation models).
- The fine-tuning dataset.
- The RLHF preference data / reward-model training data.
- The synthetic data generated for augmentation.
- Any human-labelled subset used for supervised training or
  evaluation-set anchors that feed retraining.

Training data does **not** include prompts to a frozen inference
endpoint. Those are input, not training data. They *become* training
data only if a promotion pipeline (see mod-104 for lineage) crosses
the training-eligible trust boundary. Confusing these two is how
model-skewing (OWASP ML08) happens.

### Sensitivity classification

Training data inherits the sensitivity of every record that composes
it. A training corpus containing one PII record is a PII asset. In
practice, tiers used:

- **Public** — content the organisation could publish without harm.
  Common Crawl subsets in a pre-training corpus, for example.
- **Internal** — non-public organisational content.
- **Confidential** — commercial secrets, unreleased product info.
- **Regulated** — PII / PHI / PCI / student records / financial
  records subject to specific statute (GDPR, HIPAA, PCI DSS, FERPA,
  GLBA).

The classification determines the DP budget, the retention window,
the deletion obligation, and the export controls that apply.

### Blast radius

If the training data is exfiltrated: worst-case a full data breach
of every record in it. The breach must be notified per the
regulator obligations that apply. Records that could be reconstructed
from the model via inversion (asset class 3) are part of this blast
radius even without a bulk exfiltration.

If the training data is tampered: the resulting model has an
attacker-influenced defect. Poisoning (OWASP ML02), backdoor (OWASP
ML07 in transfer-learning contexts), and skewing (OWASP ML08) all
land here. The blast radius is the model's downstream impact
surface, not the data itself.

### Trust boundary membership

Training data must sit inside the **training-eligible boundary**.
The boundary's control gate is a signed promotion step: a record is
training-eligible only when the promotion job carries a valid
signature (mod-104 details the scheme).

### Admissible operations

- **Ingest** — from a lineage-tracked source with a signed manifest.
- **Read** — by training jobs, by data-lineage introspection tools,
  by DP-SGD accountants.
- **Amend** — never in-place; only via a new version with lineage.
- **Delete** — via right-to-erasure workflows that also invalidate
  models trained on the record (see mod-108 for unlearning).

### Signature / provenance requirement

Signed dataset manifests (cosign + in-toto), per-record lineage
edges to their ingest source, and (for regulated tiers) an attached
DPIA reference.

---

## Asset class 2 — Model artifact

### What it is

Every persisted representation of the trained model that a serving
or downstream training path can load, including:

- The model weights file(s) — `pytorch_model.bin`, `.safetensors`,
  `saved_model.pb`, `model.onnx`, TensorRT engine, HuggingFace repo
  snapshot, GGUF, LoRA / QLoRA adapters, quantised variants.
- The tokenizer / preprocessor / feature-extraction pipeline.
- The model configuration (architecture, hyperparameters).
- The model card that binds the above to a version and to the
  training run that produced it.

The model artifact is *not* the running process. The process is a
distinct DFD element (a "serving process" in classical STRIDE
terms). The artifact is what the process loads.

### Sensitivity classification

The model artifact's classification is the *maximum* of:

- The sensitivity of any record the model has memorised (via
  membership inference and inversion pathways).
- The commercial value of the model itself as intellectual property.
- Any dual-use / export-controlled capability the model has (large
  generative models with biological, chemical, or cyber-offensive
  capability increasingly land under export-control rules).

A model trained on regulated data inherits regulated status; a model
whose weights represent significant R&D investment is confidential
IP; frontier-capability models are potentially export-controlled.

### Blast radius

If the artifact is exfiltrated (OWASP ML05 extraction or ML10
theft): the attacker has offline query access with no rate limits.
Every defensive control that depended on inference-time rate
limiting is defeated. Watermarking (mod-101 chapter 03) becomes the
only remaining evidence.

If the artifact is tampered (OWASP ML10 model poisoning): the serving
path returns attacker-influenced outputs. This is the highest-blast
tampering scenario because it happens *after* every training-time
control has run.

### Trust boundary membership

The model artifact sits inside the **model-artifact boundary**. The
boundary's control gate is a signature scheme: only signed
artifacts, produced by a known training job with a valid provenance
attestation, are admitted to the serving path.

### Admissible operations

- **Write** — only by a signed training job at model registration
  time.
- **Read / verify** — by any authorised serving process, subject to
  signature verification at load.
- **Delete / archive** — by governed lifecycle policy only; retention
  is often driven by audit obligations (SR 11-7 for finance, FDA
  PCCP for medical).

### Signature / provenance requirement

Cosign signature, SLSA v1.0 provenance attestation naming the
training job, ML-BOM (mod-110), ModelScan clean report, DP-SGD
training log where DP was required.

---

## Asset class 3 — Decision surface

### What it is

The model's input-to-output function *as exposed to querying
parties*. This is a distinct asset from the model artifact because
an attacker who cannot exfiltrate the artifact can still attack the
decision surface — through inversion, membership inference,
extraction, or evasion — via queries.

Concretely, the decision surface is:

- The set of admissible inputs.
- The output the serving path returns for each — the top-1 label,
  the score vector, the ranked list, the generated text, the tool
  call.
- The metadata leaked alongside the output — latency, model version
  header, tokens consumed, "did we retrieve documents" flags.

Two systems with the same model artifact but different serving
configurations have different decision surfaces. A system exposing
top-1 labels has a smaller decision surface than a system exposing
full softmax vectors; a system exposing per-token logprobs has a
larger surface still.

### Sensitivity classification

The decision surface's classification is the maximum of:

- The classification of the training data the surface leaks about
  (via inversion, membership inference, extraction).
- The classification of any input a legitimate user may send
  (through-flow PII).
- The regulatory tier of the decisions themselves (SR 11-7 model
  decisions in finance, FDA-regulated medical decisions).

### Blast radius

- Extraction of the surface (OWASP ML05) produces a functionally
  equivalent surrogate model an attacker can deploy offline.
- Inversion (OWASP ML03) leaks representative training records to a
  querying party.
- Membership inference (OWASP ML04) leaks per-record training-set
  membership — a direct GDPR/HIPAA problem where the training set
  is medical or behavioural.
- Evasion (OWASP ML01) produces attacker-chosen outputs at
  inference time.

### Trust boundary membership

The decision surface is the outermost trust boundary of the ML
system for querying parties. It sits inside the same authentication /
authorisation boundary the rest of the serving path sits behind, and
its query-side controls (rate limits, per-tenant budgets,
score-truncation) are named in the admissible-operations envelope.

### Admissible operations

- **Query** — under authenticated identity, subject to per-tenant
  and per-endpoint rate limits and cost budgets.
- **Introspect** (return metadata beyond the prediction) — only for
  authorised roles; deliberately narrow the surface for external
  users.
- **Replay / batch** — under differentiated privilege; batch offline
  scoring should have a distinct role from real-time queries so
  extraction-shaped anomaly detection can exclude legitimate batch.

### Signature / provenance requirement

For high-stakes decisions, signed decision receipts (mod-101 chapter
01 §ML09). The decision surface itself is not a signable artifact,
but the *decisions it emits* can be.

---

## Asset class 4 — Prompt / tool graph

### What it is

For LLM applications, the prompt / tool graph is the composition of
everything the model sees and everything it can invoke at inference
time:

- The **system prompt** — developer-authored, versioned in code.
- The **conversation history** — the user's turns and the model's
  prior turns.
- The **retrieved content** — chunks returned from the embedding
  index (asset class 5) or any other retrieval source.
- The **tool schemas** — the function signatures the model is
  offered.
- The **tool responses** — the outputs of every tool the model has
  invoked in this session.
- The **agent-loop policy** — the code that decides when to stop
  looping, how to escalate, and how to route to a human.

The prompt/tool graph is an *asset* because it composes the model's
authority at inference time. A prompt/tool graph that mixes trusted
and untrusted tokens without labelling them is the failure mode
behind indirect prompt injection (OWASP LLM01:2025). A prompt/tool
graph that grants tools without ACLs is the failure mode behind
excessive agency (OWASP LLM06:2025).

### Sensitivity classification

The prompt/tool graph's classification is the maximum of:

- The classification of any secret in the system prompt (there
  should be none — see mod-101 chapter 01 §LLM07).
- The classification of any retrieved content or tool response
  reaching the context window.
- The privilege of the tools available to the agent.

### Blast radius

- **Prompt injection (direct or indirect)** — attacker-supplied
  tokens override developer intent and cause the model to emit
  unintended text or invoke unintended tools.
- **System prompt leakage (LLM07)** — the guarded prompt content
  reaches the user; if it names guardrails or contains secrets, the
  guardrails are enumerable.
- **Excessive agency (LLM06)** — the agent calls tools outside its
  intended envelope; the blast radius is whatever the tools can do
  (send email, transfer money, execute code, write to shared state).

### Trust boundary membership

The prompt/tool graph must respect the **retrieval / tool-response
boundary** — each token source labelled with its trust level; the
system prompt at the highest trust, tool schemas at high trust, the
user at low trust, retrieved content and tool responses at the
*lowest* trust.

### Admissible operations

- **Compose** — the serving process assembles the graph per turn,
  labelling every token source with its trust level.
- **Invoke tool** — subject to per-tool ACLs bound to the
  authenticated user session; irreversible tools bounded by
  human-in-the-loop confirmation.
- **Persist** — the full graph for each session logged with tenant
  and identity metadata for IR replay (see mod-111).

### Signature / provenance requirement

The system prompt is versioned in code with a signed hash. The tool
schemas are versioned in code. Retrieved content carries the source
identifier from the embedding index (asset class 5), which itself
carries provenance to ingest.

---

## Asset class 5 — Embedding index

### What it is

The vector store used to retrieve context into the prompt in a RAG
architecture:

- The **embeddings** — high-dimensional vectors.
- The **document store** — the raw or chunked documents the
  embeddings represent.
- The **retrieval configuration** — top-k, similarity thresholds,
  hybrid-search parameters, per-tenant namespace ACLs.
- The **embedding model** — the model that produced the vectors,
  itself a distinct asset with its own model-artifact and
  decision-surface rows.

The embedding index is not just a passive store. It is a queryable
inference surface — a similarity query can be a covert
information-disclosure channel (a form of extraction over the
underlying documents), and the ingest path can be poisoned to plant
injection payloads (LLM08:2025).

### Sensitivity classification

The embedding index's classification is the maximum of:

- The classification of any document indexed in it.
- The classification of any tenant whose documents share a
  namespace.

Cross-tenant sharing of an embedding namespace inherits every
tenant's classification and requires the strictest one; per-tenant
namespaces are the norm.

### Blast radius

- **Cross-tenant leakage** — a retrieval query from tenant A
  returns tenant B's documents. Direct PII / IP disclosure.
- **Poisoning (LLM08:2025)** — attacker-controlled content ingested
  into the index carries an injection payload; every subsequent
  retrieval that surfaces the chunk delivers the payload.
- **Similarity-query exfiltration** — an attacker with query access
  reconstructs indexed content by iterated similarity search.

### Trust boundary membership

The embedding index sits inside the **retrieval / tool-response
boundary** — its outputs, when composed into the prompt, are at the
lowest trust level.

Ingest into the index sits inside a separate boundary — an
ingest-eligibility gate — analogous to the training-eligible
boundary for training data. Not every document that could be
indexed is authorised to be indexed by the tenant serving the query.

### Admissible operations

- **Ingest** — from a signed source, with a document-provenance
  record.
- **Retrieve** — under the authenticated tenant's namespace ACL,
  subject to per-tenant retrieval budgets.
- **Delete** — via right-to-erasure workflows that also invalidate
  cached retrievals reaching downstream logs.

### Signature / provenance requirement

Document-provenance records at ingest, per-tenant namespace ACLs,
signed retrieval-configuration checked in as code.

---

## Composing the inventory

The five classes rarely appear alone; a realistic system has several
of each, and one asset often depends on another. The inventory is a
graph.

Example — the fintech LLM agent from mod-101 exercise 01, sketched
in shorthand:

- `asset.fraud-v42.training-corpus` (class training-data) — 24
  months of internal transaction records, PII tier.
- `asset.fraud-v42.model-artifact` (class model-artifact) — XGBoost
  binary, signed, in registry.
- `asset.fraud-v42.decision-surface` (class decision-surface) —
  internal REST endpoint, top-1 label + calibrated score, tenant-
  scoped by internal service.
- `asset.assistant-llm.system-prompt` (class prompt-tool-graph
  subcomponent) — versioned in code, signed hash, no secrets.
- `asset.assistant-llm.tools.get-transactions` — read-only, per-user
  ACL bound to session identity.
- `asset.assistant-llm.tools.categorise-transaction` — read-only,
  same ACL.
- `asset.assistant-llm.tools.propose-savings-transfer` —
  irreversible, per-session budget, requires human-in-the-loop
  confirmation.
- `asset.assistant-rag.embedding-index.customer-help-docs` —
  per-tenant namespaces, ingest allow-list, product help content.
- `asset.assistant-rag.embedding-index.customer-support-emails` —
  per-tenant namespaces, PII tier, ingest allow-list is the failure
  mode the recent white paper exploited.
- `asset.fraud-v42.decision-receipts` — high-stakes decision
  receipts signed by serving process, retained for IR.

Every one of these rows must have all fields from the row template
filled in. Half-filled rows produce half-covered STRIDE walks.

---

## Two frequent misassignments

Practitioners new to this classification often misassign two things.
Fix them at the inventory step, not later.

### The serving process is not the decision surface

The serving process is an ordinary DFD "process" element — it has
STRIDE rows for spoofing (workload identity), tampering (process
memory), information disclosure (log leakage), and so on. The
decision surface is the *ML asset* the process exposes. They share
a physical embodiment; they have different threat rows.

The clue: STRIDE rows against the serving process reduce to normal
service-security rows. STRIDE rows against the decision surface
produce inversion, membership inference, extraction, and evasion
rows — the ML-native ones.

### Prompts to a frozen endpoint are inputs, not training data

An inference prompt is not training data. It is a data flow into
the decision surface. It becomes training data only if a specific,
audited promotion pipeline moves it across the training-eligible
boundary. Confusing these two produces the classic model-skewing
failure mode (OWASP ML08) in the *architecture* (the pipeline
implicitly promotes everything), which the threat model then cannot
represent because it treated all inputs as already-training-eligible.

---

## The output artifact this chapter is training you to produce

By the end of this chapter and exercise 01, for the target system,
you produce:

- An **asset inventory table**: one row per asset with all row-
  template fields filled.
- A **dependency graph**: which assets depend on which. Used in
  chapter 05 to walk attack-tree fan-out.
- A **first-draft DFD** with the five asset classes drawn as
  first-class DFD elements and the three ML-specific trust
  boundaries drawn.

The chapter-03 STRIDE walk consumes this artifact directly. If any
asset is missing from the inventory, the STRIDE table cannot cover
its threats.

---

## Summary

- Five asset classes must appear as first-class DFD elements:
  training data, model artifact, decision surface, prompt/tool
  graph, embedding index.
- Every asset gets a row with: class, owner, sensitivity, blast
  radius, trust boundary, admissible operations,
  signature/provenance requirement, retention, dependencies.
- The model artifact is not the running process. The decision
  surface is not the model artifact. Inference prompts are not
  training data. These distinctions carry through the rest of the
  module.
- Assets rarely appear alone. Dependencies between them drive the
  attack-tree fan-out in chapter 05.
- The inventory is the input to STRIDE (chapter 03). A missing
  asset is a missing threat row.
