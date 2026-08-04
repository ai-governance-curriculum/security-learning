# Chapter 02 — Adversarial Training as a Platform Service

> **Note on AI-assisted content.** Verify library APIs (PyTorch,
> TorchAttacks, ART, Cleverhans) against current docs — the training-
> attack surface for these tools has moved between minor releases.
> See [`resources.md`](./resources.md).

---

## Why this chapter exists

Chapter 01 named **evasion** as the inference-time integrity attack
adversarial training addresses. This chapter authors the actual
training pipeline.

The specific failure mode this chapter is written to prevent:

> A research engineer runs PGD adversarial training in a notebook,
> gets +30 points of robust accuracy on CIFAR-10, and writes it up.
> The training team, tasked with "adding adversarial training" to
> the production ImageNet pipeline, discover the notebook uses a
> hand-rolled inner-loop with a hard-coded ε, a hard-coded step
> count, and no gradient-clipping — it OOMs at the batch sizes the
> production pipeline uses, and even when it runs, the robustness
> claim does not survive AutoAttack (Croce & Hein 2020, the standard
> ensemble evaluation) — the original evaluation only used PGD-20 in
> the same threat model it was trained under, and gradient masking
> hid the failure. Six months later the production model has been
> shipped as "adversarially trained" and the security team has been
> quoting the notebook's robust accuracy externally.

Adversarial training as a platform service means:

1. **Configurable, not hand-rolled** — the training platform exposes
   adversarial training as a first-class option on the same training
   job type teams already use, with the attack, threat model, and
   evaluation ensemble as explicit configuration.
2. **Evaluated with a standard ensemble** — robust accuracy reported
   under AutoAttack (or the current state-of-the-art ensemble), not
   only under the attack used during training.
3. **Costed and budgeted** — adversarial training is 3–10× slower
   than standard training; that cost is priced into the training-
   plan approval.
4. **Bounded by an explicit threat model** — you certify robustness
   under a specific L∞ / L2 ball, and outside that ball you make no
   claim.

You leave this chapter able to:

- Configure PGD adversarial training and TRADES on a standard
  training-platform job with an explicit ε, step count, and step
  size.
- Report robust accuracy correctly — under AutoAttack, at the same
  perturbation budget the training claimed, on a held-out set.
- Distinguish empirical from certified robustness and set
  expectations accordingly.
- Recognise the standard failure modes: gradient masking, obfuscated
  gradients, over-fitting to the attack, and clean-accuracy
  collapse.
- Cost an adversarial training run at production scale and produce
  the budget delta the training team needs to approve it.

---

## The mental model — inner min-max

Adversarial training is the *saddle-point / min-max* formulation
Madry et al. 2018 popularised. The training objective changes from
minimising loss on the training data to minimising loss on the
**worst-case perturbed** training data within a threat-model ball:

```
min_θ   E_(x,y) ~ D  [   max_(δ ∈ S)   L( f_θ (x + δ),  y ) ]
```

- `θ` — model parameters.
- `(x, y)` — a training example and its label.
- `S` — the threat-model ball: e.g. `{δ : ||δ||_∞ ≤ ε}` for L∞, or
  `{δ : ||δ||_2 ≤ ε}` for L2.
- `L` — the loss (cross-entropy for classification).

The inner `max` is intractable exactly; you approximate it with a
strong attack — canonically **projected gradient descent (PGD)** — and
train against that approximation.

Two operational takeaways:

- **The threat model is a choice.** L∞ balls are the standard image
  benchmark; tabular data usually uses L2 or per-feature bounds; NLP
  usually operates on token substitutions or synonyms and does not
  live in an ε-ball at all (it lives in a discrete set — the *Text
  Attack* survey has the catalogue). Pick the ball that matches the
  actual perturbation an attacker can perform.
- **The attack strength during training determines the robustness
  claim.** Train against PGD-10 with ε = 4/255; do not claim
  robustness at ε = 8/255. Do not claim robustness against attacks
  outside the ball (e.g. patch attacks if you trained under L∞
  pixel-wise).

---

## PGD adversarial training — the minimal recipe

Projected Gradient Descent (Madry et al. 2018) is the standard
approximation of the inner max. For each training batch:

1. Sample `(x, y)`.
2. Initialise `δ_0` — small uniform noise inside the ball (this
   randomised start matters — deterministic starts under-cover the
   ball).
3. For `k = 1..K`:
   ```
   δ_k = Π_S ( δ_{k-1} + α · sign(∇_δ L(f_θ(x + δ_{k-1}), y)) )
   ```
   where `Π_S` is the projection onto the threat-model ball (clip to
   `[-ε, ε]` for L∞).
