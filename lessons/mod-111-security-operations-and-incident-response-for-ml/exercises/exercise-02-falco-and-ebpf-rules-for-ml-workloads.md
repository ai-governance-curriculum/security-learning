# Exercise 02 — Falco / eBPF Rules for ML Workloads

**Estimated effort:** ~3 hours
**Deliverable:** A committed Falco content bundle for a
realistic ML cluster, consisting of (a) a **Falco rules
file** containing at least six ML-workload rules — two for
serving pods, two for training pods, and two for the
training/serving-boundary surface — with lists, macros,
scoped exceptions, and `output:` templates in JSON-
compatible form; (b) a **baseline design** describing the
per-rule tuning window, image-digest allowlists, and
scoped-exception mechanism; (c) an **alert-forwarding
plan** that ships Falco JSON into the chapter 01 SIEM
pipeline with ATLAS tags preserved; (d) a **testing-
harness manifest** showing how each rule is validated with
`event-generator`, with synthetic / replayed syscall
traces, or against a disposable test pod — including the
expected rule firings; (e) a **detection-vs-enforcement
decision log** stating, for each rule, whether it is
detection-only or whether Tetragon/Tracee-style
enforcement is planned, with the rationale; and (f) a
one-page **operational-runbook snippet** telling the SOC
on-call what each rule means and what the chapter 03
playbook link is.
**Prerequisites:** Chapter 02 read end-to-end. Chapter 01
read for the SIEM-ingest contract and ATLAS tagging.
Chapter 03 read for the playbook references. Access to a
Falco installation (minikube / kind / a dev cluster) or a
credible model of your production ML cluster. Familiarity
with the Falco rule DSL (`condition`, `output`, `tags`,
`exceptions`), and with how Falcosidekick / an equivalent
shipper forwards alerts to your SIEM.

---

## Objective

Chapter 02's claim is that an ML cluster's runtime
posture is defined by a small set of Falco rules on the
syscall stream, scoped to the ML namespaces and image
digests, backed by baselines and shipped into the
same SIEM pipeline that chapter 01 established. This
exercise is where the rules get written against a real
or realistic ML cluster and the operational trimmings
— baselines, exceptions, alert forwarding, testing,
runbook — are built around them.

By the end of this exercise you have:

- A **rules file** that enforces the ML-workload
  invariants chapter 02 names: shell in a serving
  pod, pickle open and child spawn, credential-path
  reads, unexpected GPU-device access, unexpected
  egress, writes to the registry credential path.
- A **baseline design** that avoids the "flood on
  day one" failure: tuning windows, image-digest
  allowlists, scoped exceptions in the rule file
  itself.
- An **alert-forwarding plan** so Falco output
  participates in the same incident workflow as
  SIEM-native events, with ATLAS tags preserved.
- A **testing harness** that validates each rule
  against a specific triggering event and against a
  known-benign baseline.
- A **detection-vs-enforcement decision** that is
  explicit about which rules will eventually move
  from alert-only to kill-the-process enforcement
  and under what conditions.
- A **runbook snippet** that lets the SOC on-call go
  from "Falco alert fired" to "page the right people,
  run the right playbook" without reading chapter 02.

You are **not** running Falco in production enforcement
mode in this exercise. You are producing the rules, the
baselines, the forwarding plan, and the tests that
make a production rollout defensible.

---

## Problem statement

Pick one ML cluster context up front:

- **Real ML cluster.** Your training / serving GKE /
  EKS / AKS / OpenShift cluster, or a dev replica of
  it.
- **Reference ML cluster.** A kind / minikube cluster
  with representative workloads: a Triton or vLLM
  serving pod, a Jupyter / Argo training pod, a
  model-pulling init container, a dataset-pulling
  init container.

State before you start:

- Cluster name / shape.
- The namespaces in scope: `ml-serving`, `ml-
  training`, or whatever your convention is.
- The serving binary / image set (digests where
  possible).
- The training image set (digests where possible).
- The identity model (KSAs, workload identities).
- The Falco deployment shape: eBPF probe (libbpf
  CO-RE) running as a DaemonSet; `falco.yaml` with
  `json_output: true`; Falcosidekick or equivalent
  shipper configured.

If the cluster is hypothetical, note so and model the
image set and identities realistically.

---

## Requirements

### Deliverable A — Falco rules file

Author at least **six** rules, with a shape consistent
with chapter 02's examples. Rule set should include:

- **Serving-side (two).** Examples: shell in a
  serving pod; pickle open and child spawn under
  serving binary; unexpected `nvidia-smi` /
  `/dev/nvidia*` access.
