# Exercise 05 — Defense-in-Depth Design

**Estimated time**: 2 hours
**Deliverable**: A 2–4 page Markdown design document
**Prerequisite**: Exercises 01 and 02 completed

---

## The assignment

Take the SmartRecs system (from Exercise 01) and produce a
defense-in-depth control map keyed to the ML lifecycle. The
control map answers, for each lifecycle stage, **what controls
should be in place and why**.

The lifecycle stages, from lecture notes §6:

1. Data ingest
2. Feature engineering
3. Training
4. Evaluation
5. Registration
6. Deployment
7. Inference
8. Monitoring
9. Decommission

For each stage:

1. **Threats** the stage is exposed to (cite Top-10 IDs and/or
   ATLAS tactics where applicable).
2. **Preventive controls** — what stops the threat.
3. **Detective controls** — what notices when prevention fails.
4. **Responsive controls** — what limits blast radius when
   detection fires.
5. **Acceptance** — threats you are *not* mitigating at this
   stage, with justification ("this is mitigated at stage X
   instead" or "we accept this risk because Y").

Most stages will not need every category filled in. **Honest "none"
or "deferred to stage X" entries are part of a defensible design.**

## Format

Suggested structure:

```
# Defense-in-Depth Control Map: SmartRecs

## Reference threat model
(Link to your Exercise 01 artifact)

## Control map

### Stage 1: Data ingest
- **Threats**: ...
- **Preventive**: ...
- **Detective**: ...
- **Responsive**: ...
- **Accepted at this stage**: ...

### Stage 2: Feature engineering
...

### Stage 3: Training
...

### Stage 4–9
...

## Cross-cutting controls
(Controls that span stages — identity, audit, access reviews.)

## Sequencing
(In what order should the controls be implemented? Justify.)

## Open questions
```

## Quality criteria

A passing design:

- Each stage has a non-trivial entry. "Same as previous stage"
  without elaboration is not enough.
- Controls are **concrete** (specific tools, specific policies,
  specific metrics) — not "implement access control."
- Detective controls produce a **named signal** on a **named
  surface** (e.g., "Prometheus metric `feature_drift_score{}`,
  alert at score > 0.3, paged to ml-platform on-call").
- The sequencing section defends the order. Foundation controls
  (identity, audit) should come before everything else.
- Accepted risks are named honestly. A design with no accepted
  risks is usually overclaiming.

A failing design:

- Lists tools without explaining what they detect or prevent.
- Treats "defense in depth" as "more controls is better"
  without considering operational cost.
- Implements every control at every stage (duplication).
- Implements only preventive controls (no detection).
- Treats SmartRecs as if it had a Fortune-100 budget — propose
  controls a 5-person team can actually operate.

## Reflection questions

1. Which **one** control, if you could only add one, has the
   largest impact? Defend the choice.
2. Which stage of the lifecycle is **most often** under-protected
   in real production systems, in your experience or based on
   the lecture notes?
3. Which control will the SmartRecs team *resist* adding most
   strongly? What argument convinces them?
4. If you were giving up your security role at SmartRecs in 6
   months and handing off to someone less experienced, which
   *three* controls would you want firmly in place by then?

## Capstone connection

This artifact — the control map — is what later modules
implement. Each subsequent module will pick up one or two
lifecycle stages and go deep on the controls. Save it; you'll
refer back to it.

## Solution comparison

After writing your own, compare against the reference design in
[`ai-infra-security-solutions/modules/mod-001-ml-security-foundations/exercise-05/`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions/tree/main/modules/mod-001-ml-security-foundations) (when published).

The reference design is one defensible answer for SmartRecs at
its current scale. A defensible alternative might trade *more*
detective controls for *fewer* preventive ones if operational
capacity is the binding constraint.
