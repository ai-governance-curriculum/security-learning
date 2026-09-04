# Chapter 04 — Poisoning and Backdoor Detection

> **Note on AI-assisted content.** Detection library APIs (ART's
> `PoisonFilteringDefence`, activation-clustering, spectral-signature
> modules) move between releases. Verify the current interface
> before quoting or copying. See [`resources.md`](./resources.md).

---

## Why this chapter exists

Chapter 01 named **poisoning** and **backdoors** as the training-time
integrity attacks. Chapters 02 and 03 hardened the model against
inference-time perturbation and gave nothing back to the poisoning
problem — because they cannot; the wrong data was in the training
set before the loss was ever computed.

The specific failure modes this chapter is written to prevent:

> A recommender team ingests user feedback nightly for continual
> retraining. A coordinated group registers ten thousand accounts
> and thumbs-up a competitor's product for two weeks. The model
> starts recommending the competitor in the top slot. The team
> discovers the shift through revenue drops, not through any
> integrity signal from the training pipeline.
>
> A vision team fine-tunes a pretrained backbone downloaded from a
> public hub. On the standard evaluation set the model reports 91%
> accuracy. In production, inputs containing a specific 3×3 pixel
> pattern in the top-right corner are classified as the attacker's
> chosen label — every time. The backdoor sat in the base weights
> and no fine-tuning check would have found it.

Poisoning and backdoors share the training-time seam but split on
detection surface: **poisoning** distorts the aggregate training
distribution, so aggregate defences (spectral signature, activation
clustering, canaries) apply; **backdoors** hide inside a
statistically-normal training set as a small correctly-labelled
trigger, so trigger-search defences (Neural Cleanse, STRIP) are
what work.

You leave this chapter able to:

- Choose an appropriate defence for a given poisoning shape
  (availability / targeted / clean-label / backdoor).
- Configure **spectral-signature detection** (Tran, Li, Madry 2018)
  and **activation clustering** (Chen et al. 2018) on a training
  pipeline and interpret their outputs.
- Run **Neural Cleanse** (Wang et al. 2019) and **STRIP** (Gao et
  al. 2019) as backdoor detectors, and know the failure modes of
  each.
- Wire **canary samples** into a continual-learning pipeline so
  distribution drift and targeted poisoning surface as pipeline
  alerts, not as revenue anomalies.
- Compose these controls with the provenance guarantees from
  mod-104 (signed datasets, in-toto attestations) and the supply-
  chain gates from mod-110 (base-model scanning).

---

## The families in one diagram

The chapter treats four attack shapes. They are not disjoint — a
backdoor is a special case of targeted poisoning — but the detection
surface differs enough to be worth naming.

| Shape | Attacker's goal | Poisoned-sample count needed | Poisoned label pattern | Best-fit detector |
| --- | --- | --- | --- | --- |
| Availability poisoning | Degrade overall accuracy | Many (5–20% of the set) | Random / flipped | Data QC + statistical outlier scans |
| Targeted poisoning | Cause misclassification on a specific input | Few (dozens) | Label-flipped or clean-label | Spectral signature, activation clustering |
| Clean-label poisoning | Same as targeted, but with correct labels | Very few (dozens–hundreds) | Correct — the input has been feature-shifted | Spectral signature, activation clustering |
| Backdoor / trojan | Any input with trigger → attacker label | Few (dozens–hundreds) | Correct (attacker label) with trigger | Neural Cleanse, STRIP, fine-pruning, provenance |

The seam that shapes the detector choice:

- **Availability poisoning changes overall model accuracy.**
  Standard eval-set accuracy dips notice it. Simple statistical
  filters (per-class outlier scores) catch it.
- **Targeted and clean-label poisoning do *not* move overall
  accuracy.** You need feature-space defences that see the poisoned
  samples' peculiar signature.
- **Backdoors also do not move overall accuracy on any input that
  lacks the trigger.** You need trigger-search or trigger-response
  defences.

