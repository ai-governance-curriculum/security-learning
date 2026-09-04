# Exercise 01 — Robustness Baseline Assessment with ART

**Estimated effort:** ~3 hours
**Deliverable:** A committed baseline-assessment bundle consisting
of (a) the chapter-01 threat-model artefact filled in for one
target model, (b) a runnable evaluation harness using the
Adversarial Robustness Toolbox that reports robust accuracy under
AutoAttack and at least two auxiliary attacks at a stated threat
model, (c) a robust-accuracy scorecard (Markdown or CSV) with the
attack, ε, and reported number per row, and (d) a written
interpretation memo that names which findings warrant follow-up
in exercises 02–05.
**Prerequisites:** Chapter 01 read end-to-end. A target model
(any classifier — a CIFAR-10 baseline, a fraud model you have
access to, a public HuggingFace image classifier, or a scratch
model trained for this exercise). Python environment with `torch`,
`torchvision`, `adversarial-robustness-toolbox`, and `autoattack`
installed at recent versions (verify current release notes for
API compatibility).

---

## Objective

Produce the *before* number that every subsequent chapter compares
against. Without a baseline, every defence in this module is
argued in the abstract; with one, the model team can see the
delta.

Concretely, by the end of this exercise you have:

- Written down which of the five NIST AI 100-2 / OWASP ML Top 10
  attack families apply to the target model, and for each, the
  attacker access, consequence, and owner.
- Measured robust accuracy on the model under a standard attack
  ensemble at a stated threat model (norm + ε).
- Explained the numbers well enough that a reader who has not
  seen the model can decide whether the risk profile is
  acceptable.

You are *not* fixing the model in this exercise. You are
producing the baseline that justifies the fix.

---

## Problem statement

Pick one target model. If you have a real production or staging
model with read access, use it — the reality check is much
better than a toy. If not, train a small CIFAR-10 or MNIST
classifier for the exercise; a stock ResNet-18 with standard
augmentation and no adversarial defence trains in under an hour
on a single consumer GPU.

Whatever the model, the current state is:

- Trained normally; no adversarial training, no smoothing, no
  DP-SGD.
- Deployed (or would be deployed) behind a query API with basic
  rate limiting.
- Never had its robust accuracy measured, or measured only
  informally.

Your job is to produce a **security-facing** assessment — not a
research paper. The audience is the on-call security engineer
who inherits this model next week.

---

## Requirements

### Deliverable A — threat-model artefact

Fill in the table from chapter 01 for this specific model:

| Attack family | Applicable? | Attacker access assumed | Consequence if unmitigated | Defence chapter | Owner |
| --- | --- | --- | --- | --- | --- |
| Evasion | | | | 02 / 03 | |
| Data poisoning | | | | 04 | |
| Backdoor | | | | 04 (+ mod-104, mod-110) | |
| Model extraction | | | | 05 | |
| Membership / attribute inference | | | | 05 + 06 | |

Rules from chapter 01 apply:

- Every "Applicable? = yes" row must have a named owner and a
  defence chapter reference.
- Every "Applicable? = no" row must have a written reason.
- "The model isn't deployed yet" is not a reason to strike a
  row — it is a decision to defer, and must be labelled as such.

### Deliverable B — evaluation harness

A committed, runnable script (or notebook, if the team prefers)
that:

1. Loads the target model at a pinned version (weights hash + a
   commit SHA of the loading code).
2. Loads a held-out evaluation set of at least 1000 samples the
   model has not seen during training. State how the split was
   done and how you verified the samples are held out.
3. Records **clean accuracy** on the eval set as the reference.
4. Runs **AutoAttack** (Croce & Hein 2020) as the primary
   evaluation at a specified `(norm, ε)`. The `standard` version
   is the required baseline; `rand` and `plus` are optional
   supplements.
5. Runs at least **two auxiliary attacks** from ART — pick from
   FGSM, PGD (with a step count and step size different from the
   training claim if the model was ever adversarially trained),
   Carlini & Wagner L2, DeepFool. Each attack runs at the same
   `(norm, ε)` as AutoAttack for direct comparison.
6. Writes a machine-readable report (JSON or CSV) with one row
   per attack containing: attack name, norm, ε, evaluated
   sample count, robust accuracy, wall-clock runtime, and the
   library version.

Constraints:

- **Norm and ε are chosen deliberately.** For an image classifier,
  L∞ ε ∈ {4/255, 8/255} is the standard image benchmark. For a
  tabular model, choose per-feature bounds or L2 — argue the
  choice in the memo (Deliverable D).
- **Reproducibility.** The script sets random seeds where library
  APIs expose them; the report captures the random seed so a
  colleague can rerun and get the same number.
- **Do not evaluate only inside the training distribution.**
  Include at least one adversarial-perturbation attack at a
  *higher* ε than the primary evaluation to see how robustness
  degrades.
- **No PII in the report.** Perturbation examples are diagnostic;
  do not attach raw customer inputs.

### Deliverable C — robust-accuracy scorecard

A Markdown table (in the exercise's directory or attached to the
model card) shaped as:

| Attack | Norm | ε | Robust accuracy | Notes |
| --- | --- | --- | --- | --- |
| Clean (no attack) | — | 0 | | reference |
| AutoAttack (standard) | | | | primary claim |
| PGD (K=…, α=…) | | | | auxiliary |
| C&W L2 | | — | | auxiliary |
| PGD at 2× ε | | | | out-of-band stress |

