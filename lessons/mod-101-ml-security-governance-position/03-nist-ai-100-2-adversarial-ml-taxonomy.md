# Chapter 03 — NIST AI 100-2 as the Working Adversarial-ML Vocabulary

> **Note on AI-assisted content.** Verify all NIST AI 100-2 vocabulary
> against the current published version at
> [csrc.nist.gov/pubs/ai/100/2](https://csrc.nist.gov/pubs/ai/100/2/e2023/final).
> The published edition at the time of writing is
> `NIST.AI.100-2e2023`.

---

## Why this chapter exists

OWASP tells you the *risk categories*. MITRE ATLAS tells you the
*TTPs*. NIST AI 100-2 — the Adversarial ML Taxonomy — gives you the
*shared vocabulary* the field's academic literature, tool authors,
red-team reports, and formal threat models all speak.

If a security-engineering team cannot use this vocabulary precisely,
three failure modes appear:

1. **Threat models read as vibes.** A team that says "we defend
   against attackers" without specifying attacker capability,
   knowledge, and goal is not actually running a threat model.
2. **Red-team reports do not compare across models.** Without shared
   dimensions of attack, "attack success rate 30%" is not
   interpretable — is that a white-box PGD-∞ at ε=8/255, or a
   black-box query-limited HopSkipJump?
3. **Standards conversations stall.** EU AI Act Article 15's
   "cybersecurity, accuracy, and robustness" obligation is discussed
   in NIST AI 100-2 vocabulary; ISO/IEC 42001 clauses hook the same
   vocabulary. A team without the vocabulary cannot translate the
   obligation into a control.

This chapter installs the vocabulary and then shows how to *use it* to
write a threat model, a red-team report, and a control specification
that other engineers, evaluators, and auditors read the same way.

---

## The taxonomy's spine

NIST AI 100-2 organises adversarial ML along a handful of orthogonal
dimensions. Every attack the field discusses can be located on this
grid.

<!-- needs-research: verify each dimension name, each attack-family name, and each mitigation term against the current NIST AI 100-2 edition (e2023 at time of writing) before quoting to an external audience. -->

### Dimension 1 — Attacker's goal

- **Availability violation.** Degrade the model's ability to serve
  its function — denial-of-service, unacceptable latency, mass
  misclassification.
- **Integrity violation.** Cause specific incorrect outputs. Two
  sub-shapes matter:
  - **Targeted** — the attacker picks the wrong answer.
  - **Untargeted** — any wrong answer will do.
- **Privacy compromise.** Extract information about the training
  data or about the model itself (weights, decision surface,
  intellectual property).
- **Abuse violation** (GenAI/LLM extension in NIST AI 100-2
  e2023). Cause the system to produce content or actions the
  operator wants to prohibit.

### Dimension 2 — Attacker's capability

- **Training-time capability.** The attacker can influence the
  training data (poisoning) or the training process (poison the
  optimiser, poison the RLHF preferences, insert a backdoor via
  compromised code).
- **Inference-time capability.** The attacker can query the model
  and observe outputs. Sub-classes matter:
  - **Query access only** — send input, receive output.
  - **Score access** — receive per-class confidences.
  - **Gradient / logit access** — receive richer output the attacker
    can differentiate.
- **Model access.** The attacker has the model weights (full
  white-box) or a functionally similar model (grey-box).

### Dimension 3 — Attacker's knowledge

- **White-box.** Attacker knows the architecture, weights, training
  data, and hyperparameters.
- **Grey-box.** Attacker knows some — architecture but not weights,
  or training data but not weights.
- **Black-box.** Attacker knows only what the model returns.
  - **Query-limited** black-box — a strict query budget.
  - **Score-based** black-box — score access only.
  - **Decision-based** black-box — top-1 label only.

### Dimension 4 — Attack surface / lifecycle stage

- **Training** — poisoning, backdoor insertion, supply-chain
  compromise of training components.
- **Inference** — evasion, extraction, inference-time privacy
  attacks.
- **Post-deployment** — model skewing via feedback, drift
  exploitation, indirect prompt injection.

### Dimension 5 — GenAI-specific extensions (in the AI 100-2 e2023
edition)

The e2023 edition explicitly extends the taxonomy to cover generative
AI and includes:

- **Prompt injection** (direct and indirect) as an integrity-and-abuse
  attack against generative systems.
- **Data extraction** from generative models (training-data
  memorisation).
- **Denial-of-service via generation cost** for LLMs.
- **Alignment-and-safety bypasses** (jailbreaks) as abuse violations.

Refresh the exact extension list from the current edition before
citing details.

---

## The attack families the taxonomy classifies

Using the dimensions above, NIST AI 100-2 catalogues the following
families. For each, note the goal, capability, knowledge, and
lifecycle stage — this is the shape of the threat-model row you
should be able to write on demand:

| Family | Typical goal | Typical capability | Typical knowledge | Lifecycle stage |
| --- | --- | --- | --- | --- |
| **Evasion** | Integrity (targeted/untargeted misclassification) | Inference | White/grey/black-box | Inference |
| **Data poisoning** | Availability or integrity, sometimes with a backdoor | Training-data access | Grey-box typical | Training |
| **Backdoor / Trojan** | Integrity (targeted, trigger-conditional) | Training-data or model access | Grey/white-box | Training |
| **Model extraction / stealing** | Privacy (IP theft) | Query access | Black-box, budget-limited | Inference |
| **Membership inference** | Privacy (training-data disclosure) | Query access, score access preferred | Black-box | Inference |
| **Attribute inference** | Privacy (attribute disclosure) | Query access | Black-box | Inference |
| **Model inversion** | Privacy (reconstruct training records) | Query + score access | Grey/black-box | Inference |
| **Reprogramming** | Abuse / repurposing | Query access | Black-box | Inference |
| **Prompt injection** (GenAI) | Integrity or abuse | Prompt access (direct or indirect) | Black-box | Inference |
| **Data extraction / memorisation** (GenAI) | Privacy | Query access, sometimes crafted prompts | Black-box | Inference |

For every family, three questions:

1. **What is the threat-model row?** Attacker goal, capability,
   knowledge, and the concrete assets exposed.
2. **What is the standard attack in the literature?** Which reference
   attack from the academic canon (Szegedy adversarial examples,
   BadNets, Tramèr extraction, Shokri membership inference,
   Fredrikson inversion, Greshake indirect prompt injection).
3. **What is the standard mitigation in the taxonomy?** Adversarial
   training and certified defences for evasion; DP-SGD for
   inversion, membership inference, and memorisation; rate limits
   and query budgets for extraction and inversion; provenance and
   quarantine for poisoning and backdoor.

Chapters 06, 07, and 08 (mod-106, mod-107, mod-108) implement each
mitigation at platform scale. This chapter installs the vocabulary.

---

## The mitigations vocabulary

The taxonomy names classes of mitigation you will see repeatedly. Be
precise about the terminology; a control-library entry is easier to
justify when it uses the standard name.

- **Adversarial training** — training on adversarially perturbed
  examples (PGD, TRADES, FGSM).
- **Certified robustness** — training procedures that yield a
  provable bound on the perturbation the model tolerates
  (randomised smoothing, interval bound propagation).
- **Input pre-processing defences** — transformations applied to
  inputs before the model sees them (JPEG compression, random
  cropping, feature squeezing). These are useful but often bypassed
  by adaptive attackers; note the bypass risk in any control
  specification.
- **Differential privacy** — provable bound on the influence of any
  single training record on the model's output distribution,
  expressed as an (ε, δ) budget.
- **Anonymisation / de-identification** — reducing the identifiability
  of training records. **Not equivalent** to differential privacy;
  do not conflate.
- **Data provenance** — signed lineage from a data source to a
  training example.
- **Access control and rate limits** — bound the attacker's query
  capability; not a substitute for the training-time defences but a
  necessary complement.
- **Watermarking** — post-training modification enabling downstream
  identification of theft or misuse. Detective, not preventive.
- **Model unlearning** — after-the-fact removal of a record's
  influence on the model, typically approximate.
- **Detection monitors** — in-serving detectors for adversarial
  perturbation, extraction-shaped query patterns, or trigger-shaped
  inputs. Detective, not preventive.

The taxonomy is careful to distinguish **preventive** mitigations
(training-time, architecture-time) from **detective** mitigations
(inference-time, monitoring). This preventive-vs-detective split is
what you write into your coverage matrix from chapter 01.

---

## Using the vocabulary — three worked examples

### Example 1 — Writing a threat-model row

A fraud-detection classifier serves external customers. Adversarial
inputs are the primary concern.

Bad row (vibes):

> "Attackers might try to bypass fraud detection using adversarial
> examples."

Good row (NIST AI 100-2 vocabulary):

> **Threat.** Untargeted-integrity evasion against fraud model
> `fraud-v42`. **Attacker capability**: inference-time, decision-based
> black-box (top-1 label only). **Attacker knowledge**: black-box, no
> access to model or training data, no gradient access. **Assumed
> query budget**: 10^4 queries per authenticated tenant per day (per
> platform rate limit). **Standard attack**: HopSkipJump or Boundary
> attack under this capability envelope. **Reference paper**:
> Chen et al. 2020 / Brendel et al. 2018. **Mitigation**:
> preventive — adversarial training (PGD ε=8/255 on tabular
> equivalent); detective — decision-based-attack pattern detector on
> query stream.

