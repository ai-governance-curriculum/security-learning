# Chapter 04 — Keyless CI: OIDC to Cloud, Keyless Cosign Signing

> **Note on AI-assisted content.** Verify CI OIDC issuer URLs,
> cloud IAM federation configs, and Sigstore cosign CLI syntax
> against the current provider and tool docs; each of these has
> moved in the last twelve months. See
> [`resources.md`](./resources.md).

---

## Why this chapter exists

Chapter 02 removed long-lived credentials from application
workloads. Chapter 03 removed long-lived plaintext keys from
data storage. This chapter removes long-lived credentials from
CI — usually the last remaining static-credential surface, and
often the most exposed one, because CI is by design an
externally-triggered execution environment that runs any code
in the repository.

The specific failure mode this chapter is written to prevent:

> A team's GitHub Actions workflow deploys their fraud model to
> a staging cluster. To do so it holds an
> `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` in GitHub
> Secrets that grants it broad access to the staging AWS
> account. A dependency in the workflow gets typo-squatted; the
> malicious version runs during the next PR-triggered CI run and
> exfiltrates `${{ secrets }}` to an attacker-controlled URL.
> The attacker now has a long-lived credential in the staging
> AWS account. From staging they pivot: the CI-role's session
> assumes a `cross-env-read` role that shouldn't exist but does,
> and they reach the prod model registry. The blast radius is
> the org's model registry; the origin is a static credential
> in a CI secret store.

Keyless CI closes this by making sure **there is no long-lived
credential to exfiltrate**. The CI job proves its identity to
the cloud IAM (or to Sigstore's Fulcio) using a short-lived
OIDC ID token that the CI system mints per-job, signed by the
CI's own OIDC provider. The cloud (or Fulcio) exchanges the
ID token for a short-lived cloud token (or a short-lived
signing certificate) valid for the duration of the CI job.

You leave this chapter able to:

- Explain the OIDC federation flow from a CI job to a cloud
  IAM role (or to Fulcio) without a shared secret.
- Configure GitHub Actions, GitLab CI, or Buildkite (etc.) to
  mint an ID token for a specific workflow / branch /
  environment.
- Configure AWS IAM (or GCP Workload Identity Federation, or
  Azure federated credentials) to trust the CI OIDC issuer for
  a specific principal-claim pattern.
- Sign a model artifact with cosign in keyless mode using the
  CI job's OIDC identity as the Fulcio SAN.
- Author trust-policy conditions that pin the *repository*,
  *branch*, *workflow file*, and (where supported) the
  *environment* — closing the "any workflow in any repo can
  assume this role" gap.

---

## The federation flow in one diagram

The choreography is the same across cloud providers and across
Sigstore; only the names change.

```
┌─────────────────────┐                              ┌──────────────────────┐
│ CI system           │                              │ Cloud IAM            │
│ (GitHub Actions,    │                              │ (AWS IAM, GCP WIF,   │
│  GitLab, Buildkite) │                              │  Azure Fed Creds)    │
│                     │                              │                      │
│  OIDC provider      │                              │  OIDC identity       │
│  publishes JWKS at  │◄─── discovers JWKS ─────────►│  provider config     │
│  /.well-known/…     │                              │                      │
└──────────┬──────────┘                              └───────────┬──────────┘
           │                                                     │
           │ (1) job starts, requests ID token                  │
           ▼                                                     │
┌─────────────────────┐                                          │
│ CI job container    │                                          │
│                     │ (2) POSTs signed ID token +              │
│  ID token           │     assumeRoleWithWebIdentity           │
│  (JWT signed by CI  │────────────────────────────────────────► │
│  OIDC issuer)       │                                          │
│                     │ (3) cloud validates: signature vs JWKS,  │
│                     │     subject claim vs trust policy,       │
│                     │     audience claim vs configured aud     │
│                     │                                          │
│  ephemeral cloud    │◄──── (4) short-lived cloud creds ────────┤
│  credentials        │                                          │
│                     │                                          │
│  cloud API calls    │─────► API server (S3, KMS, ECR, …)       │
└─────────────────────┘                                          │
```

- Nothing here is a shared secret. The CI system's private
  signing key stays inside its OIDC provider.
- The trust policy on the cloud side is a **pattern match**
  against JWT claims — usually the `sub` claim, which the CI
  populates with values like
  `repo:acme-org/fraud-training:ref:refs/heads/main` (GitHub) or
  `project_path:acme/fraud-training:ref:refs/heads/main`
  (GitLab).
- The audience (`aud`) claim is a required check — otherwise a
  token minted for one cloud provider could be replayed against
  another that trusts the same issuer.
- The cloud credentials returned have a lifetime measured in
  minutes to an hour (AWS default 15 min, configurable up to
  12 h; GCP 1 h; Azure similar). Long enough for the job, short
  enough that a leak has a bounded window.

---

## Concrete configuration — the four common CI systems

### GitHub Actions → AWS IAM

CI side (in the workflow):

```yaml
name: build-and-sign
on:
  push:
    branches: [main]
    tags: ['v*']
permissions:
  id-token: write        # required to mint the OIDC token
  contents: read
jobs:
  build:
    runs-on: ubuntu-latest
    environment: prod    # gates + adds environment claim
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::111111111111:role/ci-fraud-training-prod
          aws-region: us-east-1
          # audience defaults to sts.amazonaws.com; keep it
      - name: Publish artifact
        run: aws s3 cp ./model.safetensors s3://acme-models/prod/…
```

AWS side (the trust policy on the role):

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::111111111111:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
      },
      "StringLike": {
        "token.actions.githubusercontent.com:sub": "repo:acme-org/fraud-training:environment:prod"
      }
    }
  }]
}
```

Key trust-policy properties:

- **`sub` pins the repo and environment.** The `sub` claim
  GitHub emits carries repo, branch/tag/PR, and (if set)
  environment. Pin the specific shape you want — the above
  pins the `prod` environment; only workflows that name
  `environment: prod` (which triggers environment protection
  rules like required reviewers) can assume the role.
- **Never `StringLike` a bare `*`.** A wildcard on `sub` means
  any workflow in any repo in your GitHub org (and, if you set
  the OIDC provider org-wide, potentially any repo anywhere on
  GitHub) can assume the role. This is the single most common
  keyless-CI misconfiguration.
- **`aud` pinning matters** — a token minted for one provider's
  audience cannot be replayed against another.

<!-- needs-research: verify the current shape of GitHub's `sub`
claim structure — GitHub has changed the shape in the past and
may add additional customisation (reusable-workflow-aware
claims). Check the docs before quoting in policy. -->

### GitLab CI → AWS IAM

GitLab mints ID tokens per-job (declared via `id_tokens:` in
the job) with `sub` claims of the form
`project_path:group/project:ref:<ref>`. AWS trust policy
follows the same shape as GitHub, with the issuer set to the
GitLab instance (`https://gitlab.com`) and the `sub`
condition matching the project path.

