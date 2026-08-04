# Exercise 02 — Vault Dynamic Secrets Plan

**Estimated effort:** ~2 hours
**Deliverable:** A design document consisting of (a) the
Vault topology diagram for the target platform, (b) the
per-secret migration plan from exercise 01's inventory to
Vault (dynamic where possible, KV where not, with rationale),
(c) sample HCL policies and role definitions, and (d) a
rollout sequence that will not break production.
**Prerequisites:** Exercise 01 complete (the inventory drives
this document). Chapter 02 read end-to-end. Familiarity with
one of Vault OSS / Vault Enterprise / OpenBao or an
equivalent cloud secrets manager (AWS SM, GCP SM, Azure KV).

---

## Objective

Design the target-state secrets store for the ML platform
carried through mod-101 → exercise 01. The design must:

- Convert every `long-lived-credential` gap from the
  inventory to a dynamic-issuance flow or, where the
  underlying system does not support dynamic issuance,
  document the KV-with-rotation fallback.
- Enforce environment isolation at the topology layer, not
  the policy layer alone.
- Give every ML workload a Vault identity attributable in
  the audit log to the workload (not to a shared role).
- Roll out without an outage.

By the end you should have a document a platform SRE can
execute against, and an audit-log detection plan a security
analyst can consume from day one.

---

## Problem statement

Take the inventory from exercise 01 as the input. The target
platform runs on GKE with three environments (`dev`,
`staging`, `prod`) and two prod regions
(`us-central1`, `europe-west1`). Vault is not yet deployed;
the org has a preference for OSS tooling but no hard
constraint. The relevant data-store systems are Snowflake,
Redshift, Redis (feature store online), S3 (feature store
offline + model artifacts), MLflow, and an OCI registry.

---

## Requirements

### Section 1 — Vault topology

A diagram (Mermaid / ASCII / image) showing:

- The Vault cluster shape — number of nodes, storage backend
  (Raft integrated storage assumed), seal mode (auto-unseal
  via cloud KMS is the default recommendation).
- Namespace or per-cluster separation per environment
  (Enterprise namespaces vs OSS separate clusters —
  justify).
- Auth mounts per Kubernetes cluster.
- Secrets engines mounted per namespace: database, aws,
  gcp, kv-v2, pki.
- Audit devices and where the audit stream lands (must be
  off-cluster).
- DR/HA topology and how a region failure is handled.

Provide a **decision log** section explaining choices:
Enterprise vs OSS, auto-unseal cloud choice, HA replica
count, DR replication mode.

### Section 2 — Per-secret migration plan

For every secret in exercise 01's inventory table, one row:

| Secret ID (from exercise 01) | Class | Current store | Vault engine | Vault path | Dynamic or KV | If KV, rotation cadence + automation | If dynamic, role definition file | Consumer(s) | Cutover method | Rollback method |

Rules:

- **Every DB credential is dynamic**, or the row has a
  written justification for why not.
- **Every cloud IAM credential** used by long-running
  workloads is either dynamic (Vault AWS/GCP/Azure engine)
  or federated (exercise 04 territory — cross-reference).
- **Every KV entry** has a rotation cadence AND a rotation
  automation plan; a KV entry with "manual, quarterly" and
  no calendar is a gap.
- **Consumer** is the specific Kubernetes SA / SPIFFE ID
  reading the secret, not the vague team name.
- **Cutover method** is one of: `Vault Agent sidecar`,
  `Vault Secrets Operator CRD`, `Secrets Store CSI driver`,
  `direct SDK call`. Pick one per workload class and be
  consistent.
- **Rollback method** describes what happens if the Vault
  path is unavailable — fail closed (workload does not
  start), fail with cached credential (allowed for a
  bounded window), or fail open (never — call it out as an
  unacceptable design).

### Section 3 — Sample HCL policies and role definitions

For at least three workload classes (training pod, eval
harness, CI-triggered deploy), author:

1. The Vault Kubernetes auth role definition (`vault write
   auth/kubernetes/role/<name> …`).
2. The HCL policy attached to that role — leaf paths only,
   explicit denies for cross-team paths.
3. The database or KV engine configuration the policy
   grants access to.
4. The Vault Agent injector / VSO / CSI configuration the
   workload uses.

The three files together should be pastable into a Vault
cluster and work.

### Section 4 — Audit and detection plan

For the Vault audit device:

- Where does the audit stream go? (Off-cluster storage;
  chapter 04 mod-104 WORM sink is the reference.)
