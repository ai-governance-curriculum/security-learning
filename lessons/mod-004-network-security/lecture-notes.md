# Module 04 — Network Security for ML Systems

> **Note on AI-assisted content.** Drafted with AI assistance and
> under human review. Verify CNI / service-mesh / gateway specifics
> against current upstream documentation — the field moves quickly
> (Cilium L7, Istio Ambient, Gateway API). See
> [`resources.md`](./resources.md).

---

## 1. Why ML networks need their own treatment

A generic web application's network surface has predictable shape:
ingress, a few services, egress to a database and maybe to an
external API. An ML system's network surface is different in three
ways that matter:

1. **Many trust boundaries, dense fan-out.** Training jobs talk to
   data warehouses, feature stores, model registries, artifact
   stores, monitoring, and the secret manager. Serving talks to
   feature stores, model artifact stores, monitoring, and the
   tenant-facing API. Each line is a trust boundary.
2. **Heterogeneous workload identities.** Multiple teams' training
   jobs, multiple serving stacks, governance jobs, notebooks —
   all with different access patterns. The "everything inside the
   cluster is trusted" model breaks faster than for a typical
   web app.
3. **Asymmetric inference cost.** A single request from an
   attacker can cost cents to dollars of GPU time. Rate limits
   matter more for ML APIs than for typical web APIs, where the
   cost of a single request is fractions of a cent.

The controls in this module are the same controls a security
team would apply to any system — but the *importance ranking*
shifts.

---

## 2. Kubernetes NetworkPolicy at depth

Module 02 introduced NetworkPolicy. This section goes beyond
"default-deny + specific allows" to the operational realities.

### 2.1 The semantics that trip people up

- **NetworkPolicy is additive.** Multiple policies for a pod
  *union* their allow rules. If policy A allows port 8080 from
  namespace X and policy B allows port 8080 from namespace Y,
  both X and Y can reach the pod.
- **There is no "deny" rule.** NetworkPolicy is an allow-list.
  "Default deny" is just "an empty allow-list applied with the
  `default-deny-all` selector pattern" — there is no `deny`
  primitive in standard NetworkPolicy.
- **NetworkPolicy is CNI-enforced.** If your CNI doesn't enforce
  NetworkPolicy (e.g., some older CNIs, or Flannel without
  Calico for policy), the resources exist but do nothing. This
  is **the most common silent failure**: the policy is "applied"
  and rejecting nothing.
- **NetworkPolicy doesn't apply to traffic the kubelet itself
  injects** (e.g., readiness probes). Document this for on-call.
- **ipBlock CIDRs are evaluated as the *source* IP from the pod's
  perspective.** Egress to "1.2.3.4" means "the pod can send to
  destination IP 1.2.3.4." For ingress, it's the *source* IP of
  the inbound traffic, which after kube-proxy / Cilium NAT may
  not be what you expect.

### 2.2 Egress: the part most teams skip

Most teams write ingress NetworkPolicies and stop. The egress
side is where data exfiltration happens, and it's harder because:

- **DNS egress** must be allowed for almost any workload to
  function. An attacker can exfiltrate over DNS (encoding data
  in subdomain queries). Allow DNS to your cluster DNS only,
  not to arbitrary external resolvers.
- **External hostnames are not stable IPs.** "Allow access to
  `api.openai.com`" cannot be done in standard NetworkPolicy
  (which is L3/L4 only). For DNS-based egress restriction, you
  need:
  - Cilium with FQDN egress policies (L7-aware DNS).
  - An egress gateway that filters by hostname.
  - A proxy (Envoy, Squid) the workload talks through.
- **Cloud metadata endpoint (`169.254.169.254`).** Block this for
  every workload that doesn't need it. SSRF attacks exfiltrate
  IAM credentials via this endpoint.

A defensible egress policy for an ML serving pod:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: serving-egress
  namespace: recs
