# Exercise 03 — ML-BOM Authoring for One Model (CycloneDX 1.6)

**Estimated effort:** ~3 hours
**Deliverable:** A committed `mlbom.json` (CycloneDX 1.6) for a
real model you have access to, an accompanying generator script
that reproduces it, a signed in-toto attestation attaching the
ML-BOM to the model artifact, and a policy / diff memo (~2 pages)
covering completeness aggregate, licence policy, and a diff
against a prior model version.
**Prerequisites:** Chapters 01, 02, 03, and 04 read end-to-end.
Exercise 02 completed (you have a signed model artifact and a
working `cosign attest` flow). Access to a real model (a Hugging
Face model you have downloaded, an internal model, or the fraud
model from exercises 01–02).

---

## Objective

For a real model, produce a schema-conformant CycloneDX 1.6
ML-BOM that covers **every** component class from chapter 04:
primary model, base and fine-tune chain, training dataset(s),
feature set(s), evaluation datasets, tokenizer, ML framework
dependencies, container base images. Attach it as a signed
in-toto attestation. Then write the policy memo describing what
completeness, licence, and diff rules the mod-103 admission gate
should enforce for it.

By the end you should be able to hand the ML-BOM to a security
engineer who has never seen the model and have them read every
input by digest, name every licence obligation, and diff the
next version against this one.

## Problem statement

Two flavours; pick whichever matches what you have access to.

### Flavour A — real Hugging Face model (recommended for self-study)

Pick a moderately-sized Hugging Face model with a documented
lineage — a fine-tune of a well-known base model, published
with a model card that references its training data. Suggested
candidates (verify current availability):

- A fine-tuned classifier where the model card names the base
  and the training corpus.
- An adapter (LoRA) whose card lists the base and adapter
  library.

Download the model files locally. You are the security engineer
who has just been handed this model and told to produce an
ML-BOM that would let admission-time policy make a rational
decision about whether to run it.

### Flavour B — the `fraud` model from exercises 01–02

Use the signed `fraud` artifact from exercise 02. This gives
you a controlled lineage but requires more of your own data
work.

## Requirements

### Deliverable A — the ML-BOM

`mlbom.json` in CycloneDX 1.6 JSON, committed to the exercise
directory. It must:

- Validate against the CycloneDX 1.6 schema (`cyclonedx
  validate --input-file mlbom.json` or an equivalent tool).
- Have `bomFormat: CycloneDX`, `specVersion: 1.6`, a `serialNumber`,
  and a `metadata.timestamp`.
- Have `metadata.component` populated with the primary model:
  name, version, purl, SHA-256 digest, licence (SPDX), and a
  `modelCard` sub-object with `modelParameters.task`,
  `modelParameters.architectureFamily`, `modelParameters.datasets`
  (as refs), and at least one `quantitativeAnalysis.performanceMetrics`
  entry with confidence interval or slice.
- Have `components[]` covering every chapter-04 class present:
  base model(s), fine-tune / adapter chain, training dataset
  snapshot with `row_count` and `sensitive_class` properties,
  feature set (if applicable), eval dataset(s), tokenizer,
  every direct ML framework dependency with pinned version
  and hash, both container base images (trainer and server) if
  applicable.
- Have `dependencies[]` accurately expressing the DAG.
- Have `compositions[]` declaring `aggregate: complete` for
  the primary assembly, OR `aggregate: incomplete_first_party`
  (or the current CycloneDX enum for a partial BOM) with an
  accompanying note in the design memo naming the gaps.
- Use SPDX expressions for every licence that has a valid SPDX
  identifier. For non-SPDX licences, use `license.name`
  explicitly.

### Deliverable B — the generator

A script (`generate_mlbom.py` or equivalent) that reproduces
`mlbom.json` from source (the model repository, the
requirements lockfile, the training config). The generator
must:

- Take at least the model artifact digest as input.
- Read dependencies from a lockfile (`requirements.lock`,
  `poetry.lock`, `pip freeze` output) — not from a static
  list hand-typed into the script.
- Produce identical output on repeated runs when given
  identical inputs (reproducible generation).

The generator does not need to be production-grade — it needs
to demonstrate that the BOM would regenerate deterministically
in CI, not be hand-crafted per release.

### Deliverable C — signed attachment

Attach the ML-BOM as a signed attestation to the model
artifact from exercise 02:

```
cosign attest \
    --predicate mlbom.json \
    --type cyclonedx \
    <artifact-digest-ref>
```

Verify with `cosign download attestation` and confirm the
DSSE envelope carries the correct predicate type
(`https://cyclonedx.org/bom`), the correct subject digest, and
a valid signature.

If you completed exercise 02 with a `ClusterImagePolicy` /
Gatekeeper flow, extend the policy to require the ML-BOM
attestation, and demonstrate that:

- An artifact with a valid ML-BOM attestation admits.
- The same artifact without the ML-BOM attestation is
  rejected (temporarily remove the attestation to demonstrate).
- An artifact whose ML-BOM has `aggregate: incomplete` when
  the policy requires `complete` is rejected.

