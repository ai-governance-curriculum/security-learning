# Chapter 01 — Zero Trust for ML Platforms: The Three-Plane Model

> **Note on AI-assisted content.** These lecture chapters were drafted
> with AI assistance and are under human review. Verify every standard
> version, technology API, and control claim against the primary
> source before quoting in production work. See
> [`resources.md`](./resources.md).

---

## Why this chapter exists

Mod-101 installed the vocabulary. Mod-102 installed the threat-model
method and produced the artifact this module consumes: an asset
inventory, an ML-adapted STRIDE table, an ATLAS + NIST AI 100-2
mapping, three attack trees, and a mitigation scorecard.

Mod-103 installs the **platform architecture** that makes those
mitigations enforceable. A threat model that says "the training data
must not be reachable from the serving pod" is inert until the
platform actively refuses that reachability. That refusal is what
zero trust delivers.

The specific failure mode this chapter is written to prevent:

> A team adopts "zero trust" as a slogan. They add SSO in front of
> Kubeflow, put the ML cluster on a VPN, and call the job done. The
> serving pod still runs with a broad service-account token that
> can pull any object from the model registry. The training pod's
> node has an IAM role attached that grants it read on every S3
> prefix, including PII datasets it does not use. When an attacker
> compromises a training pod through a poisoned dependency, they
> pivot laterally without hitting a single policy check because the
> platform has no policy-decision point between planes.

Zero trust is not a perimeter. It is an architecture where **every
request is authenticated, authorised, and encrypted regardless of
its network origin**, and where the policy decision runs on
verifiable identity, verifiable device / workload posture, and
verifiable request context — not on IP address or network zone.

This chapter installs the motivation, the reference model (the
three ML planes), and the primitives the rest of the module builds
against. Chapters 02–06 turn each primitive into an enforceable
control.

---

## What zero trust means — the NIST SP 800-207 definition

NIST SP 800-207 defines **Zero Trust Architecture (ZTA)** as an
enterprise's cybersecurity architecture based on zero-trust
principles. The core tenets, paraphrased from SP 800-207 §2:

1. All data sources and computing services are considered
   *resources*.
2. All communication is secured regardless of network location.
3. Access to individual enterprise resources is granted on a
   **per-session** basis.
4. Access to resources is determined by **dynamic policy** — the
   observable state of client identity, application / service, and
   the requesting asset, and may include other behavioural and
   environmental attributes.
5. The enterprise monitors and measures the integrity and security
   posture of all owned and associated assets.
6. All resource authentication and authorisation are **dynamic and
   strictly enforced before access is allowed**.
7. The enterprise collects as much information as possible about
   the current state of assets, network infrastructure, and
   communications and uses it to improve its security posture.

The architectural primitives named by SP 800-207 §3:

| Primitive | Role |
| --- | --- |
| **Policy Enforcement Point (PEP)** | The component that terminates the request and consults the PDP. In ML platforms: the mesh sidecar, the ingress gateway, the admission controller, the API gateway in front of the model registry. |
| **Policy Decision Point (PDP)** | The component that renders the allow / deny decision. Composed of the Policy Engine (PE) and the Policy Administrator (PA). In ML platforms: OPA, Gatekeeper, mesh RBAC, the SPIRE control plane. |
| **Policy Information Point (PIP)** | The sources the PDP consults for context — identity provider, CMDB, threat-intelligence feed, ML model registry, SBOM store, signature-verification service. |
| **Trust algorithm inputs** | Identity, device / workload posture, request attributes, environmental attributes (time, geolocation, threat feed). |

Chapter 02 walks the primitives in depth and shows how each maps to
a specific enforcement point on the ML platform.

---

## Why ML platforms need a zero-trust architecture — three concrete pressures

Classical microservice zero trust is well-served by the standard
kit: an identity provider, a mesh, network policies, an admission
gate. ML platforms bring three pressures on top.

### Pressure 1 — Training pods have unusually broad blast radius

