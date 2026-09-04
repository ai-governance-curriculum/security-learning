# Chapter 01 — SLSA v1.0 Applied to Model Artifacts

> **Note on AI-assisted content.** This chapter maps the
> Supply-chain Levels for Software Artifacts (SLSA) v1.0
> Build track (Levels 0–3) onto the *training* pipelines that
> produce ML model weights. SLSA is a living specification;
> verify each requirement wording against the canonical text
> at `slsa.dev` before quoting it to an auditor. See
> [`resources.md`](./resources.md).

---

## Why this chapter exists

Every mature software organisation eventually adopts some
version of the same three-step supply-chain reasoning:

1. Attackers who cannot compromise your *code* will target
   the *pipeline* that turns your code into a released
   artefact. (Solarwinds, xz-utils.)
2. Consumers of your artefact — internal deployers, external
   customers, downstream regulators — need a way to tell a
   real build from a poisoned one that only *looks* real.
3. The only durable answer is a signed statement, generated
   by the build platform itself and attached to the artefact,
   that describes how the artefact was built.

SLSA is a widely adopted vocabulary for that statement. Its
Build track defines four levels (L0–L3) of increasing rigour
about *how the build produced the provenance* — from "no
guarantees" (L0) up to "a hardened builder that isolates one
build from another and cannot be told to lie about what it
ran" (L3).

The failure mode this chapter is written against:

> An ML platform team ships a fine-tuning pipeline. Training
> runs in a shared Kubernetes namespace with a shared service
> account. Training logs live in an S3 bucket that anyone on
> the team can rewrite. Model weights are pushed to a
> registry with a floating `latest` tag and no attestation.
> Six months in, an internal audit asks: "for the model
> currently serving 20 % of production traffic, prove that
> the training data was v3 of the customer-vetted corpus and
> not v3.1 of the corpus that included the leaked support
> tickets." Nobody can. There is no attestation, the
> training pod is long gone, the logs have been rotated, the
> corpus at the URL the training YAML points to has been
> rebuilt twice since. The organisation has adopted
> "MLOps"; it has not adopted supply-chain integrity.

The fix is to treat the training pipeline as a *build
system* and hold it to the same SLSA requirements you hold
your CI pipelines to — with adaptations for the specific
ways model builds differ from software builds.

You leave this chapter able to:

- Explain SLSA v1.0's Build track levels (L0–L3) and the
  three requirement categories at each level (producer,
  build platform, provenance).
- Translate each L1/L2/L3 requirement into a concrete
  control on a model-training pipeline.
- Name what "hermetic" means for an ML build and where
  strict hermeticity breaks down for models.
- Distinguish build-time from run-time isolation and design
  a pipeline where the two are physically separate.
- Justify a claimed SLSA level for a model artefact with the
  attestations, logs, and platform features that back the
  claim.

---

## SLSA v1.0 in one page

SLSA v1.0 (released 2023) reorganised the earlier draft into
*tracks*. The Build track is the one that has stabilised;
Source, Dependencies, and other tracks are on the roadmap.
This chapter is about the **Build track**.

The Build track defines three roles:

- **Producer** — the party that *creates* the artefact. In
  our world, the ML team running the training job.
- **Build platform** — the system that executes the build.
  For software: GitHub Actions with a reusable workflow,
  GitLab CI, Buildkite, Google Cloud Build, Tekton Chains.
  For models: Kubeflow Pipelines, Argo Workflows, SageMaker
  Training Jobs, Vertex AI custom jobs, Ray Train on a
  managed cluster — *provided* the platform is set up to
  meet the SLSA requirements below. A random `kubectl apply`
  of a Job is not a build platform in the SLSA sense.
- **Verifier / consumer** — the party that receives the
  artefact and its provenance and *decides* to accept or
  reject it. In our world, the model registry, the
  deployment admission controller, or an external customer.

The Build track ties each level to *what the provenance
document says* and *how much you can trust it*:

| Level | Producer | Build platform | Provenance contents |
| --- | --- | --- | --- |
| **L0** | No claim | No requirements | None. |
| **L1** | Follows a consistent build process | Emits provenance describing the build | Content is unauthenticated; can be forged. |
| **L2** | Runs builds on a hosted platform | Platform signs the provenance | Provenance is authenticated to the platform; forgery requires compromising the platform. |
| **L3** | Runs on a **hardened** build platform | Build platform prevents runs from influencing each other's provenance; secret material used to sign is not reachable from user-controlled build steps | Provenance is trustworthy even against a malicious *build definition*. |

