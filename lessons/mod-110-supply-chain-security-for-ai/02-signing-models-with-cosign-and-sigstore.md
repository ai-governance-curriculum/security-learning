# Chapter 02 — Signing Model Artifacts with cosign and sigstore

> **Note on AI-assisted content.** The cosign / sigstore
> command-line surface and OCI registry conventions change
> frequently; the tool invocations below reflect the shape of
> the interface at the time of writing. Always re-verify
> against the sigstore and cosign project docs before pasting
> a command into a production pipeline. See
> [`resources.md`](./resources.md).

---

## Why this chapter exists

Chapter 01 said the training platform emits a SLSA
Provenance v1 attestation and signs it. This chapter is
about *how you sign*, *where you store the signature*, and —
most importantly — *what the verifier on the consumer side
actually checks*.

The failure mode this chapter is written against:

> A team adopts cosign. Every model artefact leaves the
> training pipeline with a `.sig` file next to it in the
> registry. The deploy admission controller is configured
> to run `cosign verify` before pulling. Six months in, an
> engineer with registry-write access swaps the model file
> and re-signs it with a personal key. The admission
> controller still passes — because `cosign verify` with
> no `--certificate-identity` and no policy just checks
> that *some* signature is present and internally valid.
> The signature bought the org nothing; the *policy* on
> top of the signature is what buys anything, and there
> was no policy.

Signing without a policy is theatre. A cosign command
without a *pinned identity* accepts any signer. A
verification step that runs without a *transparency-log
inclusion* check accepts a locally forged signature.
This chapter walks the primitives you need to compose so
that "signed and verified" means something a consumer can
lean on.

You leave this chapter able to:

- Explain the sigstore trust model — Fulcio, Rekor, the
  root of trust — and where cosign fits inside it.
- Sign a model artefact and attach a SLSA Provenance v1
  attestation using keyless (OIDC) signing.
- Verify signatures at deployment time with a
  **certificate-identity policy** and a **transparency-log
  inclusion** check.
- Package non-OCI weight files as OCI artefacts (ORAS)
  so the same signing / verification machinery works
  uniformly for containers, model images, adapters,
  datasets, and eval bundles.
- Design admission-time verification with the sigstore
  Kubernetes policy-controller or an equivalent.
- Recognise and mitigate the failure modes that make
  signing decorative.

---

## The sigstore trust model

Sigstore is a *system* for signing, verifying, and
recording software artefacts. cosign is the developer-
facing CLI in front of it. The system has three parts:

- **Fulcio** — a certificate authority that issues
  **short-lived** (typically 10-minute) X.509 code-signing
  certificates. The subject of the certificate is an
  identity proved to Fulcio via **OpenID Connect** —
  GitHub Actions' workflow identity, a Google service
  account, an Anthropic-issued email, an internal OIDC
  provider. There is no long-lived signing key to
  protect; the signer generates an ephemeral key pair,
  presents an OIDC token, receives a certificate binding
  the ephemeral public key to the OIDC identity, signs,
  and throws the private key away.
- **Rekor** — an append-only, publicly verifiable
  **transparency log**. Every signature made through
  sigstore is recorded with an inclusion proof. Consumers
  can verify not only "this signature is valid" but "this
  signature exists in Rekor and was recorded at time T".
- **Root of trust** — the set of Fulcio CA certs and Rekor
  public keys that verifiers pin. The **public sigstore**
  operates a root maintained by the sigstore project; an
  organisation may also run its own private Fulcio + Rekor
  (this is what most enterprises with strict compliance
  requirements do), publishing its own trust bundle.

The security argument this composes into:

1. The Fulcio certificate binds a signature to an OIDC
   identity — not to a KMS key an attacker who
   compromised your registry can also reach.
2. The Rekor entry binds the signature to a *point in
   time* — an attacker who compromises Fulcio *tomorrow*
   cannot backdate a certificate to cover an artefact
   they pushed *yesterday*, because the tlog inclusion
   proof from yesterday cannot be forged.
