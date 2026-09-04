# mod-104 — Data and Model Lineage Security: Signed Provenance, Immutable Audit, ML-BOM, Evidence Linking

**Estimated effort:** 14 hours
**Track:** AI/ML Security & Governance Engineer (`security`, level 35)
**Family:** AI Governance
**Requirement themes covered:** req-13 (design and enforce end-to-
end data and model lineage security — signed provenance across the
five ML artifact classes, cosign / Sigstore signing wired into the
training pipeline, CycloneDX ML-BOM per model, model-card and
system-card evidence linking, and an immutable audit-log
architecture for training, admission, deployment, and inference
events).

---

## What this module is for

Mod-103 installed the admission gate that refuses model deployments
lacking a verified cosign signature, a fresh clean scan, a
CycloneDX ML-BOM, and a SLSA v1.0 provenance attestation. That
gate is only as trustworthy as the **evidence it consumes**.

Mod-104 authors that evidence. You leave this module able to:

- Design the **end-to-end provenance architecture** for an ML
  platform against the five object classes — training data
  snapshot, feature set, model artifact, evaluation run,
  deployment / serving revision — naming, per class, what is
  signed, what is logged, what is retained, and for how long,
  under a retention schedule driven by the three composed
  drivers (regulatory, incident-response, model-monitoring).
- Wire **cosign / Sigstore signing** into a training pipeline —
  keyless signing via Fulcio-issued short-lived certificates
  bound to a SPIFFE / CI OIDC identity, Rekor transparency-log
  inclusion, `sign-blob` for weights and `attest` for
  attestations.
- Produce **SLSA v1.0 in-toto provenance attestations** for the
  training build, structured to satisfy at least SLSA Build L2
  requirements against the target builder.
- Author a **CycloneDX 1.6 ML-BOM** for a target model — model
  component, dataset components, third-party base models,
  framework components, licences, provenance claims — and
  attach it as an in-toto attestation.
- Wire lineage evidence into **model cards and system cards**
  (Hugging Face front-matter convention + Google Model Card
  Toolkit patterns) so external audiences can walk a claim in
  prose to a specific attestation UUID with a matching digest.
- Design the **immutable audit-log architecture** — narrow
  audit-event catalogue, SPIFFE-authenticated event bus,
  schema-validated ingress, WORM sink on S3 Object Lock /
  GCS Bucket Lock / Azure Immutable Blob (compliance-mode
  retention), tamper-evident log on Rekor or private Trillian,
  off-account + cross-region replication, monitors run under
  separate admin identity.

By the end of the module, given a target ML platform and the
mod-103 admission-gate policy set, you should be able to name
every artifact the platform produces, point at the concrete
resource that signs and retains it, defend the retention floor
against the composed regulatory / IR / monitoring drivers, and
prove that no rewrite of the audit stream would go undetected.

## How to work through this module

1. Read the six lecture chapters in order — each builds on the
   prior one's artifact.
2. Complete the five exercises in [`exercises/`](./exercises/) in
   order. The provenance architecture (exercise 01) enumerates
   the artifacts and drives the retention schedule; cosign
   signing (exercise 02) signs the model artifact; the ML-BOM
   (exercise 03) enumerates its components; the model + system
   card (exercise 04) exposes the evidence to external audiences;
   the audit-log design (exercise 05) closes the loop by
   guaranteeing the record of everything above survives under
   adversary.
3. Use [`resources.md`](./resources.md) as the primary-source
   reference list. Every standard, tool, and API cited in the
   chapters is linked there.
4. Move to `mod-105-secrets-and-key-management` when you can
   produce the module's five deliverables (provenance
   architecture, signed model artifact + attestations, ML-BOM,
   model + system card, audit-log design) for a target platform
   you have never seen before, in under an engineering week.

## Lecture chapters