### GitLab CI / GitHub Actions → GCP Workload Identity Federation

GCP Workload Identity Federation configures a Pool + Provider
that trusts the CI OIDC issuer. A service account is then
grantable via `workloadIdentityUser` binding. The `attribute
condition` pins the repo / branch:

```
assertion.repository == "acme-org/fraud-training" && assertion.ref == "refs/heads/main"
```

The CI job authenticates via `google-github-actions/auth` (or
equivalent) using the WIF provider path; GCP returns a
short-lived access token for the bound service account.

### CI → Azure Federated Credentials

Azure AD supports federated identity credentials on an
application registration or a user-assigned managed identity.
Each federated credential specifies an issuer (CI OIDC issuer),
a subject pattern (the CI `sub` claim shape), and an audience
(`api://AzureADTokenExchange`). The CI job requests an ID
token, exchanges it via `az login --federated-token`, and
receives an Azure AD token for the identity.

### Buildkite / CircleCI / other CI systems

The pattern is identical; each system exposes an OIDC token
minting API (see the vendor docs for the endpoint) and the
cloud provider accepts the token if the trust policy matches.

---

## Keyless cosign signing

Sigstore's Fulcio issues short-lived (10-minute default) X.509
signing certificates whose Subject Alternative Name (SAN)
carries an OIDC identity. Chapter 02 of mod-104 covered the
cosign side of the flow end-to-end; this chapter zooms in on
the CI side.

The invocation, on a GitHub-Actions runner with
`id-token: write`:

```yaml
- name: Install cosign
  uses: sigstore/cosign-installer@v3

- name: Sign the model artifact
  env:
    COSIGN_EXPERIMENTAL: "1"
  run: |
    cosign sign --yes \
      --oidc-issuer=https://token.actions.githubusercontent.com \
      oci://acme-registry/models/fraud@sha256:${MODEL_DIGEST}
```

Behind the scenes:

1. Cosign requests an ID token from
   `${{ ACTIONS_ID_TOKEN_REQUEST_URL }}` with audience
   `sigstore`.
2. Cosign POSTs the ID token to Fulcio, which validates the
   token and issues an X.509 certificate whose SAN is (for
   GitHub) `https://github.com/acme-org/fraud-training/.github/workflows/build.yml@refs/heads/main`
   or similar.
3. Cosign signs the artifact digest with the ephemeral private
   key it generated, and pushes both the certificate and the
   signature to Rekor (transparency log) and to the OCI
   registry as an OCI-aware artifact.

The verification policy at admission time (mod-103 chapter 06)
pins the SAN pattern — e.g. "SAN must match
`^https://github\\.com/acme-org/fraud-training/\\.github/workflows/build\\.yml@refs/heads/(main|release/.*)$`"
— so a signature from another repo or another workflow file is
rejected even if it was validly issued by Fulcio.

---

## What "keyless" is actually eliminating

Keyless CI eliminates the following classes of credential from
the CI system:

- Long-lived cloud access keys stored in GitHub Secrets, GitLab
  Variables, Jenkins Credentials, etc.
- Cosign private keys stored as CI secrets or in KMS accessed
  by a long-lived credential.
- Artifact-registry username / password pairs.
- Kubeconfig with long-lived tokens for the target cluster.

What remains (and cannot be keylessly eliminated by this
chapter alone):

- Third-party API tokens for services that do not accept OIDC
  (chapter 01 class 4; chapter 05 rotation policy applies).
- Any credential the CI system itself must hold to authenticate
  its own runners (usually managed by the CI provider).

The scoring for a keyless-CI transition:

- **Good** — every cloud API call from CI uses OIDC-federated
  short-lived credentials; cosign signing is keyless; only
  third-party API tokens remain as static, and those are
  scoped per workflow and rotation-tracked.
- **Bad** — one long-lived `PROD_AWS_KEY` remains in a global
  secret, or the OIDC role's trust policy uses `sub: *`.

---

## Pinning the CI identity: how strict is strict enough?

Trust-policy conditions rank in strictness roughly:

1. `repo == "org/name"` — necessary but not sufficient.
2. `ref == "refs/heads/main"` — refuses PR branches and forks.
3. `workflow == "build.yml"` — refuses ad-hoc workflows a
   repo-writer might add.
4. `job_workflow_ref == "org/name/.github/workflows/build.yml@refs/heads/main"`
   (GitHub, for reusable workflows) — refuses a same-repo
   workflow that reuses the trusted workflow from a different
   ref.
5. `environment == "prod"` (GitHub) — requires the workflow to
   run in a specific GitHub Environment, which can attach
   required reviewers, protected branches, and wait timers.

For **production-affecting roles** (deploy, sign, push), pin
at least 1+2+3, and prefer 1+2+3+5 so that an environment
protection rule adds a human gate. For **read-only roles**
(pull dependencies, run tests), 1+2 is enough. Do not skip 2
even for read-only roles — a PR from a fork should not assume
a role in your account.

---

## Anti-patterns you will meet in the wild

- **Bare `sub: *` or missing `sub` condition.** Anyone who can
  push to any repo trusting the same OIDC issuer can assume the
  role. This is exploitable within an hour of the mistake going
  live.
- **Trust-policy audience unpinned.** Without an `aud`
  condition, a token minted for one relying party can be
  replayed against yours.
- **Same role for CI and for humans.** The role that CI
  assumes should be assumable **only by CI's federated identity**
  — humans get a separate role via SSO. Mixing them means a
  human's stolen SSO session can impersonate CI's blast radius.
- **PR-triggered workflows assuming prod roles.** A PR from a
  fork can run workflow files that the PR itself added; if
  those workflows can assume production credentials, an
  attacker with the ability to open a PR has production
  access. Restrict OIDC-assuming jobs to trusted branches and
  use GitHub's `pull_request_target` semantics carefully.
