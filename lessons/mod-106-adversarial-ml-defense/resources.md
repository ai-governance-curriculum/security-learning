# Resources — mod-106-adversarial-ml-defense

Primary sources for every claim in chapters 01–06 and the five
exercises. Prefer the official standard, the author's preprint on
arXiv, and the project's own documentation over secondary summaries.
Versions, revisions, API surfaces, and paper numbering move; verify
at time of reading.

---

## Standards and taxonomies

- **NIST AI 100-2** — *Adversarial Machine Learning: A Taxonomy and
  Terminology of Attacks and Mitigations*. The canonical attack
  taxonomy chapter 01 is written against. Check for the current
  revision; the publication is updated.
  <https://csrc.nist.gov/pubs/ai/100/2/final>
- **NIST AI RMF 1.0** — *AI Risk Management Framework*. GOVERN /
  MAP / MEASURE / MANAGE; the measurement surface the chapters here
  feed into.
  <https://www.nist.gov/itl/ai-risk-management-framework>
- **NIST AI RMF — Generative AI Profile (NIST AI 600-1).**
  <https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.600-1.pdf>
- **OWASP Machine Learning Security Top 10.** The developer-facing
  shorthand chapter 01 uses alongside NIST AI 100-2.
  <https://owasp.org/www-project-machine-learning-security-top-10/>
- **OWASP LLM Top 10 (2025).** Cross-reference for prompt-injection,
  jailbreak, and prompt-based training-data-extraction attacks
  (mod-107 owns this surface in depth).
  <https://genai.owasp.org/llm-top-10/>
- **MITRE ATLAS** — adversarial-ML technique catalogue mapped to a
  familiar ATT&CK-style structure. Useful for threat-model artefacts
  and red-team planning.
  <https://atlas.mitre.org/>
- **ISO/IEC 23894:2023** — *Information technology — Artificial
  intelligence — Guidance on risk management*.
  <https://www.iso.org/standard/77304.html>
- **ISO/IEC 42001:2023** — *Information technology — Artificial
  intelligence — Management system*.
  <https://www.iso.org/standard/81230.html>
- **EU AI Act (Regulation (EU) 2024/1689).** Article 15 (accuracy,
  robustness, and cybersecurity) is the one chapters 02–03 and 06
  most directly map to; verify article numbers against the OJEU
  consolidated text.
  <https://eur-lex.europa.eu/eli/reg/2024/1689/oj>

---

## Chapter 01 — attack landscape (foundational papers)

- **Szegedy et al. 2014** — *Intriguing properties of neural
  networks* (first adversarial-example demonstration).
  <https://arxiv.org/abs/1312.6199>
- **Goodfellow, Shlens, Szegedy 2015** — *Explaining and Harnessing
  Adversarial Examples* (FGSM).
  <https://arxiv.org/abs/1412.6572>
- **Papernot et al. 2017** — *Practical Black-Box Attacks against
  Machine Learning* (transferability, the extraction-to-evasion
  pivot).
  <https://arxiv.org/abs/1602.02697>

---

## Chapter 02 — adversarial training

- **Madry et al. 2018** — *Towards Deep Learning Models Resistant to
  Adversarial Attacks* (PGD and PGD-AT; the reference adversarial-
  training formulation).
  <https://arxiv.org/abs/1706.06083>
- **Zhang et al. 2019** — *Theoretically Principled Trade-off
  between Robustness and Accuracy* (TRADES).
  <https://arxiv.org/abs/1901.08573>
- **Wong, Rice, Kolter 2020** — *Fast is better than free: Revisiting
  adversarial training* (FGSM-AT with random init; cost reduction
  pitfalls).
  <https://arxiv.org/abs/2001.03994>
