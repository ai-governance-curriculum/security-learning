# Module 08 — Resources

> Primary sources for runtime security. Verify URLs at access time.

## Kubernetes Pod Security

- **Pod Security Standards**
  [kubernetes.io/docs/concepts/security/pod-security-standards/](https://kubernetes.io/docs/concepts/security/pod-security-standards/)

- **Pod Security Admission**
  [kubernetes.io/docs/concepts/security/pod-security-admission/](https://kubernetes.io/docs/concepts/security/pod-security-admission/)

- **From PodSecurityPolicy to Pod Security Standards** (migration)
  [kubernetes.io/blog/2022/08/25/pod-security-admission-stable/](https://kubernetes.io/blog/2022/08/25/pod-security-admission-stable/)

## Seccomp / AppArmor / SELinux

- **Kubernetes Seccomp documentation**
  [kubernetes.io/docs/tutorials/security/seccomp/](https://kubernetes.io/docs/tutorials/security/seccomp/)

- **Kubernetes AppArmor documentation**
  [kubernetes.io/docs/tutorials/security/apparmor/](https://kubernetes.io/docs/tutorials/security/apparmor/)

- **SELinux Project documentation**
  [github.com/SELinuxProject/selinux-notebook](https://github.com/SELinuxProject/selinux-notebook)

## Falco

- **Falco documentation**
  [falco.org/docs/](https://falco.org/docs/)

- **Falco rules reference**
  [falco.org/docs/reference/rules/](https://falco.org/docs/reference/rules/)

- **Falco default rules**
  [github.com/falcosecurity/rules](https://github.com/falcosecurity/rules)

- **Falcosidekick** (alert routing)
  [github.com/falcosecurity/falcosidekick](https://github.com/falcosecurity/falcosidekick)

## eBPF and Tetragon

- **Tetragon documentation**
  [tetragon.io/docs/](https://tetragon.io/docs/)

- **eBPF.io** (general eBPF reference)
  [ebpf.io/what-is-ebpf/](https://ebpf.io/what-is-ebpf/)

- **Cilium documentation** (includes Hubble for flow logs)
  [docs.cilium.io](https://docs.cilium.io/en/stable/)

## Sandboxing

- **gVisor documentation**
  [gvisor.dev/docs/](https://gvisor.dev/docs/)

- **Kata Containers documentation**
  [katacontainers.io/docs/](https://katacontainers.io/docs/)

## NIST and standards

- **NIST SP 800-190 — Application Container Security Guide**
  [csrc.nist.gov/pubs/sp/800/190/final](https://csrc.nist.gov/pubs/sp/800/190/final)

- **CIS Kubernetes Benchmark**
  [cisecurity.org/benchmark/kubernetes](https://www.cisecurity.org/benchmark/kubernetes)

- **NSA / CISA Kubernetes Hardening Guide**
  [media.defense.gov/2022/Aug/29/2003066362/-1/-1/0/CTR_KUBERNETES_HARDENING_GUIDANCE_1.2_20220829.PDF](https://media.defense.gov/2022/Aug/29/2003066362/-1/-1/0/CTR_KUBERNETES_HARDENING_GUIDANCE_1.2_20220829.PDF)

## MITRE references

- **MITRE ATT&CK for Containers**
  [attack.mitre.org/matrices/enterprise/containers/](https://attack.mitre.org/matrices/enterprise/containers/)

- **MITRE ATLAS** (ML-specific tactics; Module 01 also)
  [atlas.mitre.org](https://atlas.mitre.org/)

## Books

- **Container Security** by Liz Rice (O'Reilly).
  Comprehensive practical reference.

- **Practical Kubernetes Hardening** (various authors).
  Operational guidance.

## Tools (operational reference)

- **kubectl-trace** — eBPF tracing for Kubernetes from CLI.
- **Inspektor Gadget** — eBPF observability tooling for K8s.
- **kube-bench** — CIS Benchmark scanner.
- **Trivy** — image + filesystem scanner (also catches some
  runtime-relevant findings).

## Commercial reference (not endorsement)

- **Sysdig Secure**
- **Aqua Security**
- **Wiz Runtime**
- **Lacework**

(For curriculum purposes; production teams choose based on
specific evaluation.)

## Cross-references within this curriculum

- [`ai-infra-security-solutions/projects/project-1-zero-trust/falco-rules/`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions/tree/main/projects/project-1-zero-trust/falco-rules) — Reference Falco rules.

- [`ai-infra-security-solutions/projects/project-5-security-operations/sigma-rules/`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions/tree/main/projects/project-5-security-operations/sigma-rules) — Higher-level detection patterns.

- [`ai-infra-engineer-solutions/modules/mod-104-kubernetes/`](https://github.com/ai-infra-curriculum/ai-infra-engineer-solutions/tree/main/modules/mod-104-kubernetes) — Pod security + multi-tenancy reference.

## Things deliberately not on this list

- Tools claiming "AI-powered" runtime security without
  specifics on what the AI does.
- Tutorials older than 2022 (the PSP → PSS transition broke a
  lot of pre-2022 guidance).
- Vendor whitepapers that conflate prevention with detection.