spec:
  podSelector:
    matchLabels:
      app: model-serving
  policyTypes:
    - Egress
  egress:
    # DNS to cluster DNS only
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
    # Feature store
    - to:
        - namespaceSelector:
            matchLabels:
              name: features
          podSelector:
            matchLabels:
              app: feature-api
      ports:
        - protocol: TCP
          port: 8080
    # Model artifact store (S3 via VPC endpoint, not internet)
    - to:
        - ipBlock:
            cidr: 10.100.0.0/16  # VPC endpoint CIDR
      ports:
        - protocol: TCP
          port: 443
    # Metrics export to monitoring
    - to:
        - namespaceSelector:
            matchLabels:
              name: monitoring
          podSelector:
            matchLabels:
              app: prometheus
      ports:
        - protocol: TCP
          port: 9090
  # Note: cloud metadata endpoint 169.254.169.254 is NOT in the
  # allow list. Egress to it is denied.
```

The key property: this pod cannot exfiltrate over DNS to an
external resolver, cannot reach the cloud metadata endpoint,
cannot reach an arbitrary internet target. Tightly bounded.

### 2.3 Ingress: the obvious-but-incomplete part

Ingress policies are easier to write but often too permissive:

- **Namespace-based selectors are too broad.** "Allow from
  namespace `recs`" includes every pod in `recs`. Use **pod
  selectors** with explicit labels: "from pods with
  `app=gateway`."
- **Don't trust labels you don't control.** A pod selector on
  `app=gateway` matches any pod with that label. If anyone in
  the namespace can create pods, anyone can claim the label.
  This is why workload identity (mod-002) is the next layer up —
  it's harder to spoof.

### 2.4 NetworkPolicy testing

Treat NetworkPolicies as code. Tools:

- **kubectl-np-viewer** / **policy-tester**: visualization and
  unit-test tools for NetworkPolicies.
- **Calico Policy Recommender** / **Cilium Network Policy
  Editor**: GUI-based authoring + simulation.
- Most importantly: **integration tests** in CI. Spin up a kind
  cluster, apply the policies, run a test pod that tries the
  denied paths and confirms denial.

---

## 3. CNI choice and security implications

Your CNI plugin enforces NetworkPolicy. Different CNIs have
different capabilities.

### 3.1 What each major CNI gives you

| CNI | NetworkPolicy enforcement | L7 awareness | Notes |
|---|---|---|---|
| **Cilium** | Yes (eBPF) | Yes (L7 HTTP, gRPC, DNS) | Most capable for ML use cases. eBPF datapath. |
| **Calico** | Yes | Some via Calico Enterprise | Standard NetworkPolicy is L3/L4 only in OSS. |
| **Antrea** | Yes | Some L7 in Antrea+ | OVS-based. Used in VMware environments. |
| **Flannel** | No (needs Calico for policy) | No | Use Flannel for networking, Calico for policy if combining. |
| **Weave Net** | Yes | No | Less actively developed. |
| **Cloud-provider native** (VPC CNI, GKE Dataplane V2) | Varies | Varies | GKE Dataplane V2 uses Cilium. AWS VPC CNI does not enforce NetworkPolicy without an add-on. |

For ML workloads, the practical winner is **Cilium** because:

- L7 awareness (filter HTTP methods, gRPC services, DNS names).
- eBPF observability (Hubble) for security telemetry.
- FQDN egress (the only way to do hostname-based egress in
  standard form).
- ClusterMesh for multi-cluster (relevant for federated ML).

The trade-off is operational complexity. Cilium has more moving
parts than Calico. For a small team, Calico is operationally
cheaper if you don't need L7.

### 3.2 The default-CNI trap

Many managed Kubernetes distributions ship with a CNI that
**doesn't enforce NetworkPolicy at all**:

- EKS with **VPC CNI** (the default) — no NetworkPolicy
  enforcement without enabling the bundled OSS Calico add-on or
  switching to Cilium.
- GKE — Dataplane V2 (Cilium-based) is opt-in for older clusters.
- AKS — Calico, Azure CNI, or "BYO CNI". Azure CNI without
  policy add-on doesn't enforce.

**Audit your CNI for NetworkPolicy enforcement** before believing
that your policies do anything. The bug is silent.

### 3.3 eBPF and Hubble (Cilium-specific)

Cilium's Hubble surfaces flow logs and policy verdicts via:

- **CLI / UI**: `hubble observe` shows real-time flows.
- **Prometheus metrics**: per-namespace flow rates, drops,
  policy verdicts.
- **OpenTelemetry export**: flows as spans for correlation with
  application traces.

For security: a sudden spike in `policy: denied` verdicts on a
specific namespace is a high-signal event. Module 11's detections
key off this surface.

---

## 4. Service mesh security at depth

Module 02 introduced Istio AuthorizationPolicy. This section
covers the operational layer.

### 4.1 The four Istio CRs that matter for security

| CR | What it controls |
|---|---|
| **PeerAuthentication** | Whether mTLS is enforced on connections (DISABLE / PERMISSIVE / STRICT) |
| **DestinationRule** | TLS configuration for outbound traffic |
| **AuthorizationPolicy** | Who can call what (RPC-level allow/deny) |
| **RequestAuthentication** | JWT validation on incoming requests |

A defensible Istio security baseline:

1. **Mesh-wide PeerAuthentication: STRICT.**
2. **Namespace-level AuthorizationPolicy with `action: ALLOW`** at
   each namespace boundary. Without any matching policy, Istio's
   default is deny.
3. **RequestAuthentication** at the gateway for end-user JWT
   validation.
4. **DestinationRule** to enforce outbound mTLS where needed.

### 4.2 Istio Ambient: the sidecar-less alternative

Istio Ambient (released as beta-grade in 2024+) removes the
per-pod sidecar and runs the mesh dataplane in node-level
"ztunnel" daemonsets. Implications:

- **Lower per-workload overhead** — no sidecar memory cost.
- **L4 features only at the base layer** — L7 features still
  require a per-namespace "waypoint" proxy.
- **Simpler upgrade story** — no rolling pod restarts to upgrade
  the mesh.

For ML workloads with many lightweight serving pods, Ambient's
overhead savings are nontrivial. For workloads needing L7 policy
on every call (per-tenant feature access), the waypoint proxy
adds latency comparable to a sidecar.

Choose based on your traffic shape:

- **Ambient**: many low-latency lightweight services, mostly L4
  needs.
- **Classic Istio (sidecar)**: heavy L7 policy requirements.

### 4.3 Policy composition gotchas

Istio AuthorizationPolicy composition is **not intuitive**.
Specifically:

- If **any** policy at a workload matches with `action: ALLOW`,
  the request is allowed.
- If **any** policy matches with `action: DENY`, the request is
  denied, regardless of allow policies.
- DENY policies are evaluated **before** ALLOW.

This means you can express "allow X but not Y where Y is a
subset of X" using a DENY rule. Useful for narrowing broad
allow rules without rewriting them.

### 4.4 ExternalAuthorization

Istio can delegate authorization to an external service (e.g.,
OPA, your own service). The flow:

1. Request enters Istio.
2. Istio sends an ext-authz query to the configured backend.
3. Backend returns allow/deny + headers to inject.
4. Istio enforces.

For multi-tenant ML where authorization depends on tenant
context, ExternalAuthorization is the clean answer. OPA-based
backends are the most common.

### 4.5 What service meshes *don't* solve

A list to keep your team calibrated:

- **They don't prevent application bugs.** The mesh allows
  `GET /features/v1/<id>`; the application logic still has to
  enforce that the caller is allowed to read `<id>`.
- **They don't help with data exfiltration through allowed
  channels.** If an attacker compromises a pod and that pod is
  allowed to talk to the feature store, the mesh lets the
  exfiltration through.
- **They don't replace network policy.** L3/L4 NetworkPolicy
  protects pods that *don't* have a sidecar (system pods,
  init containers, the mesh itself).

---

## 5. Ingress and gateway hardening

The edge of your network is the first thing an attacker sees.

### 5.1 The ingress layer

A typical layered ingress for an ML platform:

```
Internet
   │
   ▼
