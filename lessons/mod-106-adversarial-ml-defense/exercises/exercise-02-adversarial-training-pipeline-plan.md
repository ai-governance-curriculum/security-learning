# Exercise 02 — Adversarial Training Pipeline Plan

**Estimated effort:** ~4 hours
**Deliverable:** A design bundle consisting of (a) a design memo
(~3–4 pages) that specifies how PGD-AT and TRADES land on the
target training platform, (b) a `training_job.yaml` schema
extension covering the adversarial-training section with a
worked example config, (c) a compute-cost delta table for a
named target model at the trained ε, (d) a written evaluation-
harness specification that the platform enforces before any
robust-accuracy number leaves it, and (e) a rollout plan that
names the first target model, the gating checks, and the
rollback trigger.
**Prerequisites:** Chapter 02 read end-to-end. Exercise 01
completed for at least one target model — the baseline number is
the input to the "does this help?" argument. Familiarity with
the target org's training platform primitives (Kubeflow /
SageMaker / Vertex / a custom scheduler — the exercise structure
does not depend on which).

---

## Objective

Turn "we should do adversarial training" from a wish into a
platform-ready plan. The output is what a training-platform
staff engineer takes into a design review — a proposal detailed
enough for the platform team to build against, and honest enough
about the costs that the finance and product stakeholders sign
off with eyes open.

By the end of this exercise you have:

- Argued *which* adversarial-training method (PGD-AT or TRADES)
  fits the first target model and why.
- Specified the platform-facing config the training team sets
  when opting in.
- Priced the compute-cost delta so the run does not surprise the
  budget.
- Named the standard evaluation ensemble the platform runs
  before publishing any robustness number.
- Named the rollback trigger — when the platform reverts a
  release, no matter how promising the numbers looked.

You are not writing training code in this exercise. You are
writing the *plan* the training team implements.

---

## Problem statement

Continue with the target model from exercise 01. Its baseline
robust accuracy is on the record; the current production version
has no adversarial training.

The current training platform:

- Accepts training jobs as YAML + Python entrypoint.
- Runs on a managed cluster (assume GPUs with modern batch
  capacity — H100 / A100 / equivalent).
- Records artefacts to an object store; registers final models
  in the org's registry (mod-104).
- Has no first-class adversarial-training path today. A single
  researcher has a working PGD notebook that runs at half the
  production batch size.

Business context:

- The product team can accept a modest clean-accuracy drop if the
  robustness number is defensible.
- Compute is a real cost — a 5× longer training run must be
  justified.
- The organisation has one team of ~4 platform engineers who own
  training-platform features; anything added here contends with
  their other roadmap items.

Your job is to hand the platform team a plan they can build
without further clarification.

---

## Requirements

### Deliverable A — design memo

A structured Markdown memo (~3–4 pages) covering, in order:

1. **Target model and baseline.**
   Reference exercise 01's threat-model artefact and scorecard.
   State the clean and robust accuracy numbers verbatim from the
   scorecard.
2. **Method choice: PGD-AT vs TRADES.**
   Choose one for the first target. Argue on:
   - Cost tolerance (TRADES adds ~10–20% compute over PGD-AT for
     the same K; both are 3–10× vs. clean training).
   - Utility tolerance (TRADES gives back more clean accuracy at
     equal robustness).
   - Operational surface (TRADES adds `β` as a knob; PGD-AT does
     not).
   - Precedent in the org and in the literature for this
     architecture and dataset.
   If both are on the table, state the criterion for switching
   after the first run.
3. **Threat model.**
   Norm, ε, and (for tabular / text / audio models) the
   per-domain adaptation from chapter 02. Cite the perturbation
   an attacker can actually perform on the input surface — do not
   pick ε in a vacuum. State what is *outside* the threat model
   (semantic transforms, patches, other norms) and how the
   product surface handles that residual risk.
4. **Attack configuration.**
   `K`, `α`, `random_start`, and the projection convention. Argue
   any departure from chapter 02's reference values.
5. **Training recipe.**
   Optimiser, LR schedule, batch size, epoch count, mixed-
   precision policy, BatchNorm handling under adversarial and
   clean inputs, checkpoint policy. If the team plans a fast-AT
   variant (free-AT / YOPO / fast-FGSM with cyclic LR), name
   the specific failure-mode monitoring (gradient-alignment for
   fast-FGSM, catastrophic-overfitting early-stopping) required
   before it ships.