4. Perform a normal SGD step using the loss at the perturbed
   input `x + δ_K`.

Reference hyperparameters that most PGD-AT papers use for CIFAR-10:

| Hyperparameter | Typical value | Notes |
| --- | --- | --- |
| ε | 8/255 (L∞) or 0.5 (L2) | The threat-model ball radius |
| α (step size) | 2/255 (L∞) | Roughly ε / K · 2.5 |
| K (steps) | 7–20 | Fewer steps → faster + weaker; 7 is Madry's canonical, 10 is common in reproductions |
| Batch size | 128–512 | Adversarial training likes larger batches for gradient noise reduction |
| Base LR schedule | Standard | Warmup + cosine or piecewise decay; adversarial training does not radically change the schedule |
| Total epochs | ≥ 100 | Adversarial training needs more epochs than standard training to converge |

Every value above is a *starting point*. Real production configs
tune them against the target robustness metric.

### PyTorch skeleton

The following skeleton uses `torchattacks` (a widely-used PyTorch
library — verify its current API). It runs on any classification
model. Do not copy it into production without adapting the LR
schedule, data augmentation, and evaluation harness.

```python
import torch
import torch.nn.functional as F
from torchattacks import PGD

def train_pgd_epoch(
    model,
    loader,
    optimizer,
    *,
    epsilon: float,
    alpha: float,
    steps: int,
    device: torch.device,
) -> dict:
    """One epoch of PGD adversarial training.

    epsilon, alpha are in the same units as the input data
    (e.g. [0, 1] pixel space → 8/255 for the standard L∞ threat).
    """
    model.train()
    attack = PGD(model, eps=epsilon, alpha=alpha, steps=steps,
                 random_start=True)  # random start matters

    running_loss = 0.0
    correct_clean = 0
    correct_adv = 0
    seen = 0

    for x, y in loader:
        x, y = x.to(device), y.to(device)

        # Craft the adversarial batch under the current model.
        model.eval()          # BN/Dropout in eval mode during attack
        x_adv = attack(x, y)  # returns x + δ_K projected to the ball
        model.train()         # back to train mode for the update

        optimizer.zero_grad()
        logits_adv = model(x_adv)
        loss = F.cross_entropy(logits_adv, y)
        loss.backward()
        optimizer.step()

        with torch.no_grad():
            running_loss += loss.item() * y.size(0)
            correct_adv += (logits_adv.argmax(1) == y).sum().item()
            correct_clean += (model(x).argmax(1) == y).sum().item()
            seen += y.size(0)

    return {
        "loss": running_loss / seen,
        "acc_clean": correct_clean / seen,
        "acc_adv_train_attack": correct_adv / seen,   # under PGD used
    }
```

Four things to notice:

- **`model.eval()` during the attack** — batch normalisation and
  dropout in `train` mode leak signal and produce distorted
  perturbations. Standard practice is to switch to `eval` for the
  attack construction and back to `train` for the gradient step.
- **Random start.** `random_start=True` samples `δ_0` uniformly in
  the ball. Without it, `δ_0 = 0` is a stationary point of the
  cross-entropy gradient when the model is already confident, and
  the attack fails to move.
- **The reported "adv accuracy" is under the training attack.**
  This is not the number you publish. AutoAttack (below) is.
- **The tradeoff is real.** Expect 10–20 points of clean-accuracy
  loss for a standard L∞ ε = 8/255 CIFAR-10 setup; more if you
  push ε higher or reduce model capacity.

---

## TRADES — trading off clean vs robust accuracy

**TRADES** (Zhang et al. 2019, *Theoretically Principled Trade-off
between Robustness and Accuracy*) is the second workhorse. It
decomposes the loss into a natural-accuracy term and a robustness-
regularisation term:

```
L_TRADES = CE(f_θ(x), y)   +  β · KL( f_θ(x) || f_θ(x + δ*) )
```

- The first term is standard cross-entropy on the clean input.
- The second term is the KL divergence between the model's
  distribution on `x` and on the worst-case perturbation `x + δ*`
  (found by PGD on the KL objective, not on the cross-entropy).
- `β` is the tradeoff dial — higher β → more robustness, lower
  clean accuracy. `β = 6` is the CIFAR-10 default in the original
  paper; production configs frequently tune it lower for a smaller
  clean-accuracy hit.

**When to prefer TRADES over PGD-AT.**

- When you can accept a small robustness drop for a meaningfully
  larger clean-accuracy retention.
- When the deployment has a "clean input" majority and adversarial
  input minority — most production settings.
- When the operations team can tune β as a first-class knob.

**When to prefer PGD-AT.**

- Pure worst-case robustness benchmarks (RobustBench leaderboards).
- When β-tuning would add operational surface you cannot support.

