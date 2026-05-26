# Module 02 — Zero-Trust Architecture for ML Systems

> **Note on AI-assisted content.** These lecture notes were drafted
> with AI assistance and are under ongoing human review. Verify
> against primary sources (NIST SP 800-207, BeyondCorp papers,
> SPIFFE specification, vendor docs) before quoting in production
> work. See [`resources.md`](./resources.md) for primary sources.

---

## 1. What "zero-trust" actually means

The phrase "zero-trust" is overloaded enough that anyone using it
unqualified is probably saying something misleading. The phrase
came from Forrester in 2010, was implemented at scale by Google
(BeyondCorp, 2014–2017), and was formalized by NIST in **SP
800-207** (2020). Read the NIST publication once — it's the most
careful definition publicly available.

### 1.1 The five tenets (compressed from NIST SP 800-207)

A zero-trust architecture observes five core properties:

1. **Every resource access is authenticated, authorized, and
   encrypted, regardless of where the request originates.**
   "Inside the VPN" is not a privileged position. "Same cluster"
   is not a privileged position. "Same namespace" is not a
   privileged position.

2. **Access decisions are made per-request, not per-session.**
   A token issued an hour ago is not authorization for a request
   right now if the conditions have changed. Token lifetimes are
   short; reauthentication is frequent.

3. **Resource access is granted on the **least privilege**
   principle**, scoped to the specific resource and operation
   needed for the task in front of the requestor.

4. **All assets are inventoried, identifiable, and protected**;
   security posture is observable for every asset.

5. **The integrity and security posture of all owned and
   associated assets is monitored and used to inform access
   decisions.** A pod failing runtime-security checks should
   lose access privileges, not just generate an alert.

### 1.2 What zero-trust is *not*

| Claim | Why it's wrong |
|---|---|
| "We have an SSO, so we have zero-trust." | SSO covers user authentication. Zero-trust covers workloads, networks, and per-request decisions too. |
| "We use mTLS, so we have zero-trust." | mTLS is one mechanism; zero-trust is an architecture. mTLS without identity-based authorization is just encrypted traffic. |
| "We have a VPN, so the network is secure." | The VPN is precisely the privileged-position the perimeter model relies on. Zero-trust rejects this assumption. |
| "We have a service mesh, so we have zero-trust." | Same as mTLS. The mesh is a substrate, not the architecture. |
| "We're zero-trust because we have OAuth." | OAuth is an authorization protocol. It is part of a zero-trust implementation, not equivalent to one. |

The pattern: zero-trust is **a set of assumptions** about how
access decisions are made, instantiated through a stack of
specific technologies. Pointing at any single technology and
declaring zero-trust is a category error.

---

## 2. Why the perimeter model fails for ML systems

The traditional "castle-and-moat" model assumes:

- A trusted internal network exists.
- Users authenticate at the perimeter, then move freely inside.
- Workloads inside the perimeter implicitly trust each other.

Every step of this assumption breaks worse for ML systems than
for traditional web apps:

### 2.1 Trusted internal network — broken

ML systems have **larger lateral-movement risk** because:

- Training jobs read from many data sources (warehouses, feature
  stores, object stores). A compromise of one training job is a
  compromise of read access to many tenants' data.
- Model registries are accessed by training, serving, and
  governance workloads simultaneously. A perimeter breach grants
  access to all of them.
- Feature stores are read by both training and serving; a
  perimeter breach lets an attacker read what every model is
  conditioned on.

### 2.2 Authenticate-at-perimeter — broken

ML APIs typically authenticate paying customers, including
attackers. The threats the API faces (ML01 evasion, ML05
extraction) don't require breaking authentication — they require
authenticated query access.

### 2.3 Workloads trust each other — broken

ML workloads are heterogeneous: training jobs from one team, fine-
tuning jobs from another, serving pods from a third, batch
inference from a fourth. A compromised training job in team A
*should not* be able to call team B's feature store or model
registry. Under the perimeter model, it can; under zero-trust, it
can't.

### 2.4 The asymmetry

For a traditional web app, the perimeter failure mode is "an
attacker got inside and now can see internal services." Bad. For
an ML system, the perimeter failure mode is "an attacker got
inside and now can poison training data, extract models, and
inspect prediction patterns across tenants." Worse — and harder
to detect, because the lateral movement looks like normal
workload behavior.

---

## 3. Identity-first design

The single most important architectural shift in zero-trust:

> **Identity is the new perimeter.**

Every access decision is keyed on the *identity* of the
requester — not their IP, not their network segment, not their
cluster.

