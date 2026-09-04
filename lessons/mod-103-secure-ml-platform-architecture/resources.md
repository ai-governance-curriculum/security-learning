# Resources — mod-103 (Secure ML Platform Architecture)

> Primary sources for the five topic areas the module covers:
> zero-trust architecture (NIST SP 800-207), SPIFFE / SPIRE
> workload identity, Kubernetes network policy and service-mesh
> authorisation, the CIS Kubernetes Benchmark and Pod Security
> Admission, and admission-time policy-as-code (OPA / Gatekeeper /
> Kyverno) plus the signature / provenance / ML-BOM evidence it
> gates on. Verify every URL and version at time of access; the
> field moves and links rot. Where a citation pins to a specific
> edition, the pinned version is called out.

---

## Zero Trust Architecture — NIST and companion guidance

- **NIST SP 800-207 — *Zero Trust Architecture*** (August 2020).
  [csrc.nist.gov/pubs/sp/800/207/final](https://csrc.nist.gov/pubs/sp/800/207/final)
  The pinned primary source for chapters 01 and 02. Defines the
  seven ZTA tenets (§2), the logical architecture (§3.2 —
  PE / PA / PEP), the trust-algorithm variants (§3.3), and the
  deployment variants (§3.4).

- **NIST SP 800-207A — *A Zero Trust Architecture Model for
  Access Control in Cloud-Native Applications in Multi-Cloud
  Environments*** (September 2023).
  [csrc.nist.gov/pubs/sp/800/207/a/final](https://csrc.nist.gov/pubs/sp/800/207/a/final)
  Extends SP 800-207 to service-mesh / cloud-native substrates —
  directly applicable to the three-plane Kubernetes model in
  chapter 02.

- **NIST SP 1800-35 — *Implementing a Zero Trust Architecture*
  (NCCoE)** (multi-volume, current).
  [csrc.nist.gov/pubs/sp/1800/35/final](https://csrc.nist.gov/pubs/sp/1800/35/final)
  Reference-implementation guidance from the NCCoE ZTA project;
  useful for concrete PEP / PDP / PIP wiring examples.

- **CISA — *Zero Trust Maturity Model* v2.0** (April 2023).
  [cisa.gov/zero-trust-maturity-model](https://www.cisa.gov/zero-trust-maturity-model)
  The five-pillar maturity ladder (identity, devices, networks,
  applications / workloads, data). Chapter 01's gap assessment
  scoring rubric aligns with this.

- **DoD Zero Trust Reference Architecture** (v2.0, July 2022).
  [dodcio.defense.gov](https://dodcio.defense.gov/)
  US Department of Defense reference architecture. Complements
  SP 800-207 with a defence-scale deployment blueprint.
  <!-- needs-research: confirm current canonical URL for the
  v2.0 PDF; the DoD CIO site restructures periodically -->

- **John Kindervag — *No More Chewy Centers: The Zero Trust
  Model of Information Security*** (Forrester, 2010).
  Foundational paper commonly cited as the origin of the "never
  trust, always verify" phrasing that SP 800-207 later codified.
  <!-- needs-research: locate a canonical, currently hosted URL
  for the original Forrester paper before external publication -->

---

## SPIFFE and SPIRE — workload identity

- **SPIFFE — The Secure Production Identity Framework For
  Everyone.** [spiffe.io](https://spiffe.io/)
  Umbrella site for the SPIFFE / SPIRE project (CNCF graduated).

- **SPIFFE Specifications (canonical).**
  [github.com/spiffe/spiffe/tree/main/standards](https://github.com/spiffe/spiffe/tree/main/standards)
  Includes:
  - *SPIFFE ID and SVID*: identity URI format.
  - *X509-SVID*: SPIFFE identity as an X.509 certificate SAN URI.
  - *JWT-SVID*: SPIFFE identity as a JWT.
  - *SPIFFE Workload API*: the Unix-socket gRPC contract by
    which workloads fetch their SVIDs.
  - *SPIFFE Trust Domain and Bundle*: trust-anchor material and
    federation format.

- **SPIRE documentation.**
  [spiffe.io/docs/latest/spire-about](https://spiffe.io/docs/latest/spire-about/)
  Reference implementation of SPIFFE. Sections used in chapter
  03: server / agent architecture, node and workload attestors,
  registration entries, federation, and the OIDC discovery
  provider.

- **SPIRE — Kubernetes deployment guide.**
  [spiffe.io/docs/latest/try/getting-started-k8s](https://spiffe.io/docs/latest/try/getting-started-k8s/)
  DaemonSet agent pattern the module's SPIRE topology uses.

- **SPIRE — federation.**
  [spiffe.io/docs/latest/architecture/federation](https://spiffe.io/docs/latest/architecture/federation/)
  Cross-trust-domain trust-bundle exchange. Referenced from
  chapter 03's multi-cluster training / serving example.

- **SPIRE — production considerations.**
  [spiffe.io/docs/latest/planning/production](https://spiffe.io/docs/latest/planning/production/)
  HA server topology, datastore choices, key-manager rotation,
  disaster recovery. Called out from chapter 01's "what this
  module does not cover" list.

- **Andres Vega, Emiliano Berenbaum, et al. — *Solving the Bottom
  Turtle: A SPIFFE Way to Establish Trust in Your Infrastructure
  via Universal Identity*** (2020; free download from SPIFFE).
  [spiffe.io/book](https://spiffe.io/book/) <!-- needs-research:
  confirm current canonical URL for the book PDF before external
  citation -->
  Long-form background on SPIFFE identity semantics.

- **Kubernetes — Bound Service Account Tokens.**
  [kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/#bound-service-account-tokens](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/#bound-service-account-tokens)
  The short-lived, audience-bound token primitive SPIRE's
  node-attestor uses, and the mechanism the "no ambient node
  identity" argument in chapter 03 leans on.

- **OpenID Connect Core 1.0.**
  [openid.net/specs/openid-connect-core-1_0.html](https://openid.net/specs/openid-connect-core-1_0.html)
  The federation contract SPIRE's OIDC discovery provider
  implements; cloud STS trust policies validate against it.

- **OAuth 2.0 Token Exchange (RFC 8693).**
  [datatracker.ietf.org/doc/html/rfc8693](https://datatracker.ietf.org/doc/html/rfc8693)
  The generalised STS pattern behind cloud-provider workload
  federation.

- **Cloud workload-identity federation — primary docs.**
  - AWS IAM Roles for Service Accounts (IRSA) and OIDC identity
    providers:
    [docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
    and
    [docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_oidc.html](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_oidc.html).
  - GCP Workload Identity Federation:
    [cloud.google.com/iam/docs/workload-identity-federation](https://cloud.google.com/iam/docs/workload-identity-federation).
  - Azure Workload Identity:
    [learn.microsoft.com/en-us/azure/aks/workload-identity-overview](https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview).

---

## Kubernetes network policy and service-mesh authorisation

### Kubernetes NetworkPolicy — the L3/L4 primitive

- **Kubernetes — NetworkPolicy (concept).**
  [kubernetes.io/docs/concepts/services-networking/network-policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
  Canonical documentation for the `NetworkPolicy` API used in
  chapter 04 to segment the training / feature / serving /
  registry planes at deny-by-default.

- **Kubernetes SIG-Network — AdminNetworkPolicy and
  BaselineAdminNetworkPolicy.**
  [network-policy-api.sigs.k8s.io](https://network-policy-api.sigs.k8s.io/)
  Cluster-scoped policy primitives; useful when platform teams
  need to enforce a namespace-agnostic baseline over the top of
  namespace-scoped NetworkPolicy resources.

### CNI implementations that enforce NetworkPolicy

- **Cilium.** [docs.cilium.io](https://docs.cilium.io/)
  eBPF-based CNI with L7-aware `CiliumNetworkPolicy` and
  `CiliumClusterwideNetworkPolicy` extensions.

- **Calico.** [docs.tigera.io/calico/latest](https://docs.tigera.io/calico/latest/)
  L3/L4 CNI with an extended `GlobalNetworkPolicy` type,
  frequently deployed alongside the Kubernetes-native
  NetworkPolicy resources chapter 04 uses.

- **Antrea.** [antrea.io/docs/main](https://antrea.io/docs/main/)
  OVS-based CNI with cluster-wide policy extensions.

### Service-mesh authorisation (L7)

- **Istio — Authorization Policy.**
  [istio.io/latest/docs/reference/config/security/authorization-policy](https://istio.io/latest/docs/reference/config/security/authorization-policy/)
  Reference for the `AuthorizationPolicy` custom resource used in
  chapter 04 to enforce per-request rules keyed on the SPIFFE ID
  in the mTLS client certificate.

- **Istio — Security concepts.**
  [istio.io/latest/docs/concepts/security](https://istio.io/latest/docs/concepts/security/)
  Overview of Istio's identity model (which supports SPIFFE),
  mTLS bootstrap, and the request-authentication vs. authorisation
  split.

- **Istio — Ambient Mesh.**
  [istio.io/latest/docs/ambient](https://istio.io/latest/docs/ambient/)
  Sidecar-less deployment mode; relevant to the alternative
  topology called out in chapter 04.

- **Linkerd — Authorization Policy.**
  [linkerd.io/2/features/server-policy](https://linkerd.io/2/features/server-policy/)
  Linkerd's `Server`, `ServerAuthorization`, and
  `AuthorizationPolicy` CRDs; the L7 authorisation contract when
  Linkerd is the chosen mesh.

- **Linkerd + SPIRE integration.**
  [linkerd.io/2.15/tasks/using-spire-with-linkerd](https://linkerd.io/2.15/tasks/using-spire-with-linkerd/)
  How to source Linkerd workload identities from SPIRE.

- **Envoy — Secret Discovery Service (SDS).**
  [envoyproxy.io/docs/envoy/latest/configuration/security/secret](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret)
  The dynamic-secret contract Envoy proxies use to consume SVIDs
  from SPIRE without a full mesh.

- **Envoy — External Authorization filter.**
  [envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/ext_authz_filter](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/ext_authz_filter)
  The mechanism by which mesh sidecars call out to an external
  PDP (e.g. OPA) for per-request decisions.

---

## Kubernetes cluster hardening — CIS Benchmark and Pod Security Admission

### CIS Kubernetes Benchmark

- **CIS Kubernetes Benchmark.**
  [cisecurity.org/benchmark/kubernetes](https://www.cisecurity.org/benchmark/kubernetes)
  The authoritative benchmark. Chapter 05 references v1.9.0
  (current at time of authoring); confirm the current version
  and its numbered recommendations against the CIS Center
  download before quoting a specific control ID externally.

- **CIS Benchmarks — general download page.**
  [cisecurity.org/cis-benchmarks](https://www.cisecurity.org/cis-benchmarks/)
  Distribution and version-history landing page.

- **kube-bench.**
  [github.com/aquasecurity/kube-bench](https://github.com/aquasecurity/kube-bench)
  The reference scanner the module's hardening sprint uses to
  gather baseline state and to verify remediations against the
  CIS Kubernetes Benchmark.

- **CIS Benchmarks for the major managed distributions.** Distinct
  benchmarks per distro / vendor are listed at
  [cisecurity.org/benchmark/kubernetes](https://www.cisecurity.org/benchmark/kubernetes/)
  (EKS, GKE, AKS, and OpenShift variants alongside the upstream
  one). Pick the benchmark that matches the substrate.

### Pod Security Admission (PSA)

- **Kubernetes — Pod Security Standards.**
  [kubernetes.io/docs/concepts/security/pod-security-standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
  The `privileged` / `baseline` / `restricted` profile
  definitions PSA enforces.

- **Kubernetes — Pod Security Admission.**
  [kubernetes.io/docs/concepts/security/pod-security-admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/)
  The built-in admission controller; label-driven `enforce`,
  `audit`, `warn` modes; the migration path from the deprecated
  PodSecurityPolicy resource.

- **Kubernetes — Enforce Pod Security Standards with Namespace
  Labels.**
  [kubernetes.io/docs/tasks/configure-pod-container/enforce-standards-namespace-labels](https://kubernetes.io/docs/tasks/configure-pod-container/enforce-standards-namespace-labels/)
  The operational how-to chapter 05 walks through.

- **KEP-2579 — PodSecurityPolicy Replacement.**
  [github.com/kubernetes/enhancements/tree/master/keps/sig-auth/2579-psp-replacement](https://github.com/kubernetes/enhancements/tree/master/keps/sig-auth/2579-psp-replacement)
  Design and history of PSA and the PSP replacement path.

### Related Kubernetes security primitives

- **Kubernetes — Seccomp.**
  [kubernetes.io/docs/tutorials/security/seccomp](https://kubernetes.io/docs/tutorials/security/seccomp/)
  Cluster-wide default seccomp is one of chapter 05's high-
  blast-radius rows.

- **Kubernetes — AppArmor.**
  [kubernetes.io/docs/tutorials/security/apparmor](https://kubernetes.io/docs/tutorials/security/apparmor/)

- **Kubernetes — Audit logging.**
  [kubernetes.io/docs/tasks/debug/debug-cluster/audit](https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/)
  The apiserver audit policy; the CIS Benchmark contains
  multiple audit-configuration recommendations chapter 05
  addresses.

- **NSA / CISA — *Kubernetes Hardening Guide*** (version 1.2,
  August 2022).
  [media.defense.gov/2022/Aug/29/2003066362/-1/-1/0/CTR_KUBERNETES_HARDENING_GUIDANCE_1.2_20220829.PDF](https://media.defense.gov/2022/Aug/29/2003066362/-1/-1/0/CTR_KUBERNETES_HARDENING_GUIDANCE_1.2_20220829.PDF)
  Government-authored hardening guidance that overlaps with and
  complements the CIS Benchmark.

- **CNCF — *Cloud Native Security Whitepaper* v2.**
  [github.com/cncf/tag-security/blob/main/security-whitepaper/v2/cloud-native-security-whitepaper.md](https://github.com/cncf/tag-security/blob/main/security-whitepaper/v2/cloud-native-security-whitepaper.md)
  Vendor-neutral cloud-native security background reading.

---

## Admission-time policy-as-code — OPA, Gatekeeper, Kyverno, native

### Open Policy Agent (OPA) and Rego

- **Open Policy Agent — main documentation.**
  [openpolicyagent.org/docs/latest](https://www.openpolicyagent.org/docs/latest/)
  Overview, integrations, and the OPA HTTP / library API.

- **Rego language reference.**
  [openpolicyagent.org/docs/latest/policy-language](https://www.openpolicyagent.org/docs/latest/policy-language/)
  The policy DSL chapter 06's constraint templates and admission
  policies are written in.

- **OPA — testing policies.**
  [openpolicyagent.org/docs/latest/policy-testing](https://www.openpolicyagent.org/docs/latest/policy-testing/)
  `opa test` and the unit-test conventions the exercise 05
  acceptance criteria mandate.

### Gatekeeper

- **OPA Gatekeeper documentation.**
  [open-policy-agent.github.io/gatekeeper](https://open-policy-agent.github.io/gatekeeper/website/docs/)
  The primary source for the `ConstraintTemplate` / `Constraint`
  pattern chapter 06 uses to gate model deployments.

- **Gatekeeper Policy Library.**
  [open-policy-agent.github.io/gatekeeper-library](https://open-policy-agent.github.io/gatekeeper-library/website/)
  Curated set of upstream constraint templates; a starting point
  for the constraints exercise 05 asks the learner to author.

- **Gatekeeper — Audit and mutation.**
  [open-policy-agent.github.io/gatekeeper/website/docs/audit](https://open-policy-agent.github.io/gatekeeper/website/docs/audit/)
  and
  [open-policy-agent.github.io/gatekeeper/website/docs/mutation](https://open-policy-agent.github.io/gatekeeper/website/docs/mutation/).

### Kyverno

- **Kyverno.** [kyverno.io/docs](https://kyverno.io/docs/)
  YAML-native policy engine — an alternative to
  Rego / Gatekeeper. Referenced in chapter 06 as the option
  chosen by teams that prefer declarative policy without a DSL.

- **Kyverno — Policies.**
  [kyverno.io/policies](https://kyverno.io/policies/)
  Reference library of Kyverno policies including
  image-signature verification via cosign.

### Kubernetes native policy paths

- **Kubernetes — ValidatingAdmissionPolicy (CEL-based).**
  [kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/)
  Cluster-native alternative / complement to OPA and Kyverno
  for admission-time validation, written in CEL.

- **Kubernetes — Dynamic Admission Control.**
  [kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/)
  Reference for the `ValidatingWebhookConfiguration` and
  `MutatingWebhookConfiguration` primitives Gatekeeper and
  Kyverno register against.

- **Common Expression Language (CEL) specification.**
  [github.com/google/cel-spec](https://github.com/google/cel-spec)
  Language reference for `ValidatingAdmissionPolicy`.

---

## Signatures, provenance, and ML-BOM — the evidence the admission gate verifies

- **Sigstore project.** [sigstore.dev](https://www.sigstore.dev/)
  Umbrella project for the keyless-signing stack referenced in
  chapters 02, 03, and 06.

- **Sigstore documentation.**
  [docs.sigstore.dev](https://docs.sigstore.dev/)
  Component index: cosign (signing), Fulcio (short-lived cert
  authority), Rekor (transparency log).

- **cosign.**
  [github.com/sigstore/cosign](https://github.com/sigstore/cosign)
  The signer / verifier binary Gatekeeper and Kyverno call out
  to (or embed) in chapter 06's `require-cosign-signature`
  constraint.

- **Rekor — transparency log.**
  [docs.sigstore.dev/logging/overview](https://docs.sigstore.dev/logging/overview/)

- **Fulcio — short-lived certificate authority.**
  [docs.sigstore.dev/certificate_authority/overview](https://docs.sigstore.dev/certificate_authority/overview/)

- **SLSA — Supply-chain Levels for Software Artifacts** (v1.0,
  April 2023).
  [slsa.dev/spec/v1.0](https://slsa.dev/spec/v1.0/)
  The provenance-attestation schema and the builder-identity
  contract chapter 06 verifies against.

- **in-toto — supply-chain metadata framework.**
  [in-toto.io](https://in-toto.io/)
  The attestation-envelope format Sigstore uses to carry SLSA
  provenance, ML-BOM, and other predicates.

- **CycloneDX — ML-BOM.**
  [cyclonedx.org/capabilities/mlbom](https://cyclonedx.org/capabilities/mlbom/)
  The machine-learning bill-of-materials schema chapter 06
  gates on. Complements the general software BOM at
  [cyclonedx.org](https://cyclonedx.org/).

- **Protect AI ModelScan.**
  [github.com/protectai/modelscan](https://github.com/protectai/modelscan)
  Model-artifact scanner for pickle / TF / Keras / ONNX. Chapter
  06's `scan-clean` predicate references its output format.

- **Hugging Face `safetensors`.**
  [github.com/huggingface/safetensors](https://github.com/huggingface/safetensors)
  Safer weight-serialisation format; the "safetensors-only" rule
  in chapter 06's example constraint set is enforced by
  inspecting the artifact format.

- **OCI Distribution Specification.**
  [github.com/opencontainers/distribution-spec](https://github.com/opencontainers/distribution-spec)
  Registry API surface. Model artifacts and their signatures
  land here (ORAS reference below for non-image artifacts).

- **OCI Image Specification.**
  [github.com/opencontainers/image-spec](https://github.com/opencontainers/image-spec)

- **ORAS — OCI Registry As Storage.**
  [oras.land](https://oras.land/)
  The pattern for pushing model files and ML-BOM documents as
  OCI artifacts to any OCI-compliant registry.

- **Trivy — vulnerability and configuration scanner.**
  [aquasecurity.github.io/trivy](https://aquasecurity.github.io/trivy/)
  Container-image scanning input to the `scan-clean` predicate.

---

## Kubernetes core references

- **Kubernetes documentation — main index.**
  [kubernetes.io/docs](https://kubernetes.io/docs/)

- **Kubernetes Security Checklist.**
  [kubernetes.io/docs/concepts/security/security-checklist](https://kubernetes.io/docs/concepts/security/security-checklist/)
  The Kubernetes project's own checklist; overlaps CIS and NSA
  guides.

- **Kubernetes — RBAC.**
  [kubernetes.io/docs/reference/access-authn-authz/rbac](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
  RBAC is the identity layer the workload-identity story sits on
  top of; chapter 05 references it as a hardening surface.

---

## Cross-references within this curriculum

- The [module plan](../../CURRICULUM.md) and the [job-requirements
  packet](../../JOB_REQUIREMENTS.md) at the repository root.
- Sibling modules:
  - [mod-102](../mod-102-threat-modelling-for-ai-ml-systems/) —
    produces the STRIDE + attack-tree + mitigation scorecard that
    is the *input* to this module.
  - [mod-105](../mod-105-secrets-and-key-management/) — owns the
    KMS holding the SPIRE signing keys and the cosign keys the
    admission gate verifies against.
  - [mod-110](../mod-110-supply-chain-security-for-ai/) —
    produces the signatures, SLSA provenance, and ML-BOM that
    the mod-103 admission gate enforces on.
  - [mod-111](../mod-111-security-operations-and-incident-response-for-ml/) —
    consumes mesh authz decisions and Gatekeeper audit output as
    detection input.
- The paired solutions repo (linked from the top-level README).

---

## Things deliberately not on this list

- Vendor product whitepapers positioned as primary sources for
  zero trust or workload identity. Cite the standards (SP 800-207,
  the SPIFFE specifications) — vendor documents describe
  implementations.
- "Zero-trust-in-a-box" marketing pages. The primary sources on
  this list contain everything needed to author a real ZTA gap
  assessment.
- Blog posts as the sole source for a control claim. If a control
  is real, it exists in the standard, the tool's documentation,
  or the CIS Benchmark; those are the citations to use.
