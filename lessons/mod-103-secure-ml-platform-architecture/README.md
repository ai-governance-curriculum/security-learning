# mod-103 — Secure ML Platform Architecture: Zero-Trust, Workload Identity, Segmentation, Admission-Time Controls

**Estimated effort:** 16 hours
**Track:** AI/ML Security & Governance Engineer (`security`, level 35)
**Family:** AI Governance
**Requirement themes covered:** req-03 (design and enforce the
zero-trust ML platform architecture — NIST SP 800-207 primitives
applied to the training, registry, and serving planes; SPIFFE/SPIRE
workload identity; NetworkPolicy plus service-mesh authorisation;
CIS Kubernetes Benchmark and Pod Security Admission at the
appropriate profile; admission-time policy-as-code that gates model
deployments on required security evidence).

---

## What this module is for

Mod-102 produced the threat model — an ML-adapted STRIDE table
mapped to ATLAS and NIST AI 100-2, three attack trees, and a
prioritised mitigation scorecard. That mitigation scorecard is
inert until the platform *actively enforces* the mitigations.

Mod-103 installs the platform architecture that makes those
mitigations enforceable. You leave this module able to:

- Run a **zero-trust gap assessment** against NIST SP 800-207 for
  a target ML platform, identifying every enforcement point (PEP),
  every decision point (PDP), and every information source (PIP)
  and scoring each against the seven SP 800-207 tenets.
- Design a **SPIFFE workload-identity scheme** for the training,
  registry, and serving planes; deploy SPIRE with node and
  workload attestation; and mint short-lived, per-workload
  credentials — including via OIDC federation to cloud IAM — so
  no ambient node identity is used.
- Author **Kubernetes NetworkPolicies** (L3/L4) and **service-mesh
  AuthorizationPolicies** (L7) that segment the three planes at
  a deny-by-default anchor, with narrow allow rules for the
  enumerated cross-plane flows.
- Execute a **CIS Kubernetes Benchmark and Pod Security Admission
  hardening sprint**, prioritising high-blast-radius rows,
  labelling namespaces at the correct PSA profile, and
  documenting ML-workload exceptions with expiry.
- Author **admission-time policy-as-code** (OPA / Gatekeeper) that
  refuses any model deployment lacking a verified cosign
  signature, a CycloneDX ML-BOM, a fresh clean scan, and an
  SLSA v1.0 provenance attestation.

By the end of the module, given a target platform and the mod-102
threat model, you should be able to name every mitigation control
class (identity, segmentation, hardening, admission), point at the
concrete resource that implements it, and defend the deny-by-
default posture end to end.

## How to work through this module

1. Read the six lecture chapters in order — each builds on the
   prior one's artifact.
2. Complete the five exercises in [`exercises/`](./exercises/) in
   order. The gap assessment (exercise 01) drives the SPIFFE plan
   (exercise 02); the SPIFFE plan drives the mesh authz (exercise
   03); the hardening sprint (exercise 04) prepares the substrate
   the admission gate (exercise 05) enforces on. You are building
   one complete zero-trust platform posture.
3. Use [`resources.md`](./resources.md) as the primary-source
   reference list. Every standard, tool, and API cited in the
   chapters is linked there.
4. Move to `mod-104-data-and-model-lineage-security` when you can
   produce the module's five deliverables (gap assessment, SPIFFE
   plan, NetworkPolicy + mesh authz set, CIS + PSA state,
   admission-policy set) for a system you have never seen before,
   in under an engineering week.

## Lecture chapters

- [01 — Zero Trust for ML Platforms: The Three-Plane Model](./01-zero-trust-for-ml-platforms.md)
- [02 — NIST SP 800-207 Primitives Applied to the Training, Registry, and Serving Planes](./02-nist-sp-800-207-primitives-for-ml.md)
- [03 — Workload Identity with SPIFFE and SPIRE](./03-workload-identity-with-spiffe-spire.md)
- [04 — Network Segmentation: Kubernetes NetworkPolicy and Service-Mesh AuthorizationPolicy](./04-network-segmentation-and-mesh-authz.md)
- [05 — Cluster Hardening: CIS Kubernetes Benchmark and Pod Security Admission](./05-cluster-hardening-cis-and-pod-security-admission.md)
- [06 — Admission-Time Policy-as-Code: Gating Model Deployments on Security Evidence](./06-admission-time-policy-as-code.md)

