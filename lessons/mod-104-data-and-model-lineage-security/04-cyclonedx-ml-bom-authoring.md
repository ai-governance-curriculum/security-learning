# Chapter 04 — CycloneDX ML-BOM: Authoring a Bill of Materials for a Model

> **Note on AI-assisted content.** CycloneDX is versioned; the ML-BOM
> extension has evolved rapidly. Verify component types, licence
> expression syntax, and schema element names against the current
> [cyclonedx.org/specification](https://cyclonedx.org/specification/)
> and [ecma.github.io/ECMA-424](https://ecma.github.io/) documents.
> See [`resources.md`](./resources.md).

---

## Why this chapter exists

Chapter 03 authored the SLSA provenance predicate — what the
signature is over, describing how the artifact was built. This
chapter authors the **ML-BOM** — the standalone, canonical,
schema-defined document listing every component that went into
a model.

The specific failure mode this chapter is written to prevent:

> A team ships a fraud-detection model to production. The base
> model was pulled from Hugging Face two years ago. The
> fine-tuning data set includes rows from a customer table that
> the data-governance team has since retention-deleted. Two
> transitive Python dependencies used at training are now known
> to contain CVEs. One of the base model's fine-tunes was
> released under CC-BY-NC (non-commercial). A regulator asks the
> team to produce a component list for the deployed model. The
> team generates something ad hoc that references the training
> code but no data, no upstream model, no dependencies, and no
> licences. The regulator asks for a machine-readable version
> that can be diffed against the previous model. The team has
> nothing.

The **ML-BOM** (Machine Learning Bill of Materials) is the
schema-defined answer. It is:

- **Canonical** — one document per model, generated at build
  time, addressable by digest.
- **Machine-readable** — CycloneDX 1.6 JSON, consumable by
  scanners, policy engines, and lineage tools without parsing
  prose.
- **Schema-versioned** — components have declared types,
  licences use SPDX expressions, external references have
  declared types.
- **Signed** — the ML-BOM is attached to the model artifact as
  an in-toto attestation (`https://cyclonedx.org/bom`),
  signed by the same cosign keyless flow as chapter 02–03.

You leave this chapter able to:

- Read the CycloneDX 1.6 ML-BOM shape and know which extension
  component types to use for models, datasets, feature sets,
  and standard software components.
- Enumerate for a target model the full component graph —
  base models, fine-tunes, adapters, datasets, evaluation
  sets, tokenizers, dependencies — and populate the ML-BOM.
- Attach the ML-BOM to a model artifact as a signed in-toto
  attestation.
- Verify the ML-BOM at admission time (completeness, required
  types, licence policy, digest binding).
- Diff two ML-BOMs to answer "what changed between
  `fraud-v41` and `fraud-v42`".

---

## SBOM, ML-BOM, and AI-BOM — the naming

The vocabulary is unsettled. Three terms in current use:

- **SBOM** (Software Bill of Materials) — a general-purpose
  bill of materials for software. Formats: CycloneDX and SPDX.
  US Executive Order 14028 and subsequent NIST / CISA guidance
  drove wide SBOM adoption.
- **ML-BOM** — a bill of materials focused on ML components:
  models, datasets, feature sets, ML frameworks. CycloneDX
  introduced dedicated component types for these starting in
  1.5 (verify the exact minor version and component-type
  spellings against the current spec).
- **AI-BOM** — sometimes used interchangeably with ML-BOM;
  sometimes broader, including data-flow diagrams, deployment
  descriptors, and system-card material. No stable spec at
  drafting; use the term only when the reader knows what you
  mean by it.

This chapter uses **ML-BOM** and picks **CycloneDX** as the
concrete format because:

- CycloneDX has explicit ML-component support and an ecosystem
  of tooling that consumes it (`cyclonedx-cli`,
  `dependency-track`, Gatekeeper external-data providers).
- CycloneDX's `formulation` block can express the training
  formula (inputs, task, resulting artifact) without needing a
  separate document.
- CycloneDX composes with the in-toto attestation shape
  (`predicateType: https://cyclonedx.org/bom`) that the
  admission gate already knows how to fetch.

SPDX is a valid alternative for organisations already
standardised on SPDX for their software SBOMs; the pattern in
this chapter transfers.

---

## The CycloneDX 1.6 ML-BOM shape (annotated)

A minimal ML-BOM for a fine-tuned fraud-detection model. Verify
field names and enum values against the current CycloneDX schema
before use in production.

```json
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:6b8a7f2c-0e14-4c53-a3b1-2f9b0e7c9b2c",
  "version": 1,
  "metadata": {
    "timestamp": "2026-04-01T14:21:44Z",
    "tools": {
      "components": [
        {
          "type": "application",
          "name": "acme-mlbom-generator",
          "version": "1.4.0"
        }
      ]
    },
    "component": {
      "bom-ref": "pkg:acme-models/fraud@v42",
      "type": "machine-learning-model",
      "name": "fraud",
      "version": "v42",
      "description": "Fraud-scoring model fine-tuned from base-transformer-v3",
      "purl": "pkg:acme-models/fraud@v42",
      "hashes": [
        {
          "alg": "SHA-256",
          "content": "abc123..."
        }
      ],
      "licenses": [
        { "license": { "id": "Apache-2.0" } }
      ],
      "modelCard": {
        "modelParameters": {
          "task": "classification",
          "architectureFamily": "transformer",
          "modelArchitecture": "distilbert-base-uncased",
          "datasets": [
            { "ref": "pkg:acme-datasets/fraud@v2026-03-31" }
          ],
          "inputs": [
            {
              "format": "text",
              "description": "Merchant description + transaction amount"
            }
          ],
          "outputs": [
            {
              "format": "float",
              "description": "Fraud probability, 0.0–1.0"
            }
          ]
        },
        "quantitativeAnalysis": {
          "performanceMetrics": [
            {
              "type": "roc-auc",
              "value": "0.94",
              "slice": "overall",
              "confidenceInterval": { "lowerBound": "0.93", "upperBound": "0.95" }
            }
          ]
        },
        "considerations": {
          "ethicalConsiderations": [
            {
              "name": "geographic-bias",
              "description": "Model retrained without EEA rows per 2026 policy."
            }
          ]
        }
      }
    }
  },
  "components": [
    {
      "bom-ref": "pkg:acme-models/base-transformer@v3",
      "type": "machine-learning-model",
      "name": "base-transformer",
      "version": "v3",
      "purl": "pkg:acme-models/base-transformer@v3",
      "hashes": [{ "alg": "SHA-256", "content": "789..." }],
      "licenses": [{ "license": { "id": "Apache-2.0" } }],
      "externalReferences": [
        {
          "type": "vcs",
          "url": "https://huggingface.co/distilbert-base-uncased"
        }
      ]
    },
    {
      "bom-ref": "pkg:acme-datasets/fraud@v2026-03-31",
      "type": "data",
      "name": "fraud-training-snapshot",
      "version": "v2026-03-31",
      "purl": "pkg:acme-datasets/fraud@v2026-03-31",
      "hashes": [{ "alg": "SHA-256", "content": "bbb..." }],
      "properties": [
        { "name": "row_count", "value": "12403927" },
        { "name": "sensitive_class", "value": "pii" },
        { "name": "region_filter", "value": "excludes-eea" }
      ],
      "licenses": [{ "license": { "name": "internal-only" } }]
    },
    {
      "bom-ref": "pkg:acme-features/fraud@materialisation-2026-03-31T18:00Z",
      "type": "data",
      "name": "fraud-feature-set",
      "version": "materialisation-2026-03-31T18:00Z",
      "hashes": [{ "alg": "SHA-256", "content": "ccc..." }]
    },
    {
      "bom-ref": "pkg:pypi/torch@2.3.1",
      "type": "library",
      "name": "torch",
      "version": "2.3.1",
      "purl": "pkg:pypi/torch@2.3.1",
      "hashes": [{ "alg": "SHA-256", "content": "ddd..." }],
      "licenses": [{ "license": { "id": "BSD-3-Clause" } }]
    },
    {
      "bom-ref": "pkg:pypi/transformers@4.41.2",
      "type": "library",
      "name": "transformers",
      "version": "4.41.2",
      "purl": "pkg:pypi/transformers@4.41.2",
      "licenses": [{ "license": { "id": "Apache-2.0" } }]
    }
  ],
  "dependencies": [
    {
      "ref": "pkg:acme-models/fraud@v42",
      "dependsOn": [
        "pkg:acme-models/base-transformer@v3",
        "pkg:acme-datasets/fraud@v2026-03-31",
        "pkg:acme-features/fraud@materialisation-2026-03-31T18:00Z",
        "pkg:pypi/torch@2.3.1",
        "pkg:pypi/transformers@4.41.2"
      ]
    }
  ],
  "compositions": [
    {
      "aggregate": "complete",
      "assemblies": ["pkg:acme-models/fraud@v42"],
      "dependencies": [
        "pkg:acme-models/base-transformer@v3",
        "pkg:acme-datasets/fraud@v2026-03-31",
        "pkg:acme-features/fraud@materialisation-2026-03-31T18:00Z",
        "pkg:pypi/torch@2.3.1",
        "pkg:pypi/transformers@4.41.2"
      ]
    }
  ]
}
```

The document's shape at a glance:

- `metadata.component` — the primary component the BOM is about
  (the model itself). Includes the `modelCard` subobject with
  quantitative metrics and ethical considerations.
- `components[]` — every other component: upstream models,
  datasets, features, libraries.
- `dependencies[]` — the DAG. Which components depend on which.
- `compositions[]` — completeness declarations. `aggregate:
  complete` claims the BOM is exhaustive for this assembly.

Every component has:

- `bom-ref` — a document-local ID (usually a `pkg:` URL).
- `type` — the component type (`machine-learning-model`,
  `data`, `library`, `framework`, `application`).
- `hashes` — cryptographic digest.
- `licenses` — SPDX expression, custom name, or licence file
  ref.
- Optionally `externalReferences` — URLs to VCS, model
  registry, documentation.

---

## The component classes an ML-BOM must cover

Complete ML-BOMs for typical models cover all of the following.
Enumerate them explicitly for each model; leaving a class out is
how the "we generated a BOM but it's incomplete" trap happens.

| Class | Type in CycloneDX | Notes |
| --- | --- | --- |
| **Primary model** | `machine-learning-model` | The artifact the BOM is about. `metadata.component`. |
| **Base / upstream model(s)** | `machine-learning-model` | Foundation model pulled from Hugging Face, an internal base, a vendor model. Include vendor-supplied signature or attestation via `externalReferences` if any. |
| **Fine-tune / adapter chain** | `machine-learning-model` | Each intermediate fine-tune between base and final model, plus any LoRA / adapter deltas. Chain them via `dependencies[]`. |
| **Training dataset snapshot** | `data` | Snapshot digest, row count, sensitivity class, region filters — properties as needed for governance queries. |
| **Feature-set materialisation** | `data` | The materialised feature set the training run consumed. |
| **Evaluation datasets** | `data` | Every eval set the model was evaluated on (`evaluation-set` or similar sub-type). Chapter 05 uses these for evidence-linked claims in model cards. |
| **Tokenizer / preprocessor** | `library` or `machine-learning-model` per the tokenizer's nature | Sentencepiece vocabularies, BPE merge tables, custom preprocessors. |
| **ML framework versions** | `framework` or `library` | `torch`, `tensorflow`, `jax`, `transformers`, `peft`, and every direct training dependency pinned to a version and hash. |
| **Container base image (of the trainer)** | `container` | The training container's base image, so downstream CVE scanning can identify OS-level exposures at training time. |
| **Container base image (of the serving pod)** | `container` | Similarly for the serving container. |
| **Third-party services with side effects at training** | `service` | If training called out to a labelling service, a hosted embeddings API, etc., record it (with the caveat that content-based provenance for a service call is impossible). |

The mod-103 admission gate's `requiredComponentTypes` parameter
enumerates which of these must appear before deployment is
allowed.

---

## Generating the ML-BOM in the training pipeline

Two generation modes; the choice depends on how automatable the
pipeline's dependency capture is.

### Mode A — generator library at build time

At the end of training, a generator library walks the pipeline
runtime and produces the CycloneDX document:

- Reads the `pyproject.toml` / `requirements.lock` /
  `poetry.lock` for pinned dependencies with digests.
- Reads the training-config for dataset URIs and version tags.
- Reads the pipeline runtime for base-model reference and
  tokenizer.
- Reads the training output for the resulting model digest.
- Writes `mlbom.json` in CycloneDX 1.6 JSON.

Reference tooling:

- `cyclonedx-python` — the CycloneDX Python library, used for
  generating BOMs from Python environments.
- `cyclonedx-cli` — CLI for validation, format conversion, and
  merging.
- Vendor tooling — `syft` for container images; various ML-BOM
  scanners emerging (verify current tooling landscape).

An abbreviated example:

```python
from cyclonedx.model.bom import Bom
from cyclonedx.model.component import Component, ComponentType
from cyclonedx.model import HashType, HashAlgorithm
from packageurl import PackageURL

bom = Bom()

# Primary component
model = Component(
    bom_ref="pkg:acme-models/fraud@v42",
    type=ComponentType.MACHINE_LEARNING_MODEL,
    name="fraud",
    version="v42",
    purl=PackageURL.from_string("pkg:acme-models/fraud@v42"),
    hashes=[HashType.from_composite_str(f"SHA-256:{MODEL_DIGEST}")],
)
bom.metadata.component = model

# Base model
base = Component(
    bom_ref="pkg:acme-models/base-transformer@v3",
    type=ComponentType.MACHINE_LEARNING_MODEL,
    name="base-transformer",
    version="v3",
    purl=PackageURL.from_string("pkg:acme-models/base-transformer@v3"),
    hashes=[HashType.from_composite_str(f"SHA-256:{BASE_DIGEST}")],
)
bom.components.add(base)

# Dataset snapshot
ds = Component(
    bom_ref="pkg:acme-datasets/fraud@v2026-03-31",
    type=ComponentType.DATA,
    name="fraud-training-snapshot",
    version="v2026-03-31",
    hashes=[HashType.from_composite_str(f"SHA-256:{DATASET_DIGEST}")],
)
bom.components.add(ds)

# Dependency edges
bom.register_dependency(model, [base, ds])

# ... library components from pyproject.lock ...

with open("mlbom.json", "w") as f:
    f.write(bom.serialize().to_json())
```

### Mode B — declarative source of truth + generator on top

For platforms with strict declarative build definitions
(Kubeflow Pipelines DSL, Argo Workflows spec), extract the
dependencies directly from the pipeline spec plus the lockfiles;
generate the BOM from the resulting graph.

Mode B is more auditable (the BOM inputs are declarative
artifacts) but requires the pipeline platform to expose the
dependency graph in a way the generator can consume. Kubeflow
Pipelines' `Lineage API` and Vertex AI's `MetadataStore` are two
sources; verify their current schemas.

### Attach the ML-BOM as a signed attestation

Same shape as chapter 03's SLSA attestation, but with a
CycloneDX predicate:

```
cosign attest \
    --predicate mlbom.json \
    --type cyclonedx \
    registry.acme.internal/models/fraud@sha256:${MODEL_DIGEST}
```

`--type cyclonedx` maps to `predicateType:
https://cyclonedx.org/bom`. The attestation is signed by the
CI's keyless identity, uploaded to Rekor, and attached to the
artifact.

Multiple attestations per artifact are supported and normal:
a SLSA provenance attestation, a CycloneDX ML-BOM attestation,
a vulnerability-scan attestation. Each has its own
predicateType; the admission gate fetches by predicateType.

---

## Verifying the ML-BOM at admission

Mod-103 chapter 06 defines the shape of the admission gate.
The ML-BOM verification has more moving parts than the signature
verification because the BOM has policy-controlled content.

The verifier checks:

1. **Attestation signature.** DSSE envelope signature verifies
   against the pinned trust root (chapter 02 flow).
2. **Predicate type.** Exactly `https://cyclonedx.org/bom`.
3. **Subject digest.** Matches the deployed artifact digest.
4. **Schema version.** `specVersion` is on the accepted list
   (e.g., 1.5 and 1.6 accepted; older versions rejected).
5. **Freshness.** `metadata.timestamp` is within the freshness
   window from mod-103 (e.g., 30 days).
6. **Required component types.** Every type on the policy's
   `requiredComponentTypes` list is present at least once.
7. **Aggregate completeness.** `compositions[].aggregate ==
   "complete"` for the primary assembly (rejects partial BOMs
   masquerading as complete).
8. **Licence policy.** No component has a licence on the
   denied list (chapter 09 governance authors the licence
   allow/deny lists).
9. **Optional: dataset region policy.** Datasets with
   `sensitive_class: pii` and `region_filter: includes-eea`
   might be denied per an internal data-governance rule.

A concrete Rego snippet (Gatekeeper syntax):

```rego
mlbom_ok(image, params) {
  resp := external_data({
    "provider": "mlbom-fetcher",
    "keys": [image],
    "parameters": params
  })
  bom := resp.responses[_][1]
  bom.specVersion == params.acceptedSchemaVersions[_]
  bom.metadata_age_days <= params.maxAgeDays
  all_types_present(bom, params.requiredComponentTypes)
  aggregate_complete(bom)
  no_denied_licenses(bom, params.deniedLicenses)
}

all_types_present(bom, types) {
  every t in types {
    count([c | c := bom.components[_]; c.type == t]) > 0
  }
}

aggregate_complete(bom) {
  some comp
  comp := bom.compositions[_]
  comp.aggregate == "complete"
}

no_denied_licenses(bom, denied) {
  count([c | c := bom.components[_];
             lic := c.licenses[_];
             denied[_] == lic.license.id]) == 0
}
```

The `mlbom-fetcher` provider is the piece that reaches into the
OCI registry to pull the attestation, verifies its signature,
decodes the predicate, and returns the parsed BOM.

---

## Diffing ML-BOMs — the "what changed" question

The routine question after a model incident: "what changed
between `fraud-v41` and `fraud-v42`". The ML-BOM answers this
precisely.

Two BOMs, two versions of the same model, structured diff:

- **Added components** — the new model version pulled in a new
  dependency, dataset, or feature. Investigate.
- **Removed components** — the new version dropped a previous
  dependency. Verify intentional.
- **Version changes** — the same component moved to a new
  version. Check for CVEs in the delta.
- **Digest changes for same-version components** — usually a
  bug (a "same version" component's digest should not change);
  investigate.
- **Licence changes** — a component's licence changed between
  versions (upstream re-licensing). Governance signal.

Tooling: `cyclonedx-cli diff bom-v41.json bom-v42.json` (verify
current CLI syntax); several vendor tools (Anchore, Snyk,
Dependency-Track) consume CycloneDX and produce diffs.

The diff is what appears in the model card's changelog section
(chapter 05).

---

## When the generator cannot capture a component

Some components cannot be captured mechanically:

- **Human labelling.** If humans labelled the training set,
  the labelling process is a component in the loosest sense.
  Record the labelling protocol document, the labelling service
  (as a `service` component), and the labelling batch
  identifiers as properties on the dataset component. Do not
  attempt to "sign" a labelling process it does not have a
  digestable output.
- **Vendor black-box services.** If training called a
  proprietary embeddings API, record the service, its version
  identifier if any, the date range of calls, and a summary of
  what was sent. This is deliberately weak; the alternative is
  to omit the dependency, which is worse.
- **Prompt-tuning inputs.** For LLMs, the seed prompts or
  instruction templates are components. Record them by digest
  and by content location (a signed prompt-library reference).

The general rule: **the ML-BOM does not lie about completeness**.
If a component cannot be digested, record it with the best
identifier available and mark the composition `aggregate:
incomplete_first_party` (or the equivalent CycloneDX enum for
"first-party is complete, third-party is opaque").

---

## What this chapter does not cover

- **Publishing model cards.** The ML-BOM is machine-readable
  provenance; the model card is the human-readable narrative
  that consumes it. Chapter 05.
- **Licence-obligation compliance.** Naming the licences is
  step one. Actually complying with obligations (attribution,
  copyleft, non-commercial-use) is a legal-and-governance
  workflow, not this chapter's — mod-109.
- **CVE and vulnerability data.** The BOM lists what components
  are present; a scanner cross-references CVE databases to
  produce vulnerability records. Grype, Trivy, and
  Dependency-Track consume CycloneDX to do this. The
  admission gate's "scan clean" check (mod-103 chapter 06 gate
  3) is where the scanner output is enforced.
- **SBOM for the container image alone.** A separate CycloneDX
  document generated from the OCI image (e.g., via `syft`) is
  useful and complementary. The ML-BOM is *about the model
  artifact*; the container SBOM is *about the container it
  runs in*. Both should exist.

---

## The mistakes this chapter is trying to prevent

- **Generating a BOM but omitting dataset components.** A BOM
  with framework versions and no dataset references answers
  half the question. Datasets are components.
- **Claiming `aggregate: complete` when it isn't.** The
  completeness claim is auditable. If the BOM is missing a
  vendor black-box, declare `incomplete` and name the gap.
- **Regenerating the BOM at deploy time from the deployed
  image.** The BOM must be generated at *build* time, when the
  dependency graph is knowable. Deploy-time regeneration can
  see the container but not the training-time inputs.
- **Skipping BOM signing.** An unsigned BOM is a document that
  can be rewritten in the registry. Sign every BOM as an
  in-toto attestation.
- **Version-drift on the CycloneDX schema.** Pin accepted
  versions in the admission policy. Parsers assume schema
  guarantees; drift breaks them silently.
- **Free-text licences.** SPDX expressions are machine-
  matchable; free-text licence names ("Apache 2 sort of")
  defeat policy engines. Use SPDX IDs.
- **One monolithic BOM for a family of models.** Each model
  version gets its own BOM. Family-level documentation belongs
  in the model card, not the machine-readable BOM.

---

## Summary

- The ML-BOM is a CycloneDX 1.6 (or later) JSON document
  listing every component that went into a model: primary
  model, base and fine-tune chain, dataset snapshot, feature
  set, tokenizer, ML framework libraries, container base
  images, and third-party services with training-time side
  effects.
- Generated at build time by a generator library reading the
  pipeline runtime and lockfiles; attached to the model
  artifact as a signed in-toto attestation
  (`predicateType: https://cyclonedx.org/bom`) via `cosign
  attest`.
- Verified at admission time (mod-103 chapter 06 gate 2) for
  presence, schema version, freshness, required component
  types, aggregate completeness, and licence policy.
- Diffing two ML-BOMs answers the routine "what changed
  between versions" question and feeds the model-card
  changelog (chapter 05).
- Components that cannot be digested (labelling processes,
  vendor black-boxes) are recorded with the best identifier
  available and the composition marked `incomplete` — the BOM
  never lies about completeness.
- The ML-BOM plus the SLSA provenance predicate (chapter 03)
  plus the signature (chapter 02) is the full technical
  evidence set the mod-103 admission gate consumes and mod-109
  governance retains as compliance evidence.
