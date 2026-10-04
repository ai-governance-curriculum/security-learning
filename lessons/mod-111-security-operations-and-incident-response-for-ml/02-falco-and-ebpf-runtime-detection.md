# Chapter 02 — Falco and eBPF Runtime Detection for ML Workloads

> **Note on AI-assisted content.** Falco rule syntax
> (fields, macros, output format), the kernel probe surface,
> and the libbpf-based driver all evolve. The rule fragments
> below reflect Falco 0.3x / libs 0.1x shapes current at the
> time of writing; verify every field name against the
> installed `falco --list` output and the project
> documentation in [`resources.md`](./resources.md). cuDNN,
> CUDA, triton-inference-server, and vLLM internals change;
> any procfs path or library-load signal must be re-checked
> against your actual images.

---

## Why this chapter exists

Chapter 01 covered detections at the SIEM — rules that
read structured logs after they left the host. This
chapter is about detections that fire *inside the host*
in near-real-time, using Falco rules evaluated against
eBPF-captured syscalls, kernel events, and container
metadata. These are the detections that:

- Catch a reverse shell *in the training container* two
  seconds after a poisoned pickle executed.
- Flag a serving pod suddenly running `nvidia-smi` in a
  shell when the normal workload never shells out.
- Notice a Jupyter kernel in a training namespace reading
  `/etc/shadow` or writing to the model-registry
  credential path.
- Detect an inference container egressing to an IP outside
  the model's registered dependency set.

Runtime signals complement SIEM content; they are not a
substitute. A SIEM rule for "model-download anomaly" tells
you *that* someone pulled weights; a Falco rule for
"shell in serving pod" tells you *that someone is live
right now on a production serving host*. The response
times are different; the evidence surfaces are different;
the ingest paths are different.

The failure mode this chapter is written against:

> An attacker lands code execution inside a training
> container via a crafted dataset file processed with
> `pickle.load`. The container has broad outbound egress
> and the training-service identity's token mounted. The
> attacker exfiltrates the training corpus and the base-
> model weights, then clears the shell. The SOC's SIEM
> content eventually sees the exfil traffic as a
> flow-volume anomaly four hours later; by then the
> container is gone. A Falco rule that paged on "shell
> executed inside a training pod" would have fired at
> t+0.5s.

You leave this chapter able to:

- Explain how Falco uses eBPF (and before it, a kernel
  module) to capture kernel events and evaluate them
  against declarative rules.
- Author Falco rules in the project's rule DSL — macros,
  lists, rules, output formatting — tuned for
  ML-workload-specific behaviours.
- Pick the small set of ML-workload invariants worth
  detecting on (shell in container, syscall patterns of
  pickle deserialisation, GPU-driver access from an
  unexpected process, egress to unexpected endpoints).
- Ship Falco alerts into the SIEM pipeline chapter 01
  established so a runtime signal participates in the
  same incident workflow as an application-level signal.
- Avoid the common failure modes — rules that break on
  benign framework behaviour, rules without baselines,
  rules whose output format is unparseable downstream.

---

## eBPF and Falco in one page

**eBPF** (extended Berkeley Packet Filter) is a kernel
facility that lets you attach small verified programs to
hook points inside the kernel — syscall entry/exit,
tracepoints, kprobes, uprobes, network ingress / egress,
cgroup events — and collect metadata from each firing
without copying kernel state out via `/proc`. The verifier
guarantees the program terminates and does not read
arbitrary memory, so eBPF programs can run safely in
production kernels at low overhead.

**Falco** is an open-source runtime security engine
(originally from Sysdig; now a CNCF-graduated project)
that uses eBPF to capture a stream of enriched syscall
events — each tagged with the containing pod, container,
image, Kubernetes labels, process ancestry, and more —
and evaluates declarative rules against the stream. When
a rule fires, Falco emits an alert through its output
channels: stdout, syslog, HTTP, gRPC, file, program, or
one of several integrations (Falcosidekick to Slack,
PagerDuty, SIEM, cloud SIEMs).

Falco's three important properties for an ML programme:

- **Container-aware out of the box.** Every event
  carries `k8s.pod.name`, `k8s.ns.name`,
  `container.image.repository`, `container.image.tag`,
  `container.image.digest`. Rules can be scoped to the
  ML-serving namespace without parsing labels.
