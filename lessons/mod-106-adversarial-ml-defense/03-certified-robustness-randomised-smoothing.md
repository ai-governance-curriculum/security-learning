# Chapter 03 — Certified Robustness with Randomised Smoothing

> **Note on AI-assisted content.** These lecture chapters were drafted
> with AI assistance and are under human review. Verify every
> library API (`torch`, `torchvision`, the smoothing reference
> implementations) and every published number against the primary
> source before quoting externally. See [`resources.md`](./resources.md).

---

## Why this chapter exists

Chapter 02 delivered **empirical** robustness — adversarial training
resists the best attacks the evaluator can throw at it, but the claim
is only as strong as the attacker's imagination and compute. For
regulated deployments — safety-critical vision, medical imaging,
insurance-underwriting classifiers, evidentiary evidence — "the best
attack we ran did not succeed" is not always enough. Sometimes the
paperwork requires a **mathematical guarantee**: *for this input,
no perturbation with L2 norm below r can change the prediction*.

The specific failure mode this chapter is written to prevent:

> A team ships an adversarially-trained image classifier for a
> medical-device workflow. The regulator reviewer asks: "for a
> minimally-perturbed X-ray, what is your guarantee that the model
> still produces the correct label?" The team answers: "we ran
> AutoAttack at ε=8/255 and got 55% robust accuracy." The reviewer
> asks the question again — the empirical number does not answer the
> "no perturbation ever" question the certification needs. Six weeks
> of re-engineering follow to produce a certified defence the
> regulator will actually accept.

**Certified defences** produce that per-input guarantee. The
production-mature technique is **randomised smoothing** (Cohen,
Rosenfeld, Kolter 2019 — *Certified Adversarial Robustness via
Randomized Smoothing*), which converts *any* base classifier into a
smoothed classifier that comes with a rigorous L2-radius certificate
per input. The tradeoffs — Gaussian noise at inference, Monte Carlo
prediction cost, radius capped by the noise variance — are what this
chapter helps you weigh.

You leave this chapter able to:

- Distinguish **empirical** from **certified** robustness and know
  which one a specific requirement demands.
- Sketch the smoothing construction: noise distribution, base
  classifier, smoothed classifier, and the certificate radius.
- Wire randomised smoothing into a training + serving pipeline
  (noise-augmented training, `Predict`, `Certify`, abstention).
- Report certified accuracy correctly — as an accuracy-vs-radius
  curve, not a single number.
- Know the alternatives (interval-bound propagation, CROWN, MIP-based
  verification, Lipschitz-bounded networks) and when smoothing is
  the wrong choice.
- Cost a smoothing deployment and negotiate the noise-vs-radius knob
  with the model team.

---

## Empirical vs certified robustness — the vocabulary that matters

Two robustness concepts share the word "robust" and are routinely
confused. Keep them separate.

| | Empirical robustness | Certified robustness |
| --- | --- | --- |
| **Claim** | *No known attack under a budget succeeds* | *No perturbation inside the certified region can change the prediction* |
| **Evidence** | Ran AutoAttack at ε; measured robust accuracy | Radius `r` returned per input; probability guarantee `≥ 1 − α` |
| **Failure mode** | A stronger / cheaper attack breaks the claim | The certificate is mathematically correct within its stated probability |
| **Cost** | 3–10× training | 100–1000× inference (Monte Carlo sampling) |
| **Typical technique** | PGD-AT, TRADES (chapter 02) | Randomised smoothing, IBP, Lipschitz networks |
| **Use when** | You need broad defence and can accept "no attack we tried" | A specific input needs a paper-defensible guarantee |

Neither displaces the other. Adversarial training gives you a
generally-hardened model; certification gives you a per-input
guarantee at inference cost. Regulated deployments frequently need
both, in that order — an adversarially-trained base classifier
smoothed at serving time.

---

## The smoothing construction — Cohen et al. 2019

