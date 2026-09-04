# Exercise 05 — DP-SGD Configuration with Opacus

**Estimated effort:** ~4 hours
**Deliverable:** A runnable DP-SGD training bundle consisting of
(a) a training script that wraps the target model's training
loop with Opacus at a stated `(target_epsilon, target_delta)`,
(b) a hyperparameter-sizing worksheet showing how `C`, batch
size, epochs, and noise multiplier were chosen for the budget,
(c) a utility-comparison table against the non-private baseline,
(d) a completed model-card privacy section that lists every
field from chapter 06's model-card sketch with real numbers,
and (e) a written interpretation memo covering the utility-gap
verdict, the MI-AUC re-measurement (against the exercise-04
baseline), and the composition / retraining plan.
**Prerequisites:** Chapter 06 read end-to-end. Exercise 04
completed for the baseline MI-AUC. A target model whose training
loop you can modify (a small classifier is the right scale —
Opacus can be configured on almost any architecture but a first
successful run should not fight both DP-SGD and a distributed
training setup at the same time). Python with `torch`, `opacus`,
and the training-data pipeline for the target.

---

## Objective

Move DP-SGD from "we should use it" into a runnable, budgeted,
model-card-ready configuration. This exercise closes the loop
started in exercise 04 — the MI-AUC that triggered the concern
becomes the metric this exercise's model must beat.

By the end of this exercise you have:

- A DP-SGD run that completes with a stated `(ε, δ)` under a
  named accountant.
- Hyperparameters chosen with an explicit sizing argument, not
  by accepting defaults.
- The utility cost quantified against the non-private baseline
  on the same eval set.
- The model-card privacy section filled in with every field
  chapter 06 names.
- A composition-and-retraining plan: what the next retraining
  will do to the budget, and when the org has to reset.

You are producing a defensible DP training run. The kind a
regulator or a governance auditor can look at and understand.

---

## Problem statement

Continue with the target model from exercise 04. Its baseline
MI-AUC is known and, if the memo from exercise 04 recommended
DP-SGD, is high enough to be worth reducing.

Current state:

- Non-private training pipeline exists and reaches a known
  clean-accuracy baseline.
- MI-AUC baseline from exercise 04 is on the record.
- No DP-SGD.
- Retraining cadence: assume monthly on rolling training data
  (a common continual-learning setup — adjust to the actual
  cadence if you know it).

Your job is to configure Opacus, run one DP-SGD training,
compare it, and write the plan for the next several retrainings.

---

## Requirements

### Deliverable A — DP-SGD training script

A committed training script that:

1. Loads the target model and the training data (same source as
   the non-private pipeline; same pinned seeds where the loop
   allows).
2. Runs `ModuleValidator.fix(model)` (or documents that the
   model has no BatchNorm and this step is unnecessary).
3. Constructs the optimiser and the DataLoader as normal.
4. Wraps them with `PrivacyEngine.make_private_with_epsilon`
   at a stated `target_epsilon`, `target_delta`, `epochs`, and
   `max_grad_norm`.
5. Selects the tightest accountant Opacus exposes in the
   version pinned in the repo (PRV if available, otherwise RDP;
   log which was chosen).
6. Trains to completion.
7. Emits `privacy_report.json`:

```json
{
  "library": "opacus",
  "library_version": "1.4.0",
  "accountant": "prv",
  "target_epsilon": 3.0,
  "target_delta": 1e-5,
  "achieved_epsilon": 2.98,
  "achieved_delta": 1e-5,
  "hyperparameters": {
    "max_grad_norm": 1.0,
    "noise_multiplier": 1.31,
    "batch_size": 2048,
    "sampling_rate": 0.001110,
    "epochs": 20,
    "steps": 18018
  },
  "dataset": {
    "size": 1845002,
    "hash": "sha256:..."
  },
  "record_definition": "one user's complete session",
  "notes": "..."
}
```

Constraints:

- Do not accept Opacus defaults without checking. `noise_multiplier`
  is derived by `make_private_with_epsilon`; `max_grad_norm` is
  chosen and defended in Deliverable B.
- Data loader must be the Opacus `DPDataLoader` (via `make_
  private_*`). Do not fall back to a shuffle DataLoader and
  report the resulting `(ε, δ)` — the accountant would be wrong.
- Do a **short synthetic-run sanity check** before the real
  training: 100 steps on a small subset, verifying
  `privacy_engine.get_epsilon(delta=target_delta)` returns
  something consistent with the manual accountant calculation.
  Attach the log of the sanity check to the deliverable.

### Deliverable B — hyperparameter-sizing worksheet