Both are supported by the reference implementations in `torchattacks`,
`Adversarial Robustness Toolbox` (ART, IBM), and `Cleverhans` — but
verify each library's current API and evaluation defaults.

---

## Evaluating robustness — do not shortcut this

The most common failure of adversarial training is a *reported*
robust-accuracy number that does not survive real evaluation. Two
mechanisms:

1. **Gradient masking / obfuscated gradients** (Athalye, Carlini,
   Wagner 2018). The trained model produces uninformative gradients
   (via non-differentiable ops, extreme confidence saturation, or
   stochastic layers), so PGD's gradient-based search fails — but
   gradient-free or transfer attacks succeed. The reported number
   is high because the attack failed, not because the model is
   robust.
2. **Attack under-specification.** Training used PGD-10 at ε=8/255;
   evaluation used PGD-20 at ε=8/255; the AutoAttack ensemble at
   ε=8/255 breaks the claim.

Two operational rules:

### Report AutoAttack, not the training attack

**AutoAttack** (Croce & Hein 2020) is a parameter-free ensemble of
four attacks — APGD-CE, APGD-DLR, FAB, and Square — that has become
the de-facto standard for reporting robust accuracy. Run it against
your trained model at the same ε as the training claim; report the
worst-case accuracy across the four.

```python
# Reference — verify the current AutoAttack API.
from autoattack import AutoAttack

adversary = AutoAttack(model, norm='Linf', eps=8/255, version='standard')
_, robust_acc = adversary.run_standard_evaluation(x_test, y_test, bs=250)
```

`RobustBench` (Croce et al.) hosts a curated leaderboard where every
entry has been evaluated under AutoAttack. Use it as a reality check:
if you are claiming numbers substantially above the current
state-of-the-art at your ε and architecture, you have a gradient-
masking bug.

### Test outside the trained ball

Attack strengths outside the training ε (higher ε, other norms,
patch attacks, semantic perturbations) reveal how the defence
degrades. A model that goes from 50% robust accuracy at ε=8/255 to
2% at ε=16/255 has learned a very sharp boundary — useful
information for the risk assessment even if you never claim
robustness at the higher radius.

---

## The platform integration — what makes this a service

A one-off notebook run is not a platform. The following are the
minimum properties an adversarial-training service exposes:

### 1. First-class config on the standard training job

Team submits the same YAML/Python job type they always submit.
Adversarial training is a section, not a fork:

```yaml
# training_job.yaml — sketch
model: resnet50
dataset: imagenet
optimizer: sgd_momentum
lr_schedule: cosine

adversarial_training:
  enabled: true
  method: pgd            # or "trades"
  threat_model:
    norm: linf
    epsilon: 0.031372549   # 8/255
  attack:
    steps: 10
    alpha: 0.007843137     # 2/255
    random_start: true
  trades:
    beta: 6.0              # only used when method: trades
```

The training platform validates the config, allocates the (larger)
compute budget, and runs the job. The team does not import
torchattacks; the platform does.

### 2. Standard evaluation harness

The platform runs a **standard evaluation ensemble** — AutoAttack
plus one or two auxiliary attacks — as a mandatory post-training
step and writes the results to the model card (mod-104 chapter 05).
Robust accuracy numbers never leave the platform unless AutoAttack
signed them off.

Every model card carries:

- Threat model (norm + ε).
- Clean accuracy on the held-out set.
- Robust accuracy under each attack in the ensemble.
- Reported robust accuracy = min across the ensemble.
- AutoAttack version and library commit hash.

### 3. Compute-cost budget

Adversarial training is 3–10× slower per epoch than standard training
(inner-loop PGD is `K` extra forward+backward passes per batch), and
frequently needs more total epochs to converge. The platform:

- Prices adversarial training at its true cost. A team that opts in
  gets a bigger allocation than a team that does not.
- Caches the perturbations where reuse is safe (rare — perturbations
  are model-state-dependent, so caching is limited to specific
  contexts like semi-supervised or curriculum settings).
- Supports **fast adversarial training** variants — free-AT (Shafahi
  et al. 2019), YOPO (Zhang et al. 2019), fast FGSM with
  cyclic-LR (Wong et al. 2020) — for cost-sensitive workloads,
  with the caveat that each has known gradient-masking failure
  modes and needs re-verification per architecture.

### 4. Explicit failure surface

The platform documents, and the team accepts, that:

- Adversarial training does *nothing* about poisoning, backdoors,
  extraction, or inference (chapter 01, the seam).
- Robustness is *only* claimed inside the trained ball.
- The clean-accuracy cost is real; if the deployment cannot accept
  it, the answer is not to skip adversarial training but to change
  the threat model (smaller ε or different norm) or accept residual
  risk.
