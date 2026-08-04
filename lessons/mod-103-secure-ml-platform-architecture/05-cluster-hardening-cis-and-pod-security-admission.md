# Chapter 05 — Cluster Hardening: CIS Kubernetes Benchmark and Pod Security Admission

> **Note on AI-assisted content.** Pin the CIS Kubernetes Benchmark
> version to the one you have downloaded — recommendation IDs and
> severity ratings change between versions (v1.7, v1.8, v1.9, and so
> on). Pin Pod Security Admission (PSA) levels to the profile as
> defined in the current Kubernetes docs for the cluster's minor
> version. See [`resources.md`](./resources.md).

---

## Why this chapter exists

Chapters 03–04 gave the platform attested identity and layered
segmentation. This chapter hardens the substrate underneath — the
Kubernetes cluster itself. Even a perfect mesh authz policy is
worthless if a compromised pod can escape to the node, or if the
kube-apiserver is misconfigured to accept anonymous requests, or
if the kubelet's read-only port leaks secrets.

Two authoritative sources drive the work:

- **CIS Kubernetes Benchmark.** A prescriptive, versioned set of
  hardening recommendations for each Kubernetes component
  (apiserver, controller-manager, scheduler, etcd, kubelet, and
  policies). Every recommendation carries an ID, a rationale, an
  audit procedure, and a remediation.
- **Pod Security Admission (PSA).** The built-in Kubernetes
  admission controller that enforces the Pod Security Standards
  (Privileged, Baseline, Restricted) at namespace scope. PSA
  replaced PodSecurityPolicy, which was removed in Kubernetes
  1.25.

Both are baseline requirements for a zero-trust ML platform. This
chapter installs the mental model, the concrete controls, and the
exceptions ML workloads typically need — GPU access, hostPath
mounts for accelerator drivers, elevated capabilities for some
model runtimes — and how to grant them safely.

---

## What the CIS Kubernetes Benchmark covers

The benchmark is organised by cluster role:

- **1 — Control Plane Components.**
  - 1.1 Control Plane Node Configuration Files (file perms).
  - 1.2 API Server flags (anonymous auth off, insecure port off,
    audit log configured, TLS ciphers pinned, admission
    controllers enabled).
  - 1.3 Controller Manager flags.
  - 1.4 Scheduler flags.
- **2 — etcd.** File permissions on the etcd data directory, TLS
  auth on client and peer, snapshot encryption.
- **3 — Control Plane Configuration.** Authentication and
  authorisation configuration (client-cert, OIDC, RBAC),
  auditing, security event logging.
- **4 — Worker Nodes.**
  - 4.1 Worker Node Configuration Files.
  - 4.2 Kubelet flags (`--anonymous-auth=false`,
    `--authorization-mode=Webhook`, read-only port disabled,
    `--protect-kernel-defaults=true`, event QPS, cert rotation).
- **5 — Policies.** RBAC and service-account hygiene, PSA
  labelling, NetworkPolicy presence, image-pull secret handling,
  CNI plugin support for policies.

For a self-managed cluster (kubeadm, kubespray, on-prem), you own
every one of the ~120–150 recommendations (count varies by
version). For a managed cluster (GKE, EKS, AKS), the cloud
provider owns the control plane; your responsibility is section
4 (worker node config) and section 5 (policies).

**Cloud-managed benchmarks.** CIS also publishes cloud-specific
benchmarks for GKE, EKS, and AKS. Prefer those over the generic
Kubernetes benchmark when you run on managed clusters — they
tell you which recommendations are the cloud provider's
responsibility and which are yours.

### The kube-bench tool

Aqua Security's `kube-bench` is the practical way to audit the
benchmark. It ships in-cluster as a Job or DaemonSet, executes
the audit commands for every recommendation applicable to the
node, and reports PASS / FAIL per ID.

Reference workflow:

1. Deploy `kube-bench` as a Job that targets your cluster's
   deployment type (`kubeadm`, `gke`, `eks`, `aks`, `rke`, etc.)
   and version.
2. Extract the report; commit it to the security-evidence bucket
   (mod-104 lineage territory) tagged with cluster ID and date.
3. Feed FAIL rows into the platform-engineering backlog with the
   CIS ID as the ticket identifier.
4. Re-run monthly; failed rows should not regress silently.

Example command (kubeadm cluster on the control plane node):