- **Rules are declarative.** Falco rules read as "if
  this condition on an event is true, emit an alert
  with this message". No procedural logic lives in the
  rule.
- **eBPF probe is modern and portable.** The
  CO-RE-based (Compile-Once, Run-Everywhere) libbpf
  driver works across supported kernel versions without
  rebuilding; the older kernel-module probe is now
  deprecated for most deployments.

Falco is not an exhaustive runtime-security product. It
is a well-focused tool for syscall-level rule evaluation.
For deeper application-level observability, you pair it
with Tetragon (Cilium's eBPF-based policy and tracing
engine), with Tracee (Aqua), or with eBPF-based profilers
written against bcc or libbpf. All of them share the
same substrate; the choice of top-level tool is a
different question from "do we have eBPF-level detection
at all".

### Falco rule anatomy

A Falco rule is a YAML document with four main
constructs:

- **Macros** — reusable boolean expressions over event
  fields. "Container is in the ML serving namespace",
  "process is a shell", "image is from our internal
  registry".
- **Lists** — reusable value lists. "Approved serving
  images", "known tool-call binaries".
- **Rules** — a `rule:` with a `condition:` (a boolean
  expression using macros and raw event fields), an
  `output:` (a template string that constructs the
  alert message), a `priority:` (one of `EMERGENCY` …
  `INFORMATIONAL`), and tags.
- **Exceptions** — scoped allowlists that suppress a
  rule firing for specific legitimate cases.

A canonical shape:

```yaml
- macro: ml_serving_container
  condition: >
    (k8s.ns.name = "ml-serving") and
    (container.image.repository startswith "registry.company.com/ml/")

- list: approved_serving_processes
  items: ["python", "python3", "triton", "vllm", "tritonserver"]

- rule: Shell in ML Serving Pod
  desc: >
    A shell was executed inside an ML-serving pod. These
    pods run a fixed serving binary; a shell is unexpected.
  condition: >
    spawned_process and ml_serving_container and
    not proc.name in (approved_serving_processes) and
    (proc.name in (shell_binaries))
  output: >
    Shell spawned in ML serving pod
    (pod=%k8s.pod.name ns=%k8s.ns.name image=%container.image.repository
     proc=%proc.name parent=%proc.pname cmdline=%proc.cmdline
     user=%user.name)
  priority: WARNING
  tags: [ml, runtime, mitre_atlas_execution]
```

The `output:` fields become structured when the alert
leaves Falco in JSON mode (`json_output: true` in
`falco.yaml`), which is what the SIEM pipeline consumes.

---

## What is worth detecting for ML workloads

The useful invariants are the ones specific to how ML
containers *should* behave in production. The invariants
below are starting points; your production baseline will
differ.

### Shell in a serving pod

Serving containers run a fixed inference binary (vLLM,
TorchServe, Triton, a custom FastAPI app). A shell inside
the pod is either an operator doing something out-of-
band (should be a ticketed event; should be against a
dedicated debug image, not the production image) or an
attacker. Both are worth paging on; the first is a
tuning exception.

See the sample rule above. Tune `shell_binaries` for
your environment (`bash`, `sh`, `dash`, `ash`, `zsh`,
`busybox`); include `nc`, `ncat`, `socat` as "shell-
adjacent" if the rule's goal is to catch interactive
takeover.

### Pickle deserialisation in a serving process

Serving containers should not be deserialising pickles
at inference time. The malicious-model-file problem
(mod-110 chapter 04) is about *load* time; a serving
process that opens a `.pkl` file at serving time is
usually either a bug or an exploitation step.

Falco cannot read Python bytecode, but it can observe:

- `fd.filename` of `open` syscalls — a `.pkl` opened by
  the serving process at steady state is suspicious.
- Subsequent `clone`/`execve` from the serving PID
  tree — pickle deserialisation that spawns a child
  process is almost certainly malicious payload
  execution (`os.system`, `subprocess.Popen` embedded in
  a `__reduce__`).

A paired rule:

```yaml
- rule: Serving Process Opens Pickle File
  desc: >
    A pod in the ML-serving namespace opened a .pkl file.
    Deserialisation payloads in the ML-supply-chain
    threat model start here.
  condition: >
    open_read and ml_serving_container and
    (fd.filename endswith ".pkl" or
     fd.filename endswith ".pickle" or
     fd.filename endswith ".pt")
  output: >
    Serving pod opened pickle (pod=%k8s.pod.name
    file=%fd.name proc=%proc.name image=%container.image.repository)
  priority: NOTICE
  tags: [ml, runtime, atlas_T1059]

- rule: Serving Process Spawns Child From Pickle Load
  desc: >
    The serving process spawned a child after opening a
    pickle file. Common signature of
    pickle-deserialisation RCE.
  condition: >
    spawned_process and ml_serving_container and
    proc.pname in ("python", "python3", "tritonserver",
                   "vllm") and
    proc.name in ("sh", "bash", "nc", "socat", "curl",
                  "wget", "python", "python3")
  output: >
    Child process spawned under serving binary
    (pod=%k8s.pod.name parent=%proc.pname proc=%proc.name
     cmdline=%proc.cmdline image=%container.image.repository)
  priority: WARNING
  tags: [ml, runtime, atlas_T1059]
```

Serving-side `.pt` opens are often legitimate — PyTorch
model weights frequently use `.pt`. The second rule is
usually the one with lower false-positive rate; the
first is a `NOTICE`-level signal useful for enrichment
and correlation.

The `safetensors` migration (mod-110 chapter 04) is
what makes the first rule enforceable long-term:
production serving reads only safetensors; a `.pkl` open
is a policy violation.

### Unexpected egress from training / serving pods

Training containers read from the dataset store and
write to the model registry; they do not need to reach
`api.github.com`, `huggingface.co`, or `discord.com` at
runtime unless the pipeline specifically allows it.
Serving containers reach the model registry at pull time,
then should only accept inbound requests.

Falco can observe outbound connections and tag them with
the destination. The project ships `k8saudit` and
`network`-related rules; the ML-specific overlay
restricts the destination set.

```yaml
- list: approved_training_egress_hosts
  items:
    - "registry.company.com"
    - "datasets.internal.company.com"
    - "lineage.internal.company.com"

- rule: Training Pod Egress to Unapproved Host
  desc: >
    A training pod connected to a host outside the
    approved egress allowlist.
  condition: >
    (evt.type = connect) and ml_training_container and
    (fd.sip.name != "" and
     not fd.sip.name in (approved_training_egress_hosts))
  output: >
    Training pod egress to unapproved host
    (pod=%k8s.pod.name dest=%fd.sip.name:%fd.sport
     proc=%proc.name image=%container.image.repository)
  priority: WARNING
  tags: [ml, runtime, atlas_exfiltration]
```

A note on reality: Falco can see the destination IP
cheaply; resolving the IP to a hostname is harder at
rule-evaluation time. The `fd.sip.name` field in recent
Falco versions does best-effort reverse resolution; the
pattern above is a starting point. Production deployments
often prefer to enforce egress at the network layer
(NetworkPolicy, Cilium, service mesh) and use Falco to
*detect* bypass attempts rather than enforce the policy.

### Access to credentials or secrets from the model-training path

The training pod should not read `/root/.ssh/`, `/etc/
kubernetes/`, `/var/run/secrets/kubernetes.io/
serviceaccount/token` beyond the normal workload identity
usage, or `/root/.aws/credentials`. If the attacker's
pickle-deserialisation payload is credential theft, these
reads are the signature.

```yaml
- macro: sensitive_credential_paths
  condition: >
    fd.name startswith "/root/.ssh/" or
    fd.name startswith "/root/.aws/" or
    fd.name startswith "/root/.config/gcloud/" or
    fd.name startswith "/etc/kubernetes/" or
    fd.name = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt" or
    fd.name = "/etc/shadow"

- rule: Training Pod Read Sensitive Credential Path
  desc: >
    A training container read a path containing user
    credentials or cluster-wide secrets.
  condition: >
    open_read and ml_training_container and sensitive_credential_paths
  output: >
    Training pod read credential path
    (pod=%k8s.pod.name file=%fd.name proc=%proc.name
     image=%container.image.repository)
  priority: WARNING
  tags: [ml, runtime, atlas_credential_access]
```

### GPU/driver access from unexpected processes

In a Triton serving pod the serving binary is the one
that talks to the GPU; a shell doing `nvidia-smi` is a
reconnaissance signal. Falco can observe opens of
`/dev/nvidia*` character devices.