## Exercises

- [Exercise 01 — Zero-trust gap assessment for an ML platform](./exercises/exercise-01-zero-trust-gap-assessment-for-ml-platform.md)
- [Exercise 02 — SPIFFE workload-identity plan](./exercises/exercise-02-spiffe-workload-identity-plan.md)
- [Exercise 03 — NetworkPolicy and mesh AuthorizationPolicy authoring](./exercises/exercise-03-networkpolicy-and-mesh-authz-authoring.md)
- [Exercise 04 — CIS Benchmark and PSA hardening sprint](./exercises/exercise-04-cis-benchmark-and-psa-hardening-sprint.md)
- [Exercise 05 — Admission-time gate for model deployments](./exercises/exercise-05-admission-time-gate-for-model-deployments.md)

## Module deliverables

The artifacts you leave the module with — every one carried
forward into later modules:

- The **zero-trust gap assessment** (Ex. 01), consumed by mod-109
  as the audit-time architectural evidence set and by mod-112 as
  the engineering-roadmap input.
- The **SPIFFE workload-identity plan and SPIRE registration set**
  (Ex. 02), consumed by mod-105 (which owns the keys backing
  SPIRE's OIDC and the SVIDs' issuance) and by mod-110 (which
  uses CI SPIFFE IDs as the signing identity for cosign / SLSA
  provenance).
- The **NetworkPolicy + mesh AuthorizationPolicy set** (Ex. 03),
  consumed by mod-111 as the detection surface (allow / deny
  telemetry) and by mod-107 for the LLM-specific tool-gateway
  boundary.
- The **CIS Kubernetes Benchmark + PSA hardening state** (Ex. 04),
  consumed by mod-109 governance as compliance evidence.
- The **admission-time Gatekeeper policy set** (Ex. 05), consumed
  by mod-110 supply-chain as the enforcement surface, by mod-111
  SecOps as detection input, and by mod-109 as evidence at audit.

## Where this module sits in the track

| Module | Where mod-103 shows up |
| --- | --- |
| mod-102 Threat Modelling for ML | The STRIDE table + attack trees + mitigation scorecard are the *input* — they name the mitigations this module enforces. |
| mod-104 Data and Model Lineage Security | The registry-plane policies and SPIFFE ID scheme are reused for lineage-signing identities. |
| mod-105 Secrets and Key Management | Owns the KMS holding SPIRE signing keys and the cosign keys the admission gate verifies against. |
| mod-106 Adversarial ML Defence | Uses the training-plane SPIFFE identity + tightened cloud IAM to gate access to hardened training pipelines. |
| mod-107 LLM and Agent Security | Reuses the tool-gateway boundary and per-tenant AuthorizationPolicy authored here. |
| mod-108 Privacy Engineering for ML | Uses training-plane scoping to enforce DP training runs against tagged datasets. |
| mod-109 AI Governance and Compliance Engineering | Consumes gap assessment, CIS/PSA state, and admission-policy set as evidence artifacts. |
| mod-110 Supply Chain Security for AI | Generates the evidence (signatures, ML-BOM, provenance) the admission gate enforces on. |
| mod-111 SecOps and IR for ML | Consumes mesh + admission audit logs as detection input; drills against SPIFFE revocation / registration compromise. |
| mod-112 Program Leadership | Uses the gap-assessment scorecard as the engineering roadmap input. |

## Notes on primary sources

Every framework identifier, technology name, control ID, and CIS
recommendation number in these chapters must be verified against
the primary source before being quoted externally. Where a claim
cannot be verified in the current authoring session, the chapter
contains a `<!-- needs-research: ... -->` marker rather than a
guess. Do not publish this module content externally until every
marker has been resolved to a primary-source citation or removed
with an explicit note.
