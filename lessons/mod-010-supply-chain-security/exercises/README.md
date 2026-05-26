# Module 10 Exercises

| # | Exercise | Output | Time |
|---|---|---|---|
| 1 | [SLSA self-assessment](./exercise-01-slsa-self-assessment.md) | Per-pipeline SLSA-level scoring | 2 h |
| 2 | [Signed-pipeline design](./exercise-02-signed-pipeline-design.md) | End-to-end image+model+SBOM+attestation flow | 2–3 h |
| 3 | [Admission verification config](./exercise-03-admission-verification.md) | Kyverno / Gatekeeper policy that verifies signatures + attestations | 2 h |
| 4 | [Hugging Face model vetting](./exercise-04-hugging-face-vetting.md) | Vetting process + worked example | 2 h |
| 5 | [Supply-chain incident runbook](./exercise-05-supply-chain-incident-runbook.md) | Response procedure for confirmed CI compromise | 2 h |

## Working notes

- Reuse SmartRecs throughout. Modules 03 (Cosign) and 09
  (admission policies) are the prerequisites for Exercises 2-3.
- Exercise 4 is the ML-specific case; it builds the vetting
  process the Module 07 vendor-risk work needs for ML models.
