# Chapter 05 — Hugging Face Hub Hygiene: Consuming Third-Party Models Safely

> **Note on AI-assisted content.** Hugging Face Hub features
> (gated repositories, security scans, inference endpoints,
> organisation controls) and the model-licence landscape change
> frequently. Verify every claim about Hub capabilities against
> the current HF documentation. See
> [`resources.md`](./resources.md).

---

## Why this chapter exists

Most production ML programmes consume more third-party model
assets than they produce. The pre-training is already paid
for by somebody else; the organisation fine-tunes, aligns,
distils, or just serves. The *supply* in "supply-chain
security" for ML is therefore dominated by whatever process
pulls artefacts in from Hugging Face Hub, model vendors,
open-source releases, and research-code dumps.

Chapters 01–04 built the primitives for the artefacts the
team *produces*: SLSA provenance, signing, ML-BOM, scanning.
This chapter is the counterpart for the artefacts the team
*imports*. The thesis is that "pulling from Hugging Face
Hub" is not a developer convenience; it is a vendor
relationship that happens to be free-of-charge.

The failure mode this chapter is written against:

> An engineer wants to deploy a translation model. They
> search Hugging Face Hub, find a model with 50k downloads
> and a promising README, and run
> `pipeline("translation", model="org/model")` from a
> notebook that is also connected to the production training
> namespace. The pipeline downloads whatever the Hub returns
> under that identifier *right now*, including a
> `generation_config.json` committed yesterday that enables
> a chat template invoking a `trust_remote_code` path. The
> engineer accepts the Transformers prompt because "the
> model needs it to work". The custom code pings an attacker
> endpoint on first load. The notebook pod's token for the
> training-data bucket is in RAM. The incident ticket says
> the engineer "used the official model".

The fix is a documented, tooled, repeatable intake runbook —
a sequence of mechanical gates applied before any third-
party artefact reaches a production system. Chapters 01–04
provide the pieces; this chapter is the assembly.

You leave this chapter able to:

- Enumerate the attacker surfaces when consuming models
  from Hugging Face Hub (or any similar hub).
- Pin a Hugging Face artefact by revision SHA (not by name
  or branch), and verify it on fetch.
- Design the three gates of an intake runbook —
  **provenance verification, licence review, safety-testing
  gate** — and the pipeline that executes them.
- Design an **internal mirror** / "pull-through registry"
  pattern so downstream consumers never fetch directly
  from the public hub.
- Use Hugging Face Hub's own controls (gated repos, access
  tokens, organisation settings, inference-endpoint
  isolation) as part of the stack rather than relying on
  them in isolation.
- Produce the signed artefacts that chapters 01–04 compose
  on top of: the intake-signer identity, the scan-report
  attestation, the ML-BOM entry, the safety-eval attestation.

---

## The attacker surfaces when consuming third-party models

Enumerating them explicitly, because the "it's just a
download" framing hides them:

- **Code-exec on load.** Chapter 04 — pickle, Keras custom
  objects, `trust_remote_code`, custom pipelines.
- **Weight-space backdoor.** The weights contain a learned
  behaviour triggered by a specific input (BadNets family,
  TrojAI, Clean-Label attacks). ModelScan does not catch
  these; they require behavioural evaluation. (mod-106
  chapter 03.)
- **Prompt-injection payload baked in.** For LLMs, a
  training step may have inserted instruction-following of
  specific "owner" directives in system prompts. For
  agentic deployment (mod-107), this is a direct supply-
  chain route to tool misuse.
- **Licence trap.** The weights are licensed under a
  non-commercial, research-only, or custom-community
  licence that the team's deployment would violate. The
  org only learns at legal review before launch (expensive)
  or at external takedown (expensive and public).
- **Dataset-origin trap.** The upstream was trained on data
  the org cannot legally use (unauthorised scrape, revoked
  consent). The organisation inherits any downstream
  liability if it fine-tunes or redistributes.
