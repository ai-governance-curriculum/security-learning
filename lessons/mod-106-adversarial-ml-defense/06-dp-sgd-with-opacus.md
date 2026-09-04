# Chapter 06 — DP-SGD End to End with Opacus

> **Note on AI-assisted content.** Opacus's API surface — the
> `PrivacyEngine.make_private_*` variants, the accountant options,
> and the DDP integration — changes between releases. Verify against
> the current release notes before quoting or copying. See
> [`resources.md`](./resources.md).

---

## Why this chapter exists

Chapter 05 measured membership-inference risk and named DP-SGD as
the primary control. This chapter wires it end-to-end with Opacus,
the PyTorch implementation.

The specific failure mode this chapter is written to prevent:

> A team wraps their optimiser with `PrivacyEngine`, watches
> training complete, and reports "we trained with DP". The
> reviewer asks: "at what `(ε, δ)`? Under which accountant? With
> what clipping norm and noise multiplier? Over how many training
> examples with what sampling rate? What is the utility drop
> versus the non-private baseline?" The team can answer none of
> these because none of them were configured explicitly; the
> defaults ran and the run finished. The claim "we trained with
> DP" is unfalsifiable without those values.

DP-SGD ships with a **budget**. A DP training run without an
`(ε, δ)` value on the model card is not a DP training run — it is
a training run that added noise. The budget is what mathematics
you can defend.

You leave this chapter able to:

- State the DP-SGD guarantee (record-level `(ε, δ)`-DP) and the
  interpretation the model card carries.
- Configure Opacus's `PrivacyEngine` with an explicit clipping
  norm, noise multiplier, and accountant.
- Choose sampling rate and batch size so the accountant produces
  an `(ε, δ)` inside the budget.
- Report the accountant's final `(ε, δ)` and hyperparameters on
  the model card, alongside utility metrics measured against a
  non-private baseline.
- Debug the standard failure modes — per-sample-gradient errors,
  DDP-and-Poisson-sampling mismatches, `BatchNorm` incompatibility,
  budget exhaustion mid-training.

Chapters 05 (serving-side membership-inference monitoring) and 04
(privacy engineering as a broader programme in mod-108) surround
this chapter; here we focus on **the training-time recipe**.

---

## The guarantee, in engineer-usable form

Differential privacy in the sense DP-SGD ships is:

> An algorithm `M` is `(ε, δ)`-differentially private if, for any
> two datasets `D` and `D'` differing in exactly one record, and
> any set of outcomes `S`:
>
> ```
> Pr[M(D) ∈ S]  ≤  e^ε · Pr[M(D') ∈ S]  +  δ
> ```

The DP-SGD instantiation (Abadi et al. 2016 — *Deep Learning with
Differential Privacy*) applies this to gradient-descent training:
per-sample gradients are clipped to a fixed norm, Gaussian noise
is added to the aggregated gradient, and a privacy accountant
composes the per-step privacy cost over the training run.

The bound gives you a defensible claim of the form:

> The presence or absence of any single training record changes
> the probability of any observable outcome (any decision an
> attacker with query access can draw from the model) by a factor
> of at most `e^ε`, except with probability at most `δ`.

Sensible ranges — these are conventions, not law:

- `ε ≤ 1` — strong protection; typically requires substantial
  utility sacrifice.
- `1 < ε ≤ 4` — moderate protection; the common target for
  production ML with PII.
- `4 < ε ≤ 10` — weak but non-trivial; sometimes deployed with
  explicit acknowledgement in the model card.
- `ε > 10` — the guarantee is close to vacuous; do not label as
  "differential privacy" without a caveat.
- `δ` — should be `≤ 1/N` where `N` is the training-set size
  (rule of thumb) and always ≪ `1/N` for meaningful protection.
  `δ = 1e-5` is a common choice for `N` in the millions.

Two claims the budget does *not* make:

- **Not group privacy.** A record for a family of 100 people gets
  a proportionally weaker guarantee (`(100·ε, 100·δ)` roughly).
- **Not distributional privacy.** DP-SGD says nothing about
  learning statistical properties of the population — it protects
  the individual record's *presence*, not the distribution the
  record was drawn from.

Every model card row that names an `(ε, δ)` should also name what
the "record" is: a user, a session, a document, a labelled example.
The definition drives the meaning.

---

## The algorithm in five lines

```
For each training step:
  1. Sample a Poisson batch B ⊆ D with per-record probability q.
  2. Compute per-sample gradient g_i = ∇_θ L(f_θ(x_i), y_i)  for i ∈ B.
  3. Clip each per-sample gradient: g_i ← g_i · min(1, C / ||g_i||_2).
  4. Aggregate with Gaussian noise:  g̃ = (Σ_i g_i + N(0, (σ·C)² I))  /  |B|.
  5. Step: θ ← θ − η · g̃.
```

