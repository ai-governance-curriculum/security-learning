# Exercise 03 — Microsegmentation Plan (3 layers)

**Estimated time**: 2–3 hours
**Deliverable**: A plan document + at least 4 NetworkPolicy YAML manifests

---

## The assignment

Produce a three-layer microsegmentation plan for SmartRecs:

1. **L3/L4 network policy** (Kubernetes NetworkPolicy).
2. **mTLS + AuthorizationPolicy** (Istio, or equivalent).
3. **Application-layer authorization** (where mesh-layer is
   insufficient).

Use the workload identities from Exercise 02 as the basis.

## Part 1 — L3/L4 NetworkPolicy

Write at least 4 NetworkPolicy YAML manifests:

1. A **default-deny** in the `recs` namespace (ingress and egress).
2. A **specific allow** from `gateway` pods to `serving` pods.
3. A **specific allow** from `serving` pods to the `feature-store`
   namespace's `feature-api` pods.
4. An **egress allow** for the training job to call the
   training-data warehouse (with hostnames, ports, protocols).

The YAML should be **syntactically valid** even if you can't apply
it. Reference the [Kubernetes NetworkPolicy docs](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
for field details.

In a brief prose section under each YAML:
- What threat does this policy mitigate?
- What threat does it *not* mitigate that needs a higher layer?

## Part 2 — Mesh authorization

Write 2 Istio AuthorizationPolicy YAML manifests:

1. One that allows the `model-serving` workload identity to call
   the gateway's `/v1/predict` endpoint, denying all others.
2. One that allows the `serving` workload identity to call
   `GET /features/v1/*` on the feature store, with explicit deny
   for write methods.

(Pseudo-YAML is acceptable if you don't have access to current
Istio API docs; the structure is what matters.)

## Part 3 — Application-layer plan

Identify **at least three** authorization decisions in SmartRecs
that **cannot** be made at the mesh layer and must be made in the
application. For each:

1. **What decision** the application is making.
2. **What data** it needs to make the decision (request headers,
   tenant ID, resource ID).
3. **How that data is trustworthy** (signed by an upstream
   identity, verified at the entry point).
4. **What happens** if the application logic is wrong.

The goal: demonstrate that you understand mesh authorization is
necessary and insufficient.

## Format

```
# SmartRecs Microsegmentation Plan

## Reference: Workload identity design
(link to Exercise 02 artifact)

## Layer 1: L3/L4 NetworkPolicy

### Default-deny
(YAML)
(Threat coverage notes)

### Allow gateway → serving
(YAML)
(Threat coverage notes)

### Allow serving → feature-store
(YAML)
(Threat coverage notes)

### Egress allow for training job
(YAML)
(Threat coverage notes)

## Layer 2: Mesh authorization

### Gateway: allow only model-serving for /v1/predict
(YAML)

### Feature store: allow only serving for read methods
(YAML)

## Layer 3: Application-layer authorization

### Decision 1: per-tenant feature access
...

### Decision 2: per-version model artifact access
...

### Decision 3: ...

## Cross-layer coverage table

| Threat | L3/L4 | Mesh | Application |
|---|---|---|---|

## Acknowledged gaps
```

## Quality criteria

A passing plan:

- L3/L4 policies are **specific**, not namespace-wide. They name
  pod labels.
- Mesh policies key on **workload identity** (principal), not on
  IP or namespace.
- Application-layer cases are real — multi-tenant resource access
  is the most common.
- The cross-layer table demonstrates that **each threat** is
  caught by at least one layer.

A failing plan:

- Default-deny is forgotten.
- Allows whole namespaces ("any pod in feature-store can talk to
  any pod in recs").
- Treats mesh authorization as if it knew about tenant resources.
- Omits the application-layer section.

## Reflection questions

1. What does the L3/L4 layer catch that the mesh layer cannot?
2. What does the mesh layer catch that the L3/L4 layer cannot?
3. What does only the application layer catch?
4. Which of the three layers is most likely to be misconfigured in
   real deployments, in your view? Why?

## Save your artifact

The YAML you produce here is the input to Module 04 (Network
Security) and Module 09 (Policy as Code).
