# Capstone Exercise 03 — ML-Specific Controls

**Estimated time**: 5 hours
**Deliverable**: A 8-12 page document

---

## The assignment

Produce NorthBridge's ML-specific control plan. This is where
Modules 06, 09, and 10 synthesize.

## Required sections

### Section A: Per-model adversarial defense

For each of the 5 production models, name the defense
approach with justification:

| Model | Clean accuracy target | Robust accuracy target | Defense | Justification |
|---|---|---|---|---|
| Triage-Risk | ... | ... | ... | Life-safety; PGD adversarial training + DP-SGD |
| HAI-Predict | ... | ... | ... | ... |
| Med-Verify | ... | ... | ... | ... |
| Ambient-Doc | ... | ... | ... | (LLM — different defense set) |
| Wellness-Coach | ... | ... | ... | (vendor-hosted; different controls) |

For each, identify:

- The most credible attack class for *this model*.
- Why your defense addresses it.
- The trade-off accepted.
- The validation plan.

### Section B: Differential privacy decisions

For each training run, decide on DP-SGD usage:

| Training run | DP-SGD? | (ε, δ) target | Utility cost estimate | Justification |
|---|---|---|---|---|

For Triage-Risk and HAI-Predict (PHI training): DP-SGD is
likely required. Specify the privacy budget, clipping bound,
noise multiplier, accountant. Identify the regulatory driver
(HIPAA Privacy Rule? EU AI Act Art 10?).

For Ambient-Doc fine-tuning: DP-SGD on the fine-tune is
worth considering. Discuss.

### Section C: LLM safety pipeline

For Ambient-Doc (the self-hosted clinical LLM) and Wellness-
Coach (the OpenAI-backed consumer LLM), produce two safety
pipeline designs. Each must include:

- Input filtering layers.
- System-prompt structure (fences, separators).
- Tool authorization (NOT trusting LLM judgment).
- Output filtering.
- Adversarial corpus + regression testing.
- Audit-chain logging.
- Per-tenant rate + cost limits.
- Treat-output-as-untrusted downstream.

For Ambient-Doc specifically, the controls are tighter
because:

- The input may contain attacker-controlled patient chart
  data (indirect prompt injection).
- The output gets inserted into clinical documentation.
- The tool surface includes potential write-access to the
  EHR.

For Wellness-Coach:

- Data redaction before send to OpenAI.
- Output filtering on response.
- Consumer-grade tolerance for false-positive filtering.

### Section D: Model + dataset provenance

Apply Module 10 patterns to NorthBridge:

- **Model artifact signing** — Cosign keyless on all 5
  production models.
- **In-toto attestations** — training-provenance,
  validation, approval.
- **Dataset signing** — for the federated lake's curated
  datasets.
- **Admission verification** — what the serving cluster
  verifies before loading a model.
- **Hugging Face vetting process** — for the Llama 3 base and
  any embedding models in use.

### Section E: Model-promotion gate (policy-as-code)

Design the model-promotion gate (Module 09 §9.1) for
NorthBridge:

- The Rego (or Kyverno) policy.
- The validation evidence required.
- The fairness metrics required.
- The clinical-safety review (a human approval — who?).
- The audit-chain integration.

### Section F: Cross-references

For each control: how does it connect to:

- The Exercise 01 risk it addresses?
- The Exercise 02 architecture it depends on (workload
  identity, KMS, etc.)?
- The Exercise 04 compliance obligations it satisfies?
- The Exercise 05 detections it produces?

## Quality criteria

A passing exercise:

- Per-model defenses with **quantified trade-offs**.
- DP-SGD applied to **the training runs that need it**, not
  blindly.
- LLM safety is **multi-layer** with attention to indirect
  prompt injection.
- Provenance is **end-to-end** (training → registry →
  serving).
- Model promotion gate has **real policy logic**.

A failing exercise:

- "Adversarial training for everything" without trade-offs.
- DP-SGD ignored for PHI training.
- LLM safety addressed only via system prompt.
- Model signing only on container images, not model files.
- Model promotion is "the platform engineer approves."

## Reflection questions

1. Which model's defense costs the most engineering time?
   Defend the investment.
2. The team objects: "DP-SGD will tank accuracy on
   Triage-Risk." How do you respond?
3. The Ambient-Doc safety pipeline catches a customer-impact
   incident: what does the post-mortem look like?

## Time budget

- Per-model adversarial defense: 75 min.
- DP-SGD decisions: 60 min.
- LLM safety pipelines: 90 min.
- Model + dataset provenance: 60 min.
- Promotion gate: 30 min.
- Cross-references: 30 min.