- **Takedown / revocation.** The upstream repo is removed
  from the Hub for licence violation, trust-and-safety, or
  the author's choice. Any pipeline that resolves by name
  breaks; worse, if the name is re-used by a different
  owner, the pipeline silently fetches a different model.
- **Impersonation / typosquat.** A Hub organisation name
  one character off from a legitimate publisher serves a
  nearly identical artefact with modifications. The team
  fetches the typosquat.
- **Trust-and-safety drift.** The upstream was benign when
  first imported; a subsequent commit added a `.py` file
  with code-exec intent; the pipeline re-fetches on next
  deploy and silently pulls the new file.
- **Config-file subtleties.** `generation_config.json`,
  `tokenizer_config.json`, chat templates — these are
  JSON (or Jinja templates) that can shape model behaviour
  dramatically. A chat template that embeds a `trust_remote
  _code` path, a tokenizer that quietly includes a
  malicious BPE for a crafted prompt — these do not look
  like code and are easy to miss.

The intake runbook addresses each surface explicitly. "Scan
the file" is not enough.

---

## Pinning third-party artefacts

The single highest-leverage control is **pinning by
revision**. Every reference to a Hugging Face asset — in
code, in pipeline specs, in documentation — must carry a
commit SHA. Branches and tags move; SHAs do not.

Workable patterns:

```python
# AVOID: branch / default resolution
model = AutoModel.from_pretrained("microsoft/deberta-v3-base")

# AVOID: branch pin (branch can advance)
model = AutoModel.from_pretrained(
    "microsoft/deberta-v3-base", revision="main",
)

# PREFER: commit SHA
model = AutoModel.from_pretrained(
    "microsoft/deberta-v3-base",
    revision="6b0e7f1b7f0e...",       # verify at intake; pin in config
)

# PREFER (programmatic): hub revision pin
from huggingface_hub import snapshot_download
local_dir = snapshot_download(
    repo_id="microsoft/deberta-v3-base",
    revision="6b0e7f1b7f0e...",
    local_dir="/opt/models/deberta-v3-base/6b0e7f1b7f0e...",
    allow_patterns=["*.safetensors", "*.json", "tokenizer*"],
    # Note: `trust_remote_code` not relevant here — snapshot_download fetches,
    # it does not execute. Code review happens before loading.
)
```

The pinned SHA is the ground truth; the pipeline fetches
by SHA, verifies the SHA matches, and refuses to proceed if
the SHA has drifted (e.g. the local mirror's directory
contents hash to a different value).

For non-HF sources (vendor downloads, Kaggle, GitHub
Releases), the equivalent is a URL + a content hash.
Fetch, hash, compare. If the hash moves without a new
version string, the intake refuses.

**Allowlist of patterns.** The `allow_patterns=` argument
to `snapshot_download` is doing real work: it fetches only
the files the pipeline needs — the safetensors, the
tokenizer, the configs — and leaves `.py` modules on the
Hub unless explicitly fetched. The surface the intake
inspects is smaller as a result. For models that *require*
`.py` modules (`trust_remote_code=True`), the modules are
in a separate allowlist that triggers a human code review.

---

## Hugging Face Hub features worth using

The Hub has its own controls and services; they do not
replace the intake runbook, but they are useful parts of it:

- **Gated repositories.** Model owners can require users
  to accept terms before downloading; the gate uses the
  HF account's identity. The term acceptance is logged.
  For your organisation: use **organisation accounts** —
  not personal accounts — for intake access, so terms
  acceptance is attributable to the org and tokens are
  revocable.
- **Access tokens with scoped permissions.** Fine-grained
  tokens (read-only, write-only, specific-repos) exist;
  the intake pipeline's token is scoped to the smallest
  possible surface. Short-lived tokens via OIDC federation
  are preferable where supported.
- **Hub security scanning.** Hugging Face runs scanners
  (Picklescan, ClamAV, and malicious-pattern detectors)
  on uploaded repositories and surfaces warnings in the
  UI. These are *advisory*: use them as a signal, not as
  a substitute for your own scan.