6. **Evaluation contract.**
   Pointer to Deliverable D. In one paragraph: what the platform
   enforces before publishing.
7. **Cost delta.**
   Pointer to Deliverable C. In one paragraph: the number the
   finance / capacity conversation hinges on.
8. **Rollout plan.**
   First model, gating checks, rollback trigger, dependencies on
   other exercises (04 poisoning surface + 05 monitoring +
   mod-104 model card).
9. **Non-goals.**
   Explicit list of what this pipeline does *not* address —
   poisoning, backdoors, extraction, membership inference. The
   chapter-01 seam repeated where it will land next to
   stakeholders.

### Deliverable B — `training_job.yaml` schema extension

Extend the platform's existing training job schema (or, if there
is no schema, propose one) with an `adversarial_training:`
section. At minimum:

```yaml
adversarial_training:
  enabled: true
  method: pgd | trades
  threat_model:
    norm: linf | l2
    epsilon: <float>            # in the same units as the model input
  attack:
    steps: <int>
    alpha: <float>
    random_start: <bool>
  trades:
    beta: <float>               # only used when method: trades
  eval:
    ensemble: [autoattack, pgd_higher_k, cw_l2]
    autoattack:
      version: standard | plus | rand
    samples: <int>
    seed: <int>
  budget:
    max_walltime_hours: <int>
    max_gpu_hours: <int>
    expected_multiplier_vs_clean: <float>  # cost-review sanity
```

Deliver:

- The JSON Schema (or equivalent) documenting each field, its
  type, its default, and its required-vs-optional status.
- A **worked example** filled in for the target model with real
  values (not `<int>`).
- A section covering validation the platform performs at submit
  time (e.g. `epsilon > 0`, `alpha ≈ epsilon / steps · 2.5`,
  `budget.max_gpu_hours ≥ compute_delta_estimate`).
- Explicit note of what happens when validation fails — the
  submission is rejected with a specific error, not silently
  downgraded.

### Deliverable C — compute-cost delta table

A table with real numbers for the target model.

| Configuration | Time per epoch | Epochs | Total GPU-hours | Cost multiplier | Notes |
| --- | --- | --- | --- | --- | --- |
| Clean baseline | | | | 1.0× | current production |
| PGD-AT K=7 | | | | | reference |
| PGD-AT K=10 | | | | | proposal |
| TRADES β=6 K=10 | | | | | alternative |
| Free-AT | | | | | fast variant |

Each row must have real (measured or well-estimated) numbers,
not "TBD". If measurement is not possible in the exercise
timeframe, run a small-scale profile (one epoch on a scaled-down
dataset) and extrapolate — but call out the extrapolation
explicitly.

The last column captures assumptions: batch size, hardware, mixed
precision. A different assumption produces a different multiplier
and the reviewer must be able to see which is which.

### Deliverable D — evaluation-harness specification

The platform will run this every time a model with
`adversarial_training.enabled: true` finishes training. Specify:

- The **standard ensemble** — AutoAttack `standard` plus at least
  two auxiliaries (PGD at 2× the training K, CW L2, and/or
  Square).
- The **eval set** definition — held-out samples, minimum count,
  and how the platform verifies the samples are held out.
- The **reporting contract** — what values land in the model card
  (mod-104 chapter 05) and the audit log (mod-104 chapter 06).
  Every published number carries the norm, ε, attack version,
  seed, and library version.
- The **gate** — the platform refuses to mark the model as
  "adversarially trained" unless:
  - AutoAttack robust accuracy ≥ a stated minimum.
  - The gap between AutoAttack and the strongest auxiliary is
    ≤ a stated tolerance (large gaps flag gradient masking).
  - Clean accuracy has not dropped below a stated floor.
- The **failure path** — what happens when a gate fails. The
  training job's artefact is still written and inspectable, but
  the model registration is blocked with a specific error.

### Deliverable E — rollout plan

A one-page plan the platform lead uses to sequence the work.

- **Phase 0 — Design review.** This memo + Deliverables B–D go
  through platform review. Sign-offs required: platform lead,
  model team lead, security lead.
- **Phase 1 — Reference implementation on a scratch model.**
  A ResNet-18 on CIFAR-10 (or the analogous small model in the
  org) trained end-to-end via the new `adversarial_training:`
  path. Success = model card populated end-to-end, gates fire
  correctly, cost multiplier within 10% of the plan.
- **Phase 2 — First real target model.** The model from exercise
  01. Success = robust accuracy delta is inside the memo's
  claim; clean accuracy delta is inside the memo's floor;
  compute delta is inside the budget.
