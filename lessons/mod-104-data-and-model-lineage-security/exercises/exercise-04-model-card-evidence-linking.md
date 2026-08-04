# Exercise 04 — Model Card and System Card with Evidence Linking

**Estimated effort:** ~3 hours
**Deliverable:** (a) A published-quality model card in Hugging
Face `README.md` front-matter convention for the model you
authored the ML-BOM for in exercise 03, with every substantive
claim carrying an evidence link; (b) a signed evaluation-run
attestation attached to the model artifact; (c) a system card
for the product the model is deployed in, stitching model cards
together with deployment topology and safety mitigations; and
(d) a short automation script that regenerates the model card
from the ML-BOM + eval attestation.
**Prerequisites:** Chapters 01–05 read end-to-end. Exercises 02
and 03 completed. A model artifact with signed cosign signature,
SLSA attestation, and ML-BOM attestation already published.

---

## Objective

Turn a signed, ML-BOM'd model artifact into an externally-
publishable set of documents (model card + system card) where
every substantive claim carries an evidence link to a signed,
retrievable artifact. Then automate the card generation from
the underlying evidence so drift is prevented by construction.

By the end you should have a set of documents a regulator or
safety reviewer could walk from end to end — from a claim in
prose to a specific attestation UUID with a matching digest —
with no manual bridging.

## Problem statement

Continue from exercise 03. You have:

- A model artifact (`fraud-v42` or the Hugging Face model you
  chose) at digest `sha256:...`.
- A cosign signature verifiable against a pinned identity.
- A SLSA v1 provenance attestation.
- A CycloneDX ML-BOM attestation.

You do **not** yet have:

- A signed evaluation-run attestation.
- A published model card that links its claims to the
  underlying evidence.
- A system card describing the product the model runs in.

Your job is to produce those three and automate the model
card's generation.

## Requirements

### Deliverable A — signed evaluation-run attestation

Run an evaluation of the model on a defined eval set. The eval
set can be:

- A held-out slice of your training data (if you have real
  data).
- A well-known public eval set appropriate to the model's
  task.
- A synthetic eval set you construct — as long as its digest
  is stable and its provenance is knowable.

Produce an eval report file (JSON) containing at minimum:

- Model artifact digest under test.
- Eval-set URI and digest.
- Metric(s) with slice(s) and confidence interval(s).
- Evaluator identity.
- Start / end timestamps.
- Run URL if the eval framework has a UI (MLflow, W&B).

Attach as an in-toto attestation:

```
cosign attest \
    --predicate eval-report.json \
    --type "https://in-toto.io/attestation/test-result/v0.1" \
    <artifact-digest-ref>
```

Verify with `cosign verify-attestation` and confirm subject
digest matches the deployed model.

### Deliverable B — the model card

Publish-quality model card in Hugging Face `README.md`
front-matter convention. Committed to the exercise directory
(or, if you can, push it to an actual model repository on the
Hub or an internal card registry).

The card must:

- Have YAML front-matter with `license`, `tags`, `model-index`
  populated. `model-index.results.metrics` entries carry
  `verified: true` and `verified-signature-uri` pointing to
  the eval attestation's Rekor UUID.
- Have front-matter fields `mlbom-uri`, `provenance-uri`, and
  `artifact-digest` linking to the exercises-02/03 outputs.
- Contain body sections: description, intended use, out-of-
  scope use, training data, evaluation, limitations / ethical
  considerations / residual risk, changelog vs previous
  version, provenance and integrity.
- Every substantive claim in the body carries an evidence
  link — a URI (Rekor UUID, cosign transparency-log URL, or
  internal evidence-portal URL) plus a digest.
- The changelog section is populated from the exercise-03
  diff (added / removed / version-bumped components, licence
  changes, CVE deltas).
- The provenance section names the signing identity, the
  SLSA build level claimed, and the ML-BOM completeness
  aggregate.

### Deliverable C — the system card

For the product the model runs in (the `fraud` service, or a
plausible service context for the Hugging Face model you
chose), author a system card containing:

- **Overview** — what the system does end to end.
- **Deployment topology table** — one row per active
  deployment (region / model version / artifact digest /
  deployment date / `InferenceService` name), each with a
  link to the admission-decision audit entry that admitted
  it (from chapter 06).
- **Model card references** — links to each model card by
  content digest, not just by name.