Cloud LB (AWS ALB / GCP HTTPS LB)
   │  (TLS termination optional here)
   ▼
Ingress controller (Istio Gateway / Envoy / nginx)
   │  (TLS termination, host routing, WAF)
   ▼
Edge gateway service (custom gateway pod)
   │  (API key validation, rate limiting, tenant context)
   ▼
Service mesh (mTLS, AuthorizationPolicy)
   │
   ▼
Model serving / API services
```

Each layer is a control point.

### 5.2 TLS at the edge

- TLS 1.3 only (or TLS 1.2 + 1.3 if backward compat needed).
- Cipher suites per Mozilla intermediate config.
- HSTS header with `max-age >= 31536000`.
- Certificates from a recognized CA (Let's Encrypt for public,
  or your internal CA for internal endpoints).
- Automatic renewal via cert-manager.

### 5.3 Web Application Firewall (WAF)

For external-facing APIs, a WAF in front catches:

- SQL injection attempts (rare in ML APIs but they exist).
- Cross-site scripting (XSS) in API responses if any are
  reflected.
- Generic bot patterns.

Options:

- **AWS WAF / Cloud Armor / Azure Front Door**: managed WAF at
  the cloud LB layer.
- **ModSecurity-based** (Crowdsec, OWASP CRS): self-hosted in
  nginx/Envoy.
- **Cloud-managed bot protection** (Cloudflare, Akamai): for
  customer-facing endpoints.

For ML APIs specifically, generic WAF rules are mostly
irrelevant — ML APIs accept JSON payloads with prompts or feature
vectors. The WAF *will* false-positive on legitimate inputs that
contain SQL keywords ("`SELECT * FROM users`" in a user-submitted
prompt). Tune rulesets carefully.

### 5.4 Gateway security checklist

For the edge gateway service that fronts your ML platform:

- [ ] Authenticates every request (API key, OIDC, mTLS).
- [ ] Validates request shape and size **before** the model
      service sees it.
- [ ] Adds tenant context as signed headers (so downstream
      services don't have to trust the gateway implicitly).
- [ ] Logs every request to the audit chain.
- [ ] Enforces per-tenant rate limits.
- [ ] Strips client-controlled headers that downstream services
      might trust (`X-Forwarded-User`, etc.).
- [ ] Returns generic error messages (no stack traces, no
      "user not found" vs. "wrong password" distinction).

### 5.5 Gateway API vs. Ingress

Kubernetes Gateway API is the successor to Ingress. For new
deployments:

- **Gateway API** has richer L7 expressiveness, supports
  multi-team workflows (Gateway / HTTPRoute / TLSRoute), and
  is becoming the convergence point for ingress controllers.
- **Ingress** is simpler and ubiquitous, but limited
  expressiveness.

For an ML platform building today, Gateway API is the right
default unless your ingress controller doesn't support it.

---

## 6. Egress controls

Egress is the part most platforms underinvest in.

### 6.1 Why egress matters more for ML

A compromised ML training pod has read access to:
- The training data warehouse.
- The feature store.
- The model registry.
- Possibly secret stores via IAM.

Without egress controls, an attacker can exfiltrate any of
these to an arbitrary external destination. With egress controls,
the attacker is bounded to the destinations the pod is
*supposed* to reach.

### 6.2 Layers of egress control

In increasing order of strength:

1. **Default-deny egress NetworkPolicy** (L3/L4). Allow only
   needed destinations.
2. **FQDN-based egress** (Cilium L7). Allow only specific
   hostnames.
3. **Egress gateway** (Istio egress gateway, or a dedicated
   proxy pod). All egress traffic routes through one place that
   can enforce policy.
4. **TLS inspection at egress** (rare in ML, common in
   regulated enterprises). Decrypt + inspect + re-encrypt egress
   traffic.

For ML systems, **layers 1 and 2** are the right baseline.
Layer 3 makes sense when you have non-cluster destinations
(SaaS APIs, partner services). Layer 4 is rarely worth it.

### 6.3 The cloud metadata endpoint

`169.254.169.254` is the cloud metadata service endpoint
(AWS, GCP, Azure all use this address). It returns IAM
credentials for the node's identity.

Without controls, **any pod can call this endpoint** and get
the *node's* IAM credentials — which usually have broader
permissions than the pod should have.

Block it explicitly:

```yaml
egress:
  - to:
      - ipBlock:
          cidr: 0.0.0.0/0
          except:
            - 169.254.169.254/32
            - 169.254.170.2/32  # ECS container credentials
