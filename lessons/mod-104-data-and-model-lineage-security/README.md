# mod-104-data-and-model-lineage-security: Data and Model Lineage Security — Signed Provenance, Immutable Audit, ML-BOM, Evidence Linking

> Scaffolded by `aicg org execute-plan`. Lecture chapters and exercise content are authored on subsequent autonomous cycles.

**Estimated effort:** 14 hours

## Learning objectives

- Architect end-to-end provenance for training data / features / model artifacts / evaluation runs — what is signed, what is logged, what is retained, and for how long
- Wire cosign / sigstore signing into the training pipeline so that each model artifact carries verifiable build provenance
- Produce an ML-BOM (AI-BOM) for a target model — components, datasets, third-party models, licences, provenance claims
- Wire lineage evidence into model-card and system-card authoring so external audiences can trace a claim to its underlying artifact
- Design an immutable audit-log architecture (WORM / append-only) for training, inference, and deployment events
- Cover requirement theme req-13

## Structure

- `01-…md` … `0N-…md`: lecture chapters.
- `exercises/`: per-exercise prompts.
- `labs/`: long-form hands-on labs.
- `quizzes/`: knowledge checks.
- `resources.md`: external references.