- **Safety mitigations at the system layer** — at least three
  named mitigations (regional gating, human-in-the-loop
  thresholds, adversarial-eval cadence, drift monitoring),
  each with a link to the underlying attestation, policy, or
  runbook.
- **Residual risk** — at least two concrete residual risks
  the system layer cannot mitigate at the model layer.
- **Governance links** — DPIA, ISO 42001 conformance
  evidence, or the placeholders for these when the paired
  modules (mod-108, mod-109) have not yet been completed.
- **Incident-response link** — playbook + on-call channel.

Every link that points at an artifact must include a digest.
Names alone are not acceptable in a system card.

### Deliverable D — card automation script

A short script (`generate_model_card.py` or equivalent, up to
~100 lines) that:

- Takes the model artifact digest as input.
- Fetches the ML-BOM attestation, the SLSA attestation, and
  the eval-run attestation from the OCI registry / Rekor.
- Renders `README.md` from a template
  (`model_card_template.md.j2` or equivalent) populated with
  the fields above.
- Produces byte-identical output on repeated runs given the
  same evidence set.

The template does not need to be pretty. The point is:
regeneration is mechanical, and the model card cannot drift
from the underlying evidence because it is produced *from* the
evidence.

## Starter guidance

- Look at real-world model cards on Hugging Face to shape the
  narrative sections — good examples exist even if most cards
  in the wild lack evidence linking.
- The `model-index.results.metrics.verified` field is a
  Hugging Face convention; other card renderers (Google Model
  Card Toolkit, internal card registries) may use different
  keys. Pick the target renderer and align — the concept
  transfers.
- If you cannot push to Hugging Face, commit the card as
  `README.md` in the exercise directory and treat the local
  path as the publication surface.
- For evidence-URI format, `rekor://<UUID>` is a readable
  synthetic scheme; some templates prefer the full Rekor URL.
  Whichever you pick, be consistent.
- The system card is often the harder document because it
  requires you to model the *product*, not just the model.
  Sketch the deployment topology first, then work outward to
  mitigations.
- Do not fabricate governance evidence. If you have not
  produced a DPIA in mod-108 or an ISO 42001 conformance
  package in mod-109, mark the link as `<!-- placeholder:
  pending mod-108 completion -->` rather than inventing.

## Acceptance criteria

Passing work:

- Model card front-matter validates against the Hugging Face
  convention (or the target renderer you chose).
- Every substantive claim in the model-card body carries a
  URI + digest evidence link.
- Eval-run attestation is verifiable end to end; subject
  digest matches the deployed model.
- System card's deployment topology table names artifact
  digests, not just artifact names, for every active
  deployment.
- Automation script produces byte-identical output on repeat
  invocation.
- Every governance link either resolves to a real artifact or
  is explicitly marked as placeholder-pending-module.

Failing work:

- Prose claims without anchors ("trained on a curated
  dataset").
- Metrics without confidence intervals or slices.
- System card references model cards by name only.
- Automation script hand-populates fields instead of reading
  from evidence.
- Fabricated governance references.

## Stretch goals

- **Card diff.** Extend the automation to diff two consecutive
  cards and produce a "what changed since last version"
  digest email. This is what a customer-facing model-release
  notification would look like.
- **Signed card bundle.** Sign the rendered card as a blob
  (`cosign sign-blob --bundle`) and reference the signed
  bundle from the deployment audit-log entry (chapter 06
  event `model.deployment.applied`), so at any future point,
  the card that described the model at deploy time is
  provably retrievable.
- **Redacted evidence bundle.** For an external audience that
  should not see internal Rekor UUIDs, produce a
  redacted-but-verifiable evidence bundle (hashes of the raw
  evidence, external-verifier proof of inclusion) and rewire
  the model card's evidence links to point at it. Discuss
  the trade-offs.
- **Regulator template mapping.** Map the model card + system
  card fields to the EU AI Act Annex IV technical
  documentation template (verify current text). Which fields
  are covered, which are gaps, which would need extra
  documentation to complete.

## Do not

- Do not publish a real model card to Hugging Face for a
  model that isn't yours or that names data / people whose
  handling you cannot vouch for.
- Do not commit a solution to this repository.
- Do not fabricate evaluation numbers to make the card look
  better; the model-index metrics must be from an actual eval
  run whose attestation you signed.
- Do not include personally-identifiable information from
  the training set in card examples.