---

## Spectral-signature detection

Tran, Li, Madry 2018 (*Spectral Signatures in Backdoor Attacks*)
made a key observation: on the last representation layer of a
neural network, **poisoned examples from the same target class
form a spectrally distinct sub-population**. Concretely, if you
project each class's representations onto the top singular vector
of that class's centred representation matrix, the poisoned
examples land far out in the tails of the distribution.

The recipe:

1. Train (or partially train — a mid-training checkpoint works)
   the model on the suspect training set.
2. For each class `c`:
   a. Collect the representations `R_c` (last-layer features) of
      all training examples labelled `c`.
   b. Centre: `R_c ← R_c − mean(R_c)`.
   c. Compute the top singular vector `v_c` of `R_c` (SVD or power
      iteration).
   d. For each example `x` in class `c`, compute the **spectral
      score** `s(x) = (r_x · v_c)^2`.
3. Discard the top-`k`% of examples by spectral score within each
   class (default: 15% at the fraction of expected poison, or 1.5×
   the expected poison rate).
4. Retrain on the filtered set.

### PyTorch skeleton

```python
import torch
import numpy as np

def spectral_scores(features: torch.Tensor) -> torch.Tensor:
    """Per-example spectral score inside a single class."""
    r = features - features.mean(dim=0, keepdim=True)     # centre
    # Power iteration on r.T @ r / N for the top singular vector.
    _, _, v = torch.pca_lowrank(r, q=1, center=False)
    top_v = v[:, 0]
    scores = (r @ top_v) ** 2
    return scores

def spectral_filter(model, loader, num_classes: int, drop_fraction: float):
    """Return the indices to keep after spectral-signature filtering."""
    keep_indices: list[int] = []
    per_class = {c: [] for c in range(num_classes)}

    # Collect penultimate-layer features per class.
    model.eval()
    with torch.no_grad():
        for x, y, idx in loader:
            feats = model.features(x)          # penultimate layer
            for f, yy, ii in zip(feats, y, idx):
                per_class[int(yy)].append((int(ii), f.cpu()))

    for c, items in per_class.items():
        if not items:
            continue
        idxs = torch.tensor([i for i, _ in items])
        feats = torch.stack([f for _, f in items])
        scores = spectral_scores(feats)
        n_keep = int((1.0 - drop_fraction) * len(items))
        keep = idxs[scores.argsort()[:n_keep]]
        keep_indices.extend(int(i) for i in keep)

    return keep_indices
```

### What spectral-signature gives you

- **Works without knowing the trigger.** Feature-space filter,
  not trigger-search.
- **Is strongest against clean-label poisoning.** The poisoned
  examples share a feature signature even when their labels look
  fine.
- **Requires a reasonably-well-trained model** to produce
  meaningful representations. Applying it on a random-init model
  finds nothing.

### What spectral-signature will *not* do

- Detect targeted poisoning where the poisoned examples were
  crafted specifically to avoid a spectral signature (feature-
  collision adaptive attacks — Koh et al. 2018).
- Catch every backdoor. Small-trigger BadNets attacks with strong
  trigger signal often show up; subtle triggers may not.
- Distinguish an adversary-inserted anomaly from a genuine minority
  of hard examples. The `drop_fraction` knob throws out real data
  along with poison; the tradeoff is explicit.

Reference implementation: `art.defences.detector.poison.
SpectralSignatureDefense` in the Adversarial Robustness Toolbox.

---

## Activation clustering

Chen et al. 2018 (*Detecting Backdoor Attacks on Deep Neural
Networks by Activation Clustering*) uses the observation that
poisoned and clean examples in the same class produce distinct
activation patterns. Cluster the last-layer activations *per
class* and label the smaller cluster as the suspect group.

Recipe:

1. Train the model.
2. For each class `c`:
   a. Collect activations `A_c` from the last hidden layer for all
      examples labelled `c`.
   b. Dimensionality-reduce (PCA / ICA — Chen et al. use FastICA,
      the reference implementation offers PCA too).
   c. Run 2-means clustering on the reduced activations.
   d. **Analyse the clusters.** Two heuristics:
      - **Relative size.** If one cluster is much smaller than the
        other (e.g. < 35% of the class), the smaller cluster is a
        suspect group.
      - **Silhouette score.** High silhouette (clear cluster
        separation) plus the size heuristic points at poisoning.
3. Human review of the suspect cluster's samples. Confirmed
   poison → remove and retrain.

### Interpretation

- **Two clean clusters** (e.g. balanced 60/40 split within a class
  with poor silhouette) → almost certainly not poisoning; retain
  both.
- **Skewed cluster** (one cluster < 35%, high silhouette) → almost
  certainly poisoning; inspect.
- **Every class shows the same pattern** → your feature extractor
  is broken, or the data has legitimate sub-populations. Do not
  treat as poisoning without human review.

Reference implementation: `art.defences.detector.poison.
ActivationDefence`. Chen et al.'s original code is also public.

Activation clustering complements spectral-signature: they find
overlapping but non-identical poison sets. Running both and
taking the union is a defensible workflow for a training-pipeline
gate on a corpus you cannot fully audit by hand.

---

## Backdoor detection — Neural Cleanse and STRIP

Spectral-signature and activation-clustering treat the training
set. Neural Cleanse and STRIP treat the *trained model* and are
useful when:

- You imported a pretrained model and cannot re-audit its training
  data.
- You suspect an insider inserted a backdoor and want to inspect
  the final artefact.
- You want a post-training gate on top of the training-pipeline
  gates.

### Neural Cleanse (Wang et al. 2019)

The insight: a backdoored model has, for each *target class*, a
small trigger pattern that maps *any* input to that class. If you
optimise for the smallest trigger that flips predictions to each
class in turn, the target class will show a **conspicuously
smaller** trigger than the others (measured by L1 norm of the
trigger mask).

Recipe:

1. For each candidate target class `c`:
   a. Optimise for a `(mask, pattern)` pair such that pasting the
      pattern (weighted by the mask) onto arbitrary inputs makes
      the model predict `c`.
   b. Record the L1 norm of the mask.
2. Compute the **anomaly index** — how many median absolute
   deviations below the median the smallest mask is. Wang et al.
   flag classes with anomaly index > 2.
3. Human review of the flagged class(es). If confirmed:
   - **Mitigation 1:** Fine-prune (Liu et al. 2018) neurons whose
     activations correlate strongly with the recovered trigger.
   - **Mitigation 2:** Retrain with the recovered trigger patched
     onto benign inputs labelled with their true class
     (adversarial unlearning of the trigger).
   - **Mitigation 3:** Reject the model outright — the honest
     answer when the trained artefact came from an untrusted
     source.

### STRIP (Gao et al. 2019)

**STRong Intentional Perturbation** takes a different angle: at
inference, it perturbs a suspect input by superimposing other
random inputs; a *backdoored* model with the trigger present in
the suspect input will keep predicting the attacker's class with
low entropy across all superimpositions, while a *clean* input
would show high entropy. Concretely: compute the average
prediction entropy across many superimpositions and flag inputs
with entropy below a threshold.

STRIP runs as a **serving-time detector** on individual inputs,
not as a training-pipeline gate. It is cheap enough to run inline
on suspect traffic and does not require the training set.

### Limits of both

- Neural Cleanse assumes a **single, small, static trigger per
  target class**. Adaptive attackers with dynamic or dispersed
  triggers evade it (there are follow-on papers — TABOR, ABS —
  that address specific evasion strategies).
- STRIP requires strong prediction-locking behaviour under
  superimposition. Sophisticated backdoors that respond only to
  specific *combinations* of triggers evade STRIP.
