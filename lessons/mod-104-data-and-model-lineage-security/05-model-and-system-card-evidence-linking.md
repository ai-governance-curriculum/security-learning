# Chapter 05 — Model Cards and System Cards: Linking Every Claim to Signed Evidence

> **Note on AI-assisted content.** Model card and system card
> conventions are evolving; the terms are used differently by
> different vendors. This chapter follows Mitchell et al. 2019 for
> "model card" and follows the Meta / OpenAI usage for "system
> card". Verify current formal definitions and any organisation-
> specific templates before publishing externally. See
> [`resources.md`](./resources.md).

---

## Why this chapter exists

Chapters 02–04 produced the machine-readable evidence chain:
signed model artifact, SLSA provenance, CycloneDX ML-BOM. Those
artifacts are consumed by admission gates and by machines. This
chapter authors the **human-readable narratives** — model cards
and system cards — that expose the same evidence to external
audiences: regulators, procurement, safety reviewers, customers,
end users.

The specific failure mode this chapter is written to prevent:

> A team publishes a model card. It says the model "was trained
> on a proprietary dataset filtered to remove personally
> identifiable information" and reports an AUC of 0.94 on an
> internal test set. A regulator asks: "which dataset version,
> which filter rule, which internal test set, and when?" The
> team cannot answer without going back to MLflow, git, and
> Slack — the card contains claims but no anchors. The regulator
> asks whether the model in production today is *the same
> model* the card describes. The team is not sure — a rollout
> happened last month that may have promoted a different
> artifact. The card is prose without proof.

A model card that links every claim to a signed, retrievable
artifact is the difference between "documented" and
"documented, verifiable, and non-repudiable". Each of the
following claims should be traceable to a signed evidence
record, not a screenshot or a Slack link:

- "Trained on dataset X" → dataset snapshot digest with signed
  manifest (chapter 02) → row-count and region-filter attested
  in the ML-BOM component properties (chapter 04).
- "Achieves AUC 0.94 on eval set Y" → signed eval-report
  attestation whose subject is the deployed model digest and
  whose eval-set digest is in the ML-BOM.
- "Built from base model Z" → base-model reference in the ML-BOM
  → SLSA `resolvedDependencies` entry with digest.
- "In production as of 2026-04-15" → deployment audit-log
  entry (chapter 06) linking the served digest to a
  named `InferenceService` at that timestamp.

You leave this chapter able to:

- Author a model card whose every substantive claim carries a
  URI to a signed evidence artifact.
- Author a system card that stitches together multiple model
  cards, the deployment topology, and the operational safety
  posture into a single reviewable document.
- Publish evaluation-run attestations that pin the eval report
  to the exact model digest and the exact eval-set digest.
- Establish the automated pipeline that regenerates the card
  when a new signed model artifact is admitted, so cards do
  not drift from the artifact they describe.

---

## Model card vs system card — the distinction

The two terms overlap in common usage; keep them separate for
this chapter's purposes.

### Model card (Mitchell et al. 2019, and its descendants)

A document describing a **single model** — its intended use,
training data at a summary level, performance characteristics
across relevant slices, known limitations, ethical
considerations. Publisher formats:

- The Mitchell et al. 2019 template — freeform Markdown /
  document sections; the reference implementation of the
  concept.
- Hugging Face's YAML front-matter + Markdown body on the
  `README.md` of a model repository — the de-facto convention
  in the open-source model ecosystem.
- Google's Model Card Toolkit (`model-card-toolkit`) — a JSON
  Schema and rendering library.
