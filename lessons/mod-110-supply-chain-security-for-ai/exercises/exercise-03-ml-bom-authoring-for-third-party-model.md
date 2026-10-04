# Exercise 03 — ML-BOM Authoring for a Third-Party Model

**Estimated effort:** ~3 hours
**Deliverable:** A committed ML-BOM bundle for one real
third-party-model integration, consisting of (a) a complete
**CycloneDX 1.6 ML-BOM** (SPDX 3.0 AI/Dataset-profile as a
secondary option) describing the deployed system — the
output model, the base model, all training / fine-tuning /
preference datasets, the eval bundle, and the ambient
software dependencies, (b) a **licence-obligations summary**
derived from the component licence set, (c) a **build-time
generator** (short Python or shell script) that produces
the ML-BOM from a resolved pipeline-spec file rather than
by hand, (d) a **consumer-side demo** showing three real
workflows the ML-BOM supports — DMCA / consent-takedown
query, admission-time licence policy evaluation, DSAR data-
subject lookup — each with a short script or Rego policy,
(e) a **signed attestation** attaching the ML-BOM to a
model artefact digest with `cosign attest --type cyclonedx`,
and (f) a one-page **gaps-and-caveats** writeup stating what
the ML-BOM does and does not describe, with an explicit
list of fields that are placeholders versus fields that are
grounded in real pipeline data.
**Prerequisites:** Chapters 03, 02, and 05 read end-to-end.
A workstation with Python, `jq`, `cosign`, and (optionally)
`cyclonedx-python-lib` or similar. Access to one deployed
system that integrates a third-party base model — this can
be a staging deployment, a prototype, or a research project
you can describe in detail. Access to the training data
inventory for that system (names, versions, licences) even
if the data itself is not accessible.

---

## Objective

Chapter 03's thesis is that an **ML-BOM reconstructed
after the fact is plausible but unauditable**; the pipeline
must emit it at build time, signed by the build platform,
indexed in the mirror, and consumed by admission policy.
This exercise is the exercise that produces a working
example of all four — not a demo in isolation, but a
reference your programme could reuse.

By the end of this exercise you have:

- A real CycloneDX 1.6 ML-BOM for a real-shape system.
- A licence-obligations summary written against the
  specific licences at play in your system.
- A build-time generator script that would run inside
  your training pipeline.
- Three consumer-side workflows that *use* the ML-BOM.
- A signed cosign attestation attaching the ML-BOM to a
  model artefact.
- A gaps-and-caveats writeup separating real from
  placeholder.

You are **not** rolling out ML-BOM programme-wide. You are
producing the reference bundle.

---

## Problem statement

Pick one system that integrates a third-party model. State
the pick:

- A **translation / summarisation / classification
  service** backed by a HF Hub base model (DistilBERT,
  BART, Flan-T5, Mistral-7B-Instruct, etc.) fine-tuned
  internally.
- A **vector-embedding or retrieval system** using an
  open-weights embedding model (e5, bge, GTE).
- A **vision classifier** fine-tuned from a pretrained
  backbone (ResNet, ViT, SAM).
- A **generative image system** using a Stable Diffusion
  variant or similar (watch for the OpenRAIL licence).

Enumerate for the system, as fact-grounded as you can:

- The deployed model artefact (name, version). If you are
  using an exercise-02 artefact, say so.
- The base model (name, HF repo, revision SHA). If the
  revision SHA is not yet pinned in production, pick a
  real SHA from the repo and use it.
- The fine-tuning dataset(s). Name, version / snapshot
  ID, source, licence. Internal datasets: use real
  version IDs; public datasets: pin the HF Datasets
  revision.
- Preference / alignment data if present (for
  instruction-tuned or RLHF variants).
- The eval bundle (name, version). If mod-106 or mod-104
  chapter 06 produced one, reference it; otherwise
  describe a plausible shape and mark it placeholder.
- Ambient software dependencies: Python lockfile hash;
  container image digest; CUDA / cuDNN pinned versions.

