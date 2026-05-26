# Exercise 03 — Conftest CI Gate

**Estimated time**: 2 hours
**Deliverable**: A CI workflow + policy set + a pass/fail demo

---

## The assignment

Set up Conftest as a **CI policy gate** for SmartRecs. The gate
runs on every PR that changes Kubernetes manifests, Terraform,
or Dockerfiles.

## What the gate must enforce

1. **Kubernetes manifest policies**:
   - No `:latest` image tags.
   - All Pods have `team`, `owner` labels.
   - No `hostPath` mounts.
   - No `privileged: true` containers.
   - All Pods specify `securityContext.runAsNonRoot: true`.

2. **Terraform plan policies**:
   - No security group rule with `0.0.0.0/0` source for SSH
     (port 22) or RDP (port 3389).
   - All S3 buckets have encryption enabled.
   - All IAM policies with `*:*` actions require explicit
     approval (a specific label in the PR).

3. **Dockerfile policies**:
   - The final image does not run as root (`USER` instruction
     present and non-root).
   - No `ADD` from URLs (use `COPY` or RUN+curl with a
     verification step).
   - No `latest` in `FROM` base images.

## What you produce

1. **The Rego policies** (or reuse from Exercise 02 where
   applicable).
2. **A GitHub Actions workflow** (or equivalent CI YAML) that:
   - Detects changed file types in the PR.
   - Runs Conftest against each.
   - Posts results as a PR comment.
   - Blocks the merge on policy violation.
3. **A pass/fail demo set**:
   - 3 example manifests that should pass.
   - 3 example manifests that should fail (one per policy).
   - The expected output of `conftest test` for each.

## Format

```
# Conftest CI Gate: SmartRecs

## Policies covered
(Index of policies; reuses Exercise 02 where possible.)

## CI workflow

### .github/workflows/policy-gate.yml
(Or equivalent for GitLab CI.)

## Demo set

### Pass cases
- example-pass-1.yaml + expected output
- example-pass-2.yaml + expected output
- ...

### Fail cases
- example-fail-no-labels.yaml + expected output
- example-fail-latest-tag.yaml + expected output
- ...

## Local development workflow
(How an engineer tests their PR locally before pushing.)

## What happens when a policy violation is found
- PR check shows fail
- Comment with specific rule + line + fix suggestion
- Engineer fixes and re-pushes

## Performance considerations
(How long does the gate take? What's acceptable for CI?)

## Exemption process
(How does an engineer get a one-off exemption when needed?
Documented, audited, time-bounded.)

## Operational concerns
- Cost of running Conftest on every PR
- Triage when a previously-passing policy starts failing
- Updates to policies (policy upgrades + grandfathering)
```

## Quality criteria

A passing gate:

- CI workflow is **runnable** (real syntax, even if
  placeholders for repo-specific bits).
- Demo set demonstrates the gate working — pass cases pass,
  fail cases fail with informative messages.
- Local development workflow exists (engineers can `conftest
  test` before pushing).
- Exemption process is real (not "ask the security engineer").

A failing gate:

- Workflow that wouldn't run.
- Demo set is missing or doesn't cover real cases.
- No exemption process.
- No performance consideration.

## Reflection questions

1. Which policy is most likely to false-positive and produce
   PR friction?
2. The team objects: "CI gates slow us down." How do you
   reduce friction without reducing security?
3. An engineer needs to ship a hotfix and the policy gate is
   blocking on an unrelated issue. What's the override path?
