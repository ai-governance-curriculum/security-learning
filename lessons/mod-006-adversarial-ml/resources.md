# Module 06 — Resources

> Primary sources for adversarial ML. This is the area where
> going to the papers pays off the most.

## Foundational papers (read at least one per attack class)

### Evasion

- **Szegedy et al. 2013** — *Intriguing properties of neural
  networks*. [arxiv.org/abs/1312.6199](https://arxiv.org/abs/1312.6199)
  Introduced adversarial examples.

- **Goodfellow et al. 2014** — *Explaining and Harnessing
  Adversarial Examples*. [arxiv.org/abs/1412.6572](https://arxiv.org/abs/1412.6572)
  FGSM + intuition for why adversarial examples exist.

- **Madry et al. 2018** — *Towards Deep Learning Models
  Resistant to Adversarial Attacks*. [arxiv.org/abs/1706.06083](https://arxiv.org/abs/1706.06083)
  PGD + adversarial training as standardized methodology.

- **Carlini & Wagner 2017** — *Towards Evaluating the
  Robustness of Neural Networks*. [arxiv.org/abs/1608.04644](https://arxiv.org/abs/1608.04644)
  C&W attack.

- **Ilyas et al. 2019** — *Adversarial Examples Are Not Bugs,
  They Are Features*. [arxiv.org/abs/1905.02175](https://arxiv.org/abs/1905.02175)
  Non-robust-features intuition.

### Certified defenses

- **Cohen et al. 2019** — *Certified Adversarial Robustness via
  Randomized Smoothing*. [arxiv.org/abs/1902.02918](https://arxiv.org/abs/1902.02918)

- **Croce & Hein 2020** — *Reliable evaluation of adversarial
  robustness with an ensemble of diverse parameter-free
  attacks*. [arxiv.org/abs/2003.01690](https://arxiv.org/abs/2003.01690)
  AutoAttack — the modern evaluation standard.

### Poisoning

- **Biggio et al. 2012** — *Poisoning Attacks against Support
  Vector Machines*. [arxiv.org/abs/1206.6389](https://arxiv.org/abs/1206.6389)
  Foundational training-time attack paper.

- **Gu et al. 2017** — *BadNets: Identifying Vulnerabilities in
  the Machine Learning Model Supply Chain*. [arxiv.org/abs/1708.06733](https://arxiv.org/abs/1708.06733)
  Backdoor attacks.

- **Tran et al. 2018** — *Spectral Signatures in Backdoor
  Attacks*. [papers.nips.cc/paper/2018/hash/280cf18baf4311c92aa5a042336587d3-Abstract.html](https://papers.nips.cc/paper/2018/hash/280cf18baf4311c92aa5a042336587d3-Abstract.html)
  A backdoor detection method.

### Extraction

- **Tramèr et al. 2016** — *Stealing Machine Learning Models
  via Prediction APIs*. [arxiv.org/abs/1609.02943](https://arxiv.org/abs/1609.02943)
  Foundational model-extraction paper.

- **Papernot et al. 2017** — *Practical Black-Box Attacks against
  Machine Learning*. [arxiv.org/abs/1602.02697](https://arxiv.org/abs/1602.02697)
  Substitute models + transfer attacks.

### Privacy attacks

- **Shokri et al. 2017** — *Membership Inference Attacks Against
  Machine Learning Models*. [arxiv.org/abs/1610.05820](https://arxiv.org/abs/1610.05820)
  Foundational membership-inference paper.

- **Fredrikson et al. 2015** — *Model Inversion Attacks that
  Exploit Confidence Information and Basic Countermeasures*.
  [cs.cmu.edu/~mfredrik/papers/fjr2015ccs.pdf](https://www.cs.cmu.edu/~mfredrik/papers/fjr2015ccs.pdf)
  Foundational model-inversion paper.

### Differential privacy

- **Dwork & Roth 2014** — *The Algorithmic Foundations of
  Differential Privacy*. [cis.upenn.edu/~aaroth/Papers/privacybook.pdf](https://www.cis.upenn.edu/~aaroth/Papers/privacybook.pdf)
  Standard textbook reference.

- **Abadi et al. 2016** — *Deep Learning with Differential
  Privacy*. [arxiv.org/abs/1607.00133](https://arxiv.org/abs/1607.00133)
  DP-SGD.

## LLM-specific

- **OWASP Top 10 for LLM Applications**
  [owasp.org/www-project-top-10-for-large-language-model-applications](https://owasp.org/www-project-top-10-for-large-language-model-applications/)

- **Greshake et al. 2023** — *Not what you've signed up for:
  Compromising Real-World LLM-Integrated Applications with
  Indirect Prompt Injection*. [arxiv.org/abs/2302.12173](https://arxiv.org/abs/2302.12173)
  Indirect prompt injection.

- **Zou et al. 2023** — *Universal and Transferable Adversarial
  Attacks on Aligned Language Models*. [arxiv.org/abs/2307.15043](https://arxiv.org/abs/2307.15043)
  Automated jailbreak attacks.

- **Anthropic's Responsible Scaling Policy**
  [anthropic.com/responsible-scaling-policy](https://www.anthropic.com/responsible-scaling-policy)
  A model-developer's safety framework.

## Standards and frameworks

- **NIST AI 100-2 — Adversarial Machine Learning**
  [csrc.nist.gov/pubs/ai/100/2/e2023/final](https://csrc.nist.gov/pubs/ai/100/2/e2023/final)

- **MITRE ATLAS** (Module 01)
  [atlas.mitre.org](https://atlas.mitre.org/)

## Libraries

- **Adversarial Robustness Toolbox (ART)** — IBM
  [github.com/Trusted-AI/adversarial-robustness-toolbox](https://github.com/Trusted-AI/adversarial-robustness-toolbox)
  Documentation: [adversarial-robustness-toolbox.readthedocs.io](https://adversarial-robustness-toolbox.readthedocs.io/)
  The most comprehensive toolbox. Used in this module's exercises.

- **Opacus** — DP-SGD for PyTorch
  [opacus.ai](https://opacus.ai/)

- **TensorFlow Privacy** — DP-SGD for TF
  [github.com/tensorflow/privacy](https://github.com/tensorflow/privacy)

- **AutoAttack**
  [github.com/fra31/auto-attack](https://github.com/fra31/auto-attack)

- **CleverHans**
  [github.com/cleverhans-lab/cleverhans](https://github.com/cleverhans-lab/cleverhans)

- **Foolbox**
  [github.com/bethgelab/foolbox](https://github.com/bethgelab/foolbox)

## Books

- **Anthony D. Joseph et al. — *Adversarial Machine Learning***
  (Cambridge University Press, 2018). The standard textbook.

- **Battista Biggio & Fabio Roli — *Wild Patterns*** (book +
  the original paper [arxiv.org/abs/1712.03141](https://arxiv.org/abs/1712.03141)).
  Decade-long survey.

## Cross-references within this curriculum

- [`ai-infra-security-solutions/projects/project-3-adversarial-defense/SOLUTION.md`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions/blob/main/projects/project-3-adversarial-defense/SOLUTION.md) — Reference design with PGD, DP-SGD, input validation, rate limit.

- [`ai-infra-mlops-learning/projects/project-5-llmops/`](https://github.com/ai-infra-curriculum/ai-infra-mlops-learning/tree/main/projects/project-5-llmops) — LLM-safety pipeline reference.

- [`ai-infra-architect-solutions/projects/project-303-llm-rag-platform/SOLUTION.md`](https://github.com/ai-infra-curriculum/ai-infra-architect-solutions/blob/main/projects/project-303-llm-rag-platform/SOLUTION.md) — Architecture-level LLM safety story.

## Things deliberately not on this list

- Blog posts claiming "perfect" adversarial defense.
- Vendor whitepapers for "AI security" products that don't
  cite specific attacks.
- Tutorials older than 2022 — the field has moved, especially
  for LLM attacks.
