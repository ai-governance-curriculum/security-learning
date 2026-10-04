# Exercise 04 — Malicious Model File Detection with ModelScan

**Estimated effort:** ~3 hours
**Deliverable:** A controlled, offline **detection lab** for
malicious-model-file threats, consisting of (a) a committed
**corpus of benign and crafted malicious artefacts**
covering pickle (`.pt` / `.pkl`), Keras `.h5` with Lambda
layers, TensorFlow SavedModel with suspicious ops, and
`safetensors` baselines, (b) a **ModelScan baseline run**
against the corpus with scan output committed, (c) a
**rule-set extension** — at minimum one new positive-pattern
rule tailored to an org-specific dangerous callable — with
tests proving the rule fires on crafted inputs and does not
false-fire on benign ones, (d) a **safe-loader wrapper**
that enforces `torch.load(..., weights_only=True)` and
rejects loads of non-allowed formats, (e) a **scan-report
attestation** signed with cosign and attached to a sample
model artefact, (f) an **admission-policy sketch** that
rejects artefacts without a scan attestation or whose
attestation reports CRITICAL findings, and (g) a one-page
**ethical-handling note** describing where the crafted
malicious files live, who has access, and how they are
destroyed after the exercise.
**Prerequisites:** Chapters 04 and 02 read end-to-end. A
Python environment with `modelscan`, `picklescan`, `torch`
(≥2.6 for the `weights_only=True` default), `tensorflow`,
`keras`, `safetensors`, and `cosign`. **An isolated
sandbox** — a VM, a container with no mounted secrets, or a
disposable scratch environment. The crafted malicious
artefacts in this exercise are hostile files; they belong
only inside the sandbox.

---

## Objective

Chapter 04's thesis is that **scanning is one of several
layers**: safetensors / GGUF format preference eliminates
the surface where possible; safe loaders (`weights_only=
True`, Keras `safe_mode=True`) disable the mechanism; the
scanner catches the obvious; the sandbox limits the blast
radius. This exercise is the exercise that stands up every
layer locally, verifies the scanner behaves as expected,
and produces the signed attestation an admission policy
can consume.

By the end of this exercise you have:

- A labelled corpus of benign and crafted malicious
  artefacts covering the main pickle-exposed formats.
- A ModelScan baseline on the corpus with the output
  JSON committed and reviewed.
- A rule-set extension catching an org-specific pattern
  that the baseline misses.
- A safe-loader wrapper enforcing format and loading-flag
  policy.
- A signed scan-attestation and an admission-policy
  sketch consuming it.
- An ethical-handling note documenting disposal of the
  hostile files.

You are **not** publishing crafted malicious files, running
them outside the sandbox, or sharing them to any public
hub. The corpus is a local-only teaching asset.

---

## Problem statement

The exercise builds a corpus of six artefact types; some
benign, some crafted to trigger specific scanner rules.
All crafted-malicious files use payloads that are
**loud but non-destructive** — the point is to make the
scanner trigger, not to exercise a real exploit.
Recommended payloads:

- `print("MALICIOUS LOAD DETECTED")` wrapped in `__reduce__`.
- `pathlib.Path("sandbox-tripwire").touch()` wrapped in a
  Lambda layer config.
- Any observable side effect confined to the sandbox's
  writeable scratch directory.

Payloads must **not**:

- Reach the network (no `urlopen`, no `socket.*`).
- Spawn shells with real commands (`os.system("curl ... |
  sh")`).
- Touch anything outside the sandbox's scratch directory.

The corpus's purpose is scanner behaviour, not vulnerability
research. Scoring the scanner on destructive payloads is a
different (adversarial-research) exercise outside the
scope here.

State before you start:

- The sandbox: a Docker container (`--network none`, read-
  only filesystem except `/tmp`), a disposable VM, or a
  dedicated workstation user with no mounted credentials.
- The scanner version (`modelscan --version`,
  `picklescan --version`).
- The PyTorch / TF / Keras versions.

---

## Requirements

### Deliverable A — artefact corpus

Build a `corpus/` directory with six files:

1. `benign.safetensors` — a tiny real tensor dict saved
   with `safetensors.torch.save_file`. The negative control.
2. `benign-torch.pt` — the same tensors saved with
   `torch.save`. Benign; pickle-backed but no exploit.
3. `malicious-pickle.pt` — a `.pt` file containing a
   `__reduce__`-based payload that triggers on
   `torch.load(..., weights_only=False)`. Payload is
   loud but non-destructive.
4. `malicious-keras.h5` — a Keras model saved via
   `model.save("x.h5")` with a `Lambda` layer whose
   function performs a benign-but-detectable side effect
   on load.
5. `malicious-savedmodel/` — a TF SavedModel directory
   containing a signature that references a suspicious
   op (`tf.io.write_file` or `tf.py_function` with a
   user-controlled callable).
6. `benign-trust-remote-code/` — a HF repo-shaped
   directory with a `config.json`, a safetensors weight
   file, and a `handler.py` that would be loaded by
   `AutoModel.from_pretrained(..., trust_remote_code=
   True)`. The `.py` is syntactically benign but prints
   a visible marker on import; the point is to show the
   file is executed when the loader flag is on.

Commit the corpus with a `README.md` that:

- States each file's intent (benign vs crafted-malicious).
- Describes the exact payload shape of each crafted file.
- Links the construction script (`build-corpus.py` or
  `build-corpus.sh`) that produces the files from scratch
  — reviewers should be able to rebuild the corpus
  without peeking at pre-committed binaries.
- States the sandbox discipline the corpus requires.

### Deliverable B — ModelScan baseline

Run ModelScan over the corpus and commit the output.

```bash
modelscan -p corpus/ -r json > scan-baseline.json
jq '.summary' scan-baseline.json
```

Produce a short analysis (`scan-baseline.md`) with:

- A table of each file → ModelScan severity verdict →
  the specific rule(s) that triggered.
- An honest column for **false negatives** (benign flagged
  as malicious) and **expected findings** (malicious
  flagged as expected).
- A **gap list** — crafted-malicious files that ModelScan
  did *not* flag at the severity you expected, if any.
  These are the gaps the Deliverable C extension targets.

Also run Picklescan where applicable:

```bash
picklescan -p corpus/ > picklescan-baseline.json
```

Compare the two scanners; chapter 04's point is that each
catches a different slice of the attack surface.

### Deliverable C — rule-set extension

Pick one of:

- A **new positive-pattern rule** for an org-specific
  dangerous callable (e.g. an internal module path, or
  a less-common exfil vector not covered by the baseline).
  Add it to the scanner's configuration (ModelScan supports
  custom rules — verify the current API) and prove it
  fires on an adversarial example you craft.
- A **stricter loader** that walks the pickle opcode stream
  with a tiny allowlist (NumPy arrays, torch tensors,
  dict / list / primitives) and refuses anything else.
  This is the "run `torch.load(weights_only=True)` as a
  scanner" pattern.

Deliver:

- The rule / allowlist code.
- A test harness that runs the extension against the
  corpus and against a minimal "no, this should pass"
  negative set.
- A test matrix of positive and negative inputs with the
  expected verdict and the measured verdict. Mismatches
  are either rule bugs or corpus issues; both get fixed.
- A README stating the rule's taxonomy mapping (OWASP
  ML / LLM Top 10 entry; MITRE ATLAS tactic; NIST AI
  100-2 attack class).

### Deliverable D — safe-loader wrapper

A small Python module (`safeload.py`) exposing:

```python
from safeload import load_weights, load_hf_model

state = load_weights("path/or/digest")
model = load_hf_model("org/name", revision="<sha>")
```

Behaviour:

- `load_weights` **refuses** `.pkl` / `.pt` / `.pth` /
  `.h5` from a production allowlist by default; forces
  `safetensors` or an explicitly whitelisted format.
  When a legacy `.pt` is permitted via a signed
  exception, calls `torch.load(..., weights_only=True,
  map_location="cpu")` and nothing else.
- `load_hf_model` sets `trust_remote_code=False` by
  default; a positional override requires a signed
  exception reference the wrapper logs and checks.