A training pod is typically privileged: it needs GPU access, it
reads large datasets, it writes model artifacts. In many
platforms, the *node* running that pod carries an IAM role broad
enough to satisfy every dataset the training team ever uses, so
node-level credential theft is a full-data-lake compromise. The
zero-trust reflex — replace ambient node identity with per-pod,
attested, short-lived workload identity — is not optional here; it
is the difference between a poisoned dependency stealing one
dataset and stealing all of them.

Chapter 03 handles this with SPIFFE / SPIRE.

### Pressure 2 — The registry-to-serving hop is a supply-chain gate

Serving pods pull model artifacts at start. Whether the pulled
artifact was signed, whether its provenance is attested, whether
its ML-BOM lists any denied dependencies, whether the artifact
scanner returned clean — all of these decisions must land *before*
the pod runs, not after. If the decisions run at CI time only, an
attacker with write access to the registry (via credential theft,
misconfigured RBAC, or dependency compromise) can push a
malicious artifact and every serving pod will silently swap
onto it.

The zero-trust reflex here is to add a **policy-decision hop at
admission** — the admission controller re-verifies signatures,
provenance, ML-BOM presence, and scan-clean freshness at deploy
time, and refuses admission on failure. Chapter 06 handles this
with OPA / Gatekeeper.

### Pressure 3 — Cross-plane traffic must be segmented, but the planes share the cluster

Training, registry, feature, and serving planes typically share a
Kubernetes cluster (occasionally two, rarely per-plane clusters).
Ambient reachability inside the cluster — the default-allow
pod-to-pod network — is a lateral-movement multiplier. A
compromised training pod that can reach the registry API server
can push a malicious model; a compromised serving pod that can
reach the feature store can exfiltrate features; a compromised
registry pod that can reach the training bucket can poison future
retrains.

The zero-trust reflex is **default-deny between planes**, with
NetworkPolicy at L3/L4 and mesh AuthorizationPolicy at L7.
Chapter 04 handles this.

---

## The three planes of an ML platform

For this module and every subsequent chapter, we use a
three-plane reference model. The planes are not sacred; they are a
segmentation model that composes cleanly with zero-trust
enforcement points.

### Training plane

Where models are trained and datasets are read at bulk. Typical
components:

- Training job orchestrator (Kubeflow, Argo Workflows, Ray,
  vendor-managed like Vertex AI training).
- Training pods with GPU / accelerator attachments.
- Feature-engineering / preprocessing jobs.
- Read-side access to the data lake (raw training data,
  feature store snapshots).
- Write-side access to an experiment tracker (MLflow, Weights &
  Biases) and to a candidate-model registry.

### Registry plane

Where model artifacts, ML-BOMs, provenance attestations,
signatures, and scan results live. Typical components:

- Model registry (MLflow, Sagemaker Model Registry, Vertex AI Model
  Registry, self-hosted OCI-based registry).
- Signature and attestation store (Sigstore / Rekor transparency
  log, in-toto attestations, cosign signatures).
- ML-BOM store (CycloneDX ML-BOM documents).
- Artifact scanner outputs (ModelScan, safetensors validators,
  container scanners for served images).

### Serving plane

Where models are exposed for inference. Typical components:

- Model-serving runtime (KServe, Seldon Core, Ray Serve,
  TorchServe, Triton, vLLM, TGI).
- Feature retrieval / online feature store.
- RAG retrieval layer / vector store for LLM apps.
- Tool-invocation gateway for agent apps.
- Ingress / API gateway.

### Cross-plane flows (the only legitimate ones)

Legitimate flows between planes, with the direction that the
policy should permit:

| From | To | Purpose | Permitted operations |
| --- | --- | --- | --- |
| Training plane | Registry plane | Push signed candidate artifacts, ML-BOM, provenance | write-once artifact, no overwrite |
| Registry plane | Serving plane | Pull verified, admitted artifacts on serving-pod start | read-only artifact + verify signature |
| Serving plane | Feature store (may be its own sub-plane) | Retrieve online features per request | read-scoped by tenant |
| CI / release plane | Registry plane | Attach attestations, sign, promote | write attestation, sign, tag |
| Human operator | All planes via bastion / gateway | Debugging, deployment | strong auth + audit |

Every other cross-plane connection should default-deny at
NetworkPolicy and be rejected at the mesh AuthorizationPolicy.

