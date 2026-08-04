# Exercise 03 — NetworkPolicy and Mesh AuthorizationPolicy Authoring

**Estimated effort:** ~3 hours
**Deliverable:** A directory of Kubernetes YAML resources plus one
Markdown design note explaining choices and the negative-test plan.
**Prerequisites:** Chapter 04 read end-to-end. Exercises 01 and 02
completed (the assessment tells you the flows; the SPIFFE plan gives
you the principal names). A Kubernetes cluster you can experiment on
(kind, minikube, or a dedicated staging cluster) with a CNI that
enforces NetworkPolicy (Calico, Cilium, Antrea, or similar) and a
service mesh (Istio recommended; Linkerd or Consul are fine
substitutes).

---

## Objective

Author the full NetworkPolicy + mesh AuthorizationPolicy set that
segments the three planes of the target platform, with deny-by-
default anchors, narrow allow rules for the enumerated cross-
plane flows, and negative-test evidence that the policy set holds.

By the end of the exercise you should have a version-controlled
policy set that a peer engineer can apply to a cluster, whose
resulting reachability graph matches the plane model from chapter
01, and which passes an intentional-negative test.

## Problem statement

Continue with the fintech reference platform. Design targets:

- Three plane namespaces: `training`, `registry`, `serving`.
- Auxiliary namespaces: `feature-store` (may live in serving),
  `platform-system` (SPIRE, mesh control plane, monitoring),
  `istio-system` (mesh gateway).
- Cross-plane flows (from mod-102 asset inventory and exercise 01):
  - Training → Registry (write signed candidate artifact +
    attestations).
  - Registry → Serving (read verified artifact on serving-pod
    start; typically pulled by the serving pod itself).
  - Serving → Feature-store (read online features).
  - Serving → RAG retrieval → Vector index.
  - Serving → Tool-invocation gateway (LLM assistant only).
  - CI → Registry (attach attestations, sign, promote).
  - All planes → platform-system (SPIRE agent socket is Unix; DNS
    to kube-system; monitoring emits to Prometheus / Loki).
  - Ingress → Serving (authenticated tenants only).

## Requirements

Deliver a directory with the following structure:

```
exercise-03/
  netpol/
    training/
      00-deny-all.yaml
      10-allow-dns.yaml
      20-allow-egress-to-registry.yaml
      30-allow-egress-to-platform-system.yaml
    registry/
      00-deny-all.yaml
      10-allow-dns.yaml
      20-allow-ingress-from-training.yaml
      21-allow-ingress-from-serving.yaml
      22-allow-ingress-from-ci.yaml
    serving/
      00-deny-all.yaml
      10-allow-dns.yaml
      20-allow-egress-to-registry.yaml
      21-allow-egress-to-feature-store.yaml
      22-allow-ingress-from-ingress-gw.yaml
    feature-store/
      00-deny-all.yaml
      10-allow-dns.yaml
      20-allow-ingress-from-serving.yaml
  authz/
    peer-authentication.yaml
    request-authentication.yaml
    deny-all-anchors/*.yaml
    allow-training-write-registry.yaml
    allow-serving-read-registry.yaml
    allow-serving-read-features.yaml
    allow-rag-to-vector-index.yaml
    allow-ingress-to-serving.yaml
  DESIGN.md
  negative-tests/
    training-cannot-reach-serving.sh
    serving-cannot-reach-training.sh
    unauthenticated-caller-refused.sh
    ...
```

Every YAML file is applied by `kubectl apply -f`. Every `.sh` file
is a small script that exercises an intentional-negative test and
exits non-zero on unexpected success.

Rules:

- Every plane namespace has a `00-deny-all.yaml` NetworkPolicy
  that selects all pods and permits no ingress/egress.
- Every NetworkPolicy that opens a lane has a matching partner on
  the other side (egress + ingress pair). Do not accept a
  single-sided lane.
- Every `AuthorizationPolicy` matches on SPIFFE principals from
  exercise 02. No `principals: ["*"]`.
- `PeerAuthentication` is `STRICT` in the mesh control plane
  namespace and in every application namespace.
- The `DESIGN.md` names every cross-plane flow, the pair of
  policies that opens it, and the negative flow (what is blocked)
  it is deny-by-default against.
