# Exercise 02 — Cosign Signing of Model Artifacts (End-to-End Wire-Up)

**Estimated effort:** ~3 hours
**Deliverable:** A working, version-controlled training-pipeline
change that (a) packages a model artifact as an OCI artifact,
(b) signs and attests it via cosign keyless with an authenticated
workload identity, (c) publishes the signature and attestations
to a transparency log, and (d) is accompanied by a
`cosign verify` / `ClusterImagePolicy` verifier that pins the
signer identity. Plus a design memo (~2 pages) covering signing
identity, rotation, and revocation.
**Prerequisites:** Chapters 01, 02, and 03 read end-to-end.
Exercise 01 completed for the target pipeline. A GitHub Actions
account, a GitLab CI account, or an in-cluster Argo / Kubeflow
pipeline you can modify. Cosign v2+ installed locally.

---

## Objective

Wire cosign into the target training pipeline so that:

1. Every model artifact produced by the pipeline is packaged as
   an OCI artifact addressable by digest.
2. Every artifact is signed keylessly by the pipeline's attested
   workload identity (GitHub Actions OIDC, GitLab `CI_JOB_JWT`,
   or SPIRE JWT-SVID).
3. The signature is published to a Rekor transparency log
   (public-good or private, per the design memo).
4. A SLSA v1 provenance attestation is attached (chapter 03
   `cosign attest --type slsaprovenance1`).
5. A verifier — either `cosign verify` in a follow-on CI step
   or a `ClusterImagePolicy` at admission — is authored and
   demonstrated to reject unsigned artifacts and artifacts
   signed by a non-allow-listed identity.

## Problem statement

Continue with the `fraud` training pipeline from exercise 01.
The current pipeline produces `weights.safetensors`,
`tokenizer.json`, and `config.json` at the end of a training
run. It writes them to an S3 prefix and registers them in
MLflow. Nothing is signed; there is no OCI packaging; there is
no verifier at the consuming end.

Your job:

- Extend the pipeline to package the three files as a single
  OCI artifact via ORAS.
- Add the cosign signing and SLSA attestation steps.
- Author the verifier that (a) rejects unsigned artifacts, (b)
  rejects artifacts signed by the wrong identity, (c) rejects
  artifacts whose signed digest does not match the deployed
  digest.
- Demonstrate the negative-path rejections work by attempting
  three specific tampering scenarios and capturing the
  verifier's rejection output.

If you have a real pipeline you can safely modify, use it. If
not, spin up a minimal reference — a GitHub Actions workflow in
a scratch repository, an OCI registry (GHCR / a local
`registry:2`), and a scratch verifier — is sufficient. The
learning is in the composition, not the toy training run.

## Requirements

### Deliverable A — pipeline changes

Version-controlled changes to a training pipeline that:

- Package the model as an OCI artifact using ORAS with an
  organisation-specific `--artifact-type` MIME (e.g.
  `application/vnd.acme.ml.model.v1+json`) and one layer per
  file (weights / tokenizer / config) with distinct layer
  MIMEs.
- Compute the artifact digest post-push and pass it downstream
  by value (never by tag).
- Sign the artifact keylessly with `cosign sign --yes`, using:
  - The runner's OIDC identity (GitHub Actions token, GitLab
    `CI_JOB_JWT`, or SPIRE JWT-SVID via the SPIRE agent
    socket), issued by an OIDC provider on your organisation's
    allow-list.
  - The public-good Sigstore instance (`sigstore.dev`) OR a
    self-hosted Fulcio + Rekor deployment. Which you pick is
    a design-memo decision.
- Attach a SLSA v1 provenance attestation with `cosign attest
  --predicate <file> --type slsaprovenance1`. The predicate
  content is not the focus of this exercise (that is exercise
  03); a minimally-populated predicate that includes source
  URI + revision, resolved dependencies (at least one
  dataset URI + digest), and builder ID is sufficient.
- Emit an audit event to the audit stream (chapter 06 shape)
  containing artifact digest, Rekor UUID, and signer identity.

The pipeline change must run to completion end-to-end and
produce a signed, attested, Rekor-logged artifact.

### Deliverable B — the verifier

Either:

- **A follow-on CI step** that runs `cosign verify` with the
  full flag set from chapter 02 (`--certificate-identity-
  regexp`, `--certificate-oidc-issuer`, digest reference),
  OR
- **A `ClusterImagePolicy`** (Sigstore policy-controller)
  applied to a `serving` namespace on a Kubernetes cluster
  (kind / minikube / a real cluster), which rejects
  admission when applied to a `Deployment` or
  `InferenceService` referencing an unsigned or wrong-signer
  artifact.

Whichever you pick, the verifier's identity policy MUST NOT be
a wildcard. It MUST pin issuer and subject.

### Deliverable C — negative-path demonstrations

Attempt these three tampering scenarios and capture the
verifier's rejection output (screenshot or transcript, checked
into the exercise directory):

1. **Unsigned artifact.** Push an artifact to the registry
   without signing it, then run the verifier. Expected: reject.