- Certified robustness (chapter 03) is a separate track; adversarial
  training gives *empirical* robustness only.

---

## Standard failure modes to watch for

- **Robust overfitting** (Rice et al. 2020). Robust test accuracy
  peaks mid-training and then degrades — the opposite of clean-
  accuracy behaviour. Standard mitigations: early stopping on
  robust validation accuracy; weight-averaging (SWA); data
  augmentation; larger models.
- **Catastrophic overfitting under fast adversarial training**
  (Wong et al. 2020). Cyclic-LR-FGSM training can suddenly collapse
  to zero robust accuracy mid-training. Mitigations: gradient-
  alignment monitoring; checkpoint rollback; use PGD-AT instead if
  reliability matters more than speed.
- **Gradient masking under batch normalisation.** Mixing clean and
  adversarial inputs in the same BN batch corrupts the running
  statistics; a common fix is to compute separate BN statistics
  for clean and adversarial paths.
- **The train / test attack mismatch.** Trained against ε_train,
  evaluated against ε_test > ε_train — reports a "robustness"
  that is entirely outside the claim.
- **Larger models help; smaller models cannot compensate.** In the
  robustness regime, model capacity is a first-order variable
  (Madry et al. 2018 figure 2). Halving the parameter count and
  hoping to keep robustness is not going to work.

---

## Beyond images — where the recipe changes

The literature is heavily image-centric. In production, images are
a minority of ML workloads. The recipe adapts as follows:

- **Tabular data.** L∞ is rarely the right ball; per-feature bounds
  (an attacker can change *at most* certain features by *at most*
  certain amounts) are more realistic. `art.attacks.evasion` has
  tabular-friendly attacks; the same PGD skeleton works, with a
  custom projection to the per-feature bounds.
- **Text / NLP.** No natural ε-ball; adversarial training operates
  on discrete substitutions. See `TextAttack` and Jia et al.'s
  certified NLP work. Adversarial training in NLP is less mature;
  the reference technique is *adversarial data augmentation* rather
  than min-max.
- **Speech / audio.** L∞ over spectrograms or waveforms — feasible,
  but with careful attention to perceptual metrics (a mathematically
  small perturbation can be perceptually large in audio).
- **Graphs.** Attacks on graph structure are combinatorial; robust
  training uses continuous relaxations. See DeepRobust.

Each domain has its own literature and its own defence surface. The
common platform pattern is: expose adversarial training as a
configuration; select the attack module by domain; enforce evaluation
by a domain-appropriate standard ensemble.

---

## The mistakes this chapter is trying to prevent

- **Publishing the training attack's accuracy as the robustness
  number.** The training attack is weakest; a stronger attack
  breaks the claim. AutoAttack is the standard.
- **Confusing robust accuracy inside the ball with robustness in
  general.** Semantic attacks (rotations, colour shifts, patches)
  live outside the ε-ball and are not defended by this training.
- **Treating a fast-AT variant as a drop-in replacement.** Free-AT,
  YOPO, fast-FGSM save compute but each has known failure modes
  and requires re-verification per architecture and dataset. Do
  not migrate silently.
- **Skipping RobustBench sanity checks.** If your reported number
  is above the leaderboard's state-of-the-art at the same threat
  model, you have a bug, not a breakthrough.
- **Reporting "robust" without a norm and ε.** "Robust to
  adversarial examples" is not a claim; "45% robust accuracy under
  AutoAttack at L∞ ε=8/255 on CIFAR-10" is.
- **Confusing adversarial training with poisoning defence.** They
  are different families (chapter 01 seam). Do not check the
  poisoning box because you enabled PGD.
- **Failing to price it.** Adversarial training is expensive. If
  it is not in the training-cost budget, it will be silently
  dropped at re-training time.

---

## Summary

- Adversarial training solves the inference-time evasion problem
  by min-max training: minimise loss on the worst-case perturbed
  input within a threat-model ball.
- PGD (Madry et al. 2018) is the standard inner-max approximation;
  TRADES (Zhang et al. 2019) is the standard clean/robust tradeoff
  variant.
- Robust accuracy is reported under **AutoAttack** (Croce & Hein
  2020) or the current SOTA ensemble — never only under the
  training attack. RobustBench is the reality check.
- The platform integration matters: first-class config, standard
  evaluation harness, honest compute budget, and an explicit
  failure surface that names what this defence does *not* cover.
- Failure modes to watch — robust overfitting, gradient masking,
  catastrophic overfitting under fast-AT, BN statistics
  contamination — are known and have known mitigations.
- Adversarial training does **not** address poisoning, backdoors,
  extraction, or inference. That seam (chapter 01) is
  load-bearing.
