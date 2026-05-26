# Module 06 Exercises

Five exercises. Several involve **actually running code** (PGD,
DP-SGD, ART) — this module benefits from hands-on more than the
others.

| # | Exercise | Output | Time |
|---|---|---|---|
| 1 | [Adversarial robustness assessment](./exercise-01-robustness-assessment.md) | Empirical robustness report on a model | 3 h |
| 2 | [Defense plan with trade-offs](./exercise-02-defense-plan.md) | Defense choice document with quantified trade-offs | 2 h |
| 3 | [Poisoning detection design](./exercise-03-poisoning-detection.md) | Detection plan for a retraining pipeline | 2 h |
| 4 | [DP-SGD configuration](./exercise-04-dp-sgd-configuration.md) | Concrete DP-SGD config + utility-cost analysis | 2–3 h |
| 5 | [LLM safety pipeline](./exercise-05-llm-safety-pipeline.md) | Multi-layer defense design for prompt injection / jailbreak | 2 h |

## Working notes

- Exercises 1 and 4 are hands-on; allocate compute (a CPU is
  fine for the small models used).
- Exercise 2 builds on Exercise 1's measurements.
- Exercises 3 and 5 are design-focused, no code required.
- Exercise 5 introduces the LLM scenario; reuses the
  customer-support LLM from the quiz Q15.

## Compute notes

You'll need:
- PyTorch or TensorFlow.
- ART installed (`pip install adversarial-robustness-toolbox`).
- Opacus installed (`pip install opacus`).
- A small classification dataset (MNIST, CIFAR-10) or a small
  internal dataset.
- A few GPU minutes per run (or CPU minutes if you're patient).

If you don't have access to compute, do the exercises as
written-only design exercises — the *reasoning* is the
deliverable.