---

## The zero-trust reference architecture for the three planes

The rest of the module lands the following architecture. Chapter 07
of this section — the summary — brings it all together, but it is
useful to see the target now.

```
                         ┌──────────────────────┐
                         │  Identity Provider    │
                         │  (OIDC / SPIRE)       │
                         └───────────┬──────────┘
                                     │ SVIDs / OIDC tokens
      ┌──────────────────────────────┼──────────────────────────────┐
      │                              │                              │
      │  ┌────────────────────────┐  │  ┌────────────────────────┐  │
      │  │   Policy Decision      │  │  │   Policy Info Points   │  │
      │  │   Points (PDP)         │◄─┼──┤   (PIP)                │  │
      │  │   OPA / Gatekeeper /   │  │  │   Registry, Rekor,     │  │
      │  │   Mesh RBAC / K8s API  │  │  │   ML-BOM store, CMDB   │  │
      │  └────────────┬───────────┘  │  └────────────────────────┘  │
      │               │              │                              │
      ▼               ▼              ▼                              │
 ┌─────────┐    ┌─────────┐    ┌─────────┐                          │
 │ Training │◄──►│ Registry │◄──►│ Serving │  (only signed,          │
 │  plane   │    │  plane   │    │  plane  │   attested, scan-clean, │
 │          │    │          │    │         │   ML-BOM-present art.)  │
 └────┬─────┘    └────┬─────┘    └────┬────┘                          │
      │NetworkPolicy   │NetworkPolicy   │NetworkPolicy                 │
      │+ mesh AuthZ    │+ mesh AuthZ    │+ mesh AuthZ                  │
      │                │                │                              │
      └────────────────┴────────────────┴──────────────────────────────┘
             (default-deny between planes; SPIFFE ID in every mTLS)
```

- **Every workload has an attested identity** (chapter 03).
- **Every request between planes is authenticated, authorised, and
  encrypted** (chapter 04).
- **The underlying cluster is hardened** so that compromise of a
  pod does not become compromise of the node or of the API server
  (chapter 05).
- **Every model deployment passes an admission-time gate** on
  signature, provenance, ML-BOM, and scan result (chapter 06).

---

## Zero trust vs "we already have a VPN and SSO" — the fallacy

A recurring pushback from teams new to zero trust: "we already have
a VPN and SSO on Kubeflow — is that not zero trust?" The short
answer: no.

- **A VPN is a perimeter.** Once inside, the workload has ambient
  network access. Zero trust puts the boundary at the *resource*,
  not at the network edge.
- **SSO on the tenant UI is not workload-to-workload authn.** SSO
  authenticates the human operator to the UI; it does not
  authenticate the serving pod to the registry, and it does not
  authenticate the training pod to the feature store. Workload
  identity (chapter 03) is a distinct primitive.
- **RBAC on the human-facing API is not enough.** RBAC on the
  Kubernetes API is a separate policy surface from the mesh
  authorisation policy and from the admission-time policy. Zero
  trust needs all three, layered.

If the answer to "how does workload A prove its identity to
workload B" is "they are on the same VPN", the architecture is not
zero trust regardless of the marketing.

---

## What this module does not do

- **Author the identity provider or SPIRE control plane at
  production depth.** The chapters describe the SPIRE reference
  deployment (server + agents), attestation selectors, and the
  registration API. Running a production SPIRE with HA, backup,
  federation between clusters, and rotation is a full Ops project
  described in the SPIRE production runbook — this module gets you
  to the deploy-and-verify state, not to a production-multi-region
  posture.
- **Author the mesh from scratch.** The chapters use Istio /
  Linkerd primitives (AuthorizationPolicy, PeerAuthentication)
  with example YAML, but the operational choice between meshes and
  the per-mesh install / upgrade runbooks are out of scope.
- **Replace mod-105 (secrets) or mod-110 (supply chain).** The
  admission-time gate consumes signatures from cosign and
  provenance from SLSA / in-toto — the *keys* used to produce
  those signatures are managed in mod-105, and the *supply-chain
  pipeline* that generates the attestations is authored in
  mod-110. This module is the enforcement surface both feed.
