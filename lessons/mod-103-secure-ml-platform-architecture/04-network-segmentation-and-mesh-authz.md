# Chapter 04 — Network Segmentation: Kubernetes NetworkPolicy and Service-Mesh AuthorizationPolicy

> **Note on AI-assisted content.** Verify NetworkPolicy semantics
> against the Kubernetes upstream docs for your cluster version
> (behaviour differs for CNI plugins and for the `NetworkPolicy` API
> vs the newer `AdminNetworkPolicy` / `BaselineAdminNetworkPolicy`).
> Verify Istio AuthorizationPolicy syntax against the Istio release
> docs for the installed control plane version. See
> [`resources.md`](./resources.md).

---

## Why this chapter exists

Chapter 03 gave every workload an attested identity. This chapter
uses that identity to segment the cluster along the plane
boundaries — so a compromised training pod cannot reach the
serving plane, a compromised serving pod cannot reach the feature
store outside its tenant scope, and a compromised registry pod
cannot reach the training data.

The specific failure mode this chapter is written to prevent:

> A training pod compromised by a poisoned pip dependency scans
> the cluster's pod network, discovers the model registry API on
> its default port, uses the training-plane's registry-push
> credentials (correctly scoped to write), pushes a backdoored
> model artifact into the same version tag that CI pushed
> yesterday. Because there is no default-deny between the
> training and registry planes, and no L7 policy scoping *which*
> workload can push to *which* model, the poison lands. The
> serving plane pulls the artifact at next scheduled rollout and
> starts serving the backdoored model.

Two layered controls stop this:

- **NetworkPolicy at L3/L4** — default-deny between namespaces /
  planes, explicit allow for the enumerated flows in chapter 01.
- **Service-mesh AuthorizationPolicy at L7** — deny by default,
  allow only the specific SPIFFE identity + method + path
  combinations that the reference architecture permits.

Both are necessary. NetworkPolicy alone cannot express "workload
X can only call GET /predict on serving Y with tenant claim T".
Mesh AuthorizationPolicy alone does not stop pods that bypass the
mesh sidecar (compromised host-network pods, misconfigured
namespaces without sidecar injection). Layer them.

This chapter walks the concrete YAML for both, using the fintech
reference platform.

---

## The two policy surfaces — what each is good at

### Kubernetes NetworkPolicy

NetworkPolicy is a first-class Kubernetes API. It operates at L3/L4
(IP + port + protocol). It is enforced by the CNI plugin (Calico,
Cilium, Antrea, etc.). It is namespace-scoped: a policy in
namespace X selects pods in X.

Key semantics to install:

- **Default is allow.** A namespace with no NetworkPolicy allows
  all pod-to-pod traffic. The first NetworkPolicy that selects a
  pod switches that pod to **deny by default for the affected
  directions**; only the policy's `ingress` / `egress` rules
  permit.
- **The direction of the policy matters.** An `ingress` rule
  controls traffic coming *to* the selected pods. An `egress`
  rule controls traffic going *from* them. You need both to model
  bidirectional segmentation.
- **Multiple policies are additive.** If two policies select the
  same pod, the union of their allows applies.
- **You cannot express deny rules directly** in the `NetworkPolicy`
  API. The newer `AdminNetworkPolicy` (`ANP`) and
  `BaselineAdminNetworkPolicy` (`BANP`) APIs, promoted in more
  recent Kubernetes versions, add cluster-scoped deny and
  ordering. Use them for cluster-wide default-deny if your
  cluster and CNI support them.

For a plane-level default-deny scheme with legacy NetworkPolicy,
the standard shape is: **one deny-all policy per namespace, plus
narrow allow policies for the enumerated flows.**

### Service-mesh AuthorizationPolicy

Istio's `AuthorizationPolicy` (analogous constructs exist in
Linkerd, Consul, Kuma, and any Envoy-based mesh) operates at L7 on
mTLS-encrypted traffic that passes through the sidecar. Key
semantics:

- **L7 identity.** Match on the peer's SPIFFE ID (from the mTLS
  cert SAN), on JWT claims, on method + path.