Two features to notice before we translate to ML:

- **Provenance is machine-readable and standard-shaped.**
  The recommended format is an in-toto Statement (an
  attestation envelope) whose `predicateType` is
  `https://slsa.dev/provenance/v1`. The predicate has fields
  like `buildDefinition.buildType`, `buildDefinition.
  externalParameters`, `runDetails.builder.id`, and
  `runDetails.byproducts`. Consumers verify by parsing this
  predicate, not by reading free text.
- **The trust escalation is about "who could lie".** L1
  says provenance exists; L2 says the *platform* stands
  behind it; L3 says the *build definition itself* cannot
  make the platform lie. Each level is defined by which
  attacker capability it defeats, not by a checkbox count.

The SLSA specification also lists **verification
requirements**: what a consumer must do with provenance to
have derived any value from it. Levels the consumer never
verifies degrade to L0 in practice.

---

## Translating the Build track to model training

Model training pipelines have four characteristics that make
the SLSA translation *harder* than for a Go binary:

1. **Inputs are large and mutable by default.** A training
   run reads terabytes of data. That data lives in blob
   storage that permits overwrites. If the corpus URL is
   `s3://data/customer-v3/`, its contents today may not
   match its contents tomorrow.
2. **Determinism is imperfect.** GPU kernels, cuDNN
   algorithms, and floating-point non-associativity mean
   that two "identical" training runs on the same seed and
   the same inputs may produce weights that differ in
   epsilon-noise. Bit-for-bit reproducibility is often not
   achievable; behavioural reproducibility is.
3. **Builds are long and expensive.** A training run may
   take days and cost thousands of dollars. Re-running to
   verify is not free; provenance therefore carries more
   weight than in a CI pipeline where you can rebuild in a
   minute.
4. **The output has *capability*.** A software binary
   generally does what the source says. A model weight file
   can encode arbitrary behaviour (backdoors, injected
   biases, memorised secrets) that the source of the
   training job does not describe. Provenance about "how"
   the model was built does not fully constrain "what" it
   does — MEASURE-side controls (mod-106 evaluations,
   mod-104 lineage-integrity) are the complement.

These characteristics do not invalidate SLSA — they change
which parts of it are cheap and which are hard. The
translation below walks each level with the ML-specific
adjustments.

### SLSA L1 for model artifacts — provenance exists

**Producer requirements.**

- The training pipeline is defined in version control.
  Rules: the training entrypoint (Python file, notebook,
  YAML), the dataset selector, the hyperparameter block,
  the environment specification, and the base-model
  reference all live in a repository with reviewable
  history. "The data scientist ran a notebook on their
  laptop with a Wandb run ID" is not a controlled build
  process.
- The pipeline emits an *identifier* of the resulting
  artefact that consumers can reference. For models: an
  OCI image digest (`sha256:…`) if the model is packaged
  as an OCI artefact, or the SHA-256 of the raw weight
  file(s) if not.

**Build platform requirements.**

- The platform generates provenance for every run and makes
  it available alongside the artefact. Content: how the
  run was invoked (which entrypoint, which parameters),
  when it started and stopped, which builder image or
  runner executed it.

**Provenance requirements.**

- Follows the in-toto SLSA Provenance v1 schema.
- Names, at minimum: `subject` (the artefact digest),
  `buildType`, `externalParameters` (the inputs a caller
  could set), `builder.id` (the platform identity), and
  timestamps.
- Can be forged. An attacker who can write to the artefact
  store can write to the attestation next to it.

**Concrete example — Kubeflow / Argo.** A `PipelineRun` that
records: the compiled DAG, the input `PipelineSpec`
parameters, the container image digests of every step, the
resolved dataset URIs (with commit / snapshot IDs where the
storage supports it), and the resulting weights' SHA-256.
The provenance JSON is written to `s3://provenance/<run-
id>/slsa-provenance.json`. No signing yet.

**What L1 buys.** You can now answer "how was this model
built?" from a document rather than from someone's memory.
For a lot of internal ML programmes, this is where the
first real leverage is: L1 forces the training pipeline out
of notebooks and into version control.

### SLSA L2 for model artifacts — the platform signs

**Producer requirements.**

- Everything in L1, plus: the build runs on a **hosted
  build platform** (managed CI, managed training service,
  or an internal shared platform maintained by a different
  team from the model owners). "The scientist ran the same
  script in a container on their workstation" does not
  meet L2; the *platform boundary* is what allows the
  signature to mean something.

