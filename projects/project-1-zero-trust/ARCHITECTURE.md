# Architecture — Zero-Trust ML Infrastructure

## Layer diagram

```
┌──── L7: Application ──────────────────────────────┐
│  Apps + ML services                                │
├──── L6: Service Mesh (Istio/Linkerd) ─────────────┤
│  mTLS, traffic policies, retries                   │
├──── L5: Identity (SPIFFE/SPIRE) ──────────────────┤
│  Per-workload identity, cert rotation              │
├──── L4: NetworkPolicy (Cilium) ────────────────────┤
│  Default-deny + explicit allow                     │
├──── L3: Admission (Kyverno) ───────────────────────┤
│  Image signing, labels, security contexts          │
├──── L2: Secrets (Vault + ESO) ─────────────────────┤
│  No plaintext; auto-rotate                         │
├──── L1: Runtime (Falco) ──────────────────────────┤
│  Behavior monitoring; alert on anomalies           │
└──── L0: Audit (immutable) ─────────────────────────┘
   Tamper-evident hash chain in S3 + object lock
```

## Cross-references
- engineer-solutions/mod-109 ex-07 (Vault secret management)
- engineer-solutions/mod-109 ex-08 (policy as code)
- engineer-solutions/mod-103 ex-10 (SLSA supply chain)
- engineer-solutions/mod-104 ex-14 (multi-tenancy)