```

Even better: use **IMDSv2 with hop-limit 1** (AWS) so containers
can't reach metadata even when NetworkPolicy is absent.

### 6.4 ML-specific egress patterns

For **training jobs**:

- Allowed: training data sources, model artifact store
  (write), monitoring, secret store.
- Denied: internet, other tenants' data, model registry (read
  blocked except for fine-tuning base models).

For **serving pods**:

- Allowed: model artifact store (read for own version), feature
  store (read for own tenants), monitoring.
- Denied: training data warehouse, other models' artifacts,
  internet.

For **governance pods**:

- Allowed: model registry (read), audit log (write), all
  serving healthchecks.
- Denied: everything else.

For **notebooks**:

- This is the hard case. Notebooks are interactive, run
  arbitrary code, and need data access for the data scientist's
  job.
- Realistic: tighter network controls than other workloads,
  egress monitoring with anomaly detection, time-bounded
  identities, no production-data access (use anonymized
  samples).
- Treat the notebook environment as **higher-risk than serving**
  in your monitoring.

---

## 7. DDoS and rate limiting

ML APIs face DDoS in two flavors: traditional flood-based and
inference-cost-amplification.

### 7.1 Traditional DDoS

Same protections as any internet-facing service:

- **Cloud-provider DDoS protection** (AWS Shield, GCP Cloud
  Armor, Cloudflare). The first line.
- **Anycast / multi-region** ingress. Distributes the load.
- **Rate limiting at the LB layer**. Cuts off volumetric attacks
  before they hit your origin.

For ML APIs, these are necessary but not sufficient.

### 7.2 Inference-cost amplification

An LLM API accepts a prompt and returns a response. The
attacker's cost is one HTTP request; your cost is GPU time
proportional to prompt + response length. **A maximally
expensive prompt can cost 1000× the cheapest prompt.**

Controls:

- **Input length caps**. Hard maximum on prompt size at the
  gateway.
- **Output length caps**. `max_tokens` enforced server-side, not
  trusted from the client.
- **Per-tenant cost ceilings** (Module 09 policy-as-code).
- **Concurrency limits per tenant** — limit the number of
  in-flight requests, not just RPS.
- **Anomaly detection on per-tenant cost** — alert on a tenant
  whose cost-per-hour suddenly multiplies (Module 11).

### 7.3 Rate limiting layers

Multiple layers, each with a purpose:

| Layer | Purpose |
|---|---|
| Cloud LB | Volumetric DDoS. Cuts off floods. |
| Edge gateway | Per-tenant RPS limits. Cuts off chatty tenants. |
| Service mesh / app | Per-tenant concurrency limits. Bounds in-flight cost. |
| Background job | Per-tenant cost-budget enforcement over time. |

A defensible ML API has all four. A single rate limit at one
layer is a single point of failure.

### 7.4 Per-tenant identity for rate limits

Rate limits must be keyed on **caller identity**, not IP. Many
ML APIs have:

- One IP per cloud customer (their NAT gateway), so per-IP
  limits punish entire customers.
- Customers spreading load across IPs (CDN, mobile), so per-IP
  limits don't catch sustained load.

Per-API-key or per-tenant rate limits, enforced by the gateway,
are the right shape. Use a stateful store (Redis) for accurate
multi-pod counting.

---

## 8. Network observability for security

You can only respond to what you can see. Network telemetry for
security has three layers:

### 8.1 Flow logs

Per-connection records: source, destination, port, protocol,
bytes transferred, duration, verdict.

Sources:
- **Cilium Hubble** (eBPF, cluster-native).
- **VPC flow logs** (cloud-provider).
- **Service mesh access logs** (Istio Envoy logs).

For security:
- Spikes in **deny verdicts** = policy probing.
- Spikes in **egress to unusual destinations** = exfiltration.
- Spikes in **unusual source→destination pairs** = lateral
  movement.

### 8.2 DNS query logs

DNS is the most common exfiltration channel because it's almost
always allowed. Logging it surfaces:

- Pods resolving suspicious domains.
- DNS-based data exfiltration (long subdomain strings).
- DGA (domain generation algorithm) patterns from compromised
  pods.

Sources:
- Cluster DNS query logs (CoreDNS).
- Cilium DNS proxy.
- Cloud-provider DNS logs.

### 8.3 Mesh telemetry

The service mesh produces per-request structured logs and
metrics. For security:

- **Request volumes per principal** — a workload identity that
  suddenly sends 10× normal traffic is interesting.
- **Authorization denials** — every denial is a probe at minimum.
- **TLS errors** — a pod that's suddenly seeing cert errors may
  be facing a MITM attempt or a config drift.

### 8.4 Correlation as the actual product

Raw flow logs are noise. The product is **correlation**: tying
network events to:

- Workload identity (the SVID / SA).
- Request audit log entry.
- Process-level events from runtime security (Module 08).
- User identity (the JWT subject from the gateway).

Building this correlation pipeline is the work; the flow logs
themselves are inputs.

---

## 9. ML-specific patterns

A walkthrough of recurring patterns in ML systems.

### 9.1 Model artifact pull

Pattern: serving pod starts, downloads model from S3 / object
store, then begins accepting traffic.

Network controls:
- Egress restricted to the artifact store's VPC endpoint, not
  to the public internet.
- Object access scoped per-version (Module 02).
- Signature verification at load (Module 03).

Anti-patterns:
- Public-read bucket.
- Artifact store reachable from the public internet from inside
  the pod.
- No signature verification (trust the bucket implicitly).

### 9.2 Training-data warehouse access

Pattern: training job reads from a data warehouse (Snowflake,
Redshift, BigQuery, an internal Hive cluster).

Network controls:
- VPC peering / Private Service Connect to the warehouse, not
  internet routing.
- Per-job IAM identity scoped to the slice of data the job
  needs.
- Audit logging on the warehouse side: which workload identity
  read what.

Anti-patterns:
- Public warehouse endpoint with credentials-only auth.
- Shared IAM role across training jobs.
- No warehouse-side audit log.

### 9.3 Feature store fan-in

Pattern: many serving pods read from one feature store. The
feature store is a high-fan-in service.

Network controls:
- Per-tenant authorization at the feature store (Module 02
  microsegmentation).
- Rate limits per caller identity.
- Network policy: only serving pods that *should* be reading
  features can reach the feature store.

Anti-patterns:
- Feature store accepts queries from any pod that can reach it
  on the network.
- No per-tenant authorization at the application layer.

### 9.4 Notebook environments

Pattern: data scientists have JupyterHub or similar with broad
access to data and the ability to run arbitrary code.

Network controls:
- Separate namespace / cluster from production workloads.
- Tighter egress controls (no internet `pip install` from
  inside the notebook; install via a curated mirror).
- Time-bounded identities (expires at end of working day).
- No production data; use anonymized samples.

Anti-patterns:
- Notebooks running in the production namespace.
- `pip install` from arbitrary external repositories from
  inside the notebook.
- Notebooks with the same IAM as production jobs.

---

## 10. What you should be able to do after this module

- [ ] Author a complete NetworkPolicy set with default-deny,
      ingress, and egress, including the cloud-metadata block
      and DNS restriction.
- [ ] Evaluate a Kubernetes distribution for NetworkPolicy
      enforcement.
- [ ] Choose between Cilium and Calico for a given environment
      and defend the choice.
- [ ] Configure Istio AuthorizationPolicy that handles
      multi-tenant authorization correctly.
- [ ] Design an edge gateway hardening plan.
- [ ] Identify the cloud-metadata endpoint risk and apply
      controls.
- [ ] Design a multi-layer rate-limit and DDoS protection
      strategy for an ML API.
- [ ] Identify the four sources of network telemetry and what
      each is good for.

---

## 11. What this module deliberately doesn't cover

- **Generic Kubernetes admin** (CNI installation, control-plane
  hardening) — assumed prerequisites.
- **VPC architecture in depth** — too cloud-specific; consult
  cloud-provider docs.
- **VPN / SDN appliance management** — out of scope.
- **Application-layer authorization patterns** — covered in
  Module 09 (Policy as Code).

---

## 12. Suggested reading order

After this:

1. Read the NetworkPolicy YAML in
   [`ai-infra-security-solutions/projects/project-1-zero-trust/`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions/tree/main/projects/project-1-zero-trust)
   — it makes more sense now.
2. Read [Cilium's documentation on NetworkPolicy](https://docs.cilium.io/en/stable/security/policy/).
3. Skim the [Istio Authorization documentation](https://istio.io/latest/docs/concepts/security/#authorization).
4. Move to **Module 05: Secrets Management**.

---

## Appendix A — Glossary

- **CNI**: Container Network Interface. The plugin layer that
  Kubernetes uses for networking.
- **eBPF**: Extended Berkeley Packet Filter. In-kernel
  programmable runtime. The substrate Cilium uses.
- **Egress gateway**: A node or pod through which egress
  traffic is routed for policy enforcement.
- **ExternalAuthorization** (ext-authz): An Envoy / Istio
  feature to delegate authorization to an external service.
- **FQDN egress**: Egress policy based on hostname (instead of
  IP), enabled by L7-aware CNIs.
- **Hubble**: Cilium's observability layer for flow logs.
- **IMDS / IMDSv2**: Instance Metadata Service (AWS). v2
  requires session tokens, mitigating SSRF.
- **NetworkPolicy**: Kubernetes resource for L3/L4 network
  rules.
- **VPC**: Virtual Private Cloud. A logically isolated
  network at the cloud provider.
- **VPC endpoint / Private Service Connect**: A way to reach
  a cloud service without traversing the internet.
- **WAF**: Web Application Firewall.

---

## Appendix B — Common misconceptions

| Misconception | Reality |
|---|---|
| "We have a VPC, so the network is private." | The VPC is private from the internet's perspective. It's not private from other workloads in the same VPC. |
| "NetworkPolicy is enforced everywhere." | Enforcement depends on the CNI. Many default CNIs don't enforce. Audit. |
| "Egress is internal; we don't need to restrict it." | Egress is the exfiltration channel. Restrict it. |
| "Rate limiting at the LB is enough." | LB rate limits stop volumetric attacks. Per-tenant cost amplification needs application-layer limits. |
| "We have mTLS, so we don't need NetworkPolicy." | mTLS authenticates and encrypts. NetworkPolicy bounds who can *attempt* a connection. Both layers serve different purposes. |
| "Service mesh covers all our network security needs." | The mesh covers workload-to-workload. The edge, the egress, and the cluster-system pods need additional controls. |
| "We're using a managed K8s, so the network is secure." | The managed plane is secure. The data plane (your workloads) is your responsibility. |

---

*Continue to the [exercises](./exercises/) when you're ready.*
