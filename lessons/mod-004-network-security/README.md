# Module 04 — Network Security for ML Systems

**Duration**: ~25 hours (1 week full-time, 2.5 weeks part-time)
**Prerequisites**:
- Modules 01, 02, and 03 completed.
- Working knowledge of L3/L4/L7 networking concepts.
- Kubernetes networking model (CNI, services, ingress, network
  policy) at an operational level.

## What this module is for

Modules 02 and 03 introduced zero-trust identity and the
cryptographic substrate. This module goes deep on **the network
controls** that those substrates configure. Where Module 02
covered *what* segmentation is, Module 04 covers *how to build
and operate it*.

You will learn:

1. **Kubernetes NetworkPolicy** at depth — egress in particular,
   which most teams get wrong.
2. **CNI choice and the security implications** — Cilium vs.
   Calico vs. others; what each can and cannot enforce.
3. **Service mesh security** at depth — Istio policy
   composition, the gotchas, what breaks under load.
4. **Ingress and gateway hardening** — Layer 7 controls at the
   edge.
5. **Egress controls** — the part most ML platforms ignore until
   exfiltration happens.
6. **DDoS and rate-limiting** — protecting model APIs whose
   inference cost gives attackers asymmetric leverage.
7. **Network observability for security** — eBPF, flow logs,
   what's signal and what's noise.
8. **ML-specific patterns** — model artifact pulls,
   training-data warehouse access, feature-store fan-in,
   notebook environments.

## How to work through this module

1. Read [`lecture-notes.md`](./lecture-notes.md).
2. Complete the five exercises in [`exercises/`](./exercises/).
3. Take the [quiz](./quiz.md).
4. Use [`resources.md`](./resources.md) for primary sources.

## Module deliverables

- A **CNI evaluation document** for SmartRecs (Exercise 01).
- A **complete NetworkPolicy set** with default-deny, egress, and
  per-workload allows (Exercise 02).
- An **ingress + edge gateway hardening plan** (Exercise 03).
- A **rate-limit + DDoS protection design** for the model API
  (Exercise 04).
- A **network observability plan** keyed to the threats in your
  Module 01 model (Exercise 05).

## How this module connects to the rest of the track

| Where module 04 shows up later | What it provides |
|---|---|
| Module 05 Secrets Management | Egress controls for KMS access |
| Module 08 Runtime Security | Network anomaly detection |
| Module 09 Policy as Code | NetworkPolicy generation from policy |
| Module 11 Security Operations | Network-layer detections |

## Quick reference

- **Lecture notes**: [`lecture-notes.md`](./lecture-notes.md)
- **Exercises**: [`exercises/`](./exercises/)
- **Quiz**: [`quiz.md`](./quiz.md)
- **Resources**: [`resources.md`](./resources.md)
- **Paired project**: [`projects/project-1-zero-trust/`](../../projects/project-1-zero-trust/) (revisited at deeper detail)