- **Phase 3 — Second model.** A different architecture or
  domain — the first cross-domain sanity check.
- **Rollback trigger.** State conditions that revert a model to
  the pre-adversarial checkpoint:
  - AutoAttack robust accuracy below the promised floor.
  - Clean accuracy below the promised floor.
  - Compute delta > 1.5× the budget.
  - Any auxiliary attack shows a gradient-masking gap > the
    stated tolerance.
  - Any evaluation warning that reproduces on a second run.

Every phase has an explicit owner. Every gate is measurable.

---

## Starter guidance

- **Use chapter 02's reference numbers as the memo's starting
  point.** They are a starting point — not a claim about your
  system. Argue departures explicitly.
- **Do not defer method choice.** If the memo says "we'll
  evaluate both", the platform team will not know which one to
  build. Pick one; state the second as a fallback with a
  criterion.
- **Get the cost estimate from a real measurement.** A ratio
  drawn from a paper does not survive a finance review. Run a
  short profile on your actual data and hardware.
- **The gate matters more than the number.** A model card that
  says "50% robust accuracy" with no gate is a claim the ops
  team cannot enforce; a gate that refuses to publish anything
  above a fixed tolerance without AutoAttack sign-off is the
  actual control.
- **Involve platform earlier than feels comfortable.** The
  schema extension is where most of the friction lives (naming,
  validation, error messaging). Draft it, share it, iterate
  before locking anything else.
- **Cross-reference mod-104.** The model-card and audit-log rows
  this exercise adds are already implied by mod-104 chapter 05
  and chapter 06 — don't invent new schemas, extend the existing
  ones.

---

## Acceptance criteria

A passing bundle:

- Design memo covers every section above with substance, not
  outline.
- Method choice is argued, not deferred.
- YAML schema extension is validated, includes a worked example,
  and specifies submit-time validation.
- Cost delta table has real numbers per row with assumptions
  named.
- Evaluation harness spec names the ensemble, the eval-set
  definition, the reporting contract, the gate, and the failure
  path.
- Rollout plan has three phases with named owners and a written
  rollback trigger.

A failing bundle:

- "TBD" or "the platform team will decide" in any of the schema
  or gate fields — the point of the exercise is that this memo
  makes the decisions.
- Cost multiplier drawn from a paper without a local measurement
  or a written extrapolation.
- Evaluation gate that reports robust accuracy without a norm and
  ε.
- Rollout plan without a rollback trigger — a plan that only
  goes forward is not a plan.
- Non-goals section missing — a reviewer three months later
  cannot tell what this pipeline does not protect.

## Stretch goals

- **Prototype the schema in the platform's own config system.**
  If the platform uses Pydantic / JSON Schema / dhall, submit a
  branch that lands the schema and a stub that rejects
  submissions that violate it.
- **Add a fast-AT variant path with its own gating.** Free-AT or
  fast-FGSM as an opt-in behind a `warning: unstable` flag with
  gradient-alignment monitoring and catastrophic-overfitting
  early-stopping wired in. Document the additional gates.
- **Cross-model transferability check.** The eval harness runs
  an additional attack: AutoAttack adversarials crafted on a
  reference open-weights model, evaluated against the target.
  Report transfer accuracy alongside white-box robust accuracy.
- **Cost dashboard.** A single view that shows month-over-month
  GPU-hours consumed by adversarially-trained jobs and the
  robustness delta they buy. Puts the "is it worth it?"
  conversation on real evidence.
- **Multi-domain schema.** Extend the schema so tabular,
  text, and audio models can express their threat model in the
  same YAML — per-feature bounds for tabular, token-substitution
  budgets for text, and so on. Point at the domain-specific
  attack module the platform selects.
- **CI check on the schema.** Every submitted training job's
  YAML is validated in CI before it hits the scheduler; the
  invalid job never wastes a GPU minute.

## Do not

- Do not skip the non-goals section. Without it, "we have
  adversarial training" gets treated as "we handle adversarial
  attacks" and the chapter-01 seam is quietly erased.
- Do not commit a cost estimate without stating hardware and
  batch-size assumptions.
- Do not propose a fast-AT variant without its associated
  gradient-alignment and catastrophic-overfitting guardrails —
  the failure modes are real and the mitigation is required.
- Do not treat this as a research-paper design. The audience is
  the platform team; write for them.
- Do not commit a solution here — solutions live in the paired
  solutions repo.