```bash
kubectl apply -f https://raw.githubusercontent.com/aquasecurity/kube-bench/main/job.yaml
kubectl logs job/kube-bench > kube-bench-report.txt
```

The report includes PASS / FAIL / WARN rows keyed by the CIS
recommendation ID (e.g., `1.2.15`, `4.2.6`).

---

## The high-value CIS recommendations to prioritise

You will not fix all ~150 rows on day one, and a few of them are
platform-specific in ways that require negotiation with the ops
team. Prioritise these:

- **1.2.1 — Ensure that the `--anonymous-auth` argument is set to
  `false`.** Anonymous requests to the kube-apiserver should be
  denied. If a health check depends on it, use a service account
  instead.
- **1.2.6 / 1.2.7 — TLS ciphers pinned to secure suites.**
- **1.2.11 — Ensure the admission control plugin `AlwaysAdmit` is
  not set.** `AlwaysAdmit` disables every subsequent admission
  check.
- **1.2.14 — Ensure the admission control plugin
  `ServiceAccount` is set.** Otherwise pods get no service-
  account token and RBAC breaks.
- **1.2.15 — `NamespaceLifecycle`** is set — otherwise deleted
  namespaces leave orphaned resources.
- **1.2.16 — `NodeRestriction`** is set — kubelets can only
  modify their own node and only pods bound to that node.
- **1.2.17 — Ensure the audit log path is set.**
- **1.2.18–1.2.20 — Audit log max age / max backup / max size.**
  Audit logs are the primary evidence for mod-111 SecOps.
- **3.2.1 — Minimize the admission of privileged containers**
  (redundant with PSA restricted, but still tested).
- **4.2.1 — Ensure that the `--anonymous-auth` argument is set to
  `false` (kubelet).**
- **4.2.6 — Ensure that the `--protect-kernel-defaults` argument
  is set to `true`.**
- **4.2.7 — Read-only port is disabled** (`--read-only-port=0`).
- **5.1.5 — Ensure that default service accounts are not actively
  used.** Every pod should have its own service account.
- **5.1.6 — Ensure that Service Account Tokens are only mounted
  where necessary** (`automountServiceAccountToken: false` by
  default).
- **5.2.x — Pod Security Standards enforced via labels** (see
  next section).
- **5.3.x — Every namespace has a default-deny NetworkPolicy.**

For a full production ML cluster you will also implement 1.1.x
file-permission and 4.1.x file-permission rows; these are largely
mechanical.

---

## Pod Security Admission — the three levels

Pod Security Admission (PSA) is a namespace-scoped enforcement of
the **Pod Security Standards**. Three profiles, tightening in
order:

| Level | Intent | Typical fit |
| --- | --- | --- |
| `privileged` | No restrictions | System namespaces only (kube-system) |
| `baseline` | Minimally restrictive; prevents known escalations | General-purpose workloads that need some flexibility |
| `restricted` | Heavily restricted; follows current pod-hardening best practice | Default target for application workloads |

The `restricted` profile requires, among others:

- No privileged containers, no `hostPID`, `hostNetwork`,
  `hostIPC`.
- `allowPrivilegeEscalation: false`.
- Drop all capabilities; add only `NET_BIND_SERVICE` if needed.
- Read-only root filesystem where possible.
- Run as non-root; specify `runAsUser`, `runAsGroup` explicitly.
- Seccomp profile set to `RuntimeDefault` or a stricter localhost
  profile.
- No hostPath volumes.
- Volumes limited to `configMap`, `csi`, `downwardAPI`,
  `emptyDir`, `ephemeral`, `persistentVolumeClaim`, `projected`,
  `secret`.

Labels on the namespace set the profile:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: serving
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: v1.29
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/audit-version: v1.29
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: v1.29
```

Three modes:

- `enforce` — pods violating the level are rejected.
- `audit` — accepted, but violations are logged to the audit log.
- `warn` — a warning is returned to the applier.

Recommended posture: `enforce=restricted` on every workload
namespace; `audit=restricted` and `warn=restricted` matching, so
misconfigurations produce both logs and applier-visible warnings.

### PSA + PodSecurityPolicy — the transition

If your cluster is on Kubernetes 1.24 or earlier, you may still
be using PodSecurityPolicy (PSP). PSP was deprecated in 1.21 and
removed in 1.25. Migration to PSA (plus, where PSA is
insufficient, OPA / Gatekeeper constraints — see chapter 06) is
required. Kubernetes' migration guide walks the mapping between
PSP rules and PSA levels.

---

## ML workloads and PSA — the exceptions

`restricted` is the target for serving pods and most application
pods. ML workloads present four common exceptions.

### GPU / accelerator access

Nvidia GPUs are typically exposed via a device plugin. The
container declares:

```yaml
resources:
  limits:
    nvidia.com/gpu: 1