The good row is a working threat-model artifact. It names the exact
capability envelope; a peer or an auditor knows what attack they are
looking at and what mitigation they are evaluating.

### Example 2 — Reading a red-team report

A red-team report claims "the model's robustness dropped from 92% to
27% under attack." That statement is not interpretable without the
vocabulary.

Rewrite with NIST AI 100-2 dimensions:

> "The model's clean accuracy is 92%; under a **white-box PGD-∞
> attack at ε=8/255 with 20 steps**, targeted-integrity attack success
> rate is 73%; under **black-box query-limited HopSkipJump at 1e4
> queries per input**, untargeted-integrity attack success rate is
> 41%."

The rewrite lets you compare across models, across defensive
interventions, and across quarterly re-tests. Your control library
requires this shape; if it does not, downstream evaluation cannot
tell whether a new defence helped.

### Example 3 — Specifying a control

A control-library row for the fraud model:

> **Control ID.** SEC-ML-EVASION-01.
> **Obligation.** OWASP ML01 preventive; EU AI Act Article 15
> robustness; NIST AI RMF MEASURE 2.7 (adversarial testing).
> **Preventive mitigation.** Adversarial training with PGD-∞ at
> ε=8/255, 10 steps, on the tabular-equivalent perturbation
> definition specified in `configs/adv-train-fraud.yaml`.
> **Detective mitigation.** In-serving decision-based-attack
> detector `atlas-monitor/ml-model-access/anomalous-query-coverage`,
> mapped to ATLAS technique `AML.T####` (verify current ID) and
> ATLAS tactic `ML Model Access`.
> **Evidence artifact.** Adversarial-training report signed and
> attached to the model registry entry, including attack success
> rate at ε ∈ {2/255, 8/255, 16/255} under both PGD-∞ (white-box) and
> HopSkipJump (decision-based black-box), pre- and post-training.
> **Owner.** ML platform team writes the training-pipeline hook;
> security-engineering team owns the required-evidence policy at
> admission time.

Notice that the control specification uses the NIST AI 100-2
vocabulary, cites the OWASP category (chapter 01), and tags the ATLAS
technique (chapter 02). Three chapters, one row.

---

## The dimensions to steal for every threat model

If Exercise 03 could hand you one artefact, it would be a
threat-model row template you can memorise. Here it is:

```
THREAT
- Model: <model_id / model_type / lifecycle stage>
- Attacker goal: <availability | integrity-targeted |
                  integrity-untargeted | privacy | abuse>
- Attacker capability: <training-time | inference-time>
                        <query-only | score-access | gradient-access>
                        <query budget>
- Attacker knowledge: <white-box | grey-box (specify what) | black-box>
- Attack surface: <training | inference | post-deployment>
- Standard attack in the literature: <name + reference>
- Standard mitigation in the literature: <preventive + detective>

MITIGATION
- Preventive control: <specific artifact + owner>
- Detective control: <specific alert + query + runbook>
- Evidence artifact: <required at admission time>
- Standard vocabulary used: <NIST AI 100-2 family + OWASP ID + ATLAS ID>
```

A team that produces this row for every top-N threat in a threat
model is producing an artifact an evaluation engineer, an auditor,
and an IR responder can each read.

---

## The mistakes this chapter is trying to prevent

- **"Attacker" without capability.** A threat model that names an
  attacker without stating the capability envelope is not a threat
  model; it is a fear list.
- **"Robustness" without an attack specification.** Robustness under
  what attack, at what ε, with what query budget?
- **Conflating anonymisation with differential privacy.** They
  address overlapping but different threats. Do not use the terms
  interchangeably in a control specification.
- **Missing the abuse-violation dimension.** In LLM/agent apps, the
  attacker's goal is often abuse (produce prohibited content, take
  prohibited actions) rather than classical integrity. Name it
  explicitly.
- **Preventive/detective confusion.** Watermarking is detective, not
  preventive. Anomaly detection is detective, not preventive. Say
  which.

---

## Summary

- NIST AI 100-2 gives the field's shared vocabulary along five
  dimensions: goal, capability, knowledge, lifecycle stage, and (in
  e2023) GenAI extension.
- Every attack family in the literature — evasion, poisoning,
  backdoor, extraction, inversion, membership/attribute inference,
  reprogramming, prompt injection, memorisation extraction — locates
  on this grid.
- The taxonomy separates preventive mitigations (training-time,
  DP-SGD, adversarial training, certified defences) from detective
  mitigations (in-serving monitors, watermarking, rate limits).
- A threat-model row that uses the taxonomy's vocabulary is a
  working artifact; one that does not is a fear list.
- Chapter 04 uses the taxonomy to translate governance obligations
  (NIST AI RMF, ISO/IEC 42001, EU AI Act Articles 9–15) into
  security-engineering deliverables.
