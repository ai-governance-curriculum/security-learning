# Exercise 04 — Keyless CI with OIDC and Cosign

**Estimated effort:** ~3 hours
**Deliverable:** A design + configuration bundle consisting
of (a) an inventory of every static credential currently in
the CI system, (b) the target OIDC federation architecture
per cloud, (c) sample workflow files and IAM trust policies
for at least three workflow classes (build, sign, deploy),
(d) a phased rollout plan, and (e) a scanner / policy that
prevents the pattern from regressing.
**Prerequisites:** Exercise 01 (the CI slice of the
inventory drives this exercise). Chapter 04 read end-to-end.
Chapter 02 of mod-104 (cosign / Sigstore mental model). A
working knowledge of the target CI system (GitHub Actions,
GitLab CI, Buildkite, or similar) and one cloud IAM.

---

## Objective

Remove every long-lived credential from the CI system that
builds, signs, and deploys the target ML platform. Replace
each with an OIDC federation path pinned to the specific
repository, branch, workflow file, and (where supported)
environment. Configure cosign keyless signing for model
artifacts. Add a policy that prevents new long-lived CI
credentials from being introduced.

By the end you should have a document — with sample YAML
and JSON that a CI engineer can commit — that eliminates a
class of vulnerability entirely, and a follow-on control
that keeps it eliminated.

---

## Problem statement

Take the platform from exercise 01. CI is GitHub Actions on
GitHub Enterprise Cloud. The current-state CI workflows for
the `fraud` model:

- **`ci-build.yml`** — runs on every PR: builds the training
  container image, runs unit tests, pushes the image to the
  OCI registry using an `ECR_PUSH_KEY` stored as a GitHub
  Actions Secret.
- **`ci-train.yml`** — runs on merge to `main` and on manual
  dispatch: submits a Kubeflow pipeline run in the training
  cluster, using a `KUBECONFIG_TRAINING` secret and an
  `AWS_TRAINING_ROLE_KEY` for Snowflake reads via a bootstrap
  script.
- **`ci-sign.yml`** — runs after a successful training run:
  cosign-signs the model artifact using a `COSIGN_KEY` and
  `COSIGN_PASSWORD` pair stored as Actions Secrets; pushes
  the signature to a private Rekor.
- **`ci-deploy-staging.yml`** — runs on tag push: deploys
  to the staging KServe cluster using a
  `KUBECONFIG_STAGING` secret.
- **`ci-deploy-prod.yml`** — runs on manual approval:
  deploys to prod using a `KUBECONFIG_PROD` secret and a
  `PAGERDUTY_KEY` for cutover notifications.

The org's cloud is AWS; some workloads run on GCP for a
regional isolation experiment. Assume the trust boundary is
one cloud-provider per environment (AWS for `dev` and
`staging`, GCP for `prod-eu`, back to AWS for `prod-us`).

If your real target CI is different, substitute — the
exercise structure is identical.

---

## Requirements

### Section 1 — CI credential inventory

Enumerate every static credential currently in the CI system:

| Credential ID | Workflow(s) using it | Store (Actions Secret / Variable, org / repo / environment scope) | Underlying provider (AWS role, GCP SA, K8s SA token, cosign key) | Lifetime today | Blast radius on leak | Chapter-04 candidate? |

The last column is `YES` for anything the cloud IAM (or
Fulcio) supports federating; `NO` (with reason) otherwise.

### Section 2 — Target OIDC federation architecture

A diagram + prose for each cloud in scope:

- **AWS IAM** — OIDC provider trust for
  `token.actions.githubusercontent.com`; one role per
  environment × purpose; trust policy pins `repo`, `ref`,
  and `environment`.
- **GCP Workload Identity Federation** — Pool + Provider
  trust for GitHub OIDC; per-purpose service accounts;
  attribute conditions pin `assertion.repository`,
  `assertion.ref`.
- **Fulcio (Sigstore)** — configured for the CI OIDC
  issuer; verification policy (in mod-104 chapter 02) pins
  the SAN pattern to your org / workflow.

For each cloud, name:

- The IAM roles / service accounts created (one per
  workflow purpose).
- The trust-policy conditions.
- The set of permissions attached to each role (least-
  privilege — no `*:*`).
- The break-glass path (an alternate SSO-federated human
  role that can perform the same action; not a shared
  static credential).

### Section 3 — Sample workflows and trust policies

For at least three workflows (`ci-build`, `ci-sign`,
`ci-deploy-prod`), produce:

1. The full workflow YAML using OIDC (no static cloud
   credentials).
2. The cloud IAM trust policy JSON for the corresponding
   role, with the strict conditions from chapter 04.
3. For `ci-sign`, the cosign keyless invocation and the
   Fulcio identity that will appear in the SAN, and the
   mod-104 verification policy that admission will use.
4. For `ci-deploy-prod`, the GitHub Environment definition
   with required reviewers, wait timer, and protected
   branch — the environment claim is part of the trust
   policy's pin.

Verify each configuration for the anti-patterns from
chapter 04:

- No bare `sub: *`.
- `aud` explicitly pinned.
- Trust policy for CI role is not assumable by any human
  identity.
- PR-triggered workflows do not have production trust.

### Section 4 — Phased rollout plan

Order the transition:

1. Enable the OIDC provider trust in each cloud as an
   additional route.
