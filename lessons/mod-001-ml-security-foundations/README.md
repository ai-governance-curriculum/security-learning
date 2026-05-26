# Module 01 — Foundations of ML Security

**Duration**: ~20 hours (1 week full-time, 2 weeks part-time)
**Prerequisites**:
- Senior-level infrastructure engineering background, or
- The Engineer track ([ai-infra-engineer-learning](https://github.com/ai-infra-curriculum/ai-infra-engineer-learning)) plus working familiarity with the OWASP Top 10 and threat modeling fundamentals.

## What this module is for

ML systems present a security surface that **does not reduce to** the
general infrastructure security surface. A team that protects its
APIs, its Kubernetes cluster, and its secrets store, but does not
think about its **models, training data, and feature pipelines** as
first-class assets, is shipping a system whose threat model is wrong.

This module installs the vocabulary, frameworks, and habits that every
subsequent module in this track depends on:

1. **Why ML security is different** — what an attacker wants from an
   ML system that they don't want from a generic web app.
2. **The OWASP ML Security Top 10** — the closest thing the industry
   has to a canonical catalog.
3. **MITRE ATLAS** — the ML-specific analogue of MITRE ATT&CK, with
   real-world adversary tactics.
4. **Threat modeling for ML systems** — STRIDE adapted, plus ML-only
   threat categories.
5. **Defense in depth across the ML lifecycle** — where each control
   actually applies (training-time, inference-time, supply chain).
6. **Where you sit in the org** — the security role's interface to
   ML, platform, and engineering teams.

By the end of the module you should be able to read the [`ai-infra-security-solutions`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions) project SOLUTION.md files and recognize *why* each control is where it is.

## How to work through this module

1. Read [`lecture-notes.md`](./lecture-notes.md) end-to-end. It is the
   spine of the module and assumes nothing about ML-specific
   security knowledge.
2. Complete the five exercises in [`exercises/`](./exercises/) in order.
   Exercise 1 is the foundation; later exercises build on the threat
   model you produce.
3. Take the [quiz](./quiz.md) **after** completing the exercises. It
   is calibrated to catch shallow reads.
4. Use [`resources.md`](./resources.md) as your reference list for
   anything in the lecture notes you want to chase to a primary
   source.

## Module deliverables

After working through the module, you should have:

- **A written threat model** for a small ML system (Exercise 1) — the
  artifact you'll reuse and refine in later modules.
- **An OWASP ML Security Top 10 mapping** for that system (Exercise 2).
- **A MITRE ATLAS walkthrough** of one adversary scenario (Exercise 3).
- **A security architecture review** of an existing serving stack
  (Exercise 4).
- **A defense-in-depth design** for the ML lifecycle (Exercise 5).

These artifacts are not just learning exercises; they are the format
you will produce on the job.

## How this module connects to the rest of the track

| Module | Where module 01 shows up |
|---|---|
| 02 Zero-Trust Architecture | Defense-in-depth principles applied to identity and network |
| 03 Cryptography for ML | Encryption controls keyed to the threat model produced here |
| 04 Network Security | Network controls mapped to OWASP ML06/ML08 risks |
| 05 Secrets Management | Secret-handling controls keyed to threat model |
| 06 Adversarial ML | The full evasion/poisoning/extraction taxonomy introduced here |
| 07 Compliance | Regulatory controls mapped to threat scenarios |
| 08 Runtime Security | Runtime controls keyed to lifecycle defense-in-depth |
| 09 Policy as Code | Policy authoring keyed to threats |
| 10 Supply Chain Security | Training/serving supply chain threats |
| 11 Security Operations | Detection rules mapped to MITRE ATLAS tactics |
| 12 Capstone | Synthesis exercise |

## Quick reference

- **Lecture notes**: [`lecture-notes.md`](./lecture-notes.md)
- **Exercises**: [`exercises/`](./exercises/)
- **Quiz**: [`quiz.md`](./quiz.md)
- **Resources**: [`resources.md`](./resources.md)
- **Paired solutions repo**: [`ai-infra-security-solutions`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions)
