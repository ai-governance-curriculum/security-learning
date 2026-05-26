# Exercise 04 — DP-SGD Configuration

**Estimated time**: 2–3 hours
**Deliverable**: A configuration document + experimental results (if running code) or a defended config (if not)

---

## The scenario

A new SmartRecs customer wants a regulated workload: a model
trained on customer records that include **patient-derived
features** (the customer is a healthcare network).

Requirements:

- The trained model must be defensible against membership
  inference for the regulated training data.
- The customer requires a **formal (ε, δ)-DP guarantee** —
  contractually committed.
- The utility cost must be quantified and tolerable.
- The training process must be auditable.

## The assignment

Produce a DP-SGD configuration for this training run.

### Required deliverables

1. **Target privacy budget** (ε, δ). Defend the choice against
   the customer's regulatory team and your own engineering
   constraints.
2. **DP-SGD hyperparameters**:
   - Per-sample gradient clipping bound `C`.
   - Noise multiplier `σ`.
   - Sample rate (batch size / dataset size).
   - Number of training steps.
3. **Privacy accountant** approach (RDP / Moments / GDP).
4. **Expected utility cost** — how much accuracy you expect to
   lose vs. non-private training.
5. **Audit trail** — how you record the (ε, δ) consumed across
   training runs, and where this lives in the audit chain
   (Module 03 §8).
6. **Hyperparameter tuning approach** that does not consume
   excessive privacy budget (a subtle issue — every hyperparameter
   trial leaks information).

## Constraints

- Dataset size: ~500k records.
- Model: a small neural net (a few million parameters).
- Customer's negotiated target: ε ≤ 8, δ ≤ 1/(n²).
- You have access to Opacus (PyTorch) or TensorFlow Privacy.

## If you're running the code

1. Train a baseline non-private model. Record clean accuracy.
2. Train the DP-SGD model with your proposed config. Record
   accuracy + accountant's reported (ε, δ).
3. Show the utility gap.
4. Try one variation (e.g., different `C`) and show its effect.

## If you're not running the code

Make defensible choices for the hyperparameters. Cite the
literature for typical ranges. Note where reality might
diverge from theory.

## Format

```
# DP-SGD Configuration: Healthcare Customer Model

## Customer requirement
(Stated requirements, regulatory context.)

## Privacy budget decision
- Target (ε, δ).
- Why this value (literature ranges, customer expectation,
  regulatory baseline).
- What ε = 8 actually means for this dataset (interpret it
  qualitatively).

## DP-SGD configuration

| Parameter | Value | Rationale |
|---|---|---|
| Gradient clip `C` | 1.0 | Standard starting point per Opacus |
| Noise multiplier `σ` | 1.1 | Computed to reach target ε |
| Batch size | 256 | ... |
| Epochs | 30 | ... |
| Sample rate | 0.5e-3 | Batch/dataset |
| Learning rate | 1e-3 | ... |

## Privacy accountant
(RDP / Moments / GDP — choose one, justify.)

## Expected utility cost
- Baseline (no DP) accuracy: X%
- DP-SGD accuracy estimate: Y%
- Gap: Z percentage points

## Hyperparameter tuning approach
(How to tune without leaking privacy budget — e.g., use a
smaller held-out non-private subset for tuning, validate final
choice with one private run.)

## Audit trail
- (ε, δ) consumed per epoch logged to audit chain
- Final certificate stored with model artifact
- Re-training depletes the budget; document the
  re-allocation policy

## What this configuration doesn't promise
- Robustness to non-membership-inference attacks (need other
  defenses).
- That ε = 8 satisfies all regulators (verify with the
  customer's compliance team).
```

## Quality criteria

A passing config:

- Justifies (ε, δ) with reasoning, not just by citing a value.
- Hyperparameters are plausible — `C`, `σ` are in reasonable
  ranges from the literature.
- Accounts for hyperparameter tuning's privacy cost.
- Audit trail is real — links to Module 03's hash chain.
- Acknowledges what DP-SGD doesn't promise.

A failing config:

- ε = 1 without considering utility implications.
- Magic numbers with no justification.
- No accountant choice.
- No audit-trail consideration.

## Reflection questions

1. Why is hyperparameter tuning subtle in DP? What's the
   typical workaround?
2. If the customer asks "can you re-train next year on more
   data while keeping the same ε guarantee?", what's the
   answer? What does each retraining cost in privacy budget?
3. The customer's CISO asks: "If a determined attacker spends
   $1M, can they extract a single patient's record from the
   model?" Answer honestly.
