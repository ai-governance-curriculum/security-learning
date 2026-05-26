# Lessons

Each module directory contains a `README.md`, `lecture-notes.md`,
an `exercises/` directory, `quiz.md`, and `resources.md`. Module
12 (the capstone) has additional artifacts: a scenario brief,
readiness checklist, and grading rubric.

## All modules

| Module | Status | Topic | Hours |
|---|---|---|---|
| [`mod-001-ml-security-foundations`](./mod-001-ml-security-foundations/) | ✅ Published | Foundations of ML Security — threat models, OWASP ML Top 10, MITRE ATLAS, architecture principles, defense in depth | ~20 |
| [`mod-002-zero-trust-architecture`](./mod-002-zero-trust-architecture/) | ✅ Published | Zero-Trust Architecture for ML — NIST SP 800-207 tenets, SPIFFE workload identity, 3-layer microsegmentation, Istio AuthorizationPolicy | ~25 |
| [`mod-003-cryptography-for-ml`](./mod-003-cryptography-for-ml/) | ✅ Published | Cryptography for ML — encryption at rest / in transit / in use, KMS + Vault, certificates, Cosign signing, hash chains | ~20 |
| [`mod-004-network-security`](./mod-004-network-security/) | ✅ Published | Network Security — NetworkPolicy depth, CNI choice, Istio policy composition, gateway hardening, egress control, DDoS / rate limiting, observability | ~25 |
| [`mod-005-secrets-management`](./mod-005-secrets-management/) | ✅ Published | Secrets Management — Vault deep dive, ESO, cloud secret managers, dynamic credentials, keyless CI, secret detection, break-glass | ~20 |
| [`mod-006-adversarial-ml`](./mod-006-adversarial-ml/) | ✅ Published | Adversarial ML — attack taxonomy, evasion (FGSM/PGD/C&W), adversarial training, certified defenses, poisoning, extraction, DP-SGD, LLM prompt injection | ~40 |
| [`mod-007-compliance-and-governance`](./mod-007-compliance-and-governance/) | ✅ Published | Compliance and Governance — GDPR, HIPAA, SOC 2, EU AI Act, ISO 27001/42001, NIST AI RMF, continuous compliance, vendor risk | ~35 |
| [`mod-008-runtime-security`](./mod-008-runtime-security/) | ✅ Published | Runtime Security — Pod Security Standards, seccomp/AppArmor, Falco, Tetragon/eBPF, sandboxing (gVisor/Kata), behavioral analytics, container escape | ~30 |
| [`mod-009-policy-as-code`](./mod-009-policy-as-code/) | ✅ Published | Policy as Code — OPA + Rego, Gatekeeper, Kyverno, Conftest, ML-specific policies (model promotion, training-data governance, tenant isolation), testing + distribution | ~25 |
| [`mod-010-supply-chain-security`](./mod-010-supply-chain-security/) | ✅ Published | Supply Chain Security — SLSA framework, SBOM (CycloneDX/SPDX), Cosign + Sigstore depth, in-toto attestations, image + dep scanning, model + dataset provenance, Hugging Face vetting | ~30 |
| [`mod-011-security-operations`](./mod-011-security-operations/) | ✅ Published | Security Operations — SIEM fundamentals, Sigma rule authoring, MITRE ATLAS-mapped detections, IR procedures, on-call patterns, forensics, threat intel, tabletops, postmortems, ML-specific detections | ~35 |
| [`mod-012-capstone`](./mod-012-capstone/) | ✅ Published | Capstone — synthesis exercise integrating Modules 01-11. Includes the NorthBridge Health scenario, six progressive exercises, grading rubric, and audience-targeted communication portfolio | ~30 |

**Total track**: ~335 hours.

## Track structure

The track has three phases:

### Phase 1 — Foundations (Modules 01-05, ~110 hours)

The vocabulary, the architecture, the cryptographic substrate,
and the network + secret-management layer. Every later module
assumes this material.

### Phase 2 — Specialization (Modules 06-10, ~160 hours)

The ML-specific work (adversarial defense), the regulatory
obligations (compliance), and the operational layers (runtime,
policy, supply chain). This phase is where the curriculum's
title-promise lives.

### Phase 3 — Operations + Synthesis (Modules 11-12, ~65 hours)

How the previous 10 modules become a running security program.
Module 11 covers the detection / IR layer; Module 12 is the
synthesis capstone.

## Track-level deliverable

A learner who works through all 12 modules produces:

- 11 module-level portfolios (threat models, designs,
  runbooks, policies, detection rules, etc.).
- A complete capstone portfolio (six audience-targeted
  artifacts for the NorthBridge Health scenario).

Together, these constitute a **demonstration portfolio** for
the role of AI infrastructure security engineer.

## How to study while still building skills

The capstone (Module 12) is the recommended end state. For
learners who haven't reached it yet, the per-module exercises
produce reusable artifacts:

- The Module 01 threat model is the input for every later
  module.
- The Module 02 workload-identity scheme is referenced by
  Modules 03, 05, 09, 11.
- The Module 03 audit chain is the substrate for compliance
  evidence (Module 07).
- The Module 06 adversarial defenses produce evidence for the
  EU AI Act (Module 07).
- The Module 09 policies enforce admission-time verification
  of the Module 10 supply-chain artifacts.

For implementation depth on individual controls, the paired
solutions repo
[`ai-infra-security-solutions`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions)
contains 5 project-level `SOLUTION.md` files (each with a
production-gap checklist and cross-references into the engineer
and mlops tracks).