- Which four detections from chapter 02 are enabled?
  - Read-rate anomaly per KV path.
  - Denied paths with workload identity.
  - Root-token use.
  - Auth-method config change.
- Who is paged on each? (Chapter 05 on-call.)
- What is the retention on the audit stream?

### Section 5 — Rollout sequence

Order the migration so production does not break. A reference
sequence (adapt):

1. Deploy Vault into non-prod first; migrate `dev` secrets;
   verify.
2. Add `staging` secrets; run staging workloads through
   Vault for at least one week; look for lease-renewal
   failures.
3. For prod, migrate class-by-class in decreasing order of
   redundancy — start with credentials that have alternate
   auth paths (so cutover failures don't cause outages).
4. Migrate the last classes only after two clean weeks of
   the earlier classes.
5. Delete the old credentials (chapter 05 phase 3 verify).

State the pre-conditions for each stage advance ("staging
has run seven days without a Vault-related failure").

## Starter guidance

- Do not attempt to author every policy in one pass — three
  representative workload classes are the acceptance
  requirement; the pattern generalises.
- Start with the highest-value dynamic engine — the DB
  engine — because it delivers the largest per-secret
  security improvement per unit of migration effort.
- For any external-API secret that must remain KV (chapter
  01 class 4/6), the rotation-automation plan is the
  interesting part — describe the script, the trigger, the
  provider API called, the failure mode.
- For Kubernetes auth, remember that **one auth mount per
  cluster**, not one shared mount, is the invariant.
  Justify any deviation.
- For the topology, do not over-engineer. A single-region
  Vault with cross-region DR replication is usually enough;
  every extra piece is more to run.
- The audit stream is not optional. If the platform does not
  have a WORM sink from mod-104 chapter 06, the plan
  references that dependency; do not skip it.

## Acceptance criteria

A passing document:

- Contains a topology diagram with all decisions justified.
- Migration table has one row per secret from exercise 01
  and no blank cells.
- Sample HCL for three workload classes is complete and
  self-consistent (paths in policy match paths in engine
  config).
- The audit / detection plan names the destination sink and
  the four chapter-02 detections with a pager assignment
  each.
- Rollout sequence has explicit pre-conditions per stage
  advance, not "then we do prod".
- Every KV-remaining secret has both a rotation cadence AND
  a rotation-automation plan.
- Any deviation from chapter-02 defaults (shared auth
  mount, long TTLs, KV where dynamic is possible) is
  justified in a written decision log.

A failing document:

- Uses a wildcard path in a Vault policy without a written
  justification.
- Has any workload sharing a Vault role with another
  workload.
- Skips the audit device or WORM sink.
- Uses TTLs longer than one hour on dynamic credentials
  without justification.
- Contains a rollout plan that migrates prod before staging.
- Leaves the migration of external-API keys as "TBD" — the
  KV-with-rotation fallback is a real plan.

## Stretch goals

- **Break-glass rehearsal script.** Author the script an
  on-call SRE would run to recover from Vault unavailability
  — how to reach the sealed break-glass credentials, how to
  re-issue a single high-priority credential, how the
  incident is filed.
- **Vault-to-Kubernetes-Secret sync.** For applications that
  cannot be modified to speak Vault directly, design the
  Vault Secrets Operator flow that syncs a KV path to a
  Kubernetes `Secret` on rotation. Include the trade-off
  discussion (the K8s `Secret` is still base64 and still
  readable by `get secrets` — the sync is a compatibility
  bridge, not equivalent to native Vault integration).
- **Cross-region failover exercise.** Describe what happens
  when the primary Vault region is unavailable during a
  training run — does the training pod's sidecar reach the
  DR region, or does the training fail? What is the RTO on
  re-establishing the primary?
- **OpenBao migration plan.** If the org may move from Vault
  to OpenBao (or has explicitly chosen OpenBao), add a
  section on the migration compatibility.

## Do not

- Do not author the KMS / envelope-encryption piece
  (exercise 03).
- Do not author the keyless-CI OIDC roles (exercise 04).
- Do not author the leak-response runbook (exercise 05).
- Do not commit real HCL that would apply to a live Vault
  cluster in this repo — the deliverable is a plan
  document, not a Terraform module.
- Do not include real credentials, real ARNs of prod
  resources, or real cluster identifiers — placeholders
  only.
- Do not commit a solution here — the paired solutions repo
  is where solutions live.
