# Module 08 — Runtime Security for ML Systems

> **Note on AI-assisted content.** Drafted with AI assistance and
> under human review. Specific tool behavior (Falco rule syntax,
> Tetragon TracingPolicies, kernel features) changes; verify with
> upstream docs. See [`resources.md`](./resources.md).

---

## 1. The threat model for runtime

Preventive controls (Modules 02-04) work most of the time. The
question is what happens when they don't. Threats that get to
runtime:

- **Admission bypass** — a pod was admitted via a path the
  policy didn't cover (privileged operator, broken policy,
  legacy admission).
- **Application-level compromise** — code in a pod runs a
  request that lets an attacker execute arbitrary code (RCE).
- **Supply-chain compromise** — a dependency you installed
  contains a backdoor that activates at runtime.
- **Insider threat** — someone with legitimate access does
  something they shouldn't.
- **Container escape** — an attacker breaks out of a container
  to the host (rare with modern runtimes but possible).

Runtime security has two jobs:

1. **Limit the blast radius** of an in-container compromise
   (containment).
2. **Detect** the compromise so humans can respond
   (observability).

These are different functions; the rest of the module separates
them.

### 1.1 What an attacker in a container can usually do (without
runtime controls)

In a container without seccomp / AppArmor / Pod Security
restrictions:

- Run arbitrary commands as the container's user.
- Make any network connection the network policy allows.
- Read/write any file the container's filesystem allows.
- Make syscalls (including some kernel-attack-surface
  syscalls).
- Possibly access the host kubelet API at `kubelet:10250` if
  network policy doesn't block it.
- Read mounted secrets.
- Use any privileged capabilities the container has
  (`SYS_ADMIN`, etc.).

Each of these is a control surface this module covers.

---

## 2. Pod Security Standards (PSS)

Kubernetes' built-in pod-level restriction framework. Replaced
the older PodSecurityPolicy (PSP) in Kubernetes 1.25+.

### 2.1 The three profiles

| Profile | Posture | Use case |
|---|---|---|
| **Privileged** | No restrictions | System workloads only (CNI, CSI, monitoring agents) |
| **Baseline** | Prevents the most obviously dangerous things | "Default safe" for most workloads |
| **Restricted** | Strict hardening | Production workloads that don't need elevated privileges |

For ML workloads:

- **Serving pods**: Restricted profile is the default. They
  don't need elevated privileges.
- **Training pods**: Often need access to GPUs (specific
  device plugins), which currently requires some elevated
  capabilities. Baseline is realistic; Restricted may not be
  achievable without configuration.
- **System pods** (monitoring agents, log collectors): Need
  Privileged for things like host network or read-only host
  mounts.

### 2.2 How PSS is enforced

PSS is enforced at the **namespace level** via labels:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: recs
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

Three modes per profile:
- **enforce** — pod is rejected at admission.
- **audit** — pod is admitted; violation goes to audit log.
- **warn** — pod is admitted; warning shown to the user.

A defensible rollout starts with `warn` to identify violations,
moves to `audit`, then to `enforce`.

### 2.3 What Restricted blocks (highlights)

- Privileged containers.
- Capabilities beyond a small allowed set.
- `hostPath` volumes.
- `hostNetwork`, `hostPID`, `hostIPC`.
- Running as root user (must specify a non-root user).
- `allowPrivilegeEscalation: false` required.
- ReadOnlyRootFilesystem strongly encouraged.
- Seccomp profile required (`RuntimeDefault` or stricter).

### 2.4 The "we can't go Restricted" cases

Some workloads genuinely can't run Restricted:

- **GPU pods** (NVIDIA device plugin's runtime needs).
- **Privileged DaemonSets** (CNI, storage drivers).
- **Some legacy containers** that hardcode root user.

For each, the right answer is:

- Document the exemption with a reason.
- Apply Baseline (not Privileged) where possible.
- Isolate exempted workloads in their own namespace with
  scrutiny.
- Periodically re-evaluate (vendor updates may remove the
  need).

---

## 3. Seccomp profiles

Seccomp restricts the syscalls a process can make. A pod with a
strict seccomp profile cannot use syscalls outside its profile,
even if the application code attempts them.

### 3.1 RuntimeDefault

Kubernetes ships with `RuntimeDefault` — a sensible-default
seccomp profile from the container runtime (containerd /
CRI-O). It blocks ~50 syscalls that are commonly used in
exploits and rarely needed by applications.

**Enable RuntimeDefault for every pod** unless you have a
specific reason not to:

```yaml
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
```

This is one of the highest-leverage configurations in the
module — small change, large reduction in attack surface.

### 3.2 Custom seccomp profiles

When you need tighter restrictions:

1. **Profile generation tools** (`syscall2seccomp`, Inspektor
   Gadget) capture syscalls during a representative run.
2. **Profile** the application, generate a profile.
3. Apply via `localhostProfile`.
4. Test extensively — seccomp violations can crash processes
   without obvious cause.

For ML serving pods: a custom profile that disallows everything
except the small set of syscalls Python + PyTorch + Uvicorn
actually use. The reduction in attack surface is substantial.

### 3.3 The downside

Tight seccomp profiles are brittle. Application changes (new
library, framework upgrade) can introduce syscalls the profile
blocks. Production tuning is required.

---

## 4. AppArmor and SELinux

Mandatory Access Control (MAC) systems at the kernel level.
Where seccomp restricts syscalls, MAC restricts what a process
can do (files it can access, networks it can talk to).

### 4.1 AppArmor

Ubuntu/Debian default. Profile-based: each profile defines
what a process can do.

Apply via Kubernetes annotation:

```yaml
metadata:
  annotations:
    container.apparmor.security.beta.kubernetes.io/<container-name>: localhost/<profile-name>
```

(The annotation form has changed across Kubernetes versions;
verify the current syntax.)

### 4.2 SELinux

Red Hat ecosystem default. More expressive than AppArmor;
correspondingly harder to profile.

For most production ML platforms running on EKS / GKE / AKS,
AppArmor is the more common choice. SELinux is more common on
OpenShift and RHEL-based deployments.

### 4.3 The reality

Custom AppArmor / SELinux profiles for ML workloads are rare in
production because:

- Profile generation is operationally expensive.
- Vendor-supplied containers don't ship with profiles.
- Profile violations are hard to debug.

The realistic posture: **rely on RuntimeDefault seccomp + Pod
Security Restricted**, and use AppArmor only for high-stakes
workloads where the engineering investment is justified.

---

## 5. Falco: runtime detection

Falco (CNCF graduated project) is the production default for
runtime detection in Kubernetes.

### 5.1 How Falco works

- A kernel module or eBPF program intercepts syscalls.
- A user-space process matches syscalls against rules.
- Matches produce events: alerts, logs, integrations.

The intercept layer doesn't *block* by default — Falco is a
**detection** tool. Some deployments use Falco events to trigger
external response (e.g., quarantine a pod), but the
intercept-and-decide architecture isn't built for blocking.

### 5.2 Anatomy of a Falco rule

```yaml
- rule: Write below etc
  desc: an attempt to write to any file below /etc
  condition: write_etc_common
  output: >
    File below /etc opened for writing (user=%user.name
    command=%proc.cmdline parent=%proc.pname file=%fd.name
    program=%proc.name)
  priority: ERROR
  tags: [filesystem, mitre_persistence]
```

Components:
- **rule name** — unique identifier.
- **desc** — human-readable description.
- **condition** — when to fire. Can use built-in macros
  (`write_etc_common`) or raw syscall predicates.
- **output** — the message template.
- **priority** — debug / info / notice / warning / error / critical.
- **tags** — for filtering and MITRE mapping.

### 5.3 The default ruleset

Falco ships with a substantial default ruleset covering:

- Filesystem writes outside expected paths.
- Privileged container detection.
- Shell spawned in container (common post-exploitation signal).
- Sensitive mount detection.
- Outbound connections to suspicious destinations.
- Anomalous executions in containers.

The default ruleset is the **starting point**, not the end. Tune
for your environment.

### 5.4 Writing ML-specific Falco rules

A subset of rules that matter for ML platforms:

```yaml
- rule: Unexpected write to model directory
  desc: A process wrote to the model artifact directory
        outside the expected loader
  condition: >
    open_write and
    fd.name startswith /models and
    not proc.name in (model_loader_processes)
  output: >
    Unexpected write to model directory (file=%fd.name
    process=%proc.cmdline container=%container.name)
  priority: CRITICAL
  tags: [ml, model_integrity]

- rule: Training job egress to unknown destination
  desc: A training pod connected to a destination not in
        the expected list
  condition: >
    outbound and
    container.image startswith training_image and
    not fd.sip in (training_allowed_destinations)
  output: >
    Training job unexpected egress (destination=%fd.sip
    container=%container.name)
  priority: WARNING
  tags: [ml, egress, exfiltration]

- rule: Notebook process attempting to bind low port
  desc: A notebook container attempted to bind a privileged
        port
  condition: >
    evt.type = bind and
    container.image startswith notebook_image and
    fd.lport < 1024
  output: >
    Notebook binding privileged port (port=%fd.lport
    container=%container.name)
  priority: WARNING
  tags: [ml, notebook, anomaly]
```

The patterns:

- **Filesystem integrity**: writes to paths that should be
  read-only.
- **Egress anomalies**: connections to destinations not in the
  allow-list.
- **Process anomalies**: shells, package managers, debuggers
  in production containers.
- **Privilege anomalies**: workloads attempting actions outside
  their expected capability set.

### 5.5 Falco operational concerns

- **Performance**: the kernel-module path has higher overhead
  than the eBPF path. Use eBPF for production.
- **False positives**: the default ruleset will alert on
  legitimate operational activities (kubectl exec for
  debugging, image pulls, etc.). Tune.
- **Alert volume**: a default Falco deployment can produce
  thousands of alerts per day. Without triage, this is noise.
- **Integration**: Falco events go to stdout by default. For
  production, use the Falcosidekick to route to SIEM, Slack,
  PagerDuty.

---

## 6. eBPF and Tetragon

The next generation of runtime security tooling. eBPF programs
run in the kernel without requiring custom kernel modules;
Tetragon is one of the leading eBPF-based security tools.

### 6.1 Why eBPF matters

- **Lower overhead** than kernel-module-based tools.
- **No custom kernel** required (works on stock Linux 5.x+).
- **More instrumentation surface** than syscall hooks alone —
  network, process lifecycle, file IO at semantic levels.
- **Stronger inline action capability** — eBPF programs can
  block syscalls, kill processes, drop connections.

### 6.2 Tetragon

CNCF sandbox project from Isovalent (the Cilium folks). Features:

- **TracingPolicies** — CRDs that define what to observe.
- **In-line enforcement** — beyond observation, can kill
  processes or block syscalls.
- **Process lineage** — full process tree, not just syscalls.
- **Integration with Cilium** for network-aware policies.

A sample TracingPolicy that observes writes to `/etc`:

```yaml
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: file-monitoring
spec:
  kprobes:
    - call: "security_file_permission"
      syscall: false
      args:
        - index: 0
          type: "file"
        - index: 1
          type: "int"
      selectors:
        - matchArgs:
            - index: 1
              operator: "Equal"
              values:
                - "2"  # MAY_WRITE
            - index: 0
              operator: "Prefix"
              values:
                - "/etc/"
```

This is more expressive than Falco rules but also more complex.

### 6.3 Falco vs. Tetragon

| Factor | Falco | Tetragon |
|---|---|---|
| **Maturity** | Production for years | Newer, but rapidly maturing |
| **Rule expressiveness** | Domain-specific language | Kubernetes-native CRD |
| **Performance** | Good (eBPF mode) | Better |
| **Inline enforcement** | Limited | Strong |
| **Integration** | Wide (Falcosidekick) | Tight with Cilium |
| **Default ruleset** | Comprehensive | Smaller (newer project) |

For a 2026-era greenfield deployment, Tetragon is increasingly
compelling, especially if you're on Cilium. For a deployment
with existing Falco rules, the migration cost is real.

### 6.4 Cilium Network Observability (Hubble) revisited

Module 04 mentioned Hubble. The runtime-security overlap: Hubble
captures L3/L4/L7 flows; Tetragon captures process and file
events. Together they're a comprehensive eBPF-based runtime
observability stack.

---

## 7. Sandboxing — gVisor, Kata Containers

When the threat model includes "containers themselves are not
sufficient isolation," sandboxing provides VM-grade isolation.

### 7.1 gVisor

Google's user-space kernel implementation. Containers run
against gVisor instead of the host kernel; gVisor implements
most Linux syscalls in user-space, dramatically reducing the
kernel attack surface.

Trade-offs:
- **Performance**: 5-30% overhead depending on workload.
- **Syscall compatibility**: most things work; some edge cases
  don't.
- **GPU support**: limited. Most ML workloads using GPUs can't
  run on gVisor today.

For ML platforms, gVisor is realistic for **non-GPU workloads**:
serving pods that don't use GPU (CPU inference), governance
pods, audit pods.

### 7.2 Kata Containers

OCI-compatible containers that run inside lightweight VMs.
Stronger isolation than gVisor; comparable overhead.

Trade-offs:
- **VM-grade isolation** — true kernel separation.
- **Performance**: similar to gVisor.
- **GPU support**: better than gVisor; supported via vGPU.
- **Storage / networking**: works via standard CNI / CSI plugins.

For ML platforms running customer-isolated workloads (a
multi-tenant LLM platform where each tenant gets its own
inference), Kata is increasingly attractive.

### 7.3 When sandboxing is worth it

- **Multi-tenant environments** where one tenant's workload
  could attack another via shared kernel.
- **Untrusted user code** — Jupyter notebooks running arbitrary
  Python with broad library access.
- **Regulated workloads** where the threat model includes
  cloud-provider operators or co-tenants.

For **single-tenant production serving** with well-controlled
images, sandboxing usually isn't justified — the cost outweighs
the benefit.

---

## 8. Behavioral analytics

Rules detect *known* patterns. Behavioral analytics detects
*deviations* from baseline.

### 8.1 The pattern

1. Establish a baseline of normal behavior over a learning
   window (typically 1-4 weeks).
2. Define the dimensions to baseline:
   - Per-workload syscall frequencies.
   - Per-workload outbound destinations.
   - Per-workload process tree depth.
   - Per-workload CPU/memory profile.
   - Per-workload network connection patterns.
3. At runtime, compare current behavior to baseline.
4. Alert on statistically-significant deviations.

### 8.2 Why it matters

Rules catch known attacks. They don't catch novel attacks. An
attacker doing something the rule authors didn't anticipate
will not trigger a rule but may trigger a behavioral alert.

For ML platforms specifically: the *types* of deviations that
matter:

- A serving pod that's normally CPU-bound suddenly making heavy
  outbound calls (data exfiltration?).
- A training job that normally talks to S3 suddenly talking to
  arbitrary external IPs.
- A governance pod that normally only reads suddenly writing.
- A notebook that's normally idle 80% of the time suddenly
  running at 100% CPU 24/7 (cryptomining?).

### 8.3 Tools

- **Falco** has limited behavioral support; mostly rule-based.
- **Tetragon** + a baseline-builder is more flexible.
- **Cilium** Hubble flows + a behavioral analyzer.
- Commercial: Sysdig Secure, Aqua, Wiz Runtime, Lacework all
  include behavioral analytics.
- Custom: Hubble flow logs → Prometheus → alert rules on
  deviations.

### 8.4 Operational realities

- **Baseline drift** is real — workloads evolve, baselines
  need re-learning.
- **Per-pod baselines** vs. **per-deployment baselines** — pods
  are ephemeral; baselines should be at the deployment level.
- **Confidence intervals** matter — alerting on 1σ deviations
  produces noise; 3σ is more useful.
- **The cold-start problem** — a new workload has no baseline.
  How do you behave for the first week?

---

## 9. ML-specific runtime threats and detections

A catalogue of patterns specific to ML platforms.

### 9.1 Model file tampering

A process writes to a model artifact file outside the expected
loader. Could be:
- An attacker modifying a model in place to install a
  backdoor.
- A legitimate update that wasn't routed through the registry.
- A bug in the artifact-handling code.

Detection: Falco rule on `open_write` to the model directory,
where the writing process is not in an allowlist.

### 9.2 Training-job egress anomalies

A training job that normally reads from the data warehouse
suddenly tries to call `api.openai.com`. Could be:
- Exfiltration via embedded model call.
- A bug.
- Legitimate but undocumented dependency.

Detection: per-training-job egress baseline + Cilium FQDN
policy enforcement (deny unexpected destinations).

### 9.3 GPU misuse (cryptomining or unauthorized workloads)

A pod that's supposed to be idle is running at 100% GPU
utilization. Could be:
- A legitimate but undocumented workload spike.
- Cryptomining via a compromised container.
- A misconfigured retraining job.

Detection: GPU utilization baseline per workload + alerts on
sustained high utilization outside expected windows.

### 9.4 Notebook abuse

A notebook installs a package from an unusual source, makes
heavy outbound calls, or attempts to access production data.

Detection:
- Egress monitoring on notebook namespaces.
- Audit logging of `pip install` commands (via shell
  monitoring).
- Anomaly detection on data access patterns.

### 9.5 Embedded reverse shells

Standard post-exploitation pattern: an attacker establishes a
reverse shell from a compromised pod.

Detection: Falco rule for shell processes (`bash`, `sh`,
`python -i`) in production containers, especially production
serving pods that should never spawn shells.

### 9.6 Container escape attempts

An attempt to escape from a container to the host.

Detection: Falco / Tetragon rules for known escape patterns
(mount namespace manipulation, `nsenter`, suspicious `setns`
calls).

---

## 10. Operating runtime security at scale

Alert volume is the chronic problem.

### 10.1 The alert pyramid

A well-tuned runtime-security setup has alerts at multiple
priority levels:

| Priority | Examples | Response time |
|---|---|---|
| **Critical** | Container escape attempt, shell in production serving | Page immediately |
| **High** | Privileged container admitted, sensitive mount, suspicious egress | On-call within 1 hour |
| **Medium** | Unexpected process in container, baseline deviation | Next business day |
| **Low** | Configuration drift, missing label | Weekly review |

Without this layering, every alert is treated equally, which
means few alerts are treated seriously.

### 10.2 Triage tooling

A typical runtime-security triage flow:

1. **Alert** fires in Falco / Tetragon.
2. **Falcosidekick** (or equivalent) routes to:
   - PagerDuty for Critical.
   - Slack channel for High.
   - SIEM for Medium / Low (review later).
3. **On-call engineer** investigates Critical/High using:
   - Audit chain to see what else happened around the time.
   - Kubernetes audit log for the pod's history.
   - Application logs.
   - Network flow logs.
4. **Decision**: false positive (tune rule), known issue,
   real incident.

### 10.3 Reducing alert volume

- **Tune the default ruleset** — disable rules that don't
  apply or that produce constant noise.
- **Add workload-specific allowlists** — `kubectl exec` in
  development namespaces is expected; in production, it's a
  signal.
- **Use rule priorities** — distinguish "informational" from
  "actionable."
- **Suppression windows** — when doing planned maintenance,
  suppress related alerts.
- **Anomaly batching** — alerting on each minor deviation
  produces noise; batching to alert on patterns reduces it.

### 10.4 Integration with the audit chain

Every runtime-security alert should produce an audit-chain
entry. This is the bridge to the compliance work (Module 07):
the audit chain becomes the forensic record.

For each alert: workload identity, alert rule, signal value,
timestamp, on-call response.

---

## 11. The realistic posture for SmartRecs-scale platforms

A 6-engineer team can't operate a sophisticated runtime-security
stack at the level of an enterprise SOC. The realistic posture:

### 11.1 Day 1 (cheap, high-value)

- **Pod Security Standards: Restricted** for production
  namespaces; Baseline for training; Privileged only where
  documented.
- **Seccomp: RuntimeDefault** everywhere.
- **Falco with default ruleset** + a handful of
  ML-specific rules.
- **Alerts** routed to Slack; one engineer reviews weekly.

### 11.2 Day 30 (modest investment)

- **Falco rule tuning** — remove the noise, keep the signal.
- **A baseline of expected egress** per workload class.
- **Audit-chain integration** of high-priority alerts.

### 11.3 Day 90 (steady state)

- **Behavioral analytics** at least at the network level
  (Hubble flow anomalies).
- **Quarterly review** of rules, removing stale, adding new.
- **Incident-response drills** (tabletop) that include
  runtime-security alerts.

### 11.4 What you don't need at SmartRecs scale

- Tetragon / Cilium-based eBPF stack (unless you're on Cilium
  already).
- Custom seccomp profiles (RuntimeDefault is enough).
- Sandboxing (gVisor / Kata) unless multi-tenant.
- A dedicated runtime-security platform (Sysdig, Aqua, etc.).
- 24/7 SOC monitoring.

---

## 12. What you should be able to do after this module

- [ ] Configure Pod Security Standards at namespace level with
      `warn → audit → enforce` rollout.
- [ ] Enable RuntimeDefault seccomp on every pod.
- [ ] Write a Falco rule that fires on a specific ML-platform
      threat (model file tampering, training-job egress
      anomaly).
- [ ] Tune the default Falco ruleset for false positives.
- [ ] Design a behavioral baseline for a serving workload.
- [ ] Identify which workloads in a platform are candidates for
      gVisor / Kata sandboxing.
- [ ] Write a container-escape response runbook.
- [ ] Integrate runtime-security alerts with the audit chain
      (Modules 03, 07).

---

## 13. What this module deliberately doesn't cover

- **General Linux security** (kernel hardening, system tuning)
  — see books like *Linux Hardening Guide*.
- **OS-level patching cadence** — operational, not in this
  module's scope.
- **SIEM authoring** — Module 11.
- **Specific commercial-product evaluations** — products
  change; principles persist.

---

## 14. Suggested reading order

After this:

1. Skim the [Falco documentation](https://falco.org/docs/).
2. Skim the [Tetragon documentation](https://tetragon.io/docs/).
3. Read about the [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/).
4. Try `kubectl-trace` or `inspektor-gadget` on a real cluster
   for hands-on intuition.
5. Move to **Module 09: Policy as Code**.

---

## Appendix A — Glossary

- **AppArmor**: Linux MAC system, profile-based.
- **eBPF**: extended Berkeley Packet Filter; in-kernel
  programmable runtime.
- **Falco**: CNCF runtime-detection tool.
- **gVisor**: user-space kernel implementation for container
  sandboxing.
- **Kata Containers**: VM-isolated OCI runtime.
- **Pod Security Standards (PSS)**: Kubernetes built-in pod
  restriction framework (replaces PSP).
- **PodSecurityPolicy (PSP)**: deprecated predecessor of PSS.
- **Seccomp**: Linux syscall filtering.
- **SELinux**: Linux MAC system, label-based.
- **Tetragon**: CNCF eBPF-based runtime security from Isovalent.
- **TracingPolicy**: Tetragon CRD for observation rules.

---

## Appendix B — Common misconceptions

| Misconception | Reality |
|---|---|
| "Containers are a security boundary." | Containers are an isolation mechanism, not a security boundary. Kernel exploits cross containers. |
| "If admission controls passed, the pod is fine." | Admission is point-in-time; runtime threats develop later. |
| "Runtime security is the same as application monitoring." | Application monitoring tracks application metrics; runtime security tracks attacker-relevant signals. |
| "RuntimeDefault seccomp is enough." | RuntimeDefault is a sensible default. Custom profiles are tighter when the threat model justifies the engineering cost. |
| "Falco blocks attacks." | Falco detects; some integrations enable response. The architecture is detection-first. |
| "We have a SIEM, so we have runtime security." | SIEM stores and queries events; runtime security produces them. |
| "Behavioral analytics is just ML." | Statistical baselines + thresholds is what most "behavioral" tools do. ML-based behavioral analytics adds value but adds complexity. |

---

*Continue to the [exercises](./exercises/) when you're ready.*
