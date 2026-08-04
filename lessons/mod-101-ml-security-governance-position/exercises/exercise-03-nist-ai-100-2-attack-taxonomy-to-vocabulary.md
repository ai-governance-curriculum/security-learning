# Exercise 03 — NIST AI 100-2 Attack Taxonomy as Working Vocabulary

**Estimated effort:** ~2 hours
**Deliverable:** One Markdown document containing five NIST-vocabulary
threat-model rows, one rewritten red-team report excerpt, and one
control specification that unifies OWASP + ATLAS + NIST 100-2 tags
**Prerequisite:** Chapters 01, 02, and 03 read end-to-end; the outputs
from Exercises 01 and 02 available for reference

---

## Objective

Convert the fintech system's threat inventory (Exercise 01) and
technique coverage (Exercise 02) into artifacts written in the NIST
AI 100-2 vocabulary. The goal is precision: after this exercise, a
red-team report you consume or produce must be interpretable by
peers, evaluators, and auditors without follow-up questions.

## Problem statement

Continue with the same fintech LLM-agent-plus-fraud-classifier
system. Your peer `ai-evaluation-engineer` has flagged that the
Exercise 01 matrix uses inconsistent language for the attacker
capability envelope, and your CISO's staff engineer has asked for a
control specification example they can copy into their review
template.

## Requirements

Produce a Markdown document with the following four sections.

### Section 1 — Five NIST-vocabulary threat-model rows

Pick five threats from your Exercise 01 coverage matrix, spanning at
least three different attack families (evasion, poisoning, backdoor,
extraction, membership inference, model inversion, prompt injection,
data extraction from generative models). For each threat, write a
row using the template in chapter 03 §"The dimensions to steal for
every threat model":

```
THREAT
- Model: <model_id / model_type / lifecycle stage>
- Attacker goal: <availability | integrity-targeted |
                  integrity-untargeted | privacy | abuse>
- Attacker capability: <training-time | inference-time>
                        <query-only | score-access | gradient-access>
                        <query budget>
- Attacker knowledge: <white-box | grey-box (specify) | black-box>
- Attack surface: <training | inference | post-deployment>
- Standard attack in the literature: <name + reference>
- Standard mitigation in the literature: <preventive + detective>

MITIGATION
- Preventive control: <specific artifact + owner>
- Detective control: <specific alert + query + runbook>
- Evidence artifact: <required at admission time>
- Standard vocabulary used: <NIST AI 100-2 family + OWASP ID + ATLAS ID>
```

Every row must:

- Fill every line — no TBDs.
- Cite a *specific* standard attack from the academic canon (Szegedy,
  Goodfellow, Madry, BadNets, Tramèr, Shokri, Fredrikson, Greshake
  indirect prompt injection, Carlini extraction, etc.) with a link
  or DOI.
- Cite the OWASP row from Exercise 01 the threat originated in.
- Cite the ATLAS technique from Exercise 02 the threat maps to
  (may be `n/a` if the ATLAS technique for that variant is
  absent — mark and defend).

### Section 2 — Rewrite a vague red-team claim

Take the following (deliberately vague) red-team excerpt and rewrite
it using NIST AI 100-2 vocabulary. The rewrite should be
interpretable across models, defence versions, and quarterly
re-tests without a follow-up call.

> Red-team excerpt (vague):
> "Our attack succeeded 47% of the time against the fraud model. We
> observed a robustness drop of 22 percentage points versus the
> undefended baseline. The LLM agent was jailbroken in 12 of 100
> attempts, though the results depended on how we set up the
> environment."

Your rewrite should name, for each claim:

- The exact attack (family, name, hyperparameters where applicable).
- The exact capability envelope (white/grey/black-box, query budget,
  score/decision access).
- The exact attacker goal.
- The exact measurement — success rate at named budget, comparison
  baseline defined.
- The environment / setup that made the LLM number sensitive.

The rewrite may reasonably expand the excerpt to 3–5 paragraphs.

### Section 3 — One unified control specification

