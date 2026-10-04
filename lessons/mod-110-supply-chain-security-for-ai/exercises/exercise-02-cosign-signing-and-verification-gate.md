# Exercise 02 — cosign Signing and Verification Gate

**Estimated effort:** ~3 hours
**Deliverable:** A working signing + verification pipeline
end-to-end on one real model artefact, consisting of
(a) a **signing pipeline step** that produces a signed OCI
model artefact and at least two signed attestations
(SLSA Provenance v1 and CycloneDX ML-BOM) using **keyless**
cosign, (b) a **verifier harness** that enforces signature
validity, pinned certificate identity, transparency-log
inclusion, and attestation-content policy, (c) a documented
**failure-mode walkthrough** that proves the gate catches
the five canonical misuses — unsigned artefact, wrong
signer identity, missing attestation, bad-content
attestation, tag-swap after signing — with reproducible
transcripts, (d) a **Kubernetes admission policy** sketch
(sigstore policy-controller `ClusterImagePolicy`, Kyverno
`ClusterPolicy`, or Gatekeeper constraint) that would
enforce the same gate at Pod admission, (e) a documented
**trust-root choice** (public sigstore vs private
Fulcio/Rekor) with the trust-bundle configuration consumers
would use, and (f) a **key-rotation / identity-migration
runbook** stating how a change in the signing identity is
rolled out without breaking downstream verification.
**Prerequisites:** Chapter 02 read end-to-end; chapter 01
read for the attestation context. A workstation with
`cosign` installed (verify version against the current
release), an OCI registry you can push to (local
`distribution/registry`, a GHCR / GCR / ACR / ECR you own,
or `ttl.sh` for ephemeral experiments). An OIDC identity to
sign under — GitHub Actions workflow identity, a Google
service account for GCP workloads, or a workstation login
via sigstore's `oauthflow` — and a published certificate-
identity policy you can pin verifiers to.

---

## Objective

Chapter 02's thesis is that *signing without a verifier
with policy is theatre*. This exercise is the exercise
that stands up both halves: a signing step producing
cryptographically valid, policy-shaped signatures and
attestations; and a verifier that fails when any of the
five canonical misuses happens. By the end you have
command transcripts, policy files, and a runbook — the
artefacts a programme would reuse unchanged.

By the end of this exercise you have:

- A signed OCI model artefact in your chosen registry,
  signed by a **keyless OIDC-bound identity** (public
  sigstore or your internal Fulcio).
- At least **two signed attestations** attached to the
  artefact: a SLSA Provenance v1 attestation and a
  CycloneDX (ML-BOM) attestation.
- A **verifier harness** (`verify.sh` or `make verify`)
  that performs all three cosign checks (signature
  validity, pinned identity, transparency-log inclusion)
  plus content policy over the attestations.
- **Reproducible transcripts** of five canonical
  verification failures with the exact command and the
  exact error.
- A **Kubernetes admission policy** YAML that enforces
  the gate at Pod admission.
- A one-page **trust-root choice** writeup.
- A one-page **key-rotation runbook**.

You are **not** running the gate against every artefact
in your fleet. You are producing a working reference
pipeline that could be rolled out as the baseline.

---

## Problem statement

Pick one model artefact. Options:

- An internal model your team already produces (ideal if
  possible).
- A pre-trained open-weights model (DistilBERT, GPT-2
  small, a Mistral variant) pulled from HF Hub,
  repackaged as an OCI artefact via ORAS. The point of
  this exercise is the *signing / verification*, not the
  model.
- A toy model you build in the exercise (fine-tune on a
  tiny dataset; save as safetensors; package).

State before you start:

- The artefact (digest once pushed).
- The registry (and whether it is a scratch registry like
  `ttl.sh`, a local `distribution/registry`, or a
  production registry your org owns).
- The signing identity you will use — the OIDC issuer and
  the certificate subject the identity will carry (e.g.
  `repo:owner/name:ref:refs/heads/main` for GitHub
  Actions, `training-runner@my-project.iam.gserviceaccount.
  com` for GCP, your email for an interactive workstation
  signing).
- The trust root (public sigstore vs private
  Fulcio/Rekor).

If this is your first time with cosign, use the public
sigstore for the exercise. If your organisation has a
private sigstore, use that; capture the trust-bundle
retrieval and verification steps as part of Deliverable E.