### Deliverable D — policy and diff memo (~2 pages)

Cover:

- **Required component types.** The list your admission-gate
  policy enforces for this model (`machine-learning-model`,
  `data`, `library`, ...). Which types are mandatory-present,
  which are conditional, and why.
- **Licence policy.** Your allow-list and deny-list, using
  SPDX identifiers. At minimum: which licences are permitted
  in production, which trigger a governance review, which are
  blocked. Include one non-trivial case (e.g. AGPL-3.0, CC-BY-
  NC-4.0, custom "research only" licences) and how your
  policy handles it.
- **Aggregate completeness.** Whether your BOM is
  `aggregate: complete` and if not, what specifically is
  missing and how you disclose it.
- **Diff vs prior version.** Diff your ML-BOM against the
  previous version of the same model (from your own history,
  or from a previous release of the Hugging Face model). If
  no prior version exists, hand-construct a plausible "prior
  version" ML-BOM by copying yours and rolling back one
  dependency version and one dataset version — then diff.
  Report:
  - Added / removed components.
  - Version bumps and any CVE deltas the version bumps
    close (or open).
  - Licence changes.
  - Digest changes on same-versioned components (should be
    zero; investigate any hit).
- **Coverage of "un-diges­table" components.** If your model
  used human labelling, a vendor black-box, or prompt-tuning
  inputs whose provenance you cannot fully attest, name them
  and describe how the ML-BOM reflects that (component
  present, `aggregate: incomplete_first_party`, or however
  the current CycloneDX enum handles it).

## Starter guidance

- The CycloneDX Python library (`cyclonedx-python`) has been
  the reference generator. Verify the current package name
  and API before use — the ecosystem is moving.
- Cross-check the ML-BOM's `resolvedDependencies` mirror the
  SLSA provenance `resolvedDependencies` from exercise 02.
  Divergence between the two is a red flag; both should
  agree on training-time inputs.
- For datasets from public sources (Hugging Face datasets,
  Common Crawl, Kaggle), pin to a version tag *and* record a
  SHA-256 of the snapshot you actually consumed. Version tags
  can be rewritten upstream.
- Do not put row-level or PII data in `properties`. Aggregate
  metadata only (row count, sensitivity class, region).
- For SPDX licence expressions, `Apache-2.0`, `MIT`, `BSD-3-
  Clause`, `LGPL-2.1-or-later` are common. Verify identifier
  spelling at [spdx.org/licenses](https://spdx.org/licenses).
- If the Hugging Face model card does not name the training
  data at digest precision, record what the card *does* say
  (URL, description) and mark that component's
  attestation-status as vendor-supplied — the ML-BOM does not
  lie about what is knowable.

## Acceptance criteria

Passing work:

- `mlbom.json` validates against the CycloneDX 1.6 schema.
- Every chapter-04 component class present in the target
  model is present in the BOM. Missing classes are
  intentional (not applicable) and explained in the memo.
- Generator reproduces the same document on re-run with the
  same inputs.
- Attestation is verifiable with `cosign verify-attestation`
  and returns the CycloneDX predicate.
- Admission policy demonstration: valid → admit; missing
  attestation → deny; incomplete aggregate → deny (if the
  policy requires complete).
- Licence policy is expressed in SPDX identifiers, not free
  text.
- Diff shows added / removed / version-changed components,
  with any CVE-delta or licence-delta called out.

Failing work:

- BOM does not validate.
- Dataset components missing.
- BOM claims `aggregate: complete` while the memo admits gaps.
- Digests missing on any component that has a knowable
  digest.
- Licences given as free text ("Apache 2 sort of").
- Diff is a prose narrative rather than a per-component
  change list.
- Generator hand-lists dependencies rather than reading a
  lockfile.

## Stretch goals

- **Cross-format conversion.** Convert your CycloneDX ML-BOM
  to SPDX and back (`cyclonedx-cli convert`); enumerate what
  round-trips cleanly and what doesn't. This tells you which
  fields are safe to rely on for cross-tool interop.
- **Dependency-Track integration.** Load the ML-BOM into a
  Dependency-Track instance and watch it enrich with CVE
  data. Author a policy in Dependency-Track that mirrors
  your admission-gate policy and confirm they agree.
- **Multi-model BOM.** Author a *portfolio* BOM covering all
  models the fraud service uses (v42 primary, v41 EEA
  fallback, an experimental v43). Compare the union of
  dependencies across the portfolio; identify the shared
  risk surface.
- **Vendor-model BOM.** Pick a black-box vendor model
  (an OpenAI or Anthropic API endpoint used by your service)
  and produce the ML-BOM for the "component" the vendor
  provides, given the limited disclosure available. Explicit
  disclosure of what is missing is the point.

## Do not

- Do not synthesise dataset digests. If the digest is not
  knowable, record so plainly.
- Do not use free-text licence names when an SPDX identifier
  exists.
- Do not hand-type dependencies you could have read from a
  lockfile.
- Do not commit a solution to this repository.
- Do not invent CycloneDX field names — verify against the
  current schema, and use a `needs-research` marker for any
  claim you can't verify.