The reported **robust accuracy** for the primary claim is
`min(AutoAttack, auxiliaries)`. If any auxiliary attack breaks
the AutoAttack number by more than 3 percentage points, flag the
result — this often indicates a gradient-masking bug on the
model or an evaluation misconfiguration; do not silently publish
the higher number.

### Deliverable D — interpretation memo

~2 pages of Markdown. Not a paper. Answer, in this order:

1. **What did we test and why?** State the model, the eval set,
   and the threat model (norm + ε). State what an attacker who
   wins each attack could actually do to the product.
2. **What did we find?** Report the clean accuracy, the primary
   robust accuracy, and the tightest auxiliary. Point out any
   discrepancies.
3. **Where does the model land vs. reference points?** Compare
   against RobustBench for the closest architecture and dataset.
   If the model reports robust accuracy substantially above
   RobustBench SOTA at the same threat model, treat it as a bug
   (gradient masking, evaluation misconfiguration, wrong ε units)
   and investigate before publishing.
4. **Which of the chapter-01 rows is this the "before" number
   for?** Name the rows explicitly. This exercise only measures
   evasion (family 1) directly — but the memo must say so, and
   name what would produce the baseline for the other four
   families (exercises 03, 04, 05).
5. **What is the recommended next step?** Point at the specific
   exercise (02 = adversarial training, 03 = smoothing, 04 =
   poisoning detection, 05 = privacy monitors) with a one-line
   justification per pointer.

Cite:

- The library version (ART and AutoAttack) at the top.
- The paper for AutoAttack (Croce & Hein 2020) and for each
  auxiliary attack referenced.
- The RobustBench comparison point (URL + accessed date).

---

## Starter guidance

- **Pick the ε before you pick the code.** The threat model is
  the input to the evaluation, not the output. If you have to
  choose between L∞ and L2, argue for one based on the attacker
  capability (pixel-noise attacker → L∞; feature-value shift
  attacker → L2; per-feature-bound attacker → custom).
- **Start with the smallest reasonable eval set.** 1000 samples
  runs quickly; scale up when the harness is working. AutoAttack
  on 10 000 samples on a modern GPU is tractable; on a laptop
  CPU it is not.
- **Adopt an existing reference harness rather than writing
  from scratch.** The ART examples repository and the AutoAttack
  reference implementation both include drop-in loops that avoid
  the common mistakes (wrong preprocessing, wrong labels format,
  wrong batch size).
- **Run PGD twice** — once with the step count you would use for
  training (chapter 02 default: K=10), once with a higher count
  (K=50). Diverging results between them is a smell.
- **Do a "does the attack actually attack" sanity check.** If
  PGD at ε=8/255 does not lower accuracy at all, either your
  preprocessing is wrong, the labels are miscoded, or you are
  attacking a model that already saw these adversarials (label
  leakage). Fix it before writing the report.
- **Assume the numbers will change.** ART and AutoAttack are
  living projects; the assessment is a snapshot at a library
  version, and the top of the report says so.

---

## Acceptance criteria

A passing bundle:

- Threat-model artefact is filled in end-to-end with the rules
  above obeyed (no unnamed owners on "yes" rows; no unlabelled
  "no" rows).
- Evaluation harness runs from a fresh clone (`pip install -r
  requirements.txt && python evaluate.py --config config.yaml`)
  and produces the JSON / CSV report.
- Scorecard is present with a value in every cell it defines.
- Primary robust-accuracy number is `min(AutoAttack,
  auxiliaries)`; the memo explains any inter-attack discrepancy.
- Interpretation memo cites library versions, at least one
  RobustBench comparison, and points at the specific follow-up
  exercises.

A failing bundle:

- Reports the training-time attack's accuracy as the robustness
  number.
- Claims robustness without stating the norm and ε.
- Omits AutoAttack entirely.
- Publishes a robust-accuracy number substantially above
  RobustBench SOTA at the same threat model without
  investigation.
- Threat-model artefact treats "we don't have a defence yet" as
  "not applicable".
- Harness that does not reproduce (missing pins, missing seed,
  missing config).

## Stretch goals

- **Add a transferability check.** Craft AutoAttack adversarials
  against a *different* model (e.g. a torchvision-pretrained
  ResNet-50) and evaluate them against the target. High transfer
  success rates reveal that closed-weight serving does not
  buy you as much as you might hope.
- **Evaluate under an out-of-band perturbation.** Rotate,
  colour-shift, or add a small adversarial patch (via
  `art.attacks.evasion.AdversarialPatch`). This measures
  semantic robustness that the L∞ / L2 story does not cover.
- **Extend to a tabular model.** Repeat the exercise on a tabular
  classifier using per-feature bounds and ART's tabular attacks
  (e.g. `HopSkipJump` for black-box). Argue the threat model
  differently than for images.
- **Wire the harness into CI.** Every model version's baseline
  robustness runs on release as a CI check; the model-card row
  updates automatically. This is exercise-02 material done
  eagerly.
- **Publish the harness as a reusable module.** If the
  organisation has multiple models, the harness becomes a shared
  service. Extract the config, the report writer, and the CI
  wiring into a package.

## Do not

- Do not use production customer data as the evaluation set
  without the privacy team's sign-off; a held-out synthetic set
  is preferable for a first pass.
- Do not commit large evaluation datasets to git; reference them
  by URL or by managed-storage path.
- Do not skip the RobustBench comparison — if you are outside
  the leaderboard's range, the finding is a bug until proven
  otherwise.
- Do not label the primary attack as "AutoAttack" without stating
  the version (`standard` / `plus` / `rand`) and the ensemble
  members.
- Do not commit a solution here — solutions live in the paired
  solutions repo.