2. **Signed by wrong identity.** Sign an artifact with an
   identity outside the allow-list (a personal
   `cosign generate-key-pair` local key, or a keyless sign
   from a different repository / different SPIFFE ID), then
   run the verifier. Expected: reject.
3. **Signed for a different digest.** Take a valid signature
   for artifact A and attempt to use it to admit a deployment
   pointing at artifact B (either by manually crafting the
   verify command or by mutating the registry entry).
   Expected: reject.

For each, the output must clearly identify *why* the
verification failed.

### Deliverable D — design memo (~2 pages)

Cover the following, in prose:

- **Signing identity design.** What OIDC issuer, what SPIFFE
  ID template, what allow-list pattern in the verifier. What
  namespaces of identities are permitted to sign for what
  registries / namespaces.
- **Public-good vs private Sigstore choice.** Which you
  picked and why. Which of the following trade-offs you
  accepted: privacy of signing events (public Rekor exposes
  them), operational burden of running Fulcio + Rekor +
  Trillian internally, availability of the public-good
  instance vs your compliance posture.
- **Rotation.** How the SPIFFE ID / OIDC subject rotates.
  What happens to past-signed artifacts when the identity
  moves. When (if ever) the underlying Fulcio root changes
  and how you preserve verifiability of old signatures (TUF
  root, cached-root pinning).
- **Revocation.** Step-by-step response to a hypothetical
  "identity compromised" incident. What allow-list update
  happens first. How you enumerate past artifacts signed by
  the compromised identity via Rekor. What re-signing /
  rollback / removal actions follow. How the incident is
  audited.
- **Failure modes rejected.** Explicitly call out which of
  the chapter-02 failure modes you have prevented (wildcard
  identity, missing issuer pin, signing by tag, single-file
  signing without manifest, no Rekor inclusion, no audit
  event emission).

## Starter guidance

- Use `sigstore/cosign-installer@v3` (or newer) in GitHub
  Actions; the `permissions: id-token: write` grant is
  required for keyless.
- ORAS is a separate tool; install with `oras-project/setup-
  oras@v1` or brew equivalent. Read the ORAS quickstart before
  starting.
- For the local reference deployment: `docker run
  registry:2` gives you an OCI registry on `localhost:5000`.
  Cosign works against it directly.
- Use safetensors for the weights file, not pickle. If you
  don't have real weights, `python -c "import safetensors.torch;
  safetensors.torch.save_file({'w': torch.zeros(10, 10)},
  'weights.safetensors')"` produces a valid one for the
  packaging round-trip.
- Do NOT hand-hold the negative path — actually attempt the
  tampering and observe the failure. The pedagogic value is
  in reading the failure message.
- For the SPIRE variant, running SPIRE in a kind cluster is
  a half-day of setup on its own; unless you are already
  running SPIRE (mod-103 exercise 02 deliverable), the GitHub
  Actions or GitLab OIDC path is faster.

## Acceptance criteria

Passing work:

- The pipeline runs to completion and produces a signed,
  attested, Rekor-logged artifact on the target registry.
- `cosign verify` (or the `ClusterImagePolicy`) admits the
  produced artifact when run with the pinned identity.
- All three negative-path scenarios reject with clear
  messages captured in the exercise directory.
- The design memo answers rotation and revocation
  concretely, not with "we would do that later".
- No wildcard identity anywhere in the verifier.
- No signing by tag; digests everywhere.

Failing work:

- The verifier's `--certificate-identity-regexp` is `.*` or
  effectively-wildcard.
- The verifier is missing `--certificate-oidc-issuer`.
- The pipeline signs by tag rather than digest.
- The three negative-path scenarios pass verification (a
  configuration bug — investigate before submitting).
- The design memo defers rotation / revocation to "future
  work" without answering.
- No SLSA attestation is attached, or the attestation is
  attached with `--type custom` and no predicate type URI.

## Stretch goals

- Add a **transparency-log monitor** — a small script that
  polls Rekor for signatures matching the allow-listed
  identity and alerts on unexpected artifact digests. This is
  the detection surface for a "identity compromised, adversary
  signed something we didn't expect" event.
- Sign the ORAS artifact via a **detached blob signature**
  path (`cosign sign-blob`) in addition to the OCI-attached
  path, and compare — enumerate which downstream verifier
  patterns each supports.
- Wire a second signer identity (**dual-sign**) so both the
  training pipeline and a release-approval workflow must sign
  before the artifact is admitted. Author the verifier that
  requires both.
- Extend the negative-path list with a **tag-repointing
  attack**: point a tag at a new digest after signing and
  demonstrate that a deployment using the tag reference
  (rather than a digest reference) can be swapped even though
  a "signature exists". This is the failure mode that
  justifies digest-only deployments.

## Do not

- Do not use long-lived signing keys stored in secrets. Use
  keyless.
- Do not commit `cosign.key` or any private key to the
  repository.
- Do not commit a solution to this repository.
- Do not use the `--allow-insecure-registry` flag against
  registries that require TLS — configure the registry
  properly instead.
