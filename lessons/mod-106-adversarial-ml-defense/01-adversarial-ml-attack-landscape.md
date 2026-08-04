# Chapter 01 — The Adversarial-ML Attack Landscape

> **Note on AI-assisted content.** These lecture chapters were drafted
> with AI assistance and are under human review. Verify every standard
> version, tool API, and control claim against the primary source
> before quoting in production work. See
> [`resources.md`](./resources.md).

---

## Why this chapter exists

Mod-102 gave you a threat-modelling process; mod-103 gave you the
platform primitives that hold that model in place; mod-104 gave you
signed lineage. None of those chapters distinguished between the many
distinct ways an attacker can subvert a model **as a model** — through
its inputs, its training data, its query surface, or its parameter
copy. Adversarial-ML is that distinction.

The specific failure mode this chapter is written to prevent:

> A team ships a fraud-detection classifier. They review the OWASP web
> Top 10, patch the API, and treat the model as done. Six months
> later, an attacker sends a stream of near-duplicate transactions
> that differ only in fields the model never saw during training; the
> classifier waves them through. Post-mortem: "the model was
> vulnerable to evasion attacks." The team had no vocabulary for
> "evasion" because their security programme did not distinguish
> attacks on the classifier from attacks on the surrounding service.

You cannot defend against a family of attacks you cannot name. This
chapter installs the vocabulary the rest of the module uses:
**evasion**, **poisoning**, **model extraction**, **membership /
attribute inference**, and **backdoor / trojan** attacks — as codified
in NIST AI 100-2 and the OWASP Machine Learning Security Top 10 — plus
the threat-actor and access model you use to reason about them.

You leave this chapter able to:

- Name the five adversarial-ML attack families and, for each, the
  attacker's goal, prerequisite access, and canonical example.
- Cross-map each family to the NIST AI 100-2 attack taxonomy and to
  the corresponding OWASP ML Top 10 risk.
- Distinguish **training-time** attacks (data poisoning, backdoors)
  from **inference-time** attacks (evasion, extraction, inference)
  and understand why the defence surface is different for each.
- Classify a proposed defence by which attack family it addresses —
  and which it does not — so that no single control is asked to
  cover threats it cannot cover.
- Understand the standard access models — **white-box**, **grey-box**,
  **black-box** — and how each shapes both attacks and defences.

---

## The two standards you keep on hand

Two documents anchor the conversation. Read both; keep both open when
running a threat model against a model.

### NIST AI 100-2 — *Adversarial Machine Learning: A Taxonomy and
Terminology of Attacks and Mitigations*

NIST AI 100-2 (initial public release 2024, revised on an ongoing
cadence — verify the current revision on the NIST publication page) is
the authoritative attack taxonomy. It carves the space along four
axes:

1. **Learning method** — supervised, unsupervised, reinforcement,
   generative (including LLMs).
2. **Attacker's goal** — availability breakdown, integrity breakdown,
   privacy compromise, misuse.
3. **Attacker's capabilities** — the access the attacker has to the
   training data, the model, and the query interface.
4. **Attacker's knowledge** — white-box, grey-box, black-box.

The taxonomy names each attack family by combining values from those
axes. When you need a precise term for a threat-model artefact — and
you should, because "adversarial input" without qualification is
ambiguous — pull it from NIST AI 100-2.

### OWASP Machine Learning Security Top 10 (and OWASP LLM Top 10)

OWASP publishes two lists relevant here. The **ML Top 10** covers
classical ML risks; the **LLM Top 10** covers generative-AI risks.
mod-107 owns LLM/agent security in depth; this module concentrates on
the classical ML surface, which the OWASP ML Top 10 organises as:

- **ML01 — Input manipulation attack** (evasion).
- **ML02 — Data poisoning attack**.
- **ML03 — Model inversion attack** (a subset of privacy/inference).
- **ML04 — Membership inference attack**.
- **ML05 — Model theft** (extraction).
- **ML06 — AI supply chain attacks** (covered by mod-104 and
  mod-110).
- **ML07 — Transfer learning attack**.
- **ML08 — Model skewing** (a form of data poisoning targeted at
  distribution drift).
- **ML09 — Output integrity attack**.
- **ML10 — Model poisoning** (parameter-level tampering, related to
  backdoors).

The Top 10 entries do not partition the space cleanly — several
(e.g. ML03 and ML04) are both privacy attacks, and ML02 / ML08 / ML10
are three flavours of poisoning that this module treats together.
When the taxonomy names diverge from NIST, cite NIST for the formal
category and OWASP for the "developer's shorthand".

<!-- needs-research: confirm the current revision of NIST AI 100-2 and
     the exact version of OWASP ML Top 10 in force when the module
     ships, and update the Top 10 numbering if OWASP has re-ordered
     between the 2023 draft and the current publication. -->