- **Deny takes precedence over allow.** When multiple policies
  apply, an explicit DENY wins over an ALLOW at any priority.
- **Empty ALLOW → deny.** An `AuthorizationPolicy` of action
  `ALLOW` with no rules matches no requests → deny all. Use this
  as the deny-by-default anchor.
- **Applies only to sidecar-injected pods.** Pods without a
  sidecar bypass the policy. This is the reason NetworkPolicy is
  still required as the L3/L4 defence.

The two policy surfaces compose: NetworkPolicy enforces "can you
reach this port at all?", AuthorizationPolicy enforces "which
identity is allowed to invoke which method on which path?"

---

## The plane-level segmentation model

Recall the three planes and the legitimate cross-plane flows:

| From | To | Purpose |
| --- | --- | --- |
| Training | Registry | Write signed candidate artifact + attestations |
| Registry | Serving | Pull verified artifact on serving-pod start |
| Serving | Feature store | Read online features per request |
| CI | Registry | Attach attestations, sign, promote |
| Human operator | All planes (via bastion / gateway) | Debugging, deployment |

For simplicity, assume each plane is a Kubernetes namespace:

- `training`
- `registry`
- `serving`
- `feature-store` (may be its own or part of `serving`)
- `platform-system` (SPIRE server, ingress, monitoring)

---

## NetworkPolicy — the default-deny anchor per namespace

Every plane namespace gets a `deny-all` policy that selects every
pod and permits no ingress or egress. Then narrow allow policies
open only the required flows.

### The deny-all anchor (applied per namespace)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: training
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
```

Repeat for `registry`, `serving`, `feature-store`. This is the
foundation — every subsequent allow rule opens the minimum
needed and nothing more.

Two egress exceptions every namespace usually needs:

- DNS to `kube-system` on port 53 (UDP + TCP).
- SPIRE agent socket — but this is a Unix socket, not network
  traffic, so no NetworkPolicy applies.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-dns
  namespace: training
spec:
  podSelector: {}
  policyTypes: [Egress]
  egress:
    - to:
        - namespaceSelector:
            matchLabels: { kubernetes.io/metadata.name: kube-system }
          podSelector:
            matchLabels: { k8s-app: kube-dns }
      ports:
        - port: 53
          protocol: UDP
        - port: 53
          protocol: TCP
```

Label the namespaces (`kubernetes.io/metadata.name` is applied
automatically by kubelet on 1.22+) so cross-namespace selectors
work reliably.

### Allow training → registry (write model artifacts)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-training-egress-to-registry
  namespace: training
spec:
  podSelector:
    matchLabels: { component: training-job }
  policyTypes: [Egress]
  egress:
    - to:
        - namespaceSelector:
            matchLabels: { kubernetes.io/metadata.name: registry }
          podSelector:
            matchLabels: { component: model-registry }
      ports:
        - port: 8443
          protocol: TCP
```

Mirror on the receiving side:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-registry-ingress-from-training
  namespace: registry
spec:
  podSelector:
    matchLabels: { component: model-registry }
  policyTypes: [Ingress]
  ingress:
    - from:
        - namespaceSelector:
            matchLabels: { kubernetes.io/metadata.name: training }
          podSelector:
            matchLabels: { component: training-job }
      ports:
        - port: 8443
          protocol: TCP
```

Repeat this shape for every legitimate cross-plane flow. Every
pair of allow policies (egress on the source side, ingress on the
destination side) opens one narrow lane. Do not accept a policy
that allows the whole namespace unless the whole namespace really
is the source or destination.

### The critical negative rule: no serving → training, ever

There is no legitimate reason a serving pod should reach a
training pod. The default-deny anchor already refuses this, but
make the intent explicit in review by labelling the negative rule
in the design doc:

> **NEG-1:** No serving-plane pod initiates any connection to the
> training-plane namespace. Enforced by absence of egress policy
> on serving side and by default-deny anchor on training side.

Similarly:

- **NEG-2:** Registry-plane pods do not reach training data
  buckets (via cloud IAM scoping, not NetworkPolicy — the bucket
  is off-cluster).
