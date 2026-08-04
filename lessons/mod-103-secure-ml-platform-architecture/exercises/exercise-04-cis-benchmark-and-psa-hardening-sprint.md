# Exercise 04 — CIS Benchmark and Pod Security Admission Hardening Sprint

**Estimated effort:** ~3 hours (plan-and-execute; the full sprint
in chapter 05 is a 2-week engagement — this exercise scopes an
end-to-end pass on a representative cluster you can iterate on
in the lab).
**Deliverable:** One directory containing (a) the `kube-bench`
report before and after remediation, (b) the namespace-labelling
manifest that turns on PSA `restricted` (or `baseline` with
exception records), (c) the exception records for any namespace
below `restricted`, and (d) a change-log Markdown that names every
CIS ID closed and every ticket left open.
**Prerequisites:** Chapter 05 read end-to-end. Exercises 01–03
completed. A Kubernetes cluster you can operate on — a kind /
minikube / kubeadm setup is fine; a managed cluster is fine but the
control-plane rows will show as "not applicable, managed by
provider" and you will focus on section 4 (worker) and section 5
(policies).

---

## Objective

Execute a scoped CIS Kubernetes Benchmark + Pod Security Admission
hardening pass. Produce the evidence artifact that mod-109
governance and mod-111 SecOps consume, and leave the cluster in a
posture the mod-103 admission gate (exercise 05) can rely on.

## Problem statement

Continue with the fintech reference platform. The relevant
starting state:

- `kube-bench` has never been run against the cluster.
- No PSA labels on any namespace.
- Cluster-admin ClusterRoleBinding bound to the group `mlops`.
- Kubelet flags at Kubernetes distribution defaults.
- No audit-log policy tuned; audit output at default level.
- A subset of ML workloads (training, some serving) needs
  documented exceptions to `restricted`.

If you are working against a real cluster, name the starting state
in one paragraph before proceeding.

## Requirements

Deliver a directory with the following structure:

```
exercise-04/
  reports/
    kube-bench-before.txt
    kube-bench-after.txt
  psa/
    namespace-labels.yaml
    exceptions/
      training.md
      serving-legacy.md
  audit-policy/
    audit-policy.yaml
  changelog.md
  runbook.md
```

Rules:

### 1 — Run the initial audit

Run `kube-bench` against your cluster and save the report as
`kube-bench-before.txt`. Categorise the findings in `changelog.md`
into:

- **Automatable now** — flag-level fixes (kubelet flags, API
  server admission plugins, TLS ciphers).
- **Config-driven** — audit policy, RBAC cleanup, kubeconfig file
  permissions.
- **Architectural** — etcd encryption at rest, kubelet cert
  rotation, admission webhook TLS.
- **Managed by provider (N/A)** — when running on GKE / EKS / AKS.

### 2 — Remediate the priority set

Close, at minimum, the following representative rows:

- 1.2.1 `--anonymous-auth=false` (control plane).
- 1.2.11 `AlwaysAdmit` not enabled.
- 1.2.14 `ServiceAccount` admission plugin enabled.
- 1.2.16 `NodeRestriction` enabled.
- 1.2.17 Audit log path set.
- 1.2.18–1.2.20 Audit log retention.
- 3.2.1 Minimize admission of privileged containers.
- 4.2.1 `--anonymous-auth=false` (kubelet).
- 4.2.6 `--protect-kernel-defaults=true`.
- 4.2.7 Read-only port disabled.
- 5.1.5 Default service accounts not actively used.
- 5.1.6 Service-account tokens mounted only where necessary.
- 5.2.x PSA labels present on every namespace.
- 5.3.x Default-deny NetworkPolicy present in every workload
  namespace.

For every row you close, note in `changelog.md` the specific
change (flag added, resource applied, RBAC binding removed), a
link to the PR / commit, and the follow-up detection content
mod-111 should add.

### 3 — Apply PSA labels

Author `psa/namespace-labels.yaml` that labels each namespace with
the target PSA profile using the `enforce` / `audit` / `warn`
label set from chapter 05. Sequence:

- `warn` label first, cluster-wide, at the target profile.
- Observe warnings for at least one deploy cycle in your notes.
- Add `audit`, then `enforce`, in that order.

Recommended targets:

- `serving`, `feature-store`, `platform-system`, `registry`,
  `istio-system` → `enforce=restricted`.
- `training` → `enforce=baseline` **with an exception record**.
- `kube-system` → `enforce=privileged` (do not touch).

### 4 — Author exception records

For every namespace at a profile below `restricted`, write an
exception record in `psa/exceptions/<namespace>.md` covering:

