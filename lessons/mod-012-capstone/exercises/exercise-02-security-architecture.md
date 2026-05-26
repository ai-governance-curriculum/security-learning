# Capstone Exercise 02 — Security Architecture

**Estimated time**: 6 hours
**Deliverable**: A 10-15 page architecture document

---

## The assignment

Produce NorthBridge's security architecture. Each architectural
choice must address risks from Exercise 01.

## Required sections

### Section A: Zero-trust architecture (Module 02)

- **Workload identity scheme** — SPIFFE-style IDs for every
  workload class (training, serving, governance, notebooks,
  CI, OpenAI proxy).
- **Attestation selectors** — what binds identity to workload.
- **Authorization model** — what calls what, with example
  Istio AuthorizationPolicy YAML.
- **Multi-tenant isolation** — specifically for the feature
  store and the model serving pods. This is fragile today
  (per the scenario brief); the architecture must fix it.

### Section B: Cryptography + key management (Module 03)

- **Encryption at rest** — what's encrypted with what key.
  Per-tenant DEK structure for PHI.
- **Encryption in transit** — TLS 1.3 baseline; mTLS for
  service-to-service.
- **Encryption in use** — for what workloads (if any)? Defend
  the choice (the EU customer asked about this).
- **KMS hierarchy** — root → tenant → data.
- **Per-purpose key separation** — at least 6 distinct purposes.
- **Rotation cadence** — per key class.
- **Vault deployment** — including PKI, Transit, Database.

### Section C: Network security (Module 04)

- **CNI choice** — Cilium / Calico / managed CNI; defended.
- **Default-deny NetworkPolicies** with namespace-by-namespace
  allow plans.
- **Egress controls** — including the cloud-metadata block,
  DNS restrictions, and the FQDN-based egress for the OpenAI
  call (Wellness-Coach).
- **Edge gateway** — hardening checklist; auth model
  (SAML SSO for enterprise, API keys with proper validation
  for mid-market).
- **Multi-cloud readiness** — what changes when Azure (EU)
  comes online.

### Section D: Secrets management (Module 05)

- **Vault or cloud-native?** — chosen with rationale.
- **Dynamic secrets** — for the PostgreSQL clinical data
  warehouse; for AWS IAM during training; for OpenAI API
  rotation.
- **Keyless CI** — for the GitHub Actions → AWS / Sigstore flow.
- **Migration plan** — from today's "long-lived credentials in
  some places" to dynamic + identity-derived.

### Section E: Architecture diagrams

At minimum:

- **Request flow diagram** for a clinical inference request,
  showing every authentication / authorization step.
- **Training data flow diagram** showing data lineage from
  hospital EHR → warehouse → training pipeline → model
  registry.
- **Multi-tenant isolation diagram** showing the feature
  store's per-tenant boundaries.
- **Cross-cloud / cross-region diagram** showing the planned
  Azure EU expansion.

ASCII or Mermaid; this is content, not an art exercise.

### Section F: Sequencing

The architecture isn't built in a day. Sequence the changes:

- **Phase 1 (quarter 1)**: foundation — workload identity,
  KMS hierarchy, default-deny NetworkPolicies in warn mode.
- **Phase 2 (quarter 2)**: enforcement — promote policies to
  enforce; deploy keyless CI; migrate first workloads to
  dynamic secrets.
- **Phase 3 (quarter 3)**: hardening — Cilium L7 egress;
  multi-tenant authorization rewrite; Vault Transit for
  PHI columns.
- **Phase 4 (quarter 4)**: scale — multi-cloud expansion;
  trust-domain federation; hand-off documentation for the
  growing team.

For each phase: deliverables, success criterion, dependencies,
rollback.

## Quality criteria

A passing architecture:

- Addresses **every workload class** in the scenario with
  named workload identity.
- The **multi-tenant authorization fix** is concrete and
  testable.
- Network design includes **default-deny + egress controls +
  metadata block**.
- Vault deployment is sized for **8 engineers today, 25 in
  12 months**.
- Sequencing is realistic for a 4-quarter plan.

A failing architecture:

- "We'll use IAM" without workload-identity scoping.
- Multi-tenant authorization remains a gateway-side concern
  only.
- Egress is an afterthought.
- Vault is "we'll figure it out."
- Phase 1 is "everything."

## Connections to other exercises

- The workload-identity scheme drives Exercise 03's signing
  identities.
- The Vault deployment supports Exercise 04's policy-bundle
  signing.
- The architecture's hardening defines what SecOps detects on
  (Exercise 05).
- The CFO summary in Exercise 06 needs this architecture's
  cost profile.

## Time budget

- Zero-trust + identity: 90 min.
- Cryptography + KMS: 90 min.
- Network: 75 min.
- Secrets: 60 min.
- Diagrams: 60 min.
- Sequencing + integration: 45 min.

Under 5 hours → too shallow.