---

## The five attack families this module defends

Below is the working taxonomy for this module. Every subsequent
chapter is written against one or more of these families; every
exercise asks you to name which family the artefact targets.

### 1. Evasion (test-time / inference-time integrity)

**What it is.** At inference, the attacker perturbs an input so that
the model produces the label the attacker wants — without changing
the input's true semantics from the perspective of a human observer.
The classic example is the imperceptibly perturbed image: pixels
shifted by less than a threshold ε, human-perceptually identical,
classifier flips from *stop sign* to *speed limit 45*. The same
attack shape shows up for tabular fraud detection (a transaction
altered in fields the model over-relies on), for malware
classifiers (a binary with a benign-looking payload appended), and
for audio (a spoken command masked in white noise).

- **NIST AI 100-2 category.** *Evasion attack* (integrity, at
  inference, capabilities vary from black-box query-only to
  white-box gradient access).
- **OWASP ML Top 10.** ML01 (Input manipulation).
- **Prerequisite access.** Query access at minimum; gradient access
  makes attacks much stronger and faster to find.
- **Canonical attacks.** Fast Gradient Sign Method (FGSM, Goodfellow
  et al. 2014); Projected Gradient Descent (PGD, Madry et al. 2018);
  Carlini-Wagner (C&W, 2017); AutoAttack (Croce & Hein 2020) —
  currently the standard ensemble for reporting robust accuracy.
- **Defence families.** Adversarial training (chapter 02), certified
  smoothing (chapter 03), input preprocessing / detection (weaker),
  ensembling (weakest).

### 2. Data poisoning (training-time integrity or availability)

**What it is.** The attacker inserts, modifies, or deletes training
data to shift the model's decision boundary. Variants:

- **Availability poisoning** — degrade overall model quality
  ("model skewing" in OWASP ML08). Requires many poisoned samples.
- **Targeted poisoning** — cause misclassification on a specific
  input or class at inference. Requires fewer samples; the poisoned
  sample looks legitimate.
- **Clean-label poisoning** — targeted poisoning where the poisoned
  training examples are correctly labelled (Shafahi et al. 2018 —
  *Poison Frogs*). Harder to detect because a labeller's second
  look confirms the label.

Continual-learning and online-learning systems (production
recommendation systems, fraud models with feedback loops, user-
personalisation models) are particularly exposed because their
training data comes from live traffic — an attacker who can
submit traffic can submit training data.

- **NIST AI 100-2 category.** *Poisoning attack*, with sub-categories
  for availability, targeted, and clean-label variants; and the
  *backdoor* variant treated separately below.
- **OWASP ML Top 10.** ML02 (Data poisoning), ML08 (Model skewing),
  ML10 (Model poisoning).
- **Prerequisite access.** Write access to some portion of the
  training set. For continual-learning systems: any user account
  that submits data.
- **Defence families.** Data provenance and integrity (mod-104),
  spectral-signature detection (chapter 04), activation-clustering
  (chapter 04), continual-learning canaries (chapter 04), robust
  aggregation for federated setups.

### 3. Backdoor / trojan attacks (training-time targeted integrity)

**What it is.** A special case of targeted data poisoning where the
attacker embeds a *trigger* — a pixel pattern, a token sequence, a
specific input value — such that any input containing the trigger
is classified as the attacker's chosen label. On non-triggered
inputs the model behaves normally, so accuracy metrics do not flag
the compromise. BadNets (Gu et al. 2017) is the canonical
formulation.

Backdoors deserve their own row because the defence surface is
different: standard data-quality checks pass, standard accuracy
metrics pass, and detection requires either provenance discipline
(mod-104), model-internal inspection (activation clustering,
Neural Cleanse), or trigger-search techniques.

- **NIST AI 100-2 category.** *Backdoor attack* (sub-category of
  poisoning).
- **OWASP ML Top 10.** ML10 (Model poisoning), especially when the
  compromised artefact is a third-party pretrained model.
- **Prerequisite access.** Write access to training data OR to the
  model artefact (a fine-tuned pretrained model can be backdoored
  in the base weights — mod-110 owns the supply-chain angle).
- **Defence families.** Provenance (mod-104), Neural Cleanse (Wang
  et al. 2019), STRIP (Gao et al. 2019), spectral signature
  (chapter 04), fine-pruning.

### 4. Model extraction (theft of model functionality)

**What it is.** An attacker with query access reconstructs an
approximation of the target model by observing input/output pairs.
The extracted model can then be:

- Used directly, avoiding the API fees or subscription.
- Used to craft transferable adversarial examples that evade the
  target (grey-box → white-box escalation).
