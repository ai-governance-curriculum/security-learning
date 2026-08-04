# Chapter 02 — Cosign and Sigstore: Signing Model Artifacts in the Training Pipeline

> **Note on AI-assisted content.** Verify cosign CLI syntax and
> Sigstore API versions against the current
> [sigstore.dev](https://www.sigstore.dev/) documentation before
> using in production; the CLI has changed flag names between
> minor versions. See [`resources.md`](./resources.md).

---

## Why this chapter exists

Chapter 01 named signing as the trust anchor the admission gate
(mod-103 chapter 06) verifies. This chapter authors the actual
signing.

The specific failure mode this chapter is written to prevent:

> A team enables cosign in CI. Their workflow does
> `cosign sign --key env://COSIGN_KEY $IMAGE`. The key lives in a
> Kubernetes secret used by every CI runner. The verification
> policy at admission time accepts "any cosign signature". Six
> months later, a compromised CI dependency exfiltrates the key.
> The attacker signs a backdoored model artifact with the same
> key. Admission passes. The signature-verification claim is
> literally true — the artifact *was* signed by the key — and
> tells you nothing about whether it should have been.

Cosign is the signing tool; **cosign done well** is the
combination of:

1. **Keyless signing** via short-lived, workload-attested
   identities (Fulcio-issued certificates bound to a SPIFFE ID or
   an OIDC subject).
2. **Transparency-log inclusion** via Rekor, so the
   signing event is publicly (or privately) auditable.
3. **Verification policy** that pins the *signer identity*, not
   just the *signature validity*.
4. **Digest-pinning** of the artifact under signature so the
   signature travels with the exact bytes.

This chapter walks each piece, applied to ML model artifacts
specifically (which are usually pickle / safetensors weight
files, not container images — a distinction that changes the
packaging).

You leave this chapter able to:

- Package a trained model artifact for OCI-based signing.
- Configure a training pipeline to sign the artifact keylessly
  with its attested workload identity.
- Attach a signature to a Sigstore/Rekor transparency log entry.
- Author a `CosignVerificationPolicy` (or Rego constraint) that
  the mod-103 admission gate consumes.
- Rotate signers safely and revoke a compromised identity
  without breaking historical deployments.

---

## What Sigstore is, briefly

**Sigstore** is a set of open-source infrastructure for
signing, verifying, and attesting to software artifacts:

- **Cosign** — CLI + libraries for signing OCI artifacts
  (images, and any OCI-referenceable blob including model
  weights).
- **Fulcio** — a free code-signing certificate authority.
  Issues short-lived X.509 certificates whose Subject Alternative
  Name (SAN) is bound to an OIDC identity token — typically the
  identity of the CI workload that requested it.
- **Rekor** — an append-only, tamper-evident transparency log
  built on Trillian. Every signature is appended; anyone can
  fetch a proof that a given signature was included, at a
  specific tree size, at a specific time.
- **The public-good instance** (`fulcio.sigstore.dev`,
  `rekor.sigstore.dev`) is community-run; organisations that
  need control run their own — see [Sigstore private
  deployment](https://docs.sigstore.dev/) — or use vendor
  services (GitHub's `sigstore-go` integration, cloud-provider-
  hosted equivalents).

The trust model matters: **cosign sign + Fulcio + Rekor** shifts
verification from *"do you hold this key?"* to *"was this
signing event witnessed by an append-only log, signed by a
certificate whose subject matches an allow-list?"* The key
management burden collapses; the identity-management burden
becomes explicit.

---

## Two signing modes: keyed and keyless

Cosign supports both keyed and keyless signing. Understand both;
prefer keyless in modern pipelines.

### Keyed signing (legacy)

```
cosign generate-key-pair                           # produces cosign.key, cosign.pub
cosign sign --key cosign.key $ARTIFACT_REFERENCE   # signs
cosign verify --key cosign.pub $ARTIFACT_REFERENCE # verifies
```

Trust root: whoever holds `cosign.key`.

Problems in an ML pipeline:

- The key is a long-lived secret. Every CI runner that signs
  needs access. Every rotation invalidates every past-cached
  reference to the old key unless the verifier is updated.
- Compromise of a runner is compromise of the key. Blast radius:
  every artifact that key can be used to sign until rotation.
- The "who signed" question devolves to "who had the key",
  which is not answerable from the signature alone.

Keyed signing has legitimate uses (air-gapped builds, offline
signing of release artifacts, HSM-backed release ceremonies —
mod-105 territory). In-pipeline ML signing is rarely one of
them.

### Keyless signing (preferred for ML pipelines)

```
COSIGN_EXPERIMENTAL=1 cosign sign $ARTIFACT_REFERENCE
```

What actually happens under the hood:

1. Cosign asks the pipeline runtime for an OIDC ID token — from
   GitHub Actions, GitLab CI, Buildkite, Kubernetes' projected
   service-account token, or SPIRE's `spire-agent` OIDC
   federation endpoint. The token's `sub` identifies the
   workload.
2. Cosign generates an ephemeral keypair *in memory*.
3. Cosign sends the OIDC token and the ephemeral public key to
   Fulcio. Fulcio verifies the token, and issues a short-lived
   X.509 certificate (usually 10 minutes) whose SAN encodes
   the OIDC subject.
4. Cosign signs the artifact digest with the ephemeral key,
   producing a signature bundle: `{signature, cert, cert
   chain}`.
5. Cosign uploads the bundle to Rekor. Rekor returns an
   inclusion proof and a signed entry timestamp.
6. Cosign attaches the bundle (signature, certificate chain,
   Rekor UUID) to the artifact reference — for OCI, in the
   `.sig` tag.
7. The ephemeral key is discarded. No long-lived secret exists.

Verification then reduces to:

1. Fetch the signature bundle from the artifact reference (or
   from Rekor).
2. Verify the signature against the ephemeral public key.
3. Verify the ephemeral public key was issued by Fulcio to an
   OIDC identity that matches the verification policy.
4. Verify the Rekor inclusion proof establishes the signing
   event happened at a time consistent with the certificate's
   validity window.

Trust root: **the OIDC identity provider + Fulcio's CA + Rekor's
tree.** All three are consulted at verification; all three are
independently auditable.

---

## Packaging model artifacts for OCI-based signing

Cosign signs by OCI reference. Container images have obvious
OCI references; model weights (`.safetensors`, `.pt`,
`.bin`, `.gguf`) do not — until you package them.

Two acceptable packagings:

### Option A — model weights as an OCI artifact (`oras`)

Use ORAS (OCI Registry As Storage) to push the weights as an
OCI artifact:

```
oras push registry.acme.local/models/fraud/v42:2026-04-01 \
    --artifact-type application/vnd.acme.ml.model.v1+json \
    weights.safetensors:application/vnd.acme.ml.weights.safetensors \
    tokenizer/tokenizer.json:application/vnd.acme.ml.tokenizer.v1+json \
    config.json:application/vnd.acme.ml.config.v1+json
```

The push returns a digest. Signing then works exactly as for a
container image:

```
COSIGN_EXPERIMENTAL=1 cosign sign \
    registry.acme.local/models/fraud/v42@sha256:${DIGEST}
```

This is the recommended shape when the platform already has an
OCI registry (Harbor, JFrog Artifactory OCI, ECR, GAR, GHCR).
The OCI registry is the same store the admission gate already
consults, so both the container image and the model weights live
in one addressable index.

### Option B — model weights as a blob signed alongside a manifest

If the platform stores weights on object storage (S3, GCS) and
does not want to add an OCI hop, cosign can sign an arbitrary
blob by hash:

```
sha256sum weights.safetensors > weights.sha256
cosign sign-blob --bundle weights.bundle weights.safetensors
```

The bundle is a self-contained signature-plus-Rekor-proof file
that lives next to the weights in object storage. Verification:

```
cosign verify-blob \
    --bundle weights.bundle \
    --certificate-identity-regexp "..." \
    --certificate-oidc-issuer-regexp "..." \
    weights.safetensors
```

Option B is simpler operationally but pushes the "how does the
serving pod discover the bundle?" problem to the platform. Prefer
option A when the OCI registry is already in the path.

### Whichever packaging: sign the digest, never the tag

Signatures are on digests. If the pipeline signs by tag
(`:2026-04-01`), the tag can be repointed after signing and the
signature no longer describes the current bytes. Resolve to
digest before signing, always.

---

## Wiring cosign into the training pipeline — reference workflows

The signing step lives at the *end* of the training pipeline,
after the model artifact digest is known and before the artifact
is promoted to `latest` or handed to the release gate. Two
common runners:

### GitHub Actions example

```yaml
name: train-and-sign
on:
  workflow_dispatch:
    inputs:
      dataset_version:
        required: true

permissions:
  id-token: write   # required to obtain the OIDC token cosign uses
  contents: read
  packages: write   # if pushing to GHCR

jobs:
  train:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Train
        run: python -m training.train \
             --dataset ${{ inputs.dataset_version }} \
             --out ./out
      - name: Package as OCI artifact
        uses: oras-project/setup-oras@v1
      - id: push
        run: |
          DIGEST=$(oras push ghcr.io/${{ github.repository }}/model:${{ github.run_id }} \
            --artifact-type application/vnd.acme.ml.model.v1+json \
            ./out/weights.safetensors:application/vnd.acme.ml.weights.safetensors \
            ./out/tokenizer.json:application/vnd.acme.ml.tokenizer.v1+json \
            ./out/config.json:application/vnd.acme.ml.config.v1+json \
            --format json | jq -r '.reference')
          echo "digest=${DIGEST}" >> "$GITHUB_OUTPUT"
      - uses: sigstore/cosign-installer@v3
      - name: Sign the artifact (keyless)
        env:
          COSIGN_EXPERIMENTAL: "1"
        run: |
          cosign sign --yes ${{ steps.push.outputs.digest }}
```

The `permissions.id-token: write` grant is what allows the
Actions runtime to mint the OIDC token cosign presents to Fulcio.
The signing certificate's SAN will encode the workflow's
identity — e.g.
`https://github.com/acme-org/model-repo/.github/workflows/train-and-sign.yml@refs/heads/main`.
The verification policy (below) matches on that SAN.

### Kubernetes / Argo Workflows / Kubeflow example (SPIFFE-backed OIDC)

When the training runs in-cluster, use the mod-103 SPIFFE
identity as the OIDC subject. SPIRE exposes an OIDC federation
endpoint; Fulcio can be configured to trust it (either via the
public-good Fulcio instance's federated issuers list or via a
private Fulcio instance under organisational control).

```yaml
# Argo Workflow step (excerpt)
- name: sign-model
  container:
    image: ghcr.io/sigstore/cosign:v2
    env:
      - name: COSIGN_EXPERIMENTAL
        value: "1"
      - name: COSIGN_OIDC_ISSUER
        value: "https://spire-oidc.acme.internal"
      - name: COSIGN_FULCIO_URL
        value: "https://fulcio.acme.internal"
      - name: COSIGN_REKOR_URL
        value: "https://rekor.acme.internal"
      - name: SPIFFE_ENDPOINT_SOCKET
        value: "unix:///run/spire/sockets/agent.sock"
    volumeMounts:
      - name: spire-agent-socket
        mountPath: /run/spire/sockets
        readOnly: true
    command:
      - sh
      - -c
      - |
        cosign sign --yes \
          --identity-token "$(spire-agent api fetch jwt \
             -audience sigstore -socketPath /run/spire/sockets/agent.sock | head -1)" \
          registry.acme.internal/models/fraud@${MODEL_DIGEST}
```

The SPIFFE JWT-SVID carries the workload's SPIFFE ID (e.g.
`spiffe://acme.internal/plane/training/pipeline/fraud-trainer`).
Fulcio issues a certificate whose SAN is that URI. Verification
policy pins that SAN.

### Emit the signing event to the audit sink

Whichever runner, the training pipeline should also emit a
structured event to the audit sink (chapter 06):

```json
{
  "event": "model.signed",
  "artifact": "registry.acme.internal/models/fraud@sha256:abc...",
  "signer_identity": "spiffe://acme.internal/plane/training/pipeline/fraud-trainer",
  "rekor_uuid": "24296fb24b8ad77a...",
  "timestamp": "2026-04-01T14:22:11Z",
  "pipeline_run_id": "argo-workflows/fraud-training-2026-04-01-abc123"
}
```

Signature-only-in-Rekor is fine, but the audit stream is what
SIEM (mod-111) consumes for detection ("unexpected signer",
"signing outside change-window", "signing burst").

---

## Verification policy — the second half of the trust chain

A signature that verifies against "any Fulcio cert" is
approximately no verification. The verifier must pin the
signer identity.

### `cosign verify` for CI-time or ad-hoc checks

```
cosign verify \
    --certificate-identity-regexp "^spiffe://acme\\.internal/plane/training/pipeline/[a-z0-9-]+$" \
    --certificate-oidc-issuer "https://spire-oidc.acme.internal" \
    registry.acme.internal/models/fraud@sha256:${MODEL_DIGEST}
```

Every flag matters:

- `--certificate-identity-regexp` pins the SAN pattern. This is
  the allow-list. Wildcarding the identity defeats the check.
- `--certificate-oidc-issuer` pins the token issuer. Even with
  a matching SAN, a cert from a different issuer is rejected —
  otherwise anyone with an OIDC provider that Fulcio trusts and
  a matching-looking subject could sign.
- The digest (`@sha256:...`) pins the bytes. Verifying by tag
  is a race condition.

### Policy-controller / Kyverno equivalents at admission

The mod-103 chapter 06 admission gate is where this verification
runs in production. Two implementations you will see:

**Sigstore policy-controller.** A Kubernetes admission
controller that consumes `ClusterImagePolicy` CRDs:

```yaml
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: models-must-be-signed
spec:
  images:
    - glob: "registry.acme.internal/models/**"
  authorities:
    - name: acme-training-pipelines
      keyless:
        url: https://fulcio.acme.internal
        identities:
          - issuer: https://spire-oidc.acme.internal
            subjectRegExp: "^spiffe://acme\\.internal/plane/training/pipeline/[a-z0-9-]+$"
      ctlog:
        url: https://rekor.acme.internal
```

**Kyverno `verifyImages` rule.** Similar shape, Kyverno-native
policy language.

**OPA / Gatekeeper external-data.** Mod-103 chapter 06 shows
the constraint template shape. The external-data provider calls
`cosign verify` (or the equivalent library) with the flags
above.

### Match issuer *and* subject *and* pin the digest

Three checks, all required:

1. The issuer is on the allow-list (`sigstore.dev`,
   `spire-oidc.acme.internal`, `token.actions.githubusercontent.com`,
   whatever set of federated issuers the organisation trusts).
2. The subject matches the SAN allow-list (specific SPIFFE ID
   or specific GitHub workflow path).
3. The verified digest matches the deployed digest.

Skipping any one of the three collapses the property.

---

## Rekor: what the transparency log gets you

Rekor's role is not "hold the signature" — the signature is on
the artifact. Rekor's role is **inclusion proof**: given a
signature, prove it was appended to an append-only log at some
point in time, and prove the log hasn't been rewritten since.

Concretely:

- Every cosign signing event is appended to Rekor as a signed
  entry. The entry contains the artifact digest, the signature,
  and the signing certificate.
- Rekor returns a **signed entry timestamp** and an
  **inclusion proof** (a Merkle-tree path from the entry to the
  current tree head).
- Rekor periodically publishes the tree head; monitors watch
  for non-linear rewrites.

What this gives the verifier:

- **Non-repudiation.** The signer cannot later say "I didn't
  sign that." The Rekor entry is auditable evidence.
- **Detectability of key compromise.** If an attacker steals a
  signing identity's short-lived cert and signs something
  unexpected, the entry lands in Rekor. A monitor watching for
  signatures under expected identities can flag it.
- **Timestamping.** The signed entry timestamp is stronger
  evidence of "signed before this date" than a machine-local
  clock.

### Public-good vs private Rekor

- **`rekor.sigstore.dev`** is the community-run instance. Free.
  Public — every entry is world-visible.
- **Private Rekor** (self-hosted Trillian + Rekor) is the choice
  when the organisation does not want the signing events
  (which reveal model naming, timing, and metadata) exposed
  publicly.

Choose private Rekor for anything commercially sensitive.
Enrolling both a public and a private Rekor is possible and is
sometimes done for release artifacts (public claim of
authenticity) plus internal ones (private log).

---

## Rotation and revocation

Cosign keyless signing shifts the rotation problem — but does
not eliminate it. Two rotation classes:

### Rotating the signing identity

Because Fulcio certs are short-lived (~10 minutes), the identity
"rotates" every signing event. What rotates *slowly* is the
SPIFFE ID / OIDC subject the verification policy pins.

If the CI moves from `fraud-trainer` to `fraud-trainer-v2`,
update the verification policy allow-list to accept both, wait
for all past-signed artifacts to be re-signed or retired, then
remove `fraud-trainer`.

### Revoking a compromised identity

If a workload identity is compromised (attacker stole a
short-lived cert, or the SPIFFE registration was tampered):

1. **Immediately** remove the identity from the verification
   allow-list (`ClusterImagePolicy` update). This blocks new
   deployments under that identity.
2. Rotate the workload's SPIFFE ID (change the selector) so
   Fulcio's next issued cert has a different SAN.
3. Enumerate every artifact ever signed by the compromised
   identity via Rekor query (`rekor-cli search --sha ...` or by
   OIDC subject). Determine which are still in production.
4. For each still-deployed compromised-signed artifact,
   re-sign under a clean identity and re-deploy; or roll back
   to a known-good prior signature.
5. Amend the audit log with the incident record (mod-111
   territory).

The revocation window is *the time between compromise and
allow-list update*. Short-lived Fulcio certs limit the attacker's
signing window; the allow-list update is what actually blocks
verification.

### Handling verifier drift across signature ages

A common operational trap: cosign / Fulcio / Rekor APIs and
certificate validity windows evolve. A signature made two years
ago against a Fulcio root that has since been rotated may fail
verification unless:

- The verifier maintains a rooted list of past Fulcio roots
  (TUF-managed root of trust — Sigstore's TUF root is the
  standard mechanism).
- The verifier is willing to trust the Rekor inclusion proof as
  evidence that the signature was valid *at signing time*, even
  if the cert has since expired.

Configure the verifier accordingly. Do not build a system where
last year's signatures are unverifiable this year — that breaks
the retention chain from chapter 01.

---

## Model-format-specific gotchas

### Pickle / joblib weights

`.pkl` and `.joblib` files execute arbitrary code on load.
Signing tells you *who produced* the file; it does not tell you
*it is safe to load*. Combine signature verification with
ModelScan (or equivalent) *at admission time* (mod-103 chapter 06
gate 3) — signing is not a substitute for scanning.

### Safetensors weights

`.safetensors` is a format specifically designed to be
non-executable-on-load — the file contains only tensors, not
code. Signing plus format-validation (`safetensors` library's
built-in header check) is enough to establish "this file is what
the training pipeline produced and it is not going to execute
code on load". Prefer `.safetensors` over pickle for any new
pipeline.

### Multi-file model bundles (weights + tokenizer + config + adapter)

Sign the manifest, not the individual files. The ORAS artifact
push above creates a manifest with layers for each file; the
signature is on the manifest digest. Any file substitution
changes the manifest digest and invalidates the signature.

If storing on object storage without a manifest, compute a
Merkle root over the sorted-by-name file digests and sign the
root — do not sign each file individually and rely on the
verifier to check all of them.

### GGUF / quantised weights

The same principle: package as an OCI artifact (or write a
signed manifest) so the signature covers the artifact
canonicalisation, not a single file.

### LoRA adapters and fine-tune deltas

An adapter is its own artifact with its own base-model
dependency. Sign the adapter separately. The ML-BOM
(chapter 04) is what names "base model X + adapter Y" as a
composition; do not blur the two into a single signed blob.

---

## What this chapter does not cover

- **Signing-key HSM management.** Even in keyless mode, Fulcio
  has a root CA whose keys must live somewhere trustworthy;
  mod-105 handles the KMS / HSM decisions.
- **The training pipeline itself.** Signing sits at the *end* of
  the pipeline. The security of the *inputs* to that pipeline
  (dataset ingestion, dependency pinning, isolation) is mod-110
  supply-chain.
- **Provenance predicate authoring.** Cosign signs; SLSA
  provenance is a specific in-toto predicate the signature
  attests to. Chapter 03 walks the predicate shape and the
  in-toto envelope. This chapter is about the signature; chapter
  03 is about what the signature is *over*.

---

## The mistakes this chapter is trying to prevent

- **Long-lived signing keys in CI.** Keyless mode makes them
  unnecessary. If you keep them anyway, they will be exfiltrated.
- **Wildcard verification policies.** `subjectRegExp: ".*"` is
  no policy.
- **Skipping the issuer pin.** Matching the subject but not
  the issuer lets any OIDC provider that Fulcio trusts sign as
  your identity.
- **Signing by tag.** Tags are mutable; signatures on tags are
  worthless once the tag is repointed. Resolve to digest,
  always.
- **Signing pickle without scanning.** Signature is producer
  authenticity, not load safety. Scan too.
- **Signing individual files instead of the manifest.** A
  five-file bundle needs one signature on the composed
  manifest, not five signatures the verifier hopes are all
  checked.
- **Ignoring Rekor.** Signatures without transparency-log
  inclusion give up the "was this signing event witnessed"
  property that closes the "were you signed by the identity you
  claim, and were you signed when you say you were" gap.
- **Emitting no audit event for signing.** SIEM detection
  requires the pipeline to publish "I signed X at time T under
  identity I"; without that, unexpected signing is not
  detectable.

---

## Summary

- Cosign signs OCI-referenceable artifacts (via ORAS) or blobs;
  Sigstore composes cosign + Fulcio (short-lived certs bound to
  OIDC identity) + Rekor (transparency log) into a keyless
  signing story that removes long-lived signing keys from CI.
- ML model artifacts should be packaged as OCI artifacts with
  ORAS so the entire multi-file bundle (weights + tokenizer +
  config + adapter) is covered by one manifest digest and one
  signature.
- Keyless signing wired into the training pipeline uses the
  runner's OIDC identity (GitHub Actions token, GitLab
  `CI_JOB_JWT`, SPIRE JWT-SVID for in-cluster runs). The
  verifier pins issuer, subject regex, and deployed digest.
- Rekor gives non-repudiation, detectability of unexpected
  signing, and independent timestamping. Prefer private Rekor
  for commercially sensitive artifacts; retain the public
  option only for artifacts that are explicitly public.
- Rotation is per-event (short-lived certs) for identity, and
  policy-driven (allow-list update) for the SPIFFE / OIDC
  subject. Revocation is an allow-list update plus a Rekor
  audit of past signings under the compromised identity.
- Model-format gotchas: safetensors preferred over pickle; sign
  the manifest, not individual files; scan pickled weights
  regardless of signature.
- This chapter emits the signature the mod-103 admission gate
  verifies; chapter 03 authors the SLSA / in-toto provenance
  predicate the signature is over.