```

This alone is compatible with `restricted`. But some device
plugins historically required `privileged: true` or extra
capabilities. Verify against the current device plugin version
that these are not needed. If they are, isolate the workload in
a dedicated namespace at `baseline` (never at `privileged`) and
document the exception with an expiry.

### hostPath for driver libraries

Some accelerator toolkits mount driver libraries from
`/usr/local/nvidia` or similar hostPaths. Restricted disallows
`hostPath` volumes. Options:

- Bake the driver libraries into the container image and skip the
  hostPath.
- Move the workload to `baseline` in a narrowly-labelled
  namespace and add an OPA constraint pinning the exact hostPath
  patterns allowed (chapter 06).
- Use a device plugin variant that projects the libraries via a
  Volume that PSA `restricted` permits (`csi`, `projected`).

Prefer the first option; treat the others as tickets.

### Training-runtime elevated capabilities

Some training frameworks (Ray, Horovod, older MPI implementations)
require capabilities like `SYS_PTRACE` or `IPC_LOCK` for shared-
memory work. If genuinely required, move the training namespace
to `baseline` and pin the exact capability set with an OPA
policy that additionally verifies image-signature (chapter 06).

### Model-serving runtimes with mmap on large weight files

Some serving runtimes mmap multi-gigabyte weight files and set
`ulimit -l unlimited`, which may require the `IPC_LOCK`
capability. Same treatment: baseline + OPA-pinned capability
allow-list.

Rule: never use `privileged` for an ML workload. If a runtime
requires `privileged`, replace the runtime.

### Documented exception pattern

For any namespace that runs below `restricted`, produce an
exception record:

```yaml
namespace: training
psa-level: baseline
reason: Ray shared-memory workers require IPC_LOCK.
compensating-controls:
  - image-digest allow-list via Gatekeeper policy
  - dedicated node pool with taint, off-plane workloads scheduled
  - egress restricted to registry + monitoring only
