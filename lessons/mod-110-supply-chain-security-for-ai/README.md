# mod-110-supply-chain-security-for-ai: AI Supply Chain Security — SLSA for Models, Signing, ML-BOM, Malicious Model File Defence

> Scaffolded by `aicg org execute-plan`. Lecture chapters and exercise content are authored on subsequent autonomous cycles.

**Estimated effort:** 16 hours

## Learning objectives

- Extend SLSA v1.0 levels 1-3 build-integrity requirements to model artifacts — provenance attestation, hermetic build, isolation between build and run
- Sign model artifacts and container images with cosign / sigstore and verify signatures at deployment time
- Author an ML-BOM (AI-BOM) for a deployed model that covers datasets, base models, fine-tuning components, third-party dependencies, and licence obligations
- Detect malicious code in serialised model files — pickle deserialisation vulnerabilities, malicious code in Keras / TensorFlow SavedModel, HDF5 payloads; run ModelScan; enforce safetensors where possible
- Design a hygiene process for consuming third-party models from Hugging Face Hub or similar registries — provenance verification, licence review, safety-testing gate
- Position ML supply-chain security against generic software supply-chain (owned upstream) and against NIST SP 800-161 supply-chain risk management
- Cover requirement theme req-05

## Structure

- `01-…md` … `0N-…md`: lecture chapters.
- `exercises/`: per-exercise prompts.
- `labs/`: long-form hands-on labs.
- `quizzes/`: knowledge checks.
- `resources.md`: external references.