**Build platform requirements.**

- The platform signs the provenance with a key the
  producer cannot access. In modern deployments this is
  almost always via **sigstore Fulcio** — a short-lived
  OIDC-issued signing certificate that the platform's
  workload identity is authorised to request; chapter 02
  covers the mechanics.
- The platform publishes its identity and the key material
  (Fulcio's root certificate, the platform's OIDC issuer)
  in a way consumers can pin.

**Provenance requirements.**

- Signed. Consumers verify the signature against the
  platform's published identity before trusting any field.
- Forgery now requires compromising the build platform's
  signing pathway, not just writing to the artefact store.

**Concrete example — Vertex AI custom training + sigstore.**
The Vertex AI job runs under a Google-service-account
identity; a post-training step uses that identity to obtain
a Fulcio certificate keyed to the SA email and signs the
SLSA Provenance v1 predicate over the emitted model
directory's digest. The signed attestation is stored
alongside the artefact in the model registry. Consumers
verify with `cosign verify-attestation --certificate-
identity=<training-sa>@<project>.iam.gserviceaccount.com`.

**What L2 buys.** You now have a *provable* link from an
artefact in the registry back to an identity — the training
platform's workload — that ran the build. The identity is a
handle for accountability and revocation.

### SLSA L3 for model artifacts — hardened builder

**Producer requirements.**

- Everything in L2, plus: the producer uses a build
  platform that has itself been hardened to prevent one
  build run from tampering with another's provenance or
  observing another's secret material.

**Build platform requirements — the hard part.**

- **Build isolation.** Each run executes in an environment
  that is not shared with concurrent runs of other tenants.
  A workspace VM per run, or a well-hardened per-tenant
  container, is the target; a shared Jupyter kernel is
  not.
- **Provenance is not reachable from user-controlled
  build steps.** The signing key material and the code
  that generates the signed provenance run *outside* the
  build step's process. Practically: a build-service
  controller emits the attestation after the build step
  exits, using metadata it observed rather than metadata
  the build step handed it.
- **Ephemeral, isolated builder environments.** Filesystem
  and network state do not leak between runs.
- **Non-falsifiable provenance.** A malicious build
  definition — a training script the attacker owns — must
  not be able to convince the platform to emit provenance
  claiming inputs the run did not actually use.

**Provenance requirements.**

- The platform, not the build definition, is the source of
  each provenance field. `externalParameters` is what the
  caller passed; `resolvedDependencies` (dataset digests,
  container image digests, base-model digests) is what the
  platform *observed* the build fetching, not what the
  build script self-reported.
- Signatures come from a signing identity that no user
  code inside a build step can obtain.

**Concrete example — a hardened ML build service.** A
platform team runs a custom Tekton Chains variant. Each
`TrainingRun` CRD is scheduled onto a per-run VM (Firecracker
microVM or a dedicated GKE node pool with taints that keep
other tenants off). A separate Chains controller watches the
run's status, records the input digests it recorded during
input-provisioning, records the output digests it observed
at the end, and signs the resulting SLSA Provenance v1
predicate with a key held in a KMS the training container
cannot reach. The training container has *no* IAM
permissions to write to the attestation store.

**What L3 buys.** The threat model of a malicious *insider
who owns the training code* is now covered. At L2, if the
data scientist replaces the pipeline script with one that
lies about which dataset it read, the platform will sign
the lie because the script itself is fabricating the
provenance fields. At L3, the platform observes the fetch
and signs its own observation.

### The requirement bundle at a glance

Whether an artefact is at L1, L2, or L3 is answered by
walking a short checklist. A workable per-model bundle:

```yaml
model: fraud-classifier-v42
artifact_digest: sha256:abcd...
claimed_slsa_level: 2

producer:
  build_definition_in_vcs: true       # L1
  entrypoint: git+https://.../pipelines/fraud@v42
  artefact_identifier_type: oci-image-digest

build_platform:
  id: https://internal-vertex-ai.company.com/
  hosted: true                        # L2
  hardened: false                     # L3 would be true
  build_isolation: node-pool          # L3: per-run-vm
  signing_identity_source: fulcio-oidc
  build_definition_can_write_provenance: false   # L3

provenance:
  schema: https://slsa.dev/provenance/v1
  signed: true                        # L2
  signer_identity: training-runner@company.iam...
  signature_verification: cosign verify-attestation --certificate-identity=...
  resolved_dependencies_source: platform-observed   # L3
```

