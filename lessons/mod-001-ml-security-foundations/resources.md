# Module 01 — Resources

> Primary sources for everything cited in the lecture notes, plus
> recommended further reading. Verify all URLs at time of access —
> the field moves and links rot.

## Standards and frameworks

### OWASP

- **OWASP Machine Learning Security Top 10**
  [owasp.org/www-project-machine-learning-security-top-10](https://owasp.org/www-project-machine-learning-security-top-10/)
  The canonical Top-10 catalog for ML systems. The lecture notes
  reference the 2023 version; check the page for the current
  release.

- **OWASP Top 10 for Large Language Model Applications**
  [owasp.org/www-project-top-10-for-large-language-model-applications](https://owasp.org/www-project-top-10-for-large-language-model-applications/)
  The companion list for LLM-specific risks. Read in addition to
  the ML Top 10 if you operate any LLMs.

- **OWASP Application Security Verification Standard (ASVS)**
  [owasp.org/www-project-application-security-verification-standard](https://owasp.org/www-project-application-security-verification-standard/)
  Generic application security baseline. Necessary, not
  sufficient for ML systems.

### MITRE

- **MITRE ATLAS — Adversarial Threat Landscape for AI Systems**
  [atlas.mitre.org](https://atlas.mitre.org/)
  The ML-specific tactics-and-techniques framework. Used in §3
  of the lecture notes and in Exercise 3.

- **MITRE ATT&CK**
  [attack.mitre.org](https://attack.mitre.org/)
  The general enterprise version. Useful for the parts of an ML
  attack chain that aren't ML-specific (Initial Access,
  Persistence, Defense Evasion).

### NIST

- **NIST AI Risk Management Framework (AI RMF 1.0)**
  [nist.gov/itl/ai-risk-management-framework](https://www.nist.gov/itl/ai-risk-management-framework)
  Risk-management guidance for AI systems. Less technical than
  OWASP, more governance-oriented.

- **NIST AI 100-2 — Adversarial Machine Learning**
  [csrc.nist.gov/pubs/ai/100/2/e2023/final](https://csrc.nist.gov/pubs/ai/100/2/e2023/final)
  Adversarial ML threat taxonomy. Read alongside the OWASP ML
  Top 10 for the formal complement.

- **NIST SP 800-218 — Secure Software Development Framework (SSDF)**
  [csrc.nist.gov/Projects/ssdf](https://csrc.nist.gov/Projects/ssdf)
  General software supply-chain hygiene; applies to ML training
  pipelines.

### EU AI Act and related regulation

- **EU AI Act (Regulation (EU) 2024/1689)**
  [eur-lex.europa.eu/eli/reg/2024/1689](https://eur-lex.europa.eu/eli/reg/2024/1689/oj)
  Risk-based regulation of AI systems in the EU. Read at least
  Article 9 (risk management) and Article 15 (accuracy, robustness,
  cybersecurity) if you operate in or sell into the EU.

### SLSA

- **Supply-chain Levels for Software Artifacts (SLSA)**
  [slsa.dev](https://slsa.dev/)
  Measurable supply-chain integrity levels. Foundation for
  Module 10's deep dive.

---

## Foundational research

These are the papers that established the threats the OWASP ML
Top 10 catalogs. You don't have to read all of them; one each from
the three threat classes is a reasonable floor.

### Evasion attacks (ML01)

- **Szegedy et al. 2013** — *Intriguing properties of neural networks*.
  [arxiv.org/abs/1312.6199](https://arxiv.org/abs/1312.6199)
  The paper that introduced adversarial examples.

- **Goodfellow et al. 2014** — *Explaining and Harnessing Adversarial Examples*.
  [arxiv.org/abs/1412.6572](https://arxiv.org/abs/1412.6572)
  FGSM and the intuition for why adversarial examples exist.

- **Madry et al. 2018** — *Towards Deep Learning Models Resistant to
  Adversarial Attacks*. [arxiv.org/abs/1706.06083](https://arxiv.org/abs/1706.06083)
  PGD and the modern adversarial-training methodology.

### Poisoning attacks (ML02, ML08, ML10)

- **Biggio et al. 2012** — *Poisoning Attacks against Support Vector Machines*.
  [arxiv.org/abs/1206.6389](https://arxiv.org/abs/1206.6389)
  Early formal treatment of training-time attacks.

- **Gu et al. 2017** — *BadNets: Identifying Vulnerabilities in the
  Machine Learning Model Supply Chain*. [arxiv.org/abs/1708.06733](https://arxiv.org/abs/1708.06733)
  The classical backdoor-attack paper.

### Extraction attacks (ML03, ML04, ML05)

- **Tramèr et al. 2016** — *Stealing Machine Learning Models via
  Prediction APIs*. [arxiv.org/abs/1609.02943](https://arxiv.org/abs/1609.02943)
  Foundational model-extraction paper.

- **Shokri et al. 2017** — *Membership Inference Attacks Against
  Machine Learning Models*. [arxiv.org/abs/1610.05820](https://arxiv.org/abs/1610.05820)
  Foundational membership-inference paper.

- **Fredrikson et al. 2015** — *Model Inversion Attacks that Exploit
  Confidence Information and Basic Countermeasures*. ACM CCS 2015.
  [cs.cmu.edu/~mfredrik/papers/fjr2015ccs.pdf](https://www.cs.cmu.edu/~mfredrik/papers/fjr2015ccs.pdf)
  Foundational model-inversion paper.

### Differential privacy as a defense

- **Dwork & Roth 2014** — *The Algorithmic Foundations of Differential
  Privacy*. [cis.upenn.edu/~aaroth/Papers/privacybook.pdf](https://www.cis.upenn.edu/~aaroth/Papers/privacybook.pdf)
  Standard textbook reference for the formal framework.

- **Abadi et al. 2016** — *Deep Learning with Differential Privacy*.
  [arxiv.org/abs/1607.00133](https://arxiv.org/abs/1607.00133)
  DP-SGD, the standard mechanism for differentially-private
  training.

---

## Practitioner resources

### Threat-modeling references

- **Adam Shostack — Threat Modeling: Designing for Security** (book).
  The standard text on STRIDE-driven threat modeling.

- **Microsoft Threat Modeling Tool documentation**:
  [docs.microsoft.com/en-us/azure/security/develop/threat-modeling-tool-getting-started](https://docs.microsoft.com/en-us/azure/security/develop/threat-modeling-tool-getting-started)
  Tooling for producing threat models systematically.

### MLOps + security overlap

- **Google "Secure AI Framework" (SAIF)**
  [safety.google/cybersecurity-advancements/saif](https://safety.google/cybersecurity-advancements/saif/)
  Google's published framework for ML system security.

- **Anthropic Responsible Scaling Policy**
  [anthropic.com/responsible-scaling-policy](https://www.anthropic.com/responsible-scaling-policy)
  A model-developer's safety-and-security framework. Useful as a
  counter-example to a pure-infrastructure view.

### Implementation tools

- **Adversarial Robustness Toolbox (ART)**:
  [github.com/Trusted-AI/adversarial-robustness-toolbox](https://github.com/Trusted-AI/adversarial-robustness-toolbox)
  IBM-origin library implementing many attacks and defenses.
  Used in Module 06.

- **Sigstore / Cosign**:
  [sigstore.dev](https://www.sigstore.dev/)
  Signing and verification for container images and arbitrary
  blobs. Used across Modules 04 and 10 of this track.

- **HashiCorp Vault**:
  [vaultproject.io](https://www.vaultproject.io/)
  Secrets management. Module 05.

- **OPA / Gatekeeper / Kyverno**:
  [openpolicyagent.org](https://www.openpolicyagent.org/) /
  [open-policy-agent.github.io/gatekeeper](https://open-policy-agent.github.io/gatekeeper/website/) /
  [kyverno.io](https://kyverno.io/)
  Policy as code. Module 09.

- **Falco**:
  [falco.org](https://falco.org/)
  Runtime security and anomaly detection. Module 08.

---

## Cross-references within this curriculum

- [`projects/`](../../projects/) — The five capstone projects in
  this learning repo. Read each project's README after this module
  to understand what skills will be exercised end-to-end.

- [`ai-infra-security-solutions/projects/`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions/tree/main/projects) — Reference solutions, with `SOLUTION.md` design notes per project.

- [`ai-infra-mlops-learning/projects/project-4-governance/`](https://github.com/ai-infra-curriculum/ai-infra-mlops-learning/tree/main/projects/project-4-governance) — The governance project that several modules of this track build on.

- [`ai-infra-architect-solutions/projects/project-305-security-framework/SOLUTION.md`](https://github.com/ai-infra-curriculum/ai-infra-architect-solutions/blob/main/projects/project-305-security-framework/SOLUTION.md) — Architecture-level framing of the same controls discussed in this track.

---

## Things deliberately not on this list

- Vendor whitepapers presented as primary sources. Vendor papers
  describe products, not threats; cite primary research and
  framework documents instead.
- "AI safety" papers focused on existential / alignment topics —
  outside the scope of this track, which is operational security
  of deployed ML systems.
- Books that haven't been updated for the post-Transformer era;
  the field has moved.