A Markdown worksheet showing how each hyperparameter was chosen.
The worksheet is a *record of decision*, not a report of a
tuning run.

Sections:

1. **Budget target.** `target_epsilon`, `target_delta`, and
   what stakeholder / requirement they descend from (regulatory
   ask, mod-108 policy, product owner sign-off).
2. **Batch size.** Chosen batch size and why (memory limit,
   the effective batch size the accountant needs). If gradient
   accumulation was used, show the physical batch and the
   effective batch and confirm Opacus's `BatchMemoryManager`
   was wired.
3. **Epochs.** Chosen epoch count and why. Argue against both
   more (budget exhaustion) and fewer (under-training).
4. **Clipping norm `C`.** How was it chosen? A written sweep is
   ideal (`C ∈ {0.1, 0.5, 1.0, 2.0, 5.0}` on a short run
   observed for gradient-norm distribution) with the chosen
   value justified against the observed distribution.
5. **Noise multiplier `σ`.** State that it is derived by
   `make_private_with_epsilon`. Record the returned value.
6. **Accountant choice.** Name the accountant used, why (tighter
   is better where the release supports it as stable), and the
   version pinning.

### Deliverable C — utility comparison

A table comparing the DP-SGD run against the non-private
baseline on the *same* eval set.

| Metric | Non-private baseline | DP-SGD (target ε) | Delta | Comment |
| --- | --- | --- | --- | --- |
| Clean accuracy | | | | |
| Class-balanced accuracy | | | | if imbalance matters |
| MI-AUC | | | | |
| Low-FPR TPR (0.1%) | | | | |
| Training wall-clock | | | | |

Rules:

- **Same eval set for both.** Members / non-members sets
  identical to exercise 04 so the MI-AUC comparison is
  apples-to-apples.
- **Non-private baseline is the same architecture, same
  augmentation, same epoch count.** If the DP-SGD run trained
  for a different epoch count for budget reasons, also record
  a non-private baseline at the same epoch count as a
  secondary reference.
- **Utility gap is the number to negotiate with.** If the gap
  is unacceptable, the memo argues for a weaker budget or a
  different technique, not for hiding the gap.

### Deliverable D — model-card privacy section

Fill in every field from the model-card sketch in chapter 06:

```yaml
privacy:
  method: dp_sgd
  library: opacus
  library_version: "..."
  accountant: prv | rdp
  guarantee:
    epsilon: ...
    delta: ...
    record_definition: "..."
  training_config:
    dataset_size: ...
    batch_size: ...
    sampling_rate: ...
    epochs: ...
    steps: ...
    max_grad_norm: ...
    noise_multiplier: ...
  utility:
    baseline_accuracy: ...
    dp_accuracy: ...
    utility_gap: ...
  evaluation:
    membership_inference_auc: ...
    baseline_mi_auc: ...
    tpr_at_fpr_0.001: ...
    baseline_tpr_at_fpr_0.001: ...
```

Every field populated. Every field's value traceable to a
specific file (the privacy report, the utility table, the
exercise-04 MI-AUC report).

Attach this section to the target model's model card (mod-104
chapter 05). If the model card does not exist yet, produce one
following the mod-104 template and put this section in it.

### Deliverable E — interpretation memo

~2 pages of Markdown. Answer:

1. **What budget did we ship?** Restate `(ε, δ)`, accountant,
   and record definition. State what "one record" is in
   business terms — a user, a session, a document.
2. **What is the utility cost?** Point at the utility table. If
   the cost is acceptable, name the sign-off; if it is not,
   name the fallback (looser budget, different technique, hold
   the release).
3. **Did MI-AUC drop?** Compare against the exercise-04
   baseline. DP-SGD's theoretical bound is loose; the empirical
   delta is what the model card and the governance audit
   care about. If MI-AUC did not drop, investigate — the noise
   multiplier may be too low, or the members / non-members
   split may have a bug.
4. **What is the composition plan?** State the retraining
   cadence and the composed budget after N months. If N months
   of composition exceeds the org's per-model budget, state
   when the training data has to be rotated or the budget
   reset.
5. **What did not work?** DP-SGD has real failure modes. Any
   BatchNorm surprises, per-sample-gradient errors, DDP
   struggles, or hyperparameter dead-ends go here.
6. **What is the next step?** Point at mod-108 if the broader
   privacy programme is next; at exercise 04's MI-AUC monitor
   if the runtime metric needs re-wiring; at the training-
   platform team if the DP-SGD path needs to become a first-
   class training-job option.

Cite:

- Abadi et al. 2016 (the DP-SGD paper).
- The Opacus release notes for the version pinned.
- Whatever accountant paper corresponds to your choice (e.g.
  Gopi et al. 2021 for PRV, Mironov 2017 for RDP).

---

## Starter guidance

- **Sanity-check the accountant on a short run.** Before
  committing to a full training, run 100–500 steps on a small
  subset with a large `target_epsilon` (e.g. 10.0) and verify
  `get_epsilon(delta=target_delta)` returns a value at or below
  the target. If it does not, either the DataLoader was not the
  Opacus one or the accountant is misconfigured.
- **Choose the batch size deliberately.** DP-SGD prefers large
  batches — sometimes an order of magnitude larger than the
  non-private baseline. If memory is a constraint, use
  `BatchMemoryManager` for virtual batching.
- **Run the `C` sweep on a short run.** A full sweep is
  expensive; a short-training sweep gives enough signal to
  choose `C` within a factor of 2.
- **Do not silently downgrade to non-DP on error.** If
  `make_private` fails (BatchNorm, custom layer without
  per-sample gradients), fix the model — do not train without
  the wrapper and claim DP.
- **The MI-AUC comparison is the punchline.** If the number
  does not drop meaningfully, the run has a bug or the budget
  is too loose. Do not paper over a null result.
- **Use the same eval set as exercise 04.** Same file hashes;
  same members / non-members split. Different splits produce
  incomparable numbers.

---

## Acceptance criteria

A passing bundle:

- Training script runs to completion; `privacy_report.json`
  emitted with every field populated.
- Hyperparameter worksheet exists and shows each hyperparameter
  argued, not defaulted.
- Utility comparison table populated with same-eval-set
  numbers for both non-private and DP-SGD.
- Model-card privacy section filled in per chapter 06 with
  every value traceable to a file.
- Interpretation memo covers budget, utility, MI-AUC delta,
  composition plan, failure modes, and next step.
- The chosen accountant is the tightest supported by the
  pinned Opacus version, and the version is named.

A failing bundle:

- `PrivacyEngine` wired but `(ε, δ)` not reported.
- DataLoader is not the Opacus `DPDataLoader` (accountant would
  be wrong).
- MI-AUC not re-measured against the exercise-04 baseline.
- Utility comparison against a different eval set than
  exercise 04.
- Model-card privacy section with missing fields.
- Memo that reports a null MI-AUC delta without investigating
  the possible bug.

## Stretch goals

- **Composition demo.** Run the DP-SGD training three times
  (simulating three months of retraining) and compute the
  composed `(ε, δ)` under sequential composition. Compare
  against the org's per-model budget; if the composition
  exceeds it, propose either a training-data-rotation cadence
  or a per-run budget that keeps the composition inside the
  budget.
- **DDP-DP-SGD.** Move the DP-SGD run to a multi-GPU
  distributed setup using Opacus's DDP recipes; verify the
  accountant still reports the correct `(ε, δ)`. Distributed
  DP-SGD trips up teams; write down the specific gotcha you
  hit.
- **Frozen-backbone fine-tune.** Freeze the backbone and run
  DP-SGD only on the head; compare `(ε, δ)` vs. utility with
  the full-model DP run. Often the frozen-backbone variant is
  the better production choice.
- **Hyperparameter sweep with a privacy-aware selection.**
  Instead of ad-hoc `C` selection, use a private-selection
  method (e.g. exponential-mechanism selection over a small
  grid) and report the additional budget spent.
- **DP-SGD as a first-class training-job option.** Extend the
  training platform's YAML (per exercise 02) with a `dp_sgd:`
  section analogous to the `adversarial_training:` section.
  Argue the schema; leave the implementation to the platform
  team.
- **Utility recovery.** After the DP run, try one recovery
  trick (temperature scaling, weight-averaging, small non-
  private eval-only calibration) and measure how much utility
  comes back. Do not violate the budget.

## Do not

- Do not skip the sanity-check short run. It catches sampling-
  rate and accountant mismatches before you burn a full
  training on a wrong number.
- Do not accept `max_grad_norm = 1.0` as a default without a
  short gradient-norm distribution check.
- Do not report an `ε` without the accountant name — RDP,
  PRV, and GDP will disagree by a meaningful amount on the same
  run.
- Do not run DP-SGD on private data on a laptop without
  approval. The training data is protected by the resulting
  budget; the training environment must protect it before the
  budget is proven.
- Do not compose retrainings silently. Every retraining spends
  budget; the model card must reflect the composition or the
  policy that prevents it.
- Do not commit a solution here — solutions live in the paired
  solutions repo.