The construction is small and worth memorising.

Given any base classifier `f: R^d → Y` (produces a class label), the
**smoothed classifier** `g` is defined as:

```
g(x) = argmax_{c ∈ Y}  Pr_{ε ~ N(0, σ² I)} [ f(x + ε) = c ]
```

That is: "at input `x`, the smoothed classifier returns whichever
class the base classifier `f` most often assigns to Gaussian-noised
versions of `x`." The noise is isotropic Gaussian with standard
deviation `σ`.

The **certificate theorem** (Cohen et al. 2019, Theorem 1) says:

> If, at input `x`, class `c_A` has probability at least `p_A` under
> `f`'s response to `N(x, σ² I)`, and the runner-up class `c_B` has
> probability at most `p_B`, then `g(x + δ) = c_A` for every
> perturbation `δ` with:
>
> ```
> ||δ||_2  ≤  (σ / 2) · [ Φ⁻¹(p_A)  −  Φ⁻¹(p_B) ]
> ```
>
> where `Φ⁻¹` is the inverse standard-normal CDF.

Three consequences that shape every practical decision:

1. **The radius scales linearly with `σ`.** More noise → larger
   certified region → worse base-classifier accuracy on noised
   inputs. `σ = 0.25` and `σ = 0.5` are the canonical L2 evaluation
   points; `σ = 1.0` gets very large radii on toy datasets and near-
   random accuracy on real ones.
2. **The radius depends on `p_A − p_B`.** A confident smoothed
   prediction certifies far; a marginal one certifies nothing.
   The certificate is per-input; two images with the same `σ` will
   get different radii.
3. **`Φ⁻¹(1) = ∞` is unattainable.** You cannot observe `p_A = 1`
   from a finite sample; the practical certificate uses a **lower
   confidence bound** on `p_A` and an upper bound on `p_B`
   (Clopper-Pearson intervals), with a user-chosen failure probability
   `α` (typically 0.001).

The certificate is **probabilistic**: with probability at least
`1 − α`, the certified radius returned is a valid lower bound on the
true certified radius. It is not a "hard" mathematical guarantee in
the interval-analysis sense; it is a rigorous statistical guarantee.

---

## The three routines — Train, Predict, Certify

A production randomised-smoothing pipeline exposes three routines.
Keep the names — the Cohen et al. reference implementation uses them
and downstream literature refers to them by these names.

### Train — noise-augmented training

The base classifier `f` must be trained on **noised** inputs, not
clean ones. Otherwise `f`'s accuracy on `x + ε` collapses and the
certificate radius shrinks to zero. The recipe:

- Draw fresh Gaussian noise `ε ~ N(0, σ² I)` for every sample every
  epoch (not a fixed noised copy of the dataset).
- Train `f` with standard supervised loss on `(x + ε, y)`.
- Use the same `σ` at training and at certification.

If you plan to serve at multiple radii, train **separate base
classifiers** for each `σ` value (per-`σ` models are strictly better
than one model for all `σ` — this is the standard practice).

Adversarially-trained smoothing (Salman et al. 2019 —
*Provably Robust Deep Learning via Adversarially Trained Smoothed
Classifiers*) trains the base classifier under PGD *of the smoothed
classifier*, which lifts certified accuracy substantially on CIFAR /
ImageNet at extra training cost. It is the state of the art when the
training budget can accept ~10× the noise-augmented cost.

### Predict — noisy Monte Carlo prediction

At inference, you don't have access to the exact expectation in the
smoothed classifier's definition. You approximate it by sampling.

```
def predict(f, x, n, sigma, alpha):
    # Sample n noisy copies and count votes.
    counts = zeros(num_classes)
    for _ in range(n):
        eps = normal(0, sigma, shape=x.shape)
        counts[f(x + eps)] += 1

    top1, top2 = two_largest(counts)
    # Binomial test: is top1 significantly bigger than top2?
    if binom_test(top1, top1 + top2, p=0.5) <= alpha:
        return argmax(counts)
    else:
        return ABSTAIN
```