Produce one control-library row for the fraud model's evasion
mitigation, in the shape shown in chapter 03 §Example 3. Required
elements:

- **Control ID** (choose a scheme — `SEC-ML-*`, `SEC-LLM-*` — and
  stick to it).
- **Obligation.** OWASP row from Exercise 01 + EU AI Act Article 15
  robustness reference + NIST AI RMF sub-category reference (from
  chapter 04).
- **Preventive mitigation.** The attack, the perturbation budget,
  the training procedure, the config-file path in the training
  pipeline.
- **Detective mitigation.** The alert / detector, the ATLAS tactic
  and technique tags (from Exercise 02).
- **Evidence artifact.** The exact file that ships with the model,
  its signing scheme, and the admission-time policy that inspects
  it.
- **Owner.** Named team.

The control specification is the row a `senior-ai-governance-
architect` (level 50) can drop straight into the control-library
schema.

### Section 4 — Vocabulary reflection (0.5 page)

Answer two questions in one to two paragraphs each:

1. Which of your five threat-model rows was hardest to specify
   precisely — where did the vocabulary strain? (E.g., prompt
   injection over "attacker knowledge" is often awkward; membership
   inference over "query budget" often requires assumptions to
   name.) What would you propose as a house convention to remove the
   ambiguity next time?
2. Where is the vocabulary silent for your system that you wish it
   were not? (E.g., abuse-violation subcategories for
   agent-action-space attacks; multi-turn attack budgets; retrieval
   provenance envelopes.) Which of these are candidates to
   contribute back to NIST AI 100-2 update cycles or to your
   internal supplement?

## Starter guidance

- Chapter 03 §"The dimensions to steal for every threat model" is
  the template — copy it and fill it in.
- For the vague red-team rewrite, the point is not to invent
  numbers. It is to rewrite the claim so that a peer could run the
  same measurement and compare results. Where the excerpt is silent,
  name the assumption you would have written in the run-log.
- The unified control specification should be one row's worth of
  content, not a section header. A control-library row lives on one
  line in a spreadsheet or one entry in a JSON file; your rendering
  is Markdown for readability.

## Acceptance criteria

A passing set of threat-model rows:

- Five rows, each on a distinct attack family.
- Every attacker-capability line names a concrete budget, not
  "high-capability adversary."
- Every citation is a real, reachable paper reference.
- Every OWASP / ATLAS ID is present or explicitly `n/a` with a
  defence.

A passing red-team rewrite:

- Uses the taxonomy's dimensions (goal, capability, knowledge,
  lifecycle stage, attack family).
- Names hyperparameters (ε, step count, query budget, temperature,
  etc.).
- Distinguishes clean accuracy from attack success rate.
- Explains what made the LLM number environment-sensitive.

A passing control specification:

- Fits on a single logical row.
- Cites obligations across at least two frameworks (OWASP + NIST /
  EU / ISO).
- Names the ATLAS tactic and technique.
- Names the admission-time enforcement.

A failing deliverable:

- Uses "attacker" without a capability envelope.
- Uses "robustness" without an attack specification.
- Conflates anonymisation with differential privacy.
- Misses the preventive / detective distinction in the mitigation
  block.

## Stretch goals

- Extend to a sixth row covering the abuse-violation dimension for
  the LLM agent (e.g., "convince the LLM to move money to an
  attacker-controlled linked account against the user's intent").
  This dimension is under-specified in the classical taxonomy;
  document your convention explicitly.
- Prototype a machine-readable version of the control-library row
  (YAML or JSON) with the same fields. This is a preview of the
  mod-109 policy-as-code slice.
- Produce one paragraph on the seam between NIST AI 100-2 (technical
  vocabulary) and EU AI Act Article 15 (regulatory language) — where
  does one map cleanly to the other and where do they diverge?

## Do not

- Do not paraphrase the taxonomy in your own words as the
  deliverable. Use it.
- Do not fabricate paper citations. If you cannot locate a citation,
  mark the row as `<!-- needs-research: cite standard attack -->` and
  continue.
- Do not commit a solution — solutions live in the paired solutions
  repo.