- **Training-side (two).** Examples: training pod
  reading sensitive credential paths; unexpected
  outbound connect from a training pod; write to a
  training-data bucket from an unauthorised identity
  (requires Kubernetes-audit integration or a
  companion rule type).
- **Boundary (two).** Examples: write to the model-
  registry credential path; shell-adjacent binary
  (`nc`/`socat`) spawned in either namespace;
  container reading `/etc/shadow` or `/root/.ssh/*`.

For each rule, include:

- `macro:` definitions used by the rule, defined
  once and reused.
- `list:` definitions for approved images, approved
  processes, approved egress endpoints.
- `rule:` with `desc`, `condition`, `output`
  (template with named `%` fields), `priority`,
  `tags` (including an ATLAS technique ID), and
  `exceptions:` where appropriate.
- Scope conditions that restrict the rule to the ML
  namespaces / image digests (not tags).

The rules file is version-controlled; make the
intended path (e.g. `rules.d/ml-workloads.yaml`)
part of the deliverable.

### Deliverable B — baseline design

For each rule, name:

- The **tuning window** — how long the rule runs in
  `NOTICE` (not paging) before promotion to
  `WARNING` / `ERROR` paging. Two weeks is a common
  minimum.
- The **image-digest allowlist** the rule depends on,
  if any. Reference the mod-110 chapter 02 signing /
  admission pipeline that produces the digests.
- The **scoped exceptions** — the specific legitimate
  cases that must not fire. Each exception is a
  record in the rule's `exceptions:` block, not a
  comment or a wiki page.
- The **owner** — who tunes this rule when its FP
  rate drifts; chapter 05's RACI applies.
- The **retirement path** — when the rule gets
  deprecated.

### Deliverable C — alert-forwarding plan

Document how Falco alerts reach the SIEM:

- `falco.yaml` fragment enabling `json_output: true`
  and the output channel (HTTP / Falcosidekick /
  gRPC).
- The shipper configuration (Falcosidekick to
  Elasticsearch / Splunk HEC / Sentinel Log Analytics
  / an intermediate Kafka).
- The field normalisation (ECS alignment, mapping
  table from `k8s.pod.name` → `host.name`, etc.).
- Preservation of ATLAS tags in the shipped record,
  so chapter 01's coverage map renders Falco rules.
- Retention and backup — a copy of the Falco stream
  to immutable storage so an incident's runtime
  evidence survives a pod loss.

### Deliverable D — testing-harness manifest

For each rule, produce:

- A **synthetic trigger** — a `kubectl exec` command,
  a scripted container, or a `falcosecurity/event-
  generator` scenario — that fires the rule. Include
  the expected `output:` string.
- A **baseline trace** — a known-benign action in the
  same namespace that must *not* fire the rule.
  Include a before / after count of alerts.
- A **replay-against-production-sample** test. If
  real production syscall traces are available
  (sanitised), run the rule against a window of
  them; report the TP/FP count.
- A failure-mode test — a scenario where the rule
  *should* fire but conservatively does not (an
  excluded image, an allowlisted process), confirming
  the exception works as intended.

### Deliverable E — detection-vs-enforcement decision log

For each rule, record:

- Default mode: **detection-only** or
  **enforcement**.
- If enforcement, the enforcement mechanism
  (Tetragon TracingPolicy, Tracee signature, a
  companion kill-pod webhook) and the kill
  granularity (process, pod, namespace).
- The pre-conditions for enforcement to be enabled
  (baseline window completed, FP rate below
  threshold, playbook link validated).
- The blast-radius assessment — what breaks if the
  enforcement fires on a legitimate case.
- The approver (RACI).

Default should lean toward detection-only until
baselines are proven; enforcement that takes down
serving in an off-case is often worse than the
threat it prevented.

### Deliverable F — operational-runbook snippet

For each rule, a short block the SOC on-call reads
on alert:

- Rule ID and name.
- One-line meaning: "A shell was executed inside a
  production serving pod. Serving pods run a fixed
  binary; a shell is unexpected and may indicate an
  interactive takeover."
- Immediate action: who to page, which chapter 03
  playbook, which kill switch.
- Expected false-positive sources: operator debug
  (should be ticketed), new image rollout with a
  changed init pattern.
- The ATLAS tag(s) applied, so the responder knows
  the attack class.

The snippets form a per-rule section of the
production runbook; link them to the chapter 03
playbooks for the broader response.

---

## Starter guidance

