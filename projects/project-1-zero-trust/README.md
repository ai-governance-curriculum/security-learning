# Project 1: Zero-Trust ML Infrastructure

**Duration**: 140 hours
**Prerequisites**: Senior infra engineer + Kubernetes + networking fundamentals

## Goal

Build a zero-trust ML platform where every request — pod-to-pod, user-to-service, service-to-cloud — is authenticated + authorized at every hop. No implicit trust.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│ External user/service                                │
│   └─ OIDC → Envoy ingress → mTLS into mesh          │
│       └─ Istio sidecar verifies SPIFFE cert         │
│           └─ pod-to-pod mTLS (Linkerd / Istio)     │
│               └─ NetworkPolicy default-deny         │
│                   └─ OPA/Gatekeeper admission      │
│                       └─ Vault for secrets via ESO │
│                           └─ Falco runtime security│
└─────────────────────────────────────────────────────┘
```

## Required components

1. **Microsegmentation**: Cilium NetworkPolicies; default-deny + explicit allow
2. **Service mesh**: Istio or Linkerd with mTLS
3. **Identity**: SPIFFE/SPIRE per-workload identity
4. **Secrets**: Vault + External Secrets Operator
5. **Runtime security**: Falco rules for anomaly detection
6. **Admission**: OPA/Gatekeeper or Kyverno for pre-deploy policies
7. **Audit**: K8s audit log + tamper-evident chain

## Deliverables

- `terraform/` — full infra (VPC + EKS + Vault + observability)
- `helm/` — service mesh + ESO + Falco install
- `policies/` — OPA + Gatekeeper bundle
- `falco-rules/` — runtime rules
- `tests/` — penetration scenarios (must all fail to penetrate)
- `RUNBOOK.md` — operations playbook

## Acceptance

- All 7 components installed + integrated
- Penetration tests: attempt to (1) read another tenant's secret, (2) bypass NetworkPolicy, (3) spawn unsigned image, (4) escalate to root — all blocked + audit-logged
- Audit trail integrity verifiable
- Detailed `ARCHITECTURE.md`