The `claimed_slsa_level` is the *minimum* level all the
lower-numbered rows support. A team that has L2 signing but
still lets the build script self-report `resolvedDependencies`
is at L2, not L3, no matter how good the other L3 rows
look.

---

## Hermeticity for model builds

SLSA's L3 requirements mention that the build should have
its inputs "declared up front" and that "external
[dependency] resolution" happens before the isolated build
step begins. This is what the software-supply-chain
literature calls **hermeticity**.

For a Go binary, hermeticity is fairly clean: pin every
dependency in `go.sum`, run the build in a network-off
container with a pre-materialised module cache, and the
build cannot pull anything the build definition did not
name. For a model, hermeticity is *conceptually* the same
but *operationally* harder:

- **Container image.** The training runtime (framework,
  CUDA, drivers) must be pinned by digest, not by tag.
  `pytorch/pytorch:2.4-cuda12.1-cudnn9-devel` is a tag; the
  digest it resolved to at build time is what belongs in
  provenance.
- **Python dependencies.** A resolved `requirements.txt`
  or a lockfile (`pip-tools`, `uv.lock`, `poetry.lock`)
  hashed and installed offline from a local index. `pip
  install torch` inside the training container without a
  hash-locked resolution is not hermetic — the version
  and the wheel contents can drift between runs.
- **Dataset.** The corpus is content-addressed, not path-
  addressed. The provenance names either a snapshot ID
  (DVC, LakeFS, Delta Lake, Hugging Face Datasets commit
  SHA) or a manifest that hashes each file. The manifest
  itself is what the pipeline references; if the pipeline
  says "read `s3://data/customer-v3/`", that is *not
  hermetic* unless S3 versioning is on and a specific
  version ID is pinned.
- **Base model / adapter.** Same rule as dataset: an OCI
  digest, an HF revision SHA, or a signed manifest digest.
  Never a floating `latest`. (Chapter 05 walks the HF
  hygiene process; chapter 02 walks the signing.)
- **Tokeniser / auxiliary files.** Often forgotten. A
  tokeniser update is a base-model update.
- **Random seeds and non-deterministic backend flags.**
  Recorded but not sufficient for bit-for-bit
  reproducibility; see below.

### The behavioural-reproducibility fallback

Bit-for-bit reproducibility is often impractical for
GPU-accelerated training. cuDNN has non-deterministic
algorithms selected by heuristics; `torch.backends.cudnn.
deterministic = True` reduces this at a throughput cost;
multi-GPU reductions add another epsilon of noise. The
usual practical position:

- Aim for **hermetic inputs** — same dataset digests, same
  container digest, same lockfile, same base model, same
  seed — even where you cannot guarantee bit-identical
  output.
- Record what you can — deterministic flags, seed, GPU
  driver version, cuDNN version, world size, precision
  policy — in provenance so consumers can *reason* about
  the reproducibility bound.