- **Model cards and dataset cards.** Content-management
  surface for intended use, licensing, limitations,
  evaluation claims. A model card without one of these is
  itself a signal; the intake runbook treats a "missing
  model card" as reason to escalate.
- **Hub repository history.** Every file has a Git history
  on the Hub; a repo that gained a `.py` file in the week
  before intake is more interesting than one unchanged
  for a year.
- **Private spaces and inference endpoints.** For
  evaluation / sandboxed inference without pulling the
  file into your perimeter, HF Inference Endpoints can
  host a model behind their perimeter. Useful for
  pre-intake behavioural evaluation; the evaluation
  itself still happens in your perimeter when the model
  is admitted.
- **Organisation controls.** The HF organisation surface
  provides members, access tokens, SSO, and permission
  controls. Treat the org as part of your identity
  perimeter (mod-103 chapter 04).

For non-HF sources with equivalent features (ONNX Model
Zoo, Modelzoo, vendor registries, GitHub Releases) use
whatever provenance signal is available — signed releases,
hashes in release notes, published checksums.

---

## The intake runbook

The three-gate pattern:

```
┌───────────┐    ┌───────────┐    ┌───────────┐
│ Provenance│    │ Licence   │    │ Safety-   │
│ gate      │ →  │ gate      │ →  │ test gate │
└───────────┘    └───────────┘    └───────────┘
```