The exercise rejects "I'll figure out the dataset later";
the whole point of the ML-BOM is to answer "what went
into this model" definitively.

---

## Requirements

### Deliverable A — the ML-BOM document

A single valid CycloneDX 1.6 JSON file (`mlbom.cdx.json`)
following chapter 03's shape. Required elements:

- `bomFormat: CycloneDX`; `specVersion: 1.6`.
- `metadata.timestamp` (fixed; not auto-generated).
- `metadata.component`: `type: machine-learning-model`,
  the deployed model, with its own hash, licence, model-
  card content.
- `components` array containing, at minimum:
  - The **base model** (`type: machine-learning-model`,
    pinned revision, licence, supplier).
  - Every **training dataset** (`type: data`, content-
    addressed, licence, consent basis, row count).
  - Every **fine-tuning / adapter component**.
  - The **eval bundle** (`type: data` or custom; cite
    mod-104 chapter 06's eval-bundle layout if your eval
    team uses it).
  - Container / Python / CUDA dependencies (reference
    the container-SBOM via `externalReferences` rather
    than inline duplication).
- `dependencies` array capturing the `dependsOn`
  relationships: deployed model → base model + datasets
  + adapter; etc.

Optional but worth adding when relevant:

- `tokenizer` / `processor` component (version-pinned).
- Safety classifiers bundled with the serving stack.
- System prompt / tool registry (for agentic deployments).

Validate the JSON against the CycloneDX 1.6 schema
(project publishes one). State the validator used
(`cyclonedx-cli validate`, `jsonschema`, or similar).

### Deliverable B — licence-obligations summary

A short document (`license-obligations.md`) that walks
each component in Deliverable A and states:

- The identified licence (SPDX ID or custom licence
  name + URL + content hash).
- The specific obligations imposed on the deployed
  system by this licence: attribution, redistribution,
  derivative-work rules, acceptable-use clauses, scale-
  threshold triggers (e.g. Meta Llama community licence
  user-count thresholds), region or sector restrictions.
- The **composition**: when multiple licences apply, the
  effective obligation set the deployed system inherits.
- Any **unresolved issues** — missing licence file,
  licence text that references yet-undocumented
  obligations, licence drift between the version pinned
  and the current URL contents.

For public base models, verify against the current
licence URL and record the licence text SHA at retrieval
time. For internal datasets, cite the internal licence /
usage agreement reference.

The summary is the artefact a product counsel reviewer
reads before approving the deployment; the ML-BOM is the
input to the summary.

### Deliverable C — build-time generator

A short script (`generate-mlbom.py` is the obvious
form; `generate-mlbom.sh` or a tiny Go program is also
fine) that:

1. Reads a **resolved pipeline-spec** YAML file. Use the
   chapter-03 shape as the starting point.
2. Validates the spec has the required fields; a missing
   field is a fatal error (`exit 1`), not a silent omission.
3. Emits a CycloneDX 1.6 JSON document matching Deliverable
   A. The script does not accept content from arbitrary
   build-step metadata — the spec is the source of truth.
4. Prints the SHA-256 of the generated JSON for signing.

The script is deterministic: same input → same output.
Timestamps are either omitted or set from a `--timestamp`
flag the pipeline populates with the build start time.

Commit the pipeline-spec YAML alongside the script so a
reviewer can reproduce the generator run:

```bash
python generate-mlbom.py \
  --spec pipeline-spec.resolved.yaml \
  --timestamp 2026-10-04T15:02:00Z \
  --out mlbom.cdx.json
```

Rules:

- **No network calls.** The generator reads the spec and
  writes JSON. Looking up component details online is a
  job for the intake / resolve step upstream.
- **No judgement.** If the spec lists a dataset without a
  licence, the generator fails. It does not fill a licence
  in from a default.
- **Composable.** The script's output can be concatenated
  into a larger ML-BOM at a higher composition level
  (chapter 03's `dependencies.dependsOn` is the join
  key).

### Deliverable D — three consumer-side workflows