- The namespace.
- The chosen PSA profile.
- The specific reason (which ML runtime requires which capability).
- Compensating controls (image-digest allow-list, dedicated
  taint-scheduled node pool, egress restrictions).
- Expiry date.
- Owner.
- Review cadence.

An exception without a compensating-control section is a failing
record.

### 5 — Author the audit policy

Author `audit-policy/audit-policy.yaml` covering at minimum:

- All mutations to RBAC (Role, RoleBinding, ClusterRole,
  ClusterRoleBinding) at `Metadata`.
- All mutations to admission webhooks
  (`ValidatingWebhookConfiguration`,
  `MutatingWebhookConfiguration`) at `RequestResponse`.
- All access to `secrets` at `Metadata`.
- Requests to the `training`, `registry`, `serving` namespaces at
  `Metadata` for reads and `Request` for writes.
- Anonymous / system:unauthenticated at `RequestResponse` (should
  be nothing after 4.2.1 is closed; the row is a canary).
- Everything else at `None`.

Deliver the corresponding kube-apiserver flag configuration or
managed-cluster equivalent.

### 6 — Runbook and re-audit

Write `runbook.md` describing:

- How to re-run `kube-bench` on demand and on schedule.
- How to identify regressions (which CIS IDs went from PASS to
  FAIL between runs).
- How to review exception records at the next quarterly cadence.
- How mod-111 SecOps consumes the audit-log output (which
  channel, which SIEM index).

Then re-run `kube-bench` and save `reports/kube-bench-after.txt`.
`changelog.md` closes with the delta table (rows closed, rows
open, remaining tickets).

## Starter guidance

- Kubernetes distribution matters. `kube-bench --benchmark
  cis-1.9` (or your version) picks the right rule set; `kube-bench
  --target gke-1.5.0` if you are on GKE, and so on. Get the
  matching benchmark version.
- The single most impactful change on most clusters is scoping
  the `mlops` cluster-admin binding. Do that early.
- PSA `enforce=restricted` will break workloads that mount
  hostPath, run as root, or need capabilities. Discover these
  with `warn` mode before you enforce; do not skip the observation
  window.
- Managed clusters (GKE Autopilot, EKS Fargate) preset many
  section-1 and section-4 rows. Focus on section 5 (policies) and
  your workload configuration.
- Audit policy is easy to over-log. Start narrow (RBAC, admission,
  secrets, sensitive namespaces); expand only when mod-111 SecOps
  asks.

## Acceptance criteria

A passing hardening pass:

- `kube-bench-before.txt` and `kube-bench-after.txt` both present.
- Every priority-set CIS ID (listed above) is closed in the after
  report (or explicitly marked N/A with justification for managed
  clusters).
- PSA labels applied to every non-system namespace.
- Every namespace below `restricted` has an exception record with
  reason, compensating controls, expiry, owner, and review
  cadence.
- Audit policy YAML is well-formed and consumes the classes above.
- `changelog.md` and `runbook.md` present and complete.

A failing hardening pass:

- Any namespace at `privileged` without an exception record (or
  outside `kube-system`).
- Exception records without expiry or compensating controls.
- `kube-bench-after.txt` shows regressions vs before.
- Audit policy at `None` cluster-wide.
- No re-audit was performed.

## Stretch goals

- Automate `kube-bench` via a `CronJob` that runs weekly, uploads
  the report to the evidence bucket, and posts a delta to a Slack
  / Teams channel. Reference the mod-111 detection content that
  alerts on regressions.
- Add **etcd encryption at rest** with a KMS provider, using
  mod-105's key material. Document the rotation cadence.
- Add **runtime-layer signature verification** in the container
  runtime (containerd's `image_verifier` or cri-o's
  `signature_policy_file`), pointing at the same trust root
  chapter 06's admission gate uses. This is defence-in-depth
  against admission-webhook bypass.
- Author the **PSP → PSA migration record** if the cluster was
  historically on PSP. Include the PSP-to-PSA mapping and any
  OPA / Gatekeeper constraints authored to cover residual gaps
  PSA cannot express.

## Do not

- Do not run `restricted enforce` cluster-wide on day one — every
  legacy workload breaks and teams turn PSA off. Follow the
  `warn → audit → enforce` sequence.
- Do not commit a solution to any repository — solutions live in
  the paired solutions repo.
- Do not accept `privileged: true` for any ML workload. If a
  runtime requires it, replace the runtime — record the ticket.
- Do not skip the exception record — a namespace at `baseline`
  without a record is indistinguishable from an accidental drop
  at audit time.
- Do not invent CIS IDs — quote from the current CIS Kubernetes
  Benchmark document; where a claim cannot be verified, add a
  `<!-- needs-research: ... -->` marker.