- **NEG-3:** LLM-serving pods do not reach the primary training
  dataset store (again, cloud-IAM-scoped; NetworkPolicy
  reinforces if the store is in-cluster).

Chapter 05's admission policies check that these labels exist and
that the NetworkPolicy set is present in every namespace.

---

## Mesh AuthorizationPolicy — the L7 identity check

Istio examples below; the shape translates directly to Linkerd's
`Server` + `AuthorizationPolicy`, Consul's intentions, or Kuma's
`MeshTrafficPermission`.

### The deny-by-default anchor per namespace

```yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: deny-all
  namespace: registry
spec:
  {}
```

An empty `AuthorizationPolicy` with default action ALLOW and no
rules is equivalent to "deny all". Every plane namespace gets one.

Explicit deny is also available; used when you want to log the
denied requests for detection:

```yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: deny-cross-plane-writes
  namespace: registry
spec:
  action: DENY
  rules:
    - to:
        - operation:
            methods: ["POST", "PUT", "DELETE"]
      from:
        - source:
            notPrincipals:
              - "spiffe://td.acme.internal/plane/training/component/*"
              - "spiffe://td.acme.internal/plane/ci/component/*"
```

Explicit DENY rules are useful for audit trail — a hit on this
policy is a security event.

### Allow: training pipeline may write to the model registry

```yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-training-write-to-registry
  namespace: registry
spec:
  selector:
    matchLabels: { component: model-registry }
  action: ALLOW
  rules:
    - from:
        - source:
            principals:
              - "spiffe://td.acme.internal/plane/training/component/fraud-retrain"
              - "spiffe://td.acme.internal/plane/training/component/feature-eng"
      to:
        - operation:
            methods: ["POST", "PUT"]
            paths: ["/api/v2/models/*/versions"]
```

Note the level of tightness: named SPIFFE principals, named
methods, path pattern that fits the registry's actual API. Not
`"*"` on paths, not `"*"` on principals.

### Allow: serving-plane pods read models from the registry

```yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-serving-read-from-registry
  namespace: registry
spec:
  selector:
    matchLabels: { component: model-registry }
  action: ALLOW
  rules:
    - from:
        - source:
            principals:
              - "spiffe://td.acme.internal/plane/serving/component/*"
      to:
        - operation:
            methods: ["GET"]
            paths: ["/api/v2/models/*", "/api/v2/models/*/artifacts/*"]
```

Read-only by principal pattern for a whole plane. Writes are still
denied to the serving plane because no ALLOW rule lists it under
POST / PUT / DELETE.

### Allow: serving pods read features from the feature store — per-tenant scoping

The serving plane can read features, but tenant scoping is
required (mod-102 sensitivity tag drives this). Use JWT-based
extra constraints:

```yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-serving-read-features
  namespace: feature-store
spec:
  selector:
    matchLabels: { component: online-feature-store }
  action: ALLOW
  rules:
    - from:
        - source:
            principals:
              - "spiffe://td.acme.internal/plane/serving/component/fraud-serve/*"
      to:
        - operation:
            methods: ["GET"]
            paths: ["/features/v1/entities/*"]
      when:
        - key: request.headers[x-tenant-id]
          notValues: [""]
        - key: request.auth.claims[scope]
          values: ["features:read"]
```

The `when` clause pushes the tenant-scoping check up to the mesh
authz layer. The feature store's own service still enforces the
tenant match against the request payload; the mesh check is the
outer defence.

### Allow: RAG retrieval reaches only its embedding index

```yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-rag-to-vector-index
  namespace: serving
spec:
  selector:
    matchLabels: { component: vector-index }
  action: ALLOW
  rules:
    - from:
        - source:
            principals:
              - "spiffe://td.acme.internal/plane/serving/component/rag-retrieval"
      to:
        - operation:
            methods: ["POST"]
            paths: ["/search"]
```

No other principal (including other serving-plane workloads) can
reach the vector index. The LLM serving pod goes through
`rag-retrieval` to reach vectors — the retrieval layer enforces
the retrieval-boundary trust boundary from mod-102 chapter 01.

---

## Enforcing plane isolation on the ingress edge