- CycloneDX's `modelCard` sub-object within the ML-BOM
  (chapter 04's example includes one) — a machine-readable
  version co-located with the BOM.

### System card (Meta, OpenAI, Anthropic usage)

A document describing a **deployed system** in which one or
more models participate. Covers the *product* / *use case*:
what the system does end to end, which model(s) it uses, what
safety mitigations are in place at the system layer (guardrails,
retrieval boundaries, tool-use policy, human-in-the-loop), what
evaluations were run at system integration, and what residual
risks exist that a single model card cannot address.

System cards are the appropriate publication vehicle for LLM-
based agent applications, RAG systems, and product-level
disclosures. Mod-107 (LLM and Agent Security) builds on this
chapter by adding the agent-specific safety-posture sections.

### The relationship

A system card **references** one or more model cards. A model
card **describes** one model. Both **link to** the signed
evidence chain this chapter installs.

---

## The evidence-linking convention

The rule for every published card:

> Every substantive claim in the card body carries an
> **evidence link** — a URI to a signed, retrievable artifact
> that supports the claim, plus the digest of that artifact.

Concretely, a model-card claim like:

> "Fraud-v42 achieves ROC-AUC 0.94 on the `regulator-2026-Q1`
> eval set."

becomes:

> "Fraud-v42 achieves ROC-AUC 0.94 on the `regulator-2026-Q1`
> eval set. **Evidence:**
> [eval-report:fraud-v42-2026-04-05](rekor://...uuid...) sha256:eee...

The evidence link resolves to:

1. A signed in-toto attestation whose predicate is an eval
   report.
2. The subject is the model artifact digest
   (`sha256:abc...` — matches the deployed model).
3. The eval report content includes the eval-set digest
   (`sha256:fff...` — also present in the ML-BOM), the metric,
   the confidence interval, and the run timestamp.

A reader can:

- Verify the attestation signature (Sigstore trust root).
- Verify the subject digest matches the deployed model.
- Verify the eval-set digest matches the eval-set referenced in
  the ML-BOM.
- Pull the raw eval report for full detail.

That is what "verifiable" means. The card is not the record; the
card is the human-readable narrative *over* the record.

---

## The evaluation-run attestation

Chapters 02–04 covered the training-time attestations. The
evaluation-run attestation is the fifth object class from
chapter 01 in artifact form.

The evaluation-run predicate structure (using in-toto's test-
result predicate type as a base — verify current predicate
schemas for eval-specific extensions):

```json
{
  "_type": "https://in-toto.io/Statement/v1",
  "subject": [
    { "name": "fraud", "digest": { "sha256": "abc123..." } }
  ],
  "predicateType": "https://in-toto.io/attestation/test-result/v0.1",
  "predicate": {
    "result": "PASSED",
    "configuration": [
      {
        "uri": "eval-set://regulator-2026-Q1",
        "digest": { "sha256": "fff..." }
      },
      {
        "uri": "eval-config://acme/fraud-standard",
        "digest": { "sha256": "ggg..." }
      }
    ],
    "url": "https://mlflow.acme.internal/#/experiments/42/runs/eval-2026-04-05-xyz",
    "passedTests": ["auc_threshold", "coverage_check"],
    "warnings": [],
    "metrics": [
      {
        "name": "roc_auc",
        "value": 0.941,
        "slice": "overall",
        "confidence_interval": [0.933, 0.949]
      },
      {
        "name": "false_positive_rate",
        "value": 0.032,
        "slice": "high_value_txn",
        "threshold": 0.05
      }
    ],
    "runDetails": {
      "startedOn": "2026-04-05T08:00:00Z",
      "finishedOn": "2026-04-05T08:41:12Z",
      "evaluatorSpiffeID": "spiffe://acme.internal/plane/evaluation/pipeline/fraud-eval"
    }
  }
}
```

Attach with cosign:

```
cosign attest \
    --predicate eval-report.json \
    --type "https://in-toto.io/attestation/test-result/v0.1" \
    registry.acme.internal/models/fraud@sha256:${MODEL_DIGEST}
```

The evaluation pipeline signs with its own SPIFFE identity —
distinct from the training pipeline's — so a verifier can check
"training and evaluation were done by separated identities" (a
useful separation-of-duties signal).

Multiple eval-run attestations per artifact are normal and
expected: the model runs against many eval sets over its
lifetime.

---

## Publishing model cards (Hugging Face convention)

The Hugging Face `README.md` YAML-front-matter convention is
widely tooled. A model card annotated with evidence links:

```yaml
---
license: apache-2.0
tags:
  - fraud-detection
  - fine-tuned
model-index:
  - name: fraud-v42
    results:
      - task:
          type: text-classification
        dataset:
          name: regulator-2026-Q1
          type: internal
        metrics:
          - type: roc-auc
            value: 0.941
            verified: true
            verified-signature-uri: rekor://...eval-uuid...
mlbom-uri: rekor://...mlbom-uuid...
provenance-uri: rekor://...slsa-uuid...
artifact-digest: sha256:abc123...
---

# fraud-v42

**Artifact digest:** `sha256:abc123...`
**ML-BOM:** [rekor://...mlbom-uuid...](...) (CycloneDX 1.6)
**SLSA v1 provenance:** [rekor://...slsa-uuid...](...)

## Model description

Fraud-scoring model fine-tuned from
[`base-transformer-v3`](rekor://...base-uuid...) on the
[`fraud-training-snapshot@v2026-03-31`](rekor://...ds-uuid...)
dataset.

## Intended use and out-of-scope use

Used to score real-time credit-card transactions in the
`fraud-service` production system. **Not** intended for
applications outside credit-card transactions or in
jurisdictions without EU-AI-Act-equivalent oversight.

## Training data

**Snapshot:** `pkg:acme-datasets/fraud@v2026-03-31`,
[`sha256:bbb...`](rekor://...ds-uuid...),
12,403,927 rows, EEA region excluded per 2026 data-governance
policy. Full lineage: see the
[ML-BOM](rekor://...mlbom-uuid...).

## Evaluation

Evaluated on `regulator-2026-Q1` eval set (digest
`sha256:fff...`); overall ROC-AUC 0.941 (CI [0.933, 0.949]);
FPR on the `high_value_txn` slice 0.032 (below threshold
0.05). Signed eval report:
[rekor://...eval-uuid...](...).

## Limitations, ethical considerations, and residual risk

- The excluded-EEA design decision means this model must not
  be deployed for EEA customers. System-level enforcement is
  in [`system-card:fraud-service-v3`](...).
- Confidence intervals widen on transactions below $10; see
  eval report for the sliced breakdown.

## Changelog vs previous version

Diff of ML-BOM `fraud-v41` → `fraud-v42`:

- Training-snapshot version advanced (`v2026-03-15` →
  `v2026-03-31`; +411,203 rows).
- `transformers` library upgraded (`4.40.2` → `4.41.2`);
  CVE-2024-XXXX in `4.40.2` closed.
- Eval set unchanged (`regulator-2026-Q1`).

## Provenance and integrity

- **Signature:** cosign keyless, issuer
  `https://spire-oidc.acme.internal`, subject
  `spiffe://acme.internal/plane/training/pipeline/fraud-trainer`.
- **Build platform:** SLSA v1 Build L2 (attestation:
  [rekor://...slsa-uuid...](...)).
- **BOM completeness:** `aggregate: complete`.
```

Every substantive claim points at a verifiable artifact. A
reader with a healthy scepticism can walk from the card to the
Rekor entry to the raw evidence in fewer clicks than it takes to
open Slack.

---

## Publishing system cards

A system card sits above the model cards for a product. For a
fraud-service:

```markdown
# Fraud Service — System Card v3

**Deployed system:** `fraud-service` (production, `us-east-1`,
`eu-west-1`).
**Model(s):** [`fraud-v42`](model-card:fraud-v42) served in
`us-east-1`; [`fraud-v41`](model-card:fraud-v41) served in
`eu-west-1` (v42 not authorised for EEA customers per model-
card constraint).

## What the system does

Scores merchant transactions at authorisation time. Returns a
probability of fraud in the 0.0–1.0 range. Decisions above
0.85 are declined; between 0.5 and 0.85 are held for manual
review; below 0.5 are approved.

## Deployment topology

| Region | Model | Deployment digest | Deployment date | InferenceService |
| --- | --- | --- | --- | --- |
| us-east-1 | fraud-v42 | sha256:abc... | 2026-04-15 | fraud-prod (admission decision: [audit://...adm-uuid...](...)) |
| eu-west-1 | fraud-v41 | sha256:xyz... | 2026-02-10 | fraud-prod-eu (admission decision: [audit://...adm-uuid...](...)) |

## Safety mitigations at the system layer

- **Regional model gating.** `fraud-v42` blocked from EEA
  deployment by admission policy (mod-103 chapter 06
  constraint `region-model-authorisation`).
- **Human-in-the-loop for 0.5–0.85.** Held transactions
  routed to the manual-review queue; escalation SLA 4 hours.
- **Adversarial retraining cadence.** New model produced
  monthly; each new model must pass mod-106 adversarial
  eval suite. Attestations:
  [rekor://...adv-eval-uuid...](...) per release.
- **Drift monitoring.** Live feature distributions compared
  hourly against the training snapshot. Alerts route to
  fraud-oncall.

## Residual risk

- Novel merchant categories not in training data may be
  misclassified until the next monthly retrain.
- Vendor-supplied MCC (merchant category code) database has
  its own update cycle; we accept up to a 30-day lag.

## Governance

- **Data protection impact assessment:** 2026-02-01
  [dpia:fraud-service-v3](...) (mod-108 privacy engineering).
- **ISO 42001 conformance evidence:** [iso42001:2026-Q1](...)
  (mod-109).

## Incident-response link

- Playbook: [ir:fraud-service](...) (mod-111 SecOps).
- On-call: `#fraud-oncall`.
```

The system card is the artifact external stakeholders (safety
reviewers, procurement counterparties, regulators) actually
read. Everything technical in it should resolve, via evidence
links, to a signed artifact.

---

## Automating card generation

Two automation modes.

### Mode A — templated card generation at build time

The training pipeline's final step, alongside the ML-BOM
generation, populates a card template from:

- The model artifact digest.
- The ML-BOM (dataset, base model, dependencies).
- The provenance predicate (source revision, build ID).
- The eval-run attestation (metrics, confidence intervals).
- The organisation's card template (`model-card-template.md.j2`).

The rendered card is committed to the model's Hugging Face
repository (or internal card registry) as part of the release.
Any change to the model triggers a change to the card;
divergence is not possible.

### Mode B — card as a first-class deployable

The card itself is versioned, digested, and signed:

```
cosign sign-blob --bundle card-fraud-v42.bundle fraud-v42.md
```

The signed card bundle is published alongside the model artifact
in the registry, and its digest is referenced from the
deployment audit log. At any future point, the card that
described the model at deployment time is provably retrievable.

### Do not — manual card authoring divorced from the artifact

Manual card authoring produces cards that drift the moment the
artifact rev's. The card ends up describing what someone
*remembered* about the model, not what the model *is*. Automate,
even if the automation is a shell script that fills a template
from the ML-BOM.

---

## Cross-references to other modules

Model and system cards are consumed and shaped by several other
modules; call them out at authoring time.

- **mod-106 Adversarial ML Defence.** Adversarial-eval results
  appear as their own eval-run attestations and are cross-
  referenced from the model card's "robustness" section.
- **mod-107 LLM and Agent Security.** LLM system cards add
  sections on prompt-injection posture, tool-use scope,
  retrieval boundaries, and RLHF preference data. The evidence-
  linking convention is unchanged; the sections are additive.
- **mod-108 Privacy Engineering.** DP guarantees, PII handling,
  and privacy-impact assessments appear in the system card and
  are linked to the underlying evidence (DP-epsilon
  attestations, DPIA documents).
- **mod-109 AI Governance and Compliance Engineering.** The
  system card is *evidence input* to the governance audit; the
  auditor will walk the evidence links.
- **mod-111 SecOps and IR for ML.** Incident-response playbook
  links appear in the system card so a responder can find the
  runbook without a search.

The card is the joint artifact of the whole track. This chapter
authors the connective tissue; each specialised module fills
its section.

---

## What this chapter does not cover

- **Regulator-specific submission templates.** Some regimes
  (EU AI Act Annex IV, FDA SaMD 510(k) submissions for medical
  ML) prescribe technical-documentation templates whose fields
  overlap with model and system cards but are not identical.
  Mod-109 handles regime-specific submission authoring.
- **Model-hub UI conventions.** The exact YAML-front-matter
  keys Hugging Face renders in its UI are specific to that
  platform; verify current supported keys before publishing.
  Internal card registries may have different conventions;
  align the template to the target renderer.
- **The audit log itself.** Chapter 06 covers the audit-log
  infrastructure the card's deployment section references.

---

## The mistakes this chapter is trying to prevent

- **Claims without anchors.** "Trained on a curated dataset"
  is not a claim; "trained on `pkg:acme-datasets/fraud@v2026-
  03-31 sha256:bbb...`" is.
- **Metrics without confidence intervals or slices.** A single
  AUC number tells you very little. Slice-and-CI reporting is
  what regulators and safety reviewers will demand.
- **Cards that describe an outdated version.** The card must
  regenerate when the artifact regenerates. Otherwise the
  published card describes yesterday's model.
- **System cards that reference model cards by name only.**
  Reference by *model card content digest* — a plain name
  can be swapped.
- **Card evidence links to internal-only URLs.** External
  audiences cannot follow internal-only links; the evidence
  must be routable through the organisation's evidence-
  publication surface (a public Rekor mirror, an
  authenticated evidence-access portal, or a redacted /
  hashed evidence bundle for external readers).
- **Signing the card but not the evidence the card references.**
  The card can be signed as a document; the value is only
  present when the *linked* artifacts are also signed.

---

## Summary

- Model cards describe a single model; system cards describe a
  deployed product built on one or more models. Both are
  human-readable narratives over the machine-readable evidence
  chain of chapters 02–04.
- Every substantive card claim carries an evidence link — a
  URI to a signed, retrievable artifact plus its digest. A
  reader can walk from the claim to the evidence in a few
  clicks; a regulator can verify the deployed artifact is the
  one the card describes.
- The evaluation-run attestation is the fifth object class from
  chapter 01: an in-toto Statement whose subject is the model
  digest and whose predicate reports metrics, slices, and
  confidence intervals — signed by an evaluator identity
  separated from the training identity.
- Publish model cards in the Hugging Face YAML-front-matter
  convention or the CycloneDX `modelCard` sub-object; publish
  system cards as standalone Markdown that references model
  cards by digest.
- Automate card generation from the pipeline's own artifacts;
  never rely on manual editing that will drift.
- Cross-reference the specialised sections that other modules
  fill (adversarial evaluation, privacy, LLM-specific safety,
  governance evidence, IR playbooks).
- The next chapter (06) authors the immutable audit log that
  the deployment section of every system card references.
