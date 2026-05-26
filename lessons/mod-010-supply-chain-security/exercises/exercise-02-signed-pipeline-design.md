# Exercise 02 — Signed-Pipeline Design

**Estimated time**: 2–3 hours
**Deliverable**: End-to-end pipeline design + CI YAML

---

## The assignment

Design SmartRecs' signed pipeline for the `recs` image and
the recommender model. The pipeline produces:

1. A **signed container image**.
2. A **SLSA Provenance attestation**.
3. A **CycloneDX SBOM** attestation.
4. A **vulnerability scan** attestation.
5. (For the model) a **signed model artifact**.
6. (For the model) **training-provenance** + **validation** +
   **approval** attestations.

All attestations are verified at admission (Exercise 03).

## Required deliverables

1. **A pipeline diagram** showing what's signed by whom at
   each stage.
2. **The GitHub Actions workflow** (or equivalent) that does
   the signing.
3. **The OIDC trust configuration** required.
4. **The signing identity per stage** (training CI vs. build
   CI vs. promotion CI).
5. **The attestation flow** — what attestations get attached
   to which subjects.
6. **The Cosign verification commands** an operator would run
   to manually verify a deployed image.
7. **The rollback plan** if signing fails for a critical
   release.

## Format

```
# Signed Pipeline Design: SmartRecs `recs`

## Pipeline diagram
(Mermaid or ASCII showing build, sign, attest, verify.)

## Signing identities

| Stage | Identity | Trust chain |
|---|---|---|

## GitHub Actions workflow

### .github/workflows/build.yml
(YAML for image build + SBOM + scan + sign)

### .github/workflows/train.yml
(YAML for training + model signing + attestations)

### .github/workflows/promote.yml
(YAML for promotion + approval attestation)

## OIDC trust configuration

### IAM role trust policy (for AWS) or equivalent

## Attestations attached to each artifact

| Artifact | Attestations |
|---|---|

## Operator verification commands

(What a SRE runs to manually verify an image was built by
the expected workflow.)

## Failure modes
- Sigstore down: ...
- Fulcio cert issuance fails: ...
- Rekor unreachable: ...
- The signing step itself fails: ...

## Rollback plan

## What this design does NOT solve
(Be honest. What threats remain even with this design?)
```

## Quality criteria

A passing design:

- The workflow YAML is **realistic** (could be deployed with
  minor adaptations).
- Multiple signing identities — training-CI vs. build-CI vs.
  promotion-CI — are correctly distinct.
- The attestation flow is **complete** for both image and
  model.
- Operator-verification commands are concrete.
- Failure modes are addressed honestly.

A failing design:

- A single identity signs everything.
- Attestations are only on the image, not the model.
- No failure-mode consideration.
- No rollback.

## Reflection questions

1. Which stage is hardest to keep cleanly separated (different
   identity)?
2. Sigstore's public services go down for 2 hours. What
   actually breaks? Can you still deploy?
3. The team objects: "Signing slows down the build." Quantify
   the actual overhead; defend the trade-off.
