# Exercise 01 — CNI Evaluation

**Estimated time**: 2 hours
**Deliverable**: A 2–3 page decision document

---

## The assignment

You are setting up a new Kubernetes cluster for SmartRecs. The
ops team asks: "Which CNI do we use?" Produce a decision document
that picks one, defends the choice, and acknowledges the
trade-offs.

## Constraints

- SmartRecs runs on EKS today (might be GKE in 12 months).
- The team is 6 engineers; operating complex infrastructure is
  expensive.
- L7-aware egress (hostname-based filtering) is on the roadmap
  but not immediately required.
- Hubble-style observability is desirable for security work.
- The cluster will have ~30 services, ~80 pods at steady state.

## Candidates to evaluate

- **Cilium**.
- **Calico** (OSS).
- **AWS VPC CNI** (the EKS default) — with or without the OSS
  Calico add-on for NetworkPolicy enforcement.

(If you're working in GCP / Azure, substitute the equivalent
managed default and a comparable OSS option.)

## The decision document must cover

For each candidate:

1. **NetworkPolicy enforcement** — yes / no / requires-add-on.
2. **L7 awareness** — what L7 features it supports out of the box.
3. **Observability** — what telemetry it produces and how.
4. **Operational cost** — install, upgrade, troubleshooting effort.
5. **Multi-cluster / multi-cloud** — what it supports.
6. **Ecosystem maturity** — community, security advisories,
   release cadence.

Then:

- A **recommendation** with a concrete reason.
- A **migration story** if the recommendation differs from the
  EKS default (most likely Cilium-on-EKS).
- **Acknowledged downsides** of the recommendation.
- **When you would re-evaluate** (what change in SmartRecs
  warrants revisiting).

## Format

```
# CNI Decision: SmartRecs

## Audience
(Engineering leadership + ops team)

## Recommendation (TL;DR)
(One sentence, plus 2-sentence justification.)

## Candidates

### Cilium
- NetworkPolicy: ...
- L7: ...
- Observability: ...
- Operational cost: ...
- Multi-cluster: ...
- Maturity: ...

### Calico
...

### VPC CNI (EKS default)
...

## Decision

## Migration plan (if recommendation ≠ current default)

## Acknowledged trade-offs

## Re-evaluation triggers
```

## Quality criteria

A passing decision:

- Compares candidates against **the same criteria** in the same
  order.
- Recommends one explicitly. "It depends" is not a decision.
- Acknowledges the trade-offs of the recommendation — what's
  worse about your pick, not just what's better.
- Names re-evaluation triggers (when would you change your
  mind?).
- Migration plan is realistic — typically a phased CNI swap is
  multi-week to multi-month.

A failing decision:

- Picks Cilium because "L7 features are cool."
- Picks the default because "it's easier" without considering
  the security cost.
- No migration plan.
- No re-evaluation triggers.

## Reflection questions

1. What changes in SmartRecs would flip your recommendation?
2. Which factor (enforcement / L7 / observability / cost) drove
   the decision most? Defend the weighting.
3. The ops team pushes back: "We don't have time to operate
   Cilium." What's the response — give in, push back, find a
   middle ground?