---

## Requirements

### Deliverable A — signing pipeline step

A short script or CI job (`sign.sh`, a GitHub Actions
workflow, a Makefile target) that:

1. **Packages** the model as an OCI artefact. Use `oras
   push` for raw weight files; use `docker build` for
   container images.
2. **Captures the digest.** The output is `sha256:...`;
   downstream commands reference by digest, never by tag.
3. **Signs the artefact** with keyless cosign:
   ```bash
   cosign sign \
     --oidc-issuer https://token.actions.githubusercontent.com \
     $REGISTRY/$NAME@sha256:$DIGEST
   ```
   Record the exact OIDC issuer and the subject the
   resulting certificate carries.
4. **Attaches a SLSA Provenance v1 attestation.** Use the
   sample predicate from exercise 01 as the content:
   ```bash
   cosign attest \
     --predicate slsa-provenance.json \
     --type slsaprovenance \
     --oidc-issuer <issuer> \
     $REGISTRY/$NAME@sha256:$DIGEST
   ```
5. **Attaches a CycloneDX ML-BOM attestation.** Use a
   minimal ML-BOM (exercise 03 produces the full version;
   a small ML-BOM covering the model + base model + one
   dataset is enough here):
   ```bash
   cosign attest \
     --predicate mlbom.json \
     --type cyclonedx \
     --oidc-issuer <issuer> \
     $REGISTRY/$NAME@sha256:$DIGEST
   ```
6. **Prints the Rekor entry index** for each
   signature / attestation; capture the index in the
   signing log.

Script output: the artefact digest, the signatures'
Rekor indices, and the attestations' Rekor indices.
Commit the script to the exercise bundle alongside the
output.

### Deliverable B — verifier harness

A script (`verify.sh`, a CI check, a Makefile target) that:

1. **Verifies the artefact signature.** Pinned
   `--certificate-identity` or `--certificate-identity-
   regexp`; pinned `--certificate-oidc-issuer`; **no
   `--insecure-skip-verify` or `--offline`.**
   ```bash
   cosign verify \
     --certificate-identity-regexp '^<regex matching your signer subject>$' \
     --certificate-oidc-issuer '<issuer>' \
     $REGISTRY/$NAME@sha256:$DIGEST
   ```
2. **Verifies the SLSA Provenance attestation + content
   policy.**
   ```bash
   cosign verify-attestation \
     --type slsaprovenance \
     --certificate-identity-regexp '^<regex>$' \
     --certificate-oidc-issuer '<issuer>' \
     $REGISTRY/$NAME@sha256:$DIGEST \
     | jq -r '.payload | @base64d | fromjson' > provenance.json

   # Content policy: builder.id, buildType, resolvedDependencies.
   jq -e '
     .predicate.runDetails.builder.id == "https://company.com/builders/example/v1"
     and (.predicate.buildDefinition.buildType | test("^https://company\\.com/build-types/"))
     and (.predicate.buildDefinition.resolvedDependencies | length) >= 2
   ' provenance.json
   ```
3. **Verifies the CycloneDX ML-BOM attestation + content
   policy.** Pattern mirrors step 2; the content policy
   enforces that every `machine-learning-model` and
   `data` component has a `licenses` entry.
4. **Transparency-log inclusion.** `cosign verify` and
   `cosign verify-attestation` enforce Rekor inclusion by
   default in modern cosign; the verifier must *not*
   pass `--offline`. State that in a comment and ensure
   the script's exit code reflects the inclusion check.
5. **Exits non-zero on any failure.** Clear reason to
   stderr; machine-readable report to stdout for CI
   consumption.

Commit the verifier script plus the two content-policy
expressions (bash + jq, or a small Rego policy, or a CUE
policy — whichever matches the chosen approach).

### Deliverable C — canonical failure-mode walkthrough

Reproduce five failure modes against your pipeline. For
each: the setup, the exact `verify.sh` command, the exact
error, and a one-sentence explanation. Capture the
transcript.

Required failures:

1. **Unsigned artefact.** Push a second artefact to the
   same registry under a different digest; do not sign;
   run `verify.sh`. Expected: cosign reports no
   signatures for the digest.
2. **Wrong signer identity.** Sign a third artefact with
   a different OIDC subject than the policy permits
   (e.g. your personal Google account instead of the CI
   workflow identity). Run `verify.sh`. Expected: cosign
   reports certificate identity mismatch.