```yaml
- macro: nvidia_device_open
  condition: >
    open_read and
    (fd.name startswith "/dev/nvidia" or
     fd.name = "/dev/nvidiactl" or
     fd.name startswith "/dev/nvidia-uvm")

- rule: Unexpected NVIDIA Device Access in Serving Pod
  desc: >
    A process other than the approved serving binary
    opened an NVIDIA device inside an ML-serving pod.
  condition: >
    nvidia_device_open and ml_serving_container and
    not proc.name in (approved_serving_processes)
  output: >
    Unexpected NVIDIA device access
    (pod=%k8s.pod.name proc=%proc.name parent=%proc.pname
     file=%fd.name)
  priority: NOTICE
  tags: [ml, runtime, atlas_discovery]
```

### Write to the model-registry credential path

Any write (not just read) to the KSA token file, cloud-
credential file, or model-registry client config inside a
training or serving pod is strongly suspicious.

```yaml
- macro: model_registry_credential_paths
  condition: >
    fd.name = "/var/run/secrets/kubernetes.io/serviceaccount/token" or
    fd.name startswith "/root/.config/registry/" or
    fd.name startswith "/home/model-registry/credentials/"

- rule: Write to Model Registry Credential Path
  desc: >
    Attempted write to credential material used to
    authenticate against the model registry.
  condition: >
    open_write and (ml_training_container or ml_serving_container) and
    model_registry_credential_paths
  output: >
    Credential-path write
    (pod=%k8s.pod.name file=%fd.name proc=%proc.name)
  priority: WARNING
  tags: [ml, runtime, atlas_credential_access]
```

---

## eBPF-side signals Falco does not express directly

Some ML-specific observations are easier to collect with a
custom eBPF probe than with a Falco rule. Two examples:

- **Model-weight file digest at load time.** Falco can
  observe the open; computing the SHA-256 of the loaded
  file from kernel space is impractical. A user-space
  companion (an eBPF program that captures `openat` and
  a user-space daemon that hashes the file as the serving
  process reads it, or a filesystem overlay that enforces
  cosign verification at mount time) is the practical
  answer. This is more mod-110 territory, but the Falco
  rule above is useful even without the hash.
- **Prompt-level anomalies.** Falco can only see the
  socket read; the prompt is bytes inside a TLS payload.
  Application-level telemetry (chapter 01) is the
  correct layer.

Chapter 01 and this chapter are complementary surfaces;
nothing in Falco replaces the model-serving telemetry
pipeline, and nothing in that pipeline catches a shell in
a container.

### Tetragon and alternatives

If the programme already runs **Tetragon** (Cilium's
eBPF-based policy engine), the same ML invariants are
expressible as TracingPolicy CRDs with more fine-grained
process-ancestry conditions. Tetragon can also
*enforce*, not just alert — a child-process spawn under a
serving binary can be killed as a response rather than
only logged. Enforcement is a stronger action and carries
higher cost of a false positive; see chapter 05 for who
owns the policy.

If the programme uses **Tracee** (Aqua), the equivalent
rules are expressible as its Rego-based signatures and
share the same event substrate.

Pick one tool as the primary runtime engine; mixing
engines on the same hosts is possible but increases
operational cost without added coverage. The ATLAS tags
and the ingest format should be identical regardless of
engine.

---

## Shipping Falco alerts into the SIEM

Chapter 01 established an ingest pipeline for structured
events into the SIEM. Falco plugs into that pipeline:

- **`json_output: true`** in `falco.yaml` so each alert
  is a JSON object.
- **Falcosidekick** as the standard shipper. It accepts
  Falco's JSON stream and forwards to a dozen targets
  (Elasticsearch, Splunk HEC, Sentinel via Log Analytics,
  Loki, Kafka, S3, HTTP endpoints). Pick one as the
  canonical destination for the SIEM; keep a copy to
  object storage for retention.
- **Field normalisation.** Alert fields (`k8s.pod.name`,
  `container.image.repository`, `proc.cmdline`) map onto
  ECS fields where available (`host.name`,
  `container.image.name`, `process.command_line`); the
  Falcosidekick normalisers do this if configured, or
  you add a logstash / Vector pipeline step.
- **ATLAS tagging preserved.** The rule's `tags` list
  should include the ATLAS technique ID; the SIEM-side
  correlation rule reads it the same way it reads tags
  on a SIEM-native rule.