- Both catch backdoors the attacker did not anticipate defence
  for. Against an adaptive attacker aware of the defence, the
  detection rates drop substantially.

The defensible posture is: use these detectors as *screening*
tools that raise the cost of a backdoor, and rely on provenance
discipline (mod-104) plus supply-chain scanning (mod-110) as the
primary controls.

---

## Continual-learning canaries

Continual and online learning multiplies the poisoning surface: the
training data comes from live traffic, and any user with an account
is a training-data contributor. Detection cannot wait for the
quarterly retraining audit.

The pattern that works in production is **canary samples**: known
inputs with known correct labels that are re-scored after every
retraining cycle. Movement on a canary is a training-pipeline
alert.

### Canary catalogue design

Two canary types:

- **Positive canaries** — inputs the model must classify
  correctly. Drift in accuracy or confidence on these canaries
  indicates availability poisoning or unintended concept drift.
- **Trigger canaries** — inputs constructed with known synthetic
  triggers (a specific unusual token, a rare pixel pattern in a
  known-invisible corner, a marker feature no honest user would
  submit). A trigger canary that starts producing the attacker
  label indicates a backdoor is forming — either from ingested
  poison or from a compromised base model.

Canary counts should be:

- Small enough not to influence training (a few dozen per class
  is typical).
- Diverse enough to cover the model's decision surface — every
  class, every important sub-population.
- Refreshed periodically so the attacker cannot game them (the
  attacker who can predict every canary can craft data that
  passes them).

### Pipeline wiring

The continual-learning loop:

1. Fresh training data lands.
2. Data-QC gates run (schema, per-feature outlier, spectral
   signature at a light `drop_fraction`).
3. Model retrains on the accepted data.
4. **Canary re-scoring** — every canary re-evaluated at the new
   checkpoint; per-canary confidence and prediction recorded.
5. **Canary alerting** — any canary whose confidence drops by
   more than a per-canary threshold, or whose prediction changes,
   fires an alert; the retrained model is quarantined pending
   review.
6. Rollback if the alert is confirmed: revert to the previous
   checkpoint, mark the accepted data batch for re-inspection,
   run activation clustering on the added examples.

### Instrumentation

Canary evaluation produces structured records — the mod-104 audit
log is the right sink:

```
{
  "event": "canary_eval",
  "run_id": "train-2026-09-04-14-22",
  "model_uri": "oci://registry/fraud-model@sha256:...",
  "canary_id": "canary-positive-fraud-0042",
  "expected_label": "not_fraud",
  "observed_label": "not_fraud",
  "confidence_expected_class": 0.94,
  "confidence_delta_from_prev": -0.02,
  "verdict": "ok"
}
```

Alerts route through the same mod-111 event bus that owns
model-integrity monitoring. Every alert has a human owner; a
canary alert with no owner is exercise 03 of chapter 05.

---

## Composition — data-integrity defence in depth

No single defence catches every poisoning shape. The composition
this chapter recommends:

1. **Provenance (mod-104).** Signed datasets and pipelines mean
   every input to training has a signed lineage. This does not
   *detect* poisoning by an authorised source; it establishes
   who added what.
2. **Supply-chain scanning (mod-110).** Imported base models and
   third-party datasets pass through scanning gates
   (`modelscan`-style pickle inspection, publisher-identity
   verification, known-poisoned-hash denylist).
3. **Data-QC gates on ingestion.** Schema validation, per-feature
   bounds, class-balance sanity, and a light spectral-signature
   scan on the added batch.
4. **Training-time spectral + activation clustering.** Run
   on the full training set before the "final" training run,
   with humans reviewing flagged clusters.
5. **Trained-model backdoor screening.** Neural Cleanse on the
   final artefact for models that went through low-trust data
   or low-trust base models. STRIP inline on suspect serving
   traffic where the ops team has capacity.
6. **Canary re-scoring after every retraining.** The runtime
   floor.

