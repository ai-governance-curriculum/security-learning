# Module 04 — Resources

> Primary sources. Verify URLs at time of access.

## Kubernetes networking

- **Kubernetes NetworkPolicy documentation**
  [kubernetes.io/docs/concepts/services-networking/network-policies/](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
  The authoritative reference for NetworkPolicy semantics.

- **Kubernetes Gateway API**
  [gateway-api.sigs.k8s.io](https://gateway-api.sigs.k8s.io/)
  The successor to Ingress; new platforms should default to this.

- **NSA / CISA Kubernetes Hardening Guide**
  [media.defense.gov/2022/Aug/29/2003066362/-1/-1/0/CTR_KUBERNETES_HARDENING_GUIDANCE_1.2_20220829.PDF](https://media.defense.gov/2022/Aug/29/2003066362/-1/-1/0/CTR_KUBERNETES_HARDENING_GUIDANCE_1.2_20220829.PDF)
  Practical hardening checklist; the network section is solid.

## CNI documentation

- **Cilium documentation — Network Policies**
  [docs.cilium.io/en/stable/security/policy/](https://docs.cilium.io/en/stable/security/policy/)
  Including L7 / FQDN egress patterns.

- **Cilium Hubble**
  [docs.cilium.io/en/stable/observability/hubble/](https://docs.cilium.io/en/stable/observability/hubble/)
  Flow logs and observability.

- **Calico Network Policy**
  [docs.tigera.io/calico/latest/network-policy/](https://docs.tigera.io/calico/latest/network-policy/)

- **Antrea documentation**
  [antrea.io/docs/main/docs/](https://antrea.io/docs/main/docs/)

## Service mesh

- **Istio Security documentation**
  [istio.io/latest/docs/concepts/security/](https://istio.io/latest/docs/concepts/security/)

- **Istio AuthorizationPolicy reference**
  [istio.io/latest/docs/reference/config/security/authorization-policy/](https://istio.io/latest/docs/reference/config/security/authorization-policy/)

- **Istio Ambient mode**
  [istio.io/latest/docs/ambient/](https://istio.io/latest/docs/ambient/)

- **Envoy External Authorization**
  [envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/ext_authz_filter](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/ext_authz_filter)

## TLS / TLS configuration

- **Mozilla SSL Configuration Generator**
  [ssl-config.mozilla.org](https://ssl-config.mozilla.org/)

- **OWASP Transport Layer Security Cheat Sheet**
  [cheatsheetseries.owasp.org/cheatsheets/Transport_Layer_Security_Cheat_Sheet.html](https://cheatsheetseries.owasp.org/cheatsheets/Transport_Layer_Security_Cheat_Sheet.html)

## Cloud / WAF

- **AWS WAF** — [docs.aws.amazon.com/waf](https://docs.aws.amazon.com/waf/)

- **GCP Cloud Armor** — [cloud.google.com/armor/docs](https://cloud.google.com/armor/docs)

- **Cloudflare WAF** — [developers.cloudflare.com/waf](https://developers.cloudflare.com/waf/)

- **AWS Shield** (DDoS) — [aws.amazon.com/shield](https://aws.amazon.com/shield/)

## Cloud metadata / IMDS

- **AWS IMDSv2**
  [docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html)

- **GCP metadata server**
  [cloud.google.com/compute/docs/metadata/overview](https://cloud.google.com/compute/docs/metadata/overview)

- **Azure Instance Metadata Service**
  [learn.microsoft.com/en-us/azure/virtual-machines/instance-metadata-service](https://learn.microsoft.com/en-us/azure/virtual-machines/instance-metadata-service)

## NIST and standards

- **NIST SP 800-207 — Zero Trust Architecture** (covered in Module 02 also)
  [csrc.nist.gov/pubs/sp/800/207/final](https://csrc.nist.gov/pubs/sp/800/207/final)

- **NIST SP 800-204A — Microservices Security via Service Mesh**
  [csrc.nist.gov/pubs/sp/800/204/a/final](https://csrc.nist.gov/pubs/sp/800/204/a/final)

- **NIST SP 800-204B — ABAC for Microservices**
  [csrc.nist.gov/pubs/sp/800/204/b/final](https://csrc.nist.gov/pubs/sp/800/204/b/final)

## Books

- **Network Security Assessment** by Chris McNab (O'Reilly).
- **Web Application Firewalls** by Joaquim Murillo (Packt) — for
  WAF tuning specifically.
- **Container Security** by Liz Rice (O'Reilly) — covers
  container-network risk in addition to runtime.

## Cross-references within this curriculum

- [`ai-infra-engineer-solutions/modules/mod-104-kubernetes/exercise-14-resource-quotas-multitenancy`](https://github.com/ai-infra-curriculum/ai-infra-engineer-solutions/tree/main/modules/mod-104-kubernetes/exercise-14-resource-quotas-multitenancy)

- [`ai-infra-mlops-solutions/modules/09-security/exercise-04`](https://github.com/ai-infra-curriculum/ai-infra-mlops-solutions/tree/main/modules/09-security) — Pod security + NetworkPolicy.

- [`ai-infra-security-solutions/projects/project-1-zero-trust/`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions/tree/main/projects/project-1-zero-trust) — Istio + NetworkPolicy reference.

## Things deliberately not on this list

- Vendor whitepapers presented as primary references.
- "Zero-trust network" marketing material.
- CNI benchmark articles older than 2023 — eBPF performance has
  changed significantly.