The knobs:

- `C` — the per-sample gradient clipping norm.
- `σ` — the noise multiplier (relative to `C`).
- `q` — the sampling rate (batch size / dataset size).
- `T` — the total number of training steps.
- The **accountant** — the algorithm that composes per-step
  privacy costs into the final `(ε, δ)`.

`(C, σ, q, T)` collectively determine the `(ε, δ)`. Change any
one and the accountant returns a different budget.

---

## Opacus — the standard PyTorch integration

Opacus (Meta, PyTorch project) attaches to a normal PyTorch
training loop. The minimal wire-up:

```python
import torch
from torch.utils.data import DataLoader
from opacus import PrivacyEngine

model = build_model().to(device)
optimizer = torch.optim.SGD(model.parameters(), lr=0.1)
data_loader = DataLoader(train_dataset, batch_size=256, shuffle=True)

privacy_engine = PrivacyEngine(accountant="rdp")

model, optimizer, data_loader = privacy_engine.make_private(
    module=model,
    optimizer=optimizer,
    data_loader=data_loader,
    noise_multiplier=1.1,
    max_grad_norm=1.0,
)

for epoch in range(epochs):
    for x, y in data_loader:
        x, y = x.to(device), y.to(device)
        optimizer.zero_grad()
        loss = criterion(model(x), y)
        loss.backward()
        optimizer.step()

    epsilon = privacy_engine.get_epsilon(delta=1e-5)
    print(f"epoch={epoch}  ε={epsilon:.2f}  δ=1e-5")
```

`make_private` wraps three things:

- **`GradSampleModule`** around the model to expose per-sample
  gradients (Opacus uses hooks to capture them; the model layers
  must support per-sample gradient extraction — see the
  compatibility notes below).
- **`DPOptimizer`** around the optimiser to perform clipping and
  noise addition.
- **`DPDataLoader`** around the DataLoader to switch from standard
  batching to **Poisson sampling** — each training record is
  included in each batch independently with probability `q`. This
  is the sampling model the accountant assumes; using a shuffle-
  style DataLoader with the accountant returns wrong `(ε, δ)`.

### The "with target ε" variant

The more useful entry point is `make_private_with_epsilon`, which
sets `noise_multiplier` for you given a target budget:

```python
model, optimizer, data_loader = privacy_engine.make_private_with_epsilon(
    module=model,
    optimizer=optimizer,
    data_loader=data_loader,
    target_epsilon=3.0,
    target_delta=1e-5,
    epochs=20,                # accountant needs to know the total
    max_grad_norm=1.0,
)
```

You state the budget you want (`target_epsilon`, `target_delta`,
`epochs`); Opacus computes the noise multiplier that will land
inside the budget for the given batch size and dataset size. This
is the preferred entry point when the platform is enforcing a
budget as a training-plan input.

### Accountant choice

Opacus supports several accountants; the two you should know:

- **RDP (Rényi Differential Privacy).** The classical accountant;
  fast; loose (returns a larger `ε` for the same noise than the
  tightest analyses).
- **PRV (Privacy Random Variables) / GDP (Gaussian Differential
  Privacy).** Tighter accountants introduced in later Opacus
  releases; recommended for new work when available. Verify which
  accountants your Opacus version exposes and pick the tightest
  one that is documented as stable for your training setup.

Do not switch accountants mid-run. Choose at the start; record the
choice on the model card.

---

## Sizing the run — how to hit a target budget

The four variables `(C, σ, q, T)` are coupled. In practice you
choose them in this order:

1. **Set the budget.** `target_epsilon` and `target_delta` come
   from the requirement (data classification, regulator
   expectation, downstream use case).
2. **Choose the batch size.** DP-SGD prefers **large** batches —
   larger batches average out the noise. Batch sizes of 512–8192
   are common in production DP-SGD papers, versus 32–256 for
   non-private training. The batch size caps the sampling rate
   `q = batch_size / dataset_size`.
3. **Choose the epoch count.** More epochs → more steps → tighter
   noise needed to fit the budget → lower utility. Fewer epochs
   → looser noise but less optimisation → also lower utility. The
   sweet spot is usually below the non-private epoch count.
4. **Choose the clipping norm.** `C` is a hyperparameter — Opacus
   defaults are a starting point. Too small → gradients heavily
   truncated → poor optimisation. Too large → noise magnitude
   dominates → poor optimisation. Sweep `C ∈ [0.1, 10]` in
   log-scale for a real project.
5. **Let Opacus compute the noise multiplier.** With `make_
   private_with_epsilon`, `σ` is derived.