Each gate is a pipeline step with an owner, a pass/fail
output, and an attestation. The output of each gate is
signed by a distinct identity (chapter 02's "distinct
identities per artefact class" rule). The intake pipeline
produces a *bundle* of signed attestations attached to the
imported model's internal-registry entry.

### Gate 1 — provenance verification

**Owner.** The ML platform team.

**Steps.**

1. The requested model has a **pinned revision** (HF
   commit SHA or an equivalent). A pipeline refuses to
   fetch an unpinned reference.
2. **Fetch into quarantine.** Pull with `snapshot_download`
   to a quarantine namespace with no write access to any
   production store. The quarantine's egress is
   restricted; the quarantine's compute has no mounted
   service-account credentials beyond read-only hub access.
3. **Verify the SHA.** The fetched files hash to what the
   pin said. (`huggingface_hub` does this automatically
   when revision is a SHA; the check is a belt-and-braces.)
4. **Enumerate the repo contents.** List every file.
   Record file names, sizes, SHA-256. A manifest is the
   output.
5. **Check against the Hub's history.** The repo's
   `commits` endpoint is called; the commit SHA's parent
   history is listed and recorded. Repositories recently
   authored (< 7 days) or recently receiving `.py` /
   loader-affecting changes are escalated.
6. **Check the upstream's org and author.** Verify the
   org slug exactly matches the expected publisher.
   Typosquats differ by character; a cheap defence is to
   maintain an org allowlist for commonly-used publishers.
7. **Check the Hub's security scan status.** HF surfaces
   its scanner results; a `flagged` or `warning` state is
   escalated. Absence of HF scan results is *not* a pass;
   it is a reason to lean harder on your own scan.
8. **Chapter 04 scan.** Run ModelScan (and Picklescan)
   over every file. `CRITICAL` findings fail the gate.
9. **Format conversion.** If the weights are not
   safetensors / GGUF / allowed format, convert using the
   `weights_only=True` loader (chapter 04). Any failure
   of the conversion fails the gate.
10. **Emit a provenance-attestation.** A signed in-toto
    attestation with a custom `predicateType` (e.g.
    `https://company.com/attestations/intake-provenance/v1`)
    containing: pinned revision SHA, file manifest with
    SHA-256s, upstream org and author, HF scan status,
    ModelScan report, conversion outcome.

**Output of gate 1.** A signed provenance-attestation; a
set of safetensors / allowed-format files in quarantine; a
manifest.

### Gate 2 — licence review

**Owner.** Procurement / Legal, with ML Platform in
support.

**Steps.**

1. **Identify the licence.** Pull the licence text from the
   repo (`LICENSE`, `LICENSE.md`, `README.md`,
   `model_card.md`). If the licence is identified by an
   SPDX identifier in the metadata, record the identifier;
   if it is a custom licence, record the hash of the
   licence file as fetched.
2. **Walk the obligations.** Produce a licence-obligation
   summary (chapter 03's `ml:license:obligations` field):
   attribution requirements, redistribution limits,
   derivative-work rules, acceptable-use clauses (RAIL /
   OpenRAIL / community licences), scale thresholds (some
   recent community licences impose user-count or
   revenue-threshold triggers), and any sector or region
   restrictions.
3. **Walk the dataset-origin claim.** Read the model and
   dataset cards. If the upstream names its training data,
   record those names in the ML-BOM. If the upstream does
   *not* name its training data, record the omission; the
   serving-tier policy may require upstream-dataset
   disclosure.
4. **Check compatibility with intended use.** The intake
   request names the deployment the model is intended for
   (internal, external customer product, regulated use,
   etc.). The reviewer confirms the licence terms permit
   that use. Mismatch is a reject or an escalation.
5. **Check the licence version pin.** The licence terms
   fetched at intake are hashed and recorded; a future
   licence change on the upstream does not retroactively
   apply, but a redeploy triggers a re-fetch and a re-review.
6. **Emit a licence-attestation.** Signed in-toto
   attestation with a custom `predicateType` (e.g.
   `https://company.com/attestations/license-review/v1`)
   containing: licence identifier, licence hash, obligations
   summary, intended-use scope, reviewer identity, approval
   date.

**Output of gate 2.** A signed licence-attestation; a
licence-obligations summary; a scope-of-intended-use
record.

### Gate 3 — safety-testing gate

**Owner.** The ML security / evaluation team (mod-106).

**Steps.**

1. **Behavioural evaluation.** Run the intake-tier eval
   bundle against the model in a quarantine inference
   environment. The eval bundle is content-addressed
   (mod-104 chapter 06; mod-106); it includes the
   organisation's standard adversarial, toxicity, bias,
   and task-utility probes.
2. **Trigger probes.** For LLMs, run known prompt-
   injection and jailbreak suites (mod-107). For vision
   models, run known adversarial-example and trojan
   probes (mod-106 chapter 03). Record the pass/fail
   rate.
3. **Capability probes.** For large models, run the
   capability evaluations consistent with chapter 06 /
   mod-109 chapter 06 tier definitions. Over-capable
   models for the intended tier are escalated to the
   review board.
4. **Compare to the upstream's claim.** The upstream's
   model card lists metrics on specific benchmarks.
   Reproduce one or two; a large divergence is a signal
   worth escalating (the artefact may not be what the
   card describes).
5. **Emit an eval-attestation.** Signed in-toto
   attestation with `predicateType` matching mod-106's
   eval-scorecard predicate; content references the eval
   bundle by digest, lists per-probe pass/fail, and names
   the tier the model is cleared for.

**Output of gate 3.** A signed eval-attestation; a
deployment-tier verdict.

### Composition and the ML-BOM

With all three gate outputs signed, chapter 03's ML-BOM is
assembled:

- The imported model's component entry references all
  three attestations by digest in the `properties` section
  (`ml:intake:provenance-attestation`,
  `ml:intake:license-attestation`,
  `ml:intake:eval-attestation`).
- The ML-BOM is signed by the intake pipeline's identity.
- The signed ML-BOM is attached as an attestation on the
  internally-mirrored artefact.

A downstream training pipeline that consumes this base
model inherits the chain: its own SLSA provenance references
the base model's digest; the base model's ML-BOM carries
the three intake attestations; the deploy admission
controller walks the chain and verifies all four
attestations (SLSA provenance, intake-provenance, license,
eval) at admission.

---

## The internal mirror

A production ML programme does **not** let notebooks and
serving pods fetch from the public Hub directly. The
reasons:

- Public-Hub availability is not a controlled dependency.
  Pulls at serving time create a direct runtime
  dependence on `huggingface.co`.
- Public-Hub content can change (within revision
  controls, but tags move; HF-side scanning results change;
  takedown happens). A reproducible build cannot resolve
  to a floating external name.
- The attacker-surface model gets harder: a developer's
  laptop fetching from the public Hub bypasses every
  intake gate.

The pattern is an **internal mirror** or **pull-through
registry**:

1. The intake pipeline is the *only* workflow allowed to
   fetch from the public Hub. Its network identity has
   the one allowed egress to `huggingface.co`; everyone
   else does not.
2. After gate 3, the artefact is pushed to an internal
   OCI registry (via ORAS, chapter 02) under a well-known
   path like `registry.company.com/mirror/huggingface/
   microsoft/deberta-v3-base@sha-<pin>`.
3. The mirror entry carries all intake attestations as
   OCI attestations (signed by the intake identity).
4. Downstream code pulls from the mirror by exact digest.
   Network policy denies downstream pods egress to
   `huggingface.co`; the only way to get a model is
   through the mirror.
5. The admission controller requires the mirror prefix on
   any `model:` reference the serving container sees.
   Direct `hf.co/...` references in production configs
   are blocked.

The mirror is an availability control (removes a runtime
external dependency), a security control (choke-point for
the intake runbook), and a governance control (every
imported artefact has a provenance record in the mirror's
attestation store). For organisations with air-gap
requirements, the mirror is also the DMZ-side pull-through
that lets the production environment serve models whose
intake was in the connected environment.

### Mirror hygiene

- **Immutable tags.** Mirror entries are tagged by
  pin SHA; tags are not reused. A new upstream revision
  becomes a new mirror entry.
- **Attestation retention.** Attestations outlive the
  artefact; a retired mirror entry still has retrievable
  provenance.
- **Deletion controls.** Removing a mirror entry is a
  governance event. The retention policy (chapter 06;
  mod-109 chapter 05 regulatory floors) specifies how
  long each entry is retained; takedown-triggered removal
  (upstream request, licence revocation) is logged.
- **Re-sync policy.** A periodic job scans mirror entries
  against upstream status: upstream deleted / flagged /
  licence-changed signals an escalation. The signal is
  advisory to the owner teams, not an automatic takedown.

---

## Patterns the runbook rejects

Common "shortcut" patterns the intake runbook explicitly
refuses, with the reason stated so engineers can internalise
why:

- **"The team needs this fast — can we skip gate 2?"**
  No. Licence surprise at external launch costs more than
  licence review at intake. Build cycle-time into the
  runbook; do not build gate-skip into the policy.
- **"The notebook pod has the HF token for convenience."**
  No. The notebook pod has no production permissions that
  the intake pipeline doesn't; direct Hub pulls bypass
  the gates. Fix with network policy at the egress layer,
  not with an edict.
- **"We'll pull again at deploy to get fixes."**
  No. The deploy-time pull reintroduces the external
  dependency and bypasses gates. The intake runbook is
  re-run with a new pinned revision; the mirror is
  updated through the gate.
- **"The model has 100k downloads; it's fine."**
  No. Popularity is not an intake control. Famous
  checkpoints have had `.py` files added post-release;
  famous checkpoints have had licence terms changed.
- **"We trust the publisher; use their SHA from last
  month."**
  Verify. Publisher trust is scope-limited; new revisions
  from a trusted publisher still go through the runbook.
- **"We need `trust_remote_code=True` to use it; it says
  so on the model card."**
  The model card is the publisher's word. `trust_remote_
  code=True` requires code review of the exact `.py`
  files in the pinned revision; the review is itself the
  signed exception.
- **"The model is a drop-in replacement; same name, newer
  SHA."**
  Fetch, run the runbook, publish a new mirror entry. A
  "drop-in" is a new entry.

---

## Standard failure modes

- **Unpinned references in production code.**
  `AutoModel.from_pretrained("org/model")` resolves to
  whatever the Hub says today. Fix: lint for unpinned
  references in CI; the loader library's call site
  requires `revision=`.
- **`trust_remote_code=True` turned on silently.** A
  utility wrapper sets the flag; a review notices only
  after an incident. Fix: wrapper rejects the flag unless
  configured by a signed exception.
- **Pulls from the public Hub at deploy time.** Serving
  pod's egress policy permits `huggingface.co`. Fix:
  network policy denies; mirror-only path is the only
  working path.
- **Licence drift.** The upstream changes licence terms
  between intake and launch; the ML-BOM shows a licence
  no longer valid. Fix: deploy-time admission check hits
  the licence-attestation and the mirror's current
  licence; a mismatch surfaces at admission, not at
  external launch.
- **Takedown with no record.** The upstream repo is
  removed; nobody knows what was imported from it. Fix:
  mirror retains the provenance-attestation; the sweep
  policy flags removed-upstream entries.
- **Scanning run only at intake.** A new CVE in ModelScan
  or in a loader library emerges after intake; the mirror
  is not re-scanned. Fix: mirror entries carry the scanner
  version and rule-set version; a quarterly sweep re-runs
  the scan at the latest versions and emits a dated
  re-scan attestation.
- **Eval drift.** The eval bundle used in gate 3 is
  pinned; the organisation's eval standards advance;
  entries imported last year are below current bar. Fix:
  re-admission policy (mod-109 chapter 04) requires a
  re-run against the current eval bundle before a mirror
  entry can continue to serve production tiers.
- **Mirror shared with the training-data store.** The
  mirror lives in the same bucket as training data; a
  mirror-write identity can clobber training data. Fix:
  mirror is a distinct registry / bucket; identities are
  disjoint.
- **No distinct identity per gate.** The intake pipeline
  signs the ML-BOM, the provenance, and the eval
  attestations with the same identity. A compromise
  fabricates all three. Fix: gate 1 signer, gate 2 signer,
  gate 3 signer are distinct workloads with distinct OIDC
  identities (chapter 02).
- **Review board bypassed for "obvious" imports.** Small
  utility models imported without review. Fix: the
  runbook is for every intake; the smallest-model path
  can be fast but not skipped.
- **Mirror has no retention floor.** Entries deleted on
  request; audit cannot answer "what did we deploy in
  2026-Q2". Fix: retention floors from mod-109 chapter
  05 regulatory map (SOC 2 CC9.2, HIPAA § 164.316(b)(2)).

---

## Summary

- Consuming third-party models is a **vendor
  relationship**. The hub is free; the exposure is not.
- **Pin by revision SHA**, not by name or branch, and
  verify the SHA on fetch. Everything else assumes an
  external name has stable content; it does not.
- The intake runbook has three gates: **provenance
  verification** (identity, history, chapter-04 scan,
  format conversion), **licence review** (identification,
  obligations, intended-use fit, licence-text hash), and
  **safety-testing** (behavioural eval, trigger probes,
  capability check, upstream-claim reproduction).
- Each gate produces a **signed attestation by a distinct
  identity**. Chapter 03's ML-BOM composes them;
  chapter 02's admission controller enforces them.
- An **internal mirror** is the single point of pull.
  Public-Hub access is scoped to the intake pipeline;
  downstream pods have no egress to the public Hub.
- Hugging Face Hub features (**gated repositories, scoped
  access tokens, security scans, organisation controls**)
  are useful parts of the stack, not substitutes for the
  intake runbook.
- The patterns engineers *want* to use for speed —
  unpinned references, `trust_remote_code=True`, deploy-
  time pulls — are the ones the runbook refuses. The
  refusal is the control.
