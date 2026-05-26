# Module 06 — Adversarial Machine Learning

**Duration**: ~40 hours (~2 weeks full-time, ~4 weeks part-time)
**Prerequisites**:
- Modules 01–05 completed. Module 01's OWASP ML Top 10
  vocabulary is the foundation; this module goes deep on its
  underlying attacks.
- Mathematical maturity: comfort with linear algebra, gradients,
  basic probability. You don't need to be a researcher, but you
  should be able to read a paper that uses these tools.
- Working knowledge of PyTorch or TensorFlow at the level of
  "I have trained a small model and understand the loss
  function."

## What this module is for

This is the **most ML-specific** module in the track. The other
11 modules cover security work that would be needed for any
infrastructure carrying valuable data. *This* module covers the
attack surface that exists only because there's a model.

You will learn:

1. **The attack taxonomy** — evasion, poisoning, extraction,
   inversion, membership inference — at the depth where you can
   read a paper and understand the threat it documents.
2. **Evasion attacks** at depth — FGSM, PGD, C&W, transfer
   attacks, why they exist mathematically.
3. **Adversarial training** — the standard defense and why it
   trades clean accuracy for robust accuracy.
4. **Certified defenses** — randomized smoothing, interval-bound
   propagation. What provable robustness means in practice.
5. **Data poisoning** — backdoors, BadNets, defenses based on
   provenance and outlier detection.
6. **Model extraction** — query-based reconstruction, defenses
   based on rate limiting and watermarking.
7. **Privacy attacks** — model inversion, membership inference,
   and the differential-privacy formal defense (DP-SGD).
8. **LLM-specific attacks** — prompt injection, jailbreaks,
   indirect prompt injection. The set of threats that has no
   clean formal defense.
9. **Operational adversarial ML** — what you actually deploy in
   production, not what looks good in a paper.

## How to work through this module

This module has more material than the others. Take it in two
sittings:

1. **Week 1**: Lecture notes §1–§7 (evasion, defense,
   poisoning, extraction). Exercises 1–3.
2. **Week 2**: Lecture notes §8–§13 (privacy attacks, LLMs,
   operational). Exercises 4–5.

Use [`resources.md`](./resources.md) for primary sources — for
this module especially, going to the papers is worth the time.

## Module deliverables

- An **adversarial robustness assessment** of a deployed model
  (Exercise 01).
- A **defense plan** with quantified trade-offs (Exercise 02).
- A **poisoning detection design** for a retraining pipeline
  (Exercise 03).
- A **DP-SGD configuration** for a privacy-sensitive training
  run (Exercise 04).
- An **LLM safety pipeline** with multi-layer defenses
  (Exercise 05).

## How this module connects to the rest of the track

| Where module 06 shows up later | What it provides |
|---|---|
| Module 07 Compliance | Privacy attacks ↔ GDPR / HIPAA controls |
| Module 08 Runtime Security | Detection of adversarial input patterns |
| Module 10 Supply Chain | Poisoning defenses ↔ data and model provenance |
| Module 11 Security Operations | Detections for evasion, extraction, poisoning attempts |

## Quick reference

- **Lecture notes**: [`lecture-notes.md`](./lecture-notes.md)
- **Exercises**: [`exercises/`](./exercises/)
- **Quiz**: [`quiz.md`](./quiz.md)
- **Resources**: [`resources.md`](./resources.md)
- **Paired project**: [`projects/project-3-adversarial-defense/`](../../projects/project-3-adversarial-defense/)
- **Paired solution**: [`ai-infra-security-solutions/projects/project-3-adversarial-defense/SOLUTION.md`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions/blob/main/projects/project-3-adversarial-defense/SOLUTION.md)