For each, a small script (bash + jq, Python, or a Rego
policy evaluated with `opa eval`) that reads the ML-BOM
JSON and answers a specific question.

1. **DMCA / consent-takedown query.**
   > "A dataset I used has had a consent revocation. Which
   > deployed models carry it?"
   The script takes a dataset `bom-ref` (e.g.
   `data:ticket-corpus@v3`) and prints every model whose
   ML-BOM references it (directly or transitively through
   `dependsOn`). For a single-model bundle the answer is
   trivial; show how the query generalises if you were
   indexing many ML-BOMs.

2. **Admission-time licence policy.**
   > "At promotion to production, every
   > `machine-learning-model` and `data` component must
   > have a licence; any OpenRAIL / RAIL / custom-
   > community licence requires the obligations property
   > populated."
   A short Rego policy that reads the ML-BOM and emits
   an `allow` / `deny` decision with reasons. The policy
   mirrors the mod-109 chapter 04 shape — one control per
   file, violation objects carrying `rule`, `remediation`,
   and taxonomy refs.

3. **DSAR data-subject lookup.**
   > "A data subject has made an erasure request. Which
   > deployed models were trained on data that may contain
   > their records?"
   A script that takes a data-subject identifier (or a
   source dataset `bom-ref` identifying where their
   records live), walks the ML-BOM's `dependsOn` graph
   to find any dependent model, and prints the model
   list. The script does not resolve "does this
   subject's record actually appear in this dataset" —
   that is the DLP coverage log's job (mod-108 chapter
   03) — but it narrows the search space.

Each workflow has a one-paragraph writeup: the question
it answers, the input/output shape, the limitations.

### Deliverable E — signed attestation attachment

Attach the ML-BOM to a model artefact's cosign attestation
set:

```bash
cosign attest \
  --predicate mlbom.cdx.json \
  --type cyclonedx \
  --oidc-issuer <issuer> \
  <registry>/<name>@sha256:<digest>
```

Then verify:

```bash
cosign verify-attestation \
  --type cyclonedx \
  --certificate-identity-regexp '^<expected-signer>$' \
  --certificate-oidc-issuer '<issuer>' \
  <registry>/<name>@sha256:<digest> \
  | jq -r '.payload | @base64d | fromjson | .predicate' \
  > mlbom.verified.cdx.json

diff mlbom.cdx.json mlbom.verified.cdx.json  # should be empty
```

Capture both commands and their outputs. If you did not
produce a signed artefact in exercise 02, do so here
first; the attestation is bound to an artefact digest.

### Deliverable F — gaps-and-caveats writeup

One page explicitly listing:

- Fields that are grounded in **real pipeline / system
  data** (where you had the facts).
- Fields that are **placeholders** (where you did not,
  with reason — the eval bundle isn't produced yet; the
  dataset consent basis is approximate; etc.).
- What the ML-BOM **does not describe** — weight-space
  behaviour, prompt-injection resilience, bias profile,
  energy use (unless you populated the SPDX AI-profile
  `energyConsumption` field). The ML-BOM is a build-time
  inventory, not a safety evaluation.
- The **retention plan** for this ML-BOM: where it is
  stored, how long, under what identity.

The caveats document exists so a reader does not mistake
the ML-BOM for a safety or correctness claim.

---

## Starter guidance