- Logs every load (path, hash, loader-flag state) to a
  local JSON lines log for the admission audit trail.

Commit the module plus a pytest suite that covers:

- Loading a safetensors file: pass.
- Loading `malicious-pickle.pt` with default flags:
  wrapper refuses *and* ModelScan hooking (optional)
  fires.
- Loading `malicious-pickle.pt` with `weights_only=
  True`: PyTorch's restricted unpickler refuses.
- Loading `benign-trust-remote-code/` with
  `trust_remote_code=False`: refuses to load the `.py`.
- Loading `benign-trust-remote-code/` with the
  `trust_remote_code=True` flag + signed-exception
  reference stub: logs and loads.

Run the suite inside the sandbox; capture the output.

### Deliverable E — signed scan attestation

Attach the scan report to a sample model artefact as a
cosign attestation (reuse the exercise-02 pipeline):

```bash
cosign attest \
  --predicate scan-baseline.json \
  --type "https://company.com/attestations/modelscan-report/v1" \
  --oidc-issuer <issuer> \
  <registry>/<name>@sha256:<digest>
```

Verify:

```bash
cosign verify-attestation \
  --type "https://company.com/attestations/modelscan-report/v1" \
  --certificate-identity-regexp '^<expected-signer>$' \
  --certificate-oidc-issuer '<issuer>' \
  <registry>/<name>@sha256:<digest> \
  | jq -r '.payload | @base64d | fromjson'
```