- **Replace mod-111 (SecOps).** The mesh and admission decisions
  emit audit logs that mod-111 consumes as detection input.
  Sigma / KQL / SPL rule authoring against those logs is in
  mod-111.

---

## What "good" looks like versus what "bad" looks like

**Bad — perimeter-shaped.**

> "Access to the ML cluster is controlled by SSO and VPN. Once on
> the VPN, our services talk to each other over plaintext HTTP on
> the pod network. RBAC on the Kubernetes API is default-permit
> for users in the `mlops` group; the training pods use a shared
> service account with cluster-wide read access. New model
> versions are pushed to the registry by the training pipeline
> and pulled by the serving pods; there is no admission check on
> the model artifact at deploy time."

**Good — zero-trust shaped.**

> "Every workload authenticates using a SPIFFE SVID minted from a
> node + pod + image attestation. Cross-plane traffic is
> default-deny at NetworkPolicy and at Istio AuthorizationPolicy;
> only the enumerated flows in the reference architecture are
> permitted. The training-plane service account has no ambient
> cloud IAM; per-job credentials are minted via SPIRE-issued
> JWT-SVID exchange to short-lived cloud tokens with per-dataset
> scope. Every model deployment passes a Gatekeeper policy that
> verifies (1) a cosign signature attached to the OCI artifact,
> (2) an SLSA v1.0 provenance attestation whose builder identity
> matches an allow-list, (3) a CycloneDX ML-BOM at the required
> completeness level, (4) an artifact scanner result within a
> freshness window. Cluster nodes are hardened to the CIS
> Kubernetes Benchmark v1.9 baseline profile; Pod Security
> Admission is enforced at `restricted` on all non-system
> namespaces."

The rest of the module walks the second bullet, control by
control.

---

## The mistakes this chapter is trying to prevent

- **Treating zero trust as a product.** Zero trust is an
  architecture with named primitives (PDP, PEP, PIP). Vendors sell
  components that fit those primitives; no product is "zero trust"
  by itself.
- **Skipping workload identity because "we already have RBAC".**
  Kubernetes RBAC authenticates the *service account*, not the
  attested workload posture (image, node, namespace, integrity).
  SPIFFE workload identity is what closes the "who is calling me,
  really?" question.
- **Assuming the mesh handles L7 authz automatically.** Meshes
  give you the *primitives* (PeerAuthentication,
  AuthorizationPolicy). You still have to author the deny-by-
  default policy and the specific allow rules.
- **Deferring admission-time checks to CI.** CI-time checks are
  necessary but not sufficient. The admission check is what
  refuses a registry entry that was pushed *after* CI (via
  registry-write compromise) or a stale artifact whose scan window
  has expired.
- **Hardening the cluster and stopping there.** CIS-hardened
  cluster + no mesh authz + no admission policy is still a wide-
  open lateral surface. Layered controls; skipping any layer
  invalidates the model.

---

## Summary

- Zero Trust Architecture is defined by NIST SP 800-207 as a per-
  session, dynamic-policy-driven, identity- and posture-aware
  authorisation architecture. It replaces perimeter trust with
  per-resource enforcement.
- The primitives are PEP (enforcer), PDP (decider composed of PE
  and PA), and PIP (context sources). Every enforcement point in
  the ML platform maps to one of these.
- ML platforms present three unusual pressures: training pods have
  broad blast radius, the registry-to-serving hop is a supply-
  chain gate, and cross-plane traffic must be segmented despite
  planes sharing the cluster.
- The three-plane model (training, registry, serving) is the
  segmentation scaffold used by the rest of this module.
- The five deliverables the module produces map to the primitives:
  a zero-trust gap assessment, a SPIFFE workload-identity plan,
  a NetworkPolicy + mesh AuthorizationPolicy set, a CIS + PSA
  hardening state, and an admission-time Gatekeeper policy set.
- This module *enforces* the mitigations that mod-102 named. It
  does not replace mod-105 (secrets), mod-110 (supply chain), or
  mod-111 (SecOps) — it is the enforcement surface those modules
  feed.
