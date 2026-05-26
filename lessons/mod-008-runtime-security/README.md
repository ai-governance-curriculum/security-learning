# Module 08 — Runtime Security for ML Systems

**Duration**: ~30 hours (~1.5 weeks full-time, ~3 weeks part-time)
**Prerequisites**:
- Modules 01–07 completed.
- Working Kubernetes knowledge (pods, containers, runtime
  layer).
- Some exposure to Linux process / syscall concepts.

## What this module is for

Modules 02-04 covered *preventive* controls (identity, network,
encryption). This module covers what happens **after** a
preventive control fails:

- An attacker bypassed admission controls and is running code in
  a pod.
- A legitimate workload has been compromised and is now behaving
  abnormally.
- A misconfiguration produced a pod that has more privileges
  than intended.

Runtime security is the layer that *notices* these situations
and either alerts or contains.

You will learn:

1. **The threat model for runtime** — what an attacker can do
   from inside a container, and why detection matters when
   prevention has failed.
2. **Falco** — the production-default runtime detection tool.
   Rule authoring, deployment, tuning.
3. **eBPF and Tetragon** — the next-generation, lower-overhead
   approach.
4. **Pod Security Standards** — Kubernetes' built-in
   restrictions on what pods can do.
5. **Seccomp, AppArmor, SELinux** — kernel-level restrictions
   on syscalls and access.
6. **Sandboxing** — gVisor, Kata Containers for stronger
   isolation.
7. **Behavioral analytics** — building baselines and detecting
   deviations.
8. **ML-specific runtime threats** — model file tampering,
   training-job egress anomalies, GPU misuse.
9. **Container escape detection** — the worst-case scenario and
   what to look for.
10. **Operating runtime security at scale** — alert fatigue,
    triage, automation.

## How to work through this module

1. Read [`lecture-notes.md`](./lecture-notes.md).
2. Complete the five exercises in [`exercises/`](./exercises/).
3. Take the [quiz](./quiz.md).
4. Use [`resources.md`](./resources.md) for primary sources.

## Module deliverables

- A **Pod Security Standards baseline** for SmartRecs
  (Exercise 01).
- A **seccomp + AppArmor profile** for the model-serving
  workload (Exercise 02).
- A **Falco ruleset** with ML-specific detections (Exercise 03).
- A **behavioral-baseline design** for anomaly detection
  (Exercise 04).
- A **container-escape response runbook** (Exercise 05).

## How this module connects to the rest of the track

| Where module 08 shows up later | What it provides |
|---|---|
| Module 09 Policy as Code | Pod Security policies, admission controls |
| Module 11 Security Operations | Detection rules + SIEM integration |

## Quick reference

- **Lecture notes**: [`lecture-notes.md`](./lecture-notes.md)
- **Exercises**: [`exercises/`](./exercises/)
- **Quiz**: [`quiz.md`](./quiz.md)
- **Resources**: [`resources.md`](./resources.md)