Capture both. The signer identity should be a dedicated
*scanning* identity, distinct from the training identity
(chapter 02's "distinct identity per artefact class" rule).

### Deliverable F — admission-policy sketch

A `ClusterImagePolicy` (sigstore policy-controller) or
Kyverno `ClusterPolicy` snippet that enforces:

- Every model artefact in the `registry.company.com/models/
  **` set must present a signed scan-attestation of the
  expected `predicateType`.
- The attestation's content must report zero `CRITICAL`
  findings in `issues[]` (CUE / Rego content policy).
- The attestation's `scanner_version` property must
  satisfy a floor expression (`>= 0.X.Y`).

Scope and state:

- Which clusters the policy would ship to.
- Whether it runs in enforce or shadow for the first
  rollout.
- The exception path (chapter 02's break-glass pattern).

### Deliverable G — ethical-handling note

A one-page document (`ethical-handling.md`) stating:

- **Where the crafted-malicious files live.** Local
  sandbox only. Not in a shared repo, not pushed to a
  public registry, not uploaded to any hub.
- **Access control.** Only the exercise author's
  workstation / sandbox has them.
- **Destruction.** How and when the crafted files are
  deleted — ideally at the end of the exercise, with
  the sandbox torn down.
- **Rebuildable.** The `build-corpus.py` script is what
  future reviewers rerun; the binary artefacts are not
  the canonical form.
- **Harm bound.** Payloads are non-destructive and
  non-exfiltrating; the note includes the explicit
  payload descriptions so a reviewer can verify.
- **Not a weapon.** The exercise's purpose is to make
  the detection stack work; the files are detection
  targets, not exploits.

---

## Starter guidance

- **Build the corpus inside the sandbox.** Even benign
  payloads should execute first in isolation to confirm
  they are what you think they are.
- **`weights_only=True` first.** Modern PyTorch defaults
  to it, but older code and older tutorials show
  `weights_only=False`. Confirm the version matters by
  demonstrating a crafted file loading successfully
  under `weights_only=False` and failing under
  `weights_only=True`.
- **Use pytest for the test matrix.** The corpus has
  six-plus items; pytest parametrisation makes the test
  matrix compact and the failures legible.
- **Capture ModelScan output as JSON, not text.** The
  attestation and the admission policy consume JSON.
- **Pin the scanner version in CI.** Across ModelScan
  releases, severity classifications change; the policy
  expresses a floor against a specific rule set.
- **Record positive and negative examples per new rule.**
  A rule without a negative example will false-positive
  in production; a rule without a positive example is
  code untested.
- **For `trust_remote_code`, show the file is executed.**
  The point of the `benign-trust-remote-code/` corpus
  entry is to demonstrate the flag enables code
  execution; a marker side effect (writing to a scratch
  file) is the detection.

---

## Acceptance criteria

A passing bundle:

- Corpus has six files covering the four target formats
  plus the `trust_remote_code` repo-shape, with a
  `build-corpus` script that rebuilds them.
- ModelScan baseline committed; per-file verdict table
  and gap list present.
- Rule-set extension added with tests; positive and
  negative examples verified; taxonomy cross-ref present.
- `safeload.py` enforces format allowlist, `weights_
  only=True`, and `trust_remote_code=False` by default;
  pytest suite exercises every behaviour.
- Signed scan-attestation attached to a sample artefact
  and verifiable; signer identity distinct from the
  training identity.
- Admission-policy sketch enforces attestation presence,
  content, and scanner-version floor.
- Ethical-handling note names storage, access, disposal,
  and payload bound.

A failing bundle:

- Crafted-malicious payloads reach network, spawn
  destructive processes, or exceed the "loud but non-
  destructive" bound.
- Corpus files committed without the rebuilding script
  — reviewers must take binary blobs on faith.
- ModelScan baseline not analysed; gap list missing.
- Rule extension without tests.
- Safe loader allows `weights_only=False` or
  `trust_remote_code=True` by default.
- Scan attestation signed by the training identity.
- Admission policy sketch is "we require a scan report"
  with no content policy.
- Ethical-handling note missing or vague.

---

## Stretch goals

- **Picklescan + ClamAV layered.** Add Picklescan as a
  second scanner and ClamAV for file-level malware
  detection; produce a layered report.
- **Fuzzing the corpus.** Generate variants of the
  crafted-malicious files (different payload callables,
  obfuscation layers) and measure scanner recall
  against the variants. Mark the recall gap as the
  signal for the next rule.
- **Keras 3 `safe_mode` demo.** Build a Keras 3 model
  file and show `safe_mode=True` behaviour on load;
  add a `safe_mode` check in `safeload.py`.
- **GGUF benign demo.** Add a GGUF benign file to the
  corpus; demonstrate that there is no deserialisation-
  to-execute attack surface, and that ModelScan
  (expected) is quiet.
- **Chapter 05 intake wiring.** Package the scanner + the
  safe loader + the signing step into a single intake
  command (`intake.sh <hf-ref>`) that follows chapter
  05's three-gate pattern and emits all three signed
  attestations.
- **CI integration.** Wire the scanner + the test
  matrix into a GitHub Actions / GitLab CI job that
  blocks merges introducing a new corpus entry without
  a scanner verdict.
- **Rego policy extension.** Convert the admission-
  policy sketch into a mod-109 chapter 04 policy with
  tests, exception path, and taxonomy cross-refs.
- **Picklescan-vs-ModelScan agreement study.** Produce a
  disagreement matrix across the corpus; disagreements
  are cheap sources of profile improvements.

---

## Do not

- Do not place crafted-malicious files in any shared
  repo, bucket, or registry. The sandbox is the only
  home.
- Do not use real destructive payloads (`rm -rf`,
  real reverse shells, data exfiltration). The exercise
  is detection, not exploitation.
- Do not run the scanner against public-Hub artefacts
  as part of this exercise; HF scans those already, and
  running scanners against third-party content can
  trigger abuse concerns on the Hub side if the scanner
  pulls repeatedly.
- Do not treat a clean ModelScan verdict as "the model
  is safe". Chapter 04's point: scanners catch the
  known patterns; weight-space backdoors (mod-106) and
  behavioural failures (mod-104 chapter 06) are
  separate.
- Do not disable `weights_only=True` to "unblock"
  loading an old checkpoint. The right path is a one-
  shot `safeload` conversion under `weights_only=True`,
  re-save as safetensors, re-sign, re-mirror.
- Do not sign the scan-attestation with the same
  identity as the training pipeline. Chapter 02 split
  identities per artefact class.
- Do not commit the solution bundle to this repo.
  Solutions live in the paired `-solutions` repo.
