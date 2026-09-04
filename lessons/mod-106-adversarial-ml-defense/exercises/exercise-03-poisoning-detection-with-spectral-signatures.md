# Exercise 03 — Poisoning Detection with Spectral Signatures

**Estimated effort:** ~4 hours
**Deliverable:** A runnable detection bundle consisting of (a) a
poisoned-dataset generator that produces two labelled variants
of a chosen dataset — one BadNets-style backdoor and one clean-
label targeted poisoning — with pinned seeds and injection
rates, (b) a spectral-signature and activation-clustering
implementation (write-your-own or thin wrapper around ART) that
runs on the poisoned corpus and emits a per-index verdict, (c) a
retraining-and-recovery experiment that reports poison-removal
precision, poison-removal recall, and the attack success rate
before and after filtering, and (d) a written interpretation
memo that reads the numbers and names the failure modes.
**Prerequisites:** Chapter 04 read end-to-end. Exercise 01
completed for baseline evaluation practice. Python with `torch`,
`torchvision`, `adversarial-robustness-toolbox`, `scikit-learn`,
and `numpy` at recent versions.

---

## Objective

Get concrete with poisoning detection. Chapter 04 named
spectral-signature and activation-clustering as feature-space
defences; this exercise runs them on a poisoned dataset you
construct, so the "how many poisoned samples did we catch, and
at what cost in dropped clean samples" tradeoff becomes real.

By the end of this exercise you have:

- Injected two shapes of poison (backdoor + clean-label) with
  known ground truth.
- Run spectral-signature and activation-clustering detection.
- Measured detection precision and recall against the ground
  truth.
- Retrained on the filtered corpus and shown the attack-success-
  rate delta.
- Written the failure-mode section that says which shapes of
  poison the detectors miss and why.

You are proving to yourself that these defences are useful and
learning their limits at the same time. Both matter.

---

## Problem statement

Continue with the target model from exercise 01 if it is a
classifier on image or tabular data; otherwise pick a small
substitute — CIFAR-10 with ResNet-18 is the standard reference
because the literature is calibrated on it, and it fits on one
consumer GPU.

The current state:

- You have a clean training set of `N` samples with `C` classes
  and a held-out clean eval set.
- You will construct two poisoned variants of the training set
  with known ground-truth poison indices.
- Nothing in the current pipeline filters poison. A production
  team that inherited this pipeline would have no way to know
  whether the training set had been tampered with.

Your job is to build the detection layer, measure it, and write
down what it caught and what it missed.

---

## Requirements

### Deliverable A — poisoned-dataset generator

A committed script that produces two poisoned variants of the
training set, both with pinned seeds so runs are reproducible.

**Variant 1 — BadNets-style backdoor.**

- Choose a target class `c_target` and a trigger — the canonical
  choice is a small 3×3 or 4×4 pixel patch in a fixed corner with
  a distinctive colour (e.g. bright yellow on a natural image
  dataset). For tabular data, choose a rare-value combination on
  a small set of features.
- For a chosen poison rate (0.5% to 2% of the training set is a
  reasonable starting range), stamp the trigger onto training
  images and relabel them as `c_target`.
- Emit a `poison_indices.json` file listing the indices of the
  poisoned samples so the detector's precision and recall can be
  measured.

**Variant 2 — clean-label targeted poisoning.**

- Choose a target *test* image `x_target` and a target class
  `c_target` different from `x_target`'s true class.
- Craft a small number of poisoned training samples that (a) are
  correctly labelled with their true class, (b) have been feature-
  perturbed towards `x_target` so that when the model trains on
  them it moves the decision boundary in a way that
  misclassifies `x_target` as `c_target`. The simplest recipe
  is the `Poison Frogs` (Shafahi et al. 2018) feature-collision
  attack; ART includes a reference implementation
  (`art.attacks.poisoning.FeatureCollisionAttack`).
- Emit a `poison_indices.json` for this variant too.

Constraints:

- Use fixed, published seeds for both variants so the exercise
  is reproducible.
- The poison rate is a config knob so a stretch goal can sweep
  it.
- Do not commit large binary datasets to the repo; reference
  them by download URL and derive the poisoned variants
  deterministically from the clean download.

### Deliverable B — detection implementation

Two detectors — spectral-signature (Tran, Li, Madry 2018) and
activation-clustering (Chen et al. 2018) — that run on the
poisoned corpus and emit per-index verdicts.

You may:

- Write from scratch following the recipes in chapter 04 and the
  primary papers.
- Use ART's `SpectralSignatureDefense` and `ActivationDefence` as
  reference implementations with a thin wrapper that produces
  the required outputs.
- Do a mix (write spectral-signature, use ART for activation-
  clustering, or vice versa).

Whichever choice, the deliverable includes:

- A single-command entry point (`python detect.py --dataset
  variant1 --detector spectral`).
- A structured output file per detector run:

```json
{
  "detector": "spectral_signature",
  "dataset_variant": "variant1_badnets",
  "class_stats": [
    {"class": 0, "flagged": 12, "kept": 4988, "drop_fraction": 0.0024},
    ...
  ],
  "flagged_indices": [42, 137, 208, ...]
}
```

- Reproducibility metadata at the top of the file: dataset
  hash, model checkpoint hash, `drop_fraction`, `random_seed`,
  library versions.

Run both detectors on both variants (four detector runs total).

### Deliverable C — retraining-and-recovery experiment

For each variant × detector combination:

1. Compute detection precision and recall against the ground-
   truth `poison_indices.json`:

   ```
   precision = |flagged ∩ ground_truth| / |flagged|
   recall    = |flagged ∩ ground_truth| / |ground_truth|
   ```

2. Retrain the model on the *filtered* training set (poisoned
   samples the detector flagged are dropped; other samples
   remain).
