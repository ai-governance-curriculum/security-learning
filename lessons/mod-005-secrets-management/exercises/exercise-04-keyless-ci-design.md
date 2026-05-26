# Exercise 04 — Keyless CI Design

**Estimated time**: 2 hours
**Deliverable**: A 2-page design + concrete IAM trust policy + workflow YAML

---

## The current state

SmartRecs uses GitHub Actions for CI. The current workflow does:

1. Builds container images.
2. Pushes them to ECR.
3. Signs them with Cosign.
4. Deploys to EKS via `kubectl apply`.
5. Updates an internal Notion page (to track what's deployed).

All of this is currently authorized by **static credentials**
stored as GitHub Secrets:

- `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` (long-lived IAM
  user, ECR + EKS access).
- `COSIGN_PRIVATE_KEY` (raw private key for artifact signing).
- `KUBECONFIG` (long-lived service account token).
- `NOTION_API_KEY` (static).

## The assignment

Migrate this CI pipeline to keyless authentication wherever
possible. Produce:

1. **An IAM trust policy** for AWS that allows GitHub Actions
   from the SmartRecs org to assume a CI role via OIDC.
2. **An updated `.github/workflows/<name>.yml`** showing the
   relevant changes (no long-lived secrets, OIDC-based STS,
   Cosign keyless).
3. **A migration plan** with phases — you cannot just swap
   credentials in production.
4. **A residual-secrets section** — what credentials, if any,
   *must* remain static. For each: storage location, rotation
   cadence, blast-radius bound.
5. **A test plan** — how do you verify the keyless flow works
   end-to-end before flipping production?

## Specific design questions

### AWS via OIDC

The IAM trust policy must:
- Trust the GitHub OIDC provider for AWS.
- Limit `sts:AssumeRoleWithWebIdentity` to the SmartRecs org's
  repos.
- Optionally limit to specific branches (e.g., `main`,
  `release/*`).

### Cosign keyless

Replace the raw private key with Cosign's keyless flow:
- The CI job's OIDC token is the signing identity.
- Fulcio issues a short-lived signing certificate.
- Rekor records the signature.

Document what the OIDC subject looks like
(`https://github.com/smartrecs-org/<repo>/.github/workflows/<wf>@refs/heads/main`)
and how the admission policy (Module 03) verifies it.

### EKS access via OIDC

The CI doesn't need long-lived `KUBECONFIG`. Approaches:
- IRSA: the AssumeRole gives the CI an IAM role; EKS cluster
  has the role's identity in `aws-auth`; `kubectl` uses
  IAM-derived auth.
- A more sophisticated GitOps approach: CI doesn't `kubectl
  apply` at all; it pushes to a GitOps branch and ArgoCD picks
  it up. (This is a longer-term move; treat it as a
  next-phase consideration.)

### Notion API key

This is the residual static secret — Notion doesn't accept
OIDC. Options:
- Store in GitHub Secrets, rotate quarterly.
- Move to Vault if Vault is deployed (Exercise 02), with a CI
  step that exchanges OIDC for a Vault token, then reads the
  Notion key.

## Format

```
# SmartRecs Keyless CI Design

## Goal
(All CI authentication except clearly identified residuals
moves to OIDC-derived short-lived credentials.)

## Architecture
(Diagram or prose: CI → OIDC → STS / Vault / Fulcio → resources.)

## IAM trust policy (concrete JSON)

## Workflow changes (concrete YAML diff)

## Cosign keyless integration

## Residual static secrets
| Secret | Why it stays static | Storage | Rotation | Blast radius |
|---|---|---|---|---|

## Migration plan
- Phase 1: shadow keyless alongside static (don't decommission)
- Phase 2: keyless is primary; static is fallback
- Phase 3: decommission static

## Test plan
- Pre-prod verification
- Production validation
- Rollback if keyless fails

## Risks and mitigations
```

## Quality criteria

A passing design:

- IAM trust policy is **concrete** (a real JSON document, even
  if names are placeholders).
- Workflow YAML shows the actual changes.
- Cosign keyless is integrated (no long-lived signing key).
- Migration is phased and reversible.
- Residual static secrets are explicitly named and bounded.

A failing design:

- Hand-waves the IAM policy.
- Migrates everything at once.
- Treats Notion API key (or equivalent residuals) as "just keep
  it static" with no rotation plan.

## Reflection questions

1. What happens to the keyless flow if a fork of your repo is
   created? Could that fork's CI assume the same IAM role?
2. The Cosign keyless OIDC subject includes the workflow path
   and branch. What's the implication for branch protection?
3. If GitHub's OIDC service is down for 4 hours, can you still
   deploy?
