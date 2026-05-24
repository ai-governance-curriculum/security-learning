# Requirements — Zero-Trust ML Infrastructure

## FR-001: Network microsegmentation
Default-deny ingress + egress per namespace. Explicit allow for known traffic
patterns only. Verified by: pod in team-A cannot reach service in team-B without
a NetworkPolicy.

## FR-002: mTLS between services
All pod-to-pod traffic uses mTLS via SPIFFE identity. Certificates auto-rotate
every 24h. Verified by: capturing traffic + observing encrypted handshakes.

## FR-003: Vault-backed secrets
No plaintext secrets in any manifest or ConfigMap. All secrets flow Vault →
ESO → Kubernetes Secret. Verified by: scan all manifests for plaintext;
expect zero hits.

## FR-004: Admission policies
Kyverno/OPA gates: signed images only, required labels, no root containers,
no host namespaces. Verified by: attempt to deploy violating Pods; all rejected.

## FR-005: Runtime detection
Falco rules detect + alert on: shell in container, file modifications outside
allowed paths, suspicious network connections. Verified by: trigger each rule;
alert fires within 30s.

## FR-006: Audit trail integrity
K8s audit log + service-mesh access logs in tamper-evident store. Verified by:
hash chain validates over 30-day window.

## NFR-001: Performance overhead
mTLS + service mesh: < 5ms p95 added latency per hop.

## NFR-002: Cost
< 15% additional infrastructure cost vs baseline cluster.

## NFR-003: Operability
Onboarding a new team takes < 1 hour with templates.