Two knobs:

- **`n` — number of samples.** Cohen et al. use `n = 100` for
  `Predict` and `n = 100_000` for `Certify` on CIFAR-10.
- **`alpha` — abstention threshold.** With probability at least
  `1 − alpha`, the returned label matches the smoothed classifier's
  argmax.

`Predict` returns either a label *or* `ABSTAIN`. The serving layer
has to handle the abstention: fall back to a lower-tier model, defer
to a human reviewer, or return a "no confident answer" response. If
your product surface cannot handle abstention, smoothing is the wrong
choice.

### Certify — the per-input radius

`Certify` is the routine that produces the radius number the
regulator asks for. It is more expensive than `Predict` because it
needs a tight lower bound on `p_A`.

```
def certify(f, x, n0, n, sigma, alpha):
    # Small sample to pick the top class.
    counts_selection = sample_noise_counts(f, x, n0, sigma)
    c_hat = argmax(counts_selection)

    # Large sample to estimate p_A.
    counts_estimation = sample_noise_counts(f, x, n, sigma)
    p_A_lower = clopper_pearson_lower(counts_estimation[c_hat], n, alpha)

    if p_A_lower < 0.5:
        return ABSTAIN, 0.0

    radius = sigma * norminv(p_A_lower)   # tighter than the general form
    return c_hat, radius
```

The tightened radius formula `σ · Φ⁻¹(p_A_lower)` is Cohen et al.'s
"two-sided" special case where the runner-up bound is `p_B = 1 − p_A`;
it is the form the reference implementation uses.

`n = 100_000` at `α = 0.001` is the standard evaluation configuration.
At real serving time, this is 100_000 forward passes per input — see
the cost section below.

---

## Reporting certified robustness

There is no single "certified accuracy" number. The correct artefact
is a **certified-accuracy-vs-radius** curve.

Compute, on a held-out test set:

- For each test point, run `Certify` to get `(prediction, radius)`.
- For a grid of radii `r ∈ {0.0, 0.25, 0.5, 0.75, ...}`, compute:
  ```
  certified_accuracy(r) =
      (# points with prediction == label AND radius ≥ r)  /  N
  ```
- Plot certified accuracy on the y-axis, radius on the x-axis.

A published claim looks like:

> Our smoothed classifier on CIFAR-10 with `σ = 0.25` attains
> **certified accuracy of 60% at L2 radius 0.25**, **43% at 0.5**,
> and **0% at radii ≥ 1.0** (Cohen et al. protocol,
> `n = 100_000`, `α = 0.001`).

Three rules operationalise this:

1. **Cite `σ`, `n`, `α`, and the protocol.** Numbers without them are
   incomparable. The Cohen et al. protocol is the community default;
   deviations should be called out.
2. **Do not confuse smoothed-classifier accuracy with base-classifier
   accuracy.** The smoothed classifier's clean accuracy is measured
   on non-perturbed inputs but with Monte Carlo noise at inference —
   both numbers matter and both go on the model card (chapter 04 of
   mod-104).
3. **The curve *decreases*.** A "flat" certified curve is suspicious
   and usually means the abstention rate is high or the noise level
   is far above the base classifier's tolerance.

---

## Wiring it into a training + serving pipeline

The platform surface is different from the adversarial-training
surface of chapter 02 because certification lives at inference.

### Training-time knobs

The training platform exposes smoothing as a training-job flag with
`σ`, batch-size, and whether to use adversarial smoothing (Salman et
al.). The training-job config:

```yaml
# training_job.yaml — sketch
model: resnet50
dataset: cifar10
optimizer: sgd_momentum

smoothing:
  enabled: true
  sigma: 0.25              # L2 noise standard deviation
  adversarial_smoothing:   # Salman et al. — costs more, certifies further
    enabled: false
    attack:
      norm: l2
      epsilon: 0.5
      steps: 10
```