3. The verifier's **identity policy** — "the signer must
   be `training-runner@my-project.iam.gserviceaccount.
   com`" — is what turns "signed by somebody" into "signed
   by the party we authorise to sign this class of
   artefact".

The trust model has two attacker classes it defeats:

- **Registry-write attacker.** Cannot swap the artefact
  without also producing a new signature. Cannot produce
  a new signature that passes the identity policy without
  compromising the OIDC issuer for the pinned identity.
- **Signing-key compromise attacker.** No long-lived
  signing key exists to compromise. Compromising Fulcio
  gives future signatures; the Rekor tlog reveals the
  compromise via anomalous inclusion timing and prevents
  backdating.

The attacker class it does *not* defeat:

- **Compromise of the authorised signer's OIDC identity.**
  If the attacker becomes the GitHub Actions workflow you
  trust, or the KSA you trust, they can obtain a valid
  Fulcio certificate and sign whatever they like. The
  identity-provider security posture (SPIFFE / SPIRE,
  OIDC, KSA lifecycle) is a hard prerequisite — this is
  mod-103 chapter 04 (workload identity) and mod-105
  chapter 04 (identity-revocation) territory.

---

## Keyless signing with cosign

The canonical modern signing pattern is **keyless**:
sigstore generates an ephemeral key pair per signing
operation and destroys the private key immediately after.
Nothing is stored long-term.

### Signing a container image

The simplest case. Assume the model is packaged as an OCI
image:

```bash
# The training runner already has an OIDC token from its
# workload identity (GitHub Actions, GCP metadata server,
# EKS Pod Identity, or a SPIFFE JWT-SVID).
cosign sign \
  --oidc-issuer https://token.actions.githubusercontent.com \
  registry.company.com/models/fraud-classifier@sha256:abcd...
```

What happens on the wire:

1. cosign generates a fresh P-256 key pair in memory.
2. cosign obtains an OIDC token from the configured issuer
   (in a GitHub Actions runner: an OIDC token minted for
   the workflow).
3. cosign posts the OIDC token and the ephemeral public
   key to Fulcio. Fulcio validates the OIDC token, issues
   a short-lived X.509 certificate that binds the public
   key to a *subject* derived from the OIDC claims
   (`repo:owner/name:ref:refs/heads/main` for GitHub,
   the `email` claim for Google service accounts, and
   so on).
4. cosign signs the digest of the image with the ephemeral
   private key.
5. cosign posts the signature + certificate to Rekor.
6. cosign writes the signature, certificate, and Rekor
   entry index into the image's OCI registry alongside
   the image itself (in a companion tag named after the
   image digest — e.g. `sha256-abcd....sig`).
7. cosign discards the private key.

Reference the artefact **by digest**, never by tag, when
signing. A tag can move; a signature is over the digest.

### Attaching a SLSA provenance attestation

Signing an image proves it came from an authorised signer.
Attaching an attestation says *what the signer is
asserting* about the image. Chapter 01's SLSA v1
provenance is one such attestation:

```bash
cosign attest \
  --predicate slsa-provenance.json \
  --type slsaprovenance \
  --oidc-issuer https://token.actions.githubusercontent.com \
  registry.company.com/models/fraud-classifier@sha256:abcd...
```

`cosign attest` wraps `slsa-provenance.json` in an in-toto
attestation envelope keyed to the artefact's digest,
signs the envelope, and stores it in the registry (in a
companion tag like `sha256-abcd....att`). A single artefact
can have several attestations with different predicate
types (SLSA provenance, SBOM, vulnerability scan, ML-BOM
from chapter 03).

### The "predicate types" you attach to model artefacts

Types worth standardising on:

| Predicate type | What it says | Origin |
| --- | --- | --- |
| `https://slsa.dev/provenance/v1` | How the artefact was built. | Chapter 01. |
| `https://cyclonedx.org/bom` | ML-BOM / SBOM. | Chapter 03. |
| `https://in-toto.io/attestation/vuln/v0.1` | Result of a vulnerability scan on the artefact. | mod-103 container scan; mod-104. |
| `https://in-toto.io/attestation/test-result/v0.1` | Eval / red-team scorecard. | mod-106; mod-104. |
| Custom (e.g. `https://company.com/attestations/model-eval/v1`) | Org-specific evaluation results. | Internal. |

An admission policy can require the *union* of these — a
production-tier model must have SLSA provenance, an
ML-BOM, and a passing eval scorecard, all signed by
distinct trusted identities. This is the pattern chapter
04's OPA policies in mod-109 lean on.

### Signing non-OCI weight files with ORAS

Not every model artefact is a container. Raw weight files
(`.safetensors`, `.pt`, `.gguf`), adapters, and eval
bundles are often plain files in blob storage. Sigstore
signs OCI descriptors, so the standard pattern is:

1. Package the file(s) as an OCI artefact using ORAS
   (OCI Registry As Storage) or `oras push`, publishing
   to the same registry that hosts container images.
2. Sign the resulting OCI descriptor with cosign as
   above.

```bash
oras push registry.company.com/models/fraud-adapter:v42 \
  ./adapter.safetensors:application/octet-stream

# Registry returns a descriptor digest, e.g. sha256:ef12...
cosign sign registry.company.com/models/fraud-adapter@sha256:ef12...
```

Using ORAS collapses "sign container images" and "sign
model weights" into one workflow. The alternative —
signing raw files with cosign's blob mode — works but
loses the registry-native storage of signatures and
attestations, and complicates verification at the
serving layer.

---

## Verifying at deployment time

The signing side is easy; the verification side is where
programmes go wrong. A verification command without policy
is a syntax check.

### The three checks every verification does

Any usable `cosign verify` invocation checks:

1. **Signature validity** — the signature over the
   artefact's digest is cryptographically valid against
   the certificate.
2. **Certificate identity** — the certificate's subject
   matches an *identity policy* the verifier holds. For
   Fulcio-issued certs, this is the `--certificate-
   identity` (subject) and `--certificate-oidc-issuer`
   pair, or a regex pair for either.
3. **Transparency-log inclusion** — the signature was
   recorded in Rekor at a time consistent with the
   certificate's validity window. This defeats backdating.

If any of the three is missing, the verification is
substantively weaker than it looks. Below is a working
verification for a GitHub-Actions-built image:

```bash
cosign verify \
  --certificate-identity-regexp '^https://github\.com/company/ml-pipelines/\.github/workflows/train\.yml@refs/heads/main$' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  registry.company.com/models/fraud-classifier@sha256:abcd...
```

For an attestation:

```bash
cosign verify-attestation \
  --type slsaprovenance \
  --certificate-identity-regexp '^https://github\.com/company/ml-pipelines/\.github/workflows/train\.yml@refs/heads/main$' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  registry.company.com/models/fraud-classifier@sha256:abcd... \
  | jq -e '.payload | @base64d | fromjson | .predicate.buildDefinition.buildType == "https://slsa.dev/build-types/kubeflow/v1"'
```

The `jq` pipeline is where the policy really lives: after
verifying the *envelope*, the consumer checks that the
attestation *content* meets policy — the build type is
the one expected, the base model referenced in
`resolvedDependencies` is on the approved list, the
dataset digest is one of the vetted corpora, and so on.
`cosign verify-attestation` alone is not a decision; it
is a signed document you then subject to policy.

### Kubernetes admission — sigstore policy-controller

For serving on Kubernetes, the sigstore project ships a
**policy-controller** admission webhook. A representative
`ClusterImagePolicy`:

```yaml
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: models-must-be-signed-and-attested
spec:
  images:
    - glob: registry.company.com/models/**
  authorities:
    - keyless:
        url: https://fulcio.sigstore.dev
        identities:
          - issuer: https://token.actions.githubusercontent.com
            subjectRegExp: ^https://github\.com/company/ml-pipelines/.*@refs/heads/main$
      ctlog:
        url: https://rekor.sigstore.dev
      attestations:
        - name: slsa-provenance-passes
          predicateType: https://slsa.dev/provenance/v1
          policy:
            type: cue
            data: |
              predicate: {
                buildDefinition: {
                  buildType: =~"^https://slsa.dev/build-types/kubeflow/v1$"
                }
                runDetails: {
                  builder: {
                    id: =~"^https://internal-vertex-ai\\.company\\.com/"
                  }
                }
              }
```

Any Pod that pulls an image under `registry.company.com/
models/` must present:

- a Fulcio-issued signature with the pinned issuer and
  subject regex;
- a Rekor-attested SLSA provenance attestation of the
  expected `buildType` and `builder.id`.

The policy is versioned in Git and applied through the
platform's normal manifest promotion process. Chapter 04
of mod-109 (policy-as-code) covers the operational
practices — policy tests, exception handling, break-
glass — that keep this admission gate honest.

### Private-sigstore deployments

Regulated organisations often cannot rely on the public
sigstore instance (data residency, audit obligations,
outbound-network constraints). The alternative is a
**private sigstore stack**: run Fulcio and Rekor inside
the enterprise perimeter (Sigstore Scaffolding, Chainloop,
or a vendor distribution), configured with an internal
OIDC issuer (Okta, Auth0, or the KSA / SPIRE JWT-SVIDs
from mod-103 chapter 04).

The verification side then pins the **internal trust
root** instead of the public one — a bundle file
containing the internal Fulcio CA and the internal Rekor
key, published to consumers and rotated on a schedule.
The signing / verification *shape* is identical.