- Substitute **behavioural reproducibility** for bit-for-
  bit: two runs from the same hermetic inputs must produce
  weights whose eval metrics agree to within a stated
  tolerance on a stated held-out set. This is a MEASURE-
  side check (mod-104 chapter 06's eval bundle), not a
  build-side check.

Do not claim SLSA L3 based on a build whose provenance
does not record its inputs. Do not refuse to claim SLSA L3
because you cannot make GPU training bit-for-bit
reproducible; hermeticity of inputs is what SLSA asks for.

---

## Build / run isolation

A theme that runs through SLSA is that the environment
that *builds* an artefact should not be the environment
that *runs* it. For software: the CI runner is not the
production host. For models: the training cluster is not
the serving cluster.

This split matters because build environments have
credentials and privileges that run environments must not
have. A training pipeline reads raw datasets that may
contain PII (mod-108); pulls base models that may be
gated (chapter 05); writes attestations to a registry it
would be dangerous to give the serving stack write access
to. If the same node runs both, an attacker who compromises
the serving process has a shortcut to the training
identity.

Concrete controls:

- **Distinct compute pools.** Training GPUs are a
  different node pool, tenant, or account from serving
  GPUs. Firewall rules block one from reaching the
  other's control plane.
- **Distinct workload identities.** The training service
  account can write to the model registry; the serving
  service account can only read signed artefacts. The
  registry ACL enforces this.
- **Distinct credentials to third-party stores.** The
  training identity has (short-lived, KMS-mediated) read
  access to raw data; the serving identity does not.
- **Distinct provenance-writing identity.** The identity
  that writes SLSA provenance is neither the training
  identity nor the serving identity — it belongs to the
  build platform's controller. See L3 above.

The build/run split is easy to state and easy to lose.
The most common regression is "we let the serving stack
call the training pipeline for online fine-tuning" — the
credentials collapse together, and any prompt injection
(mod-107) that reaches the serving side has a path to
poison the training store.

---

## Wiring provenance into the model registry

L2 and L3 provenance is only useful if a consumer verifies
it. A workable admission chain:

1. Model registry accepts an artefact push only if a
   signed SLSA Provenance v1 attestation accompanies it.
   Enforced by a pre-push admission webhook that runs
   `cosign verify-attestation` against the registry's
   configured Fulcio identity policy.
2. Registry stores artefact + attestation together, both
   content-addressed by digest.
3. Deployment admission controller (chapter 02; mod-103)
   enforces on the *serving* side: for a model to be
   loadable at inference time, its SLSA provenance must
   pass verification against the deployment policy. The
   deployment policy is a Rego policy (mod-109 chapter 04)
   that says, for example, "for production tier, the
   provenance must be signed by `builder.id ==
   https://internal-vertex-ai.company.com/`, the
   attestation's `resolvedDependencies` must reference a
   dataset digest present in the approved-dataset
   register, and the base model must have its own signed
   attestation."
4. Every load-time verification result is logged for
   audit (mod-104 chapter 04's tamper-evident audit log).

The registry and the admission controller are the
*consumer* in SLSA's grammar. Without them, provenance is
a document; with them, it is a gate.

---

## Standard failure modes

- **Provenance without verification.** The pipeline emits
  a beautiful SLSA v1 attestation; nothing on the
  consumer side reads it. Fix: the admission controller
  is a release-gate blocker.
- **"L3" claim on a shared training namespace.** Multi-
  tenant Jupyter kernels, shared root filesystems, or
  service accounts multiple people can `kubectl exec`
  into do not meet L3 isolation. Fix: per-run isolated
  compute; walk the L3 requirements honestly.
- **Signed provenance whose fields the build script
  fills in.** The signature is real; the content is the
  build script's self-report. An attacker who owns the
  script owns the provenance. Fix: build platform
  observes the fetch and generates the provenance; the
  build step gets no KMS access.
- **Floating tags.** `pytorch/pytorch:latest`,
  `s3://data/corpus/`, `hf.co/company/base-model`. Fix:
  everything pinned by digest / revision / snapshot ID in
  provenance.
- **Hermeticity claimed, network open.** The training pod
  has unrestricted egress; `pip install` at build time
  reaches out to whatever is at the URL when the run
  happens. Fix: build step runs with network egress
  restricted to a pinned dependency mirror pre-populated
  by the platform; anything else is an outage, not a
  silent success.
- **Build identity used at serve time.** The serving
  workload's KSA has the same permissions as the
  training workload's KSA "for convenience". Fix:
  separate identities; registry ACL prevents the serving
  side from writing.
- **Attestation stored beside the artefact in a mutable
  bucket.** An attacker who can write to the bucket can
  replace both. Fix: attestations to Rekor-backed
  transparency log (chapter 02) or to an append-only
  store; verification checks tlog inclusion.
- **Reproducibility over-claimed.** The README says
  "reproducible from `git checkout <sha>`" but does not
  pin the CUDA image, the cuDNN version, or the world
  size. Fix: reproducibility statement lists exactly what
  is pinned and what is a behavioural (metric) claim.

---

## Summary

- **SLSA v1.0's Build track** defines four levels (L0–L3)
  of increasingly hardened build integrity, keyed to which
  attacker capability each level defeats.
- **L1 = provenance exists in a standard shape**
  (in-toto SLSA Provenance v1). **L2 = the build platform
  signs it.** **L3 = the platform prevents the build
  definition from lying to it.**
- Model training pipelines are build systems in SLSA's
  sense. Every level maps onto training with adjustments
  for dataset scale, GPU non-determinism, and long-running
  builds.
- **Hermeticity** for models means pinning inputs by
  digest: container images, Python lockfiles, dataset
  snapshots, base-model revisions, tokenisers. Bit-for-bit
  reproducibility of output is often not achievable;
  **behavioural reproducibility** is the practical target.
- **Build / run isolation** — distinct compute pools,
  distinct identities, distinct credentials for the
  training path versus the serving path — is the L3
  requirement most often lost in ML platforms.
- Provenance without a **verifier** on the consumer side
  is decoration. The model registry and the deployment
  admission controller (chapters 02 and 04) are where
  SLSA is enforced at admission time.
