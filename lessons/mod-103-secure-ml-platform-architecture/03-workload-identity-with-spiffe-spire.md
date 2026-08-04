# Chapter 03 — Workload Identity with SPIFFE and SPIRE

> **Note on AI-assisted content.** Verify SPIFFE spec versions and
> SPIRE APIs against [spiffe.io](https://spiffe.io) and the SPIRE
> repository on GitHub. SVID formats and node-attestor plugin names
> change between minor versions. See [`resources.md`](./resources.md).

---

## Why this chapter exists

Zero trust starts with identity. Chapter 02 said: for every request
between planes, the PDP must be able to answer "who is calling me,
attested?" The answer that is durable across cloud providers,
across clusters, and across service-mesh choices is **SPIFFE**
(Secure Production Identity Framework For Everyone), reference-
implemented by **SPIRE** (the SPIFFE Runtime Environment).

The specific failure mode this chapter is written to prevent:

> A training pod runs on a node whose IAM role grants read access
> to every dataset in the data lake. A poisoned pip dependency
> executes at import time, reads the node's instance metadata
> service, obtains the node role, and enumerates + exfiltrates
> every training corpus in the account. The training pod's own
> Kubernetes service-account token was never needed by the
> attacker; the ambient node identity was enough. No control on
> the platform authenticated *the workload* — only the node.

SPIFFE closes this by minting a **short-lived, per-workload
identity** at pod start, verified by an attestation of who the pod
actually is (node + kubelet + image + pod attributes). The pod
exchanges that identity for cloud-provider credentials via OIDC
federation, so no long-lived cloud secrets sit in the pod's
environment, and no ambient node role is used for pod-scoped
operations.

This chapter installs:

- The SPIFFE identity model (SPIFFE ID, SVID, trust domain).
- The SPIRE deployment shape (server, agents, node + workload
  attestors, registration API).
- How to design the SPIFFE ID scheme for an ML platform (training,
  registry, serving; per-model, per-tenant selectors).
- How to exchange an SVID for short-lived cloud credentials.
- How to use the SVID in mesh mTLS and in admission-time policy.
- Rotation and revocation posture.

---

## The SPIFFE identity model — the vocabulary

Three definitions to install now.

### Trust domain

A trust domain is a security boundary within which SPIFFE IDs are
issued. Represented as a DNS-name-shaped string (no protocol
prefix): `td.acme.internal`. One SPIRE server (or a federated set)
owns a trust domain.

Practical rule: one trust domain per **security perimeter**, not
per cluster. A single trust domain can span multiple clusters if
they share a security boundary (same operator team, same audit
scope). Cross-trust-domain communication requires **federation**
(exchange of trust bundles, so each side can verify the other's
SVIDs).

### SPIFFE ID

A SPIFFE ID is a URI of the form
`spiffe://<trust-domain>/<workload-path>`. The path portion is
arbitrary but conventionally hierarchical. Examples:

```
spiffe://td.acme.internal/ns/training/sa/fraud-retrain
spiffe://td.acme.internal/ns/serving/sa/fraud-serve/model/fraud-v42
spiffe://td.acme.internal/ns/registry/sa/mlflow-server
spiffe://td.acme.internal/pipeline/ci/build/main
```

The path is the workload's identifier. Design it so that
authorisation policies can match on it directly (chapter 04's
AuthorizationPolicies match on SPIFFE ID patterns).

### SVID — SPIFFE Verifiable Identity Document

An SVID is the cryptographic document that carries the SPIFFE ID.
Two formats:

- **X.509-SVID.** An X.509 certificate whose SAN contains the
  SPIFFE ID URI. Used for mTLS.
- **JWT-SVID.** A JWT whose `sub` is the SPIFFE ID. Used for OIDC
  exchange, for cross-service RPC where mTLS is not available, and
  for cloud-federation token exchange.

Both are short-lived (defaults: X.509-SVID hours, JWT-SVID
minutes) and rotated automatically by the SPIRE agent.

---

## SPIRE deployment — the components you install

SPIRE is the reference SPIFFE implementation. Two components:

- **SPIRE server** — the identity provider. Holds the trust
  domain's signing key material, maintains the registration
  entries, and signs SVIDs on request. Typically HA (3+ replicas),
  backed by a database (SQL / etcd) for registration state.
- **SPIRE agent** — a per-node DaemonSet component that
  authenticates itself to the server (node attestation), fetches
  the registration entries relevant to workloads on its node, and
  serves the Workload API on a Unix socket to pods.

Pods talk to the SPIRE agent over the Workload API (a Unix domain
socket, typically at `/run/spire/agent.sock`). They do not talk to
the SPIRE server directly. The agent verifies the pod's identity
using selectors (see below) and returns the corresponding SVIDs.

### Node attestation

Before a SPIRE agent can serve any workload, the agent itself must
prove to the server that it is running on a legitimate node. Node
attestors are pluggable. Common examples:

- `k8s_psat` — Kubernetes projected service-account token: the
  agent presents a JWT the kubelet issued for it, and the SPIRE
  server verifies it against the cluster's OIDC issuer.
- `aws_iid` — the EC2 instance identity document, verified against
  the AWS metadata service.
- `gcp_iit` — the GCE instance identity token.
- `azure_msi` — the Azure managed identity.
- `join_token` — a one-shot bootstrap token (bare-metal / dev).

For a cloud-hosted Kubernetes cluster, layered attestors are
common: `k8s_psat` for the pod, `<cloud>_iid` for the node,
combined so that a rogue in-cluster pod cannot produce SPIRE
agents impersonating other nodes.

### Workload attestation

Once the agent is trusted, it must decide what SVID to hand a
requesting pod. It uses **selectors** — attributes of the pod
extracted at request time. Common selectors:

- `k8s:ns:<namespace>` — pod's namespace.
- `k8s:sa:<serviceaccount>` — pod's service account.
- `k8s:pod-label:<key>:<value>` — pod label.
- `k8s:container-image:<image>` — container image reference.
- `unix:uid:<uid>` — process UID (for hosts).
- `docker:image:<image>` — Docker image (for host workloads).

A **registration entry** on the SPIRE server binds a SPIFFE ID to
a selector set (or a set of selectors). When a pod requests an
SVID, the agent evaluates its actual selectors against registered
entries; a match yields the SVID.

Example registration entry (SPIRE server API, JSON form):

```json
{
  "spiffe_id": "spiffe://td.acme.internal/ns/serving/sa/fraud-serve/model/fraud-v42",
  "parent_id": "spiffe://td.acme.internal/spire/agent/k8s_psat/prod-cluster/<node-uid>",
  "selectors": [
    "k8s:ns:serving",
    "k8s:sa:fraud-serve",
    "k8s:pod-label:model:fraud-v42",
    "k8s:container-image:registry.acme.local/models/fraud-v42@sha256:…"
  ],
  "ttl": 3600
}
```

Selector rules to install:

- **Prefer selectors an attacker cannot forge.** Container image
  digest and namespace + service account are stronger than pod
  labels an attacker with cluster-write can add.
- **Match on multiple selectors.** A single-selector match is
  usually too broad.
- **Never rely solely on service-account name.** A compromised
  operator with `serviceaccounts/create` in the namespace could
  create a service account named `fraud-serve` in an attacker
  pod. Layer image digest / namespace so a moved pod cannot
  masquerade.

---

## Designing the SPIFFE ID scheme for an ML platform

The scheme must be readable, matchable in AuthorizationPolicy
patterns, and stable across restarts of the same logical workload.

### Recommended path convention

```
spiffe://<td>/ns/<namespace>/sa/<sa-name>[/model/<model-name>][/tenant/<tenant>]
```

Or the plane-first variant, which chapter 04's AuthorizationPolicy
patterns match cleanly:

```
spiffe://<td>/plane/<training|registry|serving>/component/<name>[/model/<name>]
```

Whichever variant you pick, apply it consistently across the
platform. The mesh authz rules in chapter 04 will match on this
path; drift between naming conventions across teams means every
rule needs a per-team OR clause.

### Worked example — SPIFFE ID scheme for a fintech ML platform

Applying to the fintech reference system:

| Workload | SPIFFE ID |
| --- | --- |
| Fraud model retraining job (monthly) | `spiffe://td.acme.internal/plane/training/component/fraud-retrain` |
| Feature-engineering job | `spiffe://td.acme.internal/plane/training/component/feature-eng` |
| Model registry (MLflow) | `spiffe://td.acme.internal/plane/registry/component/mlflow` |
| CI signing job | `spiffe://td.acme.internal/plane/ci/component/cosign-signer` |
| Fraud model serving | `spiffe://td.acme.internal/plane/serving/component/fraud-serve/model/fraud-v42` |
| LLM assistant serving | `spiffe://td.acme.internal/plane/serving/component/assistant-serve` |
| RAG retrieval | `spiffe://td.acme.internal/plane/serving/component/rag-retrieval` |
| Vector index | `spiffe://td.acme.internal/plane/serving/component/vector-index` |
| Tool-invocation gateway | `spiffe://td.acme.internal/plane/serving/component/tool-gateway` |

Every SPIFFE ID here is stable across pod restarts. Rolling a new
model version does *not* change the SPIFFE ID at the component
level; the model version is a separate selector / label used by
per-model policy where needed.

---

## Exchanging an SVID for short-lived cloud credentials

The most valuable operational outcome of adopting SPIFFE for ML is
removing ambient node IAM. The pattern:

1. Pod requests a JWT-SVID from the SPIRE agent via the Workload
   API.
2. Pod presents the JWT-SVID to the cloud STS federation endpoint
   (AWS `AssumeRoleWithWebIdentity`, GCP `iam.credentials.exchangeToken`,
   Azure federated identity credential).
3. Cloud STS verifies the JWT-SVID's signature against SPIRE's
   OIDC-published JWKS, verifies the `sub` (the SPIFFE ID) against
   its own trust policy, and returns short-lived cloud
   credentials scoped to the role the SPIFFE ID is allowed to
   assume.
4. Pod uses the cloud credentials for the specific operation and
   discards them; they expire in minutes to an hour by default.

Key design points:

- **The SPIRE server exposes an OIDC discovery endpoint** so that
  cloud STS can fetch the JWKS. In practice this runs behind
  ingress inside the cluster or in front of the SPIRE server as a
  sidecar.
- **The cloud trust policy names the SPIFFE ID explicitly.** For
  AWS, the IAM role trust policy conditions on `sub` and `aud`.
  For GCP, the workload-identity pool binds SPIFFE IDs to service
  accounts.
- **Every cloud role should be scoped narrowly.** The fraud
  retraining SPIFFE ID gets a role that reads *only* the fraud
  training bucket, not the whole data lake.
- **The pod holds no long-lived cloud secret.** The JWT-SVID is
  short-lived; the exchanged STS token is short-lived; nothing
  survives pod termination.

Example — AWS IAM role trust policy that federates from SPIRE's
OIDC issuer:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Federated": "arn:aws:iam::123456789012:oidc-provider/spire.acme.internal" },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "spire.acme.internal:aud": "aws.acme.internal",
          "spire.acme.internal:sub": "spiffe://td.acme.internal/plane/training/component/fraud-retrain"
        }
      }
    }
  ]
}
```

The condition keys (`sub`, `aud`) are the SPIFFE ID and the
audience the pod requested — verify both. Cloud provider defaults
(e.g., wildcards on `sub`) are dangerous; the trust policy must
name the exact SPIFFE ID.

---

## Using the SVID in mesh mTLS

Once a pod has an X.509-SVID, the mesh sidecar can be configured
to accept it as the mTLS client / server certificate. Both Istio
and Linkerd support SPIRE as an identity source.

- **Istio** — the `istio-agent` (part of the sidecar) can be
  configured to fetch SVIDs from the SPIRE agent's Workload API
  instead of Istio's built-in `Citadel` CA. The mesh's
  PeerAuthentication and AuthorizationPolicy resources then match
  on the SPIFFE ID present in the client certificate SAN.
- **Linkerd** — Linkerd supports SPIRE via its
  `linkerd-identity` plugin.
- **Envoy on its own** — Envoy proxies not behind a full mesh can
  read SVIDs from the SPIRE agent using the Envoy SDS integration.

Chapter 04 walks the mesh AuthorizationPolicy YAML that matches on
the SPIFFE IDs designed here.

---

## Using the SVID in admission-time policy

Chapter 06's Gatekeeper policies match, for example, on the CI
pipeline's SPIFFE ID that signed the model artifact. The
signature-verification step consults Sigstore / Rekor and asks
"was this artifact signed by SPIFFE ID X, and is that ID on the
builder allow-list?"

The admission gate does not talk to SPIRE for the runtime pod; the
Kubernetes admission chain runs before the pod exists. But the
gate does read *evidence about earlier subjects* — the CI job's
SPIFFE ID as recorded in the Rekor entry, for example.

---

## Rotation and revocation

- **X.509-SVID rotation.** SPIRE agent rotates certificates
  automatically well before expiry; workloads read the current
  SVID from the Workload API on demand or subscribe to the
  streaming API for push updates. No manual rotation.
- **JWT-SVID rotation.** JWT-SVIDs are re-minted on demand. Pods
  should request a fresh one just before use.
- **Registration change.** Delete the SPIRE server registration
  entry; the pod's next SVID request fails; existing SVIDs remain
  valid until their (short) TTL expires. For urgent revocation,
  shorten the TTL globally *before* the incident, so the maximum
  post-registration-removal exposure is bounded.
- **Trust-bundle rotation.** SPIRE rotates its own signing keys on
  a schedule; downstream consumers (cloud STS OIDC, mesh) must
  handle key rollover. Publish the JWKS with `kid` fields and let
  consumers cache.

---

## SPIRE deployment pattern for an ML cluster — reference topology

```
   ┌──────────────────────────────┐
   │  SPIRE server (StatefulSet)  │
   │  - HA replicas (3)           │
   │  - SQL / etcd backing        │
   │  - OIDC discovery endpoint   │
   │  - Registration API          │
   └──────────────┬───────────────┘
                  │ gRPC (mTLS with cluster-scoped root CA)
                  │
   ┌──────────────┼──────────────────────────────────────┐
   │              │                                       │
   ▼              ▼                                       ▼