- Used to leak information about the training data (the extracted
  model exposes membership-inference surface even if the API
  wrappings on the original mask it).

The classic references are Tramèr et al. 2016 (*Stealing Machine
Learning Models via Prediction APIs*) and follow-on work on
functionally-equivalent extraction for deep networks (Jagielski
et al. 2020) and LLMs (Carlini et al., ongoing work on prompt-
based extraction).

- **NIST AI 100-2 category.** *Model extraction / stealing* (privacy
  or availability, depending on formulation).
- **OWASP ML Top 10.** ML05 (Model theft).
- **Prerequisite access.** Query access. High query volume is the
  giveaway signal — see chapter 05.
- **Defence families.** Query-similarity detection (chapter 05),
  rate limiting per identity, output perturbation, prediction
  confidence stripping, watermarking of outputs.

### 5. Membership and attribute inference (privacy)

**What it is.** Given the model's response to a query, decide
whether the queried input was in the training set (**membership
inference** — Shokri et al. 2017) or infer sensitive attributes of
training members (**attribute inference** — Fredrikson et al.
2015, Yeom et al. 2018). A model that overfits leaks membership.
LLMs and generative models leak *content*, not just membership —
prompt-extraction attacks recover training strings (Carlini et al.
2021, *Extracting Training Data from Large Language Models*).

These attacks are the concrete failure mode privacy-preserving
training (chapter 06 — DP-SGD) exists to defend against. They are
also the reason mod-108 covers privacy engineering: even a "public"
API can leak individual training records if the model is not
trained with a privacy budget.

- **NIST AI 100-2 category.** *Privacy attacks* — subdivided into
  membership inference, attribute inference, and training-data
  extraction.
- **OWASP ML Top 10.** ML03 (Model inversion), ML04 (Membership
  inference).
- **Prerequisite access.** Query access. Membership inference works
  black-box; the strongest attacks assume white-box or the ability
  to train shadow models.
- **Defence families.** Differential privacy in training (chapter 06),
  output confidence hiding, membership-inference risk monitoring
  (chapter 05), model distillation (as a mitigation, not a
  guarantee).

---

## Training-time vs inference-time — why the split matters

The five families cleave along a temporal seam: some happen while the
model is being built, some happen after it is deployed. The seam
determines where you install the defence.

| Family | When | Defence lives in |
| --- | --- | --- |
| Data poisoning | Training | Training pipeline (data QC, provenance, spectral / clustering) |
| Backdoor | Training or model-import | Training pipeline + supply-chain provenance (mod-104, mod-110) |
| Evasion | Inference | Model itself (adversarial training, certified smoothing) + serving-layer detection |
| Extraction | Inference | Serving layer (query telemetry, rate limits, watermarking) |
| Membership / attribute inference | Inference | Model itself (DP training) + serving layer (confidence hiding) |

Two consequences:

1. **Adversarial training does nothing about data poisoning.** It
   makes the model robust to *inference-time* perturbations of a
   given input, not to *training-time* corruption of the corpus. A
   frequent mistake is to treat "we do adversarial training" as an
   answer to a poisoning question. It is not.
2. **DP-SGD does nothing about evasion.** It bounds the *privacy*
   loss from any single training record's inclusion. It does not
   make the model robust to perturbed inputs, and in fact
   consistently *reduces* clean-input accuracy. Pairing an evasion
   defence with a privacy defence requires deliberate design; you
   do not get either free from the other.

The exercises reinforce this: exercise 01 asks you to name, for a
target model, which family each proposed defence covers and which it
does not.

---

## Access models: white-box, grey-box, black-box

Every attack and every defence assumes a specific attacker access
model. Use the standard terms.

- **White-box.** The attacker has the full model — architecture,
  weights, training-data statistics, sometimes the training data
  itself. This is the strongest attacker model and the one worst-
  case analyses assume (correctly — an attacker who buys a copy of
  the Docker image gets white-box access, and open-weight releases
  give it away for free).
- **Grey-box.** The attacker has partial information — knows the
  architecture but not the weights, or has a related model, or has
  the training data but not the trained weights. Grey-box attacks
  frequently reach white-box strength through *transferability* —
  adversarial examples crafted against one model often fool another
  trained on similar data.
- **Black-box.** The attacker has query access only. Queries can be
  labels ("hard-label"), full probability vectors ("soft-label"),
  logits, embeddings, or generation text. The attacker knows only
  what the API returns.

Two rules of thumb:

- **Assume white-box for open-weight models.** If you ship weights,
  the attacker has them. Robustness claims about closed-weight
  serving are meaningless the day you open-source the weights (or
  the day someone extracts them per family 4).
- **Assume grey-box for closed-weight serving.** Transferability
  from public models plus limited query access gives most attackers
  more than a strict black-box assumption suggests.

