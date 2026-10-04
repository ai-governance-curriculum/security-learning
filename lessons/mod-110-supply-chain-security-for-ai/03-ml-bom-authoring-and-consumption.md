# Chapter 03 — ML-BOM: Authoring an AI-BOM for a Deployed Model

> **Note on AI-assisted content.** The CycloneDX ML-BOM extension
> and the SPDX 3.0 AI profile are *living* schemas; element
> names, URIs, and required fields change between releases.
> Verify every schema fragment below against the project
> documentation current at the time of use. See
> [`resources.md`](./resources.md).

---

## Why this chapter exists

The classical supply-chain primitive for software is the
**SBOM** — a Software Bill of Materials: a machine-readable
inventory of the components inside a built artefact and their
versions, hashes, suppliers, and licences. SBOMs became
mainstream after US Executive Order 14028 pushed the federal
procurement surface toward NTIA minimum elements, and today
every container image shipped by a mature org has one.

A model is not a software binary. The components that drove
its behaviour include things an SBOM does not describe:

- The **training dataset** (and the sub-corpora it was built
  from).
- The **base model** fine-tuned to produce the deployed
  weights.
- The **adapter / LoRA / instruction tuning** overlay.
- The **evaluation suites** used to clear the model for
  release.
- The **tokeniser / processor** version.
- The **licence obligations** for each of the above — many
  of which are *data* licences, not software ones (CC-BY-SA,
  OpenRAIL, custom "no commercial use" terms, dataset-
  specific user agreements).

The failure mode this chapter is written against:

> A product team ships a classifier built on top of a popular
> open-weights base model and a scraped dataset. The model's
> SBOM lists `transformers==4.42.3`, `torch==2.4.0`, and the
> container's base image digest — everything a classical SBOM
> captures. Twelve months later, a dataset in the training
> mix is pulled from its origin (DMCA; a human-subjects
> consent revocation; a lab's reversed decision to publish).
> The team is asked, under short deadline, "which production
> models were trained on that dataset?". Nobody can answer:
> dataset lineage was never written down in a machine-
> readable form at build time. The team spends two weeks
> walking training notebooks by hand to produce a defensible
> list, and the audit outcome depends on who happens to still
> work at the company.

The fix is to generate an **ML-BOM** (also called **AI-BOM**)
at build time, sign it (chapter 02), reference it from the
model's SLSA provenance (chapter 01), and store it in the
registry alongside the model. A machine-readable inventory,
indexed by dataset ID, base-model ID, and licence, converts
*that* fire drill into an SQL query.

You leave this chapter able to:

- Explain how an ML-BOM differs from a classical SBOM in
  content and in generation workflow.
- Choose between CycloneDX (with its `machine-learning`
  component type and ML extension) and SPDX 3.0 (with its
  AI and Dataset profiles) for a given programme.
- Enumerate the component classes an ML-BOM for a deployed
  model should describe — datasets, base models, fine-tuning
  components, third-party dependencies, environment, and the
  licences tied to each.
- Design a build-time generator that populates the ML-BOM
  from pipeline metadata rather than from after-the-fact
  reconstruction.
- Define a consumer workflow — admission, audit, DSAR,
  takedown response — that uses the ML-BOM for a real
  question.

---

## From SBOM to ML-BOM

An SBOM, in NTIA's minimum-elements form, describes a *tree*
of software components: name, version, supplier, unique
identifier, dependency relationships, author, timestamp.
Formats: CycloneDX (OWASP), SPDX (Linux Foundation / ISO/IEC
5962), SWID (ISO/IEC 19770-2). CycloneDX and SPDX are the
two in widespread production use.

An **ML-BOM** extends that tree with model-specific component
types:

- **CycloneDX** introduced an ML extension with a
  `components[].type == "machine-learning-model"` entry and
  a sibling `modelCard` field that carries the model-card
  content (training considerations, inputs/outputs,
  ethical / fairness properties, performance analysis). The
  CycloneDX ML extension draws its field vocabulary from the
  Mitchell et al. model-card paper. The dataset counterpart is
  `components[].type == "data"`, used for both training and
  evaluation data.
- **SPDX 3.0** added an **AI profile** and a **Dataset
  profile**. An `AIPackage` carries energy consumption, model
  explainability, hyperparameters, safety-risk assessment,
  intended uses, and limitations. A `DatasetPackage` carries
  dataset creator, intended use, known biases, and sensitive
  attributes.
- Both formats support **relationships**: `derived-from`,
  `trained-on`, `evaluated-with`, `fine-tuned-from`,
  `described-by`. These are what make the ML-BOM a *graph*
  rather than a flat list.

Which to pick:

- **CycloneDX** is the dominant choice in the sigstore /
  cosign / Kubernetes ecosystem. Its ML extension is actively
  developed and relatively concise. If your platform already
  emits CycloneDX SBOMs for containers (via Syft, Grype,
  Trivy), extending to ML-BOM is incremental.
- **SPDX 3.0** is the ISO-standardised choice. If the
  programme ships into procurement contexts that call out
  SPDX by name, or is bound to NIST SP 800-161 explicitly,
  SPDX is often the better fit.

Dual production is possible — generate once from pipeline
metadata, serialise to both formats. The *content* is what
matters; the serialisation is downstream.

A worked CycloneDX ML-BOM fragment (abbreviated):

```json
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:...",
  "metadata": {
    "timestamp": "2026-10-04T15:02:00Z",
    "component": {
      "type": "machine-learning-model",
      "bom-ref": "model:fraud-classifier@42",
      "name": "fraud-classifier",
      "version": "42.0.0",
      "licenses": [{ "license": { "id": "Apache-2.0" } }],
      "hashes": [{ "alg": "SHA-256", "content": "abcd..." }],
      "modelCard": {
        "modelParameters": {
          "approach": { "type": "supervised" },
          "task": "classification",
          "architectureFamily": "distilbert",
          "modelArchitecture": "DistilBertForSequenceClassification",
          "datasets": [{ "ref": "data:ticket-corpus@v3" }],
          "inputs": [{ "format": "application/json" }],
          "outputs": [{ "format": "application/json" }]
        },
        "quantitativeAnalysis": {
          "performanceMetrics": [{
            "type": "F1",
            "value": "0.91",
            "slice": "held-out-eval@v12"
          }]
        }
      }
    }
  },
  "components": [
    {
      "type": "machine-learning-model",
      "bom-ref": "model:distilbert-base@main",
      "name": "distilbert-base-uncased",
      "version": "main@6cdc0aad3",
      "supplier": { "name": "Hugging Face / distilbert org" },
      "licenses": [{ "license": { "id": "Apache-2.0" } }],
      "externalReferences": [
        { "type": "distribution", "url": "https://hf.co/distilbert/distilbert-base-uncased" }
      ]
    },
    {
      "type": "data",
      "bom-ref": "data:ticket-corpus@v3",
      "name": "customer-ticket-corpus",
      "version": "v3.0.0 (snapshot sha256:ef12...)",
      "supplier": { "name": "Internal Data Platform Team" },
      "licenses": [{ "license": { "name": "Internal — Confidential" } }],
      "externalReferences": [
        { "type": "distribution", "url": "s3://data/ticket-corpus/v3?versionId=..." }
      ],
      "properties": [
        { "name": "ml:dataset:row-count", "value": "2415673" },
        { "name": "ml:dataset:consent-basis", "value": "Legitimate interest; see DPIA v4" }
      ]
    }
  ],
  "dependencies": [
    {
      "ref": "model:fraud-classifier@42",
      "dependsOn": ["model:distilbert-base@main", "data:ticket-corpus@v3"]
    }
  ]
}
```

The fields that matter for governance:

- `bom-ref` makes each component globally referenceable
  from other BOMs and from attestations.
- `hashes` and `version` make the reference *content-
  addressable* — not just "the dataset at this URL" but
  "the dataset whose SHA-256 was this".
- `supplier` makes the row answerable to the mod-110 chapter
  06 supplier register.
- `licenses` makes licence-obligation triage mechanical.
- `properties` carries org-specific extensions (consent
  basis, row count, geographical scope) without requiring
  schema changes.
- `dependencies[].dependsOn` makes the graph queryable.

---

## What goes in an ML-BOM for a deployed model

A deployed model is the output of a build; the ML-BOM
describes the inputs the build consumed. A workable minimum
is six classes:

1. **The model artefact itself** (the subject of the BOM).
   Hash, licence, version, size, format (safetensors / GGUF
   / SavedModel), signing identity.
2. **The base model.** The model fine-tuned to produce the
   output. Must include the revision pin (chapter 05) — a
   name is not enough.
3. **Training datasets.** Every corpus or sub-corpus that
   contributed training examples. Content-addressed (DVC /
   LakeFS / S3-with-versionId / HF Datasets revision).
   Include row count, intended use, consent basis, PII
   coverage reference (mod-108 chapter 03's DLP profile).
4. **Fine-tuning / preference / RLHF components.** Instruction
   datasets, preference datasets, DPO preference pairs,
   reward models used in RLHF. These are often licensed
   differently from pre-training corpora.
5. **Third-party dependencies.** The Python packages, CUDA /
   cuDNN versions, container base image. For the container
   layer, embed or reference the Syft / Trivy SBOM — do not
   duplicate.
6. **Evaluation suites.** Which eval bundles were run and
   whose results were accepted. Links to the signed eval-
   scorecard attestation from mod-106.

Optional-but-recommended classes:

- **Adapters / LoRA weights / soft prompts** when the model
  is a composition.
- **Tokeniser / processor** when it is versioned separately
  from the base model (common for multilingual models).
- **Safety classifiers / guardrail models** bundled into the
  serving stack.
- **System prompts / tool registries / RAG indices** for
  agentic systems (mod-107). These are supply-chain
  artefacts in the sense that they drive behaviour; signing
  and inventorying them closes the loop that would otherwise
  let a config-bucket compromise silently change the agent.

What *not* to include:

- **PII values.** The ML-BOM is a signed, distributable
  artefact; it is read by auditors, consumers, and tooling.
  Dataset descriptions are fine (`"row-count": 2415673`,
  `"columns": ["name", "ssn (redacted)", ...]`); the dataset
  itself is referenced by hash, not inlined.
- **Secret material.** API tokens, HF access tokens, KMS
  key names belong in mod-105 systems; names of the KMS
  references are acceptable, token values never.
- **Human free-text ethics discussions.** Keep the ML-BOM
  machine-readable. The ethics write-up lives on the model
  card (which the BOM references, but does not embed as
  prose).

---

## Dataset components in depth

Dataset entries are the hardest row to get right because the
software-SBOM reflex is "name + version", and dataset
*versioning* is often done poorly in ML pipelines. A
workable dataset component:

```yaml
type: data
bom-ref: data:ticket-corpus@v3
name: customer-ticket-corpus
version: "v3.0.0"
supplier:
  name: Internal Data Platform Team
licenses:
  - license:
      name: "Internal — Confidential"
      url: "https://internal/data-licence/ticket-corpus-v3"
externalReferences:
  - type: distribution
    url: "s3://data/ticket-corpus/v3?versionId=mnop..."
hashes:
  - alg: SHA-256
    content: "ef12..."              # hash of the manifest, not of every row
properties:
  - name: ml:dataset:row-count
    value: "2415673"
  - name: ml:dataset:language
    value: "en"
  - name: ml:dataset:temporal-coverage
    value: "2023-01-01..2026-09-30"
  - name: ml:dataset:consent-basis
    value: "Legitimate interest — see DPIA 2026-Q3 § 4.2"
  - name: ml:dataset:pii-coverage
    value: "mod-108 DLP profile training_data_tickets_v1 at ef34..."
  - name: ml:dataset:intended-use
    value: "English-language customer support classification"
  - name: ml:dataset:restrictions
    value: "No commercial redistribution; no secondary training without DP review"
```

Three design rules carry most of the weight:

1. **Hash the manifest, not the data.** A dataset of
   millions of rows has no stable per-row hash across
   retrievals; a manifest listing (`path → file hash`)
   does. The manifest is a few MB and belongs in content-
   addressed storage (chapter 02 ORAS pattern).
2. **Pin the retrieval, not the search.** `s3://data/
   ticket-corpus/v3?versionId=...` is a pin;
   `s3://data/ticket-corpus/latest/` is a search.
3. **Capture the governance context.** Consent basis,
   intended use, restrictions. The classical SBOM has no
   row for "no commercial redistribution" because software
   licences live in a different taxonomy; dataset governance
   properties are custom but mandatory for most regulated
   programmes.

Edge case — **mixed corpora**. If a training run mixes
multiple sub-corpora with different licences and consent
bases, each sub-corpus is its own ML-BOM dataset component.
A composed dataset component references them in
`dependencies`. Do not flatten; the DMCA / consent-withdrawal
drill specifically needs sub-corpus granularity.

Edge case — **upstream datasets you did not create**.
When training on a public dataset (The Pile, LAION, HF
Datasets), the dataset component names the upstream
supplier and includes the HF revision SHA or an archive
digest. If the upstream dataset itself has an ML-BOM /
dataset-card, cite it (`externalReferences.type: formulation`).

---

## Base-model and fine-tuning components

A base model entry looks like a dataset entry but with
`type: machine-learning-model`:

```yaml
type: machine-learning-model
bom-ref: model:distilbert-base-uncased@6cdc0aad3
name: distilbert-base-uncased
version: "6cdc0aad3"           # HF commit SHA
supplier:
  name: "Hugging Face — distilbert org"
licenses:
  - license: { id: Apache-2.0 }
externalReferences:
  - type: distribution
    url: "https://hf.co/distilbert/distilbert-base-uncased/tree/6cdc0aad3"
  - type: vcs
    url: "https://github.com/huggingface/transformers"
hashes:
  - alg: SHA-256
    content: "<digest of the safetensors file>"
properties:
  - name: ml:intake:scan-attestation
    value: "modelscan+safetensors cosign-attestation sha256:cafe..."
  - name: ml:intake:safety-eval
    value: "mod-110 chapter-05 intake run 2026-09-14 (pass)"
```

The two org-specific properties (`ml:intake:scan-
attestation`, `ml:intake:safety-eval`) are what chapter 05's
intake runbook produces. The ML-BOM references them so a
consumer can prove the base model passed the intake gate
*before* this training run started.

Fine-tuning components are the same shape:

```yaml
type: machine-learning-model
bom-ref: adapter:fraud-lora@12
name: fraud-domain-lora
version: "12.0.0"
supplier: { name: "Internal — Fraud ML team" }
licenses: [{ license: { id: Apache-2.0 } }]
properties:
  - name: ml:adapter:rank
    value: "16"
  - name: ml:adapter:trained-on
    value: "data:ticket-corpus@v3"
```

If a model is built from a chain — base → instruction tune →
RLHF — each link is its own component and the dependency
graph records the chain explicitly.

---

## Licence obligations

Software SBOMs standardise licence identifiers via SPDX.
Model and dataset licensing is messier:

- **Permissive software licences** (Apache-2.0, MIT, BSD-3)
  are usable on model code and on some weight files.
- **OpenRAIL / RAIL / BigScience OpenRAIL** licences
  (introduced for Stable Diffusion and BLOOM) impose
  **use-based restrictions**: the model may be used, but
  not for specified harmful purposes. These restrictions
  propagate downstream.
- **Research-only licences** on some public weights (older
  LLaMA variants, academic releases) prohibit commercial
  use.
- **Dataset-specific user agreements** on HF Datasets or
  Kaggle (gated access, no-redistribution, attribution
  terms).
- **Custom "community" licences** on recent frontier models
  (LLaMA 3, 4; Qwen; others) with scale thresholds, named-
  entity restrictions, or acceptable-use policies. These
  change over time; the ML-BOM pins the licence text at the
  version used.

The ML-BOM carries, per component:

- The **licence identifier** or, when no SPDX identifier
  exists, a licence `name` and a `url` to the licence text.
- A **licence hash** when the terms could change under the
  URL. For custom RAIL variants: hash the licence file
  retrieved at intake and store the hash.
- An **obligations summary** (optional but recommended) as
  a property, generated at intake, that the licence-review
  gate (chapter 05) populated:

  ```yaml
  properties:
    - name: ml:license:obligations
      value: >-
        Must retain attribution to Meta Llama;
        prohibits deployment above 700M MAU without
        separate licence;
        inherits acceptable-use policy at <URL>.
  ```

The licence-obligations property is what a product-counsel
reviewer sees first when the ML-BOM is pulled for a release.
It is a *summary*; the authoritative text is the licence
file linked and hashed.

The licence graph composes: a model fine-tuned on data
licensed CC-BY-SA from a base model licensed Apache-2.0
inherits the stronger constraint. The ML-BOM makes this
query answerable; it does not perform it. The
`license-obligations-review` policy in mod-109 chapter 04
is where the composition logic lives.

---

## Generation workflow

ML-BOMs *reconstructed* after the fact are usually incomplete.
The pipeline forgets about the eval bundle the data scientist
ran once from their laptop; the dataset manifest is lost
when the notebook is cleaned; the base-model revision becomes
"we used the HF latest from around that time". The output is
a plausible document, not an auditable one.

The reliable pattern is **generate at build time, from
pipeline metadata**:

1. The training pipeline reads a **declarative pipeline
   spec** that names, by content-addressed reference, every
   input: datasets, base model, adapters, lockfiles,
   container image, eval bundle, hyperparameters.
2. A **build-platform component** — not a user-written
   script — walks the resolved spec after input provisioning
   and emits an ML-BOM draft containing exactly the inputs
   the platform observed.
3. The ML-BOM draft is **merged with model-card content**
   from the trainer (metrics, intended use, limitations) via
   an in-pipeline step with no network access.
4. The resulting ML-BOM is **content-addressed, signed,
   and attached as an attestation to the model artefact**
   (chapter 02):

   ```bash
   cosign attest \
     --predicate ml-bom.json \
     --type cyclonedx \
     --oidc-issuer <platform-oidc> \
     registry.company.com/models/fraud-classifier@sha256:abcd...
   ```

Why this ordering matters:

- The ML-BOM is signed by the **build-platform identity**,
  not by the data scientist. The SLSA L3 argument from
  chapter 01 — "the build definition should not be able to
  lie about what it ran" — applies to the ML-BOM too.
- The ML-BOM references the signed-eval-scorecard
  attestation by hash, not by prose summary. A consumer
  verifying the model's attestations can walk from the
  model → ML-BOM → eval bundle, resolving each hash to a
  separately signed document.
- Build-platform observation of input provisioning is what
  makes the ML-BOM's dataset digests trustworthy. If the
  trainer script self-reports which dataset it read, an
  attacker who owns the script owns the ML-BOM; chapter 01
  SLSA L3 is the hardening for this.

### A minimal generator schema

The input the generator consumes:

```yaml
# pipeline-spec.resolved.yaml
run_id: fraud-classifier-run-20261004-abc123
model_name: fraud-classifier
model_version: "42.0.0"
base_model:
  ref: hf://distilbert/distilbert-base-uncased@6cdc0aad3
  sha256: "..."
  license: Apache-2.0
training_data:
  - ref: s3://data/ticket-corpus/v3
    version_id: "mnop..."
    manifest_sha256: "ef12..."
    license: Internal-Confidential
    row_count: 2415673
    consent_basis: "Legitimate interest; DPIA 2026-Q3"
dependencies:
  requirements_lock_sha256: "lockabc..."
  container_image_digest: "sha256:cuda123..."
evaluation:
  bundle_ref: evalbundle:fraud-eval@12
  bundle_sha256: "evalhash..."
  scorecard_attestation: "..."
hyperparameters:
  seed: 42
  epochs: 3
  learning_rate: 2e-5
output:
  artifact_digest: sha256:abcd...
  licenses: [Apache-2.0]
```

A ~200-line Python script walks this file and emits a
compliant CycloneDX 1.6 ML-BOM. The content comes from the
pipeline; the schema compliance comes from the generator.
There is no judgement in the generator — a mismatched or
missing input is a build failure, not a BOM gap filled by
heuristic.

### Tooling

- **`cdxgen`** (OWASP CycloneDX project) generates CycloneDX
  SBOMs for software projects; its ML extension support is
  evolving. Useful for the *dependencies* section of the
  ML-BOM.
- **Syft** (Anchore) generates CycloneDX SBOMs for container
  images and OS packages. The container-side SBOM is
  referenced (`externalReferences`) by the ML-BOM rather
  than duplicated.
- **Trivy** (Aqua) is an SBOM + vuln scanner alternative to
  Syft+Grype.
- **spdx-tools / spdx-python-tools** for SPDX 3.0 output.
- **AIBOM Generator (manifests from CycloneDX community)**
  and **model-card toolkits** — verify project maturity;
  this ecosystem is young.
- **For the ML-specific fields**, there is often no
  off-the-shelf generator yet. A small in-house generator
  that writes to the CycloneDX / SPDX schema is the common
  pattern.

---

## Consuming an ML-BOM

A signed ML-BOM is a document. A programme that *uses* it
derives real value from supplying the ML-BOM to concrete
workflows:

### Deployment admission

The sigstore-policy-controller policy from chapter 02 is
extended to require an ML-BOM attestation of the expected
`predicateType` (CycloneDX) and to apply content policy:

```yaml
attestations:
  - name: mlbom-present-and-licence-reviewed
    predicateType: https://cyclonedx.org/bom
    policy:
      type: cue
      data: |
        predicate: {
          bomFormat: "CycloneDX"
          components: [...{
            type: =~"^(machine-learning-model|data)$"
            licenses: [...{ license: _ }]   // every component has a licence
          }]
        }
```

Policy content worth enforcing at admission:

- Every `machine-learning-model` and `data` component has a
  licence.
- The base-model component's `supplier.name` is on the
  org's approved-supplier list (chapter 06 register).
- Every `data` component has a `consent-basis` property.
- The licence-obligations property is populated for any
  component under a RAIL / custom-community licence.

### Vulnerability and takedown response

An ML-BOM indexed in a central store makes this a query:

- "Which production models were trained on dataset X?"
  `SELECT model FROM mlbom WHERE components CONTAINS data@X;`
- "Which production models depend on base model Y at the
  pre-safety-eval revision?"
  `SELECT model FROM mlbom WHERE components CONTAINS model@Y
   AND components.ml:intake:safety-eval = 'pass';`
- "Which models fine-tuned on a dataset currently flagged
  for consent revocation?"

The index is a derived view of the attestation store; the
underlying truth is the signed ML-BOMs. Rebuild the view
rather than editing it.

### DSAR and erasure

Chapter 03 of mod-108 covers data-subject-access and erasure
end-to-end; the ML-BOM is the index. When a subject requests
erasure, the question "which trained models carried their
record" is answered first against the training-time ML-BOMs,
then against the DLP coverage logs. Models for which the
subject's record appears get re-training considered under the
chapter-108 DP-SGD and retraining-cadence policies.

### Licence review and procurement

Legal / procurement reads a product's ML-BOM at release to
confirm the licence obligations attached to the deployed
system. The licence-obligations property is first; the
actual licence files, pinned by hash and link, are second.
This is a standing input to the chapter-109 Clause 8.3
assessment and the EU AI Act Article 11 technical
documentation.

### Audit

An ISO 42001 Clause 7.5 / SOC 2 CC9.2 auditor asks "show me
the inventory of training data and models for this
deployment." The ML-BOM is the inventory. The signed
attestation is the evidence it existed at the time of
build, not after the fact.

---

## Standard failure modes

- **ML-BOM constructed after the fact.** The data scientist
  writes it from memory a week later. Fields are plausible
  but unverifiable. Fix: generate at build time from the
  resolved pipeline spec; a missing input is a build error.
- **Dataset entries that point to mutable URLs.** `s3://.../
  latest` or an unpinned HF revision. Fix: content-addressed
  references only — snapshot IDs, S3 versionIds, HF commit
  SHAs, manifest hashes.
- **PII inside the ML-BOM.** Someone embedded a sample row
  for "illustration". The ML-BOM is a signed, distributable
  artefact; the sample row is now distributed. Fix: dataset
  component carries counts and schema, not values.
- **Licence rows left blank or set to "see model card".**
  Admission policy cannot enforce blank fields. Fix: every
  component has a `licenses` entry; "proprietary / internal"
  is a valid entry when the licence is internal.
- **Base-model revision pinned to a branch, not a SHA.**
  `hf://distilbert/distilbert-base-uncased@main` is a
  search; `@6cdc0aad3` is a pin. Fix: resolver converts
  branch references to SHA at the intake gate.
- **ML-BOM and model drift apart.** The model artefact is
  rebuilt but the attestation is not re-emitted; the ML-BOM
  in the registry describes a prior build. Fix: attestations
  are bound to the artefact digest; cosign's by-digest
  signing enforces this; the pipeline must re-attest on
  every rebuild.
- **One ML-BOM per *model name*, not per *version*.** The
  registry stores a single `fraud-classifier.cdx.json` that
  overwrites per build. Fix: ML-BOM is content-addressed and
  stored per version; the attestation lives in the
  registry's attestation companion tag.
- **Ingested without signing.** The intake pipeline pulls a
  base model, emits an ML-BOM entry for it, but does not
  sign the resulting attestation (or signs with a shared
  identity). Fix: intake pipeline has its own signing
  identity; its signatures are what downstream admission
  policies accept.
- **CycloneDX and SPDX duplicates diverging.** Both formats
  are produced from independent paths and the two differ.
  Fix: a single build-time generator writes to both; the
  canonical content comes from the pipeline spec.
- **ML-BOM consumed only at audit time.** The document
  exists but nothing in the admission path reads it. Fix:
  the sigstore-policy-controller rules (above) consume the
  ML-BOM as a required attestation.
- **Agent / RAG config left out of the ML-BOM.** For
  agentic systems (mod-107), the system prompt, tool
  registry, and index config drive behaviour. Fix: include
  them as components with their own hashes and licences.

---

## Summary

- A **classical SBOM** inventories software components; an
  **ML-BOM / AI-BOM** extends that inventory with datasets,
  base models, fine-tuning components, eval bundles, and
  licence obligations that software SBOMs cannot describe.
- **CycloneDX** (OWASP, with its ML extension) and **SPDX
  3.0** (Linux Foundation / ISO, with its AI and Dataset
  profiles) are the two schemas. Choose per programme; dual
  production is possible.
- The content classes that belong in an ML-BOM for a
  deployed model: the model artefact itself, the base
  model, training datasets (sub-corpora separately),
  fine-tuning components, third-party dependencies,
  evaluation suites, and — for agents — the system prompt
  and tool registry.
- **Dataset entries** are the hardest to get right: hash
  the manifest, pin the retrieval, capture governance
  context, keep PII values out.
- **Licence obligations** are a first-class row. OpenRAIL
  and custom-community licences compose; the ML-BOM makes
  the composition queryable; mod-109 chapter 04 policies
  evaluate it.
- **Generate at build time from pipeline metadata**, sign
  with the build-platform identity, attach as a signed
  attestation to the model artefact. Reconstructed ML-BOMs
  are plausible but unauditable.
- **Admission, vulnerability triage, DSAR, licence review,
  and audit** are the workflows that make the ML-BOM
  useful. Documents without consumers are decoration;
  policy consumers are what turn the ML-BOM into a control.