The choice of public vs private sigstore is an org-level
decision (chapter 06's supplier register captures it);
what matters at the mechanism level is that verifiers pin
*their* trust root, not "sigstore, whatever that is".

---

## Signing across the model lifecycle — who signs what

Signing is not a one-time act. Different artefacts along
the pipeline carry signatures from different identities:

| Artefact | Signed by | What the signature asserts |
| --- | --- | --- |
| Base model image (imported from HF Hub, chapter 05) | The **intake pipeline**'s identity | "This is the base model we imported at revision X and safety-vetted per the chapter-05 runbook." |
| Training dataset manifest | The **data-owning team**'s pipeline identity | "This corpus was assembled from the customer-vetted sources named in the manifest." |
| Trained model artefact | The **training platform**'s identity | Chapter 01: SLSA provenance for the build. |
| ML-BOM | The **build platform**'s identity (chapter 03) | "This is the set of components that went into the model." |
| Eval scorecard | The **eval platform**'s identity (mod-106) | "The model passed evals at these thresholds." |
| Deployment manifest | The **deploy pipeline**'s identity | "The runtime configuration for the serving stack." |

The deployment admission controller composes these:

- serving-tier gate rejects any image without SLSA
  provenance;
- serving-tier gate rejects any image whose SLSA
  provenance references a base-model digest that lacks
  the intake pipeline's signature;
- serving-tier gate rejects any image whose SLSA
  provenance references a dataset manifest that lacks
  the data-team signature;
- production-tier gate additionally requires an eval
  scorecard attestation from the eval platform.

Each identity is scoped narrowly. An attacker who
compromises the eval platform's identity cannot sign new
model weights; an attacker who compromises the training
identity cannot sign eval passes.

---

## Signing dataset artefacts and eval bundles

The pattern generalises to any content-addressed artefact:

- **Dataset snapshots.** DVC / LakeFS / Delta Lake produce
  content-addressed snapshots; publish the snapshot
  manifest to the registry as an OCI artefact and sign it.
  A subsequent training run's SLSA provenance lists the
  signed snapshot digest in `resolvedDependencies`.
- **Eval bundles.** The mod-104 chapter 06 eval-bundle
  layout is content-addressable already. Publish and sign
  the bundle; the eval-scorecard attestation on a model
  references the bundle digest, so a consumer can prove
  which evals were used.
- **Adapters, LoRA weights, embeddings.** ORAS-push +
  sign, as with weight files.
- **System prompts, policies, safety classifiers.** For
  agent products (mod-107), the system prompt file and
  the tool-registry YAML are supply-chain artefacts.
  Signing them (and requiring the serving process to
  verify at startup) closes the loop that would otherwise
  let a compromise of the config bucket alter agent
  behaviour without a code change.

---

## Standard failure modes

- **`cosign verify` without `--certificate-identity`.**
  Accepts any signer. Fix: identity pin (subject +
  issuer) is mandatory in policy.
- **Verification against public sigstore in a private-
  root organisation.** Verifier is checking the wrong
  trust root; a legitimate internal signature fails, or
  a public-Fulcio signature passes when it shouldn't.
  Fix: pin the org's trust bundle; disable public
  fallback.
- **Signatures without transparency-log inclusion.**
  cosign supports `--offline` and `--experimental` modes
  that skip Rekor; the resulting artefacts are
  substantively less safe. Fix: policy requires tlog
  inclusion; `COSIGN_EXPERIMENTAL` off in verification
  contexts.
- **Attestations without content policy.** The verifier
  runs `cosign verify-attestation` and stops. The
  attestation content is never inspected. Fix: the
  policy that follows the verify step is what enforces
  the SLSA level, the eval threshold, the ML-BOM
  contents.
- **Rotating identities without policy update.** A team
  migrates from GitHub Actions to an internal runner;
  the admission policy still lists the GitHub identity.
  Fix: the policy update ships alongside the identity
  migration; a policy-review gate blocks the migration
  otherwise.
- **Signing a tag, not a digest.** `cosign sign
  registry/models/fraud:latest` signs the digest the
  tag pointed to at signing time; the tag can then be
  moved to a different digest and the signature is
  orphaned. Fix: sign digests only; CI lints for tag-
  scoped signing commands.
- **Storing signatures in a mutable bucket without a
  transparency-log entry.** The registry lets any
  registry-write identity delete or overwrite the `.sig`
  companion tag. Fix: rely on Rekor as the source of
  truth for existence; registry serves as convenience.
- **One identity signs everything.** The training
  service account signs SLSA provenance, ML-BOM, eval
  scorecards, and deployment manifests. A compromise
  fabricates all four. Fix: distinct identities per
  artefact class (see the table above).
- **Break-glass without audit.** An engineer uses
  `--allow-insecure` or edits the ClusterImagePolicy to
  admit an unsigned artefact for a hotfix; the change
  is never reverted. Fix: exceptions have TTLs, produce
  an incident ticket, and revert automatically (mod-109
  chapter 04 exception pattern).

---

## Summary

- **Sigstore** is the trust system; **cosign** is the CLI.
  **Fulcio** issues short-lived certificates keyed to OIDC
  identities; **Rekor** records signatures in an append-
  only transparency log.
- **Keyless signing** is the default: no long-lived key to
  protect; the OIDC identity is the attack surface.
- **Verification is a *policy* problem**, not a syntax
  problem. `cosign verify` without a pinned certificate
  identity, without a transparency-log inclusion check,
  and without policy over attestation content is not a
  security control.
- **ORAS** lets you package raw weight files as OCI
  artefacts and sign them with the same machinery as
  container images.
- **Attestations** (SLSA provenance, ML-BOM, eval
  scorecards) attach signed statements *about* the
  artefact. Admission policy checks each attestation's
  content, not just its envelope.
- **Distinct identities per artefact class** — training
  signer, intake signer, eval signer, deploy signer —
  limit the blast radius of any one identity compromise.
- **The sigstore Kubernetes policy-controller** enforces
  signature + attestation policy at admission time; the
  same policy language is what mod-109 chapter 04 wraps
  into org-wide governance.