External traffic enters through the ingress gateway. The gateway
is itself a mesh workload with its own SPIFFE ID. Two policies at
the ingress:

- **PeerAuthentication** — enforce mTLS on all mesh traffic. Once
  set to `STRICT`, plaintext is rejected at the sidecar.

```yaml
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT
```

- **AuthorizationPolicy on ingress** — restrict which external
  endpoints exist and require valid JWT for tenant-scoped ones.

```yaml
apiVersion: security.istio.io/v1
kind: RequestAuthentication
metadata:
  name: tenant-jwt
  namespace: istio-system
spec:
  selector:
    matchLabels: { istio: ingressgateway }
  jwtRules:
    - issuer: "https://idp.acme.local/"
      jwksUri: "https://idp.acme.local/.well-known/jwks.json"
      audiences: ["fraud-serve", "assistant-serve"]
---
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-authenticated-tenants
  namespace: istio-system
spec:
  selector:
    matchLabels: { istio: ingressgateway }
  action: ALLOW
  rules:
    - from:
        - source:
            requestPrincipals: ["*"]
      to:
        - operation:
            paths: ["/api/fraud/*", "/api/assistant/*"]
```

Combined, no external caller can reach a serving endpoint without
a valid JWT from the enterprise IdP, and no internal cross-plane
call runs unauthenticated at the mesh.

---

## Verifying the policy set — the round-trip test

A NetworkPolicy or AuthorizationPolicy that looks correct on
paper may still leave a gap. Two verification methods:

### Method 1 — the intentional-negative test

For every plane boundary, deploy a small test pod with the SPIFFE
identity of the *wrong* plane and try to reach the target. The
attempt must fail; if it succeeds, a policy is missing or the
sidecar is not injected.

Example:

```bash
# From a pod in training namespace, try to reach the serving service
kubectl exec -n training training-job-abc -- \
  curl -v --cacert /var/run/secrets/istio/root-cert.pem \
       --cert /var/run/spire/svid.pem --key /var/run/spire/svid.key \
       https://fraud-serve.serving.svc.cluster.local/predict
# Expected: connection refused (NetworkPolicy) or 403 RBAC:access
# denied (mesh authz). If 200 OK, the policy is broken.
```

### Method 2 — kube-linter / policy-audit tooling

Tools like `kube-linter`, `polaris`, `netpol-analyzer`, and
Cilium's `network-policy-editor` can statically compute the
effective reachability graph and flag flows that violate the
plane-model. Run in CI on every policy change.

Chapter 06's admission gate can also enforce a "namespace must
have a default-deny NetworkPolicy" constraint, refusing
namespaces without one.

---

## Egress to the outside world — the outbound plane

Egress from cluster pods to the internet is a separate cross-
cutting concern. Recommended posture:

- **Explicit egress gateway.** Route all egress through a
  dedicated Istio Egress Gateway or a dedicated
  `network-egress-proxy` namespace. Pods should not have direct
  Internet reachability.
- **Egress allow-list per plane.**
  - Training may need `pypi.org`, `huggingface.co`,
    `dl.pytorch.org` (during pip install), plus dataset registries
    it uses. Log every request.
  - Serving typically has no legitimate egress except telemetry
    to the observability plane. If a serving pod is reaching
    `pastebin.com`, that is exfiltration.
  - Registry / CI has its own narrow list (mirrors, GitHub,
    Sigstore).
- **DNS via an internal resolver.** Prevents DNS-tunnel exfil to
  external resolvers.

Mod-111 SecOps consumes egress logs from this layer.

---

## A worked plane-boundary policy set for the fintech reference

For the fintech reference platform, the minimum policy count:

- Per namespace (`training`, `registry`, `serving`, `feature-store`,
  `platform-system`): one `default-deny` NetworkPolicy, one
  `allow-egress-dns` NetworkPolicy, one empty AuthorizationPolicy
  (deny-all anchor). **5 × 3 = 15 baseline policies.**
- Cross-plane allow policies (from the flow table): typically 6–10
  NetworkPolicy pairs (source-egress + destination-ingress) and
  6–10 AuthorizationPolicy rules.