- **Alert deduplication and burst control.** A noisy
  rule can flood the pipeline; Falcosidekick supports
  rate limiting. The SIEM-side rule can also de-dup by
  pod and rule-id over a window.

---

## Baselines, exceptions, and tuning

Falco rules enforce invariants. If an invariant has
legitimate exceptions, those exceptions become part of
the rule — not comments in a wiki page.

- **`exceptions:` block.** Falco rules take an
  `exceptions:` list; each exception names fields and
  values that suppress the rule. Example: a specific
  "debug" image is allowed to spawn a shell in a
  pre-production namespace; the exception encodes that
  specifically.
- **Baseline-building window.** On a new rule, run in
  `log`-only mode for a defined window (two weeks is
  typical) and review every match. Only promote to
  paging once the baseline is understood.
- **Image-digest allowlists.** A rule that references
  "approved serving images" should reference *digests*,
  not tags. The allowlist is a config file version-
  controlled next to the rule; the deployment
  controller updates it when a new image is signed and
  promoted (mod-110 chapter 02).
- **Node-pool scoping.** Spot-trained models may run in
  a shared node pool with other workloads; a rule
  scoped by image / namespace / container.image.digest
  reduces cross-tenant noise.

Tuning is ongoing; the content pack carries a changelog
line per rule.

---

## Standard failure modes

- **Rule written against synthetic events only.** Falco
  rules that fire during a `kubectl exec -it … bash` on
  a staging pod but not during the real attack scenario
  are not production-ready. Replay captured syscall
  streams of real workload runs against the rule set
  before promoting.
- **"Shell in container" with no exception for
  operator debug.** Legitimate operator debug sessions
  flood the queue; triage collapses; the rule gets
  disabled. The debug path should be a tracked
  exception, not an informal norm.
- **Rule tags without ATLAS IDs.** The runtime stream
  does not join to the ATLAS coverage map; chapter 01's
  governance picture is incomplete.
- **Enforcement before detection.** Running Tetragon in
  killing mode before the baseline is understood takes
  the serving pods out. Detect first, enforce second;
  enforcement needs a change-management path (chapter
  05).
- **One rule-set across production and dev.** Dev
  clusters have shells, interactive sessions,
  rebuilds — the same rule set will fire constantly.
  Scope rules by cluster.
- **Falco output lost.** `json_output: false`, or
  `syslog` to a host whose logs get rotated and dropped,
  means the alert never reaches the SIEM. The pipeline
  is as important as the rule.
- **Rule-reloading tied to a human.** Falco rules in a
  Git repo, synced by Flux / Argo CD with policy-as-code
  review, is the sustainable pattern. "SRE Alice edited
  the rule last Tuesday" is not.
- **Trusting container metadata that is wrong.**
  `container.image.tag = "latest"` is useless;
  `container.image.digest = sha256:...` is the identity
  that matters. Make rules read digests.
- **Kernel probe fallback silently in use.** The kernel-
  module driver may still be the active probe on older
  distributions; verify with `falco --list` /
  `falco --version` that the libbpf CO-RE probe is
  loaded, which is what current Falco documentation
  recommends.

---

## Summary

- **Falco plus eBPF** is the runtime-detection stack for
  Linux-container ML workloads: eBPF captures the
  syscall stream, Falco evaluates declarative rules,
  Falcosidekick ships alerts into the SIEM pipeline
  from chapter 01.
- **The ML-specific invariants** worth encoding are:
  shell in a serving pod, pickle-deserialisation
  patterns, egress to unexpected destinations, reads of
  credential paths, unexpected GPU-device access,
  writes to the model-registry credential path. Each
  carries an ATLAS tag.
- **Rules are code**: lists, macros, rules, exceptions,
  all in version control; promoted after a baseline
  window; replayed against captured syscall streams
  before merging.
- **Enforcement** (Tetragon, Tracee, in-engine kill
  actions) is a step up from detection; it needs a
  change-management path and a baseline before it is
  turned on.
- **The ingest format is normalised to ECS** where
  possible; the ATLAS technique ID is on every rule;
  the alert lands in the same SIEM pipeline as the
  application-layer events so a single incident can
  correlate across layers.
- Standard failure modes are rules-without-baselines,
  rules-against-synthetic-data, rules-without-ATLAS-
  tags, enforcement-before-tuning, and alerts lost
  before they reach the SIEM.
