# Exercise 04 — Service-Mesh Authorization Policy

**Estimated time**: 1–2 hours
**Deliverable**: A set of Istio (or equivalent) `AuthorizationPolicy`
YAML manifests plus a defense narrative
**Prerequisite**: Module 02 lecture notes; Exercise 02 helpful

---

## The setup

You inherit a multi-team ML platform with the following workloads in
play:

- `gateway` (namespace `edge`) — terminates external mTLS.
- `serving-recs` (namespace `recs`) — recommender serving.
- `serving-fraud` (namespace `fraud`) — fraud detection serving.
- `feature-api` (namespace `features`) — shared feature store API.
- `training-recs` (namespace `recs-train`) — nightly training for
  recs.
- `training-fraud` (namespace `fraud-train`) — nightly training for
  fraud.
- `governance` (namespace `gov`) — model registry + audit log.

mTLS is `STRICT` mesh-wide. Default authorization is **DENY**.
(If you don't set any AuthorizationPolicy, the mesh denies
everything. You only get traffic by writing policies.)

## The assignment

Author the **minimum set** of AuthorizationPolicy resources to
allow this traffic and *nothing else*:

1. `gateway` → `serving-recs` (`POST /v1/predict`).
2. `gateway` → `serving-fraud` (`POST /v1/score`).
3. `serving-recs` → `feature-api` (`GET /features/v1/*`).
4. `serving-fraud` → `feature-api` (`GET /features/v1/*`).
5. `training-recs` → `feature-api` (`GET /features/v1/*` and
   `GET /features/admin/training-export/recs/*`).
6. `training-fraud` → `feature-api` (`GET /features/v1/*` and
   `GET /features/admin/training-export/fraud/*`).
7. `governance` → all model serving pods (`GET /v1/healthz` and
   `GET /v1/model-card`).
8. `governance` → `feature-api` (`GET /features/v1/metadata/*`).
9. **No other workload-to-workload traffic should be allowed.**

Write the AuthorizationPolicy YAML for each rule. Use pseudo-YAML
if you can't recall exact field names — structure is what matters.

## Constraints the policy must enforce

- `training-recs` must **not** be able to call
  `/features/admin/training-export/fraud/*` even though both are
  under `features-api`. (Per-tenant authorization on a shared
  service.)
- `serving-recs` must **not** be able to call `POST /v1/predict`
  on `serving-fraud` (and vice versa).
- `gateway` must **not** be able to call `feature-api`.
- `governance` is read-only on every service it can call.

## Format

```
# Mesh Authorization Plan

## Policy 1: gateway → serving-recs
(YAML)
(Notes: what's allowed, what's denied that this catches)

## Policy 2: ...
...

## Coverage table

| Source | Destination | Method | Allowed? | Policy enforcing |
|---|---|---|---|---|

## Attack scenarios

(For each constraint above, walk through what would happen if
the policy is wrong. E.g., "if I forget to scope
training-export by tenant, training-recs could exfiltrate
fraud training data; the mesh would allow it because the
identity matches.")

## What this still does not catch

(Application-layer concerns, supply-chain concerns, evasion at
inference time — name at least 3.)
```

## Quality criteria

A passing answer:

- Each policy uses `from.source.principals` keyed on workload
  identity (the SPIFFE-style format Istio uses:
  `cluster.local/ns/<ns>/sa/<sa>`).
- Path matching uses `paths:` and `methods:` correctly.
- The plan calls out **per-tenant routing** on the shared
  feature-api as a non-trivial concern.
- The "still does not catch" section reflects real understanding
  of mesh limitations.

A failing answer:

- Uses namespace selectors instead of principal-based identity.
- Forgets to deny anything (just allows the listed traffic without
  ensuring nothing else is allowed).
- Misses the multi-tenant nuance on feature-api.

## Reflection questions

1. Which policy was hardest to write correctly? Why?
2. Is there a policy that, if misconfigured, allows tenant
   isolation to be silently broken? Which one?
3. What testing strategy would you use to verify this policy set
   *does* enforce the constraints?

## Optional extension

For learners with Istio access: deploy these policies in a test
namespace, write integration tests that exercise the allowed and
denied paths, and verify the denials are returned as expected
(401/403, not 5xx).

## Solution comparison

After writing your own, compare to the reference policies in
[`ai-infra-security-solutions/projects/project-1-zero-trust/istio/authz-policy.yaml`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions/blob/main/projects/project-1-zero-trust/istio/authz-policy.yaml)
(when published).