2. Create the OIDC roles with strict trust policies.
3. Migrate the lowest-risk workflow first (probably
   `ci-build`); verify the trust policy denies wrong-branch
   attempts by testing (open a PR from a fork and confirm
   the assumption is denied; try a same-branch push with
   the correct policy and confirm success).
4. Migrate remaining workflows in decreasing safety-margin
   order.
5. Delete the static credentials from Actions Secrets after
   two clean weeks of the OIDC-based flow.
6. Configure CI policy to prevent the reintroduction of
   long-lived cloud credentials in Actions Secrets (see
   section 5).

Each step lists its verification action and its rollback
action.

### Section 5 — Prevention control

Add a mechanism that prevents the anti-pattern from
recurring:

- A **repository / org policy** disallowing specific
  Actions Secrets names (e.g. no secret matching
  `AWS_.*_KEY`).
- A **CI job that lint-checks every workflow file**: any
  workflow that uses `${{ secrets.AWS_ACCESS_KEY_ID }}` (or
  similar) fails the check.
- A **quarterly audit script** that lists every
  organisation-level and repository-level Actions Secret
  and flags long-lived cloud credentials.
- Optionally: use GitHub's push protection to block
  commits matching AWS-key patterns from landing at all.

### Section 6 — Cosign keyless signing wiring

For the `ci-sign` workflow, document:

- The Fulcio SAN pattern that will appear in the issued
  certificate (repo-specific, workflow-specific).
- The mod-104 verification policy that admission will
  consult (SAN regex, Rekor inclusion required).
- The Rekor instance target (public
  `rekor.sigstore.dev` vs private instance) and the
  operational implications of each.
- The behaviour on Fulcio / Rekor unavailability — does the
  CI fail (fail-closed) or fall back to keyed signing
  (fail-open, only acceptable if the fallback signature is
  distinguishable at verification time)?

## Starter guidance

- Do the AWS migration first — GitHub Actions → AWS IAM
  OIDC is the most mature path with the clearest
  documentation and the most examples.
- For GCP WIF, remember that the attribute-condition
  language is CEL; test your conditions with the GCP
  simulator.
- For the trust policy, iterate: start with a strict
  pattern (`repo:acme-org/fraud-training:environment:prod`),
  test that it rejects everything else, then loosen only if
  a specific workflow class requires it — and document why.
- Cosign keyless requires `id-token: write` in the workflow
  permissions block. Ensure the workflow explicitly sets
  `permissions:` at the top (do not rely on repository
  defaults which may vary).
- For the prevention control (section 5), the simplest
  robust design is a required-status-check pre-merge that
  runs a linter over the workflow files and rejects
  anything that references disallowed secret names.
- Do NOT delete the static credentials until section 4's
  "two clean weeks" bar is met. A rollback that requires
  re-creating credentials is a slow rollback.

## Acceptance criteria

A passing document:

- CI credential inventory covers every workflow in the
  target platform's `.github/workflows/` (or CI
  equivalent).
- OIDC federation architecture is named per cloud in
  scope, with the specific trust conditions.
- Three sample workflows + trust policies are complete
  and self-consistent.
- No sample trust policy uses `sub: *` or omits `aud`.
- Rollout plan has explicit per-step verification and
  rollback actions.
- Prevention control is a concrete mechanism, not a
  policy statement.
- Cosign keyless configuration references a mod-104
  verification policy and states the fail behaviour on
  Sigstore unavailability.

A failing document:

- Any trust policy with a wildcard `sub` or an unpinned
  `aud`.
- Any workflow that still reads a long-lived cloud
  credential from Actions Secrets.
- A rollout plan that deletes static credentials before
  the OIDC path is verified.
- No prevention control (a lint check, a policy) — the
  transition without prevention drifts back within a
  quarter.
- Cosign keyless configuration without a SAN pin — the
  signature is worthless without verification pinning.

## Stretch goals

- **Reusable workflow migration.** If the org uses GitHub
  reusable workflows, address the `job_workflow_ref`
  claim shape and pin the reusable workflow's ref in the
  trust policy.
- **Fork-safety analysis.** For each workflow, state
  whether it can be triggered from a forked PR and, if so,
  what protections apply. `pull_request_target` combined
  with OIDC is a known-sharp-edge case; walk through the
  risk explicitly.
- **Cross-CI-provider migration path.** If the org may
  migrate CI systems (e.g. GitHub Actions → GitLab CI),
  show that the federation architecture generalises —
  same target roles, different OIDC issuer.
- **Rekor mirroring / private Rekor.** Design a private
  Rekor deployment (or a public-Rekor mirror) so
  Sigstore-outage does not stop signing; discuss the
  operational cost and the trust-model implications.
- **Attestations, not just signatures.** Add an in-toto
  attestation for each signed model artifact via
  `cosign attest`, with a predicate that carries the
  training-run's SLSA provenance. This is the mod-104
  chapter 03 payload; wire it here.

## Do not

- Do not commit real trust-policy JSON that references
  live cloud account IDs — placeholders only.
- Do not commit real ARNs of production roles.
- Do not commit a `COSIGN_PASSWORD` (or any equivalent) as
  part of the deliverable — keyless is the point.
- Do not attempt the migration in a live production repo
  before the plan is reviewed.
- Do not skip section 5 (prevention control) — a one-time
  cleanup that doesn't prevent regression is not the
  chapter-04 outcome.
- Do not commit a solution here — solutions live in the
  paired solutions repo.
