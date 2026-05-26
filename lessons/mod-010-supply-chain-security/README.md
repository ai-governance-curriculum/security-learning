# Module 10 — Supply Chain Security for ML Systems

**Duration**: ~30 hours (~1.5 weeks full-time, ~3 weeks part-time)
**Prerequisites**:
- Modules 01–09 completed.
- Module 03's Cosign work is foundational; Module 09's
  admission policies are where supply-chain controls enforce.
- Comfort with container images, build pipelines, dependency
  management at an operational level.

## What this module is for

The OWASP ML Top 10 lists "AI Supply Chain Attacks" (ML06) as a
top concern. This module covers what that means
operationally — for *both* the conventional software supply
chain (container images, dependencies, IaC) **and** the
ML-specific supply chain (pretrained models, training datasets,
fine-tuning checkpoints).

You will learn:

1. **The supply-chain threat model** — what an attacker
   targets, and why ML systems have a larger surface than
   typical SaaS.
2. **SLSA framework** — the de facto standard for
   supply-chain integrity levels.
3. **SBOM (Software Bill of Materials)** — what they record,
   why, and how to use them in production.
4. **Cosign + Sigstore at depth** — keyless signing, Rekor
   transparency log, Fulcio CA.
5. **in-toto attestations** — provenance records that travel
   with artifacts.
6. **Image scanning** — Trivy, Grype, and how to operationalize.
7. **Dependency scanning** — Snyk, OSV-Scanner, Dependabot.
8. **ML model artifact provenance** — signing models, training
   pipeline attestation, lineage tracking.
9. **ML dataset provenance** — signed datasets, dataset
   lineage, attestations.
10. **Common ML supply-chain attacks** — typo-squatting,
    dependency confusion, compromised Hugging Face models.
11. **Compromised CI patterns** — what an attacker does when
    they have your CI's credentials, and how the keyless
    pattern limits damage.

## How to work through this module

1. Read [`lecture-notes.md`](./lecture-notes.md).
2. Complete the five exercises in [`exercises/`](./exercises/).
3. Take the [quiz](./quiz.md).
4. Use [`resources.md`](./resources.md) for primary sources.

## Module deliverables

- A **SLSA self-assessment** of SmartRecs' build pipeline
  (Exercise 01).
- A **complete signed-pipeline design** — image + model + SBOM
  + attestation (Exercise 02).
- An **admission-time verification configuration** that ties
  everything together (Exercise 03).
- A **Hugging Face model vetting process** (Exercise 04).
- A **supply-chain incident runbook** (Exercise 05).

## How this module connects to the rest of the track

| Where module 10 shows up later | What it provides |
|---|---|
| Module 11 Security Operations | Detection rules for supply-chain anomalies |
| Module 12 Capstone | Supply-chain controls integrated end-to-end |

## Quick reference

- **Lecture notes**: [`lecture-notes.md`](./lecture-notes.md)
- **Exercises**: [`exercises/`](./exercises/)
- **Quiz**: [`quiz.md`](./quiz.md)
- **Resources**: [`resources.md`](./resources.md)
- **Paired project**: [`projects/project-4-secure-cicd/`](../../projects/project-4-secure-cicd/)
- **Paired solution**: [`ai-infra-security-solutions/projects/project-4-secure-cicd/SOLUTION.md`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions/blob/main/projects/project-4-secure-cicd/SOLUTION.md)