### The utility conversation

Every DP-SGD run has a **utility cost** — accuracy on a held-out
set is lower than the non-private baseline. The size of the cost
depends on:

- **Dataset size.** Larger datasets tolerate DP-SGD better; the
  noise averages out over more samples. Tiny datasets and DP-SGD
  do not mix.
- **Model size.** Larger models tend to lose more utility for the
  same budget; there is active research on why and on
  architectures that fare better.
- **Data domain.** Text and image models with strong pre-training
  transfer reasonably well; tabular and small-scale supervised
  problems suffer more.
- **The budget itself.** `ε = 1` typically costs 5–20% accuracy
  vs. non-private; `ε = 8` typically costs 1–5%. Neither range
  is guaranteed — measure on your data.

The training-plan approval should include:

- Non-private baseline accuracy on the eval set.
- DP-SGD accuracy at the target `(ε, δ)`.
- The delta and whether it is acceptable for the deployment.

If the delta is too large, negotiate with the stakeholder: a
weaker budget (larger `ε`) trades utility for privacy, and the
tradeoff is explicit rather than smuggled.

---

## Reporting on the model card

The mod-104 model card (chapter 05) has a privacy section. A
DP-SGD model card fills it as:

```yaml
privacy:
  method: dp_sgd
  library: opacus
  library_version: "1.4.0"     # example — record the actual version
  accountant: prv              # or rdp — record which
  guarantee:
    epsilon: 2.98
    delta: 1e-5
    record_definition: "one user's complete session"
  training_config:
    dataset_size: 1_845_002
    batch_size: 2048
    sampling_rate: 0.001110
    epochs: 20
    steps: 18018
    max_grad_norm: 1.0
    noise_multiplier: 1.31     # computed by make_private_with_epsilon
  utility:
    baseline_accuracy: 0.912   # non-private, same architecture, same epochs
    dp_accuracy: 0.879
    utility_gap: 0.033
  evaluation:
    membership_inference_auc: 0.53    # from chapter 05 measurement
    baseline_mi_auc: 0.71             # the non-private baseline
```

Every field is load-bearing. Missing `record_definition` makes the
budget ambiguous; missing `sampling_rate` makes it unauditable;
missing `library_version` makes the accountant claim
unreproducible.

The mod-104 audit log records the same values as an
attestation; mod-109 governance consumes them at audit time.

---

## Compatibility — what breaks and how to fix it

Opacus attaches per-sample-gradient hooks to every layer. Layers
that share parameters across samples (or that batch-normalise
across samples) break the hooks and either raise an error at
`make_private` or silently return wrong gradients.

Common issues:

- **`BatchNorm` layers.** Illegal — BN mixes gradient signal
  across samples. Opacus provides `ModuleValidator.fix(model)` to
  swap `BatchNorm` → `GroupNorm` (or `LayerNorm`, depending on
  the layer). Run this before `make_private`.
- **Frozen layers.** Layers with `requires_grad = False` do not
  receive per-sample gradient hooks; Opacus honours the freeze.
  This is useful for fine-tuning: freeze the backbone, run DP-SGD
  on the head only — faster convergence, smaller sensitivity,
  usually better utility.
- **DDP / DistributedDataParallel.** Requires the Opacus DDP
  helpers. Poisson sampling across DDP workers is subtle; do not
  hand-roll it. Use `DPDataLoader.from_data_loader(..., distributed=True)`
  or the recipes in the Opacus documentation.
- **Custom layers.** Any custom module must implement per-sample
  gradient logic Opacus can hook into. Opacus's `grad_sample`
  module documents the extension points.
- **Optimisers with momentum / adaptive learning rates.** Adam and
  friends work but interact non-trivially with the noise addition.
  SGD with momentum is the safe default; adaptive optimisers
  should be sweep-tuned.
- **Gradient accumulation.** Opacus supports "virtual" batching
  via `BatchMemoryManager` — accumulate per-sample gradients into
  a virtual large batch when the physical batch does not fit in
  memory. This is the recommended pattern for GPU-limited setups.

If `make_private` fails, do not silently downgrade to non-DP
training. Fix the compatibility issue or explicitly choose a
different privacy approach.

---

## Composition and lifecycle concerns

- **Every retraining consumes new budget.** The `(ε, δ)` is per
  training *run*, not per dataset. If you retrain on the same
  underlying data monthly, an attacker with access to every
  checkpoint sees a composed budget. Track cumulative retraining
  and consider Renyi composition or a stricter per-run budget.
- **Fine-tuning consumes its own budget.** Fine-tuning a DP-
  pretrained model with more DP-SGD composes; fine-tuning
  without DP loses the guarantee entirely. State the composition
  on the model card.
