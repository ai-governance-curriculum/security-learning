# mod-106-adversarial-ml-defense: Adversarial ML Defence at Platform Scale — Evasion, Poisoning, Extraction, Inference, Backdoors

> Scaffolded by `aicg org execute-plan`. Lecture chapters and exercise content are authored on subsequent autonomous cycles.

**Estimated effort:** 18 hours

## Learning objectives

- Working command of the adversarial-ML attack families in NIST AI 100-2 and OWASP ML Top 10: evasion, data poisoning, model extraction, membership / attribute inference, backdoor / trojan attacks
- Design an adversarial-training pipeline (PGD, TRADES) that runs as part of the standard training platform, not as a bespoke research exercise
- Configure certified defences (randomised smoothing) for classifiers where robustness certificates are required
- Wire in-serving attack-detection monitors — high query-similarity extraction detection, membership-inference risk monitoring, poisoning-during-continual-learning canaries
- Configure DP-SGD end to end using Opacus for a training run that must ship with a differential-privacy budget
- Cover requirement theme req-06

## Structure

- `01-…md` … `0N-…md`: lecture chapters.
- `exercises/`: per-exercise prompts.
- `labs/`: long-form hands-on labs.
- `quizzes/`: knowledge checks.
- `resources.md`: external references.
