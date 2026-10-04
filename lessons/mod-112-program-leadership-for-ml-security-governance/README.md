# mod-112-program-leadership-for-ml-security-governance: Program Leadership for the ML Security & Governance Slice — Control Library Ownership, Metrics, Regulator Support

**Estimated effort:** 16 hours

This module is the programme-leadership capstone for the
AI/ML Security & Governance Engineer role (level 35). The
engineering-skilled chapters (mod-102 through mod-111)
built the controls; this module teaches you to **own, run,
and report on** them as a programme — against a control
library you maintain, through an interface with the CISO /
Legal / head-of-AI-governance you run deliberately,
measured by a metrics package the board consumes, and
tested by a regulator-support operation that holds the
bright line between evidence and opinion.

## Learning objectives

- Own the AI-security section of the enterprise control
  library — its scope, its version history, its evidence
  attachments; hand deeper architectural authoring to
  senior-ai-governance-architect (level 50).
- Size and scope a new ML-security engagement — inventory
  the assets, name the top-N threats, produce a cost-
  and-coverage matrix, publish the security requirements
  for the release-gate.
- Run the CISO / Legal / AI Governance interface —
  quarterly working sessions, review cadence, escalation
  path.
- Produce the ML-security metrics package that feeds the
  head-of-governance (level 60) board-level report —
  vulnerability burn-down, coverage of ATLAS TTPs, IR
  MTTD/MTTR for AI incidents, SLSA-level attainment
  across the model portfolio.
- Support regulator engagement — supply the security-
  engineering evidence a regulator interaction may
  request, coordinate with counsel, do not deliver legal
  opinion.
- Cover requirement theme req-12.

## Lecture chapters

- [01 — Owning the AI-Security Section of the Control
  Library](./01-owning-the-ai-security-control-library.md)
- [02 — Sizing and Scoping a New ML-Security
  Engagement](./02-sizing-and-scoping-an-ml-security-engagement.md)
- [03 — Running the CISO / Legal / AI Governance
  Interface](./03-the-ciso-legal-ai-governance-interface.md)
- [04 — The ML-Security Metrics
  Package](./04-the-ml-security-metrics-package.md)
- [05 — Supporting Regulator Engagement: Evidence, Not
  Opinion](./05-regulator-support-and-evidence-coordination.md)

## Exercises

- [Exercise 01 — AI-Security Control-Library Section
  Authoring](./exercises/exercise-01-ai-security-control-library-section-authoring.md)
- [Exercise 02 — Engagement Scoping: A Worked
  Example](./exercises/exercise-02-engagement-scoping-worked-example.md)
- [Exercise 03 — CISO / Legal / AI Governance Interface
  Plan](./exercises/exercise-03-ciso-legal-governance-interface-plan.md)
- [Exercise 04 — ML-Security Metrics Package for the
  Board Report](./exercises/exercise-04-ml-security-metrics-package-for-board-report.md)
- [Exercise 05 — Regulator-Support
  Runbook](./exercises/exercise-05-regulator-support-runbook.md)

## Structure

- `0N-…md`: lecture chapters.
- `exercises/`: per-exercise prompts.
- `labs/`: long-form hands-on labs.
- `quizzes/`: knowledge checks.
- `resources.md`: external references.

## How this module relates to the rest of the track

- **mod-101** sets the role and reporting structure the
  programme-lead operates within.
- **mod-102 to mod-111** supply the engineering primitives
  (threat models, platform, lineage, secrets, adversarial
  defence, LLM/agent controls, privacy, governance, supply
  chain, SOC/IR). The AI-security control library
  (chapter 01) and the engagement portfolio (chapter 02)
  are organised around those clusters.
- **mod-109** is the governance programme itself —
  frameworks, policy-as-code, frontier-tier gating.
  Chapter 01 and chapter 04 of this module are the
  programme-lead's interface with mod-109; the controls
  bind to the policy-as-code pipeline mod-109 chapter 04
  owns.
- **mod-111** supplies the SOC-side primitives (ATLAS-
  mapped detection content, IR playbooks, SOC interface
  RACI, severity ladder). Chapter 04 of this module
  consumes mod-111 outputs as the IR metric family and
  the ATLAS coverage family.
- **mod-110** supplies the supply-chain primitives (SLSA
  for models, signing, ML-BOM). Chapter 04 of this module
  consumes those as the SLSA metric family.

The programme-lead is the role that keeps all of these
coherent as a programme the organisation can run,
measure, and defend to a regulator — rather than a
collection of separately-impressive engineering
artefacts.
