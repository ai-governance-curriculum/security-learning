# mod-108-privacy-engineering-for-ml: Privacy Engineering for ML — Differential Privacy, PETs, Inference-Attack Mitigation, PII/PHI Controls

> Scaffolded by `aicg org execute-plan`. Lecture chapters and exercise content are authored on subsequent autonomous cycles.

**Estimated effort:** 14 hours

## Learning objectives

- Configure DP-SGD (Opacus) for a training run, choosing an appropriate (epsilon, delta) budget and justifying the trade-off against utility
- Mitigate membership and attribute inference attacks in a deployed model — architectural controls (per-user rate limits, output aggregation), training-time controls (DP), and monitoring
- Wire PII/PHI DLP into the training-data pipeline and into prompt logging (Presidio or equivalent)
- Translate GDPR Articles 22 (automated decisions), 25 (DP by design), and 35 (DPIA) into concrete engineering artifacts — a right-to-explanation view, DP-by-design ADR, DPIA template
- Translate HIPAA Security Rule administrative / physical / technical safeguards into ML-platform-specific controls
- Cover requirement theme req-08

## Structure

- `01-…md` … `0N-…md`: lecture chapters.
- `exercises/`: per-exercise prompts.
- `labs/`: long-form hands-on labs.
- `quizzes/`: knowledge checks.
- `resources.md`: external references.