### 3.1 Workload identity, not node identity

A pod running on a node should not inherit the node's identity.
Many incidents originate from this mistake — a single compromised
pod gets the node's IAM role, which has access to everything any
pod on the node needs.

**Workload identity** (sometimes "service identity") binds an
identity to the specific workload (pod + service account + image
+ namespace), attested at workload startup.

### 3.2 SPIFFE / SPIRE

**SPIFFE** (Secure Production Identity Framework For Everyone) is
a CNCF specification for workload identity. **SPIRE** is the
reference implementation.

The core artifact is a **SVID** (SPIFFE Verifiable Identity
Document):

- A short-lived X.509 certificate or JWT.
- Bound to a SPIFFE ID of the form
  `spiffe://<trust-domain>/<workload-path>`.
- Issued by SPIRE based on **attestation** of the workload
  (node selectors, kernel info, pod labels, container image
  digest).

A SPIFFE ID looks like:
`spiffe://example.com/ns/recs/sa/training-job/version/v17`

This identity is the basis for:
- mTLS (the SVID is the cert).
- Authorization decisions ("which workloads can read this
  feature?").
- Audit logging (every action is keyed on workload identity).

### 3.3 Cloud-native equivalents

If you're in AWS, GCP, or Azure and not running SPIRE, the
equivalents are:

- **AWS IAM Roles for Service Accounts (IRSA)** — IAM roles bound
  to a Kubernetes ServiceAccount via OIDC trust.
- **GKE Workload Identity** — GCP service accounts bound to k8s
  ServiceAccounts.
- **Azure AD Workload Identity** — same pattern in Azure.

These are not strictly SPIFFE-compliant but they implement the
*principle* of workload identity. SPIFFE adds: portability
across clouds, a uniform identity format, and trust-domain
federation.

### 3.4 Short-lived credentials

Long-lived credentials (static API keys, long-TTL JWTs, embedded
secrets) are the enemy of zero-trust. They:

- Don't degrade gracefully — a leaked credential is valid
  until revoked.
- Don't tie to workload identity — they're shareable.
- Don't carry attestation — you can't verify *which* workload
  used the credential.

Replace with:
- **SPIRE-issued SVIDs**, refreshed every ~hour.
- **Vault dynamic secrets**, where applicable (Module 05 deep
  dive).
- **OIDC tokens** for human access, short-lived (~hour).

### 3.5 Identity binding for ML-specific assets

Concretely, in an ML system, you want:

- The training job to have an identity that can read the
  training-data warehouse and write to its own artifact
  location, and *nothing else*.
- The serving pod to have an identity that can read the model
  artifact for the version it's serving and write metrics, and
  *nothing else*.
- The governance pod to have an identity that can read the
  model registry, write audit-log entries, and *nothing else*.

The same model artifact accessed by training (write), serving
(read), and governance (verify) should be accessed under
**three different identities**, each scoped to its specific
operation.

---

## 4. Microsegmentation

Zero-trust assumes lateral movement *will* happen and limits
the blast radius. Microsegmentation is how.

### 4.1 Three layers of segmentation

Modern microsegmentation operates at three layers:

1. **L3/L4 network policy** — what can talk to what at the IP/port
   level. Implemented by Kubernetes NetworkPolicy + CNI (Cilium,
   Calico).
2. **mTLS + AuthorizationPolicy** — what *workload identity* can
   call what *workload identity* at what *RPC method*.
   Implemented by Istio AuthorizationPolicy or Cilium L7 policy.
3. **Application-layer authorization** — fine-grained per-request
   decisions inside the application based on tenant, resource,
   operation. Implemented in code or via OPA/policy-as-code
   (Module 09).

A defensible design uses **all three layers**. They catch
different threats and fail in different ways.

### 4.2 L3/L4: Kubernetes NetworkPolicy

NetworkPolicy in Kubernetes is **default-allow** unless you
explicitly deny. The canonical zero-trust posture is:

1. A **default-deny** policy in every namespace that blocks all
   ingress and egress.
2. Specific **allow** policies that name the source/destination
   workloads.

```yaml
# default-deny in namespace 'recs'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: recs
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
```

Then layer in specific allows:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: serving-can-call-features
  namespace: recs
spec:
  podSelector:
    matchLabels:
      app: model-serving
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              name: feature-store
          podSelector:
            matchLabels:
              app: feature-api
      ports:
        - protocol: TCP
          port: 8080
```

**The mistakes that defeat NetworkPolicy:**
- Forgetting the default-deny (the allow rules are then redundant).
- Allowing entire namespaces instead of specific workloads.
- Not blocking DNS (a common egress channel for exfiltration).
- Mixing CIDR-based allows with label-based allows in confusing
  ways.

### 4.3 Service mesh: mTLS + AuthorizationPolicy

NetworkPolicy doesn't know *what RPC method* is being called.
For that you need a service mesh.

**Istio** (the most common choice in production) gives you:

- **PeerAuthentication: STRICT** — every workload-to-workload
  call must use mTLS.
- **AuthorizationPolicy** — allow/deny decisions keyed on
  workload identity (the SPIFFE-style cert SAN) and HTTP/gRPC
  method.

```yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: features-callable-by-serving-only
  namespace: feature-store
spec:
  selector:
    matchLabels:
      app: feature-api
  action: ALLOW
  rules:
    - from:
        - source:
            principals:
              - "cluster.local/ns/recs/sa/model-serving"
      to:
        - operation:
            methods: ["GET"]
            paths: ["/features/v1/*"]
```

This says: only the `model-serving` service account in the
`recs` namespace can call `GET /features/v1/*` on `feature-api`.
Everything else, denied.

**Cilium** with L7 policy is the alternative. It's lighter-weight
(no sidecar), uses eBPF, and integrates Kubernetes-native. Its
policy expressiveness is improving but lags Istio's in some
areas. For learning purposes, the Module 02 / Project 1
reference uses Istio.

### 4.4 Application-layer authorization

The mesh authorizes *which identity can call which method*. It
doesn't authorize *which tenant's data this request is asking
for*. That's an application-layer concern, and it's the most
common gap.

Example failure: A multi-tenant feature store exposes
`GET /features/v1/customer/{id}`. The mesh allows the
`model-serving` identity to call this method. But there's
nothing stopping a request from tenant A's pod from passing
`{id}` = "tenant-B-customer-42". The mesh's policy is
satisfied; the application's logic is what enforces tenant
isolation, and it doesn't.

The fix: tenant-aware authorization inside the application
(or via an OPA sidecar — Module 09). Every per-request
authorization check should verify "is the *caller* allowed to
access *this resource* on behalf of *this tenant*?"

### 4.5 ML-specific microsegmentation patterns

The patterns that matter most for ML systems:

- **Training → only training-data sources + own artifact path.**
  Not the production feature store, not other models' artifacts.
- **Serving → only its own model artifact + the feature store
  (read-only for its tenants).** Not the training-data warehouse,
  not other models' artifacts.
- **Governance → read-only on model registry + write-only to
  audit log.** Not the feature store, not the training-data
  warehouse.
- **Notebook / experimentation → severely limited.** Most
  exfiltration scenarios start in a notebook with broad access.

---

## 5. Defense in depth applied to a serving stack

Walk through a serving stack with all the zero-trust controls in
place, layer by layer:

### 5.1 The example

A serving pod returning fraud-detection predictions for a
financial-services customer.

**Customer request** arrives at an external load balancer,
authenticated with mTLS to the customer's CA. The LB terminates
external mTLS and forwards to the gateway.

### 5.2 Gateway

- **Authenticates** the customer (OIDC + mTLS-bound certificate).
- **Authorizes** based on the customer's tenant scope (rate
  limit, allowed model versions, allowed feature classes).
- **Tags** the request with `tenant=<id>` and `request-id`.
- **Forwards** over mTLS with the gateway's workload identity to
  the serving service.

### 5.3 Network policy (L3/L4)

- Gateway → serving: allow on port 8080.
- Serving → feature store: allow on port 8080.
- Serving → model artifact bucket: allow on port 443.
- All other egress / ingress: deny.

### 5.4 Service mesh (mTLS + AuthorizationPolicy)

- **PeerAuthentication: STRICT** mesh-wide.
- **AuthorizationPolicy** at the serving service: only the
  gateway's identity can call `POST /v1/predict`.
- **AuthorizationPolicy** at the feature store: only the
  serving service's identity can call `GET /features/v1/*`.

### 5.5 Application authorization (inside serving)

- Serving extracts `tenant` from the request headers (set by
  the gateway, trusted because the request came over mTLS from
  the gateway's identity).
- Calls feature store with `?tenant=<id>` query parameter.
- Feature store independently verifies (via its own
  application logic or OPA sidecar) that the caller is allowed
  to read tenant `<id>`'s features.
- Loads its model artifact and runs inference.
- Returns the prediction with `tenant` and `request-id` in the
  response for audit.

### 5.6 Runtime guarantees

- The serving pod's workload identity (SPIFFE SVID) is bound to
  the specific deployment + namespace + service account.
- Compromise of the pod doesn't grant access to other tenants'
  features (application-layer enforcement) or to the
  training-data warehouse (network policy).
- Audit log entries are signed by the gateway and the serving
  pod, both using their workload identities.

### 5.7 Where the design admits weakness

A defensible design acknowledges its weaknesses:

- The application-layer authorization is a single point of
  failure for tenant isolation. A bug there breaks isolation.
- Workload identity attestation depends on node integrity. A
  compromised node can impersonate workloads.
- The audit log itself must be tamper-evident (Module 07).

Calling out the weaknesses is *part of* the design, not an
omission from it.

---

## 6. Identity federation across boundaries

Real-world deployments cross trust boundaries:

- Multiple Kubernetes clusters.
- Multiple cloud accounts.
- On-prem to cloud.
- Partner orgs.

SPIFFE supports **trust domain federation**: workloads in
trust domain A can verify workloads in trust domain B, given a
federation relationship.

### 6.1 When federation matters

- Multi-cluster: training in one cluster, serving in another;
  they need to authenticate each other.
- Multi-cloud: AWS and GCP workloads call each other across the
  cloud boundary.
- Partner integration: your platform integrates with a partner's
  feature store; both sides use workload identity.

### 6.2 When federation doesn't matter

Single-cluster, single-cloud deployments don't need federation.
Don't add complexity prematurely.

---

## 7. Operational realities

Zero-trust is operationally expensive. A defensible design
acknowledges the cost:

### 7.1 Bootstrapping problem

SPIRE itself needs to be bootstrapped before any workload can
get an identity. SPIRE Server bootstraps via either a trust
bundle baked into nodes or a manual one-time process. Get this
wrong and the platform won't come up after a restart.

### 7.2 Identity propagation through pipelines

A workload's identity propagates one hop. For chained workloads
(API gateway → service A → service B → service C), each hop has
its own identity. The original *user* identity is propagated
separately, usually as a JWT in headers, verified at each hop.

This is called **on-behalf-of** authorization, and getting it
right is harder than the simple workload-identity case.

### 7.3 Audit log volume

Per-request authorization decisions produce per-request audit
entries. Volume scales with traffic. The audit retention,
query, and storage costs are nontrivial. Module 07's tamper-
evident audit log addresses *integrity*; volume is a separate
problem.

### 7.4 Operational rollback

If the AuthorizationPolicy is wrong, all traffic fails — a
production incident. Roll-out of new policies needs a tested
rollback procedure. The Module 09 policy-as-code pattern
addresses this with policy-in-monitor-mode-first.

### 7.5 Cost of mTLS

mTLS has nontrivial CPU overhead (5–15% per workload depending
on traffic shape). For latency-critical paths, this matters.
Cilium's eBPF mTLS reduces this; Istio's sidecar adds more.

---

## 8. ML-specific zero-trust considerations

Beyond the generic patterns, ML systems require:

### 8.1 Identity-scoped model access

The model artifact in S3 / object storage should be read-only
to the serving identity of the model version that was promoted.
Other model versions' identities cannot read it. This means:

- `serving-v17` identity can read `s3://models/v17/...`.
- `serving-v18` identity can read `s3://models/v18/...`.
- Neither can read the other.

This catches the case where a buggy or compromised serving pod
tries to swap to a different model version mid-flight.

### 8.2 Per-tenant feature access

The serving identity calls the feature store. The feature store
must independently verify which *tenant's* features are being
asked for. The identity is "serving"; the authorization is
"serving may read features for tenants in {A, B, C}, not D, E,
F."

### 8.3 Training-job identity isolation

Each training job should have an identity scoped to *that
specific job*. Not the team's identity, not the platform's
identity. This means:

- The job can read only the specific training-data slice it's
  permitted.
- The job can write only to its own artifact path.
- The job's identity expires when the job completes — no
  lingering credentials.

### 8.4 Notebook / experimentation environments

The hardest zero-trust environment is "a data scientist's
Jupyter notebook." It needs read access to lots of data, write
access to lots of artifacts, and the user wants to install
arbitrary packages. The realistic posture is:

- A separate cluster / namespace with stronger network
  isolation.
- Time-bounded identities (e.g., expires at end of working
  day).
- No production-data access; use anonymized / sampled data
  copies.
- Egress monitoring (because exfiltration via `pip install`
  is real).

---

## 9. What zero-trust deliberately doesn't solve

Calibration: zero-trust is one architectural pattern. It is
not:

- **A defense against authenticated adversaries.** An attacker
  who has bought a legitimate API subscription and is mining
  the model has a valid identity. Zero-trust doesn't help; rate
  limits and query-pattern detection do (Modules 06, 11).
- **A defense against poisoning.** Identity controls don't
  catch a poisoned training dataset that arrived through valid
  channels. Data provenance controls do (Modules 07, 10).
- **A defense against adversarial inputs.** ML01 evasion attacks
  come from authenticated clients. Adversarial training and
  input validation address them (Module 06).
- **A substitute for compliance.** Zero-trust improves your
  posture but doesn't map directly to regulatory controls. The
  mapping is part of compliance work (Module 07).

A team claiming "we're zero-trust, therefore we're secure" is
overclaiming. Zero-trust is a foundation; the rest of the track
fills in what zero-trust alone doesn't address.

---

## 10. What you should be able to do after this module

A working checklist:

- [ ] Articulate the five NIST SP 800-207 zero-trust tenets and
      give a concrete example of each.
- [ ] Identify three places where the perimeter model fails
      worse for ML systems than for traditional web apps.
- [ ] Draw a workload-identity design for a 3-tier ML serving
      stack using SPIFFE-style identity.
- [ ] Author a Kubernetes NetworkPolicy with default-deny + a
      specific allow.
- [ ] Author an Istio AuthorizationPolicy keyed on workload
      identity.
- [ ] Explain why mesh-layer authorization is insufficient for
      multi-tenant feature access (and what fixes it).
- [ ] Name three threats zero-trust doesn't address, and which
      modules of this track address each.

---

## 11. Suggested reading order outside this module

After this module:

1. Read the `SOLUTION.md` for [project-1-zero-trust](https://github.com/ai-infra-curriculum/ai-infra-security-solutions/blob/main/projects/project-1-zero-trust/SOLUTION.md)
   — it makes more sense now.
2. Skim the **NIST SP 800-207** document; you don't have to read
   it cover-to-cover, but knowing what it says is useful.
3. Skim the **BeyondCorp** papers — they're short and historically
   important.
4. Move to **Module 03: Cryptography for ML**.

---

## Appendix A — Quick reference glossary

- **AuthorizationPolicy**: Istio CR that defines allow/deny rules
  keyed on workload identity, HTTP method, and path.
- **BeyondCorp**: Google's published implementation of a
  zero-trust enterprise model. The papers (2014–2017) are the
  best public reference.
- **CNI**: Container Network Interface. The plugin layer in
  Kubernetes that implements networking (Cilium, Calico,
  Weave).
- **mTLS**: Mutual TLS. Both client and server authenticate to
  each other with certificates.
- **NetworkPolicy**: Kubernetes resource for declaring L3/L4
  network rules. CNI plugin enforces them.
- **PeerAuthentication**: Istio CR that controls mTLS mode
  (DISABLE / PERMISSIVE / STRICT) per namespace or workload.
- **SPIFFE**: Secure Production Identity Framework For Everyone.
  A spec.
- **SPIRE**: Reference implementation of SPIFFE. Issues SVIDs to
  attested workloads.
- **SVID**: SPIFFE Verifiable Identity Document. Short-lived
  cert or JWT.
- **Trust domain**: A SPIFFE concept; a SPIFFE ID belongs to a
  trust domain (`spiffe://trust-domain.example/...`).
- **Workload identity**: An identity bound to a specific
  workload, not a node or user.

---

## Appendix B — Common misconceptions

| Misconception | Reality |
|---|---|
| "We have mTLS, so we have zero-trust." | mTLS is necessary, not sufficient. Without identity-based authorization, mTLS is encrypted traffic between mutually unknown parties. |
| "Network policy alone is enough." | L3/L4 policy doesn't know about RPC methods or tenant context. You need at least two layers. |
| "Workload identity is just a cert." | Workload identity is a cert *plus* attestation that the cert was issued to the claimed workload. Without attestation, anyone with the cert is anyone. |
| "We default-allow because deny-by-default breaks things." | Default-allow breaks the model. If deny-by-default breaks things, the allow rules are wrong, not the principle. |
| "Zero-trust eliminates the need for compliance." | It improves the controls; compliance evidence still needs to be produced. |
| "Zero-trust slows everything down." | Done well, the overhead is single-digit percent. The slowness usually comes from policy mistakes, not the architecture. |

---

*Continue to the [exercises](./exercises/) when you are ready to
apply this material to your Module 01 system. The artifacts you
produce here will be reused in Modules 04, 05, 08, 09, and 11.*