3. **Missing attestation.** Sign the artefact but do not
   attach the SLSA attestation. Run `verify.sh`.
   Expected: `cosign verify-attestation` reports no
   attestations of the required type.
4. **Bad-content attestation.** Attach a SLSA attestation
   whose `builder.id` is not on the approved-builder list
   (modify the predicate before signing). Run `verify.sh`.
   Expected: the signature verifies; the content policy
   (jq expression) exits non-zero.
5. **Tag-swap after signing.** Push the artefact at
   `tag=v1`; sign the digest; push a different artefact
   to the same `tag=v1`; `verify.sh` references the tag
   (not the digest). Expected: when the verifier resolves
   the tag to the new digest, no signature is found, OR
   the verifier catches the mismatch between the pinned
   digest and the current tag. Explain which cosign
   version-behaviour applies to your setup.

Each failure transcript carries:

```
$ ./sign.sh --unsigned-case
<setup output>

$ ./verify.sh registry/.../@sha256:<unsigned-digest>
Error: no matching signatures: [...]
<exit code: non-zero>
```

Commit the transcripts under `failures/01-unsigned.txt`,
`.../02-wrong-identity.txt`, etc.

### Deliverable D — Kubernetes admission policy sketch

A YAML file for *one* of the three (your choice; state the
choice):

