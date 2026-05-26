# Exercise 02 — Vault Deployment Plan

**Estimated time**: 2–3 hours
**Deliverable**: A 3–4 page deployment plan

---

## The assignment

You've decided (Exercise 01 hopefully informs this) that
SmartRecs needs centralized secret management. Choose Vault or
cloud-native, and design the phased deployment.

If you pick **cloud-native**, the assignment is similar — the
patterns transfer.

## What the plan must cover

1. **Choice justification** — Vault vs. cloud-native. Defend the
   pick in the SmartRecs context (single-cloud AWS, 6 engineers,
   may add a region in 12 months).
2. **Architecture** — for Vault: HA topology, storage backend,
   unseal mechanism. For cloud-native: cross-account access
   model.
3. **Auth methods** — which auth methods you enable, for whom.
   At minimum: Kubernetes auth for workloads, OIDC for CI,
   userpass-or-OIDC for humans.
4. **Engines** — which engines you mount and where:
   - KV-v2 (static secrets).
   - PKI (internal CA — if not using SPIRE).
   - Transit (application-layer encryption).
   - Database (dynamic credentials).
   - AWS / GCP / Azure (dynamic cloud credentials).
5. **Policies** — at least 5 example policies tied to specific
   workload identities from Module 02.
6. **Operational concerns** — backup, disaster recovery,
   upgrade cadence, monitoring, runbooks.
7. **Migration from current state** — phased plan from "secrets
   in Kubernetes Secrets" to "secrets in Vault, accessed via
   workload identity."
8. **What stays out of Vault** — secrets that won't be Vault-
   managed (third-party CI integrations, etc.), with rationale.

## Phasing

The migration must be **phased**, not big-bang. Suggested
phasing:

- **Phase 0**: Stand up Vault, no workloads using it.
- **Phase 1**: Onboard one low-risk secret (e.g., monitoring API
  key) end-to-end.
- **Phase 2**: Onboard a workload class (e.g., training jobs)
  with dynamic database credentials.
- **Phase 3**: Migrate the high-value secrets (signing keys,
  customer-managed keys).
- **Phase 4**: Decommission Kubernetes Secret-based storage for
  anything not transitively legacy.

For each phase: deliverables, success criterion, duration,
rollback.

## Format

```
# SmartRecs Vault Deployment Plan

## Decision: Vault vs. cloud-native (and why)

## Architecture
(Topology, storage backend, unseal, HA, network exposure.)

## Auth methods

| Method | Subjects | Purpose |
|---|---|---|

## Engines

| Engine | Mount path | Purpose | Used by |
|---|---|---|---|

## Policies (5+ examples)

### Policy 1: training-job-recs
(HCL or pseudo-HCL.)
- Workload identity bound
- Capabilities

### Policy 2: ...

## Operations
- Backup
- Disaster recovery
- Upgrade
- Monitoring (what Vault metrics matter)
- Runbooks needed

## Migration phases

### Phase 0: Foundation
### Phase 1: First onboarded secret
### Phase 2: Workload class migration
### Phase 3: High-value migration
### Phase 4: Steady state

## What stays out of Vault

## Risks and mitigations
```

## Quality criteria

A passing plan:

- Defends the Vault-vs-cloud choice in **SmartRecs context**,
  not generically.
- Policies are bound to specific workload identities — not "the
  ML team."
- Phasing is realistic — Phase 1 is small enough to land in 2
  weeks; Phase 4 is months out.
- Acknowledges what stays out of Vault.
- Includes operational runbook needs (not the runbook itself —
  Exercise 03 produces one).

A failing plan:

- "Install Vault" with no phasing.
- Policies are generic ("read all").
- No backup / DR mention.
- Tries to migrate everything at once.

## Reflection questions

1. Which phase is most likely to stall? Why?
2. Which secret class will you find hardest to migrate? Why?
3. The team objects: "Vault is too complex for our size."
   Defend or concede. If conceding, what's the cloud-native
   alternative plan?