The trained artefact is a *base classifier `f`*. The model card
records `σ`; the serving stack refuses to certify at a different `σ`.

### Serving-time surface

The smoothed classifier is *not* a drop-in replacement for a normal
classifier. The serving stack needs three modes:

- `Predict` — cheap noisy voting for real-time traffic.
- `Certify` — expensive per-input certification for cases that
  request or require the radius.
- `Abstain` — a legitimate response the caller must handle.

A `serving_config.yaml` sketch:

```yaml
serving:
  smoothing:
    sigma: 0.25
    predict:
      n: 100
      alpha: 0.001
    certify:
      n0: 100
      n: 10000          # smaller than the paper's 100_000 for latency
      alpha: 0.001
    abstain_handler:
      type: fallback_to_baseline_model
      baseline: fraud-baseline-v3
```

The serving stack:

- Batches noise samples across the request to amortise GPU cost — a
  request-level batch of `n = 100` runs as one big forward pass, not
  100 separate ones.
- Records the returned radius (when `Certify` was called) and the
  abstention outcome as structured telemetry — the ops team needs to
  see the abstention rate as an alertable metric.
- Exposes the noise seed for reproducibility on flagged cases.

### Model card additions

Per model card (mod-104 chapter 05), a smoothed classifier reports:

- Base classifier architecture and training recipe.
- `σ` at training and at serving.
- Certified accuracy curve on the held-out set (image + CSV).
- `Predict` and `Certify` sampling configuration (`n`, `α`).
- Abstention rate on the held-out set at the deployed `n`, `α`.
- Latency and cost per `Certify` call at the target hardware.

Downstream compliance (mod-109) consumes these directly.

---

## The costs — and when smoothing is the wrong choice

Randomised smoothing is honest about its costs. The tradeoffs to
walk through with the model team:

- **Inference latency multiplies by `n`.** Even at `n = 100`, a
  single prediction is 100 forward passes. `Certify` at `n = 10_000`
  is 10_000 forward passes. Batching helps but does not eliminate
  the ×100–×10_000 cost multiplier.
- **The certified region is L2 only.** Cohen et al.'s certificate
  is L2. There are L∞ extensions (typically via Lipschitz bounds or
  ε rescaling) but they trade badly. If your threat model is L∞ (the
  standard image benchmark), smoothing gives you an L2 certificate
  that maps to a small L∞ region.
- **The base classifier has to tolerate the noise.** If you cannot
  retrain — because the model is imported from a partner, or the
  training data is deleted — you cannot smooth. Smoothing at serving
  time on a non-noise-trained base gives a smoothed classifier with
  useless accuracy.
- **The certificate is per-input.** The regulator asks about *this*
  X-ray. If the certificate for a specific input is `radius = 0.02`
  and you need `0.1`, you cannot argue around it — the certificate
  is what it is.
- **Abstention has to be operationally acceptable.** If the product
  cannot say "I don't know", the noise-and-vote scheme is a bad fit.

If any of these is a deal-breaker, evaluate alternatives:

- **Interval-bound propagation (IBP)** — Gowal et al. 2019, and
  descendants (CROWN, α-CROWN, β-CROWN). Trains for tight IBP bounds
  and returns exact interval certificates. Better for small L∞
  radii; harder to scale to large models than smoothing.
- **Lipschitz-bounded networks** — architectures with globally
  bounded Lipschitz constant (e.g. LMT, SLL, Almost-Orthogonal
  layers). Give exact Lipschitz-based certificates but restrict the
  architecture space.
- **MIP / SMT-based verification** — exact, but expensive; feasible
  for small models and small radii; used for safety-critical control
  applications more than for image classification.