- Ingress: PeerAuthentication STRICT, RequestAuthentication for
  tenant JWT, AuthorizationPolicy for tenant-scoped access.

Total: ~30–40 policy resources for the reference platform. Every
one appears in exercise 03's deliverable.

---

## Common failure modes

- **Sidecar not injected on the receiving pod.** The mesh
  AuthorizationPolicy does not apply — traffic reaches the pod
  unauthenticated. NetworkPolicy is the fallback but does not
  authenticate. Fix: enforce sidecar injection via a Gatekeeper
  policy (chapter 06).
- **Host-network pods.** Pods with `hostNetwork: true` bypass the
  pod network and the mesh. PSA `restricted` (chapter 05) forbids
  this; add an OPA policy to double-check.
- **NetworkPolicy label typo.** A `podSelector` that matches no
  pods is silently a no-op. Verification method 1 catches this.
- **AuthorizationPolicy wildcard on principals.** A rule
  `principals: ["*"]` reintroduces open-world. Prohibit in code
  review; add a Gatekeeper policy that rejects it.
- **Ingress bypassed by port-forward.** A developer with
  `kubectl port-forward` reaches a pod without going through the
  ingress mesh. Restrict the cluster RBAC for `pods/portforward`
  in production and audit remaining use.
- **NetworkPolicy applies at pod, not node.** Pods on the same
  node communicating over `hostNetwork` or `localhost` are not
  covered. Do not run cross-plane workloads on the same node
  with `hostNetwork` at all.

---

## Objections

### "Isn't the mesh AuthorizationPolicy enough on its own?"

No. Mesh policy applies only when the sidecar is present and only
to mesh-managed traffic. A pod that spawns without a sidecar, a
pod in a namespace whose label was changed to disable injection,
or a pod on `hostNetwork` — all bypass the mesh. NetworkPolicy is
the L3/L4 backstop; the mesh policy is the L7 identity check.
Both layers.

### "Why can't we just use IP-based rules like the old firewall?"

Because pods have ephemeral IPs. Cross-plane rules that reference
IP ranges rot immediately and cannot express identity. The whole
point of chapters 03–04 is that identity, not IP, is the axis of
authorisation.

### "What about egress to shared services (Prometheus, Loki, etc.)?"

Add explicit egress allow rules from every plane to the
observability namespace. Log-shipping is a legitimate flow and
belongs in the enumerated set. Do not paper over it with a broad
"allow everything to the platform-system namespace" — narrow it
to the specific ports and workloads.

---

## The mistakes this chapter is trying to prevent

- **Skipping either policy layer** (NetworkPolicy or mesh
  AuthorizationPolicy). The two answer different questions.
- **Broad namespace-to-namespace ingress rules.** "Allow anything
  from `training`" concedes lateral movement inside a plane back
  into another.
- **Forgetting the deny-all anchor.** A namespace without one has
  no default-deny; every allow is additive against an already-
  permissive base.
- **AuthorizationPolicy without matching NetworkPolicy.** L7-only
  is bypassable at L3.
- **NetworkPolicy without matching AuthorizationPolicy.** L3/L4-
  only permits any authenticated identity to reach an open port.
- **Not automating the reachability audit.** Manual review of
  the policy set breaks down at scale; use `kube-linter`,
  `netpol-analyzer`, or the mesh's own visualiser.

---

## Summary

- Two policy surfaces: Kubernetes NetworkPolicy at L3/L4 for
  plane-level reachability, service-mesh AuthorizationPolicy at
  L7 for identity + method + path.
- Both start from a deny-by-default anchor per namespace and open
  only the enumerated flows.
- NetworkPolicy pairs (egress on source + ingress on destination)
  open each lane; do not accept a single-sided rule.
- Mesh AuthorizationPolicies match on SPIFFE principals from
  chapter 03, on methods, on paths, and (where needed) on JWT
  claims for tenant scoping.
- Ingress uses `PeerAuthentication STRICT` and
  `RequestAuthentication` for JWT.
- Verification: intentional-negative tests plus policy-audit
  tooling in CI. Do not ship policy changes without both.