3. Measure the **attack success rate** — the fraction of
   triggered inputs classified as `c_target` for variant 1;
   the classification of `x_target` for variant 2 — on the
   original poisoned model and on the retrained-on-filtered
   model.
4. Measure the **clean accuracy** on the held-out clean eval set
   for each retrained model.

Produce a summary table:

| Variant | Detector | Precision | Recall | ASR (poisoned) | ASR (post-filter) | Clean acc (poisoned) | Clean acc (post-filter) |
| --- | --- | --- | --- | --- | --- | --- | --- |

Numbers are the point of this exercise. Do not summarise as
"the detector worked"; write the numbers.

### Deliverable D — interpretation memo

~2 pages of Markdown. Answer:

1. **What was the ground truth?** Poison rate per variant, the
   trigger shape (variant 1) or feature-collision target
   (variant 2).
2. **What did each detector catch, and what did each miss?**
   Point at specific numbers from Deliverable C. Where recall is
   low, hypothesise why — e.g. spectral signature struggles with
   very few clean-label poisons because there is not enough
   signal in a single class's SVD.
3. **What is the cost?** Report the clean-sample drop rate
   (samples flagged that were not poison). Fielding a filter
   that throws away 15% of clean data is a real cost even if the
   ASR delta is dramatic.
4. **What happens when you union the two detectors?** Precision
   and recall on the union — usually better recall, worse
   precision — with the tradeoff discussion.
5. **What would you do next?** Point at adaptive attacks (Koh
   et al. 2018 feature-collision-aware; adaptive-BadNets), at
   pipeline composition with mod-104 provenance, and at trigger-
   search detectors (Neural Cleanse) as the complement.

Cite:

- The papers you followed (Tran/Li/Madry 2018, Chen et al. 2018,
  Shafahi et al. 2018, Gu et al. 2017 BadNets).
- The library version.
- The random seed and the download URL for the base dataset.

---

## Starter guidance

- **Start with BadNets.** It is the easier detection case and
  the failure is obvious in the numbers. Get the whole loop
  working before tackling clean-label poisoning.
- **Sanity-check the injection.** Before running detection,
  train briefly on the poisoned set and verify the attack
  actually works — trigger present → target class predicted.
  If it does not, the detector will trivially "beat" a non-
  attack.
- **Do not tune the `drop_fraction` on the ground truth.**
  Choose it once from the expected worst-case poison rate; do
  not iterate it against the answer or you overfit the detector
  to this specific dataset.
- **Use a mid-training checkpoint for feature extraction.**
  Both detectors need meaningful representations; a random-init
  model produces useless output. If your target model is small,
  train it briefly on the poisoned set and use that checkpoint
  for the detector; note that this is a bootstrap step, not the
  final model.
- **Log the flagged indices from both detectors and compare.**
  Overlap is usually partial; the disagreement teaches you what
  each detector is good at.
- **For clean-label poisoning, expect harder numbers.** The
  literature reports recalls well below 100% even at
  ideal `drop_fraction`s. Do not chase 100% — report what you
  measured.

---

## Acceptance criteria

A passing bundle:

- Two poisoned dataset variants exist with pinned seeds and
  `poison_indices.json` files.
- Detection scripts run to completion on both variants and emit
  the structured output files.
- Retrain-and-recover experiment produces the full summary
  table with real numbers in every cell.
- Memo cites the primary papers, states the seeds and library
  versions, and interprets the numbers rather than restating
  them.
- Detectors' `drop_fraction` was chosen once ex ante and stated
  in the memo — no per-variant tuning against ground truth.

A failing bundle:

- Poison generator without a `poison_indices.json` — the
  detection numbers cannot be validated.
- Detection numbers reported without both precision *and*
  recall.
- No retrain-and-recover step — knowing what the detector
  flagged is not the same as knowing whether the model
  recovered.
- Memo that concludes "detection works" or "detection fails"
  without pointing at the specific numbers.
- Detectors run on a random-init model with no explanation of
  why the features are meaningful.

## Stretch goals

- **Poison-rate sweep.** Rerun the whole pipeline at poison
  rates in `{0.1%, 0.5%, 1%, 2%, 5%}` and plot precision /
  recall / ASR-post-filter as a function of poison rate. This
  shows where each detector's floor is.
- **Adaptive attack.** Implement a Koh et al. 2018-style
  spectral-aware clean-label attack and re-measure. The point
  of a stretch goal is to see the detectors lose; the memo
  discusses why and what layer would catch it (canaries,
  provenance).
- **Neural Cleanse.** Add a third detector on the trained
  poisoned model (Wang et al. 2019). Report the anomaly index
  and compare with the training-time detectors. Discuss where
  Neural Cleanse succeeds where spectral / activation
  clustering does not, and vice versa.
- **Continual-learning canary demo.** Layer a canary set on top
  of the pipeline: define a handful of trigger canaries, train
  the poisoned model, and verify the canary re-scoring step
  catches the backdoor. This directly seeds exercise 04 by
  proving the canary substrate works.
- **Provenance overlay.** Sign each training file with the
  cosign / in-toto flow from mod-104 chapter 02 and attach the
  attestation. Argue how provenance would have prevented the
  variant-1 injection (an unauthorised writer to the training
  bucket) even before detection ran.

## Do not

- Do not use real customer data as a base for the poisoned
  dataset. Poisoning experiments should use public datasets so
  they are safe to publish and reproduce.
- Do not tune `drop_fraction` (or any detector hyperparameter)
  against the ground-truth answer — the exercise measures
  detection, not overfit.
- Do not report the detector as "successful" without a retrain
  step that shows the model actually recovers.
- Do not commit large datasets to git; hash the download and
  regenerate.
- Do not commit a solution here — solutions live in the paired
  solutions repo.