Chapters 02 and 03 report robustness under white-box PGD by
convention — the standard evaluation practice — because a defence
that fails white-box PGD will not survive attackers who put in the
work.

---

## What we do not treat here

- **LLM prompt injection, jailbreaks, and agent-tool abuse** belong
  to mod-107 (LLM & Agent Security). They are formally a subclass
  of evasion (input manipulation against a generative model) but
  their defence surface — system-prompt discipline, tool-use policy,
  output filtering — is different enough that a shared chapter
  would help neither audience.
- **AI supply-chain attacks** (compromised base model, malicious
  pickle, poisoned Hugging Face upload) belong to mod-110. Backdoors
  cross the seam: an attacker who compromises a base model has
  installed a backdoor without touching your training data. Chapter
  04 covers detection; mod-110 covers the pre-import gate.
- **General privacy engineering** (data minimisation, k-anonymity,
  synthetic data, deletion pipelines, federated learning) belongs
  to mod-108. Chapter 06 covers **DP-SGD end-to-end** because it is
  the technique that closes the training-time privacy hole
  membership inference exploits; the broader privacy programme is
  mod-108's remit.

Being explicit about the seams prevents this module from becoming a
grab-bag.

---

## Threat-model artefact — what you produce

For any model this module protects, the artefact you produce and
carry through the rest of the chapters looks like:

| Attack family | Applicable? | Attacker access assumed | Consequence if unmitigated | Defence chapter | Owner |
| --- | --- | --- | --- | --- | --- |
| Evasion | | | | 02 / 03 | |
| Data poisoning | | | | 04 | |
| Backdoor | | | | 04 (+ mod-104, mod-110) | |
| Model extraction | | | | 05 | |
| Membership / attribute inference | | | | 05 + 06 | |

Two operational rules:

- **Every "Applicable? = no" row carries a reason.** "Model output
  is discarded after use" is a valid reason to strike evasion.
  "The model is not deployed" is not — that is a decision to defer,
  not to omit.
- **Every "Applicable? = yes" row has a named owner and a defence
  chapter reference.** A yes without an owner is a chapter-05
  incident waiting to happen.

Exercise 01 produces this artefact for a real model.

---

## The mistakes this chapter is trying to prevent

- **Treating "adversarial" as a single threat.** Evasion is not
  poisoning is not extraction. A control that addresses one does
  not automatically address the others. Anyone who says "we're
  protected against adversarial attacks" without naming which
  family should be pressed to be more specific.
- **Assuming attackers stay in one access model.** Black-box
  attackers escalate to grey-box via extraction (family 4);
  grey-box attackers escalate to white-box via transferability.
  Design as if the strongest access is possible unless a technical
  control prevents the escalation.
- **Confusing empirical robustness with certified robustness.**
  Adversarial training (chapter 02) gives empirical robustness — the
  best known attack does not succeed within your evaluation budget.
  Randomised smoothing (chapter 03) gives certified robustness — a
  mathematical guarantee up to a specific radius. Which one you
  need depends on the use case; do not conflate the two.
- **Skipping the privacy row.** Teams reading "adversarial ML"
  frequently jump to evasion and skip membership inference. The
  privacy row is often the highest-consequence one (regulator
  attention, data-subject-rights exposure — see mod-108 and
  mod-109). Do not skip it.
- **Delegating the taxonomy to the model team.** The model team
  knows the model; the security engineer owns the taxonomy. If the
  model team writes "we handle adversarial inputs" in a design doc
  and no one from security asks *which family*, the doc has said
  nothing.

---

## Summary

- Five attack families define the adversarial-ML surface:
  **evasion**, **data poisoning**, **backdoor**, **model
  extraction**, **membership / attribute inference**. NIST AI 100-2
  is the canonical taxonomy; OWASP ML Top 10 is the developer-
  facing shorthand.
- Training-time attacks (poisoning, backdoor) attack the pipeline;
  inference-time attacks (evasion, extraction, inference) attack
  the serving surface. Defences must go where the attack goes.
- Access models — white-box / grey-box / black-box — shape both
  attack strength and defence assumptions. Report robustness under
  white-box PGD by convention; assume grey-box for closed-weight
  serving and white-box for open-weight releases.
- Each subsequent chapter of this module implements defences for
  one or two of these families. Chapter 02 (adversarial training)
  and chapter 03 (certified smoothing) address evasion; chapter 04
  addresses poisoning and backdoors; chapter 05 addresses
  extraction and inference-attack detection; chapter 06 addresses
  privacy leakage with DP-SGD.
- The threat-model artefact is a per-family table with `Applicable?`,
  attacker-access, consequence, defence chapter, and owner columns.
  A yes without an owner is not a defence.