- **sigstore policy-controller** `ClusterImagePolicy`
  (chapter 02's example is the starting point).
- **Kyverno** `ClusterPolicy` with `verifyImages` /
  `verifyAttestations` rules.
- **Gatekeeper** constraint-template + constraint
  (requires more scaffolding but is widely deployed).

The policy must enforce:

- Image is signed by the pinned Fulcio OIDC identity.
- A SLSA Provenance attestation is present and its
  `builder.id` matches the approved builder regex.
- A CycloneDX ML-BOM attestation is present (content
  policy minimal here is fine; the full policy is in
  mod-109 chapter 04).
- Transparency-log inclusion is required.

State:

- Where this policy would be deployed (the serving
  cluster; the shared platform cluster; a staging
  environment).
- Whether it runs in **enforce** or **warn** mode and
  why. Shadow-mode first is a reasonable choice for a
  rollout.
- How namespaces or labels scope the policy (chapter 02's
  `glob: registry.company.com/models/**` is the pattern).

### Deliverable E — trust-root choice writeup

One page:

- **Public sigstore** (`fulcio.sigstore.dev`,
  `rekor.sigstore.dev`) — pros, cons, and the risks the
  org accepts by using it (availability dependence on a
  community-run service; data-residency concerns if your
  org cannot publish signatures to a public tlog).
- **Private sigstore** — Sigstore Scaffolding, Chainloop,
  or a vendor distribution. State the components
  (internal Fulcio, internal Rekor, internal CT log /
  trust-bundle service), the OIDC issuer, and the
  rotation strategy.
- **Your choice** for this exercise and why.
- **Trust-bundle distribution.** How verifiers (CI,
  admission controller, developers) receive and pin the
  trust root. For public sigstore, the project publishes
  it; for private, your org publishes it.

### Deliverable F — key-rotation / identity-migration runbook

One page:

- **Scenarios that trigger a change.** Identity migration
  (GitHub Actions → internal runner; Vertex SA → GKE
  Workload Identity); OIDC issuer URL change; private-
  sigstore trust-bundle rotation; a security incident
  requiring revocation of a signer identity.
- **Pre-rotation checks.** Enumerate the admission
  policies / verifier scripts / CI pipelines that pin
  the old identity. Update order: policy update ships
  *before* signer migration, in shadow mode; the signer
  starts producing signatures under the new identity;
  verifiers accept both for a transition window; the
  old identity's signatures are reconciled; the old
  identity is removed.
- **Rollback.** If the new signer breaks the pipeline,
  how to roll back without creating orphaned
  signatures.
- **Audit trail.** How the rotation is recorded (the
  change-request record; the signing-identity register;
  the admission-policy change-log).

---

## Starter guidance

- **Use `ttl.sh` for the first pass if you cannot push
  to an org registry.** It is a scratch registry that
  deletes artefacts after a TTL; perfect for throwaway
  signing experiments.
- **Pin cosign and the Fulcio / Rekor endpoints in
  version-controlled config.** Running `cosign` from
  a drifting `latest` tag at the workstation is how
  "same command fails tomorrow" happens.
- **Sign digests, not tags.** The second-most-common cosign
  footgun. Scripts take `--digest` as a parameter; CI
  jobs resolve the digest in a prior step and pass it
  forward.
- **Keep policy content next to the signing commands.** A
  content policy (the jq expression; the Rego / CUE
  policy) is a *second* artefact beside the signature. If
  policy changes, verifier changes.
- **Test the verifier against negative cases first.** If
  `verify.sh` passes trivially (because the content
  policy is weak), the failure walkthrough is cheap to
  do and often surfaces real policy gaps.
- **Use the regex form of `--certificate-identity-regexp`
  carefully.** A loose regex is a backdoor. The regex
  anchors to `^` and `$`; the regex contents are escaped
  for the identity format.
- **Record Rekor indices.** They are the long-term proof
  that signatures existed at a given time; without them
  tlog-inclusion verification is best-effort.

---

## Acceptance criteria

A passing bundle:

- Signed artefact in a registry; digest recorded.
- Signatures and attestations attached, verifiable with
  the chosen trust root.
- `verify.sh` enforces signature validity, pinned
  identity, transparency-log inclusion, and content
  policy; exits non-zero on failure.
- Five failure transcripts committed with exact
  command + error + explanation.
- Admission policy YAML (one of policy-controller,
  Kyverno, Gatekeeper) scoped to the artefact set and
  stated as enforce or shadow with rationale.
- Trust-root writeup names the chosen root and the
  bundle-distribution plan.
- Key-rotation runbook names pre-rotation checks,
  rotation order, rollback, and audit trail.

A failing bundle:

- Signatures without pinned identity verification
  (`cosign verify` with no `--certificate-identity*`).
- Attestations verified without content policy (envelope
  only, no `jq` / Rego / CUE check).
- `--insecure-skip-verify` / `--offline` in production
  verification paths.
- Failures asserted but not reproducible from the
  transcripts.
- Admission policy that permits any signer or any
  attestation shape.
- Trust-root writeup that treats the public sigstore as
  "just there" without naming the dependence or the
  alternatives.
- Rotation runbook that proposes "update everything at
  once" or "no transition window".

---

## Stretch goals

- **GitHub Actions reusable workflow.** Package the
  signing pipeline as a reusable workflow that any ML
  repo can call; publish an org-wide verifier action.
- **Internal Fulcio / Rekor rollout.** Run Sigstore
  Scaffolding locally; sign with the internal Fulcio;
  verify with the internal trust bundle; document the
  rollout.
- **Rego policy pack.** Convert the content-policy
  expressions into a Rego policy under mod-109 chapter
  04's pack; add tests.
- **Rekor monitor.** A background job that watches Rekor
  for new entries under your signing identity and alerts
  if an entry appears that does not match an in-pipeline
  signing event. Useful tripwire for a stolen OIDC token.
- **Private-sigstore DR drill.** Simulate a failure of
  the private Fulcio and run through the fallback plan
  (static pins; delayed verification; shadow-mode).
- **ORAS packaging deep dive.** For a non-trivial model
  (safetensors + tokenizer + config + chat template),
  design the ORAS media types and verify the full
  layered artefact.
- **PEP 740 experiment.** For Python-package publishing
  flows, experiment with signing wheels under sigstore
  and consuming the signatures in a `pip install`
  verification step (API currently evolving; verify
  against the current spec).

---

## Do not

- Do not run `cosign verify` without `--certificate-
  identity-regexp` + `--certificate-oidc-issuer`. The
  default accepts any Fulcio-issued signature.
- Do not disable transparency-log inclusion for
  "simplicity". The inclusion proof is a core defence.
- Do not store signing-identity secrets anywhere in the
  pipeline. The whole point of keyless is that there
  are no long-lived secrets to leak.
- Do not fork the chapter's `ClusterImagePolicy` without
  changing the identity pins. Sample policies with the
  wrong identity are indistinguishable from no policy.
- Do not treat `cosign verify-attestation` as a decision.
  It is a signed document; the content policy that
  follows is the decision.
- Do not commit the solution bundle to this repo.
  Solutions live in the paired `-solutions` repo.