- **Carlini & Wagner 2017** — *Towards Evaluating the Robustness of
  Neural Networks* (C&W attack; the "do not trust single-attack
  robustness claims" paper).
  <https://arxiv.org/abs/1608.04644>
- **Croce & Hein 2020** — *Reliable evaluation of adversarial
  robustness with an ensemble of diverse parameter-free attacks*
  (AutoAttack; the standard reporting ensemble).
  <https://arxiv.org/abs/2003.01690>
- **Athalye, Carlini, Wagner 2018** — *Obfuscated Gradients Give a
  False Sense of Security* (why gradient-masking "defences" fail).
  <https://arxiv.org/abs/1802.00420>
- **Carlini et al. 2019** — *On Evaluating Adversarial Robustness*
  (checklist for honest robustness evaluation).
  <https://arxiv.org/abs/1902.06705>
- **RobustBench.** The curated leaderboard and benchmark harness
  for robust-accuracy numbers under AutoAttack.
  <https://robustbench.github.io/>

---

## Chapter 03 — certified robustness via randomised smoothing

- **Cohen, Rosenfeld, Kolter 2019** — *Certified Adversarial
  Robustness via Randomized Smoothing*. The construction chapter 03
  implements.
  <https://arxiv.org/abs/1902.02918>
- **Reference implementation (Cohen et al.).** The authors'
  Train / Predict / Certify code; a good reading reference even if
  you re-implement.
  <https://github.com/locuslab/smoothing>
- **Salman et al. 2019** — *Provably Robust Deep Learning via
  Adversarially Trained Smoothed Classifiers* (smoothed +
  adversarially-trained base model; the SOTA pairing).
  <https://arxiv.org/abs/1906.04584>
- **Yang et al. 2020** — *Randomized Smoothing of All Shapes and
  Sizes* (smoothing beyond ℓ₂; useful if your threat model is not
  Gaussian).
  <https://arxiv.org/abs/2002.08118>
- **Lecuyer et al. 2019** — *Certified Robustness to Adversarial
  Examples with Differential Privacy* (PixelDP; connects smoothing
  to DP mechanisms).
  <https://arxiv.org/abs/1802.03471>

---

## Chapter 04 — poisoning and backdoor detection

- **Biggio, Nelson, Laskov 2012** — *Poisoning Attacks against
  Support Vector Machines* (the original formal poisoning paper).
  <https://arxiv.org/abs/1206.6389>
- **Shafahi et al. 2018** — *Poison Frogs! Targeted Clean-Label
  Poisoning Attacks on Neural Networks*.
  <https://arxiv.org/abs/1804.00792>
- **Gu, Dolan-Gavitt, Garg 2017** — *BadNets: Identifying
  Vulnerabilities in the Machine Learning Model Supply Chain*
  (the canonical backdoor formulation).
  <https://arxiv.org/abs/1708.06733>
- **Chen et al. 2017** — *Targeted Backdoor Attacks on Deep
  Learning Systems Using Data Poisoning*.
  <https://arxiv.org/abs/1712.05526>
- **Tran, Li, Madry 2018** — *Spectral Signatures in Backdoor
  Attacks* (chapter 04 implementation reference).
  <https://arxiv.org/abs/1811.00636>
- **Chen et al. 2018** — *Detecting Backdoor Attacks on Deep Neural
  Networks by Activation Clustering*.
  <https://arxiv.org/abs/1811.03728>
- **Wang et al. 2019** — *Neural Cleanse: Identifying and
  Mitigating Backdoor Attacks in Neural Networks*. IEEE S&P 2019.
  <https://people.cs.uchicago.edu/~ravenben/publications/pdf/backdoor-sp19.pdf>
- **Gao et al. 2019** — *STRIP: A Defence against Trojan Attacks
  on Deep Neural Networks*.
  <https://arxiv.org/abs/1902.06531>
- **Liu, Dolan-Gavitt, Garg 2018** — *Fine-Pruning: Defending
  Against Backdooring Attacks on Deep Neural Networks*.
  <https://arxiv.org/abs/1805.12185>
- **Steinhardt, Koh, Liang 2017** — *Certified Defences for Data
  Poisoning Attacks*.
  <https://arxiv.org/abs/1706.03691>
- **BackdoorBench.** A reference benchmark + implementation suite
  for backdoor attacks and defences.
  <https://github.com/SCLBD/BackdoorBench>

---

## Chapter 05 — serving-layer attack detection

### Extraction

- **Tramèr et al. 2016** — *Stealing Machine Learning Models via
  Prediction APIs*. USENIX Security 2016. The foundational
  extraction paper.
  <https://arxiv.org/abs/1609.02943>
- **Juuti et al. 2019** — *PRADA: Protecting against DNN Model
  Stealing Attacks* (query-distribution detector chapter 05
  implements a form of).
  <https://arxiv.org/abs/1805.02628>
- **Jagielski et al. 2020** — *High Accuracy and High Fidelity
  Extraction of Neural Networks*. USENIX Security 2020.
  <https://arxiv.org/abs/1909.01838>
- **Orekondy, Schiele, Fritz 2019** — *Knockoff Nets: Stealing
  Functionality of Black-Box Models*.
  <https://arxiv.org/abs/1812.02766>
- **Lee et al. 2019** — *Defending Against Neural Network Model
  Stealing Attacks Using Deceptive Perturbations*.
  <https://arxiv.org/abs/1806.00054>

### Membership and attribute inference

- **Shokri, Stronati, Song, Shmatikov 2017** — *Membership
  Inference Attacks against Machine Learning Models*. IEEE S&P.
  <https://arxiv.org/abs/1610.05820>
- **Yeom et al. 2018** — *Privacy Risk in Machine Learning:
  Analyzing the Connection to Overfitting*.
  <https://arxiv.org/abs/1709.01604>
- **Fredrikson, Jha, Ristenpart 2015** — *Model Inversion Attacks
  that Exploit Confidence Information*. CCS 2015.
  <https://dl.acm.org/doi/10.1145/2810103.2813677>
- **Carlini et al. 2022** — *Membership Inference Attacks From
  First Principles* (LiRA; current reference attack).
  <https://arxiv.org/abs/2112.03570>
- **Carlini et al. 2021** — *Extracting Training Data from Large
  Language Models*. USENIX Security 2021.
  <https://arxiv.org/abs/2012.07805>

### Watermarking

- **Adi et al. 2018** — *Turning Your Weakness Into a Strength:
  Watermarking Deep Neural Networks by Backdooring*.
  <https://arxiv.org/abs/1802.04633>
- **Uchida et al. 2017** — *Embedding Watermarks into Deep Neural
  Networks*.
  <https://arxiv.org/abs/1701.04082>

---

## Chapter 06 — DP-SGD with Opacus

### Foundational differential privacy

- **Dwork, McSherry, Nissim, Smith 2006** — *Calibrating Noise to
  Sensitivity in Private Data Analysis* (the ε-DP foundation).
  <https://www.iacr.org/archive/tcc2006/38760266/38760266.pdf>
- **Dwork & Roth 2014** — *The Algorithmic Foundations of
  Differential Privacy* (the standard textbook reference).
  <https://www.cis.upenn.edu/~aaroth/Papers/privacybook.pdf>
- **Dwork, Kenthapadi, McSherry, Mironov, Naor 2006** — *Our Data,
  Ourselves: Privacy via Distributed Noise Generation*.
  <https://link.springer.com/chapter/10.1007/11761679_29>

### DP-SGD and accountants

- **Abadi et al. 2016** — *Deep Learning with Differential Privacy*
  (DP-SGD; the moments accountant).
  <https://arxiv.org/abs/1607.00133>
- **Mironov 2017** — *Rényi Differential Privacy*.
  <https://arxiv.org/abs/1702.07476>
- **Mironov, Talwar, Zhang 2019** — *R(enyi) Differential Privacy of
  the Sampled Gaussian Mechanism*.
  <https://arxiv.org/abs/1908.10530>
- **Gopi, Lee, Wutschitz 2021** — *Numerical Composition of
  Differential Privacy* (PRV accountant).
  <https://arxiv.org/abs/2106.02848>
- **Dong, Roth, Su 2022** — *Gaussian Differential Privacy*.
  <https://arxiv.org/abs/1905.02383>

### Opacus (library used in chapter 06 and exercise 05)

- **Opacus documentation.** <https://opacus.ai/>
- **Opacus source.** <https://github.com/pytorch/opacus>
- **Opacus — introduction paper, Yousefpour et al. 2021.**
  <https://arxiv.org/abs/2109.12298>
- **Opacus FAQ** — compatibility, hyperparameter choice, batch-
  memory manager; read before configuring a real run.
  <https://opacus.ai/docs/faq>
- **Opacus `PrivacyEngine` API.**
  <https://opacus.ai/api/privacy_engine.html>

### Membership inference under DP (the chapter-05-to-chapter-06 bridge)

- **Jayaraman & Evans 2019** — *Evaluating Differentially Private
  Machine Learning in Practice* (why "we trained with DP" is not
  the same as "MI-AUC is near chance").
  <https://arxiv.org/abs/1902.08874>

### Alternative frameworks (for comparison)

- **TensorFlow Privacy.**
  <https://github.com/tensorflow/privacy>
- **JAX Privacy.**
  <https://github.com/google-deepmind/jax_privacy>
- **PyTorch DP-Accounting (Google).**
  <https://github.com/google/differential-privacy/tree/main/python/dp_accounting>

---

## Attack / defence tooling (used across chapters)

- **IBM Adversarial Robustness Toolbox (ART).** The reference
  toolkit for exercise 01; covers attacks, defences, and metrics
  for most ML frameworks.
  <https://github.com/Trusted-AI/adversarial-robustness-toolbox>
  Docs: <https://adversarial-robustness-toolbox.readthedocs.io/>
- **AutoAttack.** The reference evaluation ensemble.
  <https://github.com/fra31/auto-attack>
- **torchattacks.** Lightweight PyTorch attack library;
  convenient alternative to ART for PyTorch-only setups.
  <https://github.com/Harry24k/adversarial-attacks-pytorch>
- **Foolbox.** Cross-framework attack library.
  <https://github.com/bethgelab/foolbox>
- **CleverHans.** Older but still cited; useful for TF-centric
  shops.
  <https://github.com/cleverhans-lab/cleverhans>
- **Microsoft Counterfit.** Threat-emulation CLI; useful for
  red-team style exercises.
  <https://github.com/Azure/counterfit>
- **Garak (NVIDIA).** LLM vulnerability scanner; cross-reference
  for mod-107 but useful here when the model is generative.
  <https://github.com/NVIDIA/garak>
- **PyRIT (Microsoft).** Risk-identification toolkit for
  generative-AI systems.
  <https://github.com/Azure/PyRIT>

---

## Benchmarks and leaderboards

- **RobustBench** — robust-accuracy leaderboard under AutoAttack.
  <https://robustbench.github.io/>
- **BackdoorBench** — backdoor attack and defence benchmark.
  <https://github.com/SCLBD/BackdoorBench>
- **ML-Doctor** — unified framework for membership-inference and
  model-stealing attacks.
  <https://github.com/liuyugeng/ML-Doctor>

---

## Operational / platform-engineering references

- **Google — Perspectives on Issues in AI Governance.** Context
  for the "defence as a platform service, not a research notebook"
  framing chapter 02 pushes.
  <https://ai.google/static/documents/perspectives-on-issues-in-ai-governance.pdf>
- **Microsoft — Failure Modes in Machine Learning.** A
  taxonomy that overlaps with NIST AI 100-2 at the engineering
  layer.
  <https://learn.microsoft.com/security/engineering/failure-modes-in-machine-learning>
- **Google — Responsible AI Practices (Security section).**
  <https://ai.google/responsibilities/responsible-ai-practices/>
- **Google — Model Cards for Model Reporting (Mitchell et al.
  2019).** The report surface chapter 03 and chapter 06 write to.
  <https://arxiv.org/abs/1810.03993>

---

## Cross-module references

- **mod-102 — Threat Modelling for AI/ML Systems.** The scaffolding
  the chapter-01 artefact plugs into.
- **mod-103 — Secure ML Platform Architecture.** The identity,
  admission-gate, and mesh primitives chapter 05 depends on.
- **mod-104 — Data and Model Lineage Security.** Provenance and
  signed-lineage controls chapter 04 composes with.
- **mod-105 — Secrets and Key Management.** Per-caller API-key
  management for the extraction-detector identity layer.
- **mod-107 — LLM and Agent Security.** LLM-specific evasion
  (prompt injection, jailbreaks, prompt-based data extraction).
- **mod-108 — Privacy Engineering for ML.** Broader privacy
  programme chapter 06 connects into.
- **mod-109 — AI Governance and Compliance Engineering.** Consumer
  of the model-card evidence the chapters here write.
- **mod-110 — Supply Chain Security for AI.** Base-model provenance
  and imported-artefact scanning behind the backdoor surface
  chapter 04 names.
- **mod-111 — Security Operations and Incident Response for ML.**
  Event-bus consumer for canary alerts, extraction alerts, and
  MI-AUC regressions.
