# Exercise 01 — SLSA Self-Assessment

**Estimated time**: 2 hours
**Deliverable**: A per-pipeline SLSA scoring + remediation plan

---

## The assignment

Score each of SmartRecs' build pipelines against SLSA Build
levels (L1, L2, L3+). For each pipeline:

1. **Identify the current level**.
2. **Identify the gaps** to the next level.
3. **Propose a remediation plan**.

## Pipelines in scope

- `recs` image build (Python ML serving).
- `fraud` image build (Python ML serving).
- `customer-support-llm` image build (vLLM-based).
- `model-trainer` image build (training jobs).
- Terraform / IaC pipeline.
- Helm chart releases.
- The "model promotion" pipeline (Module 09 §9.1).

## What "current level" means concretely

For each, ask:

- **L1**: Does the build run in CI? Does it produce a
  provenance document?
- **L2**: Is the provenance signed by an identity that's
  cryptographically tied to the build platform?
- **L3**: Are the build environments hardened? Two-party review
  of build-config changes? No SSH / interactive access to
  running builds? Provenance not falsifiable by the developer?

## Format

```
# SLSA Self-Assessment: SmartRecs

## Summary

| Pipeline | Current level | Target level | Gap effort |
|---|---|---|---|

## Per-pipeline

### `recs` image build
- Current level: <L1/L2/L3>
- Evidence supporting the score
- Gaps to next level
- Remediation
- Estimated effort

### `fraud` image build
...

### `model-trainer` image build
...

### Model promotion pipeline
- Note: this is a non-standard pipeline. Apply SLSA's
  principles even where the spec doesn't directly fit.

### IaC / Terraform pipeline

### Helm chart releases

## Cross-cutting gaps
(Things missing across pipelines — e.g., no provenance
attestations anywhere, no signature on Helm charts.)

## Prioritization
(Which pipelines have the highest blast radius if compromised?
Address those first.)

## Sequencing — getting from current to target

### Quarter 1 (foundations)
### Quarter 2 (Build-L2 across all pipelines)
### Quarter 3 (Build-L3 where justified)
```

## Quality criteria

A passing assessment:

- Each pipeline has a **defended score**, not a self-promoted
  one.
- Gaps are **specific** (e.g., "no Cosign signing in
  Helm release workflow") not generic ("missing controls").
- Remediation is **actionable** (a specific change, in a
  specific file, with a specific effort estimate).
- The prioritization is by **blast radius**, not by ease.

A failing assessment:

- All pipelines claim L3.
- No remediation plan.
- Prioritization is "do them in order."
- Treats "we use GitHub Actions" as automatically meaning L2.

## Reflection questions

1. Which pipeline is the largest blast-radius compromise
   target? Defend.
2. Which gap is the **easiest to close** for the biggest
   security improvement?
3. The team objects: "SLSA L3 is overkill for us." Argue both
   sides; defend whichever you believe.