expires: 2026-12-01
owner: ml-platform-team
review-cadence: quarterly
```

Exception records go in the platform's ADR / evidence store. Mod-
109 (governance) references them at audit time.

---

## Cluster-wide hardening beyond CIS and PSA

Additional controls that layer on and that most ML-serving
clusters need:

- **Encryption at rest for etcd.** `EncryptionConfiguration` with
  a KMS provider (mod-105 territory).
- **Audit policy tuned for security events.** Log all mutations
  to RBAC, secrets, admission webhooks, and cluster-scoped
  resources at `Metadata` level; log requests to sensitive
  namespaces at `RequestResponse`. Full-record audit is
  expensive; targeted is not.
- **Image pull with signature verification** at the container
  runtime level (containerd's `image_verifier` or the
  cri-o `signature_policy_file`). This is a runtime-layer
  complement to the admission-time signature check in chapter
  06.
- **Sandboxed workloads.** For third-party model code, consider
  running under a userspace kernel (gVisor) or a lightweight VM
  (Kata Containers). PSA `restricted` reduces container-escape
  surface; sandboxes contain the remaining risk.
- **Kubelet certificate rotation** (`--rotate-certificates=true`
  and `--rotate-server-certificates=true`).
- **etcd backup and restore drill.** Not a hardening step per se,
  but a hardened cluster with unrecoverable etcd is a business-
  continuity failure. Mod-111 owns the drill.
- **Cluster-scoped RBAC audit.** Every ClusterRole that grants
  `cluster-admin`, `impersonate`, `nodes/proxy`, or wildcard
  verbs must be justified. `rakkess`, `kubectl-who-can`, and
  `krane` audit these.

---

## A CIS + PSA hardening sprint plan

A concrete plan for the module's exercise 04 — a 2-week sprint to
close the highest-value gaps.

### Week 1

- Day 1–2 — Run `kube-bench` against each cluster (control plane
  + workers). Store report. Categorise findings by:
  - Automatable fix (kubelet flag, apiserver flag).
  - Config-driven fix (audit policy, RBAC cleanup).
  - Architectural fix (etcd encryption, cert rotation).
- Day 3 — Fix all Level 1 (baseline) apiserver / kubelet flags.
  Test in staging; roll to production behind change-mgmt.
- Day 4 — Enforce audit logging with the security audit policy.
  Ship to SIEM (mod-111).
- Day 5 — Turn on `pod-security.kubernetes.io/warn=restricted`
  cluster-wide; observe which existing workloads warn. Do not
  enforce yet.

### Week 2

- Day 6–7 — Fix warned workloads: drop capabilities, set
  `runAsNonRoot`, add `readOnlyRootFilesystem`.
- Day 8 — Turn on `pod-security.kubernetes.io/audit=restricted`
  cluster-wide.
- Day 9 — Turn on `pod-security.kubernetes.io/enforce=restricted`
  in application namespaces (serving, feature-store). Leave
  training / GPU namespaces at `baseline` with documented
  exceptions.
- Day 10 — Re-run `kube-bench`; publish before / after.

Exercise 04 asks you to run this plan and hand in the artifacts:
the initial and follow-up `kube-bench` reports, the namespace
labelling PR, the exception records, and the audit-policy YAML.

---

## Verification — did the hardening land?

For every recommendation you fixed:

- **Automated re-audit.** `kube-bench` in a scheduled Job.
- **Detection content.** Mod-111 SecOps writes detections for
  regressions — e.g., a new pod applied without PSA labels, a
  RoleBinding granting cluster-admin, a Deployment that drops
  `readOnlyRootFilesystem: true`.
- **Admission-time prevention.** Chapter 06's OPA / Gatekeeper
  constraints are the *preventive* layer that stops these from
  landing at all. Detection is the *fallback*.

The evidence you accumulate — reports, PRs, exception records — is
what mod-109 governance consumes at audit time.

---

## Common failure modes

- **Enforcing `restricted` cluster-wide on day one.** Every
  legacy workload breaks; teams turn PSA off. Roll out
  `warn → audit → enforce` in that order, not simultaneously.
- **Namespace label drift.** A team relabels the namespace to
  `privileged` to unbreak a workload without recording an
  exception. Chapter 06's Gatekeeper policy that inspects
  namespace labels catches this.
- **Skipping the exception record.** A namespace at `baseline`
  with no record is indistinguishable from an accidental
  drop.
- **Fixing kubelet flags on some nodes only.** kube-bench per
  node is essential; a single misconfigured node is the entire
  cluster's exposure.
- **Assuming the cloud provider hardened everything.** Managed
  clusters get you the control plane; workers, RBAC, and PSA
  labels are yours regardless.

---

## The mistakes this chapter is trying to prevent

- **Running any ML workload as privileged.** Not `baseline`, not
  documented exception — actual `privileged: true`. Replace the
  runtime.
- **Using PSP after 1.25.** It is gone. Either you are on PSA or
  you are unenforced.
- **Skipping the audit log.** Audit logs are the primary
  evidence for post-incident forensics; without them, mod-111's
  investigation is starving.
- **Manual, one-off audits.** Recommend `kube-bench` on a
  schedule; a single hardening sprint decays without ongoing
  measurement.
- **CIS as a checklist without prioritisation.** Fix the
  high-blast-radius items first (auth, admission plugins, audit
  log). Not the file-permission rows.
- **Ignoring exceptions until audit.** Track them explicitly with
  expiry; every quarter, revisit whether they still apply.

---

## Summary

- CIS Kubernetes Benchmark is the prescriptive hardening
  reference for the cluster substrate. `kube-bench` is the
  practical auditor. Prioritise auth-related and admission-plugin
  rows first.
- Pod Security Admission (PSA) enforces the Pod Security
  Standards at namespace scope. Three levels: `privileged`,
  `baseline`, `restricted`. Target `restricted` for application
  namespaces; use `baseline` with documented exceptions where
  ML runtimes require elevated capabilities.
- Never use `privileged` for ML workloads. If a runtime requires
  it, replace the runtime.
- Exception records are mandatory when a namespace runs below
  `restricted`. They carry an expiry, compensating controls, and
  an owner.
- Roll out PSA `warn → audit → enforce`, not all at once.
- Audit logs, `kube-bench` reports, exception records, and PSA
  labels are the evidence set mod-109 governance and mod-111
  SecOps consume.