- **OIDC ID tokens sent to arbitrary endpoints.** If a workflow
  step `curl`s the ID-token endpoint and sends it to an
  external URL, the URL owner can now assume any cloud role
  the token's `sub` covers. Never expose the ID token as an
  environment variable read by third-party actions you have
  not vetted.
- **Sigstore Fulcio SAN not pinned at verification.** The
  chapter-04 signing produces a signature; if the admission
  verifier accepts "any Fulcio-issued cert", an attacker's
  compromised repo can produce valid signatures. Pin the SAN
  regex.

---

## Rollout sequence

The keyless-CI transition on an existing platform proceeds in
this order (each step reversible until the next):

1. **Inventory** — list every CI workflow, every static
   secret it reads, and every cloud role it assumes with
   long-lived credentials. (Chapter 01 covers this in general;
   the CI slice is a specific pass.)
2. **Enable OIDC issuer** on the cloud side as an alternate
   trust route. The existing static credential still works.
3. **Author the OIDC role** with the strictest reasonable
   trust-policy conditions.
4. **Switch one non-critical workflow** to OIDC. Verify the
   audit trail. Verify the trust-policy conditions actually
   deny wrong-branch / wrong-workflow attempts.
5. **Roll out per-workflow**, most-critical last.
6. **Delete the static credential** and the CI secret that
   holds it. Do this only after every workflow that consumed
   it has moved to OIDC and been verified.
7. **Remove the ability to add static credentials.** Configure
   the CI system's secret store to require approval for
   new long-lived cloud credentials (or forbid them outright
   for the environments you have migrated).
8. **Add a periodic scanner** that lists every workflow's
   `permissions:` block and flags any workflow that still
   requests `id-token: write` without an OIDC-federated
   downstream, or that still reads a cloud-credential secret.

Chapters 05 handles the incident case where a keyless flow
must be temporarily disabled.

---

## The mistakes this chapter is trying to prevent

- **Assuming "OIDC" is a fix-all.** OIDC federation without
  strict trust-policy conditions is a wider attack surface,
  not a smaller one — an attacker no longer needs your static
  key, they just need to trigger any workflow the trust policy
  admits.
- **Deleting the static credential before verifying the
  keyless path works.** A deployment failure at 3 AM because
  the OIDC path was misconfigured is a chapter-05 incident by
  induction.
- **Treating cosign keyless as a container-image-only tool.**
  Model artifacts, ML-BOMs, evaluation reports — all can be
  packaged as OCI artifacts and cosign-signed keylessly.
- **Not verifying at admission time that the signature came
  from your CI.** Fulcio signs anyone's token that matches
  their configured issuers. Verification must pin the SAN, or
  a malicious repo elsewhere can produce a valid Fulcio
  signature.
- **Reusing the OIDC audience across systems.** Distinct
  audiences per relying party (cloud vs Sigstore) mean a
  token minted for one cannot substitute for the other.
- **Forgetting reusable workflows.** GitHub reusable workflows
  and GitLab include-based CI have different `sub` shapes;
  the trust-policy pattern must account for the reuse.

---

## Summary

- Keyless CI replaces long-lived CI credentials with
  short-lived cloud tokens or Fulcio-issued certificates
  minted per-job via OIDC federation.
- The four common CI systems (GitHub Actions, GitLab CI,
  Buildkite, CircleCI) each expose an OIDC ID-token minting
  API; the three big clouds (AWS IAM, GCP Workload Identity
  Federation, Azure Federated Credentials) each accept those
  tokens as a federated identity.
- The security value is not "OIDC" itself; it is the **strict
  trust-policy conditions** — pin the repo, branch, workflow,
  and (where supported) environment. `sub: *` is a
  self-inflicted vulnerability.
- Cosign keyless signing uses the same OIDC flow — Fulcio
  issues a short-lived X.509 cert whose SAN encodes the
  CI identity; Rekor logs the signing event; verification
  pins the SAN regex.
- Roll out in phases: enable OIDC alongside the static
  credential, migrate workflows one at a time, then remove
  the static credential and prevent it from returning.
- The class of credential this chapter eliminates covers
  cloud access keys, cosign private keys, artifact-registry
  creds, and kubeconfigs; third-party API tokens (chapter 01
  class 4) remain static and are managed by chapter 05.