- The `negative-tests/` scripts run against a live cluster. Each
  attempts a connection that should be refused; the test passes
  when the connection is refused with the expected status
  (NetworkPolicy: dropped / connection refused; mesh authz:
  HTTP 403 `RBAC: access denied`).

### Design note contents (`DESIGN.md`)

- **Flow table.** One row per legitimate cross-plane flow, naming
  the source SPIFFE principal, the destination, the method, the
  path, the NetworkPolicy pair (by filename), and the
  AuthorizationPolicy rule (by name).
- **Negative table.** One row per meaningful denied flow (e.g.,
  serving → training) naming what stops it (the absence of an
  allow policy + the deny-all anchor).
- **Choices.** Which CNI you assume, which mesh, which mesh
  version, and any assumptions about the sidecar injection
  posture (Namespace label `istio-injection=enabled` or
  workload-specific annotations).
- **Test plan.** How you validate the set, including which
  policy-audit tools you ran (`kube-linter`, `netpol-analyzer`,
  Cilium's editor).
- **Known deferrals.** Explicit list of flows the exercise scope
  defers to a later cycle (e.g., egress to the Internet via an
  egress gateway).

## Starter guidance

- Author the deny-all anchors first for every namespace. Do not
  add any allow rule until the anchors exist.
- Author the mesh `deny-all` empty-ALLOW anchor for every
  namespace *before* the specific allow rules.
- Test on a small cluster with two or three namespaces first; the
  reachability failures surface quickly.
- If you use Istio, prefer `AuthorizationPolicy` `action: ALLOW`
  rules with explicit `principals` matches to explicit
  `action: DENY` rules — the ALLOW-based approach composes better
  with the anchor.
- Verify sidecar injection on every pod that a mesh policy
  targets. A pod without a sidecar bypasses mesh policy and only
  NetworkPolicy applies.
- The `negative-tests/` scripts are the exercise's most valuable
  artifact — a policy set that passes review but does not close
  the negative flow is worthless.

## Acceptance criteria

A passing policy set:

- Every namespace has a NetworkPolicy `default-deny-all` and a
  mesh `deny-all` anchor.
- Every cross-plane flow has a paired NetworkPolicy (egress on
  source, ingress on destination) and a matching mesh
  `AuthorizationPolicy` with the SPIFFE principal from exercise
  02.
- `PeerAuthentication` is `STRICT`.
- Ingress gateway requires JWT for tenant-scoped paths.
- All `negative-tests/*.sh` scripts pass on a live cluster
  (the negative flow is refused).
- `DESIGN.md` covers the flow table, negative table, choices,
  test plan, and deferrals sections.

A failing policy set:

- Any policy uses `principals: ["*"]` or a wildcard namespace
  selector that reintroduces open-world.
- Any allow policy is single-sided (egress without matching
  ingress or vice versa).
- Sidecar injection is not verified for the pods the mesh
  policies target.
- `negative-tests/` scripts do not exist or do not run.
- `DESIGN.md` narrates without a flow table.

## Stretch goals

- Add an **egress gateway** namespace and route all outbound
  Internet traffic through it. Egress from training goes to a
  narrow allow-list (PyPI mirrors, Hugging Face hub); egress from
  serving is telemetry-only. Include the corresponding policies.
- Add **AdminNetworkPolicy** (ANP) cluster-scoped deny rules for
  a base-of-defence layer that survives namespace-level policy
  drift. Requires a Kubernetes version and CNI that support ANP.
- Add **tenant-scoped rate-limit policies** at the ingress
  gateway using Istio's rate-limit filter or Envoy's global
  rate-limit service. Tie the rate-limit key to the JWT `sub`.
- Emit denial events to a dedicated NATS or Kafka topic and
  hand off to mod-111 SecOps for detection-content authoring
  (Sigma rule that alerts on repeated cross-plane denials from a
  single principal).

## Do not

- Do not commit a solution to any repository — solutions live in
  the paired solutions repo.
- Do not skip the negative tests. Policies that "look right" but
  don't refuse the intended-denied flow are the failure mode this
  exercise is written to prevent.
- Do not open a whole namespace-to-namespace allow. Every allow
  is scoped to the specific pods on each side.
- Do not conflate NetworkPolicy with mesh AuthorizationPolicy —
  each answers a different question.