- **Data-augmentation and DP.** Every training example run through
  augmentation is still one record for accounting purposes; the
  augmentations do not add DP protection.
- **Hyperparameter tuning consumes budget.** Every private-training
  run for hyperparameter search technically uses the private data.
  For a rigorous budget, use a private hyperparameter selection
  method or hold out a public dataset. In practice, small-scale
  sweeps on a proxy dataset and a single final DP run is the
  standard pattern; call it out on the model card.
- **Evaluation on the private dataset.** Model evaluation queries
  are not typically counted against the budget in DP-SGD (they
  are usually held-out). Do not evaluate on the training set;
  hold out a public eval set.

---

## Standard failure modes

- **"We used Opacus" without an `(ε, δ)`.** The default library
  wrapping is not a claim. Every DP-SGD run states the budget.
- **`make_private` succeeds but the accountant is wrong.**
  Sampling-rate mismatches (using a shuffle DataLoader) or DDP
  mistakes silently corrupt the accountant. Test that `get_
  epsilon` returns the value you expect on a synthetic short run
  before starting the real training.
- **Clipping norm chosen without a sweep.** Default `C = 1.0` is
  a placeholder. The right value depends on the gradient
  magnitude distribution and needs a small sweep.
- **`BatchNorm` untreated.** Errors at `make_private` (best case)
  or silent gradient corruption (worst case).
- **Publishing the RDP `ε` as if it were the tightest bound.**
  RDP is loose; if a tighter accountant exists in your Opacus
  version, use it and report the tighter number.
- **Retraining the same model monthly without budget composition.**
  The individual runs are budget-compliant; the composition is
  not. Either compose the budget in the model card (declare "1
  year at 12 retrainings composes to `(ε_total, δ_total)`") or
  rotate the underlying training data.
- **DP-SGD as a checkbox against every privacy risk.** DP-SGD
  bounds record-level leakage from the trained model. It does
  nothing about serving-side extraction (chapter 05), prompt-
  based training-data extraction on LLMs (mod-107), or data-
  storage leaks (mod-105 / mod-108).
- **Ignoring the utility hit.** A DP model that no product owner
  will ship is a DP model in name only. Negotiate the budget
  against the utility, do not ship the utility drop as a
  surprise.

---

## The mistakes this chapter is trying to prevent

- **Confusing "we added noise" with "we trained with DP".** The
  claim is `(ε, δ)`-DP with a named accountant and a named
  record definition. Anything less is a training modification,
  not a privacy guarantee.
- **Skipping the accountant tightness upgrade.** RDP is easy;
  PRV / GDP are tighter. Use the tightest accountant your Opacus
  version supports and record which.
- **Treating hyperparameters as if defaults are safe.** Opacus'
  defaults are starting points. Clipping norm, batch size, and
  epoch count *all* need attention or the resulting `(ε, δ)` is
  wrong or the utility is unnecessarily bad.
- **Wiring DP-SGD only to the training platform, not to the model
  card.** The privacy claim must land on the model card
  (mod-104), in the audit log (mod-104), and in the governance
  evidence (mod-109). A DP run that does not land there is
  operationally invisible.
- **Not measuring MI-AUC afterwards.** DP-SGD's theoretical bound
  is loose in practice — empirical MI-AUC is often much lower
  than the bound suggests. Measure and report both.
- **Composing without accounting.** Every retraining, fine-tune,
  and hyperparameter sweep on the same data adds privacy cost.
  Compose or reset the budget, but do not ignore it.

---

## Summary

- Differential privacy in the DP-SGD sense gives a per-record
  `(ε, δ)` guarantee: any single training record's presence
  changes any observable outcome by at most a factor of `e^ε`,
  except with probability `δ`.
- Opacus provides the PyTorch implementation. Use
  `make_private_with_epsilon` to state the budget and let Opacus
  derive the noise multiplier; use the tightest accountant your
  release supports (PRV where available, RDP otherwise).
- Size the run around the budget: batch size ↑, epochs at the
  sweet spot, clipping norm swept, noise derived. Report the
  utility gap against the non-private baseline; a DP model with a
  hidden accuracy tax is a DP model that will not ship.
- The model card is the deliverable — `ε`, `δ`, accountant,
  record definition, all four training hyperparameters, and the
  utility numbers. Missing fields make the claim unauditable.
- Compatibility (`BatchNorm` → `GroupNorm`, DDP recipes, per-
  sample gradient extraction) is the operational cost of
  DP-SGD; plan for it in the training-plan approval.
- DP-SGD composes with — and does not replace — the serving-side
  controls in chapter 05 and the broader privacy programme in
  mod-108. Every retraining adds to the composed budget; account
  for it or rotate the training data.
