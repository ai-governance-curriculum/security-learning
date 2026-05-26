# Exercise 01 — Pod Security Standards Baseline

**Estimated time**: 2 hours
**Deliverable**: A rollout plan + namespace label set

---

## The assignment

Roll out Pod Security Standards across SmartRecs' namespaces.
Produce:

1. **A per-namespace target PSS profile** with rationale.
2. **Namespace label YAML** for `warn → audit → enforce`
   transition.
3. **A rollout schedule** by namespace.
4. **An expected-failure log** — for each namespace, predict
   which existing pods will fail the target profile, and why.
5. **Remediation per failure** — for each expected failure,
   the engineering change needed.
6. **Rollback plan** if enforce breaks a critical workload.

## Namespaces in scope

- `edge` (gateway).
- `recs` (model-serving, recommender).
- `fraud` (model-serving, fraud).
- `recs-train` (nightly training).
- `fraud-train` (nightly training).
- `features` (feature store).
- `gov` (governance + audit).
- `obs` (Prometheus, Grafana).
- `cert-manager` (cert-manager controllers).
- `notebooks` (data-scientist Jupyter).
- `kube-system` (system).

## Format

```
# Pod Security Standards Rollout: SmartRecs

## Target profile per namespace

| Namespace | Target | Rationale |
|---|---|---|

## Label YAML (per namespace)

### `recs` namespace
```yaml
labels:
  pod-security.kubernetes.io/enforce: restricted
  pod-security.kubernetes.io/enforce-version: latest
  pod-security.kubernetes.io/audit: restricted
  pod-security.kubernetes.io/warn: restricted
```

### `recs-train`
...

## Rollout schedule

| Week | Namespace(s) | Phase |
|---|---|---|
| 1 | recs, fraud, gov | warn |
| 2 | recs, fraud, gov | audit |
| 3 | recs, fraud, gov | enforce |
| ... | ... | ... |

## Expected failures + remediation

### `recs-train`: GPU device-plugin requires capability
- **Failure**: NVIDIA device plugin pods need extra capabilities
- **Remediation**: Apply Baseline (not Restricted) to recs-train
- **Risk accepted**: documented exemption for GPU workloads

### `notebooks`: Jupyter container runs as root
- **Failure**: ...
- **Remediation**: ...

## Rollback plan

(How to revert if enforce step produces an outage.)

## Acceptance criteria

(How you know the rollout is successful per namespace.)
```

## Quality criteria

A passing plan:

- **Different profiles per namespace** based on workload needs.
- **Expected failures** are realistic and named, not hand-waved.
- **Rollout schedule** uses `warn → audit → enforce` (not
  immediate enforce).
- **Rollback** is specific (which label to revert, what to
  monitor).

A failing plan:

- "All namespaces: Restricted." Doesn't survive contact with
  GPU workloads.
- "Restricted everywhere immediately."
- No expected-failure analysis.
- No rollback.

## Reflection questions

1. Which namespace had the hardest profile decision? Why?
2. The platform team objects: "Restricted breaks notebooks."
   What's the conversation about isolating notebooks vs.
   relaxing the profile?
3. What's the audit-chain entry that gets produced when a
   pod is rejected for PSS violation? How does that satisfy
   compliance evidence requirements (Module 07)?
