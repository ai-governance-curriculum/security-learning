# Exercise 02 — SPIFFE Workload Identity Plan

**Estimated effort:** ~3 hours
**Deliverable:** One Markdown document containing (a) the SPIFFE ID
scheme, (b) the SPIRE registration entry set, (c) at least two
worked cloud-federation trust policies, and (d) a rotation /
revocation runbook stub.
**Prerequisites:** Chapter 03 read end-to-end. Exercise 01 completed
(the assessment names the workloads that need identity). Familiarity
with your target cloud's IAM federation (AWS `AssumeRoleWithWebIdentity`,
GCP workload-identity pools, Azure federated credentials).

---

## Objective

Design the SPIFFE / SPIRE workload-identity plan for the target
platform. The plan must be executable — someone reading it should
be able to deploy SPIRE, register the workloads, configure cloud
federation, and validate that pods obtain short-lived per-workload
credentials — without further design decisions.

By the end of the exercise you should have a plan that closes the
"ambient node IAM" gap surfaced in exercise 01, replaces every
plane's cloud-credentials source with SPIFFE-federated
short-lived credentials, and gives every workload the SPIFFE ID
that exercise 03's mesh AuthorizationPolicies will match on.

## Problem statement

Continue with the fintech reference platform. The exercise-01
gap assessment surfaces these identity gaps (representative):

- Training pods use a shared cluster service account and inherit
  broad node IAM.
- The MLflow model registry uses a static token stored as a
  Kubernetes Secret.
- Serving pods hard-code an OIDC client secret to talk to the
  enterprise IdP.
- The CI pipeline signs cosign artifacts using a long-lived KMS
  key pinned by service account.
- No cross-cluster identity model exists — the staging and
  production clusters are considered separate trust roots because
  no federation is defined.

If you are working against a real platform, list the equivalent
gaps in one sentence each.

## Requirements

Produce a single Markdown document with the following sections.

### Section 1 — Trust-domain design

- Declare the trust domain(s) — one per security boundary. Justify
  in one paragraph why one domain vs multiple.
- If more than one domain, describe the **federation** relationships
  — which trust bundles each side accepts, how they exchange keys,
  and how they rotate.
- Diagram the SPIRE server topology (server nodes, database,
  DisasterRecovery replicas). Note operational choices: SQL vs
  etcd backing store, HA replica count, dedicated node pool.

### Section 2 — SPIFFE ID scheme

Table:

| Workload | SPIFFE ID | Selector set | TTL |

Rules:

- Every workload from exercise 01 must appear.
- SPIFFE IDs follow a hierarchical convention (`plane/component/…`
  or `ns/namespace/sa/…` — pick one and apply consistently).
- Selectors must be *multi-attribute* — namespace + service
  account + image digest at minimum for high-value workloads.
  Single-selector entries are a fail.
- Do not encode tenant IDs, customer IDs, or secrets in the SPIFFE
  ID — SPIFFE IDs appear in logs.
- TTLs are short (minutes to a small number of hours). Justify
  any TTL longer than 1 hour.

### Section 3 — SPIRE registration entry set