Chapter 04 of mod-108 (privacy engineering) covers a *different*
certification track — differential privacy — that also shows up on
the same model card. Do not conflate DP's `(ε, δ)` with smoothing's
radius `r`; they answer different questions.

---

## Standard failure modes to watch for

- **Training on clean, serving with noise.** Base classifier never
  sees Gaussian noise → smoothed accuracy is near random →
  certificate is meaningless. The most common bug.
- **`σ` mismatch between training and serving.** The certificate is
  a function of the *serving* `σ`; if the trained noise is different,
  the base classifier's accuracy on serving noise is degraded and
  the abstention rate blows up.
- **Under-sampling `Certify`.** Small `n` gives a wide Clopper-Pearson
  interval → small radius. Do not compare radii computed at different
  `n`.
- **Reporting the smoothed classifier's clean accuracy as certified
  accuracy.** They are different metrics on different plots. A model
  card that shows only one is under-specified.
- **Silent abstentions.** If `Predict` returns `ABSTAIN` and the
  serving layer converts it to a default label, the abstention is
  hidden from telemetry and the observed accuracy is artificially
  boosted. Log every abstention.
- **Applying smoothing to attack shapes it does not defend.** The
  Cohen et al. certificate is L2 additive noise. Rotations, colour
  shifts, occlusions, and adversarial patches are outside the
  certified region.
- **Skipping the "is smoothing right?" conversation.** Randomised
  smoothing is a *large* commitment — training-recipe change,
  serving-latency multiplier, product-surface abstention. When the
  requirement is "we need robustness", empirical robustness (chapter
  02) is usually the answer. Certification is for the specific
  regulatory or contractual asks that empirical numbers cannot
  satisfy.

---

## The mistakes this chapter is trying to prevent

- **Marketing empirical robustness as certified.** A robust-accuracy
  number under AutoAttack is empirical. A radius-per-input from
  smoothing is certified. Do not blur the distinction in a design
  doc — auditors and regulators do not.
- **Deploying smoothing without an abstention path.** The `ABSTAIN`
  return value is load-bearing; a product surface that ignores it
  produces silent failure.
- **Publishing certified accuracy without the radius.** "60% certified"
  is not a claim. "60% at L2 radius 0.25 with `n = 100_000`, `σ = 0.25`"
  is.
- **Claiming L∞ certification from an L2 smoothing scheme.** The
  Cohen et al. certificate is L2. There are L∞ variants (and specific
  smoothing distributions that give L1 or L∞ certificates) but they
  are separate constructions and require separate training.
- **Skipping the Salman et al. adversarial-smoothing option** on a
  regulated deployment where the extra training cost is affordable
  and every point of certified accuracy matters.
- **Ignoring the base-classifier / smoothed-classifier distinction
  on the model card.** They are two artefacts with two accuracy
  profiles and two failure modes; the card documents both.

---

## Summary

- Certified robustness gives you a per-input mathematical guarantee
  (with a stated failure probability). Empirical robustness does
  not.
- Randomised smoothing (Cohen et al. 2019) is the production-mature
  certified defence: noise the input, vote across noised copies,
  return a radius that scales with `σ` and the top-class probability.
- The pipeline exposes three routines — `Train` (noise-augmented,
  same `σ` as serving), `Predict` (cheap Monte Carlo with
  abstention), `Certify` (expensive per-input radius) — and the
  serving stack must handle abstention as a first-class outcome.
- Report certified accuracy as an accuracy-vs-radius curve at a
  named `σ`, `n`, `α`, and protocol. Never as a single number
  without them.
- The costs — ×100 to ×10 000 inference latency, L2-only certificate,
  no post-hoc smoothing of a non-noise-trained base — are real.
  Alternatives (IBP, Lipschitz, MIP) exist for cases where
  smoothing is a bad fit.
- Smoothing is a large commitment. Enable it when a specific
  regulatory or contractual requirement demands a per-input
  certificate; for general defence, chapter 02's empirical training
  remains the right primary control.
