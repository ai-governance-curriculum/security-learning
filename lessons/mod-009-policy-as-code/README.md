# Module 09 — Policy as Code

**Duration**: ~25 hours (~1 week full-time, ~2 weeks part-time)
**Prerequisites**:
- Modules 01–08 completed. PSS and admission controls from
  Module 08; cryptographic admission policies from Module 03;
  Istio AuthorizationPolicy from Module 02.
- Comfort with declarative configuration (Kubernetes YAML).
- Helpful but not required: any prior exposure to declarative
  policy languages (HCL, JSONPath, JQ).

## What this module is for

Across the previous modules we've authored ad-hoc policies — a
NetworkPolicy here, a Pod Security label there, an admission
control elsewhere. This module unifies that work under a single
discipline: **policy as code**.

The shift is from "we have policies somewhere" to:

- Policies live in **version-controlled code**.
- Policies are **tested** in CI like any other code.
- Policies are **distributed** consistently across clusters and
  pipelines.
- Policies are **auditable** — every enforcement decision
  produces a trail.

You will learn:

1. **Open Policy Agent (OPA)** — the general-purpose policy
   engine.
2. **Rego** — OPA's policy language. Authoring, testing,
   debugging.
3. **Kubernetes admission** — Gatekeeper and Kyverno. When each
   is the right choice.
4. **Conftest** — policy evaluation in CI pipelines.
5. **OPA bundles + distribution** — getting policies to where
   they need to enforce.
6. **Policy testing** — unit tests, integration tests,
   conformance.
7. **ML-specific policy patterns** — model-promotion gates,
   training-data governance, prompt routing, tenant isolation.
8. **Migrating from ad-hoc to policy-as-code** — practical
   sequencing.

## How to work through this module

1. Read [`lecture-notes.md`](./lecture-notes.md).
2. Complete the five exercises in [`exercises/`](./exercises/).
3. Take the [quiz](./quiz.md).
4. Use [`resources.md`](./resources.md) for primary sources.

## Module deliverables

- A **Gatekeeper vs. Kyverno choice** for SmartRecs (Exercise 01).
- A **Rego policy library** with at least 5 policies (Exercise 02).
- A **CI policy gate** using Conftest (Exercise 03).
- An **ML-specific policy catalog** — model promotion,
  training-data governance, more (Exercise 04).
- A **policy testing + distribution plan** (Exercise 05).

## How this module connects to the rest of the track

| Where module 09 shows up later | What it provides |
|---|---|
| Module 10 Supply Chain | Admission policies that verify Cosign signatures |
| Module 11 Security Operations | Policy-violation alerts feed into detection |

## Quick reference

- **Lecture notes**: [`lecture-notes.md`](./lecture-notes.md)
- **Exercises**: [`exercises/`](./exercises/)
- **Quiz**: [`quiz.md`](./quiz.md)
- **Resources**: [`resources.md`](./resources.md)
