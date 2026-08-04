# Chapter 03 — SLSA v1.0 and in-toto Provenance for ML Builds

> **Note on AI-assisted content.** SLSA is at v1.0 (with v1.1
> in-progress at the time of drafting); in-toto attestations use the
> DSSE envelope. Verify the current spec version, predicate schema,
> and field naming at [slsa.dev](https://slsa.dev) and
> [in-toto.io](https://in-toto.io/) before quoting field names in
> production. See [`resources.md`](./resources.md).

---

## Why this chapter exists

Chapter 02 authored the signature that admission-time verifies.
This chapter authors **what the signature is over** — the SLSA
provenance predicate — and the envelope (in-toto DSSE) that carries
it.

The specific failure mode this chapter is written to prevent:

> A team adopts cosign. Every model artifact is signed. At audit,
> a regulator asks "which commit of your training code produced
> `fraud-v42`, and which dataset revisions did it consume?" The
> team opens MLflow, points at a run ID, and points at a Git SHA.
> The auditor asks "is that Git SHA cryptographically bound to
> the artifact digest, so I can be sure the two match?" The team
> says "well, the pipeline logged both". The regulator's
> follow-up: "so if the MLflow database were tampered with, would
> the artifact still tell me its true source?" There is no
> answer. The signature attests the artifact was signed; it
> attests nothing about where the artifact came from.

**Provenance** — how the artifact was produced — is a separate
attestation layered on top of the signature. In the Sigstore
ecosystem the signature carries an in-toto Statement whose
`predicate` is a SLSA v1.0 provenance object. That predicate is
what the mod-103 admission gate verifies against the "allowed
builder" allow-list.

You leave this chapter able to:

- Read the SLSA v1.0 provenance predicate structure and know
  which fields the ML pipeline is responsible for populating.
- Understand the in-toto Statement + DSSE envelope shape and how
  it composes with cosign.
- Locate an ML pipeline on the SLSA maturity ladder (L1–L4) and
  name the next-step control needed to advance.
- Author `cosign attest` calls in the training pipeline that
  attach a SLSA v1 provenance attestation to the model artifact.
- Verify SLSA provenance at admission time and reject artifacts
  whose builder identity, source, or materials don't match
  policy.

---

## The three specifications in play

Three interlocking specs. Understand each; treat them separately.

### SLSA (Supply-chain Levels for Software Artifacts)

Framework describing the **integrity of the build process**.
SLSA v1.0 defines four *build levels* — L0 to L3 (with L4
described but reserved) — with escalating requirements for the
build platform.

| SLSA build level | Summary (paraphrased from the SLSA v1.0 spec) |
| --- | --- |
| **L0** | No requirements. |
| **L1** | Provenance is emitted (in any format), documenting how the artifact was built. Sufficient to detect *accidental* mistakes. |
| **L2** | Provenance is signed by the build platform. Consumers can verify the build ran on the claimed platform. Prevents forgery by parties outside the build platform. |
| **L3** | The build platform provides isolation between builds and the build platform itself is hardened. Provenance is non-forgeable even by tenants of the build platform. |

Verify the exact wording against the current SLSA v1.0 spec at
[slsa.dev/spec/v1.0/levels](https://slsa.dev/spec/v1.0/levels).
The point is: **L1 is trivial**, **L2 is signing (chapter 02
gets you here)**, **L3 requires an isolated, hardened builder**.

### in-toto

Framework describing **attestations about software supply-chain
steps**. An in-toto Statement is a JSON structure with three
top-level fields:

```json
{
  "_type": "https://in-toto.io/Statement/v1",
  "subject": [
    { "name": "fraud-model", "digest": { "sha256": "abc..." } }
  ],
  "predicateType": "https://slsa.dev/provenance/v1",
  "predicate": { ... }
}
```

- `subject` — one or more artifacts the attestation is about.
- `predicateType` — a URI identifying the predicate schema.
- `predicate` — the predicate content, whose shape is determined
  by `predicateType`.

Predicates in common use:

- `https://slsa.dev/provenance/v1` — SLSA v1 provenance (this
  chapter's focus).
- `https://cyclonedx.org/bom` — CycloneDX SBOM / ML-BOM (chapter
  04).
- `https://spdx.dev/Document` — SPDX SBOM.
- `https://in-toto.io/attestation/vulns` — vulnerability scan
  result.
- `https://in-toto.io/attestation/test-result` — test / eval
  outcome (chapter 05 uses this shape for eval reports).

### DSSE (Dead Simple Signing Envelope)

The envelope format for signed in-toto Statements. A DSSE
envelope contains the base64-encoded Statement, its
`payloadType`, and an array of signatures:

```json
{
  "payloadType": "application/vnd.in-toto+json",
  "payload": "<base64-encoded Statement>",
  "signatures": [
    { "keyid": "...", "sig": "..." }
  ]
}
```

Cosign wraps this: `cosign attest` produces a DSSE envelope and
uploads it to the OCI registry (as a related artifact) or to
Rekor (as a `dsse` entry type), signed with the same keyless
identity flow as `cosign sign`.

**The composition.** A signed provenance attestation is: a SLSA
v1 predicate → wrapped in an in-toto Statement → base64-encoded
into a DSSE envelope → signed by Fulcio-issued keyless cert →
Rekor-logged. All of this is what a single `cosign attest`
command produces.

---

## The SLSA v1.0 provenance predicate — field by field

The predicate has two top-level objects: `buildDefinition` and
`runDetails`. Each has sub-fields. What the ML pipeline is
responsible for populating:

### `buildDefinition`

Describes the *inputs* to the build — external, so a verifier
can reproduce or corroborate.

| Field | What it holds | ML-pipeline responsibility |
| --- | --- | --- |
| `buildType` | URI naming the build recipe / configuration schema | Pin to a stable identifier — e.g. `https://acme.internal/pipelines/model-training/v1`. Changing the URI means changing the schema of `externalParameters`. |
| `externalParameters` | The build's inputs as declared externally (e.g., what a user supplied to trigger the build) | Include: source repository URL and revision, dataset version identifiers, feature-set materialisation IDs, hyperparameters, base model reference. Do NOT include secrets. |
| `internalParameters` | Optional; build-platform-controlled parameters that affect the build | For a Kubeflow pipeline: the pipeline template digest, the SPIFFE ID of the trainer, the GPU node pool. |
| `resolvedDependencies` | An array of every input artifact the build consumed, each with digest | Include: dataset snapshot digest, feature-set digest, base model digest, dependency lock file digest, container image digest of the trainer. This is the field the ML-BOM (chapter 04) mirrors in richer form. |

### `runDetails`

Describes the *execution* of the build — internal to the builder.

| Field | What it holds | ML-pipeline responsibility |
| --- | --- | --- |
| `builder.id` | URI identifying the build platform | The SPIFFE ID of the CI orchestrator (`spiffe://acme.internal/plane/ci/component/argo-workflows`) or the GitHub Actions runner identity. This is the field the verifier's allow-list matches on. |
| `builder.version` | Optional version of the builder | Argo Workflows version, kubectl version — for forensic value. |
| `builder.builderDependencies` | Optional list of the builder's own dependencies with digest | Rarely populated by ML pipelines; nice-to-have for high-maturity setups. |
| `metadata.invocationId` | Opaque identifier for this build execution | The pipeline run ID — deep-link into the run's UI and audit log. |
| `metadata.startedOn`, `metadata.finishedOn` | Build start / end timestamps | Populated automatically. |
| `byproducts` | Optional array of secondary artifacts produced | Training loss curves, evaluation intermediate results, W&B run URI. |

### The complete example (annotated)

```json
{
  "_type": "https://in-toto.io/Statement/v1",
  "subject": [
    {
      "name": "registry.acme.internal/models/fraud",
      "digest": { "sha256": "abc123..." }
    }
  ],
  "predicateType": "https://slsa.dev/provenance/v1",
  "predicate": {
    "buildDefinition": {
      "buildType": "https://acme.internal/pipelines/model-training/v1",
      "externalParameters": {
        "source": {
          "uri": "git+https://github.com/acme-org/model-repo",
          "digest": { "sha1": "def456..." }
        },
        "datasetVersion": "iceberg://data.acme/fraud/v2026-03-31",
        "featureSet": "feast://features/fraud/materialisation-2026-03-31T18:00Z",
        "baseModel": "registry.acme.internal/models/base@sha256:789...",
        "hyperparameters": {
          "learning_rate": 3e-5,
          "epochs": 4,
          "batch_size": 32
        }
      },
      "internalParameters": {
        "pipelineTemplate": "sha256:aaa...",
        "trainerSpiffeID": "spiffe://acme.internal/plane/training/pipeline/fraud-trainer",
        "nodePool": "gpu-a100-40g"
      },
      "resolvedDependencies": [
        {
          "uri": "iceberg://data.acme/fraud/v2026-03-31",
          "digest": { "sha256": "bbb..." }
        },
        {
          "uri": "feast://features/fraud/materialisation-2026-03-31T18:00Z",
          "digest": { "sha256": "ccc..." }
        },
        {
          "uri": "registry.acme.internal/models/base@sha256:789...",
          "digest": { "sha256": "789..." }
        },
        {
          "uri": "pkg:pypi/torch@2.3.1",
          "digest": { "sha256": "ddd..." }
        }
      ]
    },
    "runDetails": {
      "builder": {
        "id": "spiffe://acme.internal/plane/ci/component/argo-workflows",
        "version": {
          "argo-workflows": "3.5.7",
          "kubernetes": "1.29"
        }
      },
      "metadata": {
        "invocationId": "argo-workflows/fraud-training-2026-04-01-abc123",
        "startedOn": "2026-04-01T14:10:00Z",
        "finishedOn": "2026-04-01T14:21:44Z"
      },
      "byproducts": [
        {
          "name": "training-loss-curve",
          "uri": "s3://acme-training-artifacts/fraud/2026-04-01/loss.parquet",
          "digest": { "sha256": "eee..." }
        }
      ]
    }
  }
}
```

The predicate is the machine-readable answer to "how was this
artifact built".

---

## Attaching provenance with `cosign attest`

Once the predicate JSON exists on disk, cosign attaches it to
the artifact:

```
COSIGN_EXPERIMENTAL=1 cosign attest \
    --predicate provenance.json \
    --type slsaprovenance1 \
    registry.acme.internal/models/fraud@sha256:${MODEL_DIGEST}
```

`--type slsaprovenance1` tells cosign the predicate type URI is
`https://slsa.dev/provenance/v1` (an alias). Custom predicate
types are also supported via `--type <URI>`.

The attestation is:

- Wrapped in an in-toto Statement (cosign populates `subject`,
  `predicateType`).
- Wrapped in a DSSE envelope.
- Signed by the keyless Fulcio-issued cert (same identity
  flow as `cosign sign` — the OIDC subject bound to the CI
  workload).
- Uploaded to Rekor as a `dsse` entry.
- Attached to the artifact reference in the OCI registry (as a
  companion `.att` tag or via referrers API).

`cosign download attestation` fetches the envelope back; the
verifier decodes the payload, extracts the predicate, and runs
policy.

---

## Verifying provenance at admission

The mod-103 chapter 06 admission gate authors the constraint
that consumes the attestation. The gate performs:

1. **Fetch the attestation** for the deployed digest (via
   `cosign download attestation`, Rekor lookup, or the OCI
   referrers API).
2. **Verify the DSSE signature** against the same Sigstore
   trust root used for the signature check.
3. **Verify the predicate type** is exactly
   `https://slsa.dev/provenance/v1`. Refusing any other type
   prevents "wrong-predicate confusion" attacks.
4. **Match the subject digest** against the deployed digest.
   Reject if different.
5. **Match `builder.id`** against the allow-listed builder
   SPIFFE IDs. Reject if the builder is not on the list.
6. **Match `buildType`** against the allow-listed pipeline
   template URIs.
7. Optionally: **match `externalParameters.source.uri`** against
   the allow-listed source repositories.
8. Optionally: **cross-check `resolvedDependencies`** against
   the ML-BOM the artifact carries (chapter 04) — the two
   documents should agree on inputs.

Every one of these is a check the mod-103 admission gate's
external-data provider runs before returning `verified`.

A concrete Rego snippet that runs inside the constraint template
(Gatekeeper syntax; see mod-103 chapter 06 for the surrounding
template):

```rego
provenance_ok(image, params) {
  resp := external_data({
    "provider": "slsa-verifier",
    "keys": [image],
    "parameters": params
  })
  att := resp.responses[_][1]
  att.predicate_type == "https://slsa.dev/provenance/v1"
  att.subject_digest == image_digest(image)
  allowed_builder(att.predicate.runDetails.builder.id, params.allowedBuilders)
  allowed_build_type(att.predicate.buildDefinition.buildType, params.allowedBuildTypes)
  allowed_source(att.predicate.buildDefinition.externalParameters.source.uri, params.allowedSources)
}

allowed_builder(id, allowed) { allowed[_] == id }
allowed_build_type(t, allowed) { allowed[_] == t }
allowed_source(uri, allowed) { startswith(uri, allowed[_]) }
```

---

## Achieving SLSA v1.0 build levels for ML pipelines

Where a typical ML pipeline usually starts, and what advancement
looks like:

### L0 → L1 (emit provenance in some form)

The lowest bar. Requirement: the build platform emits a
provenance document describing the artifact.

For an ML pipeline:

- Add a step at the end of training that writes
  `provenance.json` with the fields above (populated from the
  pipeline runtime — dataset URIs are known, source revision is
  known, builder ID is the CI's identity).
- Upload the JSON as a pipeline artifact.

That is L1. No signing required.

### L1 → L2 (sign the provenance)

Requirement: the provenance is signed by the build platform,
and the consumer verifies the signature.

For an ML pipeline: the `cosign attest` call above is the L2
step. The signing identity is the CI workload's OIDC / SPIFFE
identity, so consumers can verify "this provenance came from
the build platform, not a third party".

Chapter 02 delivered the signing infrastructure. This chapter's
`cosign attest` composes it with the SLSA predicate to reach L2.

### L2 → L3 (isolate the build; harden the platform)

Requirement: the build platform provides isolation between
builds (so one build cannot influence another) and is hardened
against tenant-side compromise of the provenance-generation
process. Provenance is non-forgeable even by tenants of the
platform.

For an ML pipeline this is *substantial* work — often the
step where an internal build platform stops being competitive
with hosted alternatives:

- Every build runs in an ephemeral, isolated environment (fresh
  runner, no shared state, no shared cache without integrity
  guarantees).
- The build platform, not the tenant, generates the provenance
  document (the tenant cannot influence the provenance content
  because the platform observes the build directly).
- The signing key / identity is held by the platform, not
  passed through to the tenant.
- Build platform is hardened: dependencies pinned, admission
  controlled, base images signed.

Hosted options that reach L3 out of the box:

- **GitHub Actions with the SLSA GitHub Generator** — the
  generator runs in a separate workflow that observes the build
  workflow and produces the provenance itself, signed by
  Actions' identity.
- **Google Cloud Build with SLSA support** — Cloud Build emits
  L3 provenance for artifacts built through it.
- **Tekton Chains** — observes Tekton pipelines and emits
  signed provenance; L3-capable when Tekton is deployed on a
  hardened cluster with isolation guarantees.

Internal ML platforms (Kubeflow, Argo Workflows without Chains)
are typically L1 by default and L2 once cosign attest is wired.
Advancing to L3 usually means adding one of the above as the
provenance-producing layer on top of the ML pipeline.

### L4 (reserved)

L4 exists in the spec text as a placeholder for stronger
guarantees; verify the current spec if a compliance requirement
lands on L4 — as of the SLSA v1.0 release, L3 is the highest
level with concrete requirements.

---

## Adapting to ML-specific build patterns

### Multi-stage training (pretrain → fine-tune → adapter)

Each stage is its own build with its own provenance:

- The pretrain build's provenance names the pretraining dataset,
  the code revision, the resulting base-model digest.
- The fine-tune build's provenance names the base-model digest
  as a `resolvedDependency`, plus the fine-tune dataset, plus
  the resulting fine-tuned digest.
- The adapter build's provenance names both the base and any
  intermediate fine-tune as `resolvedDependencies`.

The chain of provenance attestations forms the multi-stage
lineage. The mod-103 admission gate should verify the *deployed*
artifact's provenance and, transitively, the provenances of its
`resolvedDependencies` — this is where the ML-BOM (chapter 04)
helps by canonicalising the graph in one place.

### Continuous fine-tuning / RLHF loops

Fine-tuning that runs on a schedule against fresh preference
data produces a new artifact per run. Each run:

- Has its own build ID.
- Its own resolved dependencies (yesterday's model, today's
  preference batch).
- Its own signed provenance.

The retention rule from chapter 01 applies: retain each
provenance for the lifetime of any deployment that used the
resulting artifact.

### Federated / distributed training

A federated training round is a build with distributed
participants. The provenance is emitted by the coordinator,
whose `resolvedDependencies` include the round-N-1 model digest
and pointer records for each participant's contribution
(each participant may sign its update; the coordinator's
provenance references those signatures).

This is a spec-frontier area — SLSA v1.0 does not natively
model multi-party builds. Document the extension your platform
uses and be explicit about what the provenance does and does
not attest.

### Third-party / vendor-supplied base models

For a base model pulled from Hugging Face, an OpenAI
fine-tuning result, or a vendor-supplied checkpoint:

- Verify the vendor's own signature / attestation if one exists
  (Hugging Face is rolling out signing; OpenAI does not publicly
  sign artifacts as of drafting).
- In the ML-BOM (chapter 04), record what the vendor supplied
  as provenance (a URL, a documented hash, an attestation) —
  even if it is weaker than what you would produce internally.
- Do NOT sign a claim you cannot verify. If the vendor supplies
  no attestation, the ML-BOM should say so plainly rather than
  synthesise one.

---

## What this chapter does not cover

- **The signature mechanism itself.** Chapter 02 authored
  cosign, Fulcio, and Rekor. This chapter authors what the
  signature is over. The two compose but are distinct.
- **The ML-BOM.** Chapter 04. The ML-BOM overlaps the
  `resolvedDependencies` field of the provenance predicate but
  is a richer, standalone artifact.
- **Non-training provenance.** Inference-time provenance
  ("this response came from this model at this time with these
  tools") is chapter 06 territory (audit log) — the SLSA
  predicate is about *build*, not *use*.

---

## The mistakes this chapter is trying to prevent

- **Signing without attesting.** A cosign signature says "the
  bytes weren't tampered". A SLSA provenance attestation says
  "here is how the bytes came to be". You need both.
- **Populating `externalParameters` inconsistently.** If the
  same pipeline sometimes emits `datasetVersion` and sometimes
  `dataset_uri`, verifiers cannot write portable policy. Pin the
  schema and version-tag it.
- **Not matching the subject digest.** An attestation whose
  subject is a different artifact's digest, attached to the
  deployed artifact by mistake or by tampering, is worthless
  unless the verifier checks. Always check.
- **Building at L1, claiming L3.** The build-level claim is
  auditable — the presence of isolation and non-forgeability
  properties in the pipeline is what earns the claim. Do not
  self-certify beyond the evidence.
- **Attesting from the tenant workload instead of the
  platform.** Provenance emitted by the code being attested is
  weaker than provenance emitted by an observing platform
  (Chains, GitHub SLSA generator). If tenants can write their
  own provenance, they can lie in it.
- **Skipping resolvedDependencies for datasets.** Provenance
  that lists only container image dependencies and omits the
  dataset digest is answering half the "what did this come
  from" question. Datasets are dependencies.

---

## Summary

- SLSA v1.0 defines four build levels (L0–L3); L2 is signed
  provenance, L3 adds builder isolation and non-forgeability.
- The provenance is expressed as a SLSA v1 predicate wrapped in
  an in-toto Statement, wrapped in a DSSE envelope, signed by
  the cosign keyless identity — attached to the model artifact
  by `cosign attest`.
- The predicate has `buildDefinition` (source, external
  parameters, resolved dependencies) and `runDetails` (builder
  identity, invocation metadata). ML pipelines are responsible
  for populating dataset digests, feature-set digests, base-
  model digests, and the SPIFFE identity of the builder.
- Admission-time verification pins the predicate type, the
  subject digest, the builder ID, and the source URI — anything
  short of all four leaves a class of forgery in reach.
- Advancing an ML pipeline from L1 to L2 is the cosign attest
  step; L3 usually means adopting a platform (SLSA GitHub
  Generator, Tekton Chains, Cloud Build) that emits provenance
  from outside the tenant's control.
- Multi-stage builds (pretrain → fine-tune → adapter) chain
  attestations through `resolvedDependencies`; federated
  training extends the pattern; vendor artifacts get the best
  attestation the vendor supplies plus explicit ML-BOM
  disclosure of what is missing.
- Provenance answers "how was it built"; the ML-BOM (chapter
  04) canonicalises the full component graph; together they
  cover the chapter 01 lineage-plus-provenance requirement.