┌──────────┐  ┌──────────┐                           ┌──────────┐
│ Node 1   │  │ Node 2   │        ... N nodes ...    │ Node N   │
│ SPIRE    │  │ SPIRE    │                           │ SPIRE    │
│ agent    │  │ agent    │                           │ agent    │
│ (DS pod) │  │ (DS pod) │                           │ (DS pod) │
└────┬─────┘  └────┬─────┘                           └────┬─────┘
     │             │                                     │
Workload API   Workload API                        Workload API
(Unix socket)   (Unix socket)                       (Unix socket)
     │             │                                     │
     ▼             ▼                                     ▼
 ┌───────┐    ┌───────┐                             ┌───────┐
 │ Pod A │    │ Pod B │                             │ Pod C │
 │  ⋮    │    │  ⋮    │                             │  ⋮    │
 └───────┘    └───────┘                             └───────┘
```

Deployment notes:

- **SPIRE server on its own nodes / node pool.** Isolate it from
  training / serving workloads. If the ML nodes are compromised,
  the SPIRE server continues to serve.
- **Registration entries as code.** Manage entries with a GitOps
  tool (Argo CD, Flux) so registration changes go through review.
- **Registration API access strictly scoped.** The controller
  authorised to create entries should be its own workload with
  its own SPIFFE ID; do not give humans direct write access to
  the registration API in production.
- **Federation only where necessary.** If two clusters share a
  security boundary and one trust domain, no federation is
  needed. If not, federate explicitly.

---

## Pushback and objections

### "Isn't Kubernetes ServiceAccount + BoundServiceAccountTokenVolume already enough?"

Bound projected tokens are a real improvement over legacy tokens
and are the right identity substrate for pods that only need to
talk to the Kubernetes API. They are not enough for zero-trust
mesh authz between planes because:

- The `sub` is the Kubernetes service account, not an attested
  workload identity. Any pod running under that SA gets the same
  identity, regardless of image.
- Cross-cluster identity is not defined. SPIFFE + federation gives
  you cross-cluster.
- Cloud federation requires an OIDC issuer; SPIRE gives you a
  managed one across clouds. K8s can be configured similarly but
  the ergonomics for multi-cluster federation are worse.

Use projected tokens for talking to the Kubernetes API. Use
SPIFFE for everything else.

### "Do we really need SPIRE, or can we use the mesh's built-in identity?"

Both Istio and Linkerd ship built-in identity plugins that mint
cert-per-pod. For a single-mesh, single-cluster deployment, those
are sufficient for mesh mTLS.

You want SPIRE when any of the following are true:

- You have workloads not covered by the mesh (batch jobs on VMs,
  Ray clusters, dedicated GPU nodes not on the mesh).
- You need cloud IAM federation with per-workload scopes.
- You have multiple clusters that need to share an identity model.
- You want the workload attestation to include image digest and
  arbitrary selectors the mesh does not expose.

For an ML platform that spans training clusters (often GPU-heavy,
batch-oriented, not always in-mesh) and serving clusters (mesh-
heavy), SPIRE is the durable choice.

---

## The mistakes this chapter is trying to prevent

- **Using node IAM as workload IAM.** The default of "attach a
  broad IAM role to the node, let all pods inherit" is the exact
  failure mode this chapter fixes.
- **SPIFFE IDs that leak sensitive detail.** Do not put tenant
  IDs, customer IDs, or model version secrets into SPIFFE IDs.
  SPIFFE IDs appear in logs, in policies, in mesh telemetry.
- **Single-selector registration entries.** Match on multiple
  attributes so a moved pod cannot masquerade.
- **Wildcard trust in cloud federation.** `"sub": "*"` in a cloud
  trust policy defeats the whole purpose.
- **Not planning rotation.** SVID TTLs default short for a
  reason; do not raise them to hours or days to "reduce noise" —
  the noise is the point.
- **Registering entries by hand.** Registration state must be
  GitOps-managed; a human with the registration API token can
  hand out any identity.

---

## Summary

- SPIFFE gives every workload a URI-shaped identity (SPIFFE ID)
  and a cryptographic document carrying it (SVID). SPIRE is the
  reference SPIFFE implementation: server + per-node agents.
- Workloads authenticate to the SPIRE agent via selectors
  (namespace, service account, image digest, labels). Registration
  entries bind SPIFFE IDs to selector sets.
- ML platforms use SPIFFE to eliminate ambient node IAM (via
  SPIFFE→cloud federation), to authenticate cross-plane traffic
  in the mesh, and to name the CI signer whose SPIFFE ID Rekor
  entries reference.
- Design a stable, hierarchical, matchable SPIFFE ID scheme:
  plane / component / model. Chapter 04's mesh AuthorizationPolicy
  matches on it.
- Rotation is automatic and short by default; do not raise TTLs to
  reduce log noise.
- SPIRE server on isolated nodes, registration entries as code,
  federation only where security boundaries require it.