- [01 — End-to-End Provenance for ML: What Is Signed, Logged, Retained](./01-provenance-architecture-end-to-end.md)
- [02 — Cosign and Sigstore: Signing Model Artifacts in the Training Pipeline](./02-cosign-sigstore-model-artifact-signing.md)
- [03 — SLSA and in-toto: Provenance Attestations for ML Builds](./03-slsa-in-toto-provenance-for-ml-builds.md)
- [04 — CycloneDX ML-BOM: Authoring the Bill of Materials for a Model](./04-cyclonedx-ml-bom-authoring.md)
- [05 — Model Cards and System Cards: Linking Every Claim to Signed Evidence](./05-model-and-system-card-evidence-linking.md)
- [06 — Immutable Audit Log Architecture: WORM, Object Lock, Tamper-Evident Trees](./06-immutable-audit-log-architecture.md)

## Exercises

- [Exercise 01 — Provenance architecture for one training pipeline](./exercises/exercise-01-provenance-architecture-for-one-training-pipeline.md)
- [Exercise 02 — Cosign signing of model artifacts](./exercises/exercise-02-cosign-signing-of-model-artifacts.md)
- [Exercise 03 — ML-BOM authoring for one model](./exercises/exercise-03-ml-bom-authoring-for-one-model.md)
- [Exercise 04 — Model card and system card with evidence linking](./exercises/exercise-04-model-card-evidence-linking.md)
- [Exercise 05 — Immutable audit log design doc for an ML platform](./exercises/exercise-05-immutable-audit-log-design-doc.md)

## Module deliverables

The artifacts you leave the module with — every one carried
forward into later modules:

- The **provenance architecture and retention schedule** (Ex. 01),
  consumed by mod-109 governance as the evidence map for the
  ISO/IEC 42001, EU AI Act, and NIST AI RMF audits, and by
  mod-110 supply chain as the upstream boundary for
  third-party-artifact provenance verification.
- The **signed model artifact + SLSA / ML-BOM attestations**
  (Ex. 02 and 03), consumed by mod-103's admission gate as the
  evidence bundle it verifies, and by mod-111 SecOps as the
  provenance backbone for incident investigation.
- The **model card + system card + eval-run attestation** (Ex. 04),
  consumed by mod-109 as the external-facing transparency
  evidence and by mod-108 privacy engineering as the surface for
  DPIA-linked disclosures.
- The **immutable audit-log design** (Ex. 05), consumed by
  mod-111 SecOps as the detection surface, by mod-109 as the
  audit-time evidence sink, and by mod-112 program leadership
  as an input to the multi-year evidence retention budget.

## Where this module sits in the track

| Module | Where mod-104 shows up |
| --- | --- |
| mod-101 Position | Frames the "own provenance and audit" responsibility this module operationalises. |
| mod-102 Threat Modelling | The attack trees against training data and model artifacts name the adversaries this module's signatures, ML-BOM, and WORM audit trail counter. |
| mod-103 Secure ML Platform Architecture | The admission gate is the *consumer* — this module produces the signatures, ML-BOM, and provenance the gate enforces on. The SPIFFE identity scheme is the *signer* identity for every attestation. |
| mod-105 Secrets and Key Management | Owns the KMS holding cosign signing keys, Rekor / Trillian log signing keys, and the KMS keys encrypting the WORM audit sink. |
| mod-107 LLM and Agent Security | Elevated agent-action inference events flow into this module's audit stream under the chapter-06 exceptions. |
| mod-108 Privacy Engineering | Dataset-level provenance and retention decisions here feed the DPIA and data-minimisation controls there. |
| mod-109 AI Governance and Compliance | Consumes model cards, system cards, ML-BOMs, and audit exports as evidence at ISO/IEC 42001, EU AI Act, NIST AI RMF, and SR 11-7 audits. |
| mod-110 Supply Chain Security for AI | Produces the upstream-model and third-party-dataset provenance claims that populate this module's ML-BOM. |
| mod-111 SecOps and IR for ML | Consumes the event bus as detection input; drills against rewrites of the audit stream and against cosign / Rekor compromise. |
| mod-112 Program Leadership | Uses the retention schedule and audit-log design as inputs to multi-year evidence-cost budgeting. |

## Notes on primary sources

Every framework identifier, tool name, control ID, and regulatory
citation in these chapters must be verified against the primary
source before being quoted externally. Where a claim cannot be
verified in the current authoring session, the chapter contains a
`<!-- needs-research: ... -->` marker rather than a guess. Do not
publish this module content externally until every marker has been
resolved to a primary-source citation or removed with an explicit
note.
