# Exercise 01 — Adversarial Robustness Assessment

**Estimated time**: 3 hours
**Deliverable**: A 2–3 page report with measured numbers

---

## The assignment

Empirically measure the adversarial robustness of a model. Use
the Adversarial Robustness Toolbox (ART) to run a battery of
attacks and produce a report.

## Setup

1. Train (or download) a small classifier. CIFAR-10 with a
   small CNN is the standard choice. MNIST is faster.
2. Install ART:
   ```
   pip install adversarial-robustness-toolbox
   ```

## What the assessment must measure

For your chosen model, measure and report:

1. **Clean accuracy** on the test set.
2. **Robust accuracy** under each attack:
   - FGSM at ε = 8/255 (L∞).
   - PGD at ε = 8/255, 20 steps, α = 2/255.
   - C&W (small subset of test set due to compute cost).
   - AutoAttack (if you have the compute; otherwise note the
     gap).
3. **Confidence calibration**: how does the model's confidence
   on adversarial inputs differ from clean inputs?
4. **Transferability**: train a second model (different
   architecture or random init), use its adversarial examples
   to attack the first. Report the transfer accuracy.

## The report

```
# Adversarial Robustness Assessment

## Model under test
- Architecture
- Dataset
- Training procedure (epochs, optimizer, hyperparameters)
- Clean test accuracy

## Attack results

| Attack | Parameters | Robust accuracy | Notes |
|---|---|---|---|
| FGSM | ε = 8/255 | XX% | ... |
| PGD-20 | ε = 8/255, α = 2/255 | XX% | ... |
| C&W | ε = 8/255 | XX% (on 1000-image subset) | ... |
| AutoAttack | ε = 8/255 | XX% | ... |

## Confidence on adversarial inputs vs clean
(Histogram or summary stats.)

## Transferability
- Surrogate model architecture
- Transfer accuracy at ε = 8/255

## Interpretation
- Which attack is strongest?
- What does the gap between robust accuracy and clean accuracy
  imply for a production deployment?
- What's the realistic worst-case for a determined attacker?

## What this assessment does NOT measure
- Adaptive attacks (attacks designed knowing the defense).
- Black-box query-based attacks against rate-limited APIs.
- Domain-specific perturbations (patch attacks, semantic
  attacks).
```

## Quality criteria

A passing assessment:

- **Reports actual measured numbers** (or honestly states
  "didn't run for compute reasons" if applicable).
- Calibrates the interpretation — doesn't claim "the model is
  robust" or "the model is broken" without qualification.
- Identifies the strongest attack and reports that as the
  bottom line.
- Acknowledges what the assessment doesn't cover.

A failing assessment:

- Reports only clean accuracy.
- Claims robustness based on a single weak attack (FGSM only).
- Uses ε = 0.1/255 to inflate the apparent robustness.

## Reflection questions

1. Which attack was most expensive to run? How does that
   translate to "what an attacker can afford"?
2. The transferability number is often higher than people
   expect. What's the operational implication for "we don't
   reveal the model architecture"?
3. Suppose this model goes to production at 50% robust accuracy
   at ε = 8/255. Is that acceptable? On what does the answer
   depend?

## If you can't run code

Read [the AutoAttack paper](https://arxiv.org/abs/2003.01690)
and the [RobustBench leaderboard](https://robustbench.github.io/).
Pick three published models and write the same report for them,
using their published numbers. The reasoning is the deliverable.