- **Start from a real base model and real licence.**
  Even if the training data is fictional (because you
  don't have access), the base-model row should be real:
  pick DistilBERT or Flan-T5 and look up the actual
  licence and revision SHA.
- **Hash the licence text at retrieval.** For custom
  community licences, download the licence file, compute
  SHA-256, and reference the hash. The licence URL is
  not stable.
- **Reference the container SBOM, do not inline.** The
  container-image SBOM is produced by Syft / Trivy;
  reference it via `externalReferences` in your ML-BOM
  rather than copying its component tree.
- **Keep PII values out.** Dataset components carry
  row counts, schema sketch, consent basis. Not sample
  rows.
- **Validate the JSON before signing.** CycloneDX
  validators flag minor shape issues; invalid JSON is
  invalid once signed.
- **Make the generator refuse bad input.** The pipeline-
  spec is the contract. A missing licence line in the
  spec is a build failure, not a BOM gap.
- **Use the chapter-03 property names consistently.**
  `ml:dataset:row-count`, `ml:license:obligations`,
  `ml:intake:scan-attestation`, etc. Downstream policy
  binds to these names.

---

## Acceptance criteria

A passing bundle:

- CycloneDX 1.6 JSON validates against the schema.
- Every `machine-learning-model` and `data` component has
  a licence, a version / hash pin, and a supplier field.
- Dataset components carry at least row count, consent
  basis (or equivalent), and a content-addressed
  reference.
- Licence-obligations summary walks each licence,
  compositely states the inherited obligations, and
  flags unresolved issues.
- Generator script is deterministic, refuses malformed
  spec, and takes `--timestamp` as a flag.
- All three consumer workflows return a sensible answer
  on your ML-BOM; the Rego policy produces allow / deny
  with reasons; the DMCA and DSAR scripts walk the
  dependency graph correctly.
- Signed cosign attestation attached and verifiable; the
  verified attestation diffs clean against the committed
  JSON.
- Gaps-and-caveats writeup separates real from placeholder
  and names the ML-BOM's non-goals.

A failing bundle:

- ML-BOM is only a model-card-shaped Markdown file; no
  machine-readable JSON.
- Dataset entries point to `latest` or an unpinned
  reference.
- Licence rows left blank or set to `"see model card"`.
- Generator has hard-coded content in it (a `supplier`
  field baked into the Python).
- Licence-obligations summary says "various licences
  apply" without walking them.
- Consumer workflows do not actually consume the ML-BOM
  (they're mock scripts that print a hard-coded answer).
- Attestation signed with no identity policy.
- Caveats writeup claims the ML-BOM proves model safety
  or compliance.

---

## Stretch goals

- **Dual-format (SPDX 3.0) output.** Have the generator
  emit SPDX 3.0 AI-profile JSON alongside the CycloneDX
  file; verify both validate.
- **Mirror integration.** For an actual internal mirror,
  push the ML-BOM as a sibling attestation on the mirror
  entry; verify the admission controller consumes it.
- **mod-109 policy pack extension.** Add the licence-
  policy Rego from Deliverable D to the pack with tests
  and a `test_remediation_hint_mentions_<licence>` smoke
  test.
- **Licence-text SHA tracking.** For every custom
  licence, store the retrieval SHA; a periodic job
  checks the current licence URL against the stored SHA
  and alerts on drift.
- **Dependency-graph viz.** Export the `dependencies`
  edges to a Graphviz / Mermaid diagram so the model-to-
  dataset lineage is readable to non-technical reviewers.
- **Model-card integration.** Pull the model-card content
  from the deployed model's HF repo (or your internal
  model-card system) and splice it into the ML-BOM's
  `modelCard` field programmatically; test idempotence.
- **Multi-tier composition.** Build a second ML-BOM for
  a *dependent* system (e.g. an agent that uses this
  model as a tool); demonstrate that the agent's ML-BOM
  references this model's `bom-ref`, and the two files
  compose cleanly for admission.

---

## Do not

- Do not inline sample dataset rows ("example PII:
  Alice,...") into the ML-BOM. The ML-BOM is a signed,
  distributable artefact; sample rows become distributed.
- Do not write the ML-BOM by hand. The point is to
  mechanise generation; hand-written documents are what
  reconstructed-after-the-fact ML-BOMs are.
- Do not pin by name only ("DistilBERT base"). The ML-BOM
  requires revision SHA + hash.
- Do not assume an SPDX ID for a custom RAIL licence.
  Where no SPDX ID applies, use `license.name` + `url`
  + content hash.
- Do not treat the signed attestation as "the ML-BOM is
  correct". The signature says "the build platform
  asserts this content"; correctness is a separate
  property.
- Do not commit the solution bundle to this repo.
  Solutions live in the paired `-solutions` repo.
