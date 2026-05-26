# Module 02 — Resources

> Primary sources. Verify URLs at time of access.

## Standards and frameworks

- **NIST SP 800-207 — Zero Trust Architecture**
  [csrc.nist.gov/pubs/sp/800/207/final](https://csrc.nist.gov/pubs/sp/800/207/final)
  The single best reference. ~50 pages, mostly readable.

- **NIST SP 800-204A — Building Secure Microservices-based Applications Using Service-Mesh Architecture**
  [csrc.nist.gov/pubs/sp/800/204/a/final](https://csrc.nist.gov/pubs/sp/800/204/a/final)
  Companion to 800-207 for service-mesh implementations.

- **NIST SP 800-204B — Attribute-based Access Control for Microservices-based Applications using a Service Mesh**
  [csrc.nist.gov/pubs/sp/800/204/b/final](https://csrc.nist.gov/pubs/sp/800/204/b/final)
  Authorization patterns specifically.

- **CISA Zero Trust Maturity Model**
  [cisa.gov/zero-trust-maturity-model](https://www.cisa.gov/zero-trust-maturity-model)
  A maturity scoring framework — useful for self-assessment.

## BeyondCorp

The Google papers, in chronological order:

- **BeyondCorp: A New Approach to Enterprise Security** (2014)
  [research.google/pubs/beyondcorp-a-new-approach-to-enterprise-security/](https://research.google/pubs/beyondcorp-a-new-approach-to-enterprise-security/)

- **BeyondCorp: Design to Deployment at Google** (2016)
  [research.google/pubs/beyondcorp-design-to-deployment-at-google/](https://research.google/pubs/beyondcorp-design-to-deployment-at-google/)

- **BeyondCorp 5: The User Experience** (2017)
  [research.google/pubs/beyondcorp-5-the-user-experience/](https://research.google/pubs/beyondcorp-5-the-user-experience/)

Read at least the first one; it sets the framing the rest of the
industry adopted.

## SPIFFE / SPIRE

- **SPIFFE specification**
  [github.com/spiffe/spiffe](https://github.com/spiffe/spiffe)
  The authoritative spec for SPIFFE IDs, SVIDs, and trust domains.

- **SPIRE documentation**
  [spiffe.io/docs/latest/spire-about](https://spiffe.io/docs/latest/spire-about/)
  Reference implementation. Read the "Concepts" section.

- **SPIFFE / SPIRE for Service Authentication** (CNCF whitepaper)
  Available via the SPIFFE project page.

## Service mesh

- **Istio documentation — Security**
  [istio.io/latest/docs/concepts/security/](https://istio.io/latest/docs/concepts/security/)
  Authentication, AuthorizationPolicy, certificate management.

- **Istio AuthorizationPolicy reference**
  [istio.io/latest/docs/reference/config/security/authorization-policy/](https://istio.io/latest/docs/reference/config/security/authorization-policy/)

- **Cilium documentation — Network Policies**
  [docs.cilium.io/en/stable/network/](https://docs.cilium.io/en/stable/network/)
  CNI-level enforcement, including L7 policy.

- **Cilium Service Mesh**
  [cilium.io/use-cases/service-mesh/](https://cilium.io/use-cases/service-mesh/)
  The eBPF-based alternative to sidecar meshes.

## Kubernetes networking

- **Kubernetes NetworkPolicy documentation**
  [kubernetes.io/docs/concepts/services-networking/network-policies/](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

- **CNI plugin comparison** (Cilium, Calico, Antrea, Weave)
  Read the docs for whichever your environment uses.

## Cloud-native workload identity

- **AWS IAM Roles for Service Accounts (IRSA)**
  [docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)

- **GKE Workload Identity**
  [cloud.google.com/kubernetes-engine/docs/concepts/workload-identity](https://cloud.google.com/kubernetes-engine/docs/concepts/workload-identity)

- **Azure AD Workload Identity**
  [learn.microsoft.com/en-us/azure/aks/workload-identity-overview](https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview)

## ML-specific operational references

- **Google Secure AI Framework (SAIF)**
  [safety.google/cybersecurity-advancements/saif/](https://safety.google/cybersecurity-advancements/saif/)
  Industry framework that incorporates zero-trust principles for ML
  systems.

- **MITRE ATLAS**
  [atlas.mitre.org](https://atlas.mitre.org/)
  Threat tactics that zero-trust controls map against — used in
  Module 01 and applied in this module's exercises.

## Practitioner books

- **Evan Gilman & Doug Barth — Zero Trust Networks** (O'Reilly, 2017).
  A practical book on implementing zero-trust at the network and
  identity layers.

- **Sam Newman — Building Microservices** (O'Reilly, 2021, 2nd ed.).
  Not zero-trust specific, but the security chapter sets useful
  context.

## Cross-references within this curriculum

- [`projects/project-1-zero-trust/`](../../projects/project-1-zero-trust/) — The track's capstone project that exercises everything in this module.

- [`ai-infra-security-solutions/projects/project-1-zero-trust/SOLUTION.md`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions/blob/main/projects/project-1-zero-trust/SOLUTION.md) — Reference design.

- [`ai-infra-engineer-solutions/modules/mod-104-kubernetes/exercise-14-resource-quotas-multitenancy`](https://github.com/ai-infra-curriculum/ai-infra-engineer-solutions/tree/main/modules/mod-104-kubernetes/exercise-14-resource-quotas-multitenancy) — Multi-tenancy fundamentals.

- [`ai-infra-engineer-solutions/modules/mod-109-infrastructure-as-code/exercise-07-secret-management`](https://github.com/ai-infra-curriculum/ai-infra-engineer-solutions/tree/main/modules/mod-109-infrastructure-as-code/exercise-07-secret-management) — Vault + ESO patterns.

- [`ai-infra-engineer-solutions/modules/mod-109-infrastructure-as-code/exercise-08-policy-as-code/kyverno`](https://github.com/ai-infra-curriculum/ai-infra-engineer-solutions/tree/main/modules/mod-109-infrastructure-as-code/exercise-08-policy-as-code) — Admission policy reference.

## Things deliberately not on this list

- Vendor product pages presented as primary sources.
- "Zero-trust solution" whitepapers from security vendors that
  conflate their product with the architecture.
- Tutorials older than 2022; the field has moved (Cilium's L7
  policy, SPIRE maturity, in particular).
