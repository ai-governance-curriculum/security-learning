# Module 02 — Zero-Trust Architecture for ML Systems

**Duration**: ~25 hours (1 week full-time, 2.5 weeks part-time)
**Prerequisites**:
- Module 01 — Foundations of ML Security completed.
- Working knowledge of Kubernetes (pods, services, namespaces, network policy).
- Comfort with the concepts of mTLS and OIDC at a high level.

## What this module is for

Module 01 installed *vocabulary*. This module installs the *core
architectural pattern* that the rest of the track depends on:
**zero-trust**. Every later module — secrets, network, runtime,
policy — is a specific surface where zero-trust is applied.

You will learn:

1. **What "zero-trust" actually means** beyond marketing copy —
   five core tenets, traceable to BeyondCorp and NIST SP 800-207.
2. **Why the perimeter model fails for ML systems** in ways that
   are worse than for traditional web apps.
3. **Identity-first design**: workload identity (SPIFFE / SPIRE),
   short-lived credentials, identity-bound policies.
4. **Microsegmentation** at three layers: network, service mesh
   (mTLS + AuthorizationPolicy), and L7 application controls.
5. **Defense in depth applied to a real ML serving stack** —
   how the layers compose into a defensible whole.
6. **What zero-trust deliberately doesn't solve** — and why
   teams that overclaim get into trouble.

By the end of the module you should be able to evaluate any ML
system's architecture and identify where it violates zero-trust
principles concretely (not vaguely).

## How to work through this module

1. Read [`lecture-notes.md`](./lecture-notes.md) end-to-end.
2. Complete the five exercises in [`exercises/`](./exercises/) in
   order. Exercises build on each other and the Module 01 threat
   model.
3. Take the [quiz](./quiz.md) after completing the exercises.
4. Use [`resources.md`](./resources.md) for primary sources.

## Module deliverables

After this module, you should have:

- A **zero-trust gap analysis** of the SmartRecs system you
  threat-modeled in Module 01 (Exercise 1).
- A **workload-identity design** for that system using SPIFFE
  (Exercise 2).
- A **microsegmentation plan** at three layers (Exercise 3).
- A **service-mesh authorization policy** authored by hand
  (Exercise 4).
- A **zero-trust roadmap** sequenced by reversibility (Exercise 5).

## How this module connects to the rest of the track

| Where module 02 shows up later | What it provides |
|---|---|
| Module 03 Cryptography | Identity attestation, certificate management |
| Module 04 Network Security | Microsegmentation in depth |
| Module 05 Secrets Management | Workload-identity binding for secret retrieval |
| Module 08 Runtime Security | Detecting violations of zero-trust assumptions |
| Module 09 Policy as Code | Authoring policies that encode zero-trust rules |
| Module 11 Security Operations | Detection rules keyed on workload identity |

## Quick reference

- **Lecture notes**: [`lecture-notes.md`](./lecture-notes.md)
- **Exercises**: [`exercises/`](./exercises/)
- **Quiz**: [`quiz.md`](./quiz.md)
- **Resources**: [`resources.md`](./resources.md)
- **Paired project**: [`projects/project-1-zero-trust/`](../../projects/project-1-zero-trust/)
- **Paired reference solution**: [`ai-infra-security-solutions/projects/project-1-zero-trust/SOLUTION.md`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions/blob/main/projects/project-1-zero-trust/SOLUTION.md)
