# Exercise 03 — Poisoning Detection Design

**Estimated time**: 2 hours
**Deliverable**: A 2-page design + an alerting rule set

---

## The system

SmartRecs operates a continuously-retrained recommender:

- Customer events stream into Kafka.
- Hourly aggregation produces a feature-engineering job.
- Daily retraining runs on the past 60 days of features +
  labels.
- The retrained model goes through validation gates (overall
  accuracy ≥ baseline - 0.5%) before promotion.
- Promoted models replace production within 4 hours of
  retraining.

## The threat

An attacker who can submit events to the production system can
*influence the training data*. The attacker's goal: install a
preference for their items (boost their visibility in
recommendations) without triggering the accuracy threshold.

This is a realistic threat: it doesn't require model access, it
doesn't require breaking authentication, and the attack lives in
the noise of legitimate production traffic.

## The assignment

Design a detection plan that catches this attack. The plan must
specify:

1. **Per-input-tier signals** to detect anomalous events
   *before* they enter training.
2. **Per-batch signals** to detect poisoning *during* feature
   aggregation.
3. **Per-model-version signals** to detect poisoning *in* the
   trained model.
4. **Per-prediction signals** to detect poisoning *in
   production behavior*.

For each, name:
- The signal computed.
- Where in the pipeline it's computed.
- The alert threshold (with calibration approach).
- The triage path (what to do when it fires).
- The expected false-positive rate.
- What an adaptive attacker would do to evade.

## Required techniques

The plan must include or address each of these (with concrete
deployment in the pipeline):

- **Per-user feedback rate limits** (bound any individual's
  influence).
- **Statistical outlier detection** on training-data features.
- **Activation clustering** on trained-model activations.
- **Per-class accuracy monitoring** (not just overall accuracy).
- **Per-item exposure monitoring** (a sudden "this product is
  recommended 10× more" is a signal).
- **Holdout validation** with curated test queries.

## Format

```
# Poisoning Detection Design: SmartRecs Recommender

## Threat model
(Attacker who can submit events, target: boost specific items.)

## Pipeline diagram
(Sketch where each signal lives.)

## Per-input signals
### Signal 1: <name>
- Computed where
- Threshold
- Triage
- FPR
- Adaptive-attacker evasion
### Signal 2: ...

## Per-batch signals
...

## Per-model-version signals
...

## Per-prediction signals
...

## Holdout validation queries

## Alerting + runbook
(When poisoning is suspected, what's the on-call procedure?)

## What this detection doesn't catch
```

## Quality criteria

A passing design:

- Covers all 4 layers (input / batch / model / production).
- Each signal has a **specific computation**, not "monitor
  anomalies."
- Acknowledges **adaptive attackers** — what an attacker who
  knows about the detection would do.
- Holdout validation queries exist and are described.

A failing design:

- Only one layer (e.g., only post-training detection).
- Generic "anomaly detection" without specifying the signal.
- No mention of adaptive evasion.
- No triage path — alerts without actions.

## Reflection questions

1. Which layer is most likely to have a high false-positive
   rate? What's the alert-fatigue mitigation?
2. Which layer would an adaptive attacker target first to evade?
3. The lecture notes argue that **provenance-based defense**
   (Module 10) is the strongest protection. Where in the
   pipeline would provenance hooks fit, and what would change
   in your detection design if you had them?