No layer is sufficient; every layer removes attacker options.
Missing layers create the specific poisoning class you cannot
detect.

---

## Standard failure modes

- **Filtering without human review.** Every filter throws out real
  data. Deploying a filter to auto-drop 15% of every class silently
  degrades the model. Filter → review → retrain.
- **`drop_fraction` too low.** A 1% drop cannot catch a 5% poison
  rate. Set the fraction with a written assumption about the
  expected worst-case poison rate.
- **Spectral / clustering on a random-init model.** The
  representations must be meaningful. Run these defences on a
  trained (or mid-training) checkpoint.
- **Canaries that are too obvious.** A canary that is a
  distinguishable outlier in the training-data distribution
  reveals its purpose to an attacker with training-set read
  access; the attacker crafts poison that avoids the canary
  neighbourhood.
- **Canaries never refreshed.** Attacker-inferred canaries are
  no-ops. Rotate the catalogue on a schedule.
- **Neural Cleanse false alarms.** Classes with many small,
  distinctive features can trigger anomaly-index alerts even
  without a backdoor. Human review is mandatory; do not gate
  automatically on the anomaly index alone.
- **Skipping the "the model came from a hub" case.** If the base
  model is a third-party download, backdoor detection is a
  supply-chain gate (mod-110), not just a training-pipeline
  concern. Trigger canaries are your first-line runtime detector.
- **Confusing detection with prevention.** Every detector in this
  chapter tells you *that* the model is compromised. None of them
  restores the clean model. The retraining that removes the poison
  is a separate step and must be run to completion, not deferred.

---

## The mistakes this chapter is trying to prevent

- **"Adversarial training handles it."** Adversarial training
  addresses evasion, not poisoning. A team that answered the
  chapter-01 question with "yes, we have adversarial training" and
  drew a check mark on the poisoning row has skipped this chapter.
- **Trusting label quality as proof of clean data.** Clean-label
  poisoning specifically survives label-quality checks. The
  attacker labelled the samples correctly; the shift is in the
  features.
- **Missing the base-model row.** A poisoned Hugging Face upload
  gives you a backdoored base model with correct evaluation-set
  accuracy. Supply-chain scanning and trigger canaries are the
  answer; there is no data-QC gate that catches it.
- **Deploying a training-pipeline detector without an alert
  path.** A spectral-signature flag with no on-call owner is a
  chart in a dashboard nobody watches.
- **Running canaries as a compliance box-tick.** If the retraining
  pipeline does not *quarantine* on canary movement, the canary
  is a metric, not a control.
- **Assuming the attacker is naïve.** Adaptive-attacker papers
  exist against every defence in this chapter. Design assuming a
  sophisticated attacker and use layered defence; do not oversell
  any single detector.

---

## Summary

- Poisoning and backdoors split by detection surface: aggregate
  distortions (availability / targeted / clean-label) need
  feature-space defences (spectral signature, activation
  clustering); trigger-based backdoors need trigger-search
  (Neural Cleanse) or trigger-response (STRIP) defences.
- Spectral-signature (Tran, Li, Madry 2018) and activation-
  clustering (Chen et al. 2018) are the two training-pipeline
  defences to know; reference implementations exist in ART.
  Neither is fire-and-forget — every filter runs into a human
  review step.
- Neural Cleanse (Wang et al. 2019) and STRIP (Gao et al. 2019)
  operate on trained models and are the right tools for
  screening imported artefacts and suspect serving traffic.
- Continual-learning systems require **canaries** — known-input,
  known-label samples re-scored after every retraining, wired
  into the training-pipeline event bus so poisoning surfaces as
  a pipeline alert.
- Detection composes with prevention: provenance (mod-104) and
  supply-chain scanning (mod-110) reduce the attacker's options
  before the detectors run, and no single defence is sufficient
  against adaptive attackers.
- Every defence in this chapter *detects*; the retraining or
  rejection that follows is where the compromise is actually
  removed.
