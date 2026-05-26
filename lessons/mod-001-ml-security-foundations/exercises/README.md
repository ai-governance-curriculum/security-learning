# Module 01 Exercises

Five exercises, in order. Each takes 1–3 hours. Together they produce
a portfolio of artifacts you will reuse and refine in every later
module of this track.

| # | Exercise | Output | Time |
|---|---|---|---|
| 1 | [Threat-model a small ML system](./exercise-01-threat-model-a-small-ml-system.md) | Written STRIDE+ML threat model | 2–3 h |
| 2 | [Map a system to OWASP ML Top 10](./exercise-02-map-system-to-owasp-ml-top-10.md) | Coverage matrix with gaps | 1–2 h |
| 3 | [MITRE ATLAS walkthrough](./exercise-03-mitre-atlas-walkthrough.md) | Tactic-chain narrative for one adversary scenario | 1–2 h |
| 4 | [Security architecture review](./exercise-04-security-architecture-review.md) | Review document with prioritized findings | 2 h |
| 5 | [Defense-in-depth design](./exercise-05-defense-in-depth-design.md) | Lifecycle-level control map | 2 h |

## How to work the exercises

- **Work them in order.** Exercise 1's threat model is the input to
  Exercises 2, 3, and 5. Exercise 4 is independent.
- **Write the artifacts.** The deliverable is a written document, not
  a script. Production work in this role is mostly prose.
- **Use a real-shaped system.** Each exercise gives you a synthetic
  but realistic system. Resist the urge to over-simplify — the value
  is in handling real-shaped complexity.
- **Compare to the reference, last.** The reference solutions in the
  paired `ai-infra-security-solutions` repo are *one defensible
  answer*, not the only one. Compare after you've produced your own.

## Mistake patterns to watch for

- **Producing a list instead of an analysis.** "Threats: ML01, ML02,
  ML05" is not a threat model. The threat model is the *narrative*
  of who would attack, why, and how, with concrete controls.
- **Treating compliance as security.** Items like "we have SOC 2"
  are not threat mitigations.
- **Skipping the lifecycle view.** ML threats span training-time and
  inference-time; an analysis that addresses only one is incomplete.
- **Overweighting evasion attacks.** Adversarial examples are the
  most famous ML threat, not the most common production incident.
  Real production incidents are usually supply-chain (ML06),
  governance (ML03/ML04), or skewing (ML08).
