# Exercise 01 — Gatekeeper vs. Kyverno Choice

**Estimated time**: 2 hours
**Deliverable**: A 2–3 page decision document

---

## The assignment

Pick between Gatekeeper and Kyverno for SmartRecs' admission
controller. Defend the choice in a written decision document.

## Constraints

- Team of 6 engineers; security engineer is the 6th (you).
- Kubernetes is the primary infrastructure.
- Cosign signing is in scope (Module 03 / Module 10).
- OpenAI integration is in scope (Module 06 / Module 07).
- Policies will be authored by the security engineer + a
  small subset of the platform team.
- Pursuing SOC 2 Type 2 — audit-chain integration matters.
- Some policies will likely need to run **outside Kubernetes**
  (Terraform validation, CI gates) over the next 12 months.

## The decision document must cover

1. **The criteria** — what you're evaluating against. Be
   explicit so the choice is defensible.
2. **Side-by-side comparison** on each criterion.
3. **The choice** with reasons.
4. **The trade-offs accepted** — what's worse about the pick
   vs. the alternative.
5. **Migration considerations** — if SmartRecs already has
   some Gatekeeper or Kyverno (it doesn't, but plan for the
   future).
6. **When you would re-evaluate** — what changes warrant
   revisiting.
7. **The reasoning around Rego portability** — if SmartRecs
   needs Rego for Conftest / Terraform / app authz, does the
   choice change?

## Format

```
# Gatekeeper vs. Kyverno: Decision for SmartRecs

## Audience (engineering leadership)

## TL;DR

## Decision criteria

| Criterion | Weight | Why this matters |
|---|---|---|

## Side-by-side

| Criterion | Gatekeeper | Kyverno |
|---|---|---|

## Decision

## Trade-offs accepted

## Migration considerations

## Re-evaluation triggers

## Open questions
```

## Quality criteria

A passing decision:

- Names **explicit criteria** with weights — not "we just feel
  Kyverno is friendlier."
- Side-by-side comparison hits each criterion.
- The choice acknowledges what's *worse* about it, not only
  what's better.
- The Rego-portability question is addressed (it's the key
  argument for Gatekeeper).

A failing decision:

- Picks based on what's trendier.
- "It depends on context" with no actual choice.
- Misses the Rego-portability consideration.

## Reflection questions

1. If SmartRecs decided next quarter to use Sentinel for
   Terraform, would your choice change?
2. The team objects: "Both work; let's just pick one and
   move on." Defend the value of the formal decision document.
3. What signal would tell you the choice was wrong?