Author the registration entries as YAML or JSON (whichever your
SPIRE distribution consumes). Every workload in Section 2 has an
entry. Include the `parent_id` (the SPIRE agent's SPIFFE ID) and
the full selector set.

- Register at least one **entry with a signed-image-digest
  selector**, so that changing the image redeploys the identity
  claim.
- Register at least one **entry parented to a specific node
  attestor** — for example, an `aws_iid`-parented entry for a
  training node pool tainted to accept only training workloads.
- Include an example of a **short-lived, single-use entry** for a
  one-shot job (e.g., a data-quality job that runs weekly).

### Section 4 — Cloud IAM federation

For each cloud you target (typically AWS + one of GCP / Azure),
author the trust policy that federates from SPIRE's OIDC issuer
to a workload role. At least two worked examples — for example:

- **Training** SPIFFE ID → AWS IAM role that reads the training
  bucket only.
- **CI cosign signer** SPIFFE ID → GCP KMS `signer` role for the
  cosign key, and nothing else.

Rules:

- Every trust policy names the SPIFFE ID exactly, not with
  wildcards.
- Every role's *action set* is scoped to the minimum required
  operations and resources.
- Include the SPIRE-side JWT-SVID audience the workload will
  request and the cloud-side audience matcher (they must agree).
- If the cloud provider's federation uses OIDC discovery, name
  the JWKS URL served by the SPIRE server.

### Section 5 — Mesh integration

Describe how the mesh reads SVIDs (Istio SDS with SPIFFE plugin,
Linkerd identity plugin, or bare Envoy SDS). Reference the
resource names / config you will apply. This section is short —
the important artefact is the mapping. Chapter 04 will consume
the SPIFFE IDs directly.

### Section 6 — Rotation and revocation runbook stub

Author a runbook stub that covers:

- **Routine rotation** — the SPIRE-managed SVID rotation schedule
  and what a workload does when the SVID rotates during a request.
- **Emergency revocation** — the procedure for removing a
  registration entry, its expected time-to-effective (bounded by
  the TTL), and the compensating detection content mod-111 SecOps
  should have in place.
- **Trust-bundle rotation** — SPIRE signing-key rollover, how
  the JWKS is served to cloud STS, and how downstream consumers
  (mesh, cloud) handle the transition.
- **Node attestor compromise** — what happens if the AWS IID
  metadata service or the k8s PSAT verifier is compromised.

## Starter guidance

- Read chapter 03 with the exercise-01 assessment open. Every
  workload the assessment names is a row in Section 2.
- Start with the training plane — it is where ambient node IAM is
  most dangerous, and the wins are largest.
- Do not try to be creative with the SPIFFE ID scheme. Pick one of
  the two conventions in chapter 03 and apply it consistently.
- Cloud federation policies are the row where wildcards creep in.
  Every `sub` and `aud` claim must be exact.
- If a workload cannot be given a SPIFFE ID (e.g., a legacy
  workload on a non-mesh, non-cluster host), record it as
  out-of-scope with a specific remediation ticket for a future
  cycle.

## Acceptance criteria

A passing plan:

- Every workload from exercise 01 has a SPIFFE ID row with a
  multi-attribute selector set.
- At least one entry uses a signed-image-digest selector.
- SPIRE registration YAML / JSON is well-formed and could be
  loaded by the SPIRE server API.
- At least two cloud IAM trust policies are authored end to end,
  with exact `sub` / `aud` matching, no wildcards.
- The rotation / revocation runbook stub covers the four scenarios
  named in Section 6.

A failing plan:

- Uses a single service-account selector (namespace-and-SA only)
  for a high-value workload — a moved pod could masquerade.
- Wildcards on `sub` or `aud` in cloud federation trust policies.
- Multi-tenant SPIFFE IDs that encode the tenant identifier
  directly (e.g., `.../tenant/customer-42`) — those leak to logs
  and telemetry.
- No revocation plan — the SVID TTL is treated as "long enough,
  we'll fix later".

## Stretch goals

- Design a **federation** between the staging and production
  trust domains, including the trust-bundle exchange mechanism
  and the operational cadence for rotation. Explain when to
  federate vs when to consolidate to one domain.
- Extend the plan to include **SPIFFE for CI runners** — the CI
  systems (GitHub Actions, GitLab CI, Buildkite, Tekton) that
  produce signed artifacts. SPIFFE IDs for CI let admission
  policies in exercise 05 verify signatures by SPIFFE identity
  rather than by KMS key ID.
- Author the SPIRE-server node-attestor plugin choice as an ADR:
  which attestor combo (k8s_psat + aws_iid, gcp_iit alone,
  join_token for bare-metal training) and why, with the failure
  mode of each.

## Do not

- Do not paper over a workload's lack of SPIFFE support. If the
  training runtime can't reach a Unix socket, say so and record
  the ticket.
- Do not commit a solution to any repository — solutions live in
  the paired solutions repo.
- Do not use a single-selector registration entry for anything
  beyond a throwaway dev workload.
- Do not raise SVID TTLs to reduce log noise — the noise is the
  proof rotation is working.