- **Start with the invariant, not the rule.** For
  each rule, state the one-sentence invariant it
  enforces (serving pods do not spawn shells;
  training pods do not read SSH keys). The rule
  encodes the invariant; without the invariant the
  rule is noise.
- **Pin by image digest, not tag.** Rules that
  check `container.image.repository startswith …`
  are weak; rules that check
  `container.image.digest in (<approved>)` are
  strong. Produce the digest list from the admission
  controller (mod-110 chapter 02).
- **Exceptions in code.** `exceptions:` blocks are
  version-controlled with the rule; informal
  "known OK" lists outside the rule file are
  tech debt.
- **Scope by namespace, labels, and digest.** A rule
  that matches "shell in container" cluster-wide
  fires in every dev namespace at every `kubectl
  exec`. Chapter 05's cost of a noisy pager is
  real.
- **Prefer `k8s.ns.name` scoping over
  `k8s.pod.label.app` scoping** when the namespace
  is the stable boundary. Labels churn; namespaces
  tend not to.
- **Keep rule priority honest.** `WARNING` means
  "page"; `NOTICE` means "log". The decision belongs
  in the rule, not in the shipper.
- **Test the ingest path end-to-end.** A rule that
  fires but whose alert never reaches the SIEM is a
  rule in log-only mode you did not realise was in
  log-only mode. The forwarding plan is part of the
  test harness.
- **Match the chapter 03 playbook.** Every rule's
  runbook snippet names the playbook it feeds.

---

## Acceptance criteria

A passing bundle:

- At least six rules spanning serving-side, training-
  side, and boundary surfaces, each with ATLAS
  tagging.
- A baseline design per rule with tuning window,
  image-digest allowlist (where applicable), scoped
  exceptions, owner, retirement path.
- An alert-forwarding plan with concrete config
  snippets and ATLAS-tag preservation.
- A testing harness with synthetic trigger, baseline
  trace, replay sample (where available), and
  exception-fires-correctly test.
- A detection-vs-enforcement decision per rule with
  rationale.
- A runbook snippet per rule linking to the chapter
  03 playbook.

A failing bundle:

- Rules that match by image *tag* and claim strong
  scope.
- "Exceptions managed informally" or a Confluence
  link.
- Any rule in `WARNING` without a defined baseline
  window.
- Alert-forwarding plan that drops ATLAS tags.
- Testing harness that only names synthetic triggers.
- Enforcement enabled for any rule without an
  explicit approval and blast-radius assessment.
- Runbook snippets missing playbook links.

---

## Stretch goals

- **End-to-end CI gate.** PRs to the rules file run
  through a CI gate that: (a) lints the YAML
  against the Falco rule schema; (b) runs the
  synthetic triggers in a kind cluster and verifies
  the expected alerts fire; (c) runs the baseline
  traces and verifies no alerts fire.
- **Replay fixture library.** Build a library of
  real sanitised syscall captures representing
  normal workload behaviour; every rule change
  replays against it in CI.
- **Multi-engine portability.** Produce the same
  invariants as Tetragon TracingPolicy and / or
  Tracee signatures; compare the trade-offs
  (expressiveness, enforcement options, ingest
  pipeline).
- **mTLS of the alert pipeline.** Document the
  authentication/authorisation of Falcosidekick to
  the SIEM; show how an attacker who compromises the
  Falco DaemonSet is prevented from spoofing alerts
  about themselves.
- **GPU anomaly detection beyond /dev/nvidia opens.**
  Add a rule that reads the DCGM or nvidia-smi query
  stream (via a sidecar or a Prometheus-exporter)
  for anomalous SM utilisation / memory patterns
  consistent with a crypto-miner or an attacker
  grinding adversarial examples.
- **Linkage to chapter 01's coverage map.** Falco
  rules enter the ATLAS coverage map alongside SIEM
  rules; show the integration.
- **Rehearsal integration.** Pair at least one rule
  with a chapter 03 playbook rehearsal exercise.

---

## Do not

- Do not deploy rules in paging mode without the
  tuning window.
- Do not use `evt.type` conditions that are
  version-specific without documenting the Falco
  / libs version you tested on.
- Do not rely on `fd.sip.name` reverse-resolution for
  anything mission-critical; use network policy for
  authoritative egress blocks.
- Do not stage enforcement in production before any
  detection-only data has been collected.
- Do not file rules outside Git. The rules file is a
  policy artefact.
- Do not commit the solution bundle to this repo.
  Solutions live in the paired `-solutions` repo.
